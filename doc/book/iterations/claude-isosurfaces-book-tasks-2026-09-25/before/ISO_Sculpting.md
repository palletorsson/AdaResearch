# Add a contribution

<!-- @mc_sculpt_vr -->

When two rounded deposits meet, where does their seam go?

Begin with the two deposits inside the framed volume. Their centres are 0.90 metres apart and each radius is 0.30 metres. There is room between them. Press PAIR to bring their centres to 0.65 metres apart, then 0.45. Before each change, predict whether a neck will appear. The deposits keep their radii; the relation between them changes.

HOLD keeps the current surface beside the live volume. Now press ADD. A gold point marks where the desk places its quarter-metre brush contribution. Inspect the join from another angle before adding again. A short, located edit gives you something you can explain; repeated deposits combine before their effects become easy to separate.

In VR, move a controller into the framed volume and hold its trigger briefly. The active ADD or ERASE mode also applies to this hand gesture. The desk offers a repeatable location for comparison; the controller supplies your own. Move outside the volume and the brush no longer deposits. That frame is a limit of this instrument, not the edge of space.

The brush does not push a particular triangle into a new position. Its location is translated into the generator's coordinates and stored as a contribution with a centre and radius. The field combines sphere-like distance descriptions with a smooth blending operation, then extracts the surface again.

The changed join is therefore a result of several decisions: where you deposited, how wide the contribution is, how contributions are blended and how finely the field is sampled. Your gesture participates in the form without directly specifying every point of its boundary.

The gyroid changed a repeating spatial expression. This sculptor adds local descriptions to a collection. Both approaches return to the same task of finding a visible boundary from values, but they distribute authorship differently across the volume.

Press ERASE. It uses the same marked centre and nominal radius as ADD. Look for the new inward-facing boundary, then compare with your held surface. The earlier implementation accidentally turned erasure into another addition by discarding a negative sign. Here that sign survives into the field calculation.

At the lesson's selected level of zero, the distinction can be written as two operations. The brush field is distance from its centre minus its radius:

```glsl
// deposit
field = smooth_union(field, brush, blend);
// cut
field = max(field, -brush);
```

The cut is a new contribution to the recorded history. It does not remove a record of the earlier gesture. ADD after ERASE can fill some of the cut again; ERASE after ADD leaves the cut. Order has become part of the form. Subtraction also has a sharper junction here than the smooth addition. They are different operations, not perfect opposites or an undo command.

PAIR replaces the live history with the next pair of deposits. RESET returns the wide pair and ADD mode; both keep the held surface. The display records how many contributions remain. Two different histories can leave a similar-looking boundary, and the same number of records can describe quite different bodies.

The extractor still samples 64 points per axis. Your hand moves between samples and between recorded strokes. The brush cannot promise to keep every distinction in the gesture. There is also a less visible limit: after five hundred contributions the generator drops the oldest. A cut may remain in the history after the deposit it once cut has been forgotten. This instrument's memory helps make the body, and also decides what it can cease to remember.

<!-- @ -->

The next room scales the same field-making idea towards terrain. Ask what additional relations a volume can describe beyond the single upper height of a conventional landscape.
