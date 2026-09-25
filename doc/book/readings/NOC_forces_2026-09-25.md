# What the forces chapters can learn from *Nature of Code* ch. 1–2

Read 25 September 2026 against the thirteen `final.md` of the `forces` sequence (12,424 words, skeptic-verified in the spine reading; all ten earlier tasks done): Act1 653 · VFM_02 601 · Act2 961 · Launch 722 · Motion 943 · Act3 864 · Act4a 1,196 · Act4b 1,028 · Choreography 931 · Gravity 1,019 · Legs 1,004 · Arena 1,162 · Act5 1,340. Sources: https://natureofcode.com/vectors/ and https://natureofcode.com/forces/ (Daniel Shiffman, 2nd ed.; about 21,000 words together). No agents.

## Where Ada is ahead (nearly everywhere that matters)

NOC's two chapters build a Mover class in pixels and frames; Ada's thirteen halls build the same ladder in metres, seconds, kilograms and newtons, with a body in the room. What Ada has that NOC does not:

- **The receiver gives the number its meaning.** Act3's `=` versus `+=` — one body replaces its velocity with the field sample, the other accumulates it — is NOC's whole distinction between a random walker and a random acceleration, done as an instrument you can REVERSE mid-run. "A bare arrow cannot tell us whether it names a direction, a velocity, an acceleration or a force."
- **Zero is not nothing.** VFM_02's CANCEL: displacement zero, distance accumulating; the mower's signed work versus path versus cut grass. NOC has no account of what a record keeps.
- **Units and the engine.** kg/s times m/s is newtons; `apply_central_force` integrates, it does not set; the boundary that rebounds one body and lets another through; locks that are not balance; FRAME EXIT that is not a wall.
- **The body.** WALK slows the stick; the field in Act5 carries the visitor and never divides by mass; the plank that repaired a promise. NOC's world has a mouse.
- **Softening footnoted (Plummer), NUDGE measured** (3 cm → 7.6 cm in four seconds, and the chapter says what that does and does not establish), the support polygon, the momentum carts, the crab's selection made visible.

## What to learn (eight items, each already performed by a hall and left unnamed)

1. **Newton's laws are performed and never named.** VFM_03's opening — the push lasts one second, the cube keeps going — *is* the first law, and the hall's title refutes Aristotle's two-thousand-year rule that a moving thing needs a force to keep moving; MASS is the second law; and Gravity's `mutual = false` is the third law switched off by one boolean ("the source is held in place by the implementation"), restored at the three-body floor ("an equal and opposite force on its partner"). NOC's restatement of the third law is the cleanest around: forces occur in pairs, on *different* objects — the truck on the icy street, the roller skates. Name each law where the hall does it, after it has been watched, with one footnote (Newton 1687).
2. **"Acceleration has no memory; position must remember."** NOC's central programming lesson: forces accumulate into acceleration, which is cleared every step, or the wind adds onto itself; velocity and position carry the past. Ada's Motion says "the command has ended, but the damping has not" and Act3 shows accumulation, and neither says which quantities remember. One sentence, in the sequence about records.
3. **Galileo and the missing division.** Act5's field "never divides a force by the receiver's mass. A one-kilogram body and a four-kilogram body receive the same velocity increment" — that is why all bodies fall alike (Galileo's two balls, 1589 by legend), and Gravity's `pair_force / masses[i]` shows the mass cancelling. Weight versus mass has not been said once in thirteen halls (Legs: "ten kilograms are represented as acting" — the kilograms are mass; what acts is weight).
4. **Linear drag is not air.** The corridor's `-c * v` is the linear rule (a coefficient in kg/s); NOC's is the quadratic one, ½ρv²ACd, which is what air at speed does (its coefficient in kg/m). The chapter already says the media are named, not simulated; say which law it is, and that a fast cube in real air would meet the square of its speed.
5. **The brake's guard and the step.** Motion's BRAKE "weakens near rest to avoid sending the cube back the other way" — NOC's Exercise 2.8 says why: a resistance applied for a whole step can carry a body through rest and out the other side, which no real drag does; the fault is the step's. Oscillation already says "the finite update can introduce numerical error"; connect the two.
6. **Two bodies are solved; three are not — and yet.** Gravity's three-body floor never says that the pair's orbit has a closed form and the triple has none (Poincaré, 1890), nor that the rear sculptures (`nbody_simulation`, `example_2_9_n_body_attraction_vr`, `gravity_well`, `chaos_attractor` — none mentioned) do every pair, n² of them (Barnes–Hut is the way out, NOC says). The edge the chapter wants ("a tangled trail alone would not establish chaos") has a footnote waiting: periodic three-body orbits exist — Moore's and Chenciner–Montgomery's figure-eight (2000) — so *no general solution* is not *no order*.
7. **Calder is standing in Oscillation.** NOC's Forces chapter opens on Calder's mobiles; Ada's Act4b places `calder_mobile` and `calder_object_mobile` (τ = w·d at every arm, disc masses from area, thickness and aluminium density) and says "other balances remain farther into this hall". The mobile is the torque crank of Act2 hung up as sculpture. Name him. And Act1's "This far, this way" has a pre-Western instrument: the Marshall Islands stick charts, swell directions tied into a frame of fronds — NOC's Vectors opener, and this sequence's Ba-ila.
8. **Random acceleration is a walker with continuity.** NOC: randomising acceleration rather than velocity gives "a kind of continuity and fluidity that the original random walker lacked". Act3 has the mechanism (`+=`); Random_Walk, three sequences on, has the replaced-velocity walker. One forward link: "the beads in the terrarium will replace their velocity every step; that is why they jitter and this one glides."

## Not to learn

- Pixels per frame as units; "1 time step = 1 frame". Ada's insistence on metres and seconds is the better teaching.
- The copy bug (dividing a shared force vector mutates it for the next mover): an artefact of p5.Vector; Ada hands forces to the engine.
- Mass drawn as diameter (and the √mass correction): Motion already says the silhouette cannot tell you the mass.

## Tasks

Eight tasks appended to `doc/tasks/book_forces.json` (`.011`–`.018`), source "Nature of Code ch. 1–2 reading, 25 Sept", shown on `/book-tasks` under forces. Not applied.
