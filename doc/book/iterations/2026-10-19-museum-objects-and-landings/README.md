# Museum objects and corner landings

User request: remove timber construction between floors, add simple safe plank
landings in a shaft corner, restore original Primitives objects for curation.

Implemented in the shared Void layout. Two 12 cm boards per receiving floor,
alternating outside corners of shaft B. Existing one-floor damage/death rules
remain. Original user transforms, props, walls and routes were retained; only
the old descent assembly was removed. The new objects have individual editor
transforms, copy and remove controls.

222 original interactable cells accounted for: 64 retained representations,
5 established tower adaptations, 153 restored original scene instances. Source
tokens and matches: `inventory.json`. Original placements before this migration:
`ada_run/void-museum-migration/rooms.before.json` in the project. Added objects were
fitted using Godot mesh bounds; `fitted-objects.json` records the initial layout.
This is a collection for the user to curate, not a claim of a final walk route.

Validation: `python tools/test_void_museum.py` stages real dependencies and tests
all added scene roots plus 58 desktop/XRTools physics assertions. Synthetic
tracking is not a physical headset test. The harness sometimes reports an
ObjectDB teardown warning; final runs have no script or engine errors.
`python tools/export_void_editor.py` exports the real meshes and lamps to the
encyclopedia. Existing materials with shaders have static browser approximations.

The larger inventory exposed a runtime bug: floor residency used freed Nodes as
Dictionary keys. Stable instance IDs and weak references prevent an endless
restore loop when procedural objects rebuild children. A temporary Node used to
read Melencolia's tutorial text is also freed after reading it.

No tutorial.md or final.md was rewritten. The native captures use the same tower
architecture and original artifact scenes with the Compatibility renderer.

Report: `index.html`. Rebuild it with `python doc/book/iterations/2026-10-19-museum-objects-and-landings/build.py`.
