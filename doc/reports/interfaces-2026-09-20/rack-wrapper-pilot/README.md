# Standalone rack controls reach their receivers

20 September 2026. Continuation of the release-control reference.

## Changes

- `VRRackControl` now supplies a collider matching its inset screen and a pointer-to-GUI route. Its 2D drawing, text and hit coordinates scale together. Passive displays do not intercept pointers, and an explicit `pointer_enabled = false` is available.
- `rack_pointer_surface.gd` is shared with `ModuleFaceTexture`, replacing the latter's inline/dynamically compiled forwarding script. It keeps pointer ownership, cancels on exit/focus loss/pointer removal, and processes frames only while pressed.
- Wrapper labels and values survive pre-tree configuration. Discrete initial values quantize against the final step count. This fixes the .37-at-six-steps case, which must become .4 rather than first rounding on five steps and then becoming .2.
- `ArtifactControls` no longer writes the nonexistent `_set_label_deferred` property. Its button callback now listens to the actual rising `value_changed` state; the old helper checked for a `pressed` signal absent from `RackButton`. Release/exit never repeat the action.
- Helper status labels are flat, backed screens updated on demand, replacing billboard `Label3D`. The supported update API remains `update_label`. `add_label` now returns a Node3D housing rather than a Label3D; the inspected current consumer does not use Label3D-specific properties on that return value.
- `grammar_provenance` adopts a six-position depth selector, nearby depth readout and a supported case. The selector corresponds to its existing six integer generations. The grammar rules, text, expansion and drawing algorithms are unchanged. Following the user's placement correction, the station is centred **in front of the work**, at local `(0, .86, 1.7)`, inclined -55 degrees about X. An upright stem and foot support it. The controls retain their 1.5 scale and .15m local spacing.

## Evidence

`python doc/reports/interfaces-2026-09-20/rack-wrapper-pilot/run.py` runs `commons/testing/test_rack_wrapper_input.gd` with the real Godot Mobile renderer. `checks.json` records 46 passing assertions, including ray hits and behaviour checks. Generated physics rays intersect actual screen colliders, then XRTools pointer events pass through the GUI and consumer callbacks.

Coverage: continuous/discrete/returning sliders, ordinary buttons, cancellation, competing pointers, nonuniform scale and rotation, passive displays, pre-tree configuration, status screens and a real artifact. Grammar generation one renders 5 segments (10 vertices); actual selector input changes generation two to 25 segments (50 vertices), with `Depth: 2` displayed.

`run_module_regression.py` reuses the previous 43-check module test with private output paths, so the shared bridge is checked through both wrappers. Earlier evidence is not overwritten. The final runs exit 0. Unrelated resource UID, certificate-store and shader-cache warnings remain in the logs; there are no script errors in the final runs.

`grammar-controls.png` and `grammar-artifact.png` are captures of the real artifact instantiated in a test scene, not a museum hall capture. The latter records a standing view at local `(0, 1.65, 2.1)`: the controls are in front, with all three forms and provenance boards visible behind. This view was visually inspected after moving the station. Earlier side-placement images are retained under `front-placement/previous-*.png`. These establish component assembly and receiver operation, not museum placement, accessibility, navigation or headset comfort. No live museum plan or manuscript was edited.

## Next

Review the other actual `ArtifactControls` consumers: `fitness_landscape_politics` and `edge_of_chaos_unlocked`. Confirm action callbacks, selected modes and intentional restrictions in those assemblies. The wrapper can now deliver events; inner rotary controls need a behaviour audit. `RackWheel` and `RackLever` still inherit empty input handlers and remain visual prototypes on this route.

Review: `/book-review/doc/book/iterations/2026-09-20-interface-rack-wrapper-review/index.html`.
