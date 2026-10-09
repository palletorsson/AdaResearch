# Trans_Pre — a familiar body acquires operations

This opening builds on the vertex/mesh distinctions in Animated Cube and the arrangement in Melencolia. It prepares for Trans_Introduction, where transformed surfaces participate in crossing a gap. The encounter text is `final.md`.

The question is: **what changes, relative to what, and which parts follow?** All four demonstrations instantiate `commons/scenes/mapobjects/pick_up_cube.tscn`. Its script is `pick_up_cube.gd`. Their placement settings select cumulative channels; the geometry is not reconstructed each frame.

| Source cell (x,z) | Motion setting | Observation |
|---|---|---|
| (4,2) | `still`, `hold:demo` | Translation amplitude, rotation rate and scale pulse are zero. Processing continues. |
| (4,5) | `slide`, `hold:demo` | Only vertical oscillation is visible. |
| (4,8) | `idle`, `hold:demo` | Vertical oscillation plus continuous rotation. |
| (4,11) | `all`, `hold:demo` | Both preceding channels plus uniform visual scale. |

The corresponding markers stand at (6,5), (6,8) and (6,11). Their timing is independently implemented: the Y shuttle pauses at its ends, the rotation marker initially rocks, and the scale marker uses a fixed cage. They clarify an operation; they do not control the larger pickup demonstrations.

`_process(delta)` first checks collection state, then performs these operations:

```gdscript
rotate_y(rotation_speed * delta)
time_passed += delta
var bob_offset = sin(time_passed * bob_speed) * bob_height
global_position.y = original_y + bob_offset
```

The modes choose rates and amplitudes. Default `bob_height` is 0.2 metres; `bob_speed` is 2.0 and `rotation_speed` is 2.0 radians per second where those channels are active. `original_y` is captured from world height in `_ready()`. X and Z are not rewritten by this update. The root's local Y rotation moves the entire child construction about its upright axis.

For `motion:all`, `_apply_motion()` supplies a scale amplitude of 0.3 when none was set. The pulse uses:

```gdscript
_apply_pulse(1.0 + pulse_scale * sin(time_passed * pulse_speed))
```

Within `_apply_pulse`, the visible mesh's scale is rebuilt from its saved value:

```gdscript
_pulse_mesh.scale = _pulse_mesh_scale0 * s
```

This avoids multiplying the previous frame's result repeatedly. The factor ranges from 0.7 to 1.3. The mesh and any optional dressing pulse; the separate DetectionArea is not scaled by that method. Uniform visual growth therefore does not imply uniform growth of every subsystem associated with the artifact.

`hold:demo` disables area monitoring and causes `collect()` to return. The four display cubes remain available. On the raised route, four `motion:all` instances use the ordinary collection mode at (4,16), (4,18), (4,19) and (4,20). An admitted player entering DetectionArea invokes collection: state changes, points and sound are issued, and the instance is queued for removal after a short delay. Retracing the route during the visit does not undo that event.

Three wedge lanes at source row 14 approach the raised platform; another three at row 22 descend from it. Two health crosses at (2,18) and (6,18) remain supporting objects with their own health-dependent admission rule. They are not the fifth and sixth stages of the cube lesson.

For a reader without the museum: sketch a cube and mark its centre and one corner. Compare translating all corners by the same displacement, turning them about an axis, and uniformly scaling offsets from the centre. State what happens to distances, angles and position in each case. Keep this diagrammatic exercise distinct from running the script: the detector's behaviour requires inspecting the scene hierarchy too.
