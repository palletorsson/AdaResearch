# A ghost student's notebook: the starter

*Read on 6 October 2026, after the Primitives reading and Day Zero. These are the twelve studies in the student starter, each with its own `TUTORIAL.md`, in the order its guide gives, plus the optional colonnade. I worked in my own unpacked copy of the starter. I made every edit each page asks for, and restored each one as told. I have no headset. Where a page says "hold", my hand was the real E key, sent through Godot's input to the supplied player. Where it says "walk", my legs were the supplied player's own capsule and `move_and_slide()`, at the 2.5 m/s that WASD gives; only the velocity came from my code.*

![One picture from each study](twelve-studies.png)

---

## The rooms

**1 · Point One.** Three labels, a sphere over two of them. I walked at each. I passed through the first and the second: 4.0 m of 4.0, twice. The third stopped me at z = −0.011: 0.389 m from the sphere's centre, its 0.14 radius plus the player's 0.24. Every edit behaved as written.
- A boundary of 0.5 stopped me 0.36 m sooner, in front of empty air.
- Both radii at 0.3 grew the surface and the boundary together.
- A surface of 0.3 over a boundary of 0.07 let me stand inside the visible edge.

A surface and a boundary are two decisions, and here I could measure the difference in centimetres.
*Loose thread:* the last line sends me to "Point Coordinates", which the starter does not have.

**2 · Lines.** 1.50 m, then 1.00 m, then upright and still 1.50 m, then `(-1.5, 0.0, 0.0)`, then 0.00 m and no segment. I carried one end around a 4 m square and back. The readings before and after were identical to the sixth decimal: `(1.25, 0.016564, -0.457526)`. It has kept no route.
*What I missed from the reading:* there, the reversed subtraction drew a segment that missed B, and I learned order by watching it fail. Here `show_between(a, b)` takes the two ends, so the reversal changes only a sign in the text.

