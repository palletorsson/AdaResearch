# Introduction: three required crossings

User steering: transport turned to connect one route; growing cube in the middle; rotation in the other hole. Keep lethal pits, editable objects, desktop/VR parity. Wait with tutorial/final texts.

Implemented on separate Transformation trial floor 2, east to west: original `tc` above B (5m gap), original `sc` at centre (0.5 to 3m, centre 0.5m below slab), original `rc` bridge above A (3m span). Unit cubes and wp wedges form continuous 1m-high banks. Six editable partitions obstruct side bypasses. New central basin is 2.5m deep without glass. Hazards sit 2.35m below slab. Exit is A south-west, with floor-3 landing boards moved west. Retry starts east of the first crossing.

Data/code: introduction_sequence.gd/json/tscn; growing_crossing.gd and turning_crossing.gd inherit unchanged museum sources and advance them on physics ticks. Existing lethal_pit adds width/depth. Basin's glass is optional, defaults on. Architecture's landing X side is optional, defaults east. Trial spawn points are optional. Streaming retains recessed content to its basin bottom, fixing hazards sleeping when the visitor fell below the slab.

Verification so far: 131 real engine assertions pass across desktop and synthetic tracked XR; 12 production editor tests pass. Tests walk all three crossings in one route, ride original transport with camera/body parity, fall into each pit, miss closed growth/rotation, check dark-red death/retry, side bypasses, streaming and copied/moved/rotated mechanisms. Native Mobile run: 66 assertions pass. Six paired native images captured and visually reviewed; report opened. Static GLB export preserves Grid shader modelColor (green scale, orange rotation). Physical headset is not tested. Known shutdown warning: a few RefCounted objects leaked at exit; no script errors in successful headless run.

Preservation: before.json records previous rooms/layout and hashes of all tutorial.md/final.md files, source maps, original transform scripts, curated tower rooms/layout and cube recipe. Revision-checked API save updates native and Desktop room backup. No chapter rewriting.

Editor: http://localhost:3003/lab-editor?mode=void&trial=transformation&floor=2
Test: python -X utf8 tools/test_introduction_sequence.py --verbose
Capture: same command with --capture
Editor: node tools/test_introduction_sequence_editor.cjs
Export: python -X utf8 tools/export_void_trial.py transformation
