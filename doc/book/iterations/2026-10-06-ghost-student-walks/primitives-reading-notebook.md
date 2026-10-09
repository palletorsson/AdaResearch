# A ghost student's notebook: Primitives

*Read on 6 October 2026, from `primitives-tutorial.md` and `primitives-final.md` (the complete readings of that day), one room at a time, the lesson in one hand and the essay in the other. I made every object in a small Godot 4.6 project of my own and ran it. I have no headset, so wherever the book hands the point to an XR hand, my hand is a few lines of code. Nothing here is a verdict on the book. It is what one slow reader met.*

![The objects I made, room by room](reading-objects.png)

---

## The rooms

**1 · Point Zero.** I typed the counter and ran it. The first number I saw was 39, not 0. The essay had said so: *its first number for you is not its first number.* Then I moved the reading into `_ready()`. In my fresh room the first reading happens at frame 0, so the label said **0** and stayed there. I understood the lesson (the place of an instruction decides when it runs), but for a moment the 0 looked like a broken program, not a single reading.
*Supplied myself:* the room. "Use the working project from Day Zero", and Day Zero is not in this book. I made a floor, a sun and a camera.

**2 · Point One.** A small white sphere hangs 1.12 m up, with a shadow from my own sun. I have no player to walk into it, so I dropped a ball on it. The ball came to rest at 1.30 m, on top of the sphere (1.12 + 0.14 + its own 0.05). With `boundary.disabled = true` the ball fell straight through to the floor. Seeing and touching are two constructions: here it became mine, because I felt it in numbers.

**3 · Point Coordinates.** The pickup is closed to me: `XRToolsPickable`, grip, carry, release. The other half, one point with two addresses, I could make. With the study moved two metres along X: `LOCAL (0, 1.12, 0)`, `WORLD (2, 1.12, 0)`. After my code-hand carried it: `LOCAL (0.333333, 1.32, -0.1)`, `WORLD (2.333333, 1.32, -0.1)`. The point did not become two things; I asked where it is from two places. That was the clearest moment of the first rooms.
*Where I had to think alone:* `point.position` printed exactly the same numbers as LOCAL, because the point's parent *is* the study. The lesson distinguishes them without saying that here they coincide.

**4 · Lines.** Two points one metre apart, a thin pink segment, `DISTANCE 1.0`. With `a - b` the segment shot off the other way and missed B: subtraction has an order, and I watched it go wrong. The line is not an object; it is recomputed from two positions every frame. The plus and the X: from the front the X crosses; from the side, the shadows come apart. I took `line_skin.gd`'s basis on trust, as the book allows. It is the essay's "shoulders of giants, in fog", and I could feel the fog.
*Lost me:* `DISTANCE 1.20000004768372`. The plus's span is 1.2. Nothing in the book prepares me for the eighth decimal.

**5 · Trace.** My hand drew a short walk: sideways, a turn up, a pause of one second, a way back. Thirty-four positions were kept, and the pause added none. The essay's sentence opened here: the counter keeps running, but the list does not know how long I waited. I released it (by calling the save myself, since my body has no `dropped` signal) and the drawing went into `user://ada_student_trace.scn`. Carrying it into the next room felt like the course's promise made literal.

**6 · Grid.** The first room I could do entirely on desktop. My bend arrived in pink; at 0.25 m the green copy kept a diagonal, at 0.50 m my bend became **a square**. *Is it still your bend at this size?* At 0.50, no. Dropping the height laid the green copy flat on the floor while the pink stayed in the air: one record, two representations, and the source still there to return to.

**7 · Triangle.** The printed corners `(0, 1, 2)` are the first three entries of my walk, which lie on one straight line, so the lesson answered: *"Separate the corners; lift one off the line."* The guard caught exactly my case. With `(0, 14, 24)` the message said *"Three positions; one face."* I saw three spheres and black edges, but no face. From behind, the face was there. Later in the lesson, "Read the construction" explains it: back faces are culled; walk around. But I met the absence before the explanation, and from the side where the label reads correctly.

