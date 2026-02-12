#!/usr/bin/env python3
"""
substrate_vector_generator.py — Generate substrate_vectors.json from artifact registries

Reads all 17 registry JSON files, applies keyword-based inference rules
(mirroring SubstrateAnalyzer.gd logic), then outputs a JSON file mapping
every artifact lookup_name to its 8D substrate vector.

Hand-curated overrides for the 5 theory-doc examples are applied last.

Usage:
    python substrate_vector_generator.py
    
Output:
    ../../../artifacts/registry/substrate_vectors.json
"""

import json
import os
import glob
import re
from pathlib import Path

# ── Paths ────────────────────────────────────────────────────

SCRIPT_DIR = Path(__file__).parent
REGISTRY_DIR = SCRIPT_DIR / ".." / ".." / "artifacts" / "registry"
OUTPUT_PATH = REGISTRY_DIR / "substrate_vectors.json"

# ── Keyword Maps ─────────────────────────────────────────────
# Each: keyword -> (dimension, value, weight)

GEOMETRY_KW = {
    "spheremesh": ("geometry", "primitive_mesh", 0.8),
    "boxmesh": ("geometry", "primitive_mesh", 0.8),
    "cylindermesh": ("geometry", "primitive_mesh", 0.8),
    "planemesh": ("geometry", "primitive_mesh", 0.7),
    "primitive": ("geometry", "primitive_mesh", 0.4),
    "cube": ("geometry", "primitive_mesh", 0.5),
    "sphere": ("geometry", "primitive_mesh", 0.4),
    "csg": ("geometry", "csg", 0.9),
    "csgbox": ("geometry", "csg", 0.8),
    "boolean": ("geometry", "csg", 0.5),
    "arraymesh": ("geometry", "procedural_mesh", 0.9),
    "procedural mesh": ("geometry", "procedural_mesh", 0.9),
    "surface_tool": ("geometry", "procedural_mesh", 0.8),
    "vertices": ("geometry", "procedural_mesh", 0.5),
    "terrain": ("geometry", "procedural_mesh", 0.6),
    "walkgrid": ("geometry", "procedural_mesh", 0.7),
    "heightmap": ("geometry", "procedural_mesh", 0.6),
    "height map": ("geometry", "procedural_mesh", 0.6),
    "multimesh": ("geometry", "multimesh", 0.9),
    "swarm": ("geometry", "multimesh", 0.5),
    "particles": ("geometry", "multimesh", 0.4),
    "immediatemesh": ("geometry", "immediate_mesh", 0.9),
    "arrows": ("geometry", "immediate_mesh", 0.5),
    "vector arrow": ("geometry", "immediate_mesh", 0.6),
    "parametric": ("geometry", "parametric_surface", 0.7),
    "helicoid": ("geometry", "parametric_surface", 0.7),
    "helix": ("geometry", "parametric_surface", 0.6),
    "double helix": ("geometry", "parametric_surface", 0.7),
    "dna": ("geometry", "parametric_surface", 0.6),
    "torus": ("geometry", "parametric_surface", 0.6),
    "mobius": ("geometry", "parametric_surface", 0.7),
    "riemann": ("geometry", "parametric_surface", 0.7),
    "path3d": ("geometry", "curve_extrusion", 0.8),
    "extrusion": ("geometry", "curve_extrusion", 0.7),
    "cable": ("geometry", "curve_extrusion", 0.6),
    "pipe": ("geometry", "curve_extrusion", 0.5),
    "spline": ("geometry", "curve_extrusion", 0.6),
    "catenary": ("geometry", "curve_extrusion", 0.6),
    "voxel": ("geometry", "voxel_grid", 0.8),
}

