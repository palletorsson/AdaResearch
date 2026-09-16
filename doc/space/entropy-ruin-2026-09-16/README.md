# Entropy: what still holds?

Requested reference: deteriorated classical columns and masonry, supplied by the user as two photographs. This is a procedural architectural staging inspired by their profiles, not a reconstruction of either site.

Random_Entropy now measures 17 × 31 m. Its first five artifacts retain their positions. The new `entropy_ruin` stands at (8,26), after the square glass field. The old exit moves from row 22 to row 30. All layers retain 17 columns. The museum floor is retained throughout.

Four fluted columns, capitals and a segmented lintel stand before twelve six-course wall stacks. There are 116 movable pieces. A local generator seeded with 79 chooses one exposed stack top every 0.65 seconds, after an initial arrival delay. The bottom two pieces of each stack remain. 84 pieces can fall; 32 retain their original positions. Every selected piece is still the same mesh, moved into bounded rubble. The foundations and shallow bed are additional fixed geometry.

RUN / PAUSE stops both selection and descent. ONE STONE pauses the sequence and places the next piece at its landing position. RESTORE restores all original transforms and stack membership, resets the seed, and remains paused. The simple accelerating descent and finite landing layout are authored; no structural collapse or thermodynamic process is claimed. Moving-piece colliders are disabled during descent and restored on landing. Rubble can overlap within the display bed.

Validation:

- `commons/testing/probe_entropy_ruin.gd`: source behavior, exact replay of order and landings, complete restore, finite population and termination, bounded rubble, pause, collider handoff, automatic completion without suspended pieces. Results in `unit.json`.
- `probe.gd` / `run_probe.py Random_Entropy`: actual endless museum, six artifact instances, 17×31 floor, native VR button signals, shared compact-console reach checks, glass field preserved, route support, intact/weathered captures. Results in `Random_Entropy-runtime.json`.
- The runtime logs retain existing project warnings concerning an audio UID, certificate store and shutdown leaks. No script errors occurred in these probes. No headset comfort or hand tracking test has been performed.

`final.md`, `artifacts.md`, artifact registry, primary ordering and both museum plans are updated. Review page: `/research/possible-bodies/entropy-ruin.html`.
