# Curtains — a colour walk

Five soft curtains now form a procession beside the carousel in Endless Museum.
The original rear doorway is retained and its cloth also fits its frame.

- Coral: a full top edge, free lower cloth.
- Rose: two pinned top corners per strip.
- Violet: one top corner, alternating left and right.
- Blue: alternating long and short strips.
- Mint: short central strips form an opening.

Each gate has ten strips, a dark frame, readable captions on both sides and a flat
colour runner. The first full-length curtain is three metres high. The top pins
meet the crossbar underside; side posts leave two centimetres of clearance.
Length variation changes the hem, while all top attachments stay on the beam.

The old artifact duplicated a scaled live SoftBody3D template. It now constructs
each mesh at its intended rest size. Existing lesson subdivision settings and
controls are preserved. Support-only changes keep the same simulated bodies.

42 native walkway checks and 30 existing Cloth Physics checks passed. A finite
colliding capsule crossed all five gates, finishing at map z=28.03.
Cloth moved during contact; the largest measured attachment error after passage
was 0.000015 metres. The earlier lesson still supports its
real pointer controls, corner selection, release, rebuild and carried PointBody.
These are supplied native physics/input tests, not a headset or Quest benchmark.

No new script errors or missing-physics-space errors occurred. The logs retain an
unrelated pre-existing unrecognized UID warning. Tutorial, final and technical
texts remain byte-identical; this is an installed museum variation around the
existing moving-support lesson. The current map and museum-plan placements match.

Replay: `python tools/run_encounter_probe.py SoftBodies_Carusell --sequence softbodies
--render --no-bridges --output-tag curtain-walkway --probe tools/probes/curtain_walkway.gd`
