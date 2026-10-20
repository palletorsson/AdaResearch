# Random Definition — in the museum

[Open the illustrated reading](index.html) · [Text with images](final-illustrated.md)

Actual museum screenshots and a new carried PointBody. The textiles move to an extended 10 PRINT hall. Canonical final.md files now describe those placements; their tutorial.md files keep their existing printed constructions.

The revised reflection has 12 paragraphs and 622 body words. It opens at the sphere and matches commons/maps/Random_Definition/final.md. The tutorial is unchanged by this revision. Earlier prose, the old plan and builders are preserved in before-ball-opening/. The original user-supplied consolidation remains source-draft.md. Read revision.md for the editorial assessment.

Revise draft.md and the canonical final together, retaining canonical artifact markers and the RAND footnote. Run build.py to verify their agreement and regenerate HTML and illustrated Markdown. Run export_pdf.py with the bundled Python runtime for the PDF and its review-page copy. The paired grid photographs now show the 13 October four-by-four revision.

Runtime commands (from repository root):

```powershell
python tools/run_encounter_probe.py Random_Definition --sequence randomness --render --no-bridges --probe doc/book/iterations/2026-10-13-random-definition-in-the-museum/ride_probe.gd --output-tag random-return-20261013
python tools/run_encounter_probe.py Random_Definition --sequence randomness --render --no-bridges --probe doc/book/iterations/2026-10-13-random-definition-in-the-museum/photo_probe.gd --output-tag random-return-photos-20261013
python tools/run_encounter_probe.py Randomness_10_PRINT_Algorithm --sequence randomness --render --no-bridges --probe doc/book/iterations/2026-10-13-random-definition-in-the-museum/ride_probe.gd --output-tag textiles-moved-20261013
python tools/run_encounter_probe.py Random_Definition --sequence randomness --render --no-bridges --probe doc/book/iterations/2026-10-13-four-by-four-seed/museum_probe.gd --output-tag four-by-four-20261013
python doc/book/iterations/2026-10-13-random-definition-in-the-museum/build.py
```

Read checks.json for previously recorded runtime results and captures.json for image provenance. These are not new engine runs for the prose revision. The assertions are runtime checks; headset comfort, reach and tracking remain a human test. The 10 PRINT launch has an existing CodeDisplay source-path warning and a shutdown resource warning recorded in its engine log.

The initial capture.gd records the pre-move room and is retained as process history. It expects the old placements. Use ride_probe.gd and photo_probe.gd for the current room. place.py records the placement migration; it is not part of the museum runtime.
