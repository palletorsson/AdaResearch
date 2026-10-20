# Return 2: one board for the experiment

The user's first returned finding was an interface requirement:

> the interface has to be upgraded for vr like in interface_demo but with rectangular buttons and collect on one board that has the button close.

This is direct human design feedback. It does not establish that a headset session occurred or that the mapping helped the visitor understand the values. It redirects work toward access to the experiment before another mathematical variation.

The revised study has one 0.88 × 0.46 m board, tilted 25° toward the visitor, with eight rectangular action buttons in two compact rows. Labels sit on their caps; the current mapping remains highlighted. The board shows the seed, mapping, kept status and action feedback. It uses the shared `push_button_front.tscn` used by `commons/interactables/InteractableDemo.gd`, including hand contact, controller-pointer activation and press feedback. The meshes, cap colliders and touch targets are rectangular; controls remain at unit scale.

CLOSE hides the board and disables its touch targets. It leaves the displayed values, mapping and kept result unchanged. A CONTROLS tab remains available to reopen it. The old floating control labels and carried-point selector are removed from the active study. F1–F8 still provide desktop shortcuts.

## What was checked

- Native model/study: 46 checks pass; fresh-process replay: 3; extraction of the revised printed code: 46.
- Actual museum: 18 checks pass, including a synthetic hand overlap near a rectangular cap's edge and withdrawal, XR pointer events, close/reopen without loss, and KEEP → EXPORT → NEXT SEED → CLEAR KEPT → IMPORT → REPLAY using physical-button APIs.
- The rendered board was inspected by Codex. Labels and status are visible and grouped on the backing.
- The desktop launcher smoke passed and the preview was reopened. The saved-record model and both mathematical mappings are unchanged.

These are programmatic interaction checks, not a physical headset session. Reach, comfort, text size in the headset and independent reconstruction remain open. The next return should describe whether these controls are usable, then revisit what the height assignment makes noticeable.

The tutorial now prints `seed_board.gd` and names its borrowed XR components. The final passage is retained: this feedback concerns access to the apparatus and does not yet supply a new account of the height comparison. Both decisions are recorded separately in [experiment.json](experiment.json). The prior code, text reviews and plan remain recoverable.
