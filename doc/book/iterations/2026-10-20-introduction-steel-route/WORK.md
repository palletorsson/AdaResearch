# Introduction steel route — 2026-10-20

Intent: carry the full Introduction into the pillar-attached steel kit. Read the original Trans_Introduction final.md and old introduction_sequence implementation. Preserve move/grow/turn and restore the original adjustable_landing interaction. No tutorial/final rewrites.

Floor2 in commons/void/trials/transformation/rooms.json was saved through the revision-checked API. 241 construction records: deck92, truss104, collar8, wedge12, cube24, platform1. Deck height3; four banks across X. One-metre sparse modules reuse original Cube/wp bodies and shared steel recipe. Column pairs at X14,5,-5,-14, Z+/-7 receive collars rotated90 and transverse truss spines. Exit deck has two ties to its pillar spine. Ramps rise1 over2, from outer Z+/-8 to deck Z+/-2. Moving platform begins (11.5,3,0), travels(-3,0,0), pause5.

New introduction_mezzanine scene groups only instruments, hazard surfaces and captions; native part_defaults are exported for individual browser editing. Growth centre(0,1.5,0), max scale3, decktop3. Turn centre(-10,2.9,0), original bridge3x.2x1. Adjustable landing root(-11,3,-2), facing270, original landing centred(-13,2.9,0). The corrected local control offset(3,0,-4) places controls at(-7,3,1), on the near deck. Bank subclass only removes obsolete side-aisle wording from the readout.

Six divider walls and two work lights removed. Excavations extend across side aisles; two original shafts stay vertical. Central basin width3; outside-shaft cuts width5. Lethal surfaces atY-2.35 cover all crossing gaps except A's south-west descent corner. Original B arrival and A departure remain. Floor2 style abstract removes services, and retry spawn moved fromX17.5 to18.5 to stand clear of the ramp. Other floor rooms unchanged.

Files:
- commons/void/trials/transformation/introduction_mezzanine.gd/.tscn
- commons/void/trials/transformation/introduction_bank.gd
- commons/void/trials/transformation/rooms.json and layout.json
- commons/void/catalog.json, line_parts.json, trials/playable.json
- tools/build_introduction_mezzanine.py
- tools/probes/introduction_mezzanine_probe.gd
- tools/test_introduction_mezzanine.py
- tools/test_introduction_mezzanine_editor.cjs
- Encyclopedia public/void-trials/transformation manifest and exported native models.

Verification:
- python -X utf8 tools/test_introduction_mezzanine.py: 130 checks passed, production desktop + synthetic tracked XR.
- node tools/test_introduction_mezzanine_editor.cjs: 10 checks passed.
- python -X utf8 tools/export_void_trial.py transformation: no failures.
- python -X utf8 tools/test_introduction_mezzanine.py --capture: five actual Godot screenshots; moving mechanisms posed only for photos.
- Browser confirms saved floor2, native parts and construction controls. Screenshot saved.

Checks cover continuous input-driven route, body/camera carriage, scale collision, rotation alignment, original bank slider/reset and accessible controls, hazards/retry, final descent, streamed recreation, editor copy/paint/erase, API validation and save parity. Physical headset not tested. Structural load simulation is not implemented.

Evidence caught two placement issues: a ramp overlapped a redundant cube landing (removed); the rotated bank control faced the wrong spatial side (corrected and covered by deck support/position checks). Before-rooms and protected text/tower hashes are retained. All unrelated floor rooms and protected texts/tower files verified unchanged.
