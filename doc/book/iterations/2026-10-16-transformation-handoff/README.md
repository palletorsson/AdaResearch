# Primitives → Pre → Introduction

16 October 2026. This edition updates tutorial.md in Trans_Pre and Trans_Introduction and corrects the forward promises in Cube and Melencolia. The earlier arrangements remain saved. No museum runtime or final.md edits.

- Primitives: the face-list CubeBody remains available. The next branch deliberately uses a centred BoxMesh rather than silently promising the identical class.
- Pre: BoxBody is a six-line visual class. A copy of Melencolia’s host becomes the moving cube; collection follows as a separate tested checkpoint.
- Introduction: carries box_body.gd byte-for-byte. Exact edits add independent models, a placement function and apply_pose; collection is removed. Period means a complete return cycle in both lessons.
- Book: prints complete new functions or exact changed lines. File + function/unique statement are authoritative; line numbers link to a pinned incoming state. Full programs remain online, outside the print reading.

Run `python doc/book/iterations/2026-10-16-transformation-handoff/verify.py` from the AdaResearch repository. The test reads the current canonical printed edits, rejects missing/ambiguous anchors, compares assembled outputs to full files, then runs those outputs in native Godot. prepare.py is an editorial one-shot, not a build command.

Evidence: 68 native assertions; eight variants; four deliberately broken behaviours detected; sixteen bad anchors rejected. Real XR Tools used for the prior arrangement. Synthetic player bodies used for pickup tests. No headset or human-learning result is claimed.

## Download

Copy a lesson folder into the existing prepared Endless Museum project. Use its study.tscn as a child of the hall, at floor level with unit scale and zero rotation. Or attach lesson.gd to the existing empty study host. Keep the named helper beside it. The studies use the museum’s supplied camera, light and player; the ZIP is not a separate XR installation.

## Next pass

Introduction → Translation remains open. Reuse this edition’s BoxBody and placement function; print the route values and changed update only; reconstruct the next state from these exact files. Keep the saved Pre collectible for the later Arrays branch. Do not change the museum runtime or final.md to make tutorial tests pass.
