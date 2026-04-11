#!/usr/bin/env python3
"""Batch capture screenshots of all remaining uncaptured artifacts."""
import subprocess
import os
import sys
import time

GODOT_EXE = r"C:\Users\palle\Desktop\Godot_v4.6-stable_win64.exe"
PROJECT_DIR = r"C:\Users\palle\Documents\GitHub\AdaResearch_46"
VERIFY_DIR = os.path.join(os.environ["APPDATA"], "Godot", "app_userdata", "Ada Research Zero One", "verify_shots")

# All artifacts that need capturing: (name, scene_path)
ARTIFACTS = [
    # Batch 9: d*-e*
    ("dark_sphere", "res://commons/artifacts/dark_sphere/dark_sphere.tscn"),
    ("decision_boundary_viewer", "res://commons/artifacts/decision_boundary_viewer/decision_boundary_viewer.tscn"),
    ("distribution_sampler", "res://commons/artifacts/distribution_sampler/distribution_sampler.tscn"),
    ("doppler_effect_demo", "res://commons/artifacts/doppler_effect_demo/doppler_effect_demo.tscn"),
    ("dot_product_projector", "res://commons/artifacts/dot_product_projector/dot_product_projector.tscn"),
    ("elliptic_surface", "res://commons/artifacts/elliptic_surface/elliptic_surface.tscn"),
    ("euclid_postulates_plaque", "res://commons/artifacts/euclid_postulates_plaque/euclid_postulates_plaque.tscn"),
    ("excluded_middle_demo", "res://commons/artifacts/excluded_middle_demo/excluded_middle_demo.tscn"),
    ("flow_field_painter", "res://commons/artifacts/flow_field_painter/flow_field_painter.tscn"),
    ("force_field_visualizer", "res://commons/artifacts/force_field_visualizer/force_field_visualizer.tscn"),
    # Batch 10: f*-g*
    ("foucault_pendulum", "res://commons/artifacts/foucault_pendulum/foucault_pendulum.tscn"),
    ("fractal_lsystem_string", "res://commons/artifacts/fractal_lsystem_string/fractal_lsystem_string.tscn"),
    ("friction_ramp", "res://commons/artifacts/friction_ramp/friction_ramp.tscn"),
    ("game_of_life_petri", "res://commons/artifacts/game_of_life_petri/game_of_life_petri.tscn"),
    ("genetic_tree_sculptor", "res://commons/artifacts/genetic_tree_sculptor/genetic_tree_sculptor.tscn"),
    ("glitch_body", "res://commons/artifacts/glitch_body/glitch_body.tscn"),
    ("gradient_descent_landscape", "res://commons/artifacts/gradient_descent_landscape/gradient_descent_landscape.tscn"),
    ("graph_coloring", "res://commons/artifacts/graph_coloring/graph_coloring.tscn"),
    ("grid_editor_board", "res://commons/artifacts/grid_editor_board/grid_editor_board.tscn"),
    ("grid_editor_board_3d", "res://commons/artifacts/grid_editor_board/grid_editor_board_3d.tscn"),
    # Batch 11: h*-j*
    ("harmonic_distance_table", "res://commons/artifacts/harmonic_distance_table/harmonic_distance_table.tscn"),
    ("hilbert_hotel", "res://commons/artifacts/hilbert_hotel/hilbert_hotel.tscn"),
    ("hl_turret_vectors", "res://commons/artifacts/hl_turret_vectors/hl_turret_vectors.tscn"),
    ("homogeneous_coordinates", "res://commons/artifacts/homogeneous_coordinates/homogeneous_coordinates.tscn"),
    ("hyperbolic_surface", "res://commons/artifacts/hyperbolic_surface/hyperbolic_surface.tscn"),
    ("jelly_cube", "res://commons/artifacts/jelly_cube/jelly_cube.tscn"),
    ("jelly_variants", "res://commons/artifacts/jelly_cube/jelly_variants.tscn"),
    ("julia_set_explorer", "res://commons/artifacts/julia_set_explorer/julia_set_explorer.tscn"),
    ("lenia_continuous", "res://commons/artifacts/lenia_continuous/lenia_continuous.tscn"),
    ("lsystem_dungeon", "res://commons/artifacts/lsystem_dungeon/lsystem_dungeon.tscn"),
    # Batch 12: l*-p*
    ("lsystem_tree", "res://commons/artifacts/lsystem_tree/lsystem_tree.tscn"),
    ("mario_cube", "res://commons/artifacts/mario_cube/mario_cube.tscn"),
    ("oscilloscope_artifact", "res://commons/artifacts/oscilloscope/oscilloscope_artifact.tscn"),
    ("parametric_lsystem", "res://commons/artifacts/parametric_lsystem/parametric_lsystem.tscn"),
    ("pattern_maker_station", "res://commons/artifacts/pattern_maker_station/pattern_maker_station.tscn"),
    ("poincare_disk", "res://commons/artifacts/poincare_disk/poincare_disk.tscn"),
    ("progression_driver", "res://commons/artifacts/progression_driver/progression_driver.tscn"),
    ("rejection_sampling_demo", "res://commons/artifacts/rejection_sampling_demo/rejection_sampling_demo.tscn"),
    ("riemann_sphere", "res://commons/artifacts/riemann_sphere/riemann_sphere.tscn"),
    ("room_grammar", "res://commons/artifacts/room_grammar/room_grammar.tscn"),
    # Batch 13: r*-s*
    ("rotating_cube_demo", "res://commons/artifacts/rotating_cube_demo/rotating_cube_demo.tscn"),
    ("rotation_gimbal", "res://commons/artifacts/rotation_gimbal/rotation_gimbal.tscn"),
    ("rotation_oscillation_cube", "res://commons/artifacts/rotation_oscillation_cube/rotation_oscillation_cube.tscn"),
    ("schrodinger_box", "res://commons/artifacts/schrodinger_box/schrodinger_box.tscn"),
    ("seismograph", "res://commons/artifacts/seismograph/seismograph.tscn"),
    ("sentry_turret", "res://commons/artifacts/sentry_turret/sentry_turret.tscn"),
    ("shannon_entropy_meter", "res://commons/artifacts/shannon_entropy_meter/shannon_entropy_meter.tscn"),
    ("shear_matrix_demo", "res://commons/artifacts/shear_matrix_demo/shear_matrix_demo.tscn"),
    ("sine_space_explanation", "res://commons/artifacts/sine_space_explanation/sine_space_explanation.tscn"),
    ("sine_wall_explanation", "res://commons/artifacts/sine_wall_explanation/sine_wall_explanation.tscn"),
    # Batch 14: s*-t*
    ("small_world_network", "res://commons/artifacts/small_world_network/small_world_network.tscn"),
    ("soft_stage_dashboard", "res://commons/artifacts/soft_stage_dashboard/soft_stage_dashboard.tscn"),
    ("space_filling_curve_gallery", "res://commons/artifacts/space_filling_curve_gallery/space_filling_curve_gallery.tscn"),
    ("spring_network", "res://commons/artifacts/spring_network/spring_network.tscn"),
    ("static_reference_cube", "res://commons/artifacts/static_reference_cube/static_reference_cube.tscn"),
    ("stigmergy_grid", "res://commons/artifacts/stigmergy_grid/stigmergy_grid.tscn"),
    ("superposition_display", "res://commons/artifacts/superposition_display/superposition_display.tscn"),
    ("terrain_erosion", "res://commons/artifacts/terrain_erosion/terrain_erosion.tscn"),
    ("timbre_sculptor", "res://commons/artifacts/timbre_sculptor/timbre_sculptor.tscn"),
    ("transform_composition", "res://commons/artifacts/transform_composition/transform_composition.tscn"),
    # Batch 15: t*-v*
    ("transform_matrix_cube", "res://commons/artifacts/transform_matrix_cube/transform_matrix_cube.tscn"),
    ("turing_pattern_generator", "res://commons/artifacts/turing_pattern_generator/turing_pattern_generator.tscn"),
    ("turret_targeting", "res://commons/artifacts/turret_targeting/turret_targeting.tscn"),
    ("vector_addition_demo", "res://commons/artifacts/vector_addition_demo/vector_addition_demo.tscn"),
    ("vector_field_visualizer", "res://commons/artifacts/vector_field_visualizer/vector_field_visualizer.tscn"),
    ("vector_magnitude_demo", "res://commons/artifacts/vector_magnitude_demo/vector_magnitude_demo.tscn"),
    ("vector_normalize_demo", "res://commons/artifacts/vector_normalize_demo/vector_normalize_demo.tscn"),
    ("vector_projection_demo", "res://commons/artifacts/vector_projection_demo/vector_projection_demo.tscn"),
    ("vector_subtraction_demo", "res://commons/artifacts/vector_subtraction_demo/vector_subtraction_demo.tscn"),
    ("wave_equation_solver", "res://commons/artifacts/wave_equation_solver/wave_equation_solver.tscn"),
    # Batch 16: w*-z*
    ("wave_interference_tank", "res://commons/artifacts/wave_interference_tank/wave_interference_tank.tscn"),
    ("wfc_tile_mosaic", "res://commons/artifacts/wfc_tile_mosaic/wfc_tile_mosaic.tscn"),
    ("wireworld_circuit", "res://commons/artifacts/wireworld_circuit/wireworld_circuit.tscn"),
    ("worley_noise", "res://commons/artifacts/worley_noise/worley_noise.tscn"),
    ("axis_translation_cube", "res://commons/artifacts/axis_translation_cube/axis_translation_cube.tscn"),
    ("x_translation_cube", "res://commons/artifacts/axis_translation_cube/x_translation_cube.tscn"),
    ("y_oscillation_cube", "res://commons/artifacts/y_oscillation_cube/y_oscillation_cube.tscn"),
    ("y_translation_cube", "res://commons/artifacts/axis_translation_cube/y_translation_cube.tscn"),
    ("z_translation_cube", "res://commons/artifacts/axis_translation_cube/z_translation_cube.tscn"),
    ("ball_dropper", "res://commons/artifacts/turret_targeting/ball_dropper.tscn"),
    ("bias_visualizer", "res://commons/artifacts/bias_visualizer/bias_visualizer.tscn"),
    ("laser_turret", "res://commons/artifacts/turret_targeting/laser_turret.tscn"),
    ("barnsley_fern", "res://commons/artifacts/barnsley_fern/barnsley_fern.tscn"),
]

