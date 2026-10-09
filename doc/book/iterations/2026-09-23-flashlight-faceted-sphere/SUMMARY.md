# Color_Flashlight — face by face

The requested seven-division faceted sphere is installed beside the existing board, on a low pedestal. Its centre is 1.5 metres above the floor and its diameter is 1.7 metres. Seven counts divisions around it; the rendered mesh has 42 nondegenerate triangles. Five divisions are also available as an authoring option.

## What changed

- `flashlight_demo.gd` builds an optional flat-shaded receiver with the board's same nonemissive near-white material and a matching triangle-mesh collider. Existing board, cube, lamp controls and legacy mounting remain.
- Color_Flashlight's one placement gains `receiver_sides:7`. One new key in the grid's numeric-config allow-list prevents that value from becoming a yaw override.
- `final.md` keeps every previous paragraph, code excerpt and anchor. Two new paragraphs connect the primitive sphere's faces to the light's changing incidence; the native paired figure belongs both to the book and this review.
- Intent, technical notes, field notes and core text/map hashes are current.

## Evidence and corrections

43 focused checks pass in an isolated run of the actual museum. They cover map orientation, receiver geometry and collision, supporting floor and three standing-body clearances, pickup/movement/release of all four lamps, and rendered differences on the same material under a moving held red lamp. All four lights stay on. Five-division authoring and legacy mounting also pass.

The first run exposed the parser interpreting an unknown numeric key as tutorial rotation. Registering the key repairs it. The mesh check caught degenerate pole triangles, now omitted. Native inspection also revealed the old grid cube obscuring the new pedestal: the sphere was shifted sideways, then the capture and clearance checks were repeated successfully.

Images are native Godot Compatibility renders. The book figure only crops, resizes and labels them. Supplied XRTools grabber motion and selected static capsule checks do not establish a complete player circuit, tracked-hand reach, headset comfort, learner experience or Quest performance. Existing unrelated UID/renderer warnings are retained in stdout.log; the completed run has no script errors.

No live museum restart, live bake/save overwrite, commit, frozen full-book rebuild or audiobook regeneration. Next: Color_Nails — chosen colour reaching the acting body.
