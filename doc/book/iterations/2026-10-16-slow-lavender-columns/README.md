# Slower lavender and coral columns

Palle asks for slower mixing and a queer palette. The fixed proposal interval changes from 0.12 to 0.48 seconds; displacement bounds, seeds and paths remain. 180 seconds now reproduce exactly the previous 45-second coordinates. The columns recolour their two groups as lavender #b49af7 and warm coral #f58b91. Glass and structural materials remain neutral. Labels and current texts follow the change; the original hand-sized jar retains its red/blue palette.

Existing apparatus regression checks run via run.py: 49 pass. The actual museum probe runs with output tag slow-lavender-columns: 43 pass, including approach activation, pointer pause/resume and restart. Native images at the start and three minutes were inspected. Palette legibility under headset conditions remains a human check. Earlier review records remain untouched. No placement or hall-order changes.

Reproduce with run.py, then tools/run_encounter_probe.py Random_Entropy --sequence randomness --render --no-bridges --output-tag slow-lavender-columns --probe doc/book/iterations/2026-10-16-slow-lavender-columns/museum_probe.gd, then publish.py.
