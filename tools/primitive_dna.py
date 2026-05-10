"""primitive_dna.py — DNA-style auto-research for Godot primitives.

Companion to chamber.py. Where chamber improves *named* artifacts one at a
time (proposal-without-applying), primitive_dna explores the *parameter
space* of a primitive class (TorusMesh, SphereMesh, …) and surfaces a
gallery of variants. Approved variants graduate to named artifacts.

Storage convention mirrors chamber-runs/:
    ada_encyclopedia/public/primitive-runs/<PrimitiveName>/
        manifest.json     # genome definition + variant index
        variants/<id>.png # one capture per variant

Usage:
    python tools/primitive_dna.py sweep TorusMesh
        # generates a 2D parameter sweep, captures all variants, writes manifest

    python tools/primitive_dna.py list
        # lists primitive runs that exist on disk

The Godot side (commons/testing/capture_primitive_dna.gd) does the actual
rendering. This script generates the input manifest, invokes Godot once,
and copies the captures into the encyclopedia's public/ directory so the
/primitives-dna page can render them.
"""

from __future__ import annotations

import argparse
import datetime
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parents[1]
ENCY = REPO.parent / "ada_encyclopedia"
PRIMITIVE_RUNS = ENCY / "public" / "primitive-runs"
GODOT_EXE = "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"
CAPTURE_SCRIPT = "res://commons/testing/capture_primitive_dna.gd"

# ── Genome definitions ──────────────────────────────────────────────────
#
# Each genome describes a primitive's parameter space and a default 2D
# sweep that covers the interesting range. Values picked to span "barely
# recognizable as X" → "smooth canonical X".

GENOMES: dict[str, dict[str, Any]] = {
    "TorusMesh": {
        "fixed": {
            "inner_radius": 0.18,
            "outer_radius": 0.40,
        },
        "axes": {
            "rings":         [3, 4, 5, 6, 8, 12, 16, 24],
            "ring_segments": [3, 4, 5, 6, 8, 12, 16, 24],
        },
        "camera":   {"yaw_deg": 25.0, "pitch_deg": 25.0, "pad": 1.6},
        "material": {
            "base_color":         [0.62, 0.65, 0.74, 1.0],
            "line_color":         [0.95, 0.40, 0.45, 1.0],
            "shader":             "parametric",
            # TorusMesh UV: u = around major axis, v = around tube cross-section.
            "line_count_axes":    {"u": "rings", "v": "ring_segments"},
            "line_count_defaults": {"u": 8, "v": 8},
        },
        "image":    {"width": 384, "height": 384},
        "truth":    "a torus is a 2D parameter space; rings × ring_segments names which corner the eye reads as 'donut'",
    },
    "SphereMesh": {
        "fixed": {
            "radius": 0.30,
            "height": 0.60,
        },
        "axes": {
            "rings":           [2, 3, 4, 6, 8, 12, 16, 24],
            "radial_segments": [3, 4, 5, 6, 8, 12, 16, 24],
        },
        "camera":   {"yaw_deg": 25.0, "pitch_deg": 25.0, "pad": 1.5},
        "material": {
            "base_color":         [0.62, 0.65, 0.74, 1.0],
            "line_color":         [0.95, 0.40, 0.45, 1.0],
            "shader":             "parametric",
            # SphereMesh UV: u = longitude (around), v = latitude (top->bottom).
            "line_count_axes":    {"u": "radial_segments", "v": "rings"},
            "line_count_defaults": {"u": 8, "v": 8},
        },
        "image":    {"width": 384, "height": 384},
        "truth":    "a sphere is what the eye calls a polyhedron once both axes have enough segments",
    },
    "CapsuleMesh": {
        "fixed": {
            "radius": 0.20,
        },
        "axes": {
            "height":          [0.40, 0.50, 0.65, 0.80, 1.00, 1.30, 1.60, 2.00],
            "radial_segments": [3, 4, 5, 6, 8, 12, 16, 24],
        },
        "camera":   {"yaw_deg": 25.0, "pitch_deg": 15.0, "pad": 1.5},
        "material": {
            "base_color":         [0.62, 0.65, 0.74, 1.0],
            "line_color":         [0.95, 0.40, 0.45, 1.0],
            "shader":             "parametric",
            # CapsuleMesh UV: u = longitude. Height is geometric, not
            # segment-count, so v stays at default to read the proportion.
            "line_count_axes":    {"u": "radial_segments"},
            "line_count_defaults": {"u": 8, "v": 6},
        },
        "image":    {"width": 384, "height": 512},
        "truth":    "a capsule is a sphere stretched along an axis; height vs segments names which 'pill' you mean",
    },
    "BoxMesh": {
        "fixed": {},
        "axes": {
            "subdivide_width": [0, 1, 2, 4, 8],
            "subdivide_depth": [0, 1, 2, 4, 8],
        },
        "camera":   {"yaw_deg": 25.0, "pitch_deg": 25.0, "pad": 1.6},
        "material": {
            "base_color":         [0.62, 0.65, 0.74, 1.0],
            "line_color":         [0.95, 0.40, 0.45, 1.0],
            "shader":             "parametric",
            # BoxMesh UVs are per-face. The parametric grid will paint each
            # face with the same N×M but the visual *meaning* is "this is
            # how many subdivisions exist along each axis." Map the actual
            # subdivisions to grid lines (+1 because N subdivisions = N+1 lines).
            "line_count_axes":    {"u": "subdivide_width", "v": "subdivide_depth"},
            "line_count_defaults": {"u": 2, "v": 2},
        },
        "image":    {"width": 384, "height": 384},
        "truth":    "a box subdivided is still a box; its DNA is in what you do with the extra vertices",
    },
    "CylinderMesh": {
        "fixed": {
            "top_radius": 0.30,
            "bottom_radius": 0.30,
            "height": 0.80,
        },
        "axes": {
            "rings":           [0, 1, 2, 4, 8, 16],
            "radial_segments": [3, 4, 5, 6, 8, 12, 16, 24],
        },
        "camera":   {"yaw_deg": 25.0, "pitch_deg": 18.0, "pad": 1.5},
        "material": {
            "base_color":         [0.62, 0.65, 0.74, 1.0],
            "line_color":         [0.95, 0.40, 0.45, 1.0],
            "shader":             "parametric",
            "line_count_axes":    {"u": "radial_segments", "v": "rings"},
            "line_count_defaults": {"u": 8, "v": 1},
        },
        "image":    {"width": 384, "height": 480},
        "truth":    "a cylinder is what a prism becomes when you stop counting sides; segments=3 is a triangular prism, segments=24 is the eye giving up",
    },
    "PrismMesh": {
        "fixed": {
            "size":          [0.6, 0.6, 0.6],
        },
        "axes": {
            "left_to_right":     [0.0, 0.25, 0.5, 0.75, 1.0],
            "subdivide_width":   [0, 1, 2, 4],
        },
        "camera":   {"yaw_deg": 25.0, "pitch_deg": 25.0, "pad": 1.6},
        "material": {
            "base_color":         [0.62, 0.65, 0.74, 1.0],
            "line_color":         [0.95, 0.40, 0.45, 1.0],
            "shader":             "parametric",
            "line_count_axes":    {"u": "subdivide_width"},
            "line_count_defaults": {"u": 2, "v": 4},
        },
        "image":    {"width": 384, "height": 384},
        "truth":    "a prism is a wedge with one parameter to slide between right-angled and centered — left_to_right is the asymmetry of cut",
    },
}


