# Soft Bodies — first traverse

15 September 2026. User request: establish the pedagogical order, then develop each hall.

Review: [all nine halls](../../research/possible-bodies/soft-bodies.html). [Learning arc](../../research/possible-bodies/soft-learning-arc.html).

## Progression

1. Deformation — jelly_cube and softmill: coefficients and a driven contact.
2. Cloth — cloth_straps and softstopscene: pinned boundaries and different landings.
3. Carousel — revolving_joy_ride and cloth_straps: a moving support beside a fixed support.
4. Breathing architecture — breathing_room and softbody_gallery_part2: pressure drives a pinned enclosure.
5. Contact — softbody_gallery_part2: compare groups, hold a pose and release it.
6. Sampling — rounded_softbody_test and frozen_glass_vessel: measurement beside an integrated, baked surface.
7. Affect — radiolaria: inspect the recipe behind biological resemblance.
8. Reaction–diffusion — turing_pattern_generator and reaction_diffusion: local exchanges and spatial patterns.
9. Entropy Morphogenesis — entropy_morphogenesis: distinguish a prescribed control from measured entropy.

Cloth precedes driven supports. Three halls absent from the portable museum plans are restored. All nine sequence rows, both plans, authored route, book markers, primary roles and Necklace passages agree. Fifteen primary passages accompany the actual works; primary is not a quota of one. Existing artifact multiplicities and inherited structure cells remain, with explicit floor covers and supported onward aisles. `floor-audit.json` records offsets and preservation. `before/` archives the previous sources and texts.

## Implementation

`commons/artifacts/timing_machines/soft_workshop.gd` binds to the real models in its own museum hall. Six buttons fit a compact 3×2 desk; a small translucent inclined readout reports model state. Rule cards follow the encounter. Artifact demo cameras and screen overlays do not displace the museum view.

The cloth lesson opts into fresh rest geometry on every rebuild: eight strips with top rows at 3.65m, adjustable pins and release. Ordinary placements keep their original setup. The breathing lesson opts into sine pressure in the script actually loaded by the registered scene. Gallery comparisons can disable additional variation and respawn. Radiolaria uses its own seeded random stream and replaces old generated containers; its colour control still rebuilds geometry, as the text explains. The Gray–Scott texture dimensions follow its field, and changing regime or seeding updates the visible texture immediately.

## Evidence and limits

The final nine runs passed 214 desktop checks. The content/runtime audit passed 114 checks; with 115 exact HTTP assets, the final audit passed 229/229. Each hall folder contains a receipt, detailed runtime report and engine log. Receipts include source hashes, original saved-hand checks and actual Godot screenshots. `content-checks.json` verifies ordering, preserved artifacts and floors, scene paths, primary passages and published assets when run with the corresponding options.

After runtime testing, a data-only correction aligned the nine stored primary orders. `roles-before-order.json` preserves the runtime baseline, and `encounter-order-check.json` proves that only these primary orders changed. The source validator accepts this exact delta; it rejects any other stale runtime source. The Necklace reader now enumerates rooms from the museum plan, then retains legacy rooms outside it. A unique-artifact index had omitted rooms that reused works; the check confirms all 161 museum rooms in order and all 189 previous index rooms retained.

Runtime review uses an added DesktopPlayer with its actual pointer/button collision path, in the real museum. It checks desk actions, selected model outcomes, physical aisle support, traversal and the offset exit. This does not certify the museum walker's complete interaction stack, human controller reach, comfort, Quest performance, every retained secondary artifact or every generated interior. The existing startup audio UID warning is recorded separately; captures are muted.

Later work: stronger lighting and closer specimen framing in the large courts; inspect inherited secondary interactions; more matched-condition comparisons; measure solver cost and generated-interior clearance; human VR review. Softness does not imply tearing or new connectivity. S in the final model is an authored parameter, not a measured entropy value. Increased damping in softstopscene is not an explicit frozen-vertex snapshot.

## Reproduce

Run from the repository:

```text
python -X utf8 ada_run/review_soft_all.py
python -X utf8 ada_run/check_soft_sequence.py --runtime
python -X utf8 tools/build_soft_sequence_review.py
powershell -ExecutionPolicy Bypass -File ada_run/publish_soft_sequence.ps1
python -X utf8 ada_run/check_soft_sequence.py --runtime --http
```

The runner preserves the open editor and saved hand. It owns only its isolated hidden review processes. Do not replay the one-time staging/writing/repair scripts over later work: they capture or reconstruct a dated state. The publisher validates source hashes and confines copies to the local encyclopedia research directory.

Next: **Isosurfaces / ISO_LookupTable**. First inspect its pedagogical order and existing collection, then test how a field sample becomes triangles, connectivity and possible passage. Continue the whole spine before the book-wide rewrite.