def capture_artifact(name, scene_path):
    """Capture a single artifact screenshot."""
    out_path = f"user://verify_shots/{name}.png"

    # Check if already captured
    local_path = os.path.join(VERIFY_DIR, f"{name}.png")
    if os.path.exists(local_path):
        size = os.path.getsize(local_path)
        if size > 5000:  # >5KB means likely valid
            print(f"  SKIP {name} (already captured, {size} bytes)")
            return "skipped"

    cmd = [
        GODOT_EXE,
        "--path", PROJECT_DIR,
        "--xr-mode", "off",
        "--no-window",
        "--script", "res://commons/testing/capture_tscn_shot.gd",
        "--", f"--scene={scene_path}", f"--out={out_path}",
        "--lift=0.5", "--wait=2.0", "--frames=60"
    ]

    print(f"  Capturing {name}...", end=" ", flush=True)
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30, cwd=PROJECT_DIR)

        # Check output file
        if os.path.exists(local_path):
            size = os.path.getsize(local_path)
            print(f"OK ({size} bytes)")
            return "ok" if size > 5000 else "small"
        else:
            print(f"FAIL (no output)")
            return "fail"
    except subprocess.TimeoutExpired:
        print("TIMEOUT")
        # Kill any hanging Godot processes
        subprocess.run(["taskkill", "/f", "/im", "Godot_v4.6-stable_win64.exe"],
                       capture_output=True, timeout=5)
        time.sleep(1)
        return "timeout"
    except Exception as e:
        print(f"ERROR: {e}")
        return "error"


def main():
    start_idx = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    end_idx = int(sys.argv[2]) if len(sys.argv) > 2 else len(ARTIFACTS)

    artifacts = ARTIFACTS[start_idx:end_idx]
    print(f"Batch capture: {len(artifacts)} artifacts (indices {start_idx}-{end_idx})")
    print(f"Output: {VERIFY_DIR}\n")

    results = {"ok": 0, "small": 0, "fail": 0, "timeout": 0, "error": 0, "skipped": 0}

    for i, (name, scene) in enumerate(artifacts):
        print(f"[{i+1}/{len(artifacts)}]", end="")
        status = capture_artifact(name, scene)
        results[status] = results.get(status, 0) + 1

    print(f"\n{'='*50}")
    print(f"Results: {results['ok']} ok, {results['skipped']} skipped, {results['small']} small, {results['fail']} fail, {results['timeout']} timeout, {results['error']} error")
    print(f"Total attempted: {len(artifacts)}")


if __name__ == "__main__":
    main()