**8 · Polythedra.** My three corners and an apex 0.6 m behind them became a closed tetrahedron, every front facing out. My walk became a solid. The book is honest that it only looks solid: there is no collider.
*Supplied myself:* "use the same CORNERS triple you selected there". The code ships with `(0, 1, 2)` again, so my choice did not travel; I had to remember it.

**9 · Cube.** Two cubes, one with the other diagonal, and a third of my own with corner 6 pushed back. The first cube's corner 6 stayed at (0.5, 1, 0.5). Moving a body and editing the data it is made from are different acts. The cubes float 0.7 m above the floor and the lesson does not say why.

**10 · Ignorance.** One function, three octahedra (0.3, 0.6, and my 0.45 with its top vertex pushed sideways). The function draws nothing; it returns positions, and the face renderer gives them a body. That separation became mine here.
*Lost me, a little:* the essay's room is about spheres and their rings and segments; the lesson builds octahedra. The lesson says the spheres come next. Read side by side, I was looking at one thing and making another.

**11 · Godot.** The resolution only changes while the sphere is held (`is_picked_up()`), so on desktop nothing would ever happen. I gave it a `held` flag. After 2.25 seconds the held sphere had 1 ring and 17 segments: not a rough sphere but a double cone. Its untouched neighbour stayed round, with its own mesh. The rings-only variant looks almost the same from the side; only from above would I see the difference the lesson asks me to compare, and it does not tell me where to stand.

**12 · Columns.** One waisted profile at 4, 6, 8, 12 and 16 sides, then my own profile (beads, then a point) at the same five. The waist and the beads are my rule; the facets are its sampling. Two decisions, visible in one picture. Nested loops stopped being abstract.

**13 · Profiles.** The O became a short hollow passage; with OFFSET −0.5 it sheared the other way; the C kept its gap through the whole sweep. The opening rides inside the letter's own outline.
*Supplied myself:* the font file and Godot's import step. The book says the font is "in this lesson's downloadable folder", and this reading has no link to it. I found it in the repository.

**14 · Portals.** I predicted before running, as asked. All four came out exactly: tolerance 0.01 → 48 sides; 0.05 → 24 (twelve sides miss by 0.07 mm); 0.005 → 48 again; one millionth with a budget of twelve → stops at 12, `met: false`. Two things I found that the lesson did not say: halving the tolerance from 0.01 to 0.005 changed nothing, because doubling takes coarser steps than my request; and "enough" can hinge on almost nothing. This room became wholly mine because I could predict it.

**15 · Melencolia.** The two cubes and the point stood as described, resting on the floor. Then the challenge without a recipe. I kept it small. A rule: five positions on a circle, kept untouched as a pink loop. A copy, with the third point lifted 40 cm. A face through entries 0, 2 and 4 of the copy. Two spheres of the same radius: a smooth one at the centre, a coarse one (3 rings, 6 segments) at the lifted point. The choice no calculation required: the point I took out of the pattern is the one that loses its detail.
Then a lesson in humility. I could not see my face, so I reversed the triple, using what the triangle room had taught me. The numbers corrected me: the face had been there all along, facing up, pale paper on a pale floor. I had applied a rule to a wrong reading of a picture. Over a dark floor it appeared.

---

## Day Zero, read last

*Read the same evening, after the fifteen rooms: `preface.md`, `day-zero.md`, and the student starter they point to.*

![Day Zero, and the four rooms that needed a hand, run in the starter](day-zero-and-four-rooms.png)

I came to Day Zero last, which is backwards, and it answered my first complaint. The room I had built for myself is a download: the student starter. I unpacked the zip into an empty folder, imported it and ran `main.tscn`. A pale room on a dark floor. A dark panel marked YOUR STUDY, with a running counter. A pink cube on a plinth. The desktop keys across the top of the window.

