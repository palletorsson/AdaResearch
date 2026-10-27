# Single cube / all vertices

`paired_cube_diagonals.tscn` keeps its legacy registry and lab-editor part key, but
now contains one instance of the original `animatedcubebuilder` source. The main
Animated Cube floor keeps its saved PairedCubeDiagonals position. The wide A/B
measuring display is no longer attached by the hall adapter.

All eight original handles are visible and grabbable immediately, on desktop
through production RMB carry/drop and in VR through XRTools. The source builder's
pink, red and black translucent materials are retained (alpha0.6). The wrapper
uses one double-sided triangle per fragment, avoiding coincident reverse copies
that would blend transparency twice. Vertices are shared between the same source
face recipes; moving one updates only its adjacent geometry.

RESTORE returns the eight original corners. REPLAY reveals the visitor's current
construction without resetting its vertices. DIAGONAL compares5-7 with4-6 on the
front face of this same cube, leaving all corner positions unchanged. Every corner
remains editable in either recipe. No independent scale animation is added.

The same legacy scene is used by the old museum and the Void hall. Layouts,
standard floors, the square assembly table and other Cube artifacts are unchanged.
Only the whole native part is arranged in the web editor; interactive vertex
editing runs in Godot. Restart a running game to load the changed script.

Validation: `python tools/run_single_cube.py`. Native geometry/materials, all eight
production desktop carries and supplied XRTools controller poses, replay/restore,
and moved/rotated placement. No physical-headset playthrough claim. The earlier
`void_cube_edge_probe.gd` describes the historical two-body comparison and is not
an acceptance test for this user-requested single-cube revision.
