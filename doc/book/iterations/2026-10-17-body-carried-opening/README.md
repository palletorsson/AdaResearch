# Body — the carried opening

17 October 2026. Canonical Trans_Body/tutorial.md now continues the tested Scale edition. Three insertions, 16 nonblank new code lines (18 including spacing). BoxBody, box(), apply_pose(), the complete doorway construction and sphere remain. Only two assertions enter the previous _ready body. Reflection and museum runtime remain unchanged.

## Short brief

MAKE: existing opening grows with approach, returns on retreat.
BRING: exact Scale output; BoxBody, parent/children, apply_pose(Vector3), fixed sphere.
GIVEN: Endless Museum; active walking/XR camera in same viewport; floor-level unscaled host, no tilt.
ADD: camera reference each frame; world separation projected onto XZ; bounded range; interpolated uniform factor.
CHECK: far4 → factor1; near1 → factor4; midpoint2.5 → factor2.5; height/direction irrelevant; fixed witness; no accumulation.
CARRY: unchanged frame + distance-to-factor response into Trans_Pit.
LATER: body collider, multiple visitors, smoothing, timed progress, permanent cuts.

## Before / after

Before: standalone cube rebuilt mesh construction, looked up groups that do not cover every XR rig, removed the frame and sphere. After: all Scale code retained; active camera deliberately provides viewpoint input. Camera origin and collision body are explicitly different. The frame grows on approach; the hall's separate block field shrinks parts to make space between them. These operations share the input relation, not the same geometry.

## Evidence

123 Godot 4.6 native assertions pass. Three exercise variants, five detected behavioural faults and six bad insertion anchors. The tests run the assembled printed edits, the actual preceding Scale scene, live frames, actual desktop and XR camera classes with test positions, different parent frames, no camera, late camera and freed/replaced camera. Native scene execution is not evidence of human learning, physical XR tracking or collision safety.

Run `python doc/book/iterations/2026-10-17-body-carried-opening/verify.py`, then `publish.py`. Do not rerun guarded prepare.py. These are files for the prepared museum project, not a replacement environment.

## Source context

- commons/scenes/endless_museum.gd: walking Camera3D is made current; VR has an XRCamera3D.
- commons/artifacts/approach_scale/approach_scale.gd: installed artifact explicitly distinguishes em_walker/player_body visitors from XR descendants; it measures horizontal distance and updates collision too.
- Godot 4.6 Viewport.get_camera_3d: active camera in this viewport, or null.

Next repair: Body → Trans_Pit. Continue these files; declare the change from a visual frame to a solid, combined and timed opening. Do not silently rebuild BoxBody or certify the untouched Pit lesson.