Day Zero asks for two changes, and both did what the page said, the first time.
- `count += 1` to `count += 2`: the counter went from 238 to 258 in ten frames.
- Key Energy on AdaRoom to 0: every cast shadow went, and the cube stayed readable in the sky and fill light.

Then the test of my second gap. I took the code exactly as the reading prints it for the four rooms that needed a hand: Coordinates, Lines, Trace, Godot. I put each script on the Study node of a copy of `main.tscn`, as the starter's guide says to do for another study. Then I pressed E. All four worked.
- `extends XRToolsPickable` parses, because XR Tools is in the starter.
- The starter's desktop player takes any `XRToolsPickable` it aims at, mine included. E takes the point, the mouse and WASD carry it, E lets it go, and it stays.
- Coordinates: LOCAL `(0, 1.12, 0)`, WORLD `(0, 1.12, -2.85)` from the first frame. In the copied scene the study already stands 2.85 m back, so the lesson's "move PointStudy" had happened before I touched anything. With `point.enabled = false`, E did nothing.
- Lines: the distance followed the end in my hand, from 1.0 to 1.29.
- Trace: 25 positions. On release, `point.dropped` saved them, and the archive read back 25 positions and 24 segments.
- Godot: held for 2.25 s, the sphere fell to 1 ring and 17 segments; its neighbour stayed at 16 and 32. Enter reset both.

Two of my failures were my own hand, not the book. My key taps were shorter than a person's: one pickup arrived four physics frames after I looked, and one polled Enter went unseen. Held like a real key, both worked.

Then the guide went on, and I found a second course. The starter carries its own Point One, Lines, Trace, Grid, Triangle, Polyhedra, Cube, Ignorance, Column, Portals and Composition, each with its own `TUTORIAL.md`. They are siblings of the reading's lessons, not the same lessons.
- Point Zero: the reading prints `Engine.get_process_frames()`; the starter counts its own `count` from 0. The essay's "first number" belongs to the first program. Day Zero's `count += 2` belongs to the second.
- Lines: the reading has me write `PointBody` and `LineSkin`. The starter supplies `PointHandle` and `Segment`, rounds to `"%.2f m"`, and puts the readouts above and behind the points.
- Trace: `user://ada_student_trace.scn` in the reading, `user://ada_point_trace_v1.json` in the starter.
- Triangle: one-sided and culled in the reading, two-sided in the starter.
- Coordinates, Godot and Profiles exist only in the reading. Trans_Pre and the colonnade exist only in the starter.

The starter's own record says so: Coordinates' starter version "is still pending". The reading never mentions the starter's studies.

The preface asks: "Naming what we borrow helps us return to it later." The starter does this well. `prepared/` and `addons/` are named as lent, and every supplied helper says what it does and what it leaves to me.

---

## Gaps for the teacher

