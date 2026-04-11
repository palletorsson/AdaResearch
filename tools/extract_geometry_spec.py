#!/usr/bin/env python3
"""
Extract geometry_spec for artifacts by reading their GDScript source.

Adds an engine-agnostic build recipe to each registry entry, describing
mesh type, topology, material, animation, and instance strategy.

Usage:
  python tools/extract_geometry_spec.py                          # dry-run all
  python tools/extract_geometry_spec.py --registry parametric    # one registry
  python tools/extract_geometry_spec.py --artifact mobius_strip  # one artifact
  python tools/extract_geometry_spec.py --save                   # write to JSONs
  python tools/extract_geometry_spec.py --confidence 0.4         # threshold filter
  python tools/extract_geometry_spec.py --skip-existing          # don't overwrite
"""
import json
import os
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
REGISTRY_DIR = REPO_ROOT / "commons" / "artifacts" / "registry"


# ══════════════════════════════════════════════════════════════════
# REGISTRY LOADING (from classify_artifacts.py pattern)
# ══════════════════════════════════════════════════════════════════

def load_all_registries(filter_registry=None):
    """Load all artifact entries from registry/*.json.
    Returns dict of {filename: {lookup_name: entry}}."""
    registries = {}
    for f in sorted(REGISTRY_DIR.glob("*.json")):
        if filter_registry and filter_registry not in f.stem:
            continue
        try:
            data = json.loads(f.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            continue
        arts = data.get("artifacts", {})
        if not isinstance(arts, dict):
            continue
        entries = {}
        for key, entry in arts.items():
            if not isinstance(entry, dict):
                continue
            lname = entry.get("lookup_name", key)
            entry["_key"] = key
            entries[lname] = entry
        if entries:
            registries[str(f)] = entries
    return registries


def resolve_script_path(scene_path_res):
    """Convert res:// scene path to GDScript path by parsing .tscn."""
    if not scene_path_res:
        return None
    rel = scene_path_res.replace("res://", "")
    tscn_path = REPO_ROOT / rel
    if not tscn_path.exists():
        return None
    try:
        content = tscn_path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None
    match = re.search(r'type="Script".*?path="(res://[^"]+\.gd)"', content)
    if match:
        return match.group(1)
    if "GDScript" in content and "script/source" in content:
        return "__inline__:" + scene_path_res
    return None


def read_script_content(script_path_res):
    """Read GDScript content from res:// path or inline."""
    if not script_path_res:
        return ""
    if script_path_res.startswith("__inline__:"):
        tscn_res = script_path_res.split(":", 1)[1]
        rel = tscn_res.replace("res://", "")
        tscn_path = REPO_ROOT / rel
        try:
            content = tscn_path.read_text(encoding="utf-8", errors="replace")
            match = re.search(r'script/source\s*=\s*"(.*?)"', content, re.DOTALL)
            if match:
                return match.group(1)
        except OSError:
            pass
        return ""
    rel = script_path_res.replace("res://", "")
    gd_path = REPO_ROOT / rel
    try:
        return gd_path.read_text(encoding="utf-8", errors="replace")
    except (OSError, FileNotFoundError):
        return ""


# ══════════════════════════════════════════════════════════════════
# MESH TYPE DETECTION
# ══════════════════════════════════════════════════════════════════

MESH_TYPE_SIGNALS = {
    "parametric_surface": [
        (r'SurfaceTool', 4),
        (r'PRIMITIVE_TRIANGLES', 3),
        (r'ArrayMesh', 2),
        (r'ARRAY_VERTEX', 3),
        (r'add_surface_from_arrays', 3),
        (r'generate_normals', 2),
    ],
    "procedural_line": [
        (r'PRIMITIVE_LINES', 5),
        (r'PRIMITIVE_LINE_STRIP', 5),
        (r'ImmediateMesh', 3),
    ],
    "texture_plane": [
        (r'ImageTexture', 4),
        (r'set_pixel', 4),
        (r'create_from_image', 4),
        (r'Image\.create', 3),
    ],
    "boolean_composition": [
        (r'CSGCombiner', 5),
        (r'CSGSphere3D|CSGCylinder3D|CSGBox3D|CSGTorus3D', 4),
        (r'OPERATION_UNION|OPERATION_SUBTRACTION|OPERATION_INTERSECTION', 3),
    ],
    "instanced_particles": [
        (r'MultiMesh', 5),
        (r'MultiMeshInstance3D', 4),
        (r'instance_count', 3),
        (r'GPUParticles3D', 5),
        (r'CPUParticles3D', 5),
    ],
    "composed_primitives": [
        (r'BoxMesh\.new\(\)', 2),
        (r'SphereMesh\.new\(\)', 2),
        (r'CylinderMesh\.new\(\)', 2),
        (r'TorusMesh\.new\(\)', 2),
        (r'PrismMesh\.new\(\)', 2),
        (r'MeshInstance3D\.new', 1),
    ],
    "shader_driven": [
        (r'ShaderMaterial', 3),
        (r'\.shader\s*=', 3),
        (r'set_shader_parameter', 2),
    ],
    "delegated_scene": [
        (r'preload\(["\'].*\.tscn', 3),
        (r'\.instantiate\(\)', 2),
    ],
    "terrain_deformation": [
        (r'PlaneMesh', 2),
        (r'heightmap|height_map', 4),
        (r'raise_amount|deform', 3),
    ],
}


def detect_mesh_type(code):
    """Score-based mesh type detection. Returns (type, confidence)."""
    scores = {t: 0 for t in MESH_TYPE_SIGNALS}

    for mesh_type, patterns in MESH_TYPE_SIGNALS.items():
        for pattern, weight in patterns:
            if re.search(pattern, code):
                scores[mesh_type] += weight

    # Disambiguation rules
    # Shader is almost always secondary — most artifacts use ShaderMaterial for visuals
    # but the geometry type is what matters for portability
    geometry_types = ["parametric_surface", "procedural_line", "texture_plane",
                      "boolean_composition", "instanced_particles", "composed_primitives",
                      "terrain_deformation"]
    max_geometry = max(scores[t] for t in geometry_types)
    if max_geometry > 3:
        scores["shader_driven"] = 0
    # delegated_scene is also secondary when real geometry code exists
    if max_geometry > 4 and scores["delegated_scene"] > 0:
        scores["delegated_scene"] = max(0, scores["delegated_scene"] - 3)

    # CSG beats composed_primitives (CSG implies boolean ops)
    if scores["boolean_composition"] > 4 and scores["composed_primitives"] > 0:
        scores["composed_primitives"] = 0

    # texture_plane needs actual image generation, not just any ImageTexture reference
    if scores["texture_plane"] > 0 and not re.search(r'Image\.create|set_pixel|create_from_image', code):
        scores["texture_plane"] = max(0, scores["texture_plane"] - 4)

    # terrain_deformation needs vertex modification, not just PlaneMesh
    if scores["terrain_deformation"] > 0 and not re.search(r'heightmap|height_map|deform|raise_amount|vertex.*\.y', code):
        scores["terrain_deformation"] = max(0, scores["terrain_deformation"] - 3)

    # composed_primitives at minimum score is a fallback — demote if others scored
    if scores["composed_primitives"] <= 3 and max_geometry > scores["composed_primitives"]:
        scores["composed_primitives"] = 0

    best_type = max(scores, key=scores.get)
    best_score = scores[best_type]

    if best_score < 2:
        return "composed_primitives", 0.2

    # Check for hybrid: two geometry types both scoring strongly
    geo_scores = sorted([scores[t] for t in geometry_types], reverse=True)
    if geo_scores[0] > 5 and geo_scores[1] > 5:
        return "hybrid", min(1.0, best_score / 10.0)

    return best_type, min(1.0, best_score / 10.0)


# ══════════════════════════════════════════════════════════════════
# TOPOLOGY DETECTION
# ══════════════════════════════════════════════════════════════════

def detect_topology(code, mesh_type):
    """Infer topology from mesh type and code signals."""
    code_lower = code.lower()

    if mesh_type in ("instanced_particles",):
        return "scattered"
    if mesh_type in ("texture_plane", "shader_driven"):
        return "planar"
    if mesh_type == "boolean_composition":
        return "volumetric"
    if mesh_type == "terrain_deformation":
        return "manifold_open"

    # Check for closed surfaces
    if re.search(r'sphere|torus|klein|closed', code_lower):
        if not re.search(r'open|strip|boundary|edge', code_lower):
            return "manifold_closed"

    # Check for non-manifold (lines, points)
    if mesh_type == "procedural_line":
        return "non_manifold"

    # Check cull mode for open surfaces
    if re.search(r'CULL_DISABLED|cull_mode.*disabled', code):
        return "manifold_open"

    if mesh_type == "parametric_surface":
        return "manifold_open"

    if mesh_type == "composed_primitives":
        return "manifold_closed"

    return "manifold_closed"


# ══════════════════════════════════════════════════════════════════
# MATERIAL DETECTION
# ══════════════════════════════════════════════════════════════════

def detect_material(code):
    """Detect material type and shading model."""
    mat_type = "standard"
    shading = "pbr"
    properties = []

    if re.search(r'ShaderMaterial', code):
        mat_type = "shader"
        shading = "custom_fragment"
    if re.search(r'vertex_color_use_as_albedo', code):
        mat_type = "vertex_color"
    if re.search(r'ImageTexture|create_from_image|set_pixel', code):
        mat_type = "generated_texture"
    if re.search(r'SHADING_MODE_UNSHADED|flags_unshaded', code):
        mat_type = "unlit" if mat_type == "standard" else mat_type
        shading = "unshaded"

    # Detect key properties
    if re.search(r'emission|EMISSION', code):
        properties.append("emission")
        if shading == "pbr":
            shading = "emissive"
    if re.search(r'wireframe|grid.*shader|SimpleGrid', code, re.IGNORECASE):
        shading = "wireframe"
        properties.append("grid_overlay")
    if re.search(r'metallic', code):
        properties.append("metallic")
    if re.search(r'transparency|ALPHA|alpha_scissor', code):
        properties.append("transparency")
    if re.search(r'CULL_DISABLED', code):
        properties.append("double_sided")

    return {
        "type": mat_type,
        "shading_model": shading,
        "key_properties": properties if properties else []
    }


# ══════════════════════════════════════════════════════════════════
# ANIMATION DETECTION
# ══════════════════════════════════════════════════════════════════

def detect_animation(code):
    """Detect animation type."""
    anim_type = "static"
    driven_by = None
    affects = []

    has_process = bool(re.search(r'func _process\(', code))
    has_physics = bool(re.search(r'func _physics_process\(', code))

    if not has_process and not has_physics:
        return {"type": "static", "driven_by": None, "affects": []}

    # Check what the process function does
    if re.search(r'RigidBody|apply_force|apply_impulse|SpringArm', code):
        anim_type = "physics"
        driven_by = "physics_engine"
        affects.append("transform")
    elif re.search(r'MultiMesh.*set_instance_transform|instance_transform', code):
        anim_type = "particle_lifecycle"
        driven_by = "cpu_simulation"
        affects.extend(["transform", "color"])
    elif re.search(r'GPUParticles3D|CPUParticles3D', code):
        anim_type = "particle_lifecycle"
        driven_by = "particle_system"
        affects.extend(["transform", "color", "visibility"])
    elif re.search(r'SurfaceTool|clear_surfaces|surface_begin', code) and has_process:
        anim_type = "vertex"
        driven_by = "per_frame_rebuild"
        affects.append("vertex_positions")
    elif re.search(r'set_shader_parameter.*TIME|time_offset|TIME', code):
        anim_type = "shader_time"
        driven_by = "shader_uniform"
        affects.append("visual")
    elif re.search(r'rotation|position|translate|scale', code) and has_process:
        anim_type = "transform"
        driven_by = "per_frame_update"
        affects.append("transform")
    elif re.search(r'albedo_color|emission_color|modulate', code) and has_process:
        anim_type = "color_cycle"
        driven_by = "per_frame_update"
        affects.append("color")

    return {"type": anim_type, "driven_by": driven_by, "affects": affects}


# ══════════════════════════════════════════════════════════════════
# INSTANCE STRATEGY DETECTION
# ══════════════════════════════════════════════════════════════════

def detect_instance_strategy(code):
    """Detect how many mesh instances are created."""
    if re.search(r'MultiMesh|MultiMeshInstance3D', code):
        return "multimesh"
    if re.search(r'GPUParticles3D|CPUParticles3D', code):
        return "particles"

    # Count MeshInstance3D.new() calls or add_child patterns
    mesh_creates = len(re.findall(r'MeshInstance3D\.new\(\)', code))
    child_adds = len(re.findall(r'add_child\(', code))

    if mesh_creates > 10 or re.search(r'for\s+\w+\s+in\s+range.*MeshInstance', code, re.DOTALL):
        return "array"
    if mesh_creates > 3 or child_adds > 5:
        return "few"
    return "single"


# ══════════════════════════════════════════════════════════════════
# CONSTRUCTION & VERTEX ESTIMATE
# ══════════════════════════════════════════════════════════════════

def detect_construction(code, mesh_type):
    """Infer construction method, primitives, and operations."""
    method = "unknown"
    primitives = []
    operations = []

    if mesh_type == "parametric_surface":
        method = "uv_grid_triangulation"
        operations = ["compute_vertices", "generate_triangles", "compute_normals"]
    elif mesh_type == "procedural_line":
        method = "vertex_line_strip"
        operations = ["compute_vertices", "connect_lines"]
        if re.search(r'l.system|rewrite|axiom|rule', code, re.IGNORECASE):
            method = "l_system_turtle"
            operations = ["string_rewrite", "turtle_interpret", "emit_lines"]
    elif mesh_type == "texture_plane":
        method = "pixel_computation"
        operations = ["create_image", "compute_pixels", "apply_texture"]
    elif mesh_type == "boolean_composition":
        method = "csg_boolean"
        operations = ["create_primitives", "position_primitives", "boolean_combine"]
    elif mesh_type == "instanced_particles":
        method = "multimesh_instancing"
        operations = ["allocate_instances", "set_transforms", "update_per_frame"]
    elif mesh_type == "composed_primitives":
        method = "primitive_assembly"
        operations = ["create_primitives", "position_children"]
    elif mesh_type == "shader_driven":
        method = "shader_rendering"
        operations = ["create_base_mesh", "apply_shader", "set_parameters"]
    elif mesh_type == "delegated_scene":
        method = "scene_instantiation"
        operations = ["load_scene", "instantiate", "configure"]
    elif mesh_type == "terrain_deformation":
        method = "heightmap_displacement"
        operations = ["create_plane", "compute_heights", "displace_vertices"]

    # Detect primitives used
    prim_map = {
        r'BoxMesh|CSGBox': "box",
        r'SphereMesh|CSGSphere': "sphere",
        r'CylinderMesh|CSGCylinder': "cylinder",
        r'TorusMesh|CSGTorus': "torus",
        r'PlaneMesh|QuadMesh': "plane",
        r'PrismMesh': "prism",
        r'CapsuleMesh': "capsule",
    }
    for pattern, name in prim_map.items():
        if re.search(pattern, code):
            primitives.append(name)

    return {
        "method": method,
        "primitives": primitives,
        "operations": operations
    }


def estimate_vertex_count(code, mesh_type):
    """Rough order-of-magnitude vertex estimate."""
    if mesh_type == "texture_plane":
        return "~4 (quad)"
    if mesh_type == "shader_driven":
        return "~4-24 (base mesh)"
    if mesh_type == "delegated_scene":
        return "varies"

    # Look for grid/segment dimensions
    segments = re.findall(r'(?:segments?|steps?|subdivid\w*|resolution)\s*[:=]\s*(\d+)', code)
    if segments:
        nums = [int(s) for s in segments]
        if len(nums) >= 2:
            verts = nums[0] * nums[1] * 2
            return f"~{verts}"
        return f"~{nums[0] * nums[0]}"

    # Look for instance counts
    instances = re.findall(r'(?:instance_count|num_particles?|MAX_PARTICLES?|num_points?)\s*[:=]\s*(\d+)', code)
    if instances:
        return f"~{instances[0]} instances"

    # Look for iteration/point counts
    points = re.findall(r'(?:num_points?|count|iterations?)\s*[:=]\s*(\d+)', code)
    if points:
        return f"~{points[0]}"

    return "unknown"


# ══════════════════════════════════════════════════════════════════
# SPEC ASSEMBLER
# ══════════════════════════════════════════════════════════════════

def extract_spec(code):
    """Assemble full geometry_spec from code analysis."""
    mesh_type, confidence = detect_mesh_type(code)
    topology = detect_topology(code, mesh_type)
    material = detect_material(code)
    animation = detect_animation(code)
    instance_strategy = detect_instance_strategy(code)
    construction = detect_construction(code, mesh_type)
    vertex_estimate = estimate_vertex_count(code, mesh_type)

    spec = {
        "mesh_type": mesh_type,
        "topology": topology,
        "construction": construction,
        "material": material,
        "animation": animation,
        "instance_strategy": instance_strategy,
        "vertex_estimate": vertex_estimate,
    }

    return spec, confidence


# ══════════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════════

def main():
    args = sys.argv[1:]
    filter_registry = None
    filter_artifact = None
    save = '--save' in args
    skip_existing = '--skip-existing' in args
    min_confidence = 0.0

    for i, arg in enumerate(args):
        if arg == '--registry' and i + 1 < len(args):
            filter_registry = args[i + 1]
        elif arg == '--artifact' and i + 1 < len(args):
            filter_artifact = args[i + 1]
        elif arg == '--confidence' and i + 1 < len(args):
            min_confidence = float(args[i + 1])

    registries = load_all_registries(filter_registry)

    results = []
    type_counts = {}
    no_script = 0
    skipped = 0

    for reg_file, entries in registries.items():
        reg_name = Path(reg_file).stem
        for lname, entry in entries.items():
            if filter_artifact and filter_artifact != lname:
                continue
            if skip_existing and 'geometry_spec' in entry:
                skipped += 1
                continue

            scene = entry.get('scene', '')
            script_path = resolve_script_path(scene)
            code = read_script_content(script_path)

            if not code or len(code) < 20:
                no_script += 1
                continue

            spec, confidence = extract_spec(code)

            if confidence < min_confidence:
                continue

            results.append({
                'name': lname,
                'key': entry['_key'],
                'registry': reg_name,
                'registry_file': reg_file,
                'spec': spec,
                'confidence': confidence,
            })

            mt = spec['mesh_type']
            type_counts[mt] = type_counts.get(mt, 0) + 1

    # Print summary
    total = len(results)
    print(f"\n  Geometry Spec Extraction — {total} artifacts analyzed")
    if no_script:
        print(f"  ({no_script} skipped: no script found)")
    if skipped:
        print(f"  ({skipped} skipped: already has geometry_spec)")
    print()

    if type_counts:
        print("  Mesh type distribution:")
        for t, c in sorted(type_counts.items(), key=lambda x: -x[1]):
            pct = c / max(total, 1) * 100
            bar = '#' * int(pct / 2)
            print(f"    {t:<25s} {c:>4d} ({pct:4.1f}%) {bar}")
        print()

    # Per-artifact detail
    print("  Per artifact:")
    for r in sorted(results, key=lambda x: (x['registry'], x['spec']['mesh_type'], x['name'])):
        s = r['spec']
        conf = f"{r['confidence']:.0%}"
        mat = s['material']['type']
        anim = s['animation']['type']
        print(f"    {r['name']:<40s} {s['mesh_type']:<25s} {mat:<18s} {anim:<15s} {conf:>5s}  [{r['registry']}]")

    # Low confidence warnings
    low = [r for r in results if r['confidence'] < 0.3]
    if low:
        print(f"\n  Low confidence (<30%): {len(low)} artifacts")
        for r in low:
            print(f"    {r['name']:<40s} {r['confidence']:.0%}")

    # Save to registry if requested
    if save:
        by_file = {}
        for r in results:
            f = r['registry_file']
            if f not in by_file:
                by_file[f] = []
            by_file[f].append(r)

        saved_count = 0
        for reg_file, file_results in by_file.items():
            data = json.loads(Path(reg_file).read_text(encoding='utf-8'))
            for r in file_results:
                key = r['key']
                if key in data.get('artifacts', {}):
                    data['artifacts'][key]['geometry_spec'] = r['spec']
                    saved_count += 1

            with open(reg_file, 'w', encoding='utf-8') as fh:
                json.dump(data, fh, indent='\t', ensure_ascii=False)
                fh.write('\n')

        print(f"\n  Saved geometry_spec to {saved_count} artifacts in {len(by_file)} registry files")


if __name__ == '__main__':
    main()
