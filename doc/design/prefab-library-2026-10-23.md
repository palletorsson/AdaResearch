# Prefab library — 23 October 2026

Palle confirmed: summoning another VR menu replaces/relocates the menu board. It must not replace previously placed artifacts.

Implemented first version:

- One generated catalogue, `commons/data/void_spawnlists.json`, from the spine, saved configured artifacts, the existing `primitive-prefabs.json` kit, and construction props. 1,504 entries including 152 kit recipes. These are catalogue entries/variants, not a new claim about original-occurrence transfer completeness.
- The web lab editor's Library tab has search, collection filters, favourites, recent entries, compact labels, thumbnails where available and an expanded browser. It uses the existing revisioned autosave and editable parts.
- Desktop uses the larger thumbnail browser. VR defaults to labels on one freestanding 4 × 4 m display, in a 4.16 m wide enamel frame, about 4.58 m tall including its feet. The Y button places or relocates the same instance on clear supported floor, normally 3.8 m ahead. Moving the hand does not move the board.
- Native selection prepares a position marker. Aim at the current floor, click/trigger to confirm; Q/E or right A rotates, Esc/Y cancels. The marker is a position cue, not a full geometry preview. B opens the desktop library; Y places or relocates the VR board in a live-link session.
- Spawn requests carry a catalogue ID; the bridge resolves exact config, height, scale and source. Selecting or moving the board never sends removal requests. The player-earned inventory remains separate from the authoring library.
- Shared source metadata allows main-spine preview geometry to survive placement and reload in a separate trial. No existing floor arrangements were saved or rewritten during this work.

Evidence under `ada_run/prefab-menu/`:

- `checks.json`: native UI/board regression checks pass, including single board, world anchoring, relocation, confirm and cancel. `desktop-library.png` and `vr-world-board.png` are native render captures from an isolated harness.
- `catalogue-checks.json`, `web-placement-checks.json`: all 1,504 descriptors preserve settings and existing objects in both placement implementations.
- `save-validation.json`: sample plank and AND placements pass the real save validator in memory; no user layout mutation.
- `typescript-focused.log`: focused TypeScript check passes. The repository-wide check encounters unrelated historical capture-file errors.
- `bridge-checks.json`: shared catalogue and actual kit PNG served; non-catalogue file paths rejected. One bridge process now owns both 8771 and 8772.

Limits: physical headset interaction/readability has not been tested. Browser security denied observing the localhost editor, so web visual QA remains pending; no alternate browser route was used. Some entries have no thumbnail and use label cards. The native menu retains the existing live-link prerequisite; the local bridge is running, but a previously running game must reload to load changed scripts. Native placement is limited to the player's current floor. Source artifact behaviours were not tested or changed.

Regenerate the projection with `python tools/build_void_spawnlists.py` after catalogue or source configuration changes. It never edits the sources or user layouts. Native harness: `tools/probes/prefab_menu_probe.gd`, run using the existing OS native-slot lock and isolated runtime; pass `--out=<evidence>` and `--public=<ada_encyclopedia/public>`.

## Freestanding board refinement

The VR terminal now has a restrained off-white and graphite palette, family-coloured label edges and a small orange frame accent. Two 1.9 m deep feet, rubber pads and a low centre of mass support the physical RigidBody3D. Its 50 kg mass is a starting tuning value: no axes are locked and it can be pushed. The screen uses the UI collision layer only; the compound stand provides physical collision. Both feet must find a level slab and the board volume must be clear. Unsupported summons leave the previous board where it was.

Palle reassigned left Y to summon/relocate the board or cancel active artifact placement. Its restart-from-roof handler was removed from `commons/void/game.gd`; the existing menu and desktop T remain available. Left Menu remains an alias for the board. Close hides the stand and disables its physical collisions. During artifact placement the board stays visible and physical with UI input suspended; confirming does not relocate it. Existing artifacts are never deleted by the board lifecycle.

`checks.json` records 20 passing native harness checks, including five seconds of upright settling/stability, physical impulse response, single-instance relocation, no hidden collisions, Y relocation and unsupported-placement refusal. No SCRIPT ERROR or ERROR lines occurred in the passing native run. `vr-standing-board.png` shows the feet and frame; `vr-world-board.png` is the frontal render. These are isolated native engine captures, not headset screenshots. A physical VR headset test remains necessary for controller ergonomics, label readability and natural pushing force. The live-link prerequisite remains unchanged.
