# Seed windows: one instrument body

Palle requested that the windows, information boards and interface become one body. A continuous charcoal case now surrounds the three glass bays and their inset readouts. Horizontal rails join each window to its information; the lower cabinet contains the large current seed, source receipt, two sliders, seven rectangular buttons and action line. The window glass remains transparent through the case. The separate round table, control pedestal and floating boards have been removed from this configuration.

The original controls keep their callbacks and identities. They are arranged in two rows and mounted directly on the lower face, with the panel centre at 0.75 m. Button collision targets lie entirely within the 0.60–1.80 m reach band and project beyond the solid cabinet front. A standing marker sits 0.6 m in front of the control face. Upper windows are displays, with no elevated controls.

Museum staging now respects the explicit `em_embedded_control` marker on this panel. Ordinary panels still get their previous compact consoles. Geometry is rebuilt with the matrix without leaving extra cabinets, and all components remain children of the same artifact root so room placement moves them together.

## Verification

[Instrument tests](test.log): PASS. The original three-way seed comparison, draw offset, mapping, raw strips, capture/restore, resolution and legacy modes remain covered. Added checks verify one cabinet, no separate console or table, button reach and clearance, actual XR Tools collision-hand presses on REPLAY and +1 DRAW, withdrawal, unchanged viewpoint, and an ordinary panel that still receives its compact console.

[Hall integration](hall-test.log): PASS for shared seed and replay. Native Godot views inspected: [front](windows.png), [oblique](one-body.png), [controls](controls.png). These are native scene renders and automated hand contacts; physical headset comfort remains unobserved.

The seed comparison and optional place in the room/final sequence are unchanged. No new randomness or source acquisition was introduced.
