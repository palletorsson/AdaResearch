# A line in the black room

29 September 2026. The author asks to halve the held black point and use the prepared 4 × 4 entrance bay in Point_Lines for an improved, adjustable line.

- The held black point in Point_Coordinates now has a 7 cm radius rather than 14 cm. Its spherical collider matches. The white Point One spheres and separate force point retain their sizes.
- Added `line_black_box` to the empty bay at source cell (2,2), with a half-cell X/Z offset. Its four-metre footprint fits x=1..4, z=1..4. The author's structure and utilities are unchanged. The room has a north entrance and an east passage onward.
- Matte dark walls, a pale slender segment, small pearl handles with pink collars, restrained lighting and a live metre readout. Both ends use the production XR Tools pickup driver. A released end stays where it was left.
- Reused `commons/primitives/line/line.gd` for the connection and distance calculation. This introductory instance uses a smooth 32-sided rod and disables the older artifact's integer-triggered jitter. Other line placements retain their existing behaviour.
- A wall reset works through pointer click or near-hand entry. It refuses to move an endpoint currently being held. The readout and line settle after physics and render callbacks; no visible stale segment is left when endpoints coincide.
- The existing walk-in architecture hook reports only full-height partitions to museum navigation. Roof, deck and lintels must not classify the whole room as a solid obstacle.
- Added a short opening to Point_Lines/final.md around the new first encounter. Corrected the later references to the now-separate Coordinates hall. Updated the small-point sentence and its implementation reference.

Validation: 32 checks in the actual rendered Point_Lines museum and 20 in Point_Coordinates passed. These include production pickup/release, changing and vertical lines, coincident endpoints, reset through both input routes, doorway collision, supported floors, navigation cells, coordinate readouts, target activation and the reduced radius. Screenshots come from those native scenes. No headset or learner trial.

The harness still reports the pre-existing audio-bus UID warning (`uid://rwex60pqapc`), also present in the preceding coordinate-frame run. This pass does not change audio-bus configuration. The final runs have no GDScript errors.

The portable tutorial kit remains a separate pending task. No new standalone tutorial or redesign of the rest of the hall was undertaken here.
