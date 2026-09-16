# Transport cube: VR carrying in Trans_Translation

The reported symptom was an abrupt forward/downward journey in VR. Inspection
found that the cube moved the XR collision body in the render loop while
XRTools separately recentered that body beneath the headset and estimated
moving-ground velocity. Moving the body alone did not carry the headset.

A headless reproduction with the actual XRTools body showed about 0.4 m of
horizontal lag. On a down-and-forward round trip the body eventually lost the
platform and fell below it. This reproduced a carrying failure, not a live
headset recording of the reported destination jump.

## Change

`commons/scenes/mapobjects/transport_cube.gd` now advances in physics before the
XR body. Each increment moves the body and origin together through XRTools'
transform API, retaining the tracked camera offset and updating collision hands.
The already-applied platform contact is rebased so native ground velocity does
not add the same movement again. This adapter uses XRTools' existing private
ground-contact cache; the regression probe should be rerun after an XRTools update.

The physical cube transform is flushed before carrying the rider. Endpoint
snapping is included in the carried displacement. A VR rider must have feet
above the cube's actual top to board; passing beside/below the broad detection
volume does not start a ride. A real jump or leaving the supporting footprint
releases the rider. Small contact corrections at the endpoint do not count as
jumps.

The shared transport scene supplies the change to grid and museum placements.
Map coordinates, authored distances and directions remain as authored.

## Verification

The repeatable regression suite is
`commons/testing/probe_transport_cube_vr.gd`. It loads the real XRTools body,
camera and transport scene with normal physics and gravity, without an XR
headset. It checks horizontal directions, vertical travel, the exact
Trans_Translation escalator displacement `(0, -3, 2)`, outward/return journeys,
room-scale camera offsets, a rotated rig, turning, desktop carrying, jumping,
departure and invalid boarding. All 116 assertions passed, including natural Area boarding and bounds on
per-tick headset displacement. Its machine-readable result is
`ada_run/transport-cube-vr-checks.json`.

Run from the project directory:

```powershell
& 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe' --headless --path . --xr-mode off --audio-driver Dummy --max-fps 60 --quit-after 8000 --log-file ada_run/transport-cube-vr.log --script res://commons/testing/probe_transport_cube_vr.gd
```

Additional checks covered shared parameter parity, museum gap seating, the
actual Trans_Translation descending route and the existing composed-ride
rotation/scale behavior. The old parity/seating scripts required deferred
initialization to avoid loading XR dependencies before autoload registration.
The old Introduction probe has stale authored coordinates and was not used as
evidence for the current map.

Physical headset/controller testing remains pending. Restart the VR run before
checking the route so it loads the revised script.
