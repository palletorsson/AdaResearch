# Carry, compare, then read the procedure

**Learning elements — proposed focus**

_The labels below set the revision focus; the existing lesson still needs alignment._

- Rejection sampling
- Minimum spacing
- Attempt budgets

1. At **randompoint**, carry the point within its metal frame, then out of its plane. Release it. Compare local x/y with local z. Release does not draw a replacement position.
2. At **randompoints**, compare the two framed slabs, each 0.90 × 0.90 × 0.12 m. Move your viewpoint before treating projected overlaps as close spatial pairs.
3. Use REDRAW, then NEW SEED. A repeated construction requires the same settings and generator call order as well as the seed.
4. LOAD alternates the initial request and four times that request: 24 / 96 in this map. Dimensions and minimum distance stay fixed. Read filled/unfilled separately from kept/refused candidates.
5. RULE alternates minimum-distance rejection and the clamped Gaussian. Red shells in the latter are comparisons with a reference spacing, not breaches of a promise the Gaussian made.
6. Return to spacing, carry a point into another shell, release, then RESTORE. Separate a constraint at construction from the first artifact's continuously applied coordinate clipping.

Read these actual source passages after the encounters.

The single point clips coordinates on each process frame:

```gdscript
if clamped != pos:
	point_node.position = clamped
_update_label(point_node)
```

The bench counts neighbours; this branch changes no position:

```gdscript
if a.position.distance_to(b.position) < blue_noise_min_dist - 0.001:
	touching += 1
	bad[i] = true
	bad[j] = true
```

Try a three-point overlap. Three coincident centres contain three close pairs, even though only three points change colour. The observer reports pairs, not half the number of coloured shells.

## The galleries extend the route

7. At **WhiteNoiseGallery**, follow a row of the existing 100 × 100 field. Compare height with colour. Both use the same uniform draw; adjacent heights do not constrain one another.
8. Try its WHITE, PINK, BROWN, BLUE and VIOLET controls, then STOP. Compare sound while watching the image remain fixed. These are separate generators. Reading the field into sound is a proposed extension, not an implemented control.
9. At **NoiseColors3D**, compare the five illustrated rows, then audition the sounds. Examine the tall plateaus: display clamping makes different powers share one height. The bars are not a measured audio spectrum.
10. Read the BROWN accumulation and VIOLET difference passages in final.md after listening. What does each retain from its previous step? Carry several discoveries out of the room; every work need not answer the first question in the same way.