def _short(p: Path) -> str:
    try:
        return str(p.relative_to(REPO))
    except ValueError:
        return str(p)


def _build_sweep(genome: dict[str, Any]) -> list[dict[str, Any]]:
    """Cartesian product of every axis combined with the fixed params."""
    axes: dict[str, list] = genome["axes"]
    fixed: dict = genome.get("fixed", {})
    axis_names = list(axes.keys())
    if len(axis_names) != 2:
        raise NotImplementedError(
            "Only 2-axis sweeps are supported in this first cut "
            "(got %d axes)" % len(axis_names)
        )
    a, b = axis_names
    variants = []
    for av in axes[a]:
        for bv in axes[b]:
            params = dict(fixed)
            params[a] = av
            params[b] = bv
            # ID like "rings4_segments6" — readable, sortable, filename-safe
            vid = f"{a}{av}_{b}{bv}".replace(".", "p").replace("-", "n")
            variants.append({
                "id": vid,
                "params": params,
                "axes": {a: av, b: bv},
            })
    return variants


def cmd_sweep(args) -> int:
    name = args.primitive
    if name not in GENOMES:
        print(f"  !! unknown primitive '{name}'", file=sys.stderr)
        print(f"     known: {', '.join(sorted(GENOMES.keys()))}", file=sys.stderr)
        return 1

    if not Path(GODOT_EXE).exists():
        print(f"  !! Godot exe not found: {GODOT_EXE}", file=sys.stderr)
        return 1

    if not ENCY.exists():
        print(f"  !! encyclopedia not found at {ENCY}", file=sys.stderr)
        return 1

    genome = GENOMES[name]
    variants = _build_sweep(genome)
    print(f"primitive_dna sweep: {name} ({len(variants)} variants)")
    print(f"  axes: {list(genome['axes'].keys())}")

    # Manifest the Godot side reads.
    manifest_in = {
        "primitive": name,
        "material": genome.get("material", {}),
        "camera":   genome.get("camera", {}),
        "image":    genome.get("image", {}),
        "variants": variants,
    }

    # Write to user:// so Godot can read it. We use a stable filename so a
    # rerun overwrites cleanly.
    user_data = (
        Path(os.environ.get("APPDATA", ""))
        / "Godot/app_userdata/Ada Research Zero One"
    )
    dna_in = user_data / "primitive_dna_in"
    dna_out = user_data / "primitive_dna_out" / name
    dna_in.mkdir(parents=True, exist_ok=True)
    if dna_out.exists():
        shutil.rmtree(dna_out)
    dna_out.mkdir(parents=True, exist_ok=True)

    manifest_path = dna_in / f"{name}.json"
    manifest_path.write_text(json.dumps(manifest_in, indent=2), encoding="utf-8")
    print(f"  manifest: {manifest_path}")

    # Run Godot.
    print(f"  godot:    capturing {len(variants)} variants...")
    cmd = [
        GODOT_EXE,
        "--path", str(REPO),
        "--xr-mode", "off",
        "--no-window",
        "--script", CAPTURE_SCRIPT, "--",
        f"--manifest=user://primitive_dna_in/{name}.json",
        f"--out=user://primitive_dna_out/{name}",
    ]
    try:
        result = subprocess.run(
            cmd, check=False, capture_output=True, text=True, timeout=600
        )
        if result.returncode != 0:
            print(f"    !! godot exited {result.returncode}", file=sys.stderr)
            print(result.stderr[-2000:] if result.stderr else "(no stderr)",
                  file=sys.stderr)
    except subprocess.TimeoutExpired:
        print("    !! godot timed out (10 min)", file=sys.stderr)
        return 1

    # Read the summary Godot wrote.
    summary_path = dna_out / "summary.json"
    if not summary_path.exists():
        print(f"    !! no summary.json — capture probably failed", file=sys.stderr)
        return 1
    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    print(f"  saved:    {summary['saved']}/{len(variants)} variants")

    # Copy the captures into the encyclopedia's public folder.
    target_dir = PRIMITIVE_RUNS / name
    target_variants = target_dir / "variants"
    target_variants.mkdir(parents=True, exist_ok=True)

    copied = 0
    for vid in summary["ids"]:
        src = dna_out / f"{vid}.png"
        if src.exists():
            shutil.copy(str(src), str(target_variants / f"{vid}.png"))
            copied += 1

    # Write the public-side manifest (what the page reads).
    public_manifest = {
        "primitive":    name,
        "axes":         genome["axes"],
        "fixed":        genome.get("fixed", {}),
        "image_size":   summary.get("image_size", [384, 384]),
        "truth":        genome.get("truth", ""),
        "generated_at": datetime.datetime.now().isoformat(timespec="seconds"),
        "variants":     [
            {
                "id":     v["id"],
                "params": v["params"],
                "axes":   v["axes"],
                "captured": v["id"] in summary["ids"],
            }
            for v in variants
        ],
    }
    (target_dir / "manifest.json").write_text(
        json.dumps(public_manifest, indent=2), encoding="utf-8"
    )

    print(f"  public:   {_short(target_dir)} — {copied} PNGs")
    print(f"  view:     http://localhost:3003/primitives-dna/{name}")
    return 0


