The previous room asked when a finite model was enough to hold a distinction. Here we make that question move. Add a division, then another. **What would count as arriving?**

<!-- @combine_portals -->

Begin beside an early faceted ring. Follow a straight edge around its opening, then look along the progression. Choose a later ring that seems round enough from where you stand. Keep that choice in mind as you approach it. Does the edge you had stopped seeing return?

There are twenty members in this family. The first uses three divisions in each of the torus's two surface directions. Each following member adds one in one direction and two in the other. Both are changing; the last has twenty-two and forty-one.[^portals-mesh]

At the side instrument, use **NEXT RING** and **PREVIOUS** to select a member. It turns gold. Find the selected ring in the space. The button directs your attention while leaving your body where it is.

The display names the two subdivisions and counts the mesh's triangles. It also names a **separate unit polygon**. This is a simpler question placed beside the torus: how closely does a regular polygon's perimeter approach the circumference of a circle of radius one?

Predict which way its gap will move when you select a finer ring. Compare the numbers, then look at the object again. The display borrows the torus's ring count as the polygon's number of sides. Its code calculates:

```gdscript
var perimeter: float = 2.0*mesh.rings*sin(PI/mesh.rings)
```

Each straight side is a chord between two points on the circle. Adding sides brings their total length closer to the circumference, which the panel labels **Circle**. The positive gap belongs to this planar comparison; a measure of the whole torus's accuracy would need its own definition.[^portals-circle]

This is **convergence**: as the rule continues, the perimeters approach a limit. They can get arbitrarily close to the circumference, though no finite polygon in this sequence has that exact perimeter. Twenty examples show part of an approach that can continue beyond the display.

For this comparison, choose a small positive gap you would accept for a use you can describe. Check whether any displayed member meets it. That bound is a **tolerance**: a criterion for stopping. It may select a different member from your earlier judgment of “round enough”. What matters for this use?

Now predict what **REVERSE** will do. Press it and inspect the beginning again. The positions stay; the same family of resolutions appears in the opposite order. What the earlier arrangement kept for later has become the entrance.

The sequence had quietly given refinement a direction. Does walking toward more sides still describe what you want from these forms? Keep one corner in mind that you would lose by smoothing it away. Reverse again if you want to restore the earlier order.

Through this change, the openings remain. More divisions need not give the body another kind of passage.[^portals-hole]

<!-- @achilles_tortoise -->

Two figures wait along the next instrument's track. Before pressing **NEXT STEP**, point to where you think Achilles will go. Press once, compare, and predict again.

Achilles is placed where the tortoise was. The tortoise moves ahead again. In this construction the gaps halve at each stage. The marked end of the track stays where it is.[^portals-zeno]

The script chooses Achilles' next position with:

```gdscript
var a_z := -track_length * (1.0 - 1.0 / pow(2.0, float(n)))
```

Here `n` is the stage number. The minus sign sends him along this track's negative Z direction. The first stage covers half the track, the second three quarters. Each leaves a smaller distance to the same limit.

Continue to stage ten. The instrument now holds. Read **A to limit now**. Achilles' anchor still has about 5.86 millimetres to the limit, although the bodies may look as though they have arrived together. His visible body is larger than the gap. The display has a last stage. Does the sequence it represents have one?

Press **RESTART**, then **PLAY**, and pause during a movement. Compare **A to limit now** with **A to limit at stage target**. One describes where the marker is; the other describes where this movement was taking it.

The program gives these stages a regular schedule and adds movement between them. That schedule does not reproduce the shrinking durations of a continuous runner's journey. An infinite subdivision can have a finite total; it does not make ordinary motion impossible.

This instrument can pause while the museum continues. We have held one process still long enough to ask about it.

<!-- @ -->

Twenty rings. Ten stages. Each display has a last member because someone chose where to stop building it. Neither mathematical approach acquires a last step merely because its display has ended.

**The limit gives the sequence a direction. It does not tell us where to stop.**

Name something your stopping criterion leaves open for another visit. A finite encounter can teach us something without exhausting what its rules make possible.

Melencolia gathers the tools we have learned to use. They can give exact answers. What would make the work complete?

[^portals-mesh]: The installed `combine_portals` uses [Godot 4.6 TorusMesh](https://docs.godotengine.org/en/4.6/classes/class_torusmesh.html). `rings` divides the torus around its opening; `ring_segments` divides the tube's cross-section. The authored linear rule uses `(3 + i, 3 + 2i)` for indices 0–19. The panel calls the latter **Tube sides**. Its selection highlights a mesh; these rings do not implement teleportation.

[^portals-circle]: For a regular `n`-gon inscribed in a unit circle, each chord has length `2 * sin(PI/n)`, giving perimeter `2 * n * sin(PI/n)`. `TAU = 2 * PI` is the circle's circumference. In exact mathematics the perimeter is smaller for every finite `n ≥ 3` and converges to `TAU`. A useful tolerance can be met before equality. A floating-point calculation may eventually round a gap away; that is a separate computational event. The [technical chapter](/book?map=Primitives_Portals&section=technical) explains what the instrument measures.

[^portals-hole]: These subdivisions preserve the torus surface's central opening. Resolution and topology are different questions: more triangles do not give this surface another hole. Whether an opening is a usable passage also depends on scale, placement and collision. Keep that distinction for the later investigations of possible spaces.

[^portals-zeno]: Aristotle discusses the Achilles argument and the bisection argument in [Physics, Book VI, parts 2 and 9](https://classics.mit.edu/Aristotle/physics.6.vi.html), translated by R. P. Hardie and R. K. Gaye. This exhibit stages a particular halving construction: `A_n = L(1 − 2⁻ⁿ)` and `T_n = L(1 − 2⁻⁽ⁿ⁺¹⁾)`. Its six-metre track ends the display at stage ten, leaving `6/1024` metres between Achilles' anchor and the limit. Autoplay schedules stages two seconds apart and eases movement for one second. That theatrical timing is part of the implementation, not a proof about the duration of a physical race.
