# Randomness tutorial progression: comparison receipt

15 October 2026. Palle asks to compare the Nature of Code randomness chapter with Ada's randomness sequence and propose a coherent tutorial progression.

Read the [progression and task plan](../../course/randomness-tutorial-progression.md). It preserves the current fourteen-map order and proposes eight small cumulative builds, with six application or advanced workshops at their existing positions. Entropy is the next proposed implementation, following today's four-object shelf. No chapter, room or final text is rewritten by this comparison.

Sources inspected: all fourteen `tutorial.md` chapters named by `commons/maps/sequences/randomness.json`; the Noise sequence entry; the current Definition tutorial plan; the existing randomness research/particle proposal; and [the reference chapter](https://natureofcode.com/random/). The comparison is editorial and based on source reading, not an independent learner trial. The 48-value seed bench remains the first research pilot.

`audit.json` records the sequence order, source hashes, approximate prose size, printed GDScript lines and marked student files. Thirteen tutorials contain the same normalised PointBody source. Listing totals include this inherited support and display code; they do not measure fourteen unrelated implementations or fourteen different levels of algorithmic complexity.

Reproduce the audit from the repository root:

```powershell
python -X utf8 doc/book/iterations/2026-10-15-randomness-progression/audit.py
```

Rerunning updates the audit to the files then on disk. Hashes identify the version reviewed; older task records and estimated chapter lengths are not substituted for the current files. The progression's counts-to-shelf import, workshop roles and later implementation tasks remain proposals. Existing tutorials currently generate several separate records with local seeds; their cross-hall transfer is not already implemented.