def cmd_promote(args) -> int:
    """Promote a primitive variant to a named artifact.

    Two modes:
      single — primitive variant from --params (one MeshInstance3D in scene)
      compose — composition spec from --compose=<file.json> (multiple
                MeshInstance3D children, each with its own primitive +
                params + transform)

    Generates a thin .tscn at commons/primitives/promoted/<token>/<token>.tscn
    plus a registry entry in commons/artifacts/registry/promoted.json.
    """
    # Compose mode: read spec from JSON file.
    if args.compose:
        return _cmd_promote_compose(args)
    return _cmd_promote_single(args)


def _cmd_promote_compose(args) -> int:
    """Composition mode: build a multi-primitive .tscn from a JSON spec.

    Spec format:
      {
        "primitive": "Composition",      // sentinel
        "shader": "edges" | "parametric",
        "color": [r, g, b],
        "components": [
          {
            "primitive": "CylinderMesh",
            "params": { "top_radius": 0.4, "bottom_radius": 0.4, "height": 0.2, ... },
            "transform": { "position": [0, 0.1, 0], "rotation_degrees": [0, 0, 0] }
          },
          ...
        ]
      }
    """
    token = args.as_token
    spec_path = Path(args.compose)
    if not spec_path.exists():
        print(f"  !! compose spec not found: {spec_path}", file=sys.stderr)
        return 1
    spec = json.loads(spec_path.read_text(encoding="utf-8"))

    components = spec.get("components", [])
    if not components:
        print(f"  !! compose spec has no components", file=sys.stderr)
        return 1

    shader_choice = spec.get("shader", args.shader or "edges")
    color = spec.get("color", [0.6, 0.0, 0.8])
    base_color = list(color[:3]) + [1.0]

    scene_dir = REPO / "commons" / "primitives" / "promoted" / token
    scene_path = scene_dir / f"{token}.tscn"
    if scene_path.exists() and not args.force:
        print(f"  !! {_short(scene_path)} already exists (use --force)",
              file=sys.stderr)
        return 1
    scene_dir.mkdir(parents=True, exist_ok=True)

    scene_text = _render_compose_scene(spec, base_color, shader_choice, token)
    scene_path.write_text(scene_text, encoding="utf-8")
    print(f"  scene:    {_short(scene_path)} ({len(components)} components)")

    # Registry entry.
    reg_path = REPO / "commons" / "artifacts" / "registry" / "promoted.json"
    if reg_path.exists():
        reg = json.loads(reg_path.read_text(encoding="utf-8"))
    else:
        reg = {"artifacts": {}}
    reg.setdefault("artifacts", {})[token] = {
        "category":      "primitives",
        "complexity":    "beginner",
        "description":   f"Composition of {len(components)} primitives",
        "footprint":     [1, 1, 1],
        "include_in_map_data": True,
        "lookup_name":   token,
        "map_ready":     True,
        "map_sequences": [],
        "name":          token,
        "promoted_from": {
            "kind":       "composition",
            "n_components": len(components),
            "shader":     shader_choice,
            "spec_file":  str(spec_path),
        },
        "scene":         f"res://commons/primitives/promoted/{token}/{token}.tscn",
    }
    reg_path.parent.mkdir(parents=True, exist_ok=True)
    reg_path.write_text(json.dumps(reg, indent=2), encoding="utf-8")
    print(f"  registry: {_short(reg_path)}")

    print()
    print("Verify with:")
    print(f"  godot --xr-mode off --no-window --script "
          f"res://commons/testing/capture_multi_angle.gd "
          f"-- --mode=artifact --target={token}")
    return 0