MATERIAL_KW = {
    "opaque": ("material", "opaque_standard", 0.6),
    "albedo": ("material", "opaque_standard", 0.5),
    "metallic": ("material", "opaque_standard", 0.4),
    "wood": ("material", "opaque_standard", 0.5),
    "brass": ("material", "opaque_standard", 0.5),
    "metal": ("material", "opaque_standard", 0.4),
    "transparent": ("material", "transparent", 0.8),
    "glass": ("material", "transparent", 0.7),
    "translucent": ("material", "transparent", 0.6),
    "emissive": ("material", "emissive", 0.8),
    "glow": ("material", "emissive", 0.7),
    "glowing": ("material", "emissive", 0.7),
    "neon": ("material", "emissive", 0.6),
    "emission": ("material", "emissive", 0.7),
    "shader": ("material", "shader_driven", 0.7),
    "fragment shader": ("material", "shader_driven", 0.8),
    "spatial shader": ("material", "shader_driven", 0.8),
    "vertex color": ("material", "vertex_color", 0.8),
    "double-sided": ("material", "cull_disabled", 0.7),
}

PHYSICS_KW = {
    "rigidbody": ("physics", "rigid_body", 0.8),
    "rigid body": ("physics", "rigid_body", 0.8),
    "throw": ("physics", "rigid_body", 0.5),
    "bounce": ("physics", "rigid_body", 0.5),
    "mass": ("physics", "rigid_body", 0.3),
    "softbody": ("physics", "soft_body", 0.9),
    "soft body": ("physics", "soft_body", 0.9),
    "deformable": ("physics", "soft_body", 0.7),
    "jelly": ("physics", "soft_body", 0.8),
    "squishy": ("physics", "soft_body", 0.8),
    "cloth": ("physics", "soft_body", 0.7),
    "fabric": ("physics", "soft_body", 0.5),
    "wobbly": ("physics", "soft_body", 0.5),
    "pendulum": ("physics", "custom_integration", 0.7),
    "spring": ("physics", "custom_integration", 0.6),
    "boids": ("physics", "custom_integration", 0.7),
    "flocking": ("physics", "custom_integration", 0.6),
    "orbital": ("physics", "custom_integration", 0.6),
    "coupled": ("physics", "custom_integration", 0.5),
    "gpuparticles": ("physics", "particle_system", 0.8),
    "particle system": ("physics", "particle_system", 0.7),
    "particle field": ("physics", "particle_system", 0.7),
    "walkable": ("physics", "collision_only", 0.6),
    "platform": ("physics", "collision_only", 0.5),
    "bridge": ("physics", "collision_only", 0.4),
}

TIME_KW = {
    "static": ("time", "static", 0.6),
    "motionless": ("time", "static", 0.7),
    "frozen": ("time", "static", 0.6),
    "continuous": ("time", "continuous", 0.7),
    "oscillat": ("time", "continuous", 0.6),
    "rotating": ("time", "continuous", 0.5),
    "animate": ("time", "continuous", 0.4),
    "puls": ("time", "continuous", 0.4),
    "swing": ("time", "continuous", 0.5),
    "breathing": ("time", "continuous", 0.5),
    "wave": ("time", "continuous", 0.4),
    "discrete": ("time", "discrete_step", 0.7),
    "generation": ("time", "discrete_step", 0.5),
    "cellular automata": ("time", "discrete_step", 0.7),
    "game of life": ("time", "discrete_step", 0.8),
    "click": ("time", "event_driven", 0.4),
    "collapse": ("time", "event_driven", 0.5),
    "observation": ("time", "event_driven", 0.5),
    "simulation": ("time", "simulation", 0.7),
    "multi-agent": ("time", "simulation", 0.7),
    "predator-prey": ("time", "simulation", 0.7),
    "ecosystem": ("time", "simulation", 0.7),
    "trail": ("time", "accumulative", 0.6),
    "trace": ("time", "accumulative", 0.5),
    "accumulate": ("time", "accumulative", 0.6),
    "growth": ("time", "accumulative", 0.4),
}