1. ~~**Day Zero is assumed and not given.**~~ *Closed.* Day Zero and its starter exist; my reading did not include them. What remains is the join. The lessons never say how to put a script into the starter ("duplicate `main.tscn` and attach the script to Study" is in the starter's guide). And the names differ: `CounterStudy` and `counter.gd` in one, `Study` and `hello_world.gd` in the other.
2. ~~**The headset is assumed.**~~ *Mostly closed.* In the starter, rooms 3, 4, 5 and 11 run on desktop exactly as printed. One sentence is missing from the reading, which only says "grip": *On desktop, aim and press E to take the point; E again lets go.* The E key lives in Day Zero. (The guide also says desktop pickup moves the object in front of the camera, so the first carried position is a jump, not my motion.)
3. **The read-once experiment reads 0 in a fresh project** and looks like a broken program. One line ("in a fresh project it will freeze at 0; in the museum, at some later number") would save the confusion. *Day Zero adds a twin:* the starter's counter is a different program, counting its own `count` from 0.
4. **`point.position` and `to_local()` give the same numbers here.** Say so, and say when they part (does a held point change parent?).
5. **The readouts do not round.** The essay builds a thought on the museum card's two decimals, but the student's card prints six decimals and float noise (`1.20000004768372`). Either round (`"%.2f"`, `snappedf`) or say a sentence about floating point. *The starter's own Lines rounds to two decimals; the reading's code still does not.*
6. **The readout covers the figure.** At y = 1.6 it sits in the middle of the plus, the X and the trace. In the starter, the held point also sits on its own `POINTS` number. *The starter's own Lines puts its readouts above and behind the points.*
7. **Five millimetres or five centimetres?** The essay's red pen waits for 5 mm, and the lesson's recorder for 5 cm. Different recorders, the same words; name them.
8. **Grid does not scale.** A drawing of arm's length is crushed by a 0.25 or 0.5 m grid; the essay's museum grid enlarges small drawings five times first.
9. **The triangle's missing face comes before its explanation**, and from the side where the label reads correctly. Pale paper on a pale floor also disappears. Visibility depends on the room. *Reconsidered after the preface:* "Whenever possible, an encounter comes before its explanation." So the order is the method, not a flaw. What I lacked was a way to take the absence as an encounter rather than a fault: I assumed my code was wrong. The preface's next step would do it ("Predict what a small change might do"). For example: *Before you run, guess which side will show the face.*
10. **Selections do not travel.** Triangle's chosen corners must be retyped in Polythedra.
11. **The cubes float at 0.7 m** with no reason given.
12. **Ignorance's essay and lesson pick different works** (spheres in one, octahedra in the other).
13. **Rings and segments need a viewpoint.** Say where to stand to see each.
14. **Profiles needs a font and an import step** that the reading does not link.
15. **Two ways of carrying the drawing.** The essay describes the museum's route (a TraceData autoload, six corners, flattened on arrival); the student's code uses a `user://` archive. Same story, different machinery; a student reading both will look for the one they do not have.
16. ~~**The pink line nearly vanishes in a pale room.**~~ *Closed in the starter:* the dark study panel puts the line where it can be seen.
17. **Two courses under one roof.** The reading (the museum halls' tutorials) and the starter (its own `TUTORIAL.md` studies) teach the same rooms with different code, different helpers and different saved drawings. A student who has both needs one sentence: which to follow, or where they meet.
18. **The copied scene keeps the old wall text.** "The counter is yours to change." stays on the panel in every study made from `main.tscn`, after the counter has gone.

## What became mine

That a position, a surface and a boundary are three constructions. That a point can have two addresses without becoming two things. That a line is recomputed, not kept, and a trace is what you add when you want to keep something. That a list keeps order, not time. That a grid can turn a bend into a box. That three points need an order before they are a face, and the order decides its front. That a function can return a world without drawing it. That a rule and its sampling are separate decisions. That a stopping rule needs two endings, and "enough" is a choice.

## Closing

The counter by the way out was much larger than when I arrived, and some of that was mine: the walk I drew, the bend the grid flattened, the face I could not see and then could. Most of it was not. The teacher built these rooms for a future that changed while they were building, and it shows in small ways: a hand I do not have, a room I had to make myself, a number the card never rounds. It also shows in the care. Every lesson told me what was supplied and what was mine to do. Every essay asked a question the code could not answer for me. I could have generated something far more elaborate in each room. I did not, and the small things held: one ball resting on a sphere, one line pointing the wrong way, one pentagon with a point lifted out of it.

There is always another room. Transformation is next, and I am carrying a cube, a point, and a face that taught me to check before I believe what I see.

*Later, Day Zero.* Read last, it gave back the room I had made by hand, and a hand I did not have: the E key. With it, the code I had rewritten runs as printed. It also showed me that the book has two ways in, and that I had walked through only one. The preface says a student must be able to answer back. This notebook is my answer.