def _format_transform3d(pos: list[float], rot_deg: list[float],
                         scale: list[float] | None = None) -> str:
    """Build a Transform3D() literal from position + Euler rotation (degrees).

    Order is YXZ (Godot's default Euler order for Vector3 rotations). Each
    rotation matrix is composed: R = Ry * Rx * Rz, then transposed to get
    basis columns since Transform3D stores basis as (col0, col1, col2).
    """
    import math
    rx = math.radians(rot_deg[0])
    ry = math.radians(rot_deg[1])
    rz = math.radians(rot_deg[2])
    cx, sx = math.cos(rx), math.sin(rx)
    cy, sy = math.cos(ry), math.sin(ry)
    cz, sz = math.cos(rz), math.sin(rz)

    # Y-axis rotation
    Ry = [[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]]
    # X-axis rotation
    Rx = [[1, 0, 0], [0, cx, -sx], [0, sx, cx]]
    # Z-axis rotation
    Rz = [[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]]

    def matmul(A, B):
        return [[sum(A[i][k] * B[k][j] for k in range(3)) for j in range(3)] for i in range(3)]

    # YXZ Euler: R = Ry * Rx * Rz
    R = matmul(matmul(Ry, Rx), Rz)

    # Optional non-uniform scale via the 4th argument (defaults to [1,1,1]).
    # We bake scale INTO the basis columns: column j multiplied by scale[j].
    sx_, sy_, sz_ = (scale if scale else [1.0, 1.0, 1.0])

    # Godot Transform3D(xx, xy, xz, yx, yy, yz, zx, zy, zz, ox, oy, oz) is
    # ROW-MAJOR (verified in Godot source: Basis::set assigns args to
    # rows[i][j] in order). So we iterate row-outer, column-inner.
    # Without scale this produces R as written; with scale, column j
    # is multiplied by scale[j] (so the j-th column = j-th basis vector
    # is scaled).
    parts = []
    col_scales = [sx_, sy_, sz_]
    for i in range(3):  # row index
        for j in range(3):  # column index
            parts.append(f"{R[i][j] * col_scales[j]:.6f}")
    parts.extend([f"{pos[0]}", f"{pos[1]}", f"{pos[2]}"])
    return f"transform = Transform3D({', '.join(parts)})"


def _render_compose_scene_flat(
        spec: dict[str, Any],
        base_color: list[float],
        token: str,
        ) -> str:
    """Compose .tscn with StandardMaterial3D per component."""
    components = spec.get("components", [])
    n_comp = len(components)

    component_colors: list[list[float]] = []
    for comp in components:
        c = comp.get("color")
        if c is None:
            cc = list(base_color[:3]) + [1.0]
        else:
            cc = list(c[:3]) + [float(c[3]) if len(c) > 3 else 1.0]
        component_colors.append(cc)

    mesh_blocks: list[str] = []
    for i, comp in enumerate(components):
        primitive = comp["primitive"]
        params = comp.get("params", {})
        param_lines = []
        for k, v in params.items():
            if isinstance(v, float):
                param_lines.append(f"{k} = {v:.6f}")
            elif isinstance(v, list) and len(v) == 3:
                param_lines.append(f"{k} = Vector3({v[0]}, {v[1]}, {v[2]})")
            elif isinstance(v, list) and len(v) == 2:
                param_lines.append(f"{k} = Vector2({v[0]}, {v[1]})")
            else:
                param_lines.append(f"{k} = {v}")
        mesh_blocks.append(
            f'[sub_resource type="{primitive}" id="Mesh_{i}"]\n'
            + "\n".join(param_lines)
        )

    mat_blocks: list[str] = []
    for i, color in enumerate(component_colors):
        r, g, b, a = color[0], color[1], color[2], color[3]
        mat_blocks.append(
            f'[sub_resource type="StandardMaterial3D" id="Mat_{i}"]\n'
            f'albedo_color = Color({r}, {g}, {b}, {a})\n'
            f'emission_enabled = true\n'
            f'emission = Color({r * 0.3}, {g * 0.3}, {b * 0.3}, 1.0)\n'
            f'metallic = 0.0\n'
            f'roughness = 0.5'
        )

    node_blocks: list[str] = []
    for i, comp in enumerate(components):
        transform = comp.get("transform", {})
        pos = transform.get("position", [0, 0, 0])
        rot_deg = transform.get("rotation_degrees", [0, 0, 0])
        scale = transform.get("scale", [1, 1, 1])
        node_lines = [
            f'[node name="Part{i}" type="MeshInstance3D" parent="."]',
            f'mesh = SubResource("Mesh_{i}")',
            f'material_override = SubResource("Mat_{i}")',
        ]
        if pos != [0, 0, 0] or rot_deg != [0, 0, 0] or scale != [1, 1, 1]:
            node_lines.append(_format_transform3d(pos, rot_deg, scale))
        node_blocks.append("\n".join(node_lines))

    load_steps = n_comp * 2 + 1  # n meshes + n materials + node tree

    return f"""[gd_scene load_steps={load_steps} format=3]

; Promoted composition: {token} ({n_comp} components, flat-shaded)
; Source: primitive_dna.py promote --compose=<spec> --shader=flat --as={token}
;
; Flat StandardMaterial3D per component — no edge highlighting.
; Used when the goal is silhouette fidelity and CylinderMesh's internal
; triangulation would otherwise show through with edge shaders.

{chr(10).join(mesh_blocks)}

{chr(10).join(mat_blocks)}

[node name="{token.title().replace('_', '')}" type="Node3D"]

{chr(10).join(node_blocks)}
"""