ALGORITHM_KW = {
    "sine": ("algorithm", "trig_functions", 0.7),
    "cosine": ("algorithm", "trig_functions", 0.6),
    "trig": ("algorithm", "trig_functions", 0.7),
    "trigonometric": ("algorithm", "trig_functions", 0.8),
    "harmonic": ("algorithm", "trig_functions", 0.6),
    "oscillation": ("algorithm", "trig_functions", 0.5),
    "frequency": ("algorithm", "trig_functions", 0.4),
    "lissajous": ("algorithm", "trig_functions", 0.7),
    "fourier": ("algorithm", "trig_functions", 0.7),
    "noise": ("algorithm", "noise_sampling", 0.7),
    "perlin": ("algorithm", "noise_sampling", 0.8),
    "simplex": ("algorithm", "noise_sampling", 0.8),
    "worley": ("algorithm", "noise_sampling", 0.7),
    "voronoi": ("algorithm", "noise_sampling", 0.6),
    "cellular automata": ("algorithm", "cellular_automata", 0.9),
    "game of life": ("algorithm", "cellular_automata", 0.9),
    "conway": ("algorithm", "cellular_automata", 0.8),
    "rule 30": ("algorithm", "cellular_automata", 0.8),
    "rule 110": ("algorithm", "cellular_automata", 0.8),
    "langton": ("algorithm", "cellular_automata", 0.8),
    "wireworld": ("algorithm", "cellular_automata", 0.8),
    "brians brain": ("algorithm", "cellular_automata", 0.8),
    "flocking": ("algorithm", "flocking_rules", 0.9),
    "boids": ("algorithm", "flocking_rules", 0.9),
    "swarm": ("algorithm", "flocking_rules", 0.6),
    "fractal": ("algorithm", "fractal_iteration", 0.7),
    "mandelbrot": ("algorithm", "fractal_iteration", 0.9),
    "julia": ("algorithm", "fractal_iteration", 0.8),
    "sierpinski": ("algorithm", "fractal_iteration", 0.8),
    "koch": ("algorithm", "fractal_iteration", 0.7),
    "self-similar": ("algorithm", "fractal_iteration", 0.6),
    "recursive": ("algorithm", "fractal_iteration", 0.5),
    "pendulum": ("algorithm", "physics_equations", 0.7),
    "spring": ("algorithm", "physics_equations", 0.6),
    "orbital": ("algorithm", "physics_equations", 0.7),
    "gravity": ("algorithm", "physics_equations", 0.5),
    "force": ("algorithm", "physics_equations", 0.4),
    "acceleration": ("algorithm", "physics_equations", 0.5),
    "damped": ("algorithm", "physics_equations", 0.6),
    "resonance": ("algorithm", "physics_equations", 0.5),
    "vector addition": ("algorithm", "vector_arithmetic", 0.8),
    "vector subtraction": ("algorithm", "vector_arithmetic", 0.8),
    "dot product": ("algorithm", "vector_arithmetic", 0.8),
    "cross product": ("algorithm", "vector_arithmetic", 0.8),
    "normalize": ("algorithm", "vector_arithmetic", 0.6),
    "magnitude": ("algorithm", "vector_arithmetic", 0.5),
    "projection": ("algorithm", "vector_arithmetic", 0.6),
    "basis vector": ("algorithm", "vector_arithmetic", 0.7),
    "reaction diffusion": ("algorithm", "reaction_diffusion", 0.9),
    "reaction_diffusion": ("algorithm", "reaction_diffusion", 0.9),
    "turing pattern": ("algorithm", "reaction_diffusion", 0.9),
    "gray-scott": ("algorithm", "reaction_diffusion", 0.9),
    "morphogenesis": ("algorithm", "reaction_diffusion", 0.7),
    "lsystem": ("algorithm", "lsystem_expansion", 0.9),
    "l-system": ("algorithm", "lsystem_expansion", 0.9),
    "l_system": ("algorithm", "lsystem_expansion", 0.9),
    "lindenmayer": ("algorithm", "lsystem_expansion", 0.9),
    "branching": ("algorithm", "lsystem_expansion", 0.4),
    "probability": ("algorithm", "probability", 0.7),
    "distribution": ("algorithm", "probability", 0.5),
    "gaussian": ("algorithm", "probability", 0.6),
    "monte carlo": ("algorithm", "probability", 0.8),
    "random walk": ("algorithm", "probability", 0.6),
    "stochastic": ("algorithm", "probability", 0.7),
    "bell curve": ("algorithm", "probability", 0.7),
    "topology": ("algorithm", "topology", 0.8),
    "curvature": ("algorithm", "topology", 0.6),
    "geodesic": ("algorithm", "topology", 0.7),
    "hyperbolic": ("algorithm", "topology", 0.7),
    "non-euclidean": ("algorithm", "topology", 0.7),
    "poincare": ("algorithm", "topology", 0.8),
    "mobius": ("algorithm", "topology", 0.7),
    "state machine": ("algorithm", "state_machine", 0.8),
    "superposition": ("algorithm", "state_machine", 0.6),
    "phase transition": ("algorithm", "state_machine", 0.6),
}

