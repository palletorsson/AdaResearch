# The room: form and pixels

An optional camera study in `Shader_05_Patterns`, source cell (17, 13), facing 270°. One camera supplies two banks of ten operations. The original pattern garden and UV lesson remain. These are exhibit variants within one study.

Pick up the pink camera, aim it at the museum and release it. The left screen shows its view. PIXELS / FORM switches banks. Turn EFFECT through ten detents, or press NEXT / PREVIOUS, to choose an operation. Turn STRENGTH to change its amount. SNAP saves one frame; LIVE / HOLD switches between the live view and that saved frame. Mode 7 in each bank compares saved regions with the current image when LIVE is selected. HOME returns the camera to its local stand; RESET restores mode 1, strength 80% and LIVE within the chosen bank, retaining the saved frame. A held camera is never pulled out of the hand by HOME or RESET.

## The control panel

The 1.16 m faceplate replaces the long row with two dials and seven rectangular buttons. A ten-position EFFECT dial and a continuous STRENGTH dial reuse `dial_smooth.tscn`, as in `interactable_demo`. Their native grip dimensions and unit scale are retained. Desktop/ray drag uses the shared scalar pointer; hand rotation uses the shared angular driver. Numeric displays, effect title, next/previous and reset stay synchronised.

The rectangular button vocabulary comes from InteractableDemo's RECT examples. Here it is attached to the working `push_button.tscn`: the cap mesh and hit shapes are rectangular, while pointer, hand-poke, sound and release behaviour remain shared. The buttons form three nearby pairs below the bank switch. Pink latching indicates PIXELS and HOLD; the display explicitly names the active bank and image state. Styling is local to this artifact.

## PIXELS: one flat screen

Every mode uses the same two-triangle rectangle. Integer pixel addresses, channel values or frame selection change. The saved source remains intact. At amount zero, all ten modes return the unaltered nearest-sampled source. The separate reference screen uses ordinary texture filtering, so the two screens can differ in smoothness.

| View | Operation at maximum amount | Teaching distinction |
|---|---|---|
| 1. Chop the bands | Alternate bands shift left and right; addresses wrap | Row selection and horizontal offset |
| 2. The wrong row width | Read a flattened pixel list using a longer row stride, then wrap within it | Width is part of interpreting a record |
| 3. Repeat a scanline | Repeat the first row of each group; skip intervening rows | Repetition can remove detail |
| 4. Exchange the blocks | Permute all 48 blocks of an 8 × 6 grid once each | Address order changes without new source pixels |
| 5. Channels lose registration | Red and blue read different horizontal positions; green stays | A colour combines separate channel samples |
| 6. Tear one band | Displace only the middle fifth of the image | A local condition changes a region |
| 7. Blocks keep the past | 36 blocks read SNAP; 12 read LIVE | Image time can differ within one screen |
| 8. Fewer colour values | Round each sampled channel to four levels | Value quantisation differs from address changes |
| 9. Missing blocks | Replace 24 blocks with black | Missing output need not mean missing source data |
| 10. Read every other row backwards | Reverse odd rows, retain even rows | One alternating rule breaks spatial continuity |

Block permutation is exact at amount 1 for the fixed 640 × 360 source (divisible by 8 × 6). Intermediate amounts interpolate block offsets; they need not be permutations. Readback uses shader texture sampling at pixel centres, not an edited image file. Wrong stride models a different interpretation of a flat record; it is not actual invalid GPU memory access or a broken codec. Mode 7 needs a changed live view after SNAP to make time visible.

## FORM: spatial receivers

| View | Operation | What changes |
|---|---|---|
| 1. Pull the scanlines | Sixteen horizontal strips translate sideways and in depth | Receiver vertices |
| 2. Brightness becomes relief | Weighted RGB brightness displaces vertices up to 1.2 metres toward the viewer | GPU vertex positions; **not measured depth** |
| 3. Three colour planes | Separate R, G, B masks on three additive surfaces | Channel selection and spatial separation; background contributes to the sum |
| 4. Fold the image | Eight repeated ridges gather the image into a corrugated surface | Receiver vertices; continuous UVs |
| 5. Curl the view | The rectangle bends around a cylindrical arc | Receiver vertices; attached UVs |
| 6. Shuffle the addresses | A fixed bijection exchanges 24 source tiles | UV addresses, with shallow tile offsets |
| 7. A strip stays behind | Alternate bands interpolate toward the saved frame | Image time and a small depth offset |
| 8. Rows lose alignment | Each row receives a different wrapped horizontal offset | UV addresses |
| 9. Let dark pixels go | Discard samples below a weighted brightness threshold | Visible fragments, not collision geometry |
| 10. Wrap the room | The rectangle closes around a torus | Receiver vertices; the geometric seam closes but the image edges need not match |

These are deliberate visual interventions. They do not demonstrate broken GPU memory, a corrupted file, real depth reconstruction, or an engine malfunction. Rendering an image differently does not deform the room being observed. P4 now supplies a separate recorded-data/decoder reading on this same console, below.

## Runtime and bounds

