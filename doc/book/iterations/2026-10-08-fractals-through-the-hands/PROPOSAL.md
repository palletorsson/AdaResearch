# Fractals through the hands

8 October 2026 · **Proposal, not an implemented overhaul.**

Forces asks what follows a push. Fractals can ask what follows another application of the same rule. The surprise can be perfectly deterministic: more pieces, less material; a longer boundary between unchanged endpoints; an opening that exists but cannot admit us.

Keep the seven-hall order. Develop one primary interaction for each principle, complete its runnable tutorial, then curate the surrounding collection. Begin with a hand-controlled recursive canopy, while repairing the short Recursion prerequisite lesson first.

## What the audit found

The live sequence definition contains seven halls, with 65 artifact placements (47 distinct keys) in their map data. Their scene references resolve. This is a source audit, not a new runtime verification. The seven photographs below come from saved museum runs on 14 and 25 September; they show our starting material.

Six tutorial.md files have no GDScript blocks: they are useful encounter guides, but not the complete, tested reconstructions now required of the tutorial track. The opening has eight GDScript fragments and undefined drawing helpers; it introduces factorial, memoisation, tail recursion and a complex-to-pixel mapping before giving the student one finished spatial construction. The final.md texts already follow specific encounters and have much more continuity with the rooms. Revise their interfaces and observations after each build; do not discard their reflective argument.

The existing threshold walk, canopy, Cantor gaps, Koch measurement and Menger flight are strong starting points. Most primary lesson controls are console buttons. Hand-led control should change a meaningful geometric quantity or select a particular descendant. A nearby button remains useful for discrete NEXT, UNDO and RESET; replacing it with a meaningless gesture would add work without understanding.

## What should carry the lineage

The familiar **point** can return as a grip, cursor and size probe. The **line** becomes a segment and then a branch. The **cube** returns for volume selection. Reuse their construction and appearance where appropriate; do not force all geometry into a sphere class. Saving one particular recipe or record between rooms is a separate feature that must be implemented and tested before the tutorial promises it.

The student already brings transforms, arrays, functions, seeds and the current/next pattern from the earlier spine. Introduce one new generative operation, then return to those tools. A direct recursive call, a queue that evaluates a branching rule, and a numerical recurrence are distinct implementations. This sequence is well placed to make those distinctions visible.