INTERACTION_KW = {
    "grab": ("interaction", "grab", 0.8),
    "grabbable": ("interaction", "grab", 0.8),
    "pickable": ("interaction", "grab", 0.7),
    "drag": ("interaction", "grab", 0.6),
    "slider": ("interaction", "slider", 0.8),
    "knob": ("interaction", "slider", 0.7),
    "dial": ("interaction", "slider", 0.6),
    "adjust": ("interaction", "slider", 0.4),
    "parameter control": ("interaction", "slider", 0.6),
    "grab_slide": ("interaction", "slider", 0.8),
    "button": ("interaction", "button", 0.7),
    "click": ("interaction", "button", 0.5),
    "toggle": ("interaction", "button", 0.5),
    "preset": ("interaction", "button", 0.4),
    "touch": ("interaction", "touch_surface", 0.6),
    "paint": ("interaction", "touch_surface", 0.6),
    "draw": ("interaction", "touch_surface", 0.5),
    "proximity": ("interaction", "spatial_presence", 0.7),
    "walk through": ("interaction", "spatial_presence", 0.6),
    "walkable": ("interaction", "spatial_presence", 0.5),
    "walk_through": ("interaction", "spatial_presence", 0.7),
    "embodied": ("interaction", "spatial_presence", 0.5),
}

CONTAINMENT_KW = {
    "glass jar": ("containment", "glass_jar", 0.8),
    "jar": ("containment", "glass_jar", 0.6),
    "specimen": ("containment", "glass_jar", 0.5),
    "vial": ("containment", "glass_jar", 0.5),
    "display case": ("containment", "glass_jar", 0.6),
    "museum case": ("containment", "glass_jar", 0.6),
    "aquarium": ("containment", "glass_tank", 0.8),
    "tank": ("containment", "glass_tank", 0.5),
    "petri": ("containment", "petri_dish", 0.8),
    "dish": ("containment", "petri_dish", 0.4),
    "plate": ("containment", "petri_dish", 0.3),
    "table": ("containment", "table", 0.5),
    "desk": ("containment", "table", 0.5),
    "workbench": ("containment", "table", 0.5),
    "pedestal": ("containment", "pedestal", 0.8),
    "plinth": ("containment", "pedestal", 0.7),
    "stand": ("containment", "pedestal", 0.4),
    "kiosk": ("containment", "pedestal", 0.5),
    "frame": ("containment", "frame", 0.6),
    "monitor": ("containment", "frame", 0.5),
    "screen": ("containment", "frame", 0.4),
    "canvas": ("containment", "frame", 0.5),
    "box": ("containment", "box", 0.5),
    "enclosed": ("containment", "box", 0.5),
    "rack": ("containment", "frame", 0.5),
}

INFORMATION_KW = {
    "label": ("information", "label_3d", 0.4),
    "text": ("information", "label_3d", 0.3),
    "plaque": ("information", "label_3d", 0.6),
    "infoboard": ("information", "label_3d", 0.6),
    "formula": ("information", "formula_display", 0.7),
    "equation": ("information", "formula_display", 0.6),
    "notation": ("information", "formula_display", 0.5),
    "chart": ("information", "data_visualization", 0.7),
    "histogram": ("information", "data_visualization", 0.7),
    "spectrum": ("information", "data_visualization", 0.6),
    "waveform": ("information", "data_visualization", 0.6),
    "meter": ("information", "data_visualization", 0.5),
    "gauge": ("information", "data_visualization", 0.5),
    "oscilloscope": ("information", "data_visualization", 0.7),
    "analyzer": ("information", "data_visualization", 0.5),
    "palette": ("information", "color_encoding", 0.5),
    "color mapping": ("information", "color_encoding", 0.7),
    "colored": ("information", "color_encoding", 0.3),
    "height map": ("information", "spatial_encoding", 0.6),
    "3d visualization": ("information", "spatial_encoding", 0.5),
}

ALL_KEYWORD_MAPS = [
    GEOMETRY_KW, MATERIAL_KW, PHYSICS_KW, TIME_KW,
    ALGORITHM_KW, INTERACTION_KW, CONTAINMENT_KW, INFORMATION_KW,
]

CATEGORY_HINTS = {
    "physics": {"physics": {"custom_integration": 0.4}, "time": {"continuous": 0.3}},
    "waves": {"algorithm": {"trig_functions": 0.3}, "time": {"continuous": 0.3}},
    "emergence": {"time": {"discrete_step": 0.3}, "algorithm": {"cellular_automata": 0.3}},
    "mathematics": {"information": {"formula_display": 0.3}},
    "philosophy": {"information": {"label_3d": 0.3}},
    "procedural": {"algorithm": {"noise_sampling": 0.2}},
    "qfep": {"interaction": {"slider": 0.2}, "information": {"data_visualization": 0.2}},
    "transforms": {"algorithm": {"vector_arithmetic": 0.2}},
    "audio": {"algorithm": {"trig_functions": 0.3}, "information": {"data_visualization": 0.2}},
}


def infer_vector(artifact: dict) -> dict:
    """Infer an 8D substrate vector from artifact registry data."""
    weights = {}  # {dim: {value: weight}}

    # Gather all text to search
    texts = []
    for field in ["description", "name", "lookup_name", "scene"]:
        v = artifact.get(field, "")
        if v:
            texts.append(str(v).lower())

    for field in ["tags", "dev_themes"]:
        vals = artifact.get(field, [])
        if isinstance(vals, list):
            for v in vals:
                texts.append(str(v).lower())

    interactions = artifact.get("interactions", [])
    if isinstance(interactions, list):
        for v in interactions:
            texts.append(str(v).lower())
    elif isinstance(interactions, str):
        texts.append(interactions.lower())

    interaction_field = artifact.get("interaction", "")
    if interaction_field:
        texts.append(str(interaction_field).lower())

    combined = " ".join(texts)

    # Scan keywords
    for kw_map in ALL_KEYWORD_MAPS:
        for keyword, (dim, val, weight) in kw_map.items():
            if keyword in combined:
                if dim not in weights:
                    weights[dim] = {}
                current = weights[dim].get(val, 0.0)
                if weight > current:
                    weights[dim][val] = weight

    # Category hints
    category = artifact.get("category", "")
    if category in CATEGORY_HINTS:
        for dim, vals in CATEGORY_HINTS[category].items():
            if dim not in weights:
                weights[dim] = {}
            for val, w in vals.items():
                current = weights[dim].get(val, 0.0)
                if w > current:
                    weights[dim][val] = w

    # Defaults
    if "information" not in weights:
        weights["information"] = {"label_3d": 0.3}
    if "geometry" not in weights:
        weights["geometry"] = {"primitive_mesh": 0.3}
    if "interaction" not in weights:
        weights["interaction"] = {"none": 0.3}

    # Clean: remove near-zero weights
    clean = {}
    for dim, vals in weights.items():
        cleaned = {k: round(v, 2) for k, v in vals.items() if abs(v) > 0.01}
        if cleaned:
            clean[dim] = cleaned

    return clean


# ── Hand-Curated Overrides ───────────────────────────────────

MANUAL_OVERRIDES = {
    "jelly_cube": {
        "geometry": {"primitive_mesh": 1.0},
        "material": {"transparent": 0.7, "emissive": 0.3},
        "physics": {"soft_body": 1.0},
        "time": {"continuous": 1.0},
        "algorithm": {"physics_equations": 1.0},
        "interaction": {"grab": 0.8, "slider": 0.5},
        "containment": {"none": 1.0},
        "information": {"label_3d": 0.5},
    },
    "foucault_pendulum": {
        "geometry": {"primitive_mesh": 0.6, "curve_extrusion": 0.7, "immediate_mesh": 0.4},
        "material": {"opaque_standard": 0.7, "emissive": 0.4},
        "physics": {"custom_integration": 1.0},
        "time": {"continuous": 0.8, "accumulative": 0.6},
        "algorithm": {"physics_equations": 1.0},
        "interaction": {"grab": 0.5, "spatial_presence": 0.4},
        "containment": {"none": 1.0},
        "information": {"label_3d": 0.5, "spatial_encoding": 0.7},
    },
    "schrodinger_box": {
        "geometry": {"csg": 1.0},
        "material": {"opaque_standard": 0.6, "transparent": 0.5},
        "physics": {"none": 1.0},
        "time": {"event_driven": 1.0},
        "algorithm": {"state_machine": 0.8, "probability": 0.6},
        "interaction": {"button": 0.8},
        "containment": {"box": 1.0},
        "information": {"label_3d": 0.5, "formula_display": 0.6},
    },
    "boids_aquarium": {
        "geometry": {"multimesh": 0.8, "csg": 0.5},
        "material": {"transparent": 0.7, "emissive": 0.5},
        "physics": {"custom_integration": 1.0},
        "time": {"simulation": 1.0},
        "algorithm": {"flocking_rules": 1.0},
        "interaction": {"slider": 0.7},
        "containment": {"glass_tank": 1.0},
        "information": {"label_3d": 0.5},
    },
    "mandelbrot_dive": {
        "geometry": {"primitive_mesh": 0.8},
        "material": {"shader_driven": 1.0},
        "physics": {"none": 1.0},
        "time": {"event_driven": 0.7},
        "algorithm": {"fractal_iteration": 1.0},
        "interaction": {"slider": 0.8},
        "containment": {"table": 0.7},
        "information": {"color_encoding": 0.8, "label_3d": 0.4},
    },
    # Additional well-known artifacts
    "static_reference_cube": {
        "geometry": {"primitive_mesh": 1.0},
        "material": {"opaque_standard": 1.0},
        "physics": {"none": 1.0},
        "time": {"static": 1.0},
        "algorithm": {"none": 1.0},
        "interaction": {"none": 1.0},
        "containment": {"pedestal": 0.5},
        "information": {"label_3d": 0.5},
    },
    "rotating_cube_demo": {
        "geometry": {"primitive_mesh": 1.0},
        "material": {"opaque_standard": 0.8},
        "physics": {"none": 1.0},
        "time": {"continuous": 1.0},
        "algorithm": {"trig_functions": 0.5},
        "interaction": {"none": 0.8},
        "containment": {"pedestal": 0.5},
        "information": {"label_3d": 0.5, "formula_display": 0.4},
    },
    "oscillation_controlled_cube": {
        "geometry": {"primitive_mesh": 1.0},
        "material": {"opaque_standard": 0.7, "emissive": 0.3},
        "physics": {"none": 0.8},
        "time": {"continuous": 1.0},
        "algorithm": {"trig_functions": 0.9},
        "interaction": {"slider": 0.7},
        "containment": {"pedestal": 0.5},
        "information": {"label_3d": 0.5, "formula_display": 0.6},
    },
    "vector_addition_demo": {
        "geometry": {"immediate_mesh": 1.0},
        "material": {"emissive": 0.5},
        "physics": {"none": 1.0},
        "time": {"event_driven": 0.7},
        "algorithm": {"vector_arithmetic": 1.0},
        "interaction": {"grab": 0.8, "button": 0.4},
        "containment": {"none": 1.0},
        "information": {"formula_display": 0.8, "label_3d": 0.5},
    },
    "game_of_life_vr": {
        "geometry": {"multimesh": 0.9},
        "material": {"emissive": 0.6},
        "physics": {"none": 1.0},
        "time": {"discrete_step": 1.0},
        "algorithm": {"cellular_automata": 1.0},
        "interaction": {"touch_surface": 0.6},
        "containment": {"petri_dish": 0.7},
        "information": {"color_encoding": 0.5},
    },
    "chladni_plate": {
        "geometry": {"multimesh": 0.8, "procedural_mesh": 0.5},
        "material": {"opaque_standard": 0.6, "emissive": 0.3},
        "physics": {"particle_system": 0.8},
        "time": {"continuous": 0.8},
        "algorithm": {"trig_functions": 0.7, "physics_equations": 0.5},
        "interaction": {"spatial_presence": 0.5},
        "containment": {"petri_dish": 0.8},
        "information": {"spatial_encoding": 0.6},
    },
    "poincare_disk": {
        "geometry": {"procedural_mesh": 0.7},
        "material": {"emissive": 0.5},
        "physics": {"none": 1.0},
        "time": {"static": 0.7, "event_driven": 0.3},
        "algorithm": {"topology": 1.0},
        "interaction": {"slider": 0.4},
        "containment": {"pedestal": 0.6},
        "information": {"spatial_encoding": 0.7, "label_3d": 0.4},
    },
    "bifurcation_diagram": {
        "geometry": {"procedural_mesh": 0.7},
        "material": {"emissive": 0.5},
        "physics": {"none": 1.0},
        "time": {"event_driven": 0.6},
        "algorithm": {"state_machine": 0.6, "probability": 0.5},
        "interaction": {"slider": 0.7, "spatial_presence": 0.4},
        "containment": {"none": 1.0},
        "information": {"data_visualization": 0.8, "label_3d": 0.4},
    },
}