One 640 × 360 SubViewport shares the museum World3D. Its Camera3D follows the inherited physical camera handle. It requests at most 20 updates per second while a viewer is within 25 metres and the artifact is visible. HOLD suspends that stream; SNAP reads back one image on demand. This bound is not a Quest performance measurement.

Gallery geometry uses visual layer 20, which the source camera excludes; HUD layer 19 is also excluded. Other museum objects on those layers are therefore absent from its view. This prevents an accidental recursive camera feed. The live stereo/headset view is unchanged. Surface meshes have no collider. The plinths, console and physical camera retain their real collision objects.

Only the selected receiver is present (three surfaces for spatial RGB). Maximum: 4,608 triangles in a spatial receiver; two triangles in every PIXELS mode. Spatial geometry and UV addresses return to a flat rectangle at amount zero. That is not a promise of pixel-identical RGB recombination over a non-black background.

## Source and validation

- `receivers.gd`: bounded geometry and address mappings.
- `camera_surface.gdshader`: brightness displacement, row offsets, held bands, fragment threshold.
- `colour_plane.gdshader`: an individual colour channel, additive blending.
- `pixel_surface.gdshader`: ten flat-screen pixel/address operations, no vertex displacement.
- `pixel_modes.gd`: pixel operation names and short descriptions.
- `CameraGlitchStudy.gd` and `.tscn`: live source, physical controls, placement-relative camera home.
- `glitch_console.gd`: compact panel, two shared dials, rectangular button caps and live state display.
- Supplied museum dependencies: `commons/artifacts/spine_studies/witness_camera.gd`, `commons/interactables/dial_smooth.tscn`, `push_button.tscn`, their shared input drivers, XRTools and the current museum environment.

Run `python -X utf8 tools/test_camera_pixels.py` for 28 geometry regressions, 8 spatial GPU regressions and 34 pixel GPU checks. The pixel oracle checks zero identity for all modes, specific sampled addresses, channel registration, saved/live selection and unchanged source bytes. Two deliberately faulty shader copies (correct stride in place of wrong stride; LIVE in place of SNAP) must fail. `tools/test_camera_glitch.py` additionally retains the earlier geometry mutation tests.

Run `python -X utf8 tools/run_encounter_probe.py Shader_05_Patterns --sequence shaders --render --probe tools/probes/camera_glitch_controls.gd` for the current interface and both banks in the actual hall. It inherits the earlier 70 checks (now using the strength dial), then checks all ten selector stops, button shape/grouping, state feedback, pointer dial movement/release and reset synchronisation. Real desktop pointer button clicks and XRTools grip rotation use the supplied drivers/controller poses. The museum runner writes isolated evidence under `ada_run/encounter_pilot/Shader_05_Patterns`; its log must have no script/shader error as well as passing assertions. A partial report after an exception is not a pass.

[Current dials and grouped buttons](../../../doc/book/iterations/2026-10-09-glitch-dials/index.html) · [Ten pixel views and validation](../../../doc/book/iterations/2026-10-09-cut-the-image-pixels/index.html) · [Earlier spatial views](../../../doc/book/iterations/2026-10-09-camera-image-becomes-body/index.html). Headset comfort, Quest cost, live portal traversal and an independent reader reconstruction remain open.

## P4: one record, different readings

The Patterns placement opts into `lesson:record_reading`. READ RECORD opens five readings in the existing receiver area: RGB, BGR, unsigned height, signed height and a refused 7 × 8 layout. The five-stop selector restores its original ten stops when you leave this mode. SAVE 8 × 8 reads 64 centre pixels from the current camera frame into 192 row-major RGB8 bytes. This is a retained snapshot in the artifact instance, not a disk save or depth scan. FIXTURE replaces it with an explicitly labelled known pattern. Both replace the source deliberately; receiver changes, reset and camera movement leave its SHA256 and bytes unchanged.

CHANNEL cycles R/G/B. Unsigned height uses `byte / 255 * gain * 1.2` metres. Signed reading uses two's complement, `byte - 256` for bytes ≥128, then `value / 128 * gain * 1.2` metres. A pink zero outline and cell (4,0) witness disclose this scale and interpretation. The strict layout decoder requires exactly `width * height * 3` bytes, returning invalid on mismatch before reading values. It does not model arbitrary codec corruption or out-of-bounds GPU access.

`saved_record.gd` contains the complete testable data core; `record_reading.gd` renders it using the supplied camera console. The surface is visual-only; the existing pedestal and console colliders remain. The canonical hall tutorial prints the core and a complete test driver; its primary pattern lesson is retained. The final text adds a short encounter with the changed reading.

Run `python -X utf8 tools/test_record_reading.py`: 37 core checks and two rejected faults. `python -X utf8 tools/publish_record_reading.py --prepare` extracts and tests the printed code (37 checks + eight example assertions). Native integration: `python -X utf8 tools/run_encounter_probe.py Shader_05_Patterns --sequence shaders --render --output-tag record-reading --probe tools/probes/record_reading_room.gd` — 121 checks, including 82 earlier camera checks. Publishing without `--prepare` copies the native views and source snapshots. [Images, code, reflection and receipts](../../../doc/book/iterations/2026-10-09-one-record-many-readings/index.html). No physical-headset, independent-learner or Quest performance acceptance is implied.
