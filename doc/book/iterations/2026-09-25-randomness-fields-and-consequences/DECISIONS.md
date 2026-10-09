# Randomness: fields and consequences

25 September 2026. Six remaining Randomness halls reviewed against current chapters, companion manuscripts, placed scenes and native museum views. Five chapters receive narrow changes; Random Pheromone is retained byte for byte.

## Decisions

### book_randomness.001 — Put the noise bench on the hall's floor

**done**. The malformed source grid is real: all six tokens now stand in the existing floored second chamber, all layers are 12 by 24, and the pathfinder counts all six. However, the loaded museum already used a separately stamped necklace: its bench stands at (3.5,0,19.5), supported at all three checked standing positions before and after. Retain that placement authority. A local sculpture exclusion clears the unrelated generated sculpture from its approach. Added a brief arrival sentence. No global plan regeneration: it would replace unrelated work and is not needed for this map read. Column/console contrast under the hall lighting remains a visual follow-up; do not read this as headset acceptance.

### book_randomness.004 — Drop the desktop-carry aside at the edible mushroom

**done**. Removed the desktop-carry exception and the platform label. The act of holding a mushroom close to the face remains in the chapter; no new claim about tracked-hand acceptance is made.

### book_randomness.005 — Drop the desktop-carry aside at the podium

**done**. Removed the desktop-carry aside at the podium. The passage follows holding, release and waiting; platform differences belong in implementation notes.

### book_randomness.006 — Correct the field's label and walker count

**done**. Retain the existing chapter unchanged. The review read script defaults (five walkers, 30%) but the placed pheromone_terrain.tscn overrides them with four walkers and 40%. The native museum confirms four and 0.4. An initial diagnostic and tentative edit used the review values; the failed assertion led back to the scene, and the chapter was restored byte for byte.

### book_randomness.009 — Anchor the podium and the five profiles

**done**. Added the waiting_profile encounter anchor before the last podium. The five profiles remain part of this encounter. Also corrected a separate timing claim: equal rates mean equal expected attempt counts, not identical hourly totals; the podium draws uniform waits rather than using the described Bernoulli tick rule.

### book_randomness.010 — Name the biome ladder before Noise Types

**done**. The exit now carries the question about decisions and disclosure through the Randomness biome ladder before Noise Types. No sequence order changed.

### book_randomness.011 — Remove the curator's 'returned'

**done**. Changed “Four works have returned” to “Four works share”. The gallery can introduce these works without requiring the reader to have visited them previously.

### book_randomness.012 — Give the Worley display and the returning gauge a sentence

**done**. Added the cellular field’s nearest/next-nearest distance comparison and the entropy gauge’s limitation: it counts its own symbols, not the surrounding textures. Both keep their existing roles. Native photographs showed the ground crossing them; only these placements now use 0.35 m and 1.05 m supports. A native cellular-field photograph enters the chapter.

### book_randomness.027 — A stray default PrismMesh stands in the bed, with a spare Camera3D and a 24 m FillLight

**done**. Specimen staging removes the authored demo PrismMesh, Camera3D and FillLight before building the bed. The opt-in stand:specimen path alone changes; the original standalone scene still contains all three. Native SIZE checks preserve specimen positions, types, yaw and ground, then restore the original sizes.

### book_randomness.034 — The dartboard's SPACE toggles AUTO from the desktop walking keys

**done**. This museum dartboard opts into keyboard:off so SPACE, D and R cannot operate AUTO/THROW/RESET while the visitor uses walking keys. Direct native input checks preserve count and AUTO; throwing still works. Standalone shortcuts remain enabled by default and repeated key events are ignored.

### book_randomness.028 — The random ground severs the museum walker

**open**. Still open. The retained random ground remains physically visible and its separate sampler is described accurately. This pass lifts two obscured exhibits, but does not repair the shared walker’s broad-bounds classification or establish a complete route over that ground. Keep that navigation task separate from the text repair.

### book_randomness.029 — Walk to the mixer on its plinth in the headset

**open**. Still open. Native views confirm the mixer, lifted cellular field and lifted entropy gauge coexist. This is not the requested headset approach and knob-reading test.

### book_randomness.030 — Press ATTRACT/AVOID and REPLAY in the headset

**open**. Still open. The native field confirms the scene’s four walkers and 40% guidance, and advances 100 supplied steps. No tracked-pointer ATTRACT/AVOID/REPLAY test was performed. The captured view also shows the terrain close to the end wall and gate; investigate its full exposed footprint before headset acceptance.

## What the source could not tell us alone

The noise-bench report correctly identified a malformed source grid, but its description of the loaded museum was wrong. The native hall uses its existing stamped necklace. Three standing-position floor rays succeeded before any change. Repairing the source grid and removing an unrelated generated sculpture are distinct actions; neither is evidence of having rescued a previously unsupported museum visitor. The existing necklace remains authoritative.

The pheromone review confused script defaults with scene overrides. Its initial diagnostic failed because this pass repeated that assumption. The original manuscript was restored; the diagnostic remains in `pheromone/report.json`, and the corrected check is in `pheromone-final/report.json`.

The native photographs showed two real obstructions not visible in manuscript review: random ground partly buried the cellular plane and the entropy display. Their local supports now expose both. No change to the random ground's generation, mesh or collision was made.

## Verification and remaining limits

35 native assertions across six halls pass, with all six final processes exiting 0 and no GDScript errors. These include specimen population preservation under SIZE, the scene's actual four walkers/40% guidance, unchanged independent heights when coherent frequency changes, museum keyboard isolation with legacy shortcuts preserved, two local exhibit lifts, and five retained profiles. The source-grid pathfinder reports 213/288 reachable cells and all six artifacts; its two-teleporter warning is retained.

Existing engine warnings remain, including UID, unavailable renderer features, invalid resource state warnings and shutdown resource leaks. See `engine-limitations.json` and the full logs. Native assertions are bounded; they are not a claim that every room is visually or spatially finished. In particular, the noise bench remains overlit; the pheromone photograph shows its terrain close to the end wall/gate and does not establish a fully exposed, approachable footprint. Investigate those together with the still-open headset tasks.

The random ground's walker classification is still open. No tracked-hand eating, headset approach, pointer comfort, Quest performance, complete museum traversal or reader-learning test was performed. The older removal-floor shutdown failure remains outside this pass.

All photographs are original PNGs from the running Godot museum, not grid illustrations. Mushroom populations differ between runs; those images show staging, not a controlled seed comparison. The geometry room's random shapes also differ. The raised-gauge pair uses the same eye-height standing position with the view tilted toward its new height. Two native photographs enter canonical final.md and the current 14-hall capture.

Companion manuscripts, source excerpts, artifact roles, sequence order, other artifact placements and live plan/bake/save files are retained. Shared core references are updated only for these six halls. No new commit is made by this pass.
