# Physical choices in front of a fitness landscape

21 September 2026. This pass migrates `fitness_landscape_politics`, used in the particle-swarm hall and several placed/trial maps.

The old side column becomes a low, inclined console in front of the terrain. Four physical caps choose CONVERGE, SPREAD, NOVELTY or RIDGE. Exactly one retains a green selection after release. RESET remains momentary and resets the seeded population without changing the selected reward or inertia. The fader is continuous across 0–1; it retains its position on release. Labels and live readings are flat textures on surfaces. The existing interpretive captions move onto a supported sign behind the terrain.

The default artifact now exposes RIDGE as well as the original three choices. Previously RIDGE was available only when that mandate had been supplied by configuration, to preserve an earlier capture layout. This is a deliberate interface change. The scoring functions, swarm integration, random seed and manuscript are preserved.

## Reuse

`commons/ui/physical_choice_console.gd` composes the existing ControlPanel and push-button scenes with the physical fader. It supports one to four choices, one normalized continuous parameter and RESET. Configure `title`, `choices`, and `parameter` before tree entry. Connect `choice_pressed(index)`, `value_changed(value)` and `reset_pressed`. Owners synchronize state with silent `set_selected`, `set_value` and `set_reading` calls. Selection is owned by the artifact, not toggled independently by the buttons.

`physical_stepped_slider.gd` retains its six-stop default for grammar. Its explicit `continuous` option removes quantization for inertia; the printed six marks then label a continuous scale, not six available values. Near-grab and pointer input use the same XR Tools track. Physics nodes stay at unit scale.

Two shared button repairs accompany this pass: initial released colours are applied even before the first press, and a pointer disappearing or losing application focus releases its press without cancelling another hand still touching the button.

## Evidence

- `run.py` runs 45 checks on real artifact instances: ray hits, collision overlap using an AnimatableBody3D on the XR hand layer, cap travel and release, persistent selection, XR Tools pickup/grab-driver movement, continuous values, state synchronization, reset, configured rebuilding and unchanged seeded agents/terrain.
- `run_regressions.py` passes 46 grammar checks and 23 Shannon checks. Outputs are kept here, without replacing the earlier review evidence.
- Captures use Godot 4.6, the Mobile renderer, an RTX 3070 and a desktop test scene. Before/after views share cameras and initial simulation state. `ridge-*` shows the changed rule after 120 integration steps. These are artifact captures, not full museum or headset captures.
- Close camera: `(0.42, 1.38, 2.52)`, looking at `(0, 0.80, 1.84)`, FOV 57. Operating view: `(0, 1.65, 2.5)`, looking at `(0, 0.42, 0.35)`, FOV 90.

The panel is 76 cm wide, its root 76 cm above the artifact floor, tilted 60 degrees. Its forward position follows `arena_size / 2 + 0.34`. These are authored dimensions, not a claim that reach is validated for all bodies. At the captured operating pose the panel still covers part of the near terrain; moving around it remains useful. Placement on raised exhibit furniture needs a separate hall check.

Headset reach, tactile comfort, tracked-hand behaviour and Quest performance remain pending. No performance improvement or project-wide migration is claimed. Known unrelated startup messages about an unresolved UID, certificate access and shader-cache writes remain in the logs; the test scripts complete without script errors.

## Next bounded pass

Review `edge_of_chaos_unlocked`. Its unlocked, clamped, withheld, frozen and chaos configurations intentionally give different access to the parameter. Preserve those differences while improving the controls; a uniform appearance must not erase the lesson.