def _render_scene_flat(
        primitive: str,
        params: dict[str, Any],
        base_color: list[float],
        token: str,
        ) -> str:
    """Single-primitive .tscn with StandardMaterial3D — no edge shader.

    Used when the goal is silhouette fidelity and the artifact's edges
    aren't part of the teaching. Removes the "internal triangulation
    showing through" problem that CylinderMesh-as-tetrahedron etc. suffers
    with edge-highlighting shaders.
    """
    mesh_lines: list[str] = []
    for k, v in params.items():
        if isinstance(v, float):
            mesh_lines.append(f"{k} = {v:.6f}")
        elif isinstance(v, list) and len(v) == 3:
            mesh_lines.append(f"{k} = Vector3({v[0]}, {v[1]}, {v[2]})")
        elif isinstance(v, list) and len(v) == 2:
            mesh_lines.append(f"{k} = Vector2({v[0]}, {v[1]})")
        else:
            mesh_lines.append(f"{k} = {v}")
    mesh_block = "\n".join(mesh_lines)

    r, g, b, a = base_color[0], base_color[1], base_color[2], base_color[3]
    node_name = token.title().replace('_', '')
    return f"""[gd_scene load_steps=3 format=3]

; Promoted artifact: {token}
; Source: primitive_dna.py promote {primitive} --shader=flat --as={token}
;
; Flat material: no edge shader. Pure albedo + soft emission.
; Hides CylinderMesh's internal triangulation when the original was
; rendered with flat shading too. Trade-off: loses the wireframe-grid
; teaching pedagogy that --shader=edges or --shader=parametric provides.

[sub_resource type="{primitive}" id="MeshRes"]
{mesh_block}

[sub_resource type="StandardMaterial3D" id="MatRes"]
albedo_color = Color({r}, {g}, {b}, {a})
emission_enabled = true
emission = Color({r * 0.3}, {g * 0.3}, {b * 0.3}, 1.0)
metallic = 0.0
roughness = 0.5

[node name="{node_name}" type="Node3D"]

[node name="Mesh" type="MeshInstance3D" parent="."]
mesh = SubResource("MeshRes")
material_override = SubResource("MatRes")
"""


