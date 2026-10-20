# Gallery of kept hybrids

16 October 2026. User asks to keep several interesting hybrids with their seeds, compare them side by side and replay any one.

[Native gallery](index.html) · [Implementation guide](implementation.md) · [Apparatus checks](verification.json) · [Actual hall checks](museum-report.json) · [Five complete records](gallery-records.json) · [Source manifest](manifest.json).

KEEP adds a complete arrangement to a persistent local index. Each entry holds all four forms and fifty meshes, with seed and slider stage. GALLERY shows four uniformly fitted sets at a time. PREVIOUS/NEXT navigate additional pages; REPLAY 1–4 restores the selected full-size arrangement; BACK preserves the live experiment. Main REPLAY returns to the most recently selected/kept entry during the session. After reopening, main REPLAY reads the latest KEEP pointer and GALLERY still offers all entries. Older records are not evicted.

`gallery_store.gd` manages the index and migrates the previous latest pointer. `kept_gallery.gd` reads validated records, builds only the visible page, and routes selection through the existing replay path. The pose calculation is shared with the host, so miniature previews use the same stored draws and targets. Missing/incompatible records become UNAVAILABLE. An unreadable index is retained without being overwritten. Native hidden consoles have their processing and collision layers disabled.

104/104 apparatus checks and 32/32 actual-hall checks pass. The tests keep five distinct variants, include stage 0.73, compare all miniature transforms with their records, page to a fifth entry, restore older entries, reopen a fresh instance, verify migration and malformed/missing-file behavior, and press the installed physical controls. Existing generator, slider reversal and earlier-record checks also pass. Test pointers are isolated from the user's collection. The malformed-index fixture is intentional; JSON parsing returns failure without emitting a misleading runtime error.

Reproduce with `python -X utf8 doc/book/iterations/2026-10-16-hybrid-gallery/run.py`, then `python -X utf8 tools/run_encounter_probe.py Random_Entropy --sequence randomness --render --no-bridges --output-tag hybrid-gallery --probe doc/book/iterations/2026-10-16-hybrid-gallery/museum_probe.gd`. Run `publish.py` here after both pass.

The optional tutorial, writing-wall entry, registry and research card/plan describe the gallery. Main room/final order and the first 48-value pilot remain in place. Next human observation: compare two seeds at the same stage, follow one identifiable part and record why a relationship is worth keeping. Recognition, learner reconstruction and headset comfort remain untested. The separate matched-base-motion refinement is still proposed; this gallery does not resolve that confound.
