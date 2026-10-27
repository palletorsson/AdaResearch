# Shader collection transfer

All 13 source placements are present on two editable Void trial floors. This is
an inventory in playable space, not the final path or composition.

- Floor 1: five shaping desks; shared wall/cube mask; dark sphere; ScienceScreen.
- Floor 2: original pattern modes; walk-through patterned passage and chair;
  film monitor; camera record-reading study; pattern garden; fuzzy body;
  model disagreement; fuzzy doorway; dark sphere.

Original map files, final text and source artifact implementations are unchanged.
`source-inventory.json` keeps the original tokens, cells and map-text hashes.
The stable IDs connect every placed item with that inventory.

Two local adapters fit museum furniture to the tower: `disagreement.gd` relocates
the remote console, retained-source stand and title; `fuzzy_body.gd` lowers the
backdrop and two headings below the slab. Neither changes the experimental mesh,
numerical ranges, controls, model scale or calculation.

Native Mobile rendering: 45 checks pass, including desktop mouse and synthetic
XR pointer EDGE, ATTACH and RESET buttons, slider-to-uniform propagation, mode
changes, record-reading, original geometry calculations, shaft descent, floor
sleep and retry. Other controls remain candidates for deeper interaction review.
No physical headset test or headset performance measurement was performed.

The editor exports real geometry with static shader colour approximations.
Shaders and interactions execute in Godot; the editor is for arrangement.

Later curation: separate the four-panel shader table from the larger walk-through
rooms; decide whether the fuzzy/precision works belong on this floor; tune title
placement, viewing angles and the patterned passage's relation to fixed pillars.
ScienceScreen retains its source config `mode:grid`; the source implementation
reports generic mode when no grid-producing instrument is found. This limitation
is recorded rather than replacing it with an invented shader readout.

Run native checks: `python tools/test_shader_transfer.py`.
Evidence: `evidence/checks.json`, `evidence/engine.log`, four PNG captures.

Editor validation: 16 checks pass, including real exported geometry, independent
copy/move/rotation, shared native save, Desktop backup, stale-save rejection and
restoration of the saved arrangement. Source coverage/configuration audit: 69
checks pass. Export: 48 GLBs, no failures (includes the common prefab palette).