def _render_compose_scene(
        spec: dict[str, Any],
        base_color: list[float],
        shader_choice: str,
        token: str,
        ) -> str:
    """Render a composition .tscn — multiple MeshInstance3D children, each
    with its own optional per-component color. Components without a color
    override share a single global ShaderMaterial; components with a
    `color` field get their own ShaderMaterial sub-resource so the
    artifact's surface pattern (stripes, gradients, alternating fills)
    transfers from the hand-coded original."""
    components = spec.get("components", [])
    n_comp = len(components)

    if shader_choice == "flat":
        return _render_compose_scene_flat(spec, base_color, token)

    if shader_choice == "parametric":
        shader_path = "res://commons/resourses/shaders/ParametricGrid.gdshader"
    else:
        shader_path = "res://commons/resourses/shaders/SimpleGrid.gdshader"

    def _shader_uniform_block(color: list[float]) -> str:
        a = color[3] if len(color) > 3 else 1.0
        if shader_choice == "parametric":
            return (
                f'shader_parameter/fill_color = Color({color[0]}, {color[1]}, {color[2]}, {a})\n'
                f'shader_parameter/line_color = Color(1, 1, 1, 1)\n'
                f'shader_parameter/lines_u = 8\n'
                f'shader_parameter/lines_v = 4\n'
                f'shader_parameter/line_width = 0.02\n'
                f'shader_parameter/emission = 1.2\n'
                f'shader_parameter/show_mesh_edges = false\n'
                f'shader_parameter/mesh_edge_alpha = 0.15'
            )
        else:
            # SimpleGrid quirks:
            #  - emissionColor defaults to RED; need to set it = modelColor
            #    so per-component colors emit their own color, not red.
            #  - width=2.0 makes wireframe dominate the surface; lowering
            #    to 1.0 gives the surface a chance to show its color.
            #  - emission_strength=2.0 saturates everything; 1.0 is enough.
            return (
                f'shader_parameter/modelColor = Color({color[0]}, {color[1]}, {color[2]}, {a})\n'
                f'shader_parameter/wireframeColor = Color(1, 1, 1, 1)\n'
                f'shader_parameter/emissionColor = Color({color[0]}, {color[1]}, {color[2]}, {a})\n'
                f'shader_parameter/width = 1.0\n'
                f'shader_parameter/emission_strength = 1.0\n'
                f'shader_parameter/show_interior = true'
            )

    # Collect per-component colors. Components without their own color
    # share a single "global" material (Mat_global) — saves sub-resources
    # in the common case where everything matches.
    component_colors: list[list[float] | None] = []
    needs_global = False
    for comp in components:
        c = comp.get("color")
        if c is None:
            component_colors.append(None)
            needs_global = True
        else:
            cc = list(c[:3]) + [float(c[3]) if len(c) > 3 else 1.0]
            component_colors.append(cc)

    # Build mesh sub-resources.
    mesh_blocks: list[str] = []
    for i, comp in enumerate(components):
        primitive = comp["primitive"]
        params = comp.get("params", {})
        param_lines = []
        for k, v in params.items():
            if isinstance(v, float):
                param_lines.append(f"{k} = {v:.6f}")
            elif isinstance(v, list):
                if len(v) == 3:
                    param_lines.append(f"{k} = Vector3({v[0]}, {v[1]}, {v[2]})")
                elif len(v) == 2:
                    param_lines.append(f"{k} = Vector2({v[0]}, {v[1]})")
            else:
                param_lines.append(f"{k} = {v}")
        mesh_blocks.append(
            f'[sub_resource type="{primitive}" id="Mesh_{i}"]\n'
            + "\n".join(param_lines)
        )

    # Build material sub-resources. One global material if any component
    # didn't supply a color, plus one per-component material for those
    # that did.
    mat_blocks: list[str] = []
    if needs_global:
        mat_blocks.append(
            f'[sub_resource type="ShaderMaterial" id="Mat_global"]\n'
            f'shader = ExtResource("1_shader")\n'
            f'{_shader_uniform_block(base_color)}'
        )
    for i, color in enumerate(component_colors):
        if color is not None:
            mat_blocks.append(
                f'[sub_resource type="ShaderMaterial" id="Mat_{i}"]\n'
                f'shader = ExtResource("1_shader")\n'
                f'{_shader_uniform_block(color)}'
            )

    # Build node blocks. Each node references the right material — its
    # own per-component Mat_i if it has one, otherwise the global.
    node_blocks: list[str] = []
    for i, comp in enumerate(components):
        transform = comp.get("transform", {})
        pos = transform.get("position", [0, 0, 0])
        rot_deg = transform.get("rotation_degrees", [0, 0, 0])
        scale = transform.get("scale", [1, 1, 1])
        mat_id = f"Mat_{i}" if component_colors[i] is not None else "Mat_global"
        node_lines = [
            f'[node name="Part{i}" type="MeshInstance3D" parent="."]',
            f'mesh = SubResource("Mesh_{i}")',
            f'material_override = SubResource("{mat_id}")',
        ]
        if pos != [0, 0, 0] or rot_deg != [0, 0, 0] or scale != [1, 1, 1]:
            node_lines.append(_format_transform3d(pos, rot_deg, scale))
        node_blocks.append("\n".join(node_lines))

    # Recompute load_steps: 1 ext_resource + n_comp meshes + n_mats
    load_steps = 1 + n_comp + len(mat_blocks)

    return f"""[gd_scene load_steps={load_steps} format=3]

; Promoted composition: {token} ({n_comp} components)
; Source: primitive_dna.py promote --compose={spec.get('_spec_file', '<spec>')} --as={token}
;
; Each component below is a MeshInstance3D child of a shared Node3D
; root. Components can specify their own `color` in the spec to get a
; per-component ShaderMaterial; otherwise they share Mat_global. This
; lets compositions reproduce the surface patterns (stripes, alternating
; fills) of the hand-coded artifacts they replace.

[ext_resource type="Shader" path="{shader_path}" id="1_shader"]

{chr(10).join(mesh_blocks)}

{chr(10).join(mat_blocks)}

[node name="{token.title().replace('_', '')}" type="Node3D"]

{chr(10).join(node_blocks)}
"""


