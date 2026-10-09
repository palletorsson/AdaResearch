# Different neighbours

A walk-in Godot study after the floor-to-wall display arrangements of Ryoji Ikeda. The floor, rear wall, side monitors and ceiling strip show one small retained array. Walk into the difference between repeating a rule and shuffling its result.

Open `project.godot` in Godot 4.6. Day Zero's edit/run workflow is assumed. The included project is independent of the main Ada project and requires no add-ons or autoloads.

## Try the room

- **Repeat:** two complementary banks of alternating two-row bands.
- **Shuffle rows:** keep each complete row, change the order of the rows.
- **Shuffle cells:** rearrange all 4,096 values individually.
- **New seed / seed field:** choose or recover a permutation. Repeat ignores the seed.
- **Step one row:** shift the displayed address window by one row, wrapping after 256. No new values are drawn.
- **4 × 4 inspection slider:** read rows 0–252, columns 6–9, from the current displayed record. The small physical monitor has the same patch, top row first.
- **Walk inside:** WASD and mouse. Esc returns. Keys 1/2/3 change the rule while walking; H shows controls; V changes the saved review camera.

There is no automatic animation, strobe or audio. Black cells retain the same solid floor as white cells. Side walls and ceiling repeat the whole record; they do not create additional samples. The floor and rear wall divide one continuous unfolded view at their crease.

## Place in the capability ladder

**Arrays → tiling → seeded randomness → a return after Random_Entropy.**

The new act is a permutation: an existing collection can change its neighbours without changing what it contains. Earlier array addressing and repetition remain useful. Rendering a room from an ImageTexture, the room architecture and the player are supplied apparatus, not prerequisites to be taught here. A later shader return can open that apparatus; a later data lesson can replace our synthetic binary inventory with an explicit encoding of a real source.

This is a registered, runnable **chapter companion**, not yet a stop in the installed museum spine. Intended placement is after Random_Entropy. It needs its own spatial bay, main-player controls and an entrance/exit connection before promotion; it should not be squeezed into the existing entropy hall. Native captures here are from the actual standalone Godot room, not the production museum generator. No XR or Quest trial is claimed.

## Source and interpretation

The user supplied a slide headed Ryoji Ikeda / Datamatics; its photograph's exact work and edition are unverified. Ikeda's own account of [test pattern](https://www.ryojiikeda.com/project/testpattern/) describes encoding source data into binary/barcode patterns and installations spanning large display surfaces. This study borrows a spatial question from that family of work. It does not reproduce Ikeda's score, sound, image data or rapid temporal behaviour.

Our display is a permutation of a balanced binary collection. It is not an independent coin toss at every cell, not a source-data decoder, and not a measure of the room's thermodynamic entropy. Its **marginal Shannon entropy stays 1 bit per symbol** in all three modes. The separate neighbour counter counts unequal horizontal and vertical adjacent pairs in the logical 16 × 256 array, without wrapping its edges; there are 7,920 such pairs. It is a simple description of local difference, not a second entropy formula.

## Files and verification

- `artifacts/score.gd`: the learner's rule and seeded permutation.
- `artifacts/signal_room.gd`: architecture, texture upload, unfolding, sample and readouts.
- `artifacts/build.gd`: borrowed primitive fabrication helpers.
- `gallery.gd`: supplied viewer, walking controller and controls.
- `capture.gd`: native rendering, state and collision checks.
- `source-hashes.json`: canonical source and portable copy hashes. `sync.py` regenerates copies inside the repository; it is not needed to run the downloaded kit.

Rendering uses five opaque unshaded surfaces sharing one 16 × 256 texture. There are no per-cell scene nodes. Display update runs only when a control changes. Local screen-space density may still alias at oblique angles; this desktop comparison is not a headset/performance certification.
