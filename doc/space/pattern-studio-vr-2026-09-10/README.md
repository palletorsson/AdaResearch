# Pattern Studio in VR — 2026-09-10

User asked to improve the Godot equivalent of /pattern-studio and provided /loom, /mosaic-editor, /meander-editor, /pattern-maker and /facade-builder as related sources.

Improved the existing studio plate with a separate physical front end: 1.32 m face, 42 cm source grid, tiled GPU preview, palette, named previous/next controls, mirror, rotate, clear, 32-state undo and separate local Save/Restore. Native motifs are no longer cropped. Corrected the group-name order (CM precedes PMM) and the old half-overwrite mirror operation. Source row zero matches browser orientation. Walking keyboard controls do not edit the station.

WEB NEXT loads compatible saved JSON from commons/patterns, preserving shader finish through PatternLoader. Supported sizes: 2/4/6/8 and up to 9 colours. Denser inputs are rejected without mutation. SAVE writes user://pattern_recipes/studio.json; it does not overwrite browser-authored packages or synchronize back to the browser. Shader parameter editing, receiver adapters and garment transfer remain open.

The original grid (9,21) trapped the panel behind blocks. Moved only this interactable to (7,25), root at floor level. Added a sculpture exclusion rectangle around the approach, left structure/museum/utilities unchanged, and placed its carpet 1 cm above the floor. Backed the pedestal away from the tilted controls after visually detecting occlusion. Primary/book anchors remain unchanged.

48 desktop museum checks pass; captured and inspected the actual station and carpet. Covered pointer paint, group names, complete motif loading, reversible operations, legacy/current package validation, shader shape and wear, Save/Restore, palette control availability, standing capsule and obstacle-free rays to every visible control. No headset test. Existing unrelated missing UID warning remains.

Public comparison and next steps: doc/research/possible-bodies/studio-workshop.html. Existing Panel Bridge is the reuse point for loom/matrix panels. Shared conventions should retain distinct source models rather than flattening every instrument to texture. Browser automation failed to initialize; local source and HTTP inspection covered all six URLs.

Before-snapshots are excluded from Godot import using .gdignore. No commits or external publication. Local encyclopedia guide receives the reports and captures.