def _cmd_promote_single(args) -> int:
    """Single-primitive mode (original behavior)."""
    primitive = args.primitive
    if primitive not in GENOMES:
        print(f"  !! unknown primitive '{primitive}'", file=sys.stderr)
        return 1

    token = args.as_token
    if not token or not token.replace("_", "").isalnum():
        print(f"  !! invalid --as=<token>: '{token}' (alphanumeric + underscores)",
              file=sys.stderr)
        return 1

    # Parse param overrides from the CLI: --params radius=0.424 height=0.8 ...
    # Vector3 syntax: size=1.0,1.0,1.0 (3 comma-separated floats → Vector3 list)
    params: dict[str, Any] = {}
    for kv in args.params or []:
        if "=" not in kv:
            print(f"  !! malformed --params token '{kv}' (need key=value)",
                  file=sys.stderr)
            return 1
        k, v = kv.split("=", 1)
        if "," in v:
            # Strip optional brackets, then parse as comma-separated numbers.
            v_clean = v.strip("[]()")
            parts = v_clean.split(",")
            try:
                vec = [float(p) for p in parts]
                params[k] = vec  # _render_scene converts list[3] → Vector3
            except ValueError:
                params[k] = v
        elif v.lstrip("-").isdigit():
            params[k] = int(v)
        else:
            try:
                params[k] = float(v)
            except ValueError:
                params[k] = v
    if not params:
        print(f"  !! --params required (e.g. --params rings=2 radial_segments=4)",
              file=sys.stderr)
        return 1

    shader_choice = args.shader  # "edges" or "parametric"

    # Derive parametric-grid line counts from the genome's line_count_axes
    # mapping, so a promoted SphereMesh(rings=2, radial_segments=4) gets
    # lines_u=4 lines_v=2 — exactly matching the actual edge structure.
    # Caller can override with --lines-u / --lines-v.
    lines_u: int = 8
    lines_v: int = 8
    genome_material = GENOMES[primitive].get("material", {})
    line_axes = genome_material.get("line_count_axes", {})
    line_defaults = genome_material.get("line_count_defaults", {"u": 8, "v": 8})
    u_axis_name = line_axes.get("u", "")
    v_axis_name = line_axes.get("v", "")
    if u_axis_name and u_axis_name in params:
        lines_u = int(params[u_axis_name])
    else:
        lines_u = int(line_defaults.get("u", 8))
    if v_axis_name and v_axis_name in params:
        lines_v = int(params[v_axis_name])
    else:
        lines_v = int(line_defaults.get("v", 8))
    if args.lines_u is not None:
        lines_u = args.lines_u
    if args.lines_v is not None:
        lines_v = args.lines_v
    lines_u = max(1, min(64, lines_u))
    lines_v = max(1, min(64, lines_v))

    color = args.color or "0.6,0.0,0.8"
    color_parts = [float(x) for x in color.split(",")]
    if len(color_parts) < 3:
        print(f"  !! --color needs 3 floats (r,g,b)", file=sys.stderr)
        return 1
    base_color = list(color_parts[:3]) + [1.0]

    # Output paths.
    scene_dir = REPO / "commons" / "primitives" / "promoted" / token
    scene_path = scene_dir / f"{token}.tscn"
    if scene_path.exists() and not args.force:
        print(f"  !! {_short(scene_path)} already exists (use --force to overwrite)",
              file=sys.stderr)
        return 1
    scene_dir.mkdir(parents=True, exist_ok=True)

    # Build the .tscn text.
    scene_text = _render_scene(primitive, params, base_color, shader_choice, token,
                                lines_u, lines_v)
    scene_path.write_text(scene_text, encoding="utf-8")
    print(f"  scene:    {_short(scene_path)}")

    # Update registry.
    reg_path = REPO / "commons" / "artifacts" / "registry" / "promoted.json"
    if reg_path.exists():
        reg = json.loads(reg_path.read_text(encoding="utf-8"))
    else:
        reg = {"artifacts": {}}
    reg.setdefault("artifacts", {})[token] = {
        "category":      "primitives",
        "complexity":    "beginner",
        "description":   f"{primitive} promoted to named artifact: {dict(params)}",
        "footprint":     [1, 1, 1],
        "include_in_map_data": True,
        "lookup_name":   token,
        "map_ready":     True,
        "map_sequences": [],
        "name":          token,
        "promoted_from": {
            "primitive": primitive,
            "params":    dict(params),
            "shader":    shader_choice,
        },
        "scene":         f"res://commons/primitives/promoted/{token}/{token}.tscn",
    }
    reg_path.parent.mkdir(parents=True, exist_ok=True)
    reg_path.write_text(json.dumps(reg, indent=2), encoding="utf-8")
    print(f"  registry: {_short(reg_path)}")

    print()
    print("Verify with:")
    print(f"  godot --xr-mode off --no-window --script "
          f"res://commons/testing/capture_multi_angle.gd "
          f"-- --mode=artifact --target={token}")
    return 0


