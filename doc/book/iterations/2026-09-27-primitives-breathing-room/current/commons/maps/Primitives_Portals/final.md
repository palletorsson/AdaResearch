# Circular Approximation and Limits

The previous room asked when a finite model was enough to hold a distinction. Here we make that question move. Add a division, then another. **What would count as arriving?**

<!-- @combine_portals -->

Begin beside an early faceted ring. Follow a straight edge around its opening, then look along the progression. Choose a later ring that seems round enough from where you stand. Keep that choice in mind as you approach it. Does the edge you had stopped seeing return?

These are portals for looking through: twenty rings that frame the space beyond. Near the beginning, their flat patches are easy to see. Each following member divides both surface directions more finely.[^portals-mesh]

At the side instrument, use **NEXT RING** and **PREVIOUS** to select a member. It turns gold. Find the selected ring in the space. The button directs your attention while leaving your body where it is.

Beside the counts, a rose-coloured polygon sits inside a grey circle. Selecting a finer ring adds sides to the polygon while the circle stays. This separate, flat figure borrows one of the torus's subdivision counts to ask a simpler question: how closely can straight sides approach a circle?

The circle has radius one. For its inscribed polygon, the code calculates:

```gdscript
var perimeter: float = 2.0*mesh.rings*sin(PI/mesh.rings)
```

Each straight side is a chord between two points on the circle. Adding sides brings their total length closer to the circumference, which the panel labels **Circle**. The positive gap belongs to this planar comparison; a measure of the whole torus's accuracy would need its own definition.[^portals-circle]

![Three states of the museum diagram: three, eight and twenty-two straight sides approach the same circle.](/book-review/doc/book/figures/Primitives_Portals/portals-visible-limit.png)

*The corner becomes harder to see. The gap remains. These are three states of the same diagram beside the rings; the numbers compare boundary lengths.*

This is **convergence**: as the rule continues, the perimeters approach a limit. They can get arbitrarily close to the circumference, though no finite polygon in this sequence has that exact perimeter. Twenty examples show part of an approach that can continue beyond the display.

Suppose you needed this polygon for something you were making. You could set a small positive gap you were willing to accept and stop when a member met it. That bound is a **tolerance**. It might lead you to a different choice from the ring that first looked round enough.

Press **REVERSE** and return to the beginning. The positions stay; the same family of resolutions appears in the opposite order. What the earlier arrangement kept for later has become the entrance.

The sequence had quietly given refinement a direction. Walking the other way, corners become available again. You might want one of those corners. Adding more sides would take it away.

Through this change, the openings remain. More divisions need not give the body another kind of passage.[^portals-hole]

<!-- @achilles_tortoise -->

Two figures wait along the next instrument's track. Press **NEXT STEP** and watch the space between them.

Achilles is placed where the tortoise was. The tortoise moves ahead again. In this construction the gaps halve at each stage. The marked end of the track stays where it is.[^portals-zeno]

The first stage carries Achilles halfway along the track, the second three quarters of the way. Each new stage leaves half the remaining distance. The endpoint is close enough to point to. The rule keeps putting him short of it.

At stage ten, the instrument holds. The bodies may look as though they have arrived together, but Achilles' anchor is still less than six millimetres from the limit. His visible body is larger than the gap. The display has a last stage. Does the sequence it represents have one?

Use **RESTART**, then **PLAY** to let the figures move between stages. Pause them partway through a movement. The panel keeps both distances in view: where Achilles is now, and where this step was taking him.

The program gives these stages a regular schedule and adds movement between them. That schedule does not reproduce the shrinking durations of a continuous runner's journey. An infinite subdivision can have a finite total; it does not make ordinary motion impossible.

This instrument can pause while the museum continues. We have held one process still long enough to ask about it.

<!-- @ -->

Twenty rings. Ten stages. Each display has a last member because someone chose where to stop building it. Neither mathematical approach acquires a last step merely because its display has ended.

**The limit gives the sequence a direction. It does not tell us where to stop.**

There may already be a ring you want to return to. A finite encounter can teach us something without exhausting what its rules make possible.

Melencolia gathers the tools we have learned to use. They can give exact answers. What would make the work complete?

[^portals-mesh]: The installed `combine_portals` uses [Godot 4.6 TorusMesh](https://docs.godotengine.org/en/4.6/classes/class_torusmesh.html). `rings` divides the torus around its opening; `ring_segments` divides the tube's cross-section. The authored linear rule uses `(3 + i, 3 + 2i)` for indices 0–19. The panel calls the latter **Tube sides**. Its selection highlights a mesh; these rings do not implement teleportation.

[^portals-circle]: For a regular `n`-gon inscribed in a unit circle, each chord has length `2 * sin(PI/n)`, giving perimeter `2 * n * sin(PI/n)`. `TAU = 2 * PI` is the circle's circumference. In exact mathematics the perimeter is smaller for every finite `n ≥ 3` and converges to `TAU`. A useful tolerance can be met before equality. A floating-point calculation may eventually round a gap away; that is a separate computational event. The [technical chapter](/book?map=Primitives_Portals&section=technical) explains what the instrument measures.

[^portals-hole]: These subdivisions preserve the torus surface's central opening. Resolution and topology are different questions: more triangles do not give this surface another hole. Whether an opening is a usable passage also depends on scale, placement and collision. Keep that distinction for the later investigations of possible spaces.

[^portals-zeno]: Aristotle discusses the Achilles argument and the bisection argument in [Physics, Book VI, parts 2 and 9](https://classics.mit.edu/Aristotle/physics.6.vi.html), translated by R. P. Hardie and R. K. Gaye. This exhibit stages a particular halving construction: `A_n = L(1 − 2⁻ⁿ)` and `T_n = L(1 − 2⁻⁽ⁿ⁺¹⁾)`. Its six-metre track ends the display at stage ten, leaving `6/1024` metres between Achilles' anchor and the limit. Autoplay schedules stages two seconds apart and eases movement for one second. That theatrical timing is part of the implementation, not a proof about the duration of a physical race.
