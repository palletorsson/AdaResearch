# Tutorial output gallery

Current scope: 15 Primitives halls and 6 Transformation halls, through Trans_Body.

`python capture.py` copies exact learner scripts, validates canonical code blocks, imports an isolated Godot project, renders 36 states and checks continuity. `python capture.py --reuse` refreshes the same isolated project. `python publish.py` rebuilds the image gallery and source reader. Requires the local Godot path in capture.py, Python and Pillow; the repository supplies XRTools.

No museum code, tutorial text or reflective text is edited. Camera, environment and ground belong to the capture harness. Inputs are specified per image; source files and original files are hashed in verification.json. The unique temporary project prevents overwriting the learner’s own saved trace.

Verified scope: source agreement, native scene startup, 36 image captures, actual XRTools synthetic pickup/release, trace filtering and saving, archive identity through three consumers, resolution ownership, bounded resolution search and camera-driven doorway size. This is not a replacement for each lesson’s full reconstruction tests or a headset/human learning test.

Lineage review: Triangle returns to the original Trace archive, not the snapped Grid copy. Cube and octahedron reuse FaceBody with fresh data. Profiles uses a supplied font/sweep helper. Trans_Pre replaces CubeBody with BoxBody. Scale reuses BoxBody and parent-child structure to create a new doorway and a new comparison sphere. Body keeps that construction and adds a proximity input.

Presentation findings: Labels can overlap the movable point and trace. Introduction’s centred scaling box extends below y=0; the stage floor is lowered for that comparison. These are documented, not silently fixed.