def main():
    # Read all registries
    all_artifacts = {}
    registry_files = sorted(glob.glob(str(REGISTRY_DIR / "*.json")))

    # Exclude our output file
    registry_files = [f for f in registry_files if "substrate_vectors" not in os.path.basename(f)]

    for fpath in registry_files:
        with open(fpath, "r", encoding="utf-8") as fh:
            data = json.load(fh)
        arts = data.get("artifacts", {})
        for key, val in arts.items():
            if not isinstance(val, dict):
                continue
            lookup = val.get("lookup_name", key)
            all_artifacts[lookup] = val

    print(f"Read {len(all_artifacts)} artifacts from {len(registry_files)} registry files")

    # Infer vectors
    vectors = {}
    for name, artifact in sorted(all_artifacts.items()):
        vectors[name] = infer_vector(artifact)

    # Apply manual overrides
    for name, override in MANUAL_OVERRIDES.items():
        vectors[name] = override
        print(f"  Override: {name}")

    # Write output
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    with open(OUTPUT_PATH, "w", encoding="utf-8") as fh:
        json.dump(vectors, fh, indent=2, sort_keys=True, ensure_ascii=False)

    print(f"Wrote {len(vectors)} substrate vectors to {OUTPUT_PATH}")

    # Stats
    dim_counts = {}
    for vec in vectors.values():
        for dim in vec:
            if dim not in dim_counts:
                dim_counts[dim] = 0
            dim_counts[dim] += 1

    print("\nDimension coverage:")
    for dim in sorted(dim_counts):
        print(f"  {dim}: {dim_counts[dim]}/{len(vectors)} artifacts")


if __name__ == "__main__":
    main()