**3 · Trace.** One loop kept 21 positions. A one-second pause: still 21. `spacing` 0.25: 8. `capacity` 32: the count stopped at 32 and the beginning went away. The pink dots on black made the loop easy to read.
Three surprises, all from the desktop hold:
- Taking the point makes it jump in front of the camera, and the jump is recorded. My drawing begins with a spur I did not draw.
- The held point follows my view. When I stepped back to look, it drew a long line.
- Ending the scene while holding counts as letting go, and letting go saves. Two of my test runs ended while I held the point, and the last one replaced my loop. (My runs ended by quitting; I did not try the editor's Stop button.)

**4 · Grid.** The first time, Grid showed "32 positions from Trace". That was not my loop but the drawing I was holding when a run ended. I went back, drew a loop with a tail, let go, then stepped back to look. 24 samples.
- At 0.25 m: 12 places, a square with a diagonal.
- At 0.5 m: 6 places, and the loop was gone: a T and a stroke.
- At 0.1 m: 21 places, a pixelated loop.

The pink original never changed. An index names a sample; an address names a place. I could count it.
*Small:* the page says "Find the bend you made in Trace". Trace asked me for a loop.

**5 · Triangle.** Entries 0, 8 and 16 of my 24. With the face off: a closed boundary around nothing. With `show_face = true`: a face that followed a carried corner, opened wide from its normal, and collapsed to a line with my eye in its plane. I carried B to the exact midpoint of A and C: no face from the front, the right or the left. Lifted a little, a sliver came back. The face is two-sided, so it never vanished from behind. My stumble in the reading does not exist here.
*Supplied myself:* why one corner stood half a metre behind the others. Entry 0 is where the point stood before I took it, not where my drawing began.

**6 · Polyhedra.** My triangle and a fourth point 0.7 m behind it. "4 positions / 3 faces". Carrying point 0 took all three faces with it. `[1, 3, 2]` made "4 faces"; removing it opened the room again. A hole can be an omitted connection: in the code, and in the readout.
*Lost me:* in the picture. The faces are flat off-white with no shading. From the right, open and closed were identical. From the left, the only difference was one thin edge seen through the opening. "Look into the opening": what is inside looks exactly like what is outside.

**7 · Cube.** Corner 6, pulled 0.2 m towards me, tilted only the pink triangle; the white one stayed. The other diagonal gave the same corners a different surface. `show_faces = false` left the edges. The diagonal was already there.
*Faint:* the crease. On flat faces, a 0.2 m pull shows only as a slight change of outline. At 0.35 it reads.

**8 · Ignorance.** A function that returns six positions. `octahedron_positions(0.75)` pushed every corner out, and one corner carried sideways left the rule behind. Beside it stands a SphereMesh with its edges drawn, so `radial_segments` 16 and `rings` 8 were both readable from the front. The essay's spheres and the lesson's octahedron finally stand in one room.

**9 · Column.** Lit stone at last. The facets catch the sun, so the waist, the bulge, the shorter column and 4, 6, 12 and 16 sides read at a glance. My own outline (0.12 near the bottom, 0.70 at the top) became a funnel. The outline was mine; the sides were its sampling.

**10 · Portals.** I predicted first, with 2n·sin(π/n): gaps of 0.283185, 0.071528, 0.017928 and 0.004485 m. The readout matched to the sixth decimal. 48 sides passed 0.01 and failed 0.001 without a point moving.
*Small:* the stroke casts a dark second ring on the backdrop, which can read as another guide.

**11 · Composition.** The middle pyramid, brought forward, covered its neighbours from the entrance but not from the side. For my arrangement I put the middle at (0.9, 0, 1.0). From the entrance it merged with the right pyramid; from the side the two stood apart while another pair overlapped. Moving a body is not editing it.

**12 · Rings of Ash** (optional). Twenty-five columns, red walls, a rose light at the end. I walked 8 m down the aisle. The labels sit at shin height, pale on pale. Close up, the bronze base hides them; from farther away they read. I did not do its `varied_forms` comparison.

**13 · Trans_Pre.** Numbers, not pictures, because a still cannot show a rate.
- Stage 0: still at 1.30 m, the clock counting.
- Stage 1: an even rise and fall between 1.05 and 1.55 m, 3 s a cycle. `travel` 0.4 widened it to about 0.9–1.7 m; `leg_seconds` 3.0 made the cycle 6 s.
- Stage 2: 45° a second, round in 8 s; with `TAU / 4.0`, round in 4 s.
- Stage 3: largest at the top.
- Sine: the same ends at the same times, slowing into each. It moved 0.023 m in the last quarter second before the top, against 0.127 m through the middle.

*Small:* at stage 0 the readout already shows a value for `t`, before the page explains `t`.

---

## Gaps for the teacher

1. **Coordinates is named but missing.** Point One and Lines both send me to "Point Coordinates" for a working hold and a frame. The starter has no Coordinates study; its own record says the revision is pending. A starter-only student meets the frame by name only.
2. **The desktop hold has three behaviours the lessons do not mention.**
   - The jump into the hold is recorded (Trace's spur; Triangle's entry 0 left behind in depth).
   - A held point follows the view, so looking draws.
   - Ending a scene while holding releases and saves, over whatever was saved before.

   The guide mentions the first; none of the lessons say any of them. "Release your drawing before leaving" protects against losing a drawing. The danger I met was the opposite: keeping one I did not choose.
3. **Bend or loop.** Trace asks for a loop. Grid, Triangle and Polyhedra look for "the bend you made".
4. **The flat two-sided material** spares me the culling surprise, but it removes the light that shows an inside (Polyhedra) or a crease (Cube). Those two lessons are about exactly that. Where the material is lit (Column, Composition), form reads at a glance.
5. **Lines' reversed subtraction happens only in the text.** With `show_between(a, b)` the drawing ignores my subtraction, so the order of subtraction is a sign, not an event.
6. **Small:**
   - `t` appears on the Trans_Pre readout before it is taught.
   - The Portals stroke's shadow ring can look like another guide.
   - The colonnade's labels are low, pale and half-hidden.

## What became mine

That an empty space can be made impassable: 0.36 m of air in front of a small sphere. That a relation keeps no route: identical to six decimals after a detour. That a list keeps order, not time: 21, and still 21. That an index names a sample and an address names a place: 24 samples, then 12, 6 and 21 places. That zero area is zero from every side. That a hole can be a missing row. That the diagonal was already there. That a function returns data and draws nothing. That an outline and its sampling are two decisions. That "enough" is a choice I can predict to six decimals. That moving a body is not editing it. That time can be carried into a position steadily, or by a sine.

## The two courses, side by side

I have now walked both ways in. The starter closes many of my reading gaps:
- the room and the desktop hand (1, 2);
- the rounded distance (5);
- readouts above and behind the figure (6);
- the face that does not vanish (9);
- sphere and octahedron together (12);
- drawn edges (13);
- dark backdrops (16).

It is careful everywhere: each page names what is lent, and each did what it said.

It also trades some felt moments for safety. In the reading, a face vanished and taught me to check before believing; a subtraction missed and taught me order. Here neither can happen, and the inside of a solid is harder to see. The reading's clearest room, Coordinates, has no starter version yet.

## Closing

Twelve rooms, and every page held. I supplied almost nothing: the starter, and a little patience with the hold. Where understanding became mine, it was through a number I could check against a promise: 0.389 m, 21 and 21, 0.004485. Where the instructions lost me, it was never the code. It was the hold, which jumps, follows my eyes and saves when I leave. And it was the flat white, which makes the inside of a solid look like its outside.

The guide ends at Transformation, and so do I. The cube rises, turns and grows; it is largest at the top. There is always another room.