def _render_scene(
        primitive: str,
        params: dict[str, Any],
        base_color: list[float],
        shader_choice: str,
        token: str,
        lines_u: int = 8,
        lines_v: int = 8,
        ) -> str:
    """Render a minimal .tscn for the promoted artifact."""
    # Build PrimitiveMesh sub-resource lines.
    mesh_lines: list[str] = []
    for k, v in params.items():
        if isinstance(v, float):
            mesh_lines.append(f"{k} = {v:.6f}")
        elif isinstance(v, list) and len(v) == 3:
            mesh_lines.append(f"{k} = Vector3({v[0]}, {v[1]}, {v[2]})")
        elif isinstance(v, list) and len(v) == 2:
            mesh_lines.append(f"{k} = Vector2({v[0]}, {v[1]})")
        else:
            mesh_lines.append(f"{k} = {v}")
    mesh_block = "\n".join(mesh_lines)

    # Shader / material strategy.
    if shader_choice == "flat":
        # No shader — StandardMaterial3D. No edge highlighting, so
        # CylinderMesh's internal triangulation doesn't show through.
        # Best for promotions where silhouette is the goal and the
        # original used flat shading too (bipyramid, diamond, tetrahedron).
        return _render_scene_flat(primitive, params, base_color, token)

    if shader_choice == "parametric":
        shader_path = "res://commons/resourses/shaders/ParametricGrid.gdshader"
        shader_uniforms = (
            f'shader_parameter/fill_color = Color({base_color[0]}, {base_color[1]}, {base_color[2]}, {base_color[3]})\n'
            f'shader_parameter/line_color = Color(1, 1, 1, 1)\n'
            f'shader_parameter/lines_u = {lines_u}\n'
            f'shader_parameter/lines_v = {lines_v}\n'
            f'shader_parameter/line_width = 0.02\n'
            f'shader_parameter/emission = 1.2\n'
            f'shader_parameter/show_mesh_edges = false\n'
            f'shader_parameter/mesh_edge_alpha = 0.15'
        )
    else:
        # SimpleGrid path — uses camelCase uniform names.
        # Same emission fix as compose mode: shader's emissionColor uniform
        # defaults to RED, which dominates at strength=2.0. Set it to match
        # modelColor and lower strength so the actual color shows through.
        shader_path = "res://commons/resourses/shaders/SimpleGrid.gdshader"
        shader_uniforms = (
            f'shader_parameter/modelColor = Color({base_color[0]}, {base_color[1]}, {base_color[2]}, {base_color[3]})\n'
            f'shader_parameter/wireframeColor = Color(1, 1, 1, 1)\n'
            f'shader_parameter/emissionColor = Color({base_color[0]}, {base_color[1]}, {base_color[2]}, {base_color[3]})\n'
            f'shader_parameter/width = 1.0\n'
            f'shader_parameter/emission_strength = 1.0\n'
            f'shader_parameter/show_interior = true'
        )

    node_name = token.title().replace('_', '')
    return f"""[gd_scene load_steps=4 format=3]

; Promoted artifact: {token}
; Source: primitive_dna.py promote {primitive} --as={token} --params {params}
;
; This scene is generated. The hand-coded primitive it replaces (if any)
; lives in commons/primitives/<original>/. After verification, the
; original .gd / .tscn pair can be retired.
;
; Structure: Node3D root with a MeshInstance3D child — matches the
; convention used by hand-coded primitives so the artifact catalog and
; capture pipeline both treat it identically.

[ext_resource type="Shader" path="{shader_path}" id="1_shader"]

[sub_resource type="{primitive}" id="MeshRes"]
{mesh_block}

[sub_resource type="ShaderMaterial" id="MatRes"]
shader = ExtResource("1_shader")
{shader_uniforms}

[node name="{node_name}" type="Node3D"]

[node name="Mesh" type="MeshInstance3D" parent="."]
mesh = SubResource("MeshRes")
material_override = SubResource("MatRes")
"""


def cmd_list(args) -> int:
    if not PRIMITIVE_RUNS.exists():
        print(f"  no primitive runs found ({PRIMITIVE_RUNS} doesn't exist)")
        return 0
    rows = []
    for name_dir in sorted(PRIMITIVE_RUNS.iterdir()):
        if not name_dir.is_dir():
            continue
        manifest_path = name_dir / "manifest.json"
        if not manifest_path.exists():
            continue
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        n_variants = len(manifest.get("variants", []))
        n_captured = sum(1 for v in manifest.get("variants", []) if v.get("captured"))
        rows.append((name_dir.name, n_captured, n_variants))
    if not rows:
        print("  no primitive runs yet — try: python tools/primitive_dna.py sweep TorusMesh")
        return 0
    print(f"  {'primitive':20s}  {'captured':>10s}")
    for name, captured, total in rows:
        print(f"  {name:20s}  {captured:>4d}/{total:<4d}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(prog="primitive_dna")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_sweep = sub.add_parser(
        "sweep", help="generate a parameter sweep + capture all variants"
    )
    p_sweep.add_argument("primitive", help=f"one of: {', '.join(sorted(GENOMES.keys()))}")
    p_sweep.set_defaults(func=cmd_sweep)

    p_list = sub.add_parser("list", help="list primitive runs on disk")
    p_list.set_defaults(func=cmd_list)

    p_promote = sub.add_parser(
        "promote",
        help="promote a primitive variant to a named artifact (.tscn + registry entry)",
    )
    p_promote.add_argument("primitive", nargs="?",
                           help=f"one of: {', '.join(sorted(GENOMES.keys()))} (omit if --compose)")
    p_promote.add_argument("--as", dest="as_token", required=True,
                           help="artifact token, e.g. bipyramid_v2")
    p_promote.add_argument("--params", nargs="+", default=[],
                           metavar="key=value",
                           help="primitive params, e.g. rings=2 radial_segments=4 (single mode)")
    p_promote.add_argument("--compose", default=None,
                           help="path to a composition spec JSON (compose mode)")
    p_promote.add_argument("--shader", choices=["edges", "parametric", "flat"], default="edges",
                           help="material strategy: edges (SimpleGrid, mesh-edge highlighting), parametric (ParametricGrid, UV-grid), or flat (StandardMaterial3D, no edges — best when CylinderMesh's internal triangulation would otherwise show through)")
    p_promote.add_argument("--color", default=None,
                           help="base color as 'r,g,b' (default 0.6,0.0,0.8 — bipyramid violet)")
    p_promote.add_argument("--lines-u", type=int, default=None,
                           help="parametric shader: lines along u axis (default: from genome line_count_axes)")
    p_promote.add_argument("--lines-v", type=int, default=None,
                           help="parametric shader: lines along v axis (default: from genome line_count_axes)")
    p_promote.add_argument("--force", action="store_true",
                           help="overwrite if scene already exists")
    p_promote.set_defaults(func=cmd_promote)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