[The Nature of Code, chapter 8](https://natureofcode.com/fractals/), supplies a useful progression through recursive functions, finite stopping conditions, segment replacement, trees and symbolic rewriting. Ada can add the bodily question: what do those constructions let us enter, hold or traverse? Its existing Cantor grammar already makes a precise handoff to L-systems. Julia and Mandelbrot remain optional extensions; there is no need to add complex-number iteration to this main route now.

## Spatial rhythm

**Unfold → branch → cut → trace → enter → arrange → compose.**

Each hall gets a reachable small model, one large consequence where scale is useful, and an open route to the next encounter. Place optional comparisons along the perimeter. Keep the input visible alongside its result. Highlight one generation or ancestry path before colouring the whole structure. Only one spatial instrument should dominate the first view into a room.

Use the same rose grips and readable state labels developed in Forces. Allow controlled exuberance after the small rule can be read: a canopy above us, a folded route, a porous cube to fly through. Keep stable floors and exits; distinguish a generated surface from its collision. Fractals can be wild through scale, multiplication and exclusion without every example acquiring a physics simulation.

## Tutorial and reflection

For each hall, tutorial.md declares the inherited code, supplies every new dependency and shows one complete minimal working example. A student must be able to make an independent change and predict an observable difference. Geometry, readout and test must evaluate the same rule. final.md can ask what that rule permits or excludes, what an ideal limit promises, and where a bodily limit interrupts it. Neither text has to explain every artifact.

Repeated form is not automatically a fractal. Finite displayed detail is not demonstrated infinity. A branch count is not a measure of entropy or freedom. A golden proportion is not proof of beauty. These are useful distinctions to experience, not a list of caveats to recite at the door.

## First build and acceptance

1. **Repair the opening lesson.** One bounded frame generator from the existing line construction. Declare its base case and test it in Godot; defer unrelated programming topics.
2. **Pilot the canopy.** Two point grips, one fork, one visible generation and one large preview. Preserve the existing console and primary tree until the replacement works. Hold randomness fixed. Make a local edit and show which descendants change.
3. **Run the complete interaction.** Exercise desktop and actual XRTools pickup paths with supplied poses; verify release, reset, subtree isolation and finite allocations. Capture the museum at eye height and from above. Physical headset comfort still needs a human trial.
4. **Extend only after that comparison.** Apply the proven interaction language to Cantor and Koch, then Menger, then the shorter mapping and composition rooms. Test the saved-record handoff before writing it as a learner action.

The suggested assertions below are an implementation contract. They have **not** been run in this proposal pass. Existing September test reports are historical evidence, not a pass for these new designs.


## 1. Fractal_Recursion — Again — until what?

**Existing anchor:** `fractal_recursion_2 / threshold_walk`

![Shrinking coloured doorway frames stand beside the existing square-recursion desk inside the museum.](images/Fractal_Recursion.png)

*Existing museum capture · 2026-09-25. The proposal below is not pictured.*

**Keep:** The square desk and matching shrinking doorways already connect a repeated scale operation with the visitor's body. MORE, LESS and layout controls expose finite terms. Keep this encounter.

**Proposed interaction:** Add a nearby held handle that unfolds one generation at a time. A separate, clearly marked scale handle changes the reduction factor. Highlight the current call, parent and stopping condition. Keep a stable bypass beside the doorway sequence.

**Learning elements:** recursive call, argument change, base case, depth and size limits.

**One-paragraph lesson:** Return to the line/frame construction the student already knows. Make one frame, call the same construction with a smaller size and one fewer remaining step, then stop. Show the complete small script and its supplied dependencies. The first independent change is the reduction factor; the student predicts the next size before running it. Factorial, memoisation, tail recursion and pixel mapping move out of this first lesson.

**Reflection:** The instruction can continue after an opening has become useless to this body. Computational continuation, visibility and passage have different limits.

**Test to write:** Depth zero emits nothing; three requested terms produce three frames when above the minimum size; adjacent sizes follow the declared factor. Boundary inputs terminate without removing the room's bypass.

**Carry onward:** A bounded generating function and an explicit record of the terms it produced.


## 2. Fractal_RecursiveTrees — One gesture, many descendants

**Existing anchor:** `recursive_tree_2 / branch_canopy`

![The museum canopy branches overhead, with smaller trees visible beside it.](images/Fractal_RecursiveTrees.png)

*Existing museum capture · 2026-09-25. The proposal below is not pictured.*

**Keep:** A large canopy already follows the growth study. The primary tree grows from queued branch records; its console changes angle, length and fork count. A second tree supports inspection of its existing structure.

**Proposed interaction:** Put two familiar point grips on a small parent-and-children model. Moving a grip changes a child direction; descendants inherit the local rule and the room-sized canopy previews it. Offer one-generation growth beside the hand. Begin with fixed deterministic geometry; use a held seed when later comparing irregular growth.

**Learning elements:** parent and child, local frame, branch record, inherited parameters, generation queue.

**One-paragraph lesson:** Extend the known line into two shorter children at its endpoint. Store start, direction, length and depth as a branch record. Reuse the previous stopping condition, then show how a queue lets the museum reveal a generation without pretending this source is a direct self-call. Compare two and three children only after the two-child construction works. Save a chosen rule and seed for later reconstruction.

**Reflection:** A small choice near the root can become the shape of the whole canopy. Repetition distributes an earlier decision; it does not make that decision inevitable.

**Test to write:** Every child begins at its parent's endpoint. A complete binary tree through depth four has 31 segments including the trunk. Altering the selected subtree leaves its sibling unchanged; replaying the same seed and rule reproduces the geometry.

**Carry onward:** A branch recipe, with a named root, local coordinates and optional fixed seed.


## 3. Fractal_CantorSet — Make room by removing

**Existing anchor:** `cantor_set; pagoda as the body-scale comparison`

![A narrow opening between pink Cantor-pagoda pillars frames the museum beyond.](images/Fractal_CantorSet.png)

*Existing museum capture · 2026-09-14. The proposal below is not pictured.*

**Keep:** The interval study already separates latest state, history and ghost removals. The pagoda turns repeated removal into gaps of different widths. Preserve those distinctions.

**Proposed interaction:** Let the player pull a removable middle-third handle, then apply that same cut to the current generation. Show only the newest rule application first; history stays optional. Bring the held sphere to the pagoda as a probe before trying the player's own body.

**Learning elements:** interval record, replacement, current and next arrays, retained length, history.

**One-paragraph lesson:** Reuse arrays and the current/next pattern encountered earlier in the spine. Replace each interval by its two outer thirds, keeping the source row intact. Count the survivors and sum their lengths. The learner changes one legal retained fraction in a clearly labelled variant, while the canonical thirds remain available for comparison. Save the generated intervals for the final hall.

**Reflection:** More pieces can occupy less material. A hole can admit a point, a sphere or a person differently; counting holes does not establish access.

**Test to write:** For the standard thirds rule, generation n has 2^n intervals and total length L(2/3)^n. Hiding history changes neither result. Ghost middles stay non-solid and the original record remains intact.

**Carry onward:** Ordered intervals, the rule that made them and a retained original record.


## 4. Fractal_KochSierpinski — The shortest way becomes longer

**Existing anchor:** `fractal_koch_curve; Sierpinski and measurement as successive comparisons`

![An orange Koch curve holds fixed endpoints above its control desk, with a triangular construction behind it.](images/Fractal_KochSierpinski.png)

*Existing museum capture · 2026-09-14. The proposal below is not pictured.*

**Keep:** The Koch desk compares endpoint distance with path length. Sierpinski exposes kept and removed area. A separate box-counting instrument holds its sample while changing measurement scales. These are valuable but dense together.

**Proposed interaction:** Move the familiar point along a widened, supported floor drawing of the Koch route; compare direct distance with distance travelled. A nearby control replaces each segment once. Then visit the cut triangle. Keep box counting in a quieter optional study bay with an unchanged sample.

**Learning elements:** segment replacement, endpoint invariance, path length, area removal.

**One-paragraph lesson:** Reuse the line endpoints and segment list. One classical Koch step replaces one segment by four at one-third length; the next generation reads the previous list without editing it in place. Test this before adding the separate Sierpinski triangle operation. The held point reads the construction and its measurement; the tutorial does not rebuild locomotion or introduce springs here.

**Reflection:** The ends remain where they were while the route between them grows. A measurement depends on the path and on the scale at which we inspect it.

**Test to write:** For the standard 60-degree Koch rule, 4^n segments join without gaps, endpoints stay fixed and length is L(4/3)^n. At four steps a four-metre seed measures about 12.642 metres. Test a variant separately rather than borrowing the standard formula.

**Carry onward:** A reusable segment replacement and the distinction between endpoint distance and path length.


## 5. Fractal_MengerSponge — The cube becomes a place

**Existing anchor:** `menger_sponge / existing flight enclosure`

![The view from a Menger-sponge passage shows nested openings in dark geometry edged in pink.](images/Fractal_MengerSponge.png)

*Existing museum capture · 2026-09-14. The proposal below is not pictured.*

**Keep:** The nine-metre sponge, two finite cuts, retained solid cells and flight enclosure already exist. The desk refuses geometry changes while a visitor is inside. This is already a strong climax.

**Proposed interaction:** Add a reachable miniature with a 3×3×3 cell-selection preview. Point to a removed cell and see its correspondence on the large cube. Apply only from outside an empty enclosure. Offer the familiar thrust-point interface through the existing flight ownership system, after testing entry, release and exit together.

**Learning elements:** 3D cell address, selection predicate, volume subdivision, construction budget.

**One-paragraph lesson:** Return to the student's cube and grid addresses. Divide one cube into 27 cells and specify which seven are removed before repeating on the twenty survivors. Produce the small construction first. The museum supplies the large display and movement service; the lesson explains that boundary instead of concealing a whole player system in the example.

**Reflection:** Seeing through, having a connected route and being able to pass through are different achievements. Removing material can create a place while still excluding a body.

**Test to write:** At n cuts, standard Menger has 20^n retained cells and volume fraction (20/27)^n. Two cuts give 400 cells. Independently verify collision and real route clearance, refusal to rebuild around an occupant, and a working ground exit.

**Carry onward:** The same replacement reasoning applied to volume; an explicit distinction between generated data and bodily access.


## 6. Fractal_GoldenSpiral — A number still needs a form

**Existing anchor:** `fibonacci_sequences / golden_rectangle`

![An upright golden rectangle is divided into coloured squares with measured side labels.](images/Fractal_GoldenSpiral.png)

*Existing museum capture · 2026-09-14. The proposal below is not pictured.*

**Keep:** The numerical sequence already compares linear and logarithmic height mappings. The rectangle shows cuts, side lengths and circular arcs. Keep it as a quieter comparison after the sponge.

**Proposed interaction:** Make the first two values tangible tiles; bring them together to request the next sum. Offer two adjacent, labelled mappings of the same held values. Let the player slide a square cut into the rectangle, keeping the measurements beside the hand.

**Learning elements:** numerical recurrence, state carried between steps, value mapping, proportion.

**One-paragraph lesson:** Reuse the known array to retain successive sums. Change how the same values determine visible size while preserving the values themselves. Then compare the separate geometric rule of the golden rectangle. This can be a short consolidation lesson: numerical recurrence is not automatically recursive geometry, and a proportion does not prove beauty.

**Reflection:** A relationship becomes a form through additional choices. Preserve the pleasure of the arrangement while making those choices available to question.

**Test to write:** The next value equals the previous two. Changing a height mapping leaves the numerical record unchanged. Rectangle measurements support the stated ratio; circular arc construction is labelled without claiming it is an exact logarithmic spiral.

**Carry onward:** A held record plus explicit mapping choices; a pause before the final composition.


## 7. Fractal_Synthesis — Choose what gets to repeat

**Existing anchor:** `cantor_set and recursive_tree / procedure gallery`

![The existing synthesis collection includes a dark sphere, branching structure and suspended cloud inside the museum.](images/Fractal_Synthesis.png)

*Existing museum capture · 2026-09-14. The proposal below is not pictured.*

**Keep:** The hall compares concrete procedures and already leads to the Cantor preset in the following L-system laboratory. The grammar F→FfF, f→fff is implemented. Julia, Mandelbrot and CrossSequence remain extensions outside this seven-hall route.

**Proposed interaction:** Give the saved interval or branching recipe a physical card. Place it beside a simple seed; inspect the first step before expanding to room scale. Allow one parameter edit, freeze a chosen result and compare with the saved version. Show seed, replacement and stop together. Audit storage before promising a cross-hall import.

**Learning elements:** recipe reconstruction, parameter comparison, stopping rule, bridge to symbolic rewriting.

**One-paragraph lesson:** Rebuild a previously saved construction from its declared recipe. The student changes one choice and predicts a difference. Reconstruct Cantor from the existing two-symbol grammar, with step size normalised to the same total span, and compare the intervals to the earlier saved record. The next sequence owns the general rewriting system; this hall demonstrates why one is useful.

**Reflection:** Which rule has been repeated, and who has room in the result? Complexity alone answers neither question. The selected work can remain particular rather than becoming a compulsory catalogue of every specimen.

**Test to write:** A saved recipe reconstructs its stated output within tolerance. Comparison does not mutate the original. At equal depth and normalised span, Cantor's symbols and interval construction agree. Every recipe declares and obeys a finite budget.

**Carry onward:** One authored construction and an exact question for L-systems: how can a written rule acquire a spatial reader?


## Three optional wild encounters

**The hydra that grows when you attack — Existing candidate, interaction unverified.** The project has a fractal_hydra with bounded head splitting. Audit its damage targeting and controller path before placing it. Killing-as-growth can make the stopping rule matter, but repeated branching alone should not be presented as a complete definition of a fractal.

**The Catalyst splits its answer — Existing code, needs runtime audit.** Fractal-mode projectiles already describe three children per split and a depth limit of two. Display ancestry and a generation counter. Verify configuration, lifetime and the count of living parents plus children before calling the weapon a working lesson.

**A chair that repeats itself out of use — Proposal using existing recursive furniture.** Let one seating surface acquire smaller descendants until sitting, looking and carrying become different demands. Keep its actual selection algorithm explicit: the recursive_chair name alone is not evidence of a self-calling function.