# Tutorial storyboards

**Reading economy:** show the complete working example once. A small experiment can name the exact edit without repeating an unchanged function or script. Test the edited result as well as the original; keep the complete variant available to download.

**Author correction, 5 October — executable lessons.** Print and explain the smallest complete working example in `tutorial.md`. Run the exact printed code in Godot with behavioural assertions. A test may supply the declared camera, player or library, but must not secretly create the lesson's label, sphere or other object. For a continuation, carry the preceding lesson's actual code: Coordinates gives Point One's same point pickup and reads its coordinates. Explain what is new; print the complete resulting small program. Short AI briefs preserve this contract. `final.md` remains the reflective track. This supersedes earlier edits-only and hidden-production-code approaches.

4 October 2026. Working brief and proposed route through all 25 sequences, for Palle to correct. These paragraphs are not approved lessons. They describe intended learning, not a claim that every transfer between existing museum artifacts is implemented.

## What the tutorial is for

The student walks through the existing Endless Museum and gradually learns enough programming to make work of their own. The artifacts provide encounters and material to think with. A tutorial selects a useful construction or operation from that material and makes it understandable, changeable and reusable. A successful lesson leaves the student able to do something deliberately, beyond following a particular edit.

The museum, tutorial and reflective writing are overlapping sets. Some works belong to both written tracks, some to one, some to neither. The tutorial teaches selected operations. `final.md` develops the critical and poetic inquiry. A reflective hall may deepen a question or let the student compose with known tools without introducing new syntax. The presence of an artifact does not oblige us to explain all its code.

**Author clarification, 5 October: two texts, two jobs.** `final.md` carries concrete poetic-critical reflection, with little code. `tutorial.md` gives context, names inherited and new work, and prints the complete reduced student example and its small supplied helpers. Full code does not mean the whole museum or XR toolkit. Preserve the object across lessons and explain the new operation without reteaching each inherited line.

Day Zero establishes the running project, player, camera, lighting and device setup. Later lessons work within that prepared museum. The counter, points and other encounters already exist. Their presence is neither an instruction to add duplicates nor a requirement to march through long production scripts. Reduced code must retain a clear connection to the real artifact and explain what the surrounding system supplies. Where the student makes their own version, decide where it runs and how it relates to the existing work in the storyboard first.

The code should be small enough to understand and substantial enough to use. Create teaching geometry in code when its construction is the lesson; keep direct references to created objects. Do not conceal necessary work behind dollar references, scene paths or unexplained helper calls. Supplied components are allowed: say what goes in, what comes out and what the student can change. A learner should not need to understand the XR player to use a working hold.

The lineage concerns both materials and programming: point, coordinates, line, retained trace, grid address, triangle, connected faces, generated forms. Introduce variables through the point, a one-dimensional list and traversal through Trace, and a function where a small geometric rule can generate positions. Earlier tools return with another purpose. A brief usable introduction can precede a later deep study, such as sine before Waves and a random choice before Randomness.

“Type-safe” is our working analogy for keeping these connections explicit. Name the kind of thing being used: position value, node, mesh, collision boundary, list, function, reference frame. A position is not its sphere; a visible surface is not automatically a physical boundary. Explain a new operation when the student first needs it. In the reflective track, a software fact, a historical claim and an artistic association also need their own kinds of support.

Write plainly, with a concrete action and consequence. Keep explanations close to the code they clarify. Preserve room for curiosity and the critical question; do not force a philosophical conclusion into every instruction. Neither exhaustive explanation nor a succession of trivial parameter edits is the goal.

## How we work from now

Move between project, sequence, map and evidence using [CONTEXT.md](storyboards/CONTEXT.md). Keep the current purpose while descending; carry consequential findings back up before leaving. Read the [sequence overview](storyboards/SEQUENCES.md) for global orientation. Existing sequence arcs need their entry, exit, boundary reasons and open choices developed; this remains proposed summary work.

Keep two versions of every summary: a full paragraph in `storyboard` and a compact AI alternative in `storyboard_short`. The short version selects the same teaching, not a different lesson. Use short instructions: **Use → Reuse → Teach/Do → Supply → Carry**. Add **Open** or **Defer** where a decision matters. Preserve dependencies, unresolved choices, supplied support and reflective purpose. Remove narrative padding; use explicit technical names rather than cryptic abbreviations. Shared constraints live here once. The review offers Full / Short AI, and a short-only Markdown export avoids reading both versions.

Palle corrects the teaching selection before a full tutorial is written. These imperatives describe a proposed lesson; they do not authorize implementation. Source reading checks the summary against the existing artifact.

Use the paragraph to distinguish what is encountered, supplied, first taught, reused and later deepened. Keep the detailed subject register behind this readable plan. Do not infer that a concept has been taught because its name occurs in code or in `final.md`. If an earlier skill is required, establish it or supply it explicitly. One map can support more than one short lesson if its learning step needs that division.

**Current pass: summaries only.** Palle clarified this on 4 October: do not change the logic of the code. Read source material to understand the existing encounter, then summarize the selected learning. Do not implement a proposed connection, redesign an artifact, change map placements or expand full lessons during this pass.

Include one small variation that lets the student use the idea independently. It may be another pair of positions, another drawing, another rule or an arrangement using known tools. Reflective halls need not become tests. If source behavior differs from a proposed paragraph, name that difference in a short writing note; do not change the code to make the paragraph true.

The [Lines → Trace → Grid notes](storyboards/LINES-TRACE-GRID.md) distinguish the proposed learning from the current behavior. The summaries remain the work for review.

The paragraphs below cover the current spine. They remain proposals: agree each teaching choice before expanding its tutorial. The existing [curriculum through Randomness](sketch/CURRICULUM_TO_RANDOMNESS.md) and [subject register](sketch/SUBJECT_REGISTER.md) provide planning material; their older host instructions and teaching locations are not settled decisions.


## Day Zero
The student opens Ada and reaches Endless Museum on desktop, with the prepared XR route available when a headset is used. They learn where to edit, save, run and return to a hall, and see what the supplied player, camera and lighting contribute to a usable image and body. The hello-world threshold is that their change can appear in a running project; the exact small check still needs choosing. Installing tools and deploying to the headset belong here, before the hall lessons. The student leaves with a working environment and an honest account of what has been prepared for them.

**Short AI alternative**
Open Endless Museum on desktop; prepare XR deployment if used. Teach edit/save/run/return. Explain supplied player, camera and lighting. Verify a saved change appears. Carry: working environment. Open: choose the small hello-world check. Complete setup before hall lessons.

## The proposed route
25 sequences · 204 halls. Each paragraph is a teaching proposal. Existing artifacts are the starting material; a proposed teaching interface or cross-hall transfer still needs implementation checks.

## 1. Primitives: Points Build Worlds
From arriving in a running world to making its first elements: a point gains a body, an address, a relation, a record and a face. Connected faces become generated forms; the closing halls ask what an exact construction and a useful approximation permit us to make.

### Point_Zero — Once, then again
The student meets the existing frame counter in a museum already running. They compare an instruction in _ready(), which initializes when the node is ready, with an instruction repeated in _process(delta). One reading and repeated readings make execution timing observable. The player, room and display are supplied; building a replacement counter is not the lesson. The student carries an understanding of when an instruction runs, while the reflective text keeps its questions of arrival and borrowed time.

**Short AI alternative**
Use existing frame counter. Prior: running museum. Teach initialization in _ready() and per-frame updates in _process(delta). Compare one reading with repeated readings. Supply player, room and display. Carry: execution timing. Reflection: arrival, borrowed time.

### Point_One — Give a point a body
The corridor moves from an unseen point to a visible sphere, then to a sphere with collision. The student introduces a position variable and changes where a body appears, distinguishing the value from its mesh and collider. Visibility and contact can now be compared. The corridor, lighting and variant system are supplied; the light switch remains an encounter with the conditions of visibility. Before drafting code, decide where the reduced construction belongs within this existing arrangement. The student carries a represented point whose visible and physical boundaries are explicit.

**Short AI alternative**
Use corridor: unseen point, visible sphere, solid sphere. Teach position variable; distinguish value, mesh and collider. Change position; compare visibility and contact. Supply corridor, lighting and variant system. Carry: represented point. Open: where reduced learner code belongs. Keep the light switch as a visibility encounter.

*For correction:* Agree how the small construction relates to the existing corridor before drafting code.

### Point_Coordinates — A point we can move
The student returns to the existing black point within the coordinate frame. Bringing a position variable and a represented body, they learn the connection to a supplied grab system, move the point along X, Y and Z, and read its position in one named frame. The XR rig and readout are supplied. Agree the taught grab interface and how far to compare local and world positions before writing the lesson. Decimal formatting can wait. The student carries a point they can move, locate and use.

**Short AI alternative**
Use existing black point and coordinate frame. Reuse position variable and body. Teach the supplied grab connection; move along X, Y, Z and read positions in one named frame. Supply XR rig and readout. Carry: movable, readable point. Open: grab interface and extent of local/world comparison. Defer decimal formatting.

*For correction:* Approve the grab interface and how much local/world comparison belongs here. Decimal formatting is not the lesson.

### Point_Lines — Put two points in relation
At the existing line and relations gallery, the student brings the same pickable point from Coordinates. Its copy becomes another endpoint. Reading both positions in the station's frame gives a displacement and its length; a supplied visible skin draws their relation each frame. A second segment uses two stored positions without pickup bodies. Parallel, plus and X become arrangements the student can alter, including a depth change that separates an apparent crossing. The learner predicts and makes another arrangement, tests coincident endpoints, and carries the connecting operation into Trace. The reflective text follows a line as route, prohibition and sign; Primitive Ignorance later considers choosing rules that organise many finite vertices.

**Short AI alternative**
Use existing line and relations gallery. Reuse Coordinates' pickable point; duplicate once. Teach same-frame endpoints, b-a and length; redraw the segment each frame. Supply visible skin and museum hands. Add a second segment from stored positions: parallel, +, X; separate in Z. Check an authored arrangement and coincidence. Carry relation into Trace. Reflection: line as route, prohibition, sign. Later Ignorance: choose rules/connectivity; finite vertices remain countable.

[Revised lesson and evidence](../iterations/2026-10-05-lines-relation-and-rule/index.html)

### Point_Trace — Keep the positions
The student uses the existing drawing pen, bringing positions and the segment between two points. They keep accepted positions in an ordered list, read one entry, then loop over neighbouring entries to connect them. A bend or return in their own drawing makes the order worth inspecting. Input, sampling and session storage are supplied. The pen shapes its samples and can retain positions across pickups; release copies the cumulative record to the session store. The student carries that retained drawing into Grid rather than starting again with a stock curve.

**Short AI alternative**
Use existing drawing pen. Reuse positions and segments. Teach ordered list: append accepted positions, read an entry, loop over neighbours. Draw a bend or return; follow its order. Supply input, sampling and session storage. Carry the student's retained drawing into Grid. Respect cumulative recording across pickups.

*For correction:* The pen already shapes its samples, and its record can continue across pickups. Describe those existing choices; do not change the recorder to fit the summary.

[Storyboard notes](storyboards/LINES-TRACE-GRID.md)

### Point_Line_Grid — Give that trace addresses
The existing grid receives the student’s released trace from the session store. Reusing the list and loop, the student distinguishes an entry’s list index from the spatial address obtained by rounding its position. The display first centres and resizes the drawing, then rounds the displayed positions in X, Y and Z; the original record remains separate. Comparing visits that reach the same address makes this transformation visible. Session transfer and fitting are supplied. The student carries a way to organize positions, without a claim that the record survives a project restart.

**Short AI alternative**
Use existing grid and the student's released trace. Reuse list and loop. Teach list index versus spatial address; follow XYZ rounding. Supply session transfer and display fitting. Existing order: centre/resize, then round displayed positions. Compare coincident addresses; retain source separately. Carry: organize positions. No restart-persistence claim.

*For correction:* The current artifact rounds after fitting the drawing for display. Do not claim rounding in the original metre frame or persistence after restart. This is a writing summary, not an implementation proposal.

[Storyboard notes](storyboards/LINES-TRACE-GRID.md)

### Point_Triangle_Context — A boundary becomes a face
The student encounters the small drawing tool and its enlarged twin. Reusing points or recorded positions and the lines connecting them, they select three non-collinear corners, close an outline and submit a triangular face in an explicit corner order. The outline and surface become distinguishable results of different operations. Mirroring, material and input are supplied. Another valid set of corners lets the student reuse the operation deliberately. A triangular face travels onward; filling an arbitrary polygon remains outside this first step.

**Short AI alternative**
Use small drawing tool and enlarged twin. Reuse points or recorded positions and segments. Select three non-collinear corners; close outline, then submit a face in explicit corner order. Distinguish boundary from surface. Supply mirroring, material and input. Carry: triangular face. Defer arbitrary polygon filling.

*For correction:* Use non-collinear positions. Defer arbitrary polygon filling.

### Primitives_Polythedra — Connect faces around a space
Among the hall’s solids, the student returns to a position list and the triangular face. Adding one point allows a small enclosure, whose first example still needs choosing. A face list now refers to stored corners by index: changing a position and changing which corners connect are different edits. The rendering wrapper is supplied, and collision remains a separate question. The wider bodily comparisons keep their reflective role. The student leaves with an editable mesh, able to locate both its positions and its connections.

**Short AI alternative**
Use the hall's solids. Reuse triangular faces and position list; add one point to make a small enclosure. Teach face indices referencing stored corners. Distinguish position edits, connectivity and collision. Supply rendering wrapper; retain bodily comparisons for reflection. Carry: editable mesh. Open: select the first enclosure.

### Point_Animatedcube — Keep the corners, change the connections
The cube and its comparison display return to the position list and face connections. The student moves a shared corner and follows the faces affected by that edit, then compares the two diagonals across one side. Editing vertex data is distinguished from moving the object as a whole. This extends the mesh work without requiring a new system for making bodies. The prefab shelf remains an encounter with reuse and repetition; teaching scene packaging can wait. What travels onward is the ability to edit a connected form deliberately.

**Short AI alternative**
Use cube and comparison display. Reuse positions and face lists. Move a shared corner; inspect affected faces; compare diagonals across one side. Distinguish vertex edits from whole-object motion. Carry: mesh editing. Keep prefab shelf as a reuse/repetition encounter; defer scene packaging.

### Primitives_Ignorance — A rule can make the positions
The solids and columns let the student return to position lists and loops. Instead of entering every position, they write a function that accepts a radius and produces symmetric positions; the face connections are supplied. They compare changing a generated result with changing the rule that makes it. This gives the student a reusable generator while leaving resolution, proportion and aesthetic judgement as separate decisions. A further lesson on profiles and rings may follow separately; its placement remains open.

**Short AI alternative**
Use solids and columns. Reuse position lists and loops. Teach function: radius in, symmetric positions out. Supply face connections. Compare editing a result with changing its rule. Carry: reusable generator. Keep resolution, proportion and aesthetic judgement distinct. Open: separate profile-and-rings follow-up.

*For correction:* One profile-and-rings follow-up can be separate. Resolution, proportion and aesthetic judgement remain different decisions.

### Primitives_Portals — Decide what is sufficient
At the ring display, the student reuses generated positions and distances while a supplied circle sampler handles construction. They compare segment counts and choose a resolution for a stated visible or bodily purpose. More segments change the approximation, but do not settle proportion or aesthetic preference. The reusable outcome is a tolerance they can explain. This hall keeps a reflective pace: deriving the trigonometric construction and implementing portal rendering are deferred.

**Short AI alternative**
Use ring display; supply circle sampler. Reuse generated positions and distances. Compare segment counts; choose sufficient resolution for a stated visible or bodily purpose. Carry: a justified tolerance. Keep resolution, proportion and aesthetic preference distinct. Preserve reflective pacing; defer trigonometric construction and portal rendering.

*For correction:* The sampler is supplied; full trigonometric construction is not assumed here.

### Primitives_Melencolia — Compose with what we have
The existing Dürer encounter gives the student room to compose with familiar forms and placement. Prepared materials are supplied, and a small arrangement can be made without requiring new syntax. If scale has not yet been taught, it must be supplied or deferred rather than silently assumed. The reflective text keeps its inquiry into geometric desire, exact forms and the difficulty of making. Composition carries these known elements toward Transformation, where their arrangement can begin to change.

**Short AI alternative**
Use existing Durer encounter and prepared materials. Reuse known forms and placement to compose a small arrangement. Require no new syntax. Preserve reflection on geometric desire, exact forms and the difficulty of making. Carry composition into Transformation. Open: scale must be supplied or deferred if not yet taught.

*For correction:* The critical discussion of geometric desire retains its own room; no new syntax is needed to finish.

## 2. Transformation: What Stays the Same When Everything Changes
The forms assembled in Primitives acquire motion, then become surfaces and boundaries a visitor can use. A small timed study introduces interpolation and sine without requiring a theory of waves; later halls distinguish path, pivot, hierarchy and input. The student finishes with a deliberate transformation rule whose visible and physical consequences can be compared.

### Trans_Pre — Give a familiar cube a rhythm
Before the four pickup demonstrations, the student recognises the cube assembled in Primitives and watches translation, rotation and scale arrive one at a time. In a small companion study, they retain the created cube reference, accumulate elapsed seconds and drive height and size between two limits, adding a timed turn. The room, display and collection behaviour are supplied. A short sine comparison keeps the endpoints and duration while changing arrival speed; its range is explained now, its circular meaning later. The student leaves with an animation they can reuse deliberately.

**Short AI alternative**
Use four pickup demonstrations. Reuse the created cube reference. Teach elapsed seconds, bounded height/size interpolation and a timed turn. Compare sine arrival speed at equal endpoints and duration; explain its range. Supply room, readout and collection. Carry reusable animation. Keep the museum encounter linear; place sine in the companion study. Defer circular meaning.

*For correction:* Keep the linear museum encounter and place the sine comparison in the student study; the older intent still postpones all sine.

### Trans_Introduction — Make a surface reach
The student crosses the moving cube, growing support and turning plank, bringing the animation operations from the pickup study. At the adjustable landing they hold the plank's motion fixed and move the destination, then use their known endpoint calculation to propose a crossing that reaches both banks. A prepared physical deck supplies collision and rider carrying; the learner controls its route and records its displacement. They discover that animating a surface and transporting a supported body require an explicit connection. A crossing specification, including its fixed references, travels onward.

**Short AI alternative**
Use moving cube, growing support, turning plank and adjustable landing. Reuse animation and endpoint calculations; hold plank motion fixed while moving the destination. Teach surface motion versus carried displacement. Supply banks, controls and physical deck with rider adapter. Carry a crossing specification with fixed references. Open: choose the smallest supported deck interface before drafting code.

*For correction:* Choose the smallest supported deck interface before writing code; inspect source rather than teaching the whole transport script.

### Trans_Translation — Choose the journey between endpoints
Seven carrier journeys separate sideways, upward and forward travel before combining directions. Reusing positions, lists and interpolation, the student describes a short route as waypoints in one named frame, then compares visiting those waypoints with travelling straight to the final destination. The prepared carrier accepts consecutive target positions and supplies rider detection; a simple marker can preview the same route without carrying anyone. Subtraction gives each leg, and dividing a nonzero leg by its length separates direction from distance. The student carries a route generator whose endpoint does not conceal its intermediate journey.

**Short AI alternative**
Use seven carrier journeys. Reuse positions, lists and interpolation. Teach waypoints in one frame, leg subtraction and direction = leg/length for nonzero legs. Compare waypoint travel with the direct route. Supply carrier, rider connection and preview marker. Carry a route generator preserving intermediate travel. Open: choose marker preview or visitor carrying; carrying needs the preceding deck interface.

*For correction:* Agree whether the first student route carries the visitor or only the preview marker; the former needs the deck interface from the preceding lesson.

### Trans_Rotation — Turn around a chosen centre
At the blades and the marked cubes, the student follows an end while its centre stays fixed. With positions, functions and a timed angle available, they make a small arm from a centre and an offset, then rotate the offset around a named axis before adding the centre back. A supplied angle display and physical ride let them compare their construction with the larger encounter. Reversing two turns at the composition workbench tests order; the hinge offers a quiet return. The reusable result is a pivoted construction, distinct from moving the whole object.

**Short AI alternative**
Use blades, marked cubes and composition workbench. Reuse positions, functions and timed angles. Teach pivoted construction: rotate an offset around a named axis, then add its centre. Reverse two turns to test order. Supply angle display and physical ride; retain the hinge as a quiet return. Carry pivoted construction distinct from whole-object motion. Defer full rotated arrays and ride physics.

*For correction:* Keep axis-angle construction small; do not make all rotated arrays and ride physics prerequisites.

### Trans_Scale — Choose what the scale reaches
Taking the bottle enlarges the room while the visitor retains their size. The student brings uniform scale and a pivoted arrangement, then groups a small set of their own forms under one created parent and scales that parent beside an unchanged reference doorway. The existing room, bottle and relocation mechanism are supplied for the encounter. They compare scaled dimensions with scaled distances between children, and identify the separate operation that moves the visitor onto the table. A grouped construction with a clearly bounded scale becomes useful for later arrays and assemblies.

**Short AI alternative**
Use the bottle enlarging the room around an unchanged visitor. Reuse uniform scale and pivoted forms. Teach parent-child transforms through one created group beside a fixed doorway; compare dimensions and child spacing. Supply room, bottle and relocation; distinguish relocation from scaling. Carry a bounded grouped construction. Open: choose the small composition.

*For correction:* Decide the small grouped composition; do not require rebuilding the room, food or player relocation.

### Trans_Body — Let proximity become an input
The slats open, the low lattice loses cells, and nearby blocks shrink. Reusing distance and interpolation, the student makes one small block respond to the supplied visitor position: convert distance to a bounded fraction, then use it to choose a size while keeping the base on the floor. The prepared body query and matching collision update are explained as inputs and outputs. Walking away distinguishes a reversible response from the lattice's retained removal. The learner takes forward a proximity function and the habit of asking which state an interaction keeps.

**Short AI alternative**
Use opening slats, retained lattice removal and shrinking blocks. Reuse distance and interpolation. Teach clamped distance-to-size mapping on one adjacent block, keeping its base grounded. Supply visitor-position query and matching collision updater with explicit inputs/outputs. Compare walking away with retained removal. Carry a proximity function and state distinction; keep carving infrastructure supplied.

*For correction:* Student block should sit beside the encounter; carving and visitor-recognition infrastructure remain supplied.

### Trans_Pit — Compose an opening through time
Beside the timed pushers, turning slabs and growers, the student predicts when a space becomes available and compares that prediction with the final airlock. They already have timed and proximity-driven transforms, so they compose a small pair of leaves whose position, angle and size receive different parts of one opening fraction. The doorway frame, occupancy input and physical leaf wrapper are supplied. Holding an intermediate pose makes clearance inspectable. No new syntax is necessary: the outcome is an authored transformation sequence that makes a usable opening, ready to be repeated across an array.

**Short AI alternative**
Use the level-ground timed pushers, slabs, growers and airlock. Reuse timed/proximity transforms. Compose two leaves whose position, angle and size share one opening fraction; hold an intermediate pose to inspect clearance. Supply frame, occupancy input and physical leaf wrapper. Carry an authored opening sequence toward arrays. Require no new syntax; discard obsolete pit/death framing.

*For correction:* The current hall is a level-ground timed study; obsolete pit/death prose must not determine the exercise.

## 3. Arrays and Regularity
PROPOSED. Keep an address while changing what its value asks a receiver to do. Return to Trace’s list and Transformation’s positioned body; extend a small occupancy record into a plane and a volume with explicit storage conventions. Then let an address choose a tile’s turn, give the same image another support, and let a clock read a score. Occupancy, orientation and musical events remain different kinds of data. Carry the read/write operation and declared readers into Colour and Tiling; automatic transport between museum exhibits is not assumed.

### Array — Keep a place when its occupant leaves
The row loses a cube without closing its gap; the nearby grid lets the student locate another absence with two indices. Bringing Trace’s list and loop and Transformation’s positioned body, they begin with four slots, then extend the same read/write operation to a small grid. Follow the installed convention, grid_data[x][z], and keep occupancy values separate from visible-node references and spacing. A named display adapter and collection event are supplied. The student empties a chosen slot, changes the spacing and explains why the other addresses remain. They carry the occupancy record and its reader. Molnár’s retained departures offer an optional next experiment; the changing floor remains an encounter with the physical consequence of an empty place.

**Short AI alternative**
Use row and indexed grid. Reuse Trace list/loop and positioned bodies. Teach retained slots, then grid_data[x][z]; separate occupancy, node reference and spacing. Supply display adapter/collection event. Check: empty one slot, vary spacing, preserve addresses. Carry record + reader. Optional: stored Molnár departures. Floor writer stays an encounter. Open: reduced learner binding; Array tutorial absent.

*For correction:* Array/tutorial.md is still absent. The reduced learner study and its display connection need choosing before a full lesson. The row uses array_data[0][i]; the grid uses grid_data[x][z]. Molnár’s current data is a different retained structure, not this occupancy table. Do not present Grid’s earlier lossy snapping as reversible.

### Tutorial_3D — Name the layer and keep the convention visible
In the flight enclosure, the student selects a cube above the ground and later reads zero where it stood. They bring the two-index occupancy record and extend the study to layers. The displayed address is [x, y, z], while the installed volume reads values[y][z][x]. Before changing a value, they show how the earlier [x][z] plane becomes one [z][x] layer: the conversion is part of the lesson. Flight, selection and collection are supplied. The student predicts an unequal-index address, changes its value and reads it back without shifting its neighbours. They carry an explicit storage-to-space mapping. Open structures and suspended fragments remain further uses of addressed places, not additional required data systems.

**Short AI alternative**
Use flight enclosure. Reuse occupancy record. Teach displayed [x,y,z] → values[y][z][x]; explicitly convert earlier [x][z] plane into a [z][x] layer. Supply flight/selection/collection. Check unequal indices; write/read one slot without shifts. Carry storage-to-space mapping. Open structures/suspension remain comparisons. Open: reduced study binding; an added dimension grants no flight.

*For correction:* Wrapping the earlier grid directly would yield values[y][x][z], not the installed values[y][z][x]. Explain the conversion or a named reader explicitly. The installed enclosure is four by four by four; the learner study may be smaller. Current tutorial’s open-form edits do not yet teach this storage conversion.

### Tutorial_Tiling_Floor — Let an address choose a turn
At the paired four-by-four samples, one extra turn at each address makes a larger figure cross the joints. The student brings addressing and rotation, but now gives the value another declared meaning: zero quarter-turns is an orientation, not an empty slot. With the asymmetric tile and image renderer supplied, they write one address-to-turn function using remainder by four. They predict a selected tile’s result, then add one exceptional address. Enlarging the field repeats the same calculation without adding instructions. They carry the motif choice, turn rule and exception separately. The other fields provide comparisons; the floor’s apparent ridges do not become steps underfoot.

**Short AI alternative**
Use paired 4×4 samples. Reuse indices/rotation. Teach address → quarter-turn via remainder; zero means orientation, not vacancy. Supply motif/image renderer. Predict one result, add one exception, enlarge field with same rule. Carry motif + turn rule + exception. Other fields compare. Existing tiling rasterizes images; no per-tile body or stored occupancy implied. Open: learner-rule binding.

*For correction:* The installed floor makes raster images from a rule; it is not a nested table of colliding triangle tiles. Do not require the learner to rebuild the renderer. The current tutorial redirects to final.md, so this remains a teaching selection rather than an implemented companion.

### Tutorial_Tiling_Walls — Keep the pattern, change what carries it
The same pattern now stands in front of the student. They bring the motif and turn rule from the floor and reuse its generated image on a supplied upright receiver. The eye chart and a walk toward and away from it let them compare what remains legible as its apparent size changes. No new syntax is needed. At the exception wall, they predict the difference between turning a mark inside the image and turning the sheet with its collision. One alters the picture; the other can open a passage. The hinge and finite landing stay supplied. They carry a comparison separating source, appearance and access, including the brief chance to look back at the outside of the museum’s enclosure.

**Short AI alternative**
Use wall fields, eye chart and turning wall. Reuse floor motif/rule/image on supplied upright receiver. Compare distance and apparent scale; no new syntax. Predict image-turn versus carrier/collision-turn. Supply hinge/landing. Carry source–appearance–access distinction. Preserve the outside pause. Open: learner image assignment; no new tiling or wall-construction lesson.

*For correction:* Reuse of the learner’s own generated image needs an explicit assignment; the installed floor and walls already share a generator, not an automatically transported learner record. Preserve the mature main text and the wall’s collision/safety behavior.

### Tutorial_Disco — Let a clock read the choices you kept
The monochrome floor changes while a separate sequencer offers empty cells to fill. The student brings indexed lookup, remainder and elapsed time. They make a short score with explicitly named track and step indices, following the instrument’s [track][step] convention; false means no new sound trigger, not a missing floor tile. A supplied sound receiver handles the note. The student advances a playhead through the kept score, moves an event without changing tempo, then changes tempo without rewriting the entries. They stop the score and watch the floor continue. They carry a reusable timed reader. The sixteen-step score’s connection to twelve floor columns is a comparison of addresses, not a lesson in recording footsteps.

**Short AI alternative**
Use separate sequencer and changing floor. Reuse lookup/remainder/time. Teach score[track][step] plus timed playhead; false = no new trigger. Supply sound receiver/display. Move event at fixed tempo; change tempo with score fixed; stop score and predict floor. Carry timed reader. 16 steps/12 columns can share a flash address. No footstep recording. Open: old tutorial contradicts current encounter.

*For correction:* The current instrument stores four tracks by sixteen boolean steps; the floor has twelve columns. The learner can start with one short track. The companion still describes a 17×17 footstep-recording floor, undefined supplied pieces and deferred Chamber_Arrays. This summary pass does not repair that full lesson: rewrite it from the present score before presenting it as reliable instructions.

## 4. Color and Composition
PROPOSED. Colour returns to the forms, transforms and addressed assignments already available. Keep geometry while changing its palette; keep a surface while moving its light. Nails introduces one bounded position-to-colour function and an explained receiver. Pillar changes that function’s coordinate convention; Grid keeps a returned value at an address. Paint returns to an existing timed path on an evolving image. Walls carries palette and arrangement onward into Tiling. Rainbow remains a generous pause with optional palette-making. Equal values need not look alike; these proposed learner connections do not imply automatic transport between exhibits.

### Color_Context_Placed — Let colour regroup an assembly
The first columns keep the same five forms while their colour assignments change. Bringing primitives, transforms and array lookup, the student selects colours for a small supplied part list while keeping its geometry fixed. Begin with list position; supplied numeric shape categories offer a second grouping once that assignment is clear. Each part has an explained material reference, so choosing a palette entry and assigning it are visible operations. The student regroups two separated parts by colour without moving either. They carry a palette and a selection rule independent of placement. The larger stacks, historical associations and cone landscape remain available for looking and composition without becoming additional required builds.

**Short AI alternative**
Use fixed-geometry columns. Reuse primitives/transforms/lookup. Teach palette selection separately from material assignment and placement. Supply part/material references; numeric categories optional after index selection. Check: regroup separated parts without moving them. Carry palette + selection rule. Rich stacks remain encounters. Open: reduced host binding; no dictionary lesson assumed.

*For correction:* Use a small explicit part/category list before requiring dictionaries. The museum’s richer stack records remain supplied; choose the reduced editing entry before writing a full lesson.

### Color_Flashlight — Change what reaches a surface
The student moves a coloured lamp across the pale board and faceted sphere, then follows the source edit already offered by this hall. They bring material colour and transforms and keep a direct reference to one existing supplied light. Change its colour while leaving the receiving surface alone; then keep the colour and change the lamp’s direction. Predict which condition changed before comparing the result. The fixed lamp in the side room offers a later return to time-varying colour. Grabbing, room geometry and the renderer remain supplied. The student carries a controllable light and the distinction between a value assigned to a material and light reaching it; no new room or lamp assembly is required.

**Short AI alternative**
Use existing lamp/board/faceted sphere. Reuse colour assignment and transforms. Follow current bounded light-colour edit; retain named light reference. Vary colour with receiver fixed, then aim with colour fixed. Supply grabbing/room/renderer. Carry illumination versus albedo distinction. Timed lamp optional. No new room; no spectral-optics claim.

*For correction:* The existing tutorial already provides a small light-colour edit. Retain that entry; do not replace it with a new host or require lighting equations.

### Color_Nails — Use a position to choose a colour
The held point recolours nails on the giant and petite hands and, in the standard VR setup, the choosing hand. Reuse a position in a named local frame and bounded mapping. The student writes one function taking that local position and positive box dimensions, clamping each component to the box and dividing by its dimension: X becomes red, Y green, Z blue. It returns a Color; one named preview material receives it through albedo_color. The grab connection, hand meshes and application signals are supplied. Predict the colour at a different point and revisit it, then keep nail colour fixed while changing rendered skin. Carry the function and a recorded colour. Preserve the critical distinction between these equally easy assignments and their unequal lived meanings.

**Short AI alternative**
Use RGB point and salon hands. Reuse local position/bounded mapping. Teach positive box sizes; clamp/divide X→R, Y→G, Z→B; return Color → named preview albedo. Supply grabbing/hands/signals. Predict another point, revisit it; keep nails fixed while changing skin. Carry function + recorded colour. Preserve Lorde/embodied difference. Open: reduced preview binding; no automatic Rainbow transfer.

*For correction:* The current companion offers observation/source tracing, not this complete authored function. Bind the reduced function to one named preview before expanding the lesson. GameManager already retains hand/nail choices, but that does not feed Rainbow or Grid automatically. Preserve the main text’s Lorde passage.

### Color_Rainbow — Divide one span into chosen colours
RE-DIVIDE changes the bands while the opening and celebration remain available. Bring the palette list and a colour recorded at Nails; there is no automatic transfer. An optional making step substitutes that value in a hand-picked palette, then compares different nonempty palette lengths with the same total band width. The curved-strip builder is supplied with radius, width and colour inputs and a returned strip reference; the learner can inspect the fixed-width division without rebuilding the arch. Predict which boundaries move while the opening stays. The forty-eight-band version introduces the difference between many samples and continuity. Carry palette choice and partitioning onward. Staying, looking and celebrating can complete this hall without another coding assignment.

**Short AI alternative**
Use RE-DIVIDE; celebration stays unconditional. Reuse palette; manually record/reuse Nails colour. Optional: replace palette entry, compare nonempty lengths at fixed total width. Supply curved-strip builder and route. Predict seams versus opening. Carry palette/partition distinction. Many bands remain discrete; HSV sampler optional before Pillar. No automatic transfer or optics claim.

*For correction:* Keep making optional. The installed options are six, seven, forty-eight and two bands. A hand-picked palette avoids making HSV a prerequisite here. Celebration does not require completing a task.

### Color_Pillar — Ask a field for a colour
A moving card samples the field between the pillars; leaving it in place keeps its latest sample. Bring Nails’ position-to-colour function and change the rule explicitly: X now chooses hue, Z saturation and represented Y value, converted with Color.from_hsv. The supplied height adapter maps the card’s local 0.65–1.85 metre range into the field’s 0.46–4.60 metre height; it is not the same position passed unchanged. Predict a sample between columns, then vary height while keeping the other coordinates. At value zero, different addresses yield the same black. Carry the field function and one recorded result toward Grid. The matching ceiling and named swatches remain encounters with appearance, classification and the gaps between visible samples.

**Short AI alternative**
Use moving sampler and constant swatch. Reuse Nails function pattern, change convention: field X→H, Z→S, Y→V; convert HSV→Color. Supply explicit hand-height adapter (.65–1.85 → .46–4.60 m), card/readouts. Predict between columns; vary V alone. Movement resamples; stationary card keeps latest. Carry function + recorded result. Black has many source addresses; HSV is not perceptually uniform. No automatic Grid handoff.

*For correction:* The sampler checks position each frame, not whether it is held. A released stationary card keeps the last sample because its position stops changing. Use actual ranges from hsv_at; value is not perceived lightness. A recorded result or copied function can connect Grid, but the installed exhibits have no such transfer.

### Color_Grid_Pallet — Let one address keep a colour
The outline leaves an edited square and returns to find its colour. Bring array addressing and a recorded result from Nails or Pillar. In the proposed reduced study, write that colour to one chosen address through an explained address-to-instance receiver; selecting another address must not write to either. The installed console instead cycles four inks, so using the learner’s own value is a proposed binding. Revisit the address, then apply the whole-grid rule and predict the replacement. Carry stored assignment separately from live field evaluation. Preserving one exception is an optional later policy, not current behaviour. The wider reach of RULE, the twenty-five selectable sites and the unbroken floor retain their critical force.

**Short AI alternative**
Use edited floor square. Reuse address/lookup and recorded Nails/Pillar Color. Propose write through named address→instance receiver; selection only reads. Check leave/return, then predict RULE overwrite. Current COLOUR cycles four inks; custom input needs binding. Carry stored assignment versus live evaluation. Optional protected exception; no history/current protection. Keep 25-site control versus wider rule and unchanged support.

*For correction:* Vector2i.y denotes room Z here. The actual colour is a MultiMesh instance value, not one separate material per cell. Current COLOUR cycles INKS; custom function input is proposed. RULE overwrites mapped floor colours; protected exceptions/history are not implemented.

### Color_Paint — Give a mark somewhere to remain
The automatic can is painting before the student takes a manual one. Bring elapsed time, sine and the distinction between an address and the value kept there. Read the existing two-coordinate automatic path, then change one rate or amplitude while keeping the other coordinate unchanged. Predict whether the path becomes narrower or turns at another pace. The supplied host converts surface coordinates into a hit and sends deposits to the same draw_spray operation used by the manual cans. Compare a quick pass with staying in one place. Carry the path rule and the distinction between replacing a grid entry and contributing to an image that spreads and fades. The shader and spray apparatus remain supplied; no second brush is required.

**Short AI alternative**
Use existing automatic path/manual cans. Reuse time/sine/address distinctions. Edit one UV rate or amplitude; predict path width or pace with other coordinate fixed. Supply UV→hit mapping and shared draw_spray surface. Compare quick versus repeated deposits. Carry path rule and evolving-image distinction, not recoverable gesture history. No second brush; defer spray/feedback shader. Albers remains an encounter.

*For correction:* Both automatic and manual callers already reach draw_spray. Keep that shared operation rather than proposing another brush system. Its retained image spreads and fades; it is not permanent storage or a lossless list of strokes. UVs are introduced as two bounded surface coordinates; shader implementation comes later.

### Color_Walls — Compose a view through colour
Walk the same route between panes in FILTER and OPAQUE modes: a chair disappears while the gaps stay. Bring colour assignment, surface geometry and transformed arrangements. Use the companion’s existing pane or palette edit to change one condition, keeping the other fixed. Alpha controls the contribution of the view behind a supplied transparent surface; the transparency mode, backing light and collision remain explicit support. Predict what can change in the view without changing passage, then walk around it. The RGB/HSV models and interpolation bench offer optional returns to coordinate choices. Carry palette separately from arrangement into Pattern_Disco. The office and assembly’s questions of privacy and who may rearrange a room need no further coding exercise.

**Short AI alternative**
Use switchable panes and existing companion edit. Reuse materials/transforms/palette. Vary one pane angle or palette while other condition stays. Explain alpha; supply transparency/light/collision. Predict view versus passage. Carry palette separate from arrangement into Pattern_Disco. RGB/HSV models/interpolation optional; preserve privacy/authority questions. No new composition required. Open: companion spacing prose/code mismatch.

*For correction:* Preserve existing bounded edits and keep interpolation optional. Companion prose says try 0.18 while its spacing example uses 0.21; reconcile at the full-lesson pass. This summary revision does not alter that companion or the mature main text.

## 5. Patterns: Dress the Architecture
PROPOSED. Return to Arrays’ addressed values and Colour’s palette/receiver distinction. Choose a small source, then separate editing it from changing how another address reads it. Give repetition a physical scale, test a symmetry with a revealing mark, and let height enter the lookup. A reflective comparison keeps source equality separate from viewed appearance. Close with a tiny UV repeat-and-offset shader using the existing studio host. Keep source, palette, sampling rule, receiver and saved version distinct. Reusing a known motif is not automatic cross-hall transfer; full lessons and learner bindings remain proposed.

### Pattern_Disco — Keep the pattern, change its palette
The familiar floor returns after Colour with two replaceable colours. Bring the earlier address rule and palette lookup; use the existing value_at result rather than making another floor or clock. With the floor held and sequencer stopped, change the pair that displays zero and one, then keep the pair while advancing one phase. Predict what stays related in each comparison. The floor receiver, controls and independent score remain supplied. The student carries the separation between a computed value and its displayed colour. The optional triangle comparison uses a different shader drawing, not one whole-cell zero or one; it can retain the palette question without becoming the opening shader lesson.

**Short AI alternative**
Reuse existing value_at and Colour palette lookup. Hold floor/stop score; change colour pair, then phase alone. Predict unchanged relationships. Supply floor/controls/separate score clock. Carry value versus appearance. Triangle drawing optional and distinct from whole-cell values. No new floor/clock; reduced palette-edit entry still to be chosen.

*For correction:* Revisit the current two-colour lookup instead of requiring a new floor or timer. The production console chooses four prepared pairs; a learner-authored pair needs a named source-edit entry. Super Triangle is separately drawn by a shader.

### Pattern_Foundry — Author the source others repeat
Begin with one off-centre pair in the small four-by-four tile and find its repeated appearances. Bring addressed writes and palette selection; let a source entry hold a palette index and let a wrapping lookup select that entry before its colour is assigned. The student predicts another copy from its address, then changes one source cell. Input controls and the image preview are supplied. Carry a small motif and its reader. On a return visit, copy the nested source explicitly and compare it with a live reference. The loom and architectural receivers remain further encounters: the loom has its own five-by-five card, HOLD retains a receiver image, and each SAVE acts on a stated source. These are not one shared learner record.

**Short AI alternative**
Use one 4×4 tile. Reuse addressed writes/palette lookup. Teach source[row][column] palette indices, wrap address then choose colour. Predict a repeated pair after one edit. Supply input/image preview. Carry motif + reader. Optional return: independent nested copy versus live reference. Loom has separate 5×5 source; HOLD image differs from SAVE. Later teaching stations use fixed seeds.

*For correction:* One core source-and-reader study first; copy/history on a return visit. Use explicit row/column storage in the reduced example and show how it connects to the selected station. The small tile, five-by-five loom and fabric studio are distinct sources. Do not present a copied source array as the implementation of a held texture.

### Tutorial_Pattern — Transform the lookup or the source
Follow the asymmetric bend through PM, then watch the source cells during FLIP X. Bring the motif and wrapping reader. First change only the read address: on alternate tile columns, reverse the source column while keeping the row. Then make a separate mirrored source by reversing entries inside each row; do not reverse the order of the rows. Displays, editor input and shader rendering are supplied. The student predicts where the coloured neighbour will appear and checks that only the second operation changes the stored source. A symmetric mark can conceal either reversal; altering one cell reveals it again. Carry two named operations, source editing and transformed reading, before considering any wider symmetry classification.

**Short AI alternative**
Use PM versus FLIP X. Reuse motif/wrapping. Teach alternate-column reflected read without source mutation; separately reverse entries within each source row, not row order. Predict asymmetric neighbour; inspect unchanged versus changed source. Supply editor/displays/shader. Carry read transform versus data transform. Symmetric motif may hide the operation; shader authorship waits.

*For correction:* Keep the first reduced address operation in GDScript. “Reverse source rows” must mean reversing entries within every row, not swapping top and bottom rows. P1/PM displays are supplied; matching appearance alone cannot tell whether the source was mutated.

### Array_Patterns — Give an address physical dimensions
Enter the tunnel with its stated fixed four-by-four source; earlier edits have not travelled here. Bring wrapped lookup and named frames. Follow one marked floor address to its source, then derive the address from a position using a declared origin, surface axes and cell width in metres. On the right wall, columns run along the passage and rows descend; they are not the floor’s directions. The tunnel, collision, shader and face selector remain supplied. Predict that changing a cell from forty to sixty centimetres changes a four-cell motif from 1.6 to 2.4 metres, without enlarging the passage. Inspect the corner where counts restart. Carry the conversion and its units; importing a learner motif remains optional future work.

**Short AI alternative**
Use fixed-source tunnel; no preceding-edit transfer. Reuse wrapped read/reference frames. Teach position→surface row/column with named origin/axes and metre cell width. Predict .4→.6 m cells means 1.6→2.4 m motif. Wall directions differ; corners restart. Supply tunnel/collision/shader/selector. Carry explicit surface conversion. Distinguish cell width from whole-repeat width; optional import remains unbuilt.

*For correction:* The tunnel intentionally uses a fixed comparison source. Teach it as such rather than requiring an import to justify the hall. Other stations quote whole-repeat width; this control quotes one source cell. Check the selected face’s actual origin and axes before expanding code.

### Symmetry_Seventeen — Make a reversal visible
Use the live and held panels to follow the same asymmetric mark through P1, PM and PG. Bring the reflected reader; on reflected alternate columns, add half the four-row source height and wrap to produce the installed glide comparison. The panels, source editor, image hold and wallpaper cage remain supplied. Predict two neighbouring source blocks before changing a mark. A generic reflected or glided arrangement needs two source blocks across its horizontal translation period, while a specially symmetric source can hide the operation or add further symmetries. Carry a motif that reveals a rule and a tested repeating unit. The seventeen-group classification and makers’ histories remain questions beyond what three buttons certify.

**Short AI alternative**
Use P1/PM/PG live-held comparison. Reuse reflected reader; on alternate reflected blocks shift source row by two and wrap four. Predict adjacent blocks and generic two-block X period. Supply editor/panels/image hold/cage. Alter asymmetric mark to hide/reveal operation. Carry diagnostic motif + tested period. Keep classification/cultural history distinct; no proof of seventeen renderers.

*For correction:* For the current even-height four-row source the glide shifts by two rows; do not silently generalise that discrete recipe to odd heights. A source block is not necessarily the whole field’s translation unit. The selected renderer name is not a proof of the resulting pattern’s complete symmetry group.

### Ribbon_Patterns_01 — Let height enter the pattern
The marked source and selected volume cube let the student follow one lookup through height. Bring the earlier volume convention, values[y][z][x], and explicitly name the source plane SOURCE[z][x]. Repeat the source through four layers, then let the layer index shift its source column: SOURCE[z][(x+y)%4]. Predict a selected address before using its marker. Cube creation, selection and slicing are supplied. Turning SLICE on hides forty-eight of the sixty-four stored values; the comparison changes visibility without deleting entries. Zero now selects a pale colour, not vacancy. Carry the layer-dependent reader and these declared meanings. The familiar starting motif returns as installed data, not a claim that a previous edit was imported.

**Short AI alternative**
Reuse volume[y][z][x]; source plane is SOURCE[z][x]. Repeat then shift lookup SOURCE[z][(x+y)%4]. Predict unequal indices before marker check. Supply cubes/selection/slicing. SLICE:16 visible,64 stored; zero=pale colour, not absence. Carry layer reader and value meaning. Fixed familiar motif, no previous-edit import. Missing full companion remains to write.

*For correction:* Preserve the YZX storage convention from the flight volume while explicitly changing values from occupancy to palette indices. The source uses ZX. Supplied rendering and selectors are not new learning prerequisites. tutorial.md is absent; this remains a plan.

### Ribbon_Patterns_02 — Compare what the carrier contributes
Keep the grey targets numerically equal while their surrounds change; there is no required perceptual answer. Bring colour values and surface addresses, then compare the same motif on a flat sheet and a curve of equal surface width. Hold the source and repeat size fixed while changing one surround, carrier or supplied shading condition. Record the equality the code guarantees separately from what appears equal from the current viewpoint. Arc length need not equal projected width. The dot-product lighting model and controls stay supplied, with the operation taught later in Forces. This hall carries a method of comparison into the studio, not a new shader assignment. Its artifact name does not establish a spectral metamerism experiment.

**Short AI alternative**
Keep reflective comparison. Equal target values, changed surrounds; same source and surface spacing, flat/curved carriers. Separate numerical equality, arc length and projected appearance. Supply controls and dot-product shading; teach operation later. No required perceptual result or new code. Carry controlled comparison to studio; no spectral-metamerism claim.

*For correction:* Retain the reflective mode. Equal physical repeat spacing here differs from equal UV repeat counts on differently sized studio receivers. No new code or dot-product prerequisite is added. Equal arc length is not equal projected width; the shader’s direction control is not a moved museum sun. tutorial.md is absent, but a short comparison companion is enough.

### Ribbon_Patterns_03 — Carry a small recipe onto fabric
Begin with the existing studio wall and preview skirt sharing a motif. Bring wrapping lookup and surface addresses into a small first shader: multiply mesh UV by repeat counts, add an offset, then sample the supplied texture into ALBEDO. The declared host turns four-by-four palette indices into a nearest-filtered, repeating texture and assigns materials; garment meshes and wardrobe remain supplied. Write and explain the reduced fragment calculation before comparing repeat and offset separately. UV repeats are counts per mesh, not metre spacing. Use the existing SAVE and WEAR SAVED flow to compare live edits with a stored recipe. That file saves bounded cells and settings, not arbitrary shader code. Carry this small sampling vocabulary to Shaders; cut-out, finish and deformation remain optional encounters.

**Short AI alternative**
Use existing studio wall/skirt host. Teach tiny fragment: UV×repeat+offset → repeating nearest texture → ALBEDO. Supply palette-index→texture conversion, material assignment, meshes/wardrobe. Predict repeat versus offset; UV counts are not metres. SAVE stores bounded cells/settings; WEAR explicitly applies snapshot to Skirt. No shader-code export or general garment transfer. Cut-out/finish/deformation optional; full companion absent.

*For correction:* Use existing Recipe.material and studio.refresh as the explained host. Current SAVE accepts repeats 4/8 and offset 0/.125 plus supported cells/settings; it excludes palette, shader code, meshes and LOOK. The current preview silhouette is chosen separately on wear. Select the reduced fragment excerpt and exact learner edit location before the full lesson; no new host is needed. All three Ribbon tutorial.md files are absent. Do not require finish or vertex deformation before the later Shaders sequence.

## 6. Change: Rate, Accumulation, and Flow
PROPOSED. Bring functions, position differences, loops and retained traces. After Tiling, supply a smooth callable curve rather than treating a sampled texture as one. In the first hall, separate writing a finite-rate function from writing a finite-sum function; return to the bridge as a signed-change comparison. In the second, let a supplied field choose each next displacement. Carry explicit inputs, units and update rules into Forces, where velocity will be retained and changed by acceleration. Keep field construction, analytic calculus and controlled step-size comparisons outside the first making task. Existing museum hosts remain; exact learner edit locations and full lessons are pending.

### Change_Intro — Measure, then accumulate
The wide joining line falls while the curve rises at its first sample. Bring functions and position differences; use the supplied smooth curve to write a finite-rate function from two heights and a nonzero horizontal interval. Predict the sign on another interval, then compare it with the supplied tangent. On a second visit to the next bench, reuse that callable curve in a loop summing height-times-width contributions. Keep the interval fixed while changing either count or sample position, and predict one rectangle before checking the total. Plots and controls are supplied. The reference is another finite sum, not the exact integral. The bridge introduces a different arch: use its supplied signed-rate comparison to ask why a rise and fall can leave no net height change. Carry two small functions with named inputs and units; x is position here, not elapsed time.

**Short AI alternative**
Reuse functions/differences/loops. Supply smooth f(x), plots, tangent and controls. First: finite rate over nonzero h; predict sign elsewhere. Next: sum f(sample)*width over fixed interval; vary count or sample fraction alone; predict one contribution. Carry rate/sum functions with units. x=position, not time. Reference=finite 4096-midpoint sum. Bridge uses DIFFERENT arch: supplied signed-rate comparison, net change not total travel. Exact learner edit location pending.

*For correction:* Two small making lessons, not a calculus survey. Keep the smooth function shared by the first two benches separate from the bridge arch. A tangent formula and finite reference are supplied comparisons; the student need not derive either. Finer samples do not guarantee monotonically smaller error. Choose the exact learner edit/receiver connection before expanding code; no replacement workbench. The bridge is a reflective return, not a third compulsory coding task.

### Flow_Field — Let the next address follow the last
Particles keep moving while FIELD HELD stops the field clock. Bring position updates, elapsed seconds and Trace’s retained list. Read the supplied direction function at one position in the two-dimensional canvas; multiply its unit direction by speed and elapsed seconds to get a displacement, then use the new position for the next lookup. Predict two updates from another starting address. Rendering, the field sampler and boundary handling remain supplied; state the canvas frame before relating it to the hall. Carry a follower and its position record, with no stored velocity or inertia. On a return, compare one step with two half-steps using the same start, held field, speed and total duration. This is a proposed calculation, not the SPEED button. Inspect the installed trail across a wrap: its joining stroke can invent a crossing. Separating trail segments remains an optional future extension.

**Short AI alternative**
Use FIELD HELD: field clock stops, particles continue. Reuse position/delta/retained list. Supply field_direction(Vector2 canvas_position), renderer/boundary policy; declare frame. Teach unit direction*speed*seconds→displacement; next address→next lookup. Predict two updates from another start. Carry follower/record, no inertia. Optional return: dt versus two dt/2, same start/field/speed/duration; SPEED is not time step and RESET rescatters. Current trails join wraps; segment break only proposed. Defer noise/angle construction and Forces velocity state.

*For correction:* Select one reduced update in the existing shared_field host; state the Vector2 canvas coordinates and the conversion to museum display separately. The sampler and noise/angle construction remain supplied. SPEED changes prescribed speed; RESET chooses fresh positions. Neither is a controlled numerical-step comparison. Keep such a comparison for a return with identical conditions and equal total duration. Trail segmentation is an unimplemented proposal, not something this summary pass fixes.

## 7. Vectors & Forces: From Direction to Dynamics
PROPOSED. Return to known positions, displacements and route records; re-explain any earlier operation that the learner has not yet owned. Separate an analytic launch from an engine-driven force pulse, then make velocity assignment versus retained velocity the central comparison. Reuse the small state update for restoration and damping. Treat work, support and targeting as selected comparisons rather than additional compulsory builds. The closing field names its cube and visitor receivers before Form Finding deliberately removes carried velocity. Keep all thirteen halls and their critical writing; reduced edit bindings and cross-hall learner-code transfer remain to be written.

### Vectors_Act1_WhatAVectorIs — Move the relation without changing it
SHIFT moves both pins while the wall arrows keep their displacement. Reuse positions and translation by reading the existing sample_vector(): end minus start in world coordinates. Predict one tip movement in the XY view and the XZ view, then reveal PARTS to check what each picture omits. SHORT, LONG and ZERO separate magnitude from direction without another drawing exercise. At the normalization companion, briefly explain division by nonzero length and its chosen small-input threshold; do not assume an earlier mention established the skill. Carry a measured displacement whose frame, origin and display scale are stated. Keep the other instruments available as returns.

**Short AI alternative**
Use SHIFT and the existing sample_vector(); reuse positions and translation. Predict a tip movement in supplied XY/XZ views, then reveal PARTS. Use SHORT/LONG/ZERO to distinguish magnitude and direction. Briefly explain normalization and its threshold at the companion. Carry a world displacement with stated display scale; require no new projection display or force controller.

*For correction:* Keep this opening a short return. sample_vector() measures world positions; wall drawings scale by 0.85 and clip to radius 1.05 without clipping the numeric vector. SHORT/LONG supply the diagonal below 0.0001, whereas the separate normalization companion returns zero at or below 0.001. Translation's final explains direction and distance, but its present tutorial does not establish normalization practice. No new display binding is implied.

### VFM_02_Operations — Keep the destination and compare routes
GO carries the cube along A and then B; SWAP changes the corner without changing the destination. Reuse displacement and accumulation in the existing room_sum study. Keep its controls, carriage and drawings supplied. In refresh(), calculate result from a+b, then compare a.length()+b.length() with result.length() before running PATH via A or direct. Read the existing travelled increment to see how the executed route is counted. CANCEL makes the distinction sharp: a nonzero out-and-back journey has zero displacement. Carry endpoint and distance as separate accounts. The local plan's forward component maps to negative Z, and GO's instant return home lies outside its reported trip.

**Short AI alternative**
Use GO/SWAP/PATH/CANCEL on room_sum. Reuse displacement and accumulation. Own result=a+b and compare summed leg lengths with direct length in the existing refresh path; keep movement and drawing supplied. Check against the actual travelled counter. Carry destination and distance separately, with local forward mapped to -Z and GO's reset excluded. No new carriage or transport binding.

*For correction:* The installed room uses buttons, not draggable pins. Vector2 stores local X/forward in metres, and floor_point maps forward to -Z. refresh() already supplies the common result to drawings and the route built by GO. The physics callback counts actual prescribed movement and consumes remaining movement budget across corners; leave it supplied. GO and input/path edits reset the counter, while RULE and selecting A/B do not. Do not claim a learner function is already bound to a separate host.

### Vectors_Act2_VectorArithmetic — Keep the component along a direction
Start with SWAP, SHIFT and SAME at the subtraction stage, reusing the measured gap rather than adding another construction. The projection station already reads this source within the same hall. RESET gives it a unit rail; SLIDE moves A across that rail while the gold part stays fixed and the pink remainder changes. In the supplied refresh path, compute gap.dot(axis), form kept=axis*gap.dot(axis), then remainder=gap-kept. Recombine the parts before trying TURN and FLIP. Carry a signed along-axis reading and the remainder it cannot describe. The FRIEND threshold and stationary torque wheel remain short comparisons about the uses of a calculation; neither adds a required controller or cross-product lesson.

**Short AI alternative**
Return to SWAP/SHIFT/SAME, then use the actual gap-to-projection connection. Teach signed dot reading, kept vector and subtracted remainder in the existing refresh path; recombine and predict SLIDE/TURN/FLIP. Supply unit rail, controls and diagrams. Carry a projection plus remainder. Keep FRIEND and torque as brief comparisons, not extra builds or evidence of mastered cross products.

*For correction:* This is a real same-hall connection, not transport from the previous room: connect_source() finds the source under the same em_map owner and subscribes refresh(). Coordinates are model X/forward, displayed at half scale, not visitor positions. TURN changes the rail by 30 degrees; bounded SLIDE requests move source A perpendicular by 0.5. FRIEND's 0.985 threshold and torque's unit-direction cross product are independent demonstrations, not subscribers. Keep normalization and subtraction as returns; the substantial new lesson is projection with its remainder.

### VFM_05_Launch — Read a flight from its beginning
FIRE sends the marker through a curve; PAIR offers equal ranges with different flight times. Reuse elapsed time, vector components and the distinction between a position and its rate. Introduce acceleration's units, then supply the constant-acceleration position formula, angle conversion and landing-time calculation already used by launch_chamber. Trace flight_position() and change one initial condition, keeping gravity fixed. PATH shows its sampled prediction; PARTS lets the student compare zero vertical velocity at the apex with continuing downward acceleration. SLOW changes playback time without changing the path. Carry a usable position-at-time function and its assumptions into Motion, where retaining and updating velocity becomes the new task.

**Short AI alternative**
Use FIRE/PAIR, then trace existing flight_position(). Reuse time, vector components and rate. Supply the analytic position formula, angle conversion, duration and receiver; introduce acceleration's units without deriving a ballistic solver. Vary one beginning, inspect PATH/PARTS and distinguish SLOW from changed gravity. Carry a position-at-time function with assumptions. Launch stays before Motion; no integration or collision response is claimed.

*For correction:* Launch precedes Motion. Supply p(t)=origin+v0*t+0.5*g*t*t, angle-to-velocity conversion and duration rather than asking for their derivation. The existing host clamps each lane to its own equal-height landing time; the frozen velocity is pre-impact. PATH is 64 equal-time segments, while live markers are evaluated analytically. PAIR has separate lane origins, so equal range does not mean the same world endpoint. Parameter edits reset the flight; SLOW only rescales its local clock. No learner-path binding or ballistic solver is newly installed.

### VFM_03_Motion — End the command and keep the motion
A one-second push ends while the cube continues. Bringing Launch’s initial velocity and Change’s rate and accumulation, the student writes a finite force schedule for a supplied rigid body. Before running, they predict the velocity change: force divided by mass, multiplied by pulse duration. They compare one- and two-kilogram beginnings with drag off, before either cube reaches the frame. The learner owns when the command starts and ends; the engine retains velocity and supplies integration and contact. A perpendicular pulse then meets motion already acquired. COAST cancels the command; it does not erase that history. The kept pulse rule and prediction prepare the next room to expose the state update itself. The friction ramp remains a separate comparison of a threshold and a simplified sliding model.

**Short AI alternative**
Reuse Launch’s initial velocity, timed callbacks and Change rates. Own a finite force schedule for a supplied rigid body; predict delta-v = (F/m)T, then compare masses from rest with drag off before contact. COAST ends the command while velocity remains. A perpendicular pulse meets existing motion. Supply engine integration, chamber and readouts. Carry the schedule and prediction into Fields. Keep the friction ramp a separate comparison; do not teach a second solver.

*For correction:* Summary proposal only. The installed motion_chamber sends force in newtons to apply_central_force; the engine supplies time integration. Do not multiply that force by dt again. Its active/delta factor only averages a partial final pulse step. COAST leaves optional engine damping active, so the controlled comparison explicitly turns DRAG off. Exact binding from a learner-authored pulse function to the supplied receiver remains to be chosen; the current operating/source companion is not evidence of that authoring interface. No new runtime check in this pass.

### Vectors_Act3_FieldsAndMotion — Give the same field two meanings
Cyan approaches the centre while pink crosses and returns. The student brings Flow Field’s sampled direction and Motion’s retained velocity into one small study with position and velocity as named state. A supplied runner calls their update: one receiver assigns velocity from the field; the other adds acceleration times the step, then both advance position using the new velocity. The same dimensionless field receives different unit conversions. Before trying the sink, they predict two steps in a uniform field from equal beginnings. Reversing the field then asks whether changing an influence erases motion already acquired. Markers, sampling and trails stay supplied; these numerical receivers have neither mass nor collisions. The learner keeps the update convention for Oscillation, through their own notes or companion file, rather than an assumed transfer between halls.

**Short AI alternative**
Reuse Flow Field sampling and Motion’s retained velocity. In a proposed small position/velocity study, own assignment versus accumulation and the subsequent position update. Predict two uniform-field steps before the sink comparison; reverse influence without erasing state. Supply dimensionless field, unit adapters, fixed runner, markers and trails. Carry the update convention manually toward Oscillation. Installed markers have no mass or collisions, and no shared learner state travels between halls.

*For correction:* Summary proposal only. field_receivers already exposes independent positions and velocities and semi-implicit accumulation in source. Each marker samples the same function at its own current position, not necessarily the same value after divergence. FIELD, GAIN and REVERSE keep state; RESET clears state and pauses while retaining parameters. Frame exit freezes outgoing state rather than colliding. A reduced learner edit function and its connection to the supplied runner are still unresolved. The proposed carried study is not an installed persistent record or crosshall transport feature. No runtime or learner-execution claim.

### Vectors_Act4a_KineticForces — Make resistance depend on motion
AIR, WATER and HONEY launch cubes at the same speed, then let them travel different distances. Bringing the pulse receiver and Fields’ distinction between a value and its operation, the student owns one linear drag function: force equals minus coefficient times current velocity. The coefficient has units of kilograms per second. A supplied rigid-body adapter passes that force to the engine; the learner does not integrate the same force again. They predict how doubling mass changes the initial acceleration at fixed speed and coefficient, then compare before either run leaves the frame. The kept resistance function supplies Oscillation’s damping term. Walking resistance, the mower’s signed work and the ring’s prescribed circle remain comparisons: different accounts can describe movement, and a return does not undo the cut lawn.

**Short AI alternative**
Own one drag function, F = -b v, with b in kg/s. Reuse Motion’s force receiver and Fields’ operation distinction. Predict initial acceleration for two masses at equal speed and fixed b; compare before frame exit. Supply engine integration, launcher and readouts. Carry resistance into spring damping. Keep walking, mower work and prescribed circular motion optional comparisons; the material names are not measured fluid properties.

*For correction:* Summary proposal only. Installed kinetic_drag applies -b*body.linear_velocity directly as force; no dt multiplication belongs in that argument. Its rigid bodies ignore contacts and are frozen at the observation cutoff; using a rigid-body engine does not imply this exhibit tests collisions. WALK is a separate chosen controller multiplier; mower work uses a nominal force, not measured hand effort; the ring prescribes a path. Exact learner drag-function binding remains open. Future focused text review: final.md’s categorical claim that air at any throwable cube speed follows a square law is broader than this source comparison establishes; this summary pass does not edit it or claim a replacement empirical result.

### Vectors_Act4b_Oscillation — Returning does not mean stopping
The released cube crosses the zero line instead of stopping there. Returning to the position/velocity study from Fields, the student adapts it to one axis and reuses Kinetic Forces’ resistance term. They own the force sum, minus stiffness times displacement minus damping times velocity, and its update: velocity changes by force divided by mass times the step; displacement then uses the new velocity. The runner, rail and handle remain supplied. Before release, they predict the restoring direction and explain why zero spring force at the centre need not mean zero motion. Equal beginnings under two damping settings test the prediction. This computed return differs from Transformation’s prescribed sine. The learner keeps a small oscillator they can vary, without assuming the museum has transported a shared state or transferred a hand throw.

**Short AI alternative**
Return to Fields’ proposed position/velocity study in one dimension; add restoration and Kinetic Forces’ damping. Own F = -kx - cv, then v += (F/m)dt and x += vdt. Supply runner, rail and handle; release starts from rest. Predict force direction and crossing, compare damping from equal beginnings, and carry the oscillator toward later waves. Distinguish computed motion from prescribed sine; no shared museum-state or hand-throw transfer is implied.

*For correction:* Summary proposal only. The installed restoring_forces variant computes scalar motion; its frozen pickable is input/display, not another body solver. k is N/m, c is kg/s, and F/m is acceleration, not F/dt. DAMP selects a ratio and computes c = 2*ratio*sqrt(k*m); changing mass or stiffness therefore changes c at a fixed nonzero ratio. Hold m and k fixed for the damping comparison. Parameter changes preserve state, whereas release starts from rest. The common learner update and its edit binding remain proposed, with manual reuse rather than automatic transport. Keep legacy cosine towers distinct; do not add a full numerical-methods lesson.

### Change_Choreography — Keep an offset, change a rate
Twenty rods turn together, form a wave, then drift apart; the conveyor gives a rate mismatch a different material consequence. Reuse indexed repetition and rate over elapsed time; introduce period and phase with the rods before returning to the supplied paired dials. Make the existing tutorial's one source edit: halve DRIFT_RATIO's excess above one, keeping the twelve-second period. Predict the gap after thirty seconds, then use SAME RATE to stop its growth without closing it. Carry a tested distinction between changing a stored angle and changing the rate added to it. Keep the conveyor as a comparison with contact, arrival and finite capacity. The paired-clock reference remains open to interpretation; this shared engine clock supplies neither independent ageing nor the bodily history of its reference.

**Short AI alternative**
Keep rods, conveyor and paired dials in their existing order. Reuse indexed repetition and elapsed time; introduce period and phase at the rods. Follow the existing DRIFT_RATIO edit from 1.04 to 1.02; predict thirty seconds of separation, then preserve the gap with SAME RATE. Supply display and controls. Carry offset versus accumulated rate difference. Conveyor contacts and the clocks' historical reference remain comparisons, not extra builds or claims of bodily simulation.

*For correction:* This uses an actual authored source exercise already present in tutorial.md, replacing the proposed extra marker-row build. Oscillation does not establish period and phase; introduce those terms at the rods. The rods assign absolute angle from elapsed time, so configuration changes may jump; the paired score instead advances stored angles, and SAME RATE preserves them. The conveyor has finite rigid parcels, contact and admission limits. Both dials share engine delta and discard whole-turn counts; neither battery ageing nor the material and bodily conditions of the Gonzalez-Torres reference are simulated. No new runtime or tutorial work is applied by this summary.

### VFM_07_Gravity — Allow the reference to answer
The gold satellite turns around a held source; at the next station both bodies answer the attraction. Reuse separation, mass and acceleration by completing the two receiver contributions in the existing accelerations() pattern: one shared pair force, opposite signs, each divided by its receiving mass. Supply the softened law, pair loop, state and integrator. Test one pair with unequal masses before summing more pairs; equal forces need not produce equal accelerations. Read the guard that withholds body zero's response. The museum stations also change masses and beginnings, so their paths are not a controlled test of that guard alone. Third-body and NUDGE encounters remain available comparisons. Carry a paired contribution rule and the question of whose response a fixed reference leaves out.

**Short AI alternative**
Use the held source and mutual-body stations. Reuse separation and force-to-acceleration. Own the two receiver contributions in the existing pair pattern; supply softened attraction, loop and integrator. Check equal/opposite forces with unequal receiving masses. Read the omitted response for body zero. The stations change beginnings as well as recipients. Keep third-body and NUDGE as comparisons; require no new gravity solver.

*For correction:* The two-line contribution exercise is a proposed teaching emphasis on existing source, not an already rewritten tutorial or a new solver. Supply the law and integrator intact; assess the contributions before integration. The first station uses 12 kg and 1 kg with a held source; the mutual station starts with equal 4 kg bodies and different positions/velocities. Do not present their paths as an otherwise identical fixed/mutual experiment. Softened markers have no mutual collisions or player coupling. NUDGE's paired beginning and finite observation window warrant a measured comparison, not a proof of chaos or escape.

### VFM_09_Legs — Ask what supports a still body
A plate rests on four posts; removing support or shifting its mass centre changes what happens after RELEASE. Bring the distinction between geometry, physical properties and a body's received forces. Use the existing FEET and SHIFT controls to state a support hypothesis before the plate moves. Compare adjacent and diagonal pairs at the same centred mass setting: the number of posts alone cannot explain the difference. The supplied outline encloses finite pad corners and describes the initial horizontal arrangement, not every later contact. Then watch the procedural walker and inspect how its body and feet are commanded. Carry a comparison of two accounts of standing, with their limits named. No new hull routine or gait controller is required, and limb count need not become a rule for viable bodies.

**Short AI alternative**
Use FEET, SHIFT and RELEASE on the existing plate. Reuse geometry, mass centre and physical response. Predict adjacent versus diagonal support with the same centred mass; check the initial finite-pad outline against release. Supply hull and solver. Compare the commanded walker without treating it as balance validation. Carry an explicit support hypothesis and its limits; add no hull or gait implementation obligation.

*For correction:* Preserve this hall as comparison and independent judgement. The actual plate is a rigid body; the pads have finite square tops, and the hull uses their corners. The outline is an initial horizontal support estimate, not a changing contact solver. SHIFT changes the custom mass centre while keeping the configured inertia; scope the claim accordingly. The walker advances its body and places feet through authored rules without a hull-based balance test. Do not infer a required anatomy, demand that learners build a controller, or use the walker as physical validation of the plate.

### VFM_08_Arena — Ask what an encounter keeps
The crab turns toward a beacon or mushroom; a screen can remove a candidate from view. Bring distance comparisons, conditions and the previous hall's distinction between commanded movement and physical response. Before a meal starts, keep candidate positions fixed and insert the screen: predict what selection may change and what completed-meal history cannot. Read the supplied selector and feeding record to check that account. The learner need not rebuild steering, legs or an event system. The five-meal stop is authored, while the meaning of this apparent relationship remains open to discussion. Keep the collision carts as a separate, optional comparison with an explicit one-dimensional model. Carry a distinction between present eligibility, retained events and an interpretation of agency; none alone establishes the others.

**Short AI alternative**
Keep Arena a comparison. Reuse distances, conditions and commanded-body distinctions. Before feeding starts, hold positions fixed, insert the screen and predict selection versus completed-meal history. Read the supplied selector and event record; build no new controller. The five-meal stop is authored. Keep collision carts a separate model and interpretation open. Carry a distinction between eligibility, retained events and attributed agency.

*For correction:* Change the former make obligation to reflect: the current final/tutorial support an encounter and source comparison, not a prerequisite to author a new selector, gait or event framework. Selection uses a strict six-metre candidate range and a supplied visibility test; active feeding and temporary ignoring affect when selection resumes. The five completed meals trigger an authored stop, not learned policy. The carts display a supplied analytic elastic-collision account rather than measuring the crab's collisions. Keep critical interpretation available without presenting friendship, intent or conservation as facts proved by target selection.

### Vectors_Act5_ForceAsPlace — Declare what receives the field
Glass cubes show the bounded field before the visitor tries the gap. Reuse the sampled-field question from Flow Field and Forces' retained velocity: what receives this vector, in what units, and what changes? Compose an up-and-forward acceleration through the supplied controls, then read the cube's velocity increment. Set field strength to zero while a cube moves and predict why it does not stop immediately; damping and contacts still matter. Compare the visitor's separately supplied carrying rule without treating the two bodies as interchangeable. Carry a field with declared membership, units and retained state. Form Finding will reuse a direction through a different receiver: descent updates a point from a gradient without retaining velocity. Its trail records past positions, and its step size is not elapsed physical time.

**Short AI alternative**
Use cubes before the visitor crossing. Reuse sampled fields and retained velocity; compose acceleration with supplied controls and inspect the cube update. Predict zero field versus immediate stopping, keeping damping and contacts explicit. Compare the visitor's separate receiver. Carry membership, units and state. Prepare the change to Form Finding: its gradient descent stores no velocity, and its step size is not elapsed physical time.

*For correction:* The cube receiver adds field_vector * delta directly to linear_velocity; field_vector is acceleration, with no division by mass. Inside the zone ordinary gravity is suppressed, but damping and contacts remain; leaving restores saved gravity. The visitor has a separate locomotion/carry contract. Both can retain motion, so zero field does not mean stopped body. The next hall instead evaluates point - rate * gradient(point), with no velocity term or physics-delta factor; its display trail is history, not momentum. Preserve that change of model and do not promise a new receiver or descent implementation in this summary.

## 8. Form Finding: Rules, Constraints and Possible Shapes
The route asks how a form arrives and what counts as a satisfactory result. A local search, an evaluated curve, repeated geometric corrections and a solved lever each offer different ways to construct an answer. Random proposals provide a first useful search beyond greedy descent. The student ends by keeping physical behaviour, computed criteria and authored appearance distinct.

### FormFinding_Descent — Use a slope to choose the next address
STEP moves the gold point across the cost surface and leaves its history behind. The student brings Change's finite differences and a vector update, then estimates slope along two axes of a simple cost function they can edit. They subtract a chosen step times that gradient from the current address and compare two beginnings. The surface display, buttons and trail renderer are supplied. Large steps and a loose stopping threshold reveal what the update does not guarantee. The reusable result is a small optimiser with an explicit cost, step size and stopping reason.

**Short AI alternative**
Use STEP on the cost surface. Reuse finite differences and vector updates. Estimate two-axis gradient of an editable cost; subtract step times gradient. Compare beginnings, large steps and stopping thresholds. Supply surface, controls and trails. Carry an optimiser with declared cost, step and stopping reason. Keep iteration separate from physical time; small slope does not certify lowest cost.

*For correction:* Keep optimiser steps separate from physical time. A small slope does not certify the lowest cost.

### FormFinding_Catenary — Distinguish a drawn curve from a settled one
The student moves the cable's cyan beads, then inspects the formula-built washing lines and the catenoid in hand. Bringing generated positions and constrained point placement, they describe which inputs each construction obeys and make a small comparison curve through supplied anchor positions. A supplied curve sampler turns the chosen spans and sag into points; the tube renderer and analytic surfaces remain supplied. They change one anchor and test the retained constraints rather than claiming the curve found equilibrium. The reusable outcome is a curve specification that states whether shape is drawn, evaluated or physically settled.

**Short AI alternative**
Use drafted cable, formula washing lines and fixed catenoid. Reuse generated/constrained positions. Compare construction inputs; vary an anchor in a small span/sag curve and test retained constraints. Supply anchors, sampler, tube renderer and analytic examples. Carry a specification distinguishing drawn, evaluated and settled shapes. Open: whether code is needed; neither spline nor catenoid is an interactive equilibrium solver.

*For correction:* Decide whether this reflective comparison needs code at all. The cable is a drafted spline and the catenoid is fixed geometry, not an interactive film solver.

### FormFinding_Relaxation — Correct a relationship repeatedly
The cloth changes shape as the number of correction passes changes. Bringing position arrays and motion history, the student constructs a short chain with retained current and previous positions and a list of neighbour pairs with rest lengths. A supplied fixed-step runner and line renderer show it; the learner writes one distance correction while keeping selected anchors fixed. Repeating the pass lets many local requirements negotiate a shape. Comparing pass counts and turning the supplied wind off makes the budget visible. The result is a small constrained network, ready for later cloth without claiming an exact solution.

**Short AI alternative**
Use cloth responding to correction-pass count. Reuse position arrays/history. Build a short chain with current/previous positions and neighbour rest lengths; teach distance correction, zero-distance guard and pinned-endpoint effects. Supply fixed-step runner, line renderer and wind. Repeat passes, vary count and disable wind. Carry a constrained network and explicit computation budget; defer full cloth and exact-solution claims.

*For correction:* Begin with a short chain rather than the whole cloth. Explain the zero-distance guard and how pinned endpoints affect each correction.

### FormFinding_Equilibrium — Place a pivot from the loads
At the mobile, a heavier disc hangs nearer its pivot, and nothing needs to move for that relationship to appear. The student brings distances, mass and functions, then calculates the two arm lengths for one pair of supplied modelled masses over a chosen total span. They build that small arm from known line and point operations and check the two mass-distance products. Disc geometry and the larger branching mobile are supplied. The reusable outcome is a balance function; a bottom-up hierarchy can reuse it later, without claiming the displayed sculpture is dynamically simulated.

**Short AI alternative**
Use the mobile's heavier disc nearer its pivot. Reuse distance, mass, functions and line/point construction. Calculate two arm lengths across a chosen span; check equal mass-distance products. Supply modelled disc masses, geometry and larger mobile. Carry a balance function for later hierarchy. Omit rod/wire mass explicitly; display is not dynamic simulation. Defer recursion; production use does not require teaching it.

*For correction:* Do not introduce recursion solely because the production mobile uses it. Rod and wire mass are omitted in this model.

### FormFinding_Annealing — Let a search sometimes climb
The wrinkled bench traps a local descent, while the annealing table sometimes accepts an uphill move. Bringing the cost function and stored bounded random choice, the student proposes a nearby candidate, compares its cost and always accepts improvements. For a worse candidate, a supplied temperature-to-probability function gives a threshold against a zero-to-one draw. The landscape and controls are supplied. They keep a best-so-far record separate from the current position and compare cooling schedules. The reusable result is a search that can leave one basin, without promising the best answer or treating temperature as physical heat.

**Short AI alternative**
Use wrinkled descent and annealing tables. Reuse cost and stored random choice. Propose candidates; accept improvements. For worse candidates, compare zero-to-one draws with supplied temperature-dependent probability thresholds. Keep current/best records separate; compare cooling. Supply landscape/controls. Carry probabilistic search without optimality or physical-heat claims. Open: best-so-far host display. Defer distribution quality and seeded replay to Randomness; explain probability here.

*For correction:* Explain this minimal probability use here; distribution quality and seeded replay remain for Randomness. Verify the proposed best-so-far teaching display against its eventual host.

### FormFinding_Forge — Write what counts as success
The student stacks loose pieces and discovers that a quiet low heap can fail the puzzle's height requirement. Bringing timers, comparisons and physical versus prescribed motion, they write a small success predicate for a supplied stack observation: choose what height and duration of low movement should count, then test a construction the original criterion rejects. Contacts and measurements are supplied. The clock-driven forge and restarting optimiser provide contrasting arrivals to inspect. No new syntax is required; the learner carries a declared criterion and can distinguish meeting it from becoming alive or finding a universally best form.

**Short AI alternative**
Use the quiet low stack failing height requirements. Reuse timers, conditions and physical/prescribed distinctions. Write height-and-low-movement-duration success criteria; test a rejected construction. Supply contacts and measurements. Carry a declared criterion without new syntax or claims of life/universal optimality. Compare restarting optimiser and clock-driven forge. Open: measurement interface; MAX Q is a clock effect, not an optimisation measure.

*For correction:* Confirm the small measurement interface before expanding code. The forge's MAX Q is clock-driven and must not become an optimisation measurement.

## 9. Wavefunctions: What Returns
Sine returns as something already usable, now examined through state, sampling, circular coordinates, spatial form and sound. The student contrasts a computed swing with a prescribed cycle, constructs a wave through neighbouring interactions, and separates a sound event from the signal it starts. The final harmonic sum recombines functions and arrays while making the limits of its chosen vocabulary available for the coming study of randomness.

### WaveFunctions_Intro — The same angle can carry another motion
The released pendulum crosses the ring twice with opposite velocity signs. Bringing the spring's state update and vector projection, the student makes a small angular model using a supplied restoring-acceleration rule, then compares releases from the same angle with different initial angular velocities. The bob, constrained hold and hand-velocity samples are supplied; projecting the release along the swing gives one deliberate input. Nearby sine-driven cubes provide the contrast with prescribed motion. The learner leaves with an angular state model and can explain why position alone does not determine what happens next.

**Short AI alternative**
Use opposite-velocity pendulum crossings and prescribed sine cubes. Reuse spring integration and dot projection. Teach angle/angular-velocity state; project hand release along swing and compare equal angles with different velocities. Supply bob, constrained hold, hand samples and restoring-acceleration rule. Carry angular state beyond position alone. Open: timestep and damping; current texts identify frame-dependent damping.

*For correction:* Resolve the teaching model's timestep and damping before code expansion; current source texts identify a frame-dependent damping regime.

### WaveFunctions_Pendulum — Keep when as well as where
A teal mark recedes behind the pendulum while the bob returns. The student brings Trace's ordered positions and now records a named position and timestamp for each sample, then draws age along a separate axis. The pendulum and drawing receiver are supplied; the learner owns sampling interval, count limit and age limit. Comparing a fine record, a coarse one and sampling near one whole period shows that an unchanged motion can leave very different evidence. The reusable outcome is a bounded timestamped recorder, with its display direction distinguished from the body's actual path.

**Short AI alternative**
Use the pendulum's receding teal record. Reuse Trace and elapsed time. Teach named position/timestamp fields, sampling interval and count/age bounds; draw age on a separate axis. Compare fine, coarse and near-period sampling. Supply pendulum state and renderer. Carry a bounded timestamped recorder with temporal resolution/span. Keep display direction separate from body path; do not silently encode time in position components.

*For correction:* Introduce named fields for position and time explicitly. Do not reuse a Vector3 position component as time without explaining that changed data contract.

### WaveFunctions_Sine_Space — Make a wave into a surface
Spheres meet the tray's folds, while the corridor's moving walls offer a different relation to the visitor. Bringing indexed geometry and the early sine function, the student samples two spatial sines on a small grid, multiplies them into heights and joins neighbouring samples with known triangles. A supplied mesh-to-collision step gives the static tray a physical boundary; sphere release and counting remain supplied. They compare surface relief with body size before the observation window ends. The reusable result is a sampled height surface, with spatial frequency, visible geometry and physical contact kept distinct.

**Short AI alternative**
Use the tray and collision-disabled corridor walls. Reuse grid samples, triangles and sine. Multiply two spatial sines into grid heights; join neighbours. Supply static mesh-to-collision creation, sphere release and counts. Compare relief with body size within the observation window. Carry a sampled height field distinguishing spatial frequency, visible surface and contact. Defer moving construction until mesh/collision updates are explained.

*For correction:* The corridor walls have collision disabled. Keep the student construction static until a later lesson explains updating both mesh and collision.

### WaveFunctions_Unit_Circle — Build the circular sampler
The rotating point supplies two projections, and the graph keeps a history of one of them. Reusing the sine cycle and pivoted construction, the student writes the circular position function that earlier lessons supplied: cosine and sine give the two offsets, radius scales them, and the centre places them. The reference circle, angle control and graph receiver are supplied. Quarter-turn predictions establish radians, phase and the relation between both coordinates. The learner replaces a borrowed circle sampler with an understood generator, while recognising that one projection alone cannot recover the whole position.

**Short AI alternative**
Use rotating point, two projections and graph. Reuse sine and pivot/radius. Teach centre plus radius-scaled cosine/sine; predict quarter turns to establish radians/phase. Supply circle, angle control and graph receiver. Carry an understood sampler replacing those supplied in Primitives and curved strips. One projection cannot recover full position; do not generalise uniform rotation to all periodic motion.

*For correction:* Return explicitly to the sampler supplied in Primitives and curved-strip construction; do not claim all periodic motion is a projection of uniform rotation.

### WaveFunctions_3D_Wave_Propagation — Let neighbours transmit a disturbance
The central sphere moves, and a pulse reaches its neighbours only when coupling is enabled. Bringing the spring update and indexed states, the student makes a short row of oscillators whose acceleration includes differences from adjacent displacements. A supplied fixed-step runner, impulse control and marker display make the comparison visible. Each step reads the old row before committing the new states, so update order does not quietly favour one direction. Comparing linked and independent runs separates a travelling disturbance from a collection of imposed phases. The reusable result is a local interaction rule that transmits change.

**Short AI alternative**
Use the current coupled lattice. Reuse spring updates and indexed states/copies. Teach acceleration from adjacent displacement differences in a short oscillator row; read all old states before committing updates. Supply fixed-step runner, impulse control and markers. Compare linked/independent runs. Carry local transmission distinct from imposed phases. Keep older dropped-pebble/distance-delay proposals separate.

*For correction:* Use the current coupled lattice primary; the older tutorial's dropped pebbles and distance-delay source generator describe another proposal.

### WaveFunctions_Effect_Sound — Put one oscillation inside another
At the two desks, the held note makes a change of the orange ball audible beside its baseline. The student brings sampled functions and sine, then fills a short list of sound samples with a carrier whose phase receives a second sine. A supplied buffer encoder and player turn the list into a note; the amplitude envelope and audition controls are supplied with their roles stated. They keep carrier frequency fixed while comparing modulation depth. The reusable outcome is a small signal function, with modulation inside phase distinguished from simply adding another audible tone.

**Short AI alternative**
Use two desks and held-note comparison. Reuse sampled functions and sine phase. Fill a finite sample list with a carrier receiving a second sine inside phase; hold frequency while varying depth. Supply encoding, playback, envelope and audition controls. Carry phase modulation distinct from tone addition. Open: responsive note length and desktop input; the scope does not prove listening experience.

*For correction:* Choose a responsive teaching note length and provide a real desktop input path. The existing scope is not proof of the listener's experience.

### Wavefunctions_Bernini — Read time through a static form
A ridge twists upward while its whole column slowly turns. Bringing the circle sampler and height-field construction, the student builds a short stack of rings whose angular offset depends on height, then connects corresponding corners using their known face construction. Lighting and a reference column are supplied. They pause their whole-object rotation to inspect the twist that remains, then restore it without rebuilding the profile. The learner carries a height-dependent geometry generator and a clear distinction between a form varying through space and that completed form changing through time.

**Short AI alternative**
Use the twisting, rotating column. Reuse circle sampling and connected faces. Build a reduced ring stack beside it with angular offset depending on height; connect corresponding corners. Pause/restart whole-object rotation without rebuilding geometry. Supply reference column and lighting. Carry spatial twist distinct from temporal animation. Open: source-check reduced geometry; avoid the old incomplete triangle-strip construction.

*For correction:* Use a reduced shaft beside the exhibit; its geometry should be source-checked instead of repeating the old tutorial's incomplete triangle-strip construction.

### WaveFunctions_John_Cage — Compose what chance may choose
The student listens for a continuous layer and intermittent events, then attends to their intervals instead of counting every entrance. Bringing the early bounded random choice and timed score, they make a short event score from a supplied sound collection, explicitly choosing the available entries and interval bounds. Sound generation and playback are supplied. Replaying a kept event list distinguishes the decisions that composed a vocabulary from the choices that arranged one performance. No new syntax is necessary. The reusable outcome is an inspectable chance score that prepares the deeper Randomness sequence without claiming to perform a Cage work.

**Short AI alternative**
Use continuous sound and intermittent events; attend to intervals. Reuse bounded choice and timed scores. Propose a retained event list with chosen vocabulary/interval bounds; replay to distinguish authored options from performance choices. Supply sounds and playback. Carry inspectable chance composition toward Randomness without new syntax. Open: replay extension; current soundscape records no visitor sound and implements no particular Cage score.

*For correction:* A replayable teaching score is a proposed extension. The current soundscape neither records visitor sound nor implements a particular Cage score.

### WaveFunctions_AirMusic — Give each note its own beginning
A struck bar keeps ringing after the hand leaves; striking another adds a voice while restriking the first restarts it. The student brings the generated note and event-based state, then gives two supplied sound players separate start times and multiplies each sine by a decaying envelope. The striker detection, buffer encoder and bar bodies are supplied. They compare a retrigger with two overlapping notes and keep the chosen frequency independent of visible bar length. The reusable outcome is an event-driven voice whose age belongs to its own beginning, ready to combine with others.

**Short AI alternative**
Use ringing bars, retriggers and overlapping strikes. Reuse sine notes and event state. Give two supplied players separate start times; multiply each sine by a decaying envelope. Compare retrigger/overlap; keep chosen frequency independent of visible length. Supply strike events, bodies and encoding. Carry independently aged voices. Open: desktop strike input; the synthesised model does not derive frequency from material.

*For correction:* Use the current synthesised-bar model. A physical bar's frequency is not solved from its material, and desktop strike input must be made concrete.

### Wavefunctions_Sky_Stairs — Turn sampled positions into support
The spiral's radius breathes while its treads rise steadily, and connecting surfaces fill some spaces between them. Bringing circular sampling, spatial sine and repeated bodies, the student constructs a short three-to-six-tread segment beside the existing stair. They calculate tread centres, then give each a width, orientation and separate collision boundary through supplied tread components. Comparing inner and outer edges exposes what centre spacing leaves undecided. The large staircase and its surrounding floor are supplied for inspection. The reusable outcome is a small route segment whose support is tested independently of the smooth formula behind its outline.

**Short AI alternative**
Use uniform rise and sine-modulated stair radius. Reuse circle sampling, spatial sine and repeated bodies. Build three-to-six treads beside the stair; calculate centres, widths, orientations and separate collision boundaries. Supply tread components, staircase and viewing floor. Compare inner/outer edges. Carry a tested support segment beyond centre spacing; do not infer complete climbing or headset comfort.

*For correction:* The active stair has uniform rise and sine-modulated radius. Do not claim a complete climb or headset comfort from the sampled segment.

### WaveFunctions_TrigWalkingPath — A slow envelope from two fast returns
At the three rows, A and B keep oscillating while their sum grows and shrinks more slowly. Bringing sine functions and independent rates, the student samples two close frequencies at the same times and adds their signed values into a third record. The row display and frequency controls are supplied; the learner states its drawing scale separately from the computed sum. They exchange which frequency is higher and predict the envelope's pace before running again. The reusable result is a two-signal comparison that reveals cancellation without inventing a third source or claiming the visual exhibit produces sound.

**Short AI alternative**
Use the three-row beat exhibit. Reuse sine, frequency and phase. Sample two close frequencies at shared times; add signed values into a third record with separate display scale. Supply rows and controls. Exchange higher frequency and predict envelope pace. Carry superposition/cancellation without a third source or audio claim. Keep walking paths secondary: finite and circulating, not endlessly generated.

*For correction:* Keep the beat exhibit primary. The existing walking paths are finite and circulating, not generated endlessly beneath the visitor.

### WaveFunctions_Synthesis_Lab — Choose the parts of a wave
The five coloured rows can be removed until only one sine remains beneath the pale sum. Bringing signal addition, lists and loops, the student writes a function that visits a coefficient list and adds each weighted harmonic at one shared phase. The sliders, sample plot and held comparison are supplied. They predict the contribution at a marked address, build a chosen finite shape and state which changes its nonnegative coefficients cannot express. The reusable outcome is a compact wave recipe; the room-memory detour offers a separate comparison between repeating stored state and processing it again.

**Short AI alternative**
Use five harmonic rows and their pale sum. Reuse addition, lists and functions. Sum weighted harmonics from coefficients at shared phase; predict a marked sample and build a finite shape, naming nonnegative-coefficient limits. Supply sliders, plot and held comparison. Carry a wave recipe. Keep room-memory repeat/reprocess comparison separate; this visual bench neither shares specimen state nor generates its waveform's audio.

*For correction:* This bench is visual. Do not imply it shares state with the other lab specimens or already turns the composed waveform into audio.

## 10. Randomness: What Can Chance Change?
PROPOSED. Deepen the bounded choices already used earlier into reproducible procedures, retained samples, distributions and feedback. The learner makes small, useful operations beside the existing museum encounters; the full artifact, its input and its presentation remain named supplied parts. These teaching connections need approval and implementation before any promise of transporting learner work between halls.

### Random_Definition — Keep a generated arrangement
At the paired colour grids, the student chooses an arrangement worth recovering. Bringing RGB colours, lists, loops and bounded random choice, they make a colour recipe with a local seeded generator and explicit request order. A proposed adapter would send their colour list to one existing grid while the other holds a witness; this interface is not yet verified. The displays, replay controls and generator internals are supplied. One unused request reveals why a seed alone cannot identify a picture. They keep recipe and seed together, gaining a reproducible construction for later reuse.

**Short AI alternative**
Use paired colour grids. Reuse RGB lists, loops and bounded draws. Teach a local seeded recipe with explicit request order; insert an unused request to change the picture. Supply displays, replay controls and generator internals. Carry recipe plus seed. Open: verify the proposed colour-list adapter and witness grid; promise neither existing transfer nor cross-version replay.

*For correction:* Propose a colour-list adapter for one existing grid, retaining the other as witness. Its implementation and available interface still require verification; do not promise cross-version replay.

### Random_Entropy — Count what the arrangement loses
The ledger's tiles change neighbours when sorted, while their counts and entropy reading stay fixed. Bringing retained lists and seeded samples, the student makes a frequency table from a small symbol record, copies that list before sorting, and displays both arrangements beside the same counts. Copying preserves a snapshot instead of another reference to changing data. The ledger, tile renderer and entropy calculation are supplied. They learn what counting discards and carry both a sample-to-count operation and a way to keep earlier states, without making the statistical reading a measure of freedom.

**Short AI alternative**
Use the ledger's sorting tiles. Reuse retained seeded samples. Teach frequency counting and copying before sorting; compare changed neighbours against unchanged counts and entropy. Supply ledger, tiles and entropy calculation. Carry a snapshot and separate frequency account; entropy does not measure freedom. Open: Definition's colour-record transfer is proposed; the ledger owns its sample.

*For correction:* The current ledger owns its sample; transferring Definition's colour record would be a new connection.

### Random_Remove — Choose who can be chosen
At the amber removal board and paired sampling hoppers, the student predicts an impossible choice before drawing. With grid addresses, conditions and a seeded generator, they construct an eligible list, draw one member, and decide whether to return it or remove it before the next draw. The board, hopper animation and removal floor are supplied. This makes sampling with and without replacement usable rather than merely named. The remaining list travels forward as a way to control opportunity; the floor separately shows when removing a visual also withdraws collision.

**Short AI alternative**
Use the amber board, sampling hoppers and removal floor. Reuse addresses, conditions and seeded draws. Teach an eligible list; predict excluded choices, then draw with or without replacement. Supply displays, animation and floor. Carry candidate list and removal policy; distinguish visual removal from lost collision. Open: choose the board adapter or a compact supplied display.

*For correction:* Choose whether learner results drive the board or a compact supplied display beside it.

### Randomness_10_PRINT_Algorithm — Give each choice a mark
The student follows diagonals from the printing screen into the slab arrangement. They bring grid traversal, lines and bounded choices, then construct a small tile drawing in which each retained draw selects one of two diagonal endpoints. Changing the threshold changes the choices; changing the mark changes their reading. The existing screen, wall-scale display and separate navigation study are supplied. They leave with a reusable rule for assigning marks to addresses, knowing that a convincing maze image has not yet established a connected route or a passage wide enough for a body.

**Short AI alternative**
Use printing screen and slab arrangement. Reuse grid traversal, lines and retained draws. Teach mapping each draw to two diagonal endpoints; vary threshold or mark separately. Supply screen, large display and navigation study. Carry an address-to-mark rule. Distinguish the screen's sine-driven bias from fixed learner probability; maze appearance proves neither connected routes nor bodily clearance.

*For correction:* Keep the screen's sine-driven bias distinct from the fixed-probability learner construction.

### Random_Cubes — Let an outcome continue an instruction
After throwing the physical die, the student follows the continuing die's chain: six permits another throw, while another face ends the sum. Bringing state, retained outcomes and counting, they make a bounded accumulator called once by each supplied landing event. It records the face, adds its value and decides whether the chain remains open. The die physics, landing-event connection and column display are supplied. They gain a reusable event-driven accumulator without having to implement asynchronous input. A visible limit reports an unfinished chain; the retained sequence distinguishes the total from how it was reached.

**Short AI alternative**
Use physical and continuing dice: six continues, another face ends the sum. Reuse state, sums and retained outcomes. Teach a bounded accumulator invoked once per accepted landing; report unfinished chains at the limit. Supply physics, landing connection and columns. Carry sequence, total and stopping rule. Preserve physically read faces; no RNG substitution, waiting loop or fair-release claim.

*For correction:* The supplied landing event invokes the learner's accumulator once per accepted throw. Do not replace the physically read face with an RNG, spin a loop waiting for it, or imply fair releases.

### Random_Rotate_Random_XYZ — Separate an increment from a position
The turning cube and prism stacks keep their places while their orientations accumulate small changes. Bringing transformations, time steps and random draws, the student makes a short orientation history for one supplied piece, comparing assigning a fresh angle with adding an increment to the existing angle. The stack renderer and its existing controls are supplied. They learn to identify the state that persists and what RESET actually restores, then carry that distinction into a walking position. The wear rig remains a useful counterexample: its changing appearance does not require random input.

**Short AI alternative**
Use turning stacks and wear rig. Reuse transforms, time steps and draws. Compare fresh-angle assignment with accumulated in-plane increments; record orientation and inspect RESET. Supply stack renderer and controls. Carry persistent state versus increment into Walk. Identify the production update's frame dependence; the historical XYZ title misleads, and the wear rig changes without randomness.

*For correction:* Historical map title and old tutorial suggest independent XYZ rolls; current encounter is accumulated in-plane rotation. Its frame-dependent production update should be identified, not copied as a timing model.

### Random_Walk — Build a walk that remembers its position
At the terrarium and paired rails, the student predicts a destination before the animation moves there. They bring vector addition, accumulated state and Trace's retained list, then make a walker that adds a sampled displacement to its current position and records each accepted endpoint. The moving bead, timing controls and boundary comparison are supplied. They choose and explain a boundary rule rather than hiding it inside a helper. The resulting walk and record are reusable separately: smooth travel can be supplied, and the trail need not influence the next decision.

**Short AI alternative**
Use terrarium and paired rails. Reuse vector addition, accumulated state and Trace's list. Teach sampled displacements and recorded endpoints; predict a step and state its boundary rule. Supply bead, timing and boundary comparison. Carry walker and separate record; smooth travel need not affect decisions, nor trails guide them. Open: choose a reduced boundary example before full folding.

*For correction:* Choose a reduced boundary example before expanding to the terrarium's full folding implementation.

### Random_Gaussian — Keep the values before drawing the bars
The sampling cabinet gathers falling beads into bars, then redraws those bars without taking new samples. Bringing retained lists and frequency counts, the student constructs a histogram from a saved numerical sample and changes its interval boundaries while retaining every value. Uniform and Gaussian sampling functions, the cabinet and falling-bead animation are supplied, with their input and output ranges stated. The learner distinguishes sampling, clipping and binning, and leaves with a reusable distribution display. A familiar bell shape becomes something to investigate, rather than the expected destination of every random process.

**Short AI alternative**
Use the bead cabinet. Reuse retained samples and counts. Teach numerical bins; redraw boundaries without resampling. Supply uniform/Gaussian samplers with stated ranges, cabinet and animation. Carry a reusable histogram; separate sampling law, finite sample, clipping and binning. Treat the bell shape as a question. Defer sampler mathematics; decide whether an optional derivation follows.

*For correction:* Decide whether a later optional lesson derives a sampler; transformation mathematics is supplied here.

### Random_Mushrooms — Make a population with a declared vocabulary
The specimen bed, arrival wardrobe and garment comparison show several ways a recipe can admit differences. Bringing generated forms, transformations and sampling, the student makes a small population description: template identity, position and scale are stored separately, then passed to supplied specimen builders. They can preserve a placement while changing the permitted repertoire, or keep the repertoire while changing its distribution. The bed display, specimen geometry and wardrobe interfaces are supplied. The reusable outcome is a population recipe whose discrete kinds and continuous variations remain visible, including changes it cannot express.

**Short AI alternative**
Use specimen bed, wardrobe and garment comparison. Reuse generated forms, transforms and sampling. Teach separate template, position and scale records; vary repertoire independently from distribution. Supply specimen builders, bed and wardrobe interfaces. Carry a population recipe with visible discrete kinds, continuous variation and limits. Open: select the smallest honest builder interface; follow the fourteen-map sequence.

*For correction:* Current intent retains an obsolete shortened route; use the fourteen-map sequence order. Choose which specimen builder offers the smallest honest interface.

### Random_Space_Geometry — Read neighbouring samples
The WHITE NOISE and PERLIN NOISE grids let the student compare three neighbouring heights before naming a landscape. They bring grid addresses, seeded draws and value-to-height mapping, then build one short sampled profile using independent draws and another using a supplied coherent field function at the same coordinates. The comparison bench and Perlin sampler are supplied. They measure adjacent differences and change coordinate spacing deliberately, gaining a way to study spatial relationships. A field's correlation is not stored history, and matching displays does not establish matching numerical distributions.

**Short AI alternative**
Use WHITE NOISE and PERLIN NOISE grids. Reuse addresses, seeded draws and height mapping. Teach matched profiles from independent draws and a coherent field; measure adjacent differences and vary coordinate spacing. Supply bench and Perlin sampler. Carry spatial comparison; correlation is not memory, and matching displays do not establish matching distributions. Open: verify perlin_noise_bridge's reduced interface.

*For correction:* Current final centres perlin_noise_bridge, absent from the sequence's older artifact list; verify its reduced interface before writing the tutorial.

### Randomness_Examples_of_Randomness — Give chance a numerical job
Among the floor painting, pipes and particle study, the student stops at the dartboard to make an estimate. Bringing coordinates, random sampling, conditions and counts, they construct a bounded point experiment: sample inside a square, test distance from its centre, retain the hit count and compare successive estimates. The dartboard, plotting surface and controls are supplied. They learn why a random draw can support a numerical estimate and carry a reusable sample-test-count procedure. The surrounding works let them compare that purpose with choosing a mark or extending a path.

**Short AI alternative**
Use the dartboard among paintings, pipes and particles. Reuse coordinates, sampling, conditions and counts. Teach a bounded square-sampling experiment: test centre distance, count hits and compare successive estimates. Supply dartboard, plotting and controls. Carry sample-test-count estimation; contrast its numerical purpose with marks or paths. Keep finite-sample error visible: extra draws need not improve each estimate.

*For correction:* Keep finite-sample error visible; more draws need not improve every individual estimate.

### Random_Pheromone — Let the trace enter the next choice
At the terrain console, a visited patch rises while later walkers may return to its fading signal. The student brings a random walker, grid addresses and stored values, then gives their walker a separate signal field: deposit at an address, decay the field, and compare neighbouring values before selecting a step. The terrain renderer, stepped clock and walker display are supplied. They learn feedback by making a trace influence future action. The reusable field remains distinct from accumulated height, and reinforcement supplies no proof that the resulting route is shortest or best.

**Short AI alternative**
Use terrain console. Reuse walker, grid addresses and stored values. Teach a separate signal field: deposit, decay, read neighbours, choose a step. Supply terrain renderer, stepped clock and walker display. Carry feedback into future choices; distinguish fading signal from accumulated height, without optimal-route claims. Open: reusing the learner's walker is proposed; current artifacts own separate states.

*For correction:* Using the student's earlier walker here is a proposed teaching connection; current artifacts own separate states.

### Random_Space — Compose a finite field from contributions
At the noise mixer, broad features remain while finer ones arrive as layers are added. Bringing sine functions, loops and the previous field comparison, the student makes a short weighted sum that samples the same supplied base function at several coordinate scales. They retain each contribution before adding it, so removal and recombination have an inspectable meaning. The mixer display and base sampler are supplied. The outcome is a reusable finite field recipe with separate frequency and amplitude choices, preparing Noise without confusing the sine-based construction with geological processes or stored visits.

**Short AI alternative**
Use the noise mixer. Reuse sine, loops and field sampling. Teach a finite weighted sum across coordinate scales; retain contributions for removal and recombination. Supply base sampler and mixer display. Carry a field recipe separating frequency from amplitude into Noise. Disclose the mixer's display rescaling; distinguish this sine-based construction from geology or stored visits.

*For correction:* The existing mixer rescales its picture; a teaching display must disclose that mapping while comparing amplitudes.

### Random_Game — Distinguish a decision from its disclosure
The three-stone crossing and door timing trials let the student compare a wait already drawn with one still to come. They bring state, elapsed time and seeded choices, then describe a small event schedule that draws a duration once, stores its deadline and reports its remaining time. The crossing, door trials and collision timing are supplied. This deepens their ability to explain a running process without rebuilding the obstacle course. They carry a reusable distinction between state order, decision time and disclosure, while deciding how much information their own future interaction should expose.

**Short AI alternative**
Use crossing and door timing trials. Reuse state, elapsed time and seeded choices. Teach drawing one duration, storing its deadline and reporting remaining time. Supply crossing, trials and collision timing. Carry a readable schedule separating state order, decision and disclosure; choose what a future interaction reveals. Open: existing-process trace or executable teaching adapter.

*For correction:* Choose whether the small schedule is a readable trace of the existing crossing or an executable teaching adapter.

## 11. Noise: Fields and Possible Bodies
PROPOSED. Follow sampled values into constraints, colours, displacement, occupancy and borrowed coordinates. Reuse the learner's functions and arrays while supplying the field generator itself. Separate correlation from memory and the visible surface from collision. Any shared learner dataset or cross-hall transport below is a proposal; the existing instruments generally own independent samples.

### Random_Noise_Types — Give a candidate permission to remain
The held point returns to its plane, while the neighbouring slab keeps only candidates far enough from earlier points. Bringing coordinates, conditions and bounded draws, the student constructs a small placement function that proposes a position, checks its distances from the accepted list, and either records or rejects it. The grabbable point, slab display and proposal counter are supplied. They learn the difference between admission during construction and a constraint enforced every update. Their reusable sampler reports its attempt budget honestly, because failing to place a point does not prove no placement exists.

**Short AI alternative**
Use the constrained point and placement slab. Reuse coordinates, distances, conditions and draws. Teach proposing, distance-checking and accepting/rejecting positions against a retained list. Supply point, slab and attempt counter. Carry a budgeted sampler; failed attempts do not prove impossibility. Distinguish admission from enforcement every update. Defer spectral/audio galleries to comparisons unless separately approved.

*For correction:* Leave the spectral and audio galleries as comparisons unless a separate lesson is approved.

### Noise_Columns — Choose what receives a changing value
The three columns share a shaft recipe but receive held, periodic and field-derived values. Bringing sine, elapsed time and generated geometry, the student writes a driver function that returns one scalar and an explicit receiving function that turns that scalar into a column setting. They compare the same recipient under two drivers before changing the recipient. The column builder, local clock controls and marble material are supplied. The reusable outcome is a clean separation of source and use; the independently pulsing orb demonstrates why pausing this clock need not pause the museum.

**Short AI alternative**
Use three columns and independently pulsing orb. Reuse sine, elapsed time and generated geometry. Teach scalar driver and explicit shaft receiver; compare two drivers before changing the recipient. Supply column builder, local clock and marble. Carry source/use separation; stopping one clock need not stop the museum. Follow the actual shaft driver, without invented vertex erosion or loading.

*For correction:* Use the actual scalar shaft driver; do not invent per-vertex Perlin erosion or structural loading.

### Noise_One — Give one value two visible consequences
The paired rings receive the same field as relief and colour. Bringing scalar drivers, mesh positions and colour mapping, the student makes two receiving functions for a retained signed sample: one offsets a position, the other remaps the value into a colour range. The ring mesh, paired probes and noise sampler are supplied. They discover why clipping all negative values to black conceals differences that relief still shows. Their reusable pair of mappings can dress other generated forms, while the layered basin extends the comparison without claiming its different resources are identical octaves.

**Short AI alternative**
Use paired relief/colour rings and layered basin. Reuse scalar drivers, positions and colour mapping. Teach two receivers for one retained signed sample; compare offset geometry with remapped colour and inspect negative-value clipping. Supply ring construction, probes and sampler. Carry reusable mappings. Open: select directly referenced vertices; the basin's different resources are not identical octaves.

*For correction:* Select a small set of directly referenced ring vertices; the full ring constructor stays supplied.

### Noise_Voxel — Turn a field into occupied cells
At the small voxel body and its enlarged counterpart, the student holds one sample steady while the threshold removes its block. They bring multidimensional arrays, field values and conditions, then construct an occupancy array from a supplied field using an explicit height bias and threshold. The cell renderer, section screen and large collision receiver are supplied. The resulting binary volume can be inspected independently of its display. They learn that a visual cut need not change stored occupancy, and that connected occupied cells do not by themselves establish a usable route for a particular body.

**Short AI alternative**
Use small voxel body and enlarged receiver. Reuse arrays, fields and conditions. Teach occupancy from explicit height bias and threshold; hold a sample while changing its classification. Supply cells, section screen and collision receiver. Carry binary volume separate from display. Display cuts need not alter occupancy; connected cells cannot certify access. Open: choose smaller array and receiver.

*For correction:* The full 24-cubed volume is supplied; choose a smaller learner array and a disclosed receiver before implementation.

### Noise_6_Wall — Read a surface without mistaking it for support
Inside the pink enclosure, the student freezes the material and removes its finish while keeping the doors and floor in view. Bringing layered field sums, colour mappings and the garment's texture-sampling shader, they compose a signed-value-to-colour rule and compare it with the cloud material on the existing panel. The shader host, cloud sampler and room collision are supplied. This deepens the earlier surface lesson before the dedicated shader sequence. They carry a clear account of which operation changes appearance and which could change geometry; a visible fold need not become a place to stand.

**Short AI alternative**
Use the pink enclosure; freeze its finish. Reuse layered fields, colour mappings and Ribbon_Patterns_03's sampler. Teach signed-value colour mapping against the cloud material. Supply shader host, cloud sampler and room collision. Carry appearance/support distinctions; visible folds need not bear weight. Keep this 2D field distinct from Noise_Voxel's volume; dedicated Shaders deepens the supplied setup later.

*For correction:* Reuses Ribbon_Patterns_03's texture-sampling shader before the later shader sequence deepens it. This hall's 2D field is not Noise_Voxel's stored volume.

### Noise_Inside_Noise — Change the address before asking for a value
Inside the enclosing sphere, the student watches a marked direction remain fixed while its colour changes under WARP. Bringing coordinates, functions and field sampling, they construct two explicit steps: turn a position p into a borrowed address q, then ask the same supplied field for its value at q. The paired images, coordinate witnesses and sphere receivers are supplied. They can inspect the address change before applying colour or relief, gaining a reusable domain-warp function. The floor and pinned doorway edges clarify which parts of the environment receive the deformation.

**Short AI alternative**
Use enclosing sphere and fixed direction witness. Reuse coordinates, functions and sampling. Teach p-to-q address transformation before querying the same field; inspect addresses before colour or relief. Supply offset fields, paired images, witnesses, receivers and collision reconstruction. Carry domain warping separate from receiving. Preserve fixed floor and doorway edges; the study is static between actions.

*For correction:* Keep the supplied offset fields and collision reconstruction visible as dependencies; this study is static between actions.

### Noise_Space_10 — Test a proposed route against ground
The gold proposal and pink walking record cross the same terrain, but only one records a visitor's passage. Bringing Trace's position list, height sampling and surface construction, the student samples a chosen line across the supplied terrain and makes a small height profile to compare with an actual walk. The terrain collision, supported player tracking and recording interface are supplied. They learn to distinguish a geometric proposal from a tested route and carry a reusable terrain-section tool. A second body scale makes clear why a line's continuity cannot certify bodily access.

**Short AI alternative**
Use gold proposal and pink walking record. Reuse Trace positions, height sampling and surfaces. Teach sampling a chosen line through the actual triangle-height query; compare its profile with a walk at another body scale. Supply terrain collision, player tracking and recording. Carry profile and separate passage record; continuity cannot certify access. Open: cross-hall export remains proposed.

*For correction:* Expose the actual triangle-height query; exporting the student's profile or walk to another hall is proposed.

### Noise_Perlin_Simplex — Ask two fields the same question
Between the paired cube displays and walk-through arches, the student follows one shared sample address. They bring seeded field recipes and explicit receivers, then make a comparison function that asks two supplied generators for values at the same positions and records their difference. Seed, coordinate scale and output mapping become stated conditions. The Perlin and OpenSimplex2 implementations, arches and sample markers are supplied. The reusable result is a fairer comparison procedure, not a verdict that one field is more natural; removing relief also reveals how much of each arch was authored before sampling.

**Short AI alternative**
Use paired cubes and arches. Reuse seeded fields and explicit receivers. Teach matched addresses and recorded differences with declared seed, scale and output mapping. Supply Perlin/OpenSimplex2 generators, arches and markers. Remove relief to inspect authored arch geometry. Carry comparison conditions into Shaders; preserve correlation versus stored state, without ranking one field as more natural.

*For correction:* Earlier prose sends this directly to CA; the current spine inserts Shaders. Preserve the distinction between spatial correlation and stored state.

### Lab_Path — Keep an unfinished question
The optional corridor's dark sphere continues pulsing while the student recalls one change from the Noise halls. They bring a concrete encounter and the operation they traced, then make two short accounts of it: what happened to their view or movement, and which values, addresses or receivers changed. The corridor and sphere are supplied; no new code is required. Choosing a small return experiment leaves them with a useful comparison question rather than a compulsory conclusion. This paragraph is a proposed optional reflection, because the current museum portal does not connect this room.

**Short AI alternative**
Use optional dark-sphere corridor as a proposed reflection; its museum portal is inactive. Reuse one Noise encounter and source/receiver distinctions. Describe both felt view or movement and changed values, addresses or receivers; choose a return experiment. Supply corridor and sphere. Carry a specific unfinished comparison question. Require no new code or compulsory conclusion.

*For correction:* Listed in noise.json, but intent says dropped from museum and portal is inactive. Do not present it as an implemented route.

## 12. Shaders: What a Surface Answers To
PROPOSED. Familiar forms acquire new ways of appearing. Deepen the garment studio’s first shader use: construct a form from a coordinate rule, transform and repeat it, compare its material on different primitive bodies, then alter it with a layered field. Compose these choices before asking what an image must retain to evolve. Keep the existing images → bodies → rooms route. The learner carries a small form function and its settings; museum bindings and transport remain proposed until implemented.

### Shader_01_Shaping — Give a familiar form a surface rule
At the graph panels, the student returns to the point, distance and the boundary of a face. Bringing coordinates, functions, colour mapping and the garment studio’s first shader, they make one circular mark from distance to a chosen centre. A threshold turns that distance into an inside and an outside; a narrow transition softens the visible edge. The existing graphs explain the rule. The panel, material binding and coordinate display are supplied. The student changes centre and radius independently, then explains why the mark moved while the panel did not. They carry a small mask function and its parameters. A band or box is a later variation; the timed graph remains a comparison, not a second opening lesson.

**Short AI alternative**
Use graph panels to explain a circular mark. Reuse point distance, functions, colour mapping and garment UVs. Teach coordinate → distance → mask; expose centre/radius and compare sharp/soft edge. Supply panel/material binding. Check: move centre without changing radius; explain unchanged mesh. Carry mask + settings. Optional band/box; defer clock analysis. Open: learner binding; softened edge needs valid bounds.

*For correction:* The existing hall displays graphs. The learner mask and its host connection are proposed; the deferred Shapes sources provide the operation, not an installed new station. Keep one main form. Use step for a hard edge and ordered, distinct smoothstep bounds for softness. Verify the actual phase-speed control before expanding the clock comparison.

### Shader_05_Patterns — Transform the form inside its address
The tiled squares return to the earlier floor and garment, where a pattern already depended on how it was sampled. The student brings the retained mask, transforms and array addresses. They first offset and turn a band or asymmetric version of the mark around a named centre, then repeat it in a four-by-four study. The integer tile address chooses a variation; the fractional coordinate evaluates the form inside that tile. One chosen tile turns while the rest keep their orientation. They carry the mask, coordinate transform and address rule as separate parts. The garden offers a further comparison: its supplied world projection lets a pattern cross several bodies. Moving the learner’s function there needs an explicit adapter that preserves that projection.

**Short AI alternative**
Use tiled panels; return to floor/garment sampling. Reuse mask, transforms and array addresses. Offset/turn an asymmetric mark, then repeat 4×4. Teach floor = tile ID; fract = local coordinate. Check: turn one tile only. Carry mask + transform + address rule. Supply host; garden projection stays world-based. Open: binding/transfer adapter. Deferral: no new Shapes/Matrices halls.

*For correction:* A centred circle cannot reveal rotation: use a band or asymmetric mark for that comparison. Earlier tilings already use images and shaders. The current tile source draws a faint border; narrow the manuscript’s contrary claim in a later prose pass. The garden uses world triplanar mapping, not each object’s UVs. MODE/RESET rebuild materials; a future adapter must reconnect.

### Shader_11_QueerRubber — Let one material meet different bodies
The black ring catches a rainbow rim while the larger primitive bodies answer the lamps. The student returns to the faceted sphere, the garment’s curved receiver and the distinction between moving an object and moving around it. They compare one proposed teaching material on a sphere and a cube before adding a rim from supplied normal and view vectors in the same frame. Dot products now become an appearance. Keeping the material fixed, they change the body or viewpoint and account for the difference. They carry a material whose receiver matters. The existing leather, plastic and oil-like appearances remain available for looking and interpretation; the lesson does not require rebuilding all of them.

**Short AI alternative**
Use ring and staged primitives. Reuse faceted sphere, curved garment, transforms, dot product and retained material. Compare one material on sphere/cube; teach rim from unit normal/view vectors in one frame. Check: predict changed rim with body/viewpoint changed and material fixed. Carry receiver-aware material. Supply geometry/vectors/lamps. Open: shared-material and hold controls absent; emission is not a lamp.

*For correction:* The hall already supports several primitive body types, but does not provide a shared learner material switch or rotation-hold controls. Those are proposed adapter work. Preserve material associations as interpretation; do not claim simulated fibres, physical optics or a light cast on other bodies by EMISSION alone.

### Shader_09_FBM — Let a field enter the form
The student crosses the glass above the moving basin, then returns to the noise panels with the form function they have kept. Noise and weighted sums are familiar; here a finite shader loop combines a few scales with separate frequency and amplitude updates. A bounded contribution disturbs the mask’s boundary while the panel mesh stays fixed. Compare no disturbance with the chosen amount before adding time. The student changes the finest contribution while retaining the broad form and explains the difference. They carry a field function and its range. The basin’s vertex displacement and normal construction are supplied comparisons: its surface moves, but the glass is what carries the visitor.

**Short AI alternative**
Use noise panels and glass-covered basin. Reuse mask, weighted sums and Noise. Teach bounded octave loop; keep frequency/amplitude separate. Perturb mask boundary; compare zero contribution before adding time. Check: change fine detail while retaining broad form. Carry field + range. Supply base noise/material host and basin displacement/normals. Glass supplies support. Defer vertex teaching; coordinate warp optional.

*For correction:* The retained mask-to-field connection is proposed. The mask changes fragment colour, not mesh geometry; coordinate warping is optional. Keep water’s vertex displacement supplied. More octaves do not guarantee visible improvement and do add work; choose a bounded count suitable for the material.

### Shader_12_PinkExtravaganza — Compose a body and its appearance
Among the pink water, sagging sphere and plural body, the student chooses an arrangement worth keeping. They bring the form, repetition, rim and layered field developed here, together with Melencolia’s earlier work of composition. Choosing a supplied body, they combine a limited set of those operations and record what each contributes. One alternate version keeps the geometry but changes its appearance. They distinguish whole-object transformation, supplied vertex deformation and fragment colour. The outcome is a material recipe with reasons for its choices, not a new compulsory technique. The room’s associations remain open: which setting is a default, and who gets to call its appearance excessive?

**Short AI alternative**
Use pink water, sagging sphere and plural body. Reuse Melencolia composition + retained form, repetition, rim and field. Compose limited known effects on supplied body; record choices. Check: make an alternate appearance with geometry fixed; distinguish transform/vertex/fragment. Carry material recipe. Supply lamps/geometry/deformation. Open: composition binding absent. No new compulsory syntax; pink alone is not a theory of queerness.

*For correction:* A material-composition adapter remains proposed. The existing unfolding controls do not implement that task. This room can build judgment with known tools; do not impose another algorithm or treat pink as sufficient queer content.

### Shader_10_ReactionDiffusion — Ask what the form must remember
The green panel asks for a previous texture it does not receive. Beside it, branching frost looks grown without retaining that growth. The student brings the form recomputed from coordinates, Paint’s retained image and earlier old-state/new-state updates. They trace which inputs produce each picture, then sketch what would have to be stored for a changed mark to affect the next update. Restarting a clock and restoring a saved state become different operations. They carry this explicit state contract into Cellular Automata. The existing panels and texture-reading excerpts are supplied; this reflective threshold does not require repairing the exhibit or claim that its missing feedback already works.

**Short AI alternative**
Use green panel and apparently grown frost. Reuse retained form, Paint history and old/new state. Trace inputs; name what a changed mark must leave for next update. Check: explain clock restart versus state restore. Carry old-state → rule → new-state contract into CA. Supply panels/texture-reading excerpts. Host lacks previous-frame feedback; no promise of evolving chemistry or implemented transport.

*For correction:* The host does not bind the previous-frame texture. Preserve this honest threshold. The Book of Shaders contents lists simulation topics, but the linked chapters used here do not supply a finished Godot reaction-diffusion lesson.

## 13. Cellular Automata: Local Rules, Global Patterns
PROPOSED. Give a local rule a stored present and a separate next state, then inspect history, neighbourhoods, graded values and bodily inputs. Follow the actual artifacts rather than the historical hall names: ElementaryRules contains a three-state volume, GameOfLife a one-dimensional history bridge, and BeyondBinary a binary Life dish. Recursion is previewed by comparison and taught in the following sequence.

### CA_Introduction — Build the next row from the held row
At the held rule explorer, the student predicts the marked cell before pressing STEP and finds the same history overhead. Bringing lists, loops, conditions and Shaders' missing-memory question, they construct a row update that reads three old values, writes one next value, and swaps arrays only after every address is processed. The row display, controls and wrapped-ring receiver are supplied. They learn synchronous local updates and make the boundary rule explicit. The reusable result is a small cellular engine whose stored history can be displayed without confusing it with the current row.

**Short AI alternative**
Use held rule explorer and overhead history. Reuse lists, loops, conditions and Shaders' old/new-state contract. Teach reading three old values to write one next value; swap arrays after completing the row. Predict one cell; declare boundaries. Supply display, controls and wrapped-ring receiver. Carry synchronous engine with separate history. Open: choose readable rule table before bit encoding; rug symmetry is separate.

*For correction:* Choose a readable rule table before using bit encoding; the rug's symmetry is a separate operation.

### CA_ElementaryRules — Give a cell a fading state
The small volume and enlarged twenty-seven-position neighbourhood reveal active, fading and empty cells. Bringing synchronous updates and multidimensional addresses, the student constructs a three-state transition function, then traces one actual neighbourhood through a supplied counter. An active cell can cease participating while its fading state remains visible. The volume renderer, enlarged witness and twenty-six-neighbour enumerator are supplied with their contracts. They leave able to separate a state's persistence from its displayed colour and to reuse a transition table, while recognizing that rendered, occupied and active counts can answer different questions.

**Short AI alternative**
Use active/fading/empty volume and enlarged neighbourhood. Reuse synchronous updates and multidimensional addresses. Teach three-state transition table; trace one count through the supplied twenty-six-neighbour enumerator. Supply renderer and witness. Carry state transitions separate from colour; inactive fading cells can remain visible, so rendered, occupied and active counts differ. Follow the installed 3D study despite its historical title.

*For correction:* The historical title is misleading; this hall currently owns a three-state 3D study, not another introductory elementary-row lesson.

### CA_GameOfLife — Turn recorded time into a structure
The desk, stepping tiles and ornamental screen receive one Rule 30 history. Bringing the row engine, copied snapshots and state-to-colour mapping, the student copies each completed row into a retained history, then constructs two receivers: one arranges generations across a flat drawing, the other passes occupied entries to a supplied piece placement interface. The desk, collision tiles and screen geometry are supplied. They gain a reusable history-to-space mapping and compare zero as no mark with zero as no support. Selecting an earlier row changes attention without rerunning the automaton or altering its stored past.

**Short AI alternative**
Use Rule 30 desk, stepping tiles and screen. Reuse row engine, copied snapshots and colour mapping. Teach retained history with flat-image and piece-placement receivers; select earlier rows without rerunning. Supply desk, collision tiles, screen and placement interface. Carry history-to-space mapping; zero may mean no mark or no support. Open: learner connection remains proposed; actual Life follows in CA_BeyondBinary.

*For correction:* The current primary is a one-dimensional Rule 30 history; actual Life follows in CA_BeyondBinary. The learner receiver connection is proposed.

### CA_BeyondBinary — Let a fixed address control another object
At the Life dish, a glider crosses fixed gold addresses while lamps answer their occupancy. Bringing arrays, neighbour rules and explicit receivers, the student implements the small birth-and-survival decision from a supplied eight-neighbour count, then connects one retained cell reference to a lamp through a declared output function. The dish, floor image and lamp objects are supplied. They learn to distinguish a moving pattern from moving cells and leave with a usable simulation-to-object connection. The floor remains solid when its colour is empty, and the lamp sends no feedback into Life.

**Short AI alternative**
Use binary Life dish, fixed gold addresses and lamps. Reuse arrays, neighbour rules and receivers. Teach birth/survival from a supplied count with eight addresses explained; connect one fixed cell reference to lamp output. Supply dish, floor image and lamps. Carry state-to-object connection; patterns move across fixed cells, empty colour leaves solid floor, and lamps provide no feedback.

*For correction:* This installed study remains binary despite the map ID; keep the count helper explicit and introduce its eight addresses.

### CA_ExpandingSpace — Make the observing body an input
The bridge loses health near a probe or visitor, and its wall frieze shows the same values. Bringing synchronous arrays, distance and explicit outputs, the student constructs a local input function that turns a supplied position into a bounded health change at nearby cells. A separate neighbour rule restores health before colour and support read it. The player-position interface, bridge renderer and collision thresholds are supplied. They gain an input-update-output pattern and compare shared-old-state updates with in-place changes, discovering why scan order can alter the result before declaring the system responsive.

**Short AI alternative**
Use decaying bridge and matching frieze; choose probe for repeatability. Reuse synchronous arrays, distances and outputs. Teach bounded health changes near supplied positions; separate neighbour recovery from colour/support receivers. Compare shared-old-state and in-place updates to expose scan order. Supply position interface, bridge renderer and collision thresholds. Carry body-to-field input; keep player tracking supplied.

*For correction:* Use the probe for repeatable comparisons; no need to teach the entire player tracking system.

### CA_SoftRules — Exchange differences between neighbours
The matched concentration fields begin alike, but only one can pass its second substance across the seeded edge. Bringing graded state and synchronous buffers, the student constructs a small neighbour-difference sum and combines it with a supplied local reaction function. They track two concentration values at one witness before interpreting the resulting texture. The field displays, reaction function and one-time body-triggered seed are supplied. They learn how diffusion differs from counting occupied neighbours and carry a reusable two-field update, while the table and curved wall remain two receivers of the same state.

**Short AI alternative**
Use matched concentration fields. Reuse graded state and synchronous buffers. Teach neighbour-difference sums combined with supplied local reaction; track two concentrations at one witness before interpreting texture. Supply displays, Gray-Scott reaction and one-time body seed. Carry exchange separate from reaction; diffusion differs from occupied-neighbour counts. Table and curved wall share state. Defer reaction equations to Soft Bodies.

*For correction:* Gray–Scott equations are supplied here and deepened in Soft Bodies; current artifacts supersede the sequence's older primary list.

### CA_AgentsCircuits — Compare resemblance with procedure
The Rule 90 history makes triangular gaps that resemble the nearby Sierpinski pyramid. Bringing the row engine and its stored history, the student creates two short procedural accounts: how one cell is calculated, and how the supplied pyramid copies smaller pieces. They vary the explorer's seed while keeping the pyramid fixed, recording which resemblances survive. The explorer, enlarged floor history and pyramid are supplied. No circuit or new syntax is required. They carry a precise question into Fractals: what is repeated, what information each step needs, and when a shared appearance conceals different work.

**Short AI alternative**
Use Rule 90 history and Sierpinski pyramid. Reuse row engine and retained history. Describe cell calculation versus copying smaller pieces; vary the row seed while holding the pyramid fixed. Supply explorer, enlarged floor history and pyramid. Carry procedural questions into Fractals without new syntax. Preserve resemblance as inquiry; Wireworld is an older proposal, not an installed circuit.

*For correction:* Wireworld exists only as an older proposal here; do not teach an installed circuit that the current hall does not contain.

### CA_EdgeOfChaos — Follow one deliberate difference
The two volumes begin with a single altered address, which a selected slice can reveal or hide. Bringing multidimensional arrays, synchronous updates and matched comparisons, the student makes a paired-state experiment: copy a beginning, change one value, run the same update, and record both the largest difference and how many sites differ. The volume solver, slice displays and body-selected depth interface are supplied. They leave with a reusable perturbation study that distinguishes spread from magnitude. Integer storage and display gain become inspectable choices, without promoting an attractive image into proof of a universal critical point.

**Short AI alternative**
Use paired volumes and selected slices. Reuse arrays, synchronous updates and matched comparisons. Teach copied beginnings with one altered value; run identical updates and forcing schedules, recording maximum difference and differing-site count. Supply solver, slices and body-selected depth. Carry magnitude versus spread; inspect integer storage and display gain. Claim no universal critical threshold from the image.

*For correction:* The teaching comparison must use the same forcing schedule on both copies; no universal edge-of-chaos threshold is claimed.

## 14. Fractals: Rules, Scale and Room to Move
PROPOSED. Functions and loops already belong to the learner; self-calls and their stopping conditions are new. Develop repeated construction through branches, retained intervals, replacement segments and subdivided volumes. Use finite budgets honestly, then distinguish numerical recurrence from the geometry used to display it. The closing comparison prepares symbolic rewriting without pretending every recursive-looking artifact uses recursion.

### Fractal_Recursion — Let a function ask for a smaller task
At the nested-square desk and its floor-standing doorframes, the student asks for another term and encounters two different limits: depth and size. Bringing functions, scale and geometric construction, they write a small function that creates one square, then calls itself with reduced size and remaining depth. The line renderer, layout comparison and doorframe receiver are supplied. They can trace when each call stops and compare one descendant with several. The reusable outcome is bounded recursion, with its work budget distinguished from what an eye can resolve or a body can pass through.

**Short AI alternative**
Use nested-square desk and doorframes. Reuse functions, scale and geometry. Teach self-calls reducing size and remaining depth; trace base cases and compare one descendant with several. Supply lines, layout comparison and doorframe receiver. Carry bounded recursion; distinguish work budget, visual resolution and bodily clearance. Keep the actual square rule; branching rings may form a separate lesson.

*For correction:* Use the actual nested-square rule rather than an unrelated factorial example; branching rings can be a second short lesson.

### Fractal_RecursiveTrees — Pass a branch its starting state
The unfinished trunk gains children at its endpoint, and the enlarged canopy gives those connections bodily scale. Bringing bounded recursion, vectors and rotations, the student constructs a branch record with position, direction and length, then uses it to generate two child segments. The segment renderer, generation controls and canopy collision are supplied. They can change inherited length without changing branch count, or change descendants without merely widening the silhouette. They carry a reusable branching constructor, while comparing its recursive description with the installed tree's generation queue and keeping biological growth claims outside the rule.

**Short AI alternative**
Use unfinished trunk and enlarged canopy. Reuse bounded recursion, vectors and rotations. Teach branch records with position, direction and length; generate two children and vary inherited length separately from count. Supply segments, generation controls and collision. Carry explicit parent/child construction. Mark the recursive teaching version as proposed comparison: the installed tree uses a generation queue, without biological growth claims.

*For correction:* The installed growing tree evaluates a generation queue; label the recursive teaching version as a proposed comparison, not its exact implementation.

### Fractal_CantorSet — Keep intervals while removing their middles
At the stepped Cantor bars, the student sees more pieces but less retained length; the pagoda gives the gaps depth. Bringing lists, interval endpoints and bounded repetition, they construct the next interval list by keeping the first and last thirds of every current interval. They store the old rows separately so hiding history cannot remove more of the current set. The bar renderer, counters and collidable pagoda are supplied. The reusable outcome is a replacement operation with an explicit complement, and a finite construction that remains distinct from its mathematical limit.

**Short AI alternative**
Use stepped bars and pagoda. Reuse lists, endpoints and bounded repetition. Teach retaining first and last thirds into a new interval list; keep history separate. Compare increasing piece count with decreasing retained length. Supply bars, counters and collision. Carry finite replacement and complement; hiding old rows leaves the current set unchanged. Distinguish construction from limit. Open: endpoint pairs or centre/length records.

*For correction:* Choose whether endpoint pairs or centre-and-length records give the clearest continuity with earlier geometry.

### Fractal_KochSierpinski — Replace a segment with a detour
At the Koch desk, fixed endpoints enclose an increasingly long route; the Sierpinski study removes centres from faces. Bringing vector geometry, triangle corners and separate next lists, the student constructs one Koch replacement from a segment's endpoints, then applies it to every retained segment. The line renderer, step controls and comparison triangle are supplied. They measure endpoint distance separately from path length and carry a reusable geometry-replacement function. Sierpinski provides a second reading of replacement through midpoint faces; box-counting remains an optional measurement study rather than a prerequisite for making the curve.

**Short AI alternative**
Use Koch desk and Sierpinski comparison. Reuse vectors, triangle corners and separate next lists. Teach equilateral segment replacement across retained segments; measure endpoint distance separately from route length. Supply lines, steps and comparison triangle. Carry segment-to-segments transformation; inspect midpoint-face replacement separately. Defer optional box counting. Keep this rule distinct from the later five-segment right-angle L-system preset.

*For correction:* Keep the equilateral Koch rule distinct from the later L-system editor's five-segment right-angle preset.

### Fractal_MengerSponge — Make removal create a passage
The nine-metre cube first offers no entrance, then reveals intersecting openings. Bringing three-dimensional addresses, scale and recursive replacement, the student writes a selection rule over a three-by-three-by-three block that retains twenty cells, then repeats it for a bounded number of levels. The block renderer, collision bodies and flight enclosure are supplied. They keep the original bounds while computing the changing retained volume and inspect the removed cells as another subject. The reusable outcome is a volume-subdivision rule whose connected holes still need testing against the size and abilities of a visitor.

**Short AI alternative**
Use the cube's opening passages. Reuse 3D addresses, scale and recursive replacement. Teach retaining twenty cells from a 3-by-3-by-3 block across bounded levels; compute retained volume within fixed bounds and inspect the complement. Supply blocks, collision and flight enclosure. Carry subdivision; test holes against visitor size/abilities. Preserve the existing restriction on rebuilding while occupied.

*For correction:* Keep geometry changes outside an occupied structure; the current desk already restricts rebuilding while visitors inhabit it.

### Fractal_GoldenSpiral — Separate a recurrence from its drawing
The numbered towers grow by adding the previous pair, yet their displayed heights do not initially preserve those sums. Bringing arrays, accumulation and value mappings, the student makes a finite Fibonacci record and renders it with two explicit height functions, then checks a fixed-unit addition witness. The tower display, logarithm function and rectangle-cutting study are supplied. They gain a reusable distinction between numerical recurrence and geometric representation. The neighbouring rectangle and circular arcs leave room to ask which further choices produce a spiral, without treating resemblance in natural forms as evidence of one universal recipe.

**Short AI alternative**
Use numbered towers, addition witness and rectangle study. Reuse arrays, accumulation and mappings. Teach finite Fibonacci recurrence with two height mappings; compare displayed heights against fixed-unit sums. Supply tower display, logarithm input/output and rectangle construction. Carry numbers separate from representation. Ask what further choices create spiral arcs; claim no universal natural recipe. Defer optional logarithm derivation.

*For correction:* Do not introduce logarithms silently: supply their input-output mapping here, with a deeper derivation optional.

### Fractal_Synthesis — Describe what repeats without naming the form
At the Cantor desk and fixed block tree, the student explains one construction without using its title. They bring replacement functions, parent records and explicit stopping rules, then make a compact recipe stating the input, descendants, placement and budget. Another student, or their own later reading, should be able to predict the next step from that account. The interval display, tree and history controls are supplied. No new syntax is needed. They carry a precise description of repeated work into L-systems, while separating a change to the construction from merely hiding its record.

**Short AI alternative**
Use Cantor desk and fixed block tree. Reuse replacement functions, parent records and stopping rules. Describe input, descendants, placement and budget without naming the form; predict the next step. Supply intervals, tree and history controls. Carry a precise recipe into L-systems; hiding records differs from changing construction. Require no new syntax. Defer editable cross-procedure comparison as future work.

*For correction:* An editable cross-procedure comparison is future work; the current hall supports describing and reading existing constructions.

## 15. L-Systems: Rules Grow Structure
PROPOSED. Move from replacing geometry to rewriting symbols, then separate the sentence from the interpreter that gives it a body. Introduce an explicit stack for branching, develop footprints and conditional growth, and inspect the limits of parameter and shape vocabularies. Preserve the existing specimens; editable learner recipes and their transfer between the editor, turtle and construction studies remain proposed connections.

### LSystems_Grammar_Lab — Write a sentence before drawing it
The editor holds one drawing while the live version reads the same symbols with another turn angle. Bringing lists, traversal and geometric replacement, the student constructs one rewriting pass that reads an old string and appends each replacement to a new string. A supplied turtle interpreter draws the result, with its command meanings stated. The editor display and held witness are supplied. They can change a production separately from its interpretation and carry a usable symbolic generator, including the possibility that an undrawn symbol still participates in later rewriting.

**Short AI alternative**
Use held/live editor drawings. Reuse lists, traversal and geometric replacement. Teach one rewriting pass from old string to new; vary production separately from turn angle. Supply turtle with stated commands, display and witness. Carry symbolic generator and interpreter contract; undrawn symbols may rewrite later. Open: visitor-authored productions are not exposed; the learner-editable connection remains proposed.

*For correction:* Visitor-authored productions are not currently exposed; the learner-editable rule connection must be implemented after approval.

### LSystems_Growth — Save a state and return to it
The parametric tree steps through a bracket without drawing, then returns to an earlier position and length. Bringing rewriting, directions and copied snapshots, the student constructs a stack of turtle states: push saves a copy of position, orientation and length; pop restores it. Command dispatch for drawing and turning remains supplied, alongside the sentence and rendered stepping witness. They attach their save-and-restore functions to the bracket commands, gaining reusable branching state without rebuilding the whole interpreter. Branch nesting differs from rewriting generation, and returning restores only what the saved record contains.

**Short AI alternative**
Use parametric tree's bracket steps. Reuse rewriting, directions and copied snapshots. Teach a stack: push copies position, orientation and length; pop restores them. Supply sentence, stepping witness and ordinary draw/turn dispatch. Carry explicit branching state; nesting differs from rewriting generations, and restoration covers only saved fields. Open: learner bracket handlers' connection to the interpreter remains proposed.

*For correction:* Keep ordinary command dispatch supplied. The learner owns bracket handlers and copied state records; their connection to the existing interpreter is proposed.

### LSystems_Grammars_And_Curves — Change what forward means
The believing turtle keeps its gold heading while a blue reader draws sideways. Bringing the saved-state interpreter and transformations, the student writes a small interpretation function that converts the stored heading into a displacement, then compares direct and reflected readings of one sentence. The synchronized readers, arrow witnesses and tube-painting receiver are supplied. They gain a reusable interpreter variation while measuring what remains unchanged in segment lengths and connections. Turning the resulting trace into a tube can remain a later application; the unusual silhouette alone does not create different branch connectivity.

**Short AI alternative**
Use gold-heading turtle and sideways blue reader. Reuse saved state and transforms. Teach replaceable heading-to-displacement interpretation; compare direct/reflected readings of one sentence and check segment lengths/connectivity. Supply synchronized readers, arrows and tube receiver. Carry interpreter variation; changed silhouette need not change branching. Open: transferring learner trace into tube_painting is proposed; current controls change ring sides on supplied geometry.

*For correction:* Carrying the learner's trace into tube_painting is proposed; its installed lesson currently changes the ring side count on supplied geometry.

### LSystems_Architecture — Give a centreline a usable width
The dungeon begins as four pale centrelines, then BUILD raises a boundary a visitor can enter. Bringing turtle segments, offsets and collision distinctions, the student constructs a small footprint from a short orthogonal path, explicitly choosing corridor width and open ends. The wall builder, junction handling and collision assembly are supplied with their inputs stated. They can test whether a connected line becomes a usable passage for the prepared body. The reusable result is a path-to-footprint operation, while duplicate room records remain distinguishable from new physical rooms or meaningful uses.

**Short AI alternative**
Use dungeon centrelines and BUILD. Reuse turtle segments, offsets and collision distinctions. Teach an orthogonal path-to-footprint rule with stated width and open ends; test bodily passage. Supply wall builder, junction handling and collision with explicit inputs. Carry usable corridor footprints; duplicate room records need not create distinct rooms or uses. Defer arbitrary-angle joins and editable grammars.

*For correction:* Keep the first construction orthogonal; arbitrary-angle joining and new editable grammars are future work.

### LSystems_Competition — Let a shared resource condition a rule
The amber and blue stems share a grammar, but reversing their first turns reverses the initial advantage. Bringing state updates, rewriting and stored resources, the student makes a small scheduling experiment in which two growth requests consult and consume the same resource record. The forest kernel, soil display and specimen renderer are supplied. They record the state before each request rather than explaining unequal results through different branch instructions. The reusable outcome is an explicit rule for conditional execution and turn order, with a possible shared-snapshot comparison marked as a new experiment.

**Short AI alternative**
Use amber/blue stems sharing one grammar. Reuse rewriting, updates and resources. Teach two requests consulting/consuming one mutable record; record state before each and reverse turn order. Supply forest kernel, soil display and specimens. Carry conditional execution and explicit schedule; unequal outcomes need not mean unequal instructions. Open: shared-snapshot comparison is a new experiment; claim no ecological equilibrium.

*For correction:* Do not claim ecological equilibrium; simultaneous shared-snapshot consumption is proposed, not an existing control.

### LSystems_Living — Map a design record into a body
Beside the held tree, several small Depth changes leave the branch plan unchanged before one crosses a rounding threshold. Bringing parameter records, rewriting and numeric mappings, the student constructs an explicit conversion from a short design record into bounded generation, angle and fork values, then retains the record used by a planted specimen. The tree builder, held witness and local planting interface are supplied. They leave with a reproducible design description and can identify requested changes with no address in it. The data's name, DNA, does not make the construction a biological simulation.

**Short AI alternative**
Use held tree's Depth rounding steps. Reuse parameter records, rewriting and mappings. Teach bounded generation, angle and fork conversion; retain the design record for a planted specimen. Supply builder, witness and local planting interface. Carry reproducible design with visible vocabulary limits; DNA naming does not establish biology. Open: distinguish local specimens from DNA export; cross-hall transport remains proposed.

*For correction:* Keep local planted specimens distinct from DNA export; cross-hall transport of either requires a new connection.

### LSystems_Shape_Grammars — Choose which part an operation can address
The six cube specimens reveal how an old diagonal makes two triangles available to inset and extrude; the later strip canopy gives one face another scale. Bringing face lists, transformations and saved configurations, the student specifies a small operation sequence on selected face indices and predicts its resulting connections. The inset, extrusion and curved-strip builders are supplied with named inputs and outputs; the fixed specimens provide comparisons. They gain a reusable shape recipe, and can tell when a desired form needs a new operation rather than another amount on an existing control.

**Short AI alternative**
Use fixed cubes and strip canopy. Reuse face lists, transforms and saved configurations. Specify selected face indices and an inset/extrusion sequence; predict resulting connections and inspect the inherited diagonal. Supply builders with explicit inputs/outputs, including curved strips. Carry a shape recipe; some desired forms require new operations. Open: editable learner recipe and preview remain proposed.

*For correction:* The museum specimens are fixed. An editable learner recipe and preview are proposed, not existing controls.

### Assemblage_Same_Desire — Give a retained choice another alphabet
The textile keeps the same 144 samples while diagonals become bars and then blocks. Bringing retained draws, thresholds and the separation of sentence from interpreter, the student constructs two mark dictionaries for one binary decision list and compares the paths they see in each rendering. The textile display, held witness and full-size floor receiver are supplied. They leave with a reusable separation of sample, decision and mark. This closes the sequence without requiring new syntax: a route perceived in an image need not have been requested, checked or made collidable by its generator.

**Short AI alternative**
Use textile's retained 144 samples. Reuse draws, thresholds and interpreter separation. Teach two mark dictionaries for one binary decision list; compare apparent paths as diagonals become bars or blocks. Supply textile, witness and floor receiver. Carry sample/decision/mark separation without new syntax; perceived routes need not be checked or collidable. Open: sharing the earlier generator's record remains proposed.

*For correction:* A mark dictionary can use the learner's earlier two-mark generator; sharing its actual record across halls is proposed.

## 16. Procedural Generation: Rules Build Worlds
PROPOSED. Combine the already learned generators into scored selection, directed growth, connectivity, carving and sampling. Teach each new operation through a short construction with named supplied machinery. Do not assume the optional graph-theory branch was completed: any local search, adjacency list or traversal needed here must be introduced briefly or supplied explicitly, with full graph treatment reserved for the later spine sequence.

### PG_Genetic_Evolution — Make a criterion explicit before selecting
The six boxes keep their descriptions while TARGET changes which one leads. Bringing design records, lists and measurement, the student writes a small evaluator that turns a candidate description into a declared score, then ranks a retained population without rebuilding it. The primitive builder, displayed candidates and reproduction kernel are supplied. They learn that generation, representation and evaluation are separate operations and can inspect which features their criterion ignores. The reusable outcome is an explicit selection procedure, while the held numerical leader need not be the body the student personally wanted to keep.

**Short AI alternative**
Use six boxes under changing TARGET. Reuse design records, lists and measurement. Teach explicit candidate scoring and ranking without rebuilding the population; inspect ignored features and compare the leader with personal preference. Supply primitive builder, display and reproduction kernel. Carry generation/evaluation separation. Use the approximate estimator honestly; exact union volume and learner-selected witness retention are not installed.

*For correction:* Use the current approximate estimator honestly; exact union volume and learner-selected witness retention are not installed capabilities.

### PG_Space_Colonization — Combine requests into a growth direction
Three attraction points ask the root to grow, and their sideways contributions cancel in its first proposed step. Bringing vector subtraction, normalization and branch records, the student constructs a direction accumulator from a supplied list of assigned points, then adds a fixed-length child segment. The attraction display, nearest-site assignment and segment renderer are supplied. They gain a reusable way to combine unit directions, while comparing which sites remain eligible to respond in later generations. These points are consulted coordinates, so the resulting growth should not be described as simulated forces or light-seeking biology.

**Short AI alternative**
Use three attraction points and cancelling sideways requests. Reuse vector operations and branch records. Teach summing assigned unit directions into a fixed-length child step; compare later site eligibility. Supply attraction display, nearest-site assignment and segment renderer. Carry a request-driven branch rule; consulted coordinates are not simulated forces or light-seeking biology. Defer nearest-site search to a separate follow-up.

*For correction:* Nearest-site assignment is supplied initially; its search can be a separate short follow-up.

### PG_Branching_Growth — Choose one request and keep its provenance
The branch leans towards its nearest attraction point instead of combining every invitation. Bringing the previous direction accumulator and distance comparisons, the student constructs a nearest-eligible-point search, retains the chosen point's index, and makes one fixed-length child step. The attraction layout, branch renderer and stepped clock are supplied. Recording both parent and target lets them explain coincident children before adding jitter or a pulsing length. They carry a reusable selection-and-growth operation, distinguishing the number of records from the number of distinct positions visible in the resulting structure.

**Short AI alternative**
Use nearest-attraction branching. Reuse direction accumulation and distance comparisons. Teach nearest-eligible search; retain parent and target index before making a fixed-length step. Supply attraction layout, renderer and stepped clock. Carry growth provenance; explain coincident children before jitter or pulsing, distinguishing record count from distinct positions. Open: shared attraction concepts exist, but transferring the learner's record remains proposed.

*For correction:* Shared attraction data across the two halls is conceptually established; transferring the learner's own record remains proposed.

### PG_Percolation_Network — Declare which contacts transmit
Two cubes touch at a face, then at a corner; only one arrangement passes flow in the study's rule. Bringing grid neighbours, occupancy and synchronous updates, the student constructs a six-neighbour transmission step for a small retained volume. They keep random occupancy generation separate from flow state so the same lattice can be tested from another source. The cube display, source fixture and stepping controls are supplied. They carry a reusable local propagation operation and understand that a visible contact, a permitted adjacency and a globally reachable path are different claims.

**Short AI alternative**
Use face-touching versus corner-touching cubes. Reuse grid neighbours, occupancy and synchronous updates. Teach six-neighbour transmission with flow state separate from random occupancy; retest the retained lattice from another source. Supply cube display, source and stepping. Carry local propagation; distinguish visible contact, permitted adjacency and global reachability. Infer no universal threshold from one finite seeded lattice.

*For correction:* Do not infer a universal percolation threshold from one finite seeded lattice.

### PG_Caves_Mazes — Carve enough room around a route
The cave's gold dots identify carving centres, while the neighbouring maze reveals a different route-making procedure. Bringing the random walk, grid addresses and occupancy, the student makes a carving function that clears a stated footprint and headroom around each retained centre. The cave renderer, collision builder and maze backtracking demonstration are supplied. They can keep the same centres while changing clearance and inspect what the record omitted. The reusable outcome is a path-to-empty-volume operation; separate walkers' dots must not be joined into a fictitious continuous trail, and an opening still needs a bodily test.

**Short AI alternative**
Use cave carving dots and maze comparison. Reuse walks, grid addresses and occupancy. Teach clearing footprint and headroom around retained centres; vary clearance, then test bodily access. Supply cave renderer, collision builder and backtracking demonstration. Carry path-to-empty-volume construction; never join separate walkers' dots into a fictitious trail. Defer optional maze implementation; introduce visited record and stack if chosen.

*For correction:* A full backtracking maze implementation is optional; if selected later, introduce its visited record and stack explicitly.

### PG_Sculpted_Forms — Make a surface from a chosen sample
Twelve falling cubes become a frozen centre record and then a blocky surface. Bringing coordinate frames, voxel addresses and mesh faces, the student makes a small sampler that converts body centres into the artifact's local frame, marks a declared neighbourhood, and submits exposed faces to a supplied mesh assembler. The falling bodies, sampling control and collision builder are supplied. They carry an event-to-surface pipeline whose omissions are visible: rotation and exact contact shapes were not recorded. The dome's cutting cores remain a comparison that prepares later Boolean work, rather than an unexplained prerequisite.

**Short AI alternative**
Use falling cubes becoming a frozen blocky surface. Reuse frames, voxel addresses and faces. Teach local-frame centre sampling, declared neighbourhood marking and exposed-face submission. Supply bodies, sampling control, mesh assembler and collision. Carry event-to-surface reconstruction with actual enlarged dimensions; rotation and contact shapes are omitted. Keep dome cuts as comparison; defer Boolean machinery.

*For correction:* The existing neighbourhood enlarges each cube substantially; teach its actual dimensions, not an exact reconstruction claim.

### PG_Mirrored_Patterns — Copy an image and inspect a connection
The held cellular field acquires symmetry while the neighbouring network changes its connection policy. Bringing array addresses, transformations and retained inputs, the student constructs a reflection operator that reads one region and writes a separate result, then checks centre rows and columns explicitly. The field display, network comparison and tunnel surfaces are supplied. They leave with a reusable copying operation and two distinct accounts of repetition: repeated values in an image and repeated access between sites. The network remains an observation model, and formal graph measures can wait for their later sequence.

**Short AI alternative**
Use mirrored cellular field and network comparison. Reuse array addresses, transforms and retained inputs. Teach reading one region into a separate reflected result; check centre rows/columns. Supply field, network, tunnel surfaces and graph statistics. Carry explicit reflection boundaries; repeated image values differ from repeated access. Network collision is disabled. Defer formal graph measures; do not claim traversability.

*For correction:* Do not treat the current rhizomatic specimen as traversable; its collision is disabled. Supply graph statistics without assuming earlier graph coursework.

## 17. Soft Bodies & Morphogenesis: Matter That Finds Its Shape
PROPOSED. Reuse mesh connectivity, forces, state and constraints to distinguish a deformable body from an animated surface. Give the learner small constructions around supplied solvers: a mesh attachment, a pin selection, a driven boundary, a measured response and a frozen snapshot. Return to Gray–Scott with reaction and exchange separated. Isosurface extraction and Boolean operations come later in the spine, so their machinery stays supplied here.

### SoftBodies_Soft_Body_Deformation — Give a connected mesh to a solver
The pinned jelly cube yields while retaining its face connections. Bringing meshes, forces and physical bodies, the student connects a supplied subdivided mesh to a soft-body solver, retains the body reference and pins one selected point. They compare resistance, damping and pressure by following the same deformation rather than treating all three as softness. The mesh generator, Godot solver and hand-contact rig are supplied. They leave with a reusable deformable-body setup and a precise account of its attachment, while recognizing that a tracked hand can displace the skin without being pushed back itself.

**Short AI alternative**
Use pinned jelly cube. Reuse mesh connectivity, forces and bodies. Teach attaching supplied subdivided mesh to solver, retaining its reference and pinning one point; compare resistance, damping and pressure on one deformation. Supply mesh generator, solver and hand-contact rig. Carry explicit deformable attachment; tracked hands need not receive reaction. Open: choose understandable vertex selection, not an unexplained index.

*For correction:* Choose a reliable point-selection interface; do not bury mesh vertex selection behind an unexplained index.

### SoftBodies_Cloth_Physics — Choose the boundary that must stay
The hanging strips remain suspended when their gantry disappears, exposing a pin rule independent of visible support. Bringing mesh coordinates, conditions and the soft-body setup, the student constructs a vertex-selection function for an upper edge, then another for its corners, and applies the selected pins to a supplied open sheet. The cloth mesh, solver and support display are supplied. They gain a reusable boundary-condition recipe and can explain why an open surface has no enclosed volume to inflate. The tension membrane extends the comparison to a load acting between retained anchors.

**Short AI alternative**
Use hanging strips and tension membrane. Reuse coordinates, conditions and soft-body setup. Teach vertex-selection functions for upper edge versus corners on a supplied open sheet. Supply cloth, solver and support display; use known generated coordinates. Carry boundary-condition recipe; disappearing gantry does not remove pins, and an open surface encloses no inflatable volume. Compare loads between retained anchors.

*For correction:* The learner's reduced sheet should use known generated coordinates; keep decorative gantry changes separate from actual attachment.

### SoftBodies_Carusell — Drive an attachment while matter responds
At the revolving ride, the support stops commanding new angles while the hanging bodies continue moving. Bringing rotations, time steps and pinned or jointed constraints, the student writes a small driven-anchor rule with a rate in radians per second, then supplies that anchor to an existing hanging-body assembly. The hub, hinge connections and soft-body solver are supplied. They can stop or reverse the driver while retaining the body's state, gaining a reusable distinction between prescribed motion and simulated response. The attachment's one-way authority remains explicit: the hanging body cannot change the commanded hub rotation.

**Short AI alternative**
Use revolving ride. Reuse rotations, time steps and constraints. Teach an anchor driver in radians per second; stop or reverse it while retaining hanging-body state. Supply hub, hinges and solver. Carry prescribed motion versus simulated response; bodies cannot alter commanded hub rotation. Open: the reduced anchor connection remains proposed, with one-way authority explicit.

*For correction:* The reduced anchor connection is proposed; do not imply the driven hub receives reaction forces from the hanging bodies.

### SoftBodies_Obsticals — Use a wave as a force input
The breathing room's wall edges stay fixed while their centres respond to periodic pressure. Bringing sine, scalar receivers and pinned boundaries, the student constructs a pressure-driver function and connects its output to a supplied deformable panel. They hold the driver phase and observe that the solver can still settle under the retained pressure. The wall mesh, soft-body solver and museum support are supplied. They carry a reusable signal-to-force connection, distinguish it from directly displacing vertices, and test how a changing enclosure affects the clearance available to the prepared body.

**Short AI alternative**
Use breathing room's fixed wall edges. Reuse sine, scalar receivers and pinned boundaries. Teach a bounded panel's pressure driver; hold phase while the solver settles, then inspect bodily clearance. Supply wall mesh, solver and support. Carry signal-to-force input separate from solver state and direct vertex displacement. Open: connecting the learner's driver to both full walls needs an adapter.

*For correction:* Keep the first teaching panel bounded and inspectable; extending the learner's driver to both full walls needs an explicit adapter.

### SoftBodies_Obsticals_Part2 — Construct a comparison that earns its name
The twelve falling-body cells vary material, shape and contact in different combinations. Bringing solver settings, collision geometry and repeatable setup recipes, the student assembles a two-case comparison description that names every shared condition and one intended difference, using the High Drag case as an existing example. The gallery bodies, reset controls and physical solver are supplied. They record an observable consequence such as settling duration instead of relying on the case name. The reusable outcome is a controlled experiment recipe, with a seeded construction distinguished from a guarantee of identical physics across machines.

**Short AI alternative**
Use twelve falling-body cells and High Drag example. Reuse settings, collision geometry and repeatable setups. Teach a two-case comparison naming shared conditions and one changed factor; record a concrete consequence. Supply bodies, reset, solver and measurement support. Carry controlled experiment record; seeded construction does not guarantee identical cross-machine physics. Open: choose observable and supplied recorder.

*For correction:* Choose a concrete observable and a supplied way to record it; avoid making measurement infrastructure the lesson.

### SoftBodies_Playground_of_Joy — Keep a result and name what was measured
The rounded body's volume display can feed back into pressure, while the glass vessel freezes a solver after a chosen step budget. Bringing retained positions, measurements and physical state, the student makes a snapshot operation that copies a supplied solver's current vertices into a static mesh while preserving face connections. The solver, vertex-reading interface and mesh assembler are supplied. They leave with a reusable process-to-sculpture operation and compare its loss of motion with the live instrument's bounding-box proxy. Freezing a closed surface does not cut the opening its vessel-like appearance may suggest.

**Short AI alternative**
Use volume-feedback body and frozen glass vessel. Reuse retained positions, faces and physical measurements. Teach copying current solver vertices into a static mesh with unchanged connectivity. Supply custom vessel solver's readable positions and mesh assembler; do not assume identical Godot access. Carry snapshot and conditions; compare lost motion with bounding-box volume proxy. Freezing closed geometry creates no opening.

*For correction:* Select the custom vessel solver's readable positions; do not assume Godot's soft-body vertices expose the identical interface.

### SoftBodies_Affect_Theory_Visualization — Keep recognition beside the recipe
The radiolaria row suggests shells, pollen and organisms before its six construction recipes are explained. Bringing primitives, seeded populations and shader effects, the student chooses two forms and makes an account of which cues produce that recognition, then tests one cue while retaining the construction seed. The geometric families, rotation controls and particle effects are supplied. No new syntax is required. They carry a more deliberate vocabulary for composing apparent life, while keeping a body's resemblance, its available interaction and the mechanism generating it as separate questions that may remain artistically unresolved.

**Short AI alternative**
Use radiolaria row. Reuse primitives, seeded populations and effects. Compare two forms' recognition cues; vary one while retaining the construction seed. Supply geometric families, rotation and particles. Carry deliberate apparent-life composition without new syntax; resemblance, interaction and mechanism remain separate, potentially unresolved questions. COLOUR rebuilds geometry, so pin a seed before treating it as palette-only.

*For correction:* COLOUR rebuilds geometry in this artifact; pin a seed before using it as a palette-only comparison.

### ProceduralGeneration_Reaction_Diffusion_Systems — Separate reaction from exchange
A seeded patch changes across the held concentration grid, returning to the exchange study from Cellular Automata. Bringing two-field buffers, neighbour differences and small time steps, the student now constructs the local Gray–Scott reaction, feed and removal terms, then combines them with the known diffusion operation. The grid display, bounded stepping controls and initial field are supplied. They can hold one beginning while comparing update rules, or hold a rule while changing its seed pattern. The reusable outcome is a complete small field simulation, without claiming these are Turing's original equations or a biological organism.

**Short AI alternative**
Use held concentration grid. Reuse CA_SoftRules' two-field buffers, neighbour differences and time steps. Teach Gray-Scott reaction, feed and removal terms; combine with known diffusion. Supply display, stable stepping and initial field. Compare one beginning across rules or one rule across seeds. Carry complete update with separate contributions. Defer numerical limits; claim neither Turing's original equations nor an organism.

*For correction:* CA_SoftRules supplies the reaction function first; this hall opens it. Use supplied stable step settings before exploring numerical limits.

### Topology_Entropy_Morphogenesis — Expose the choices behind one gesture
The folded field surface changes several ways when S moves, while NOISE, LEVEL and RESOLUTION reveal separate interventions. Bringing sine fields, thresholds and composed mappings, the student makes an explicit control function that returns named frequency, noise and cut-level values instead of an unexplained master amount. The sampled-field generator, surface extractor and collision builder are supplied. They can compare one bundled gesture with independent choices and carry a reusable, inspectable control recipe. The source name entropy is not a measured distribution, and a visible opening remains a question of geometry and bodily clearance.

**Short AI alternative**
Use folded field with S, NOISE, LEVEL and RESOLUTION. Reuse sine fields, thresholds and mappings. Teach explicit control returning named frequency, noise and cut-level values; compare bundled gesture with independent choices. Supply field generator, surface extractor and collision. Carry inspectable controls; entropy is a source name, not a measurement, and openings need clearance tests. Defer extraction to Isosurfaces.

*For correction:* Surface extraction is supplied here because Isosurfaces follows at order 18; do not assume marching cubes was already taught.

## 18. Isosurfaces: Implicit to Explicit
The student turns sampled fields into boundaries, learns to compose their descriptions and finishes by testing what those boundaries let a body do. Extraction stays supplied where it would hide the meaningful construction; spatial recipes, ordered edits and comparisons become the learner's reusable work.

### ISO_Introduction — Choose where a boundary appears
The student approaches the blue specimen until its pink triangle edges become visible. Bringing sampled fields and mesh faces, they would retain scalar samples and write a separate function classifying them against a chosen level. The supplied extractor receives the original samples and level, preserving magnitudes for locating crossings. Holding one result, they would change the level before changing sample spacing. The display and collider builder remain supplied. They learn to separate the field, selected boundary and finite approximation, carrying a reusable field-to-surface experiment into the local cube cases.

**Short AI alternative**
Use blue specimen's pink triangle edges. Reuse sampled fields and faces. Teach a separate level-classification function; retain scalar magnitudes for extraction. Hold a comparison; change level before sample spacing. Distinguish field, boundary and finite approximation. Supply extractor, display and collider builder. Carry retained samples and comparison. Open: study host; one cell or small volume.

*For correction:* Choose the prepared study host and whether the first exercise exposes one cell or a small volume.

### ISO_LookupTable — Place a crossing before making a face
At the marked corners of the fifteen-case display, the student chooses an edge whose values lie on opposite sides of the level. Reusing interpolation and threshold classification, they would calculate its crossing position and draw a marker there. Changing the two values without changing their classifications moves that marker while retaining the local connection pattern. The corner cage, case table and triangle display are supplied. This introduces the separate jobs of classification and interpolation; the resulting edge-crossing function can serve every later sampled shape.

**Short AI alternative**
Use fifteen-case display. Reuse classification and interpolation; calculate and mark one crossing edge. Change values without changing classifications; observe crossing motion with unchanged connections. Supply corner cage, case table and triangle display. Carry reusable edge-crossing function. Defer bit-mask construction to another short lesson if it obscures interpolation.

*For correction:* Keep bit-mask construction as a second short lesson if it obscures the crossing calculation.

### ISO_ShapesGallery — Describe a cup with fields
The chair and cup invite the student to find a joined part and a hollow before reading their recipes. Bringing field functions and extraction, they would compose supplied box, cylinder and ring fields into a small vessel beside the existing gallery, keeping one inner volume removable. The extractor, comparison display and primitive field functions are supplied with position-in, value-out contracts. They learn that changing a description differs from changing its sampling or level. Their reusable vessel expression becomes material for periodic surfaces and later Boolean composition.

**Short AI alternative**
Use chair joins and cup hollow. Reuse field functions and extraction; compose supplied box, cylinder and ring fields into a vessel with removable interior. State position-in, value-out contracts. Distinguish recipe changes from sampling or level. Supply primitive fields, extractor and comparison display. Carry vessel expression. Open: whole cup recipe or hollow first.

*For correction:* Decide whether the learner begins with the cup's whole recipe or first constructs only its hollow.

### ISO_TorusGyroid — Follow a repeating surface
The student follows a torus opening, then a gyroid fold that continues beyond any apparent piece. Bringing periodic functions and field composition, they would change the coordinate scale of a supplied gyroid expression and preserve a comparison before adding one local intrusion. The expression, extractor and straight capsule probe are supplied. They learn how repeating a rule in space differs from copying separate objects, then compare a visible opening with the probe's limited clearance result. A controlled spatial frequency becomes another tool for making passages.

**Short AI alternative**
Use torus opening and continuous gyroid fold. Reuse periodic functions and field composition; change coordinate scale, retain comparison, then add one intrusion. Teach spatial repetition versus copied objects; opening versus clearance. Supply gyroid expression, extractor and straight capsule probe. Carry controlled spatial frequency. Open: walking alongside the probe's single-segment test.

*For correction:* The probe tests one straight segment; decide how much actual walking belongs beside that restricted comparison.

### ISO_Sculpting — Keep the order of a gesture
At the framed sculpting volume, the student watches two deposits join before placing a brush contribution of their own. Reusing lists, positions and field functions, they would record each contribution with its position, size and add-or-erase operation, then evaluate a short history in order. Input capture, brush field and extraction are supplied. Reversing two operations reveals that erasing is not undoing and that history changes the body. They carry an editable sequence of spatial operations toward terrain, retaining the limits of sampling and stored history.

**Short AI alternative**
Use joining deposits in sculpting volume. Reuse lists, positions and fields; record brush position, size and add-or-erase operation. Evaluate history in order; reverse two operations. Teach erase versus undo and history-dependent form. Supply input, brush field and extractor. Carry editable spatial history. Open: history limit and what happens when reached; retain sampling limits.

*For correction:* Choose a short history limit for the teaching study and expose what happens when that limit is reached.

### ISO_FlatTerrain — Make room below the height
A marked vertical column first meets the terrain once, then meets a folded surface more than once. Bringing noise, coordinate functions and level extraction, the student would begin with height minus vertical position and add a supplied interior contribution. The column sampler, noise source and extractor are supplied; the learner owns how the two fields combine. They learn why one height per horizontal address cannot describe every overhang or enclosure. Their composed volume carries onward to openings made by several local tendencies acting together.

**Short AI alternative**
Use column crossing terrain once, then folded surface repeatedly. Reuse noise and coordinate functions; combine height minus vertical position with supplied interior field. Teach height field versus volume and multiple crossings. Supply column sampler, noise source and extractor. Carry terrain with an interior. Treat second terrain as contrasting composition, not a matched one-parameter control.

*For correction:* Keep the second terrain as a contrasting composition, not a matched one-parameter control.

### ISO_PortalLandscape — Compose an opening
Beside the amber landscape and its held copy, the student chooses a ridge to preserve while seeking an opening beneath it. Bringing the terrain field, they would add one supplied, spatially masked contribution at a time and describe where it can act. Sampling, extraction and the held-copy display are supplied. The lesson is a purposeful composition of fields: the learner predicts a region of change, then inspects the result from above and below. A visible opening becomes a question about an actual route in the cave hall.

**Short AI alternative**
Use amber landscape and held copy; preserve a ridge while seeking an opening. Reuse terrain fields and weighted sums. Add masked contributions individually; predict affected regions and inspect above and below. Supply contributions, sampling, extractor and comparison. Carry an explainable opening recipe toward route testing. Open: first two terms; defer full five-term ladder.

*For correction:* Choose two useful terms for the first construction; the full five-term ladder can remain a later return.

### ISO_Caves — Find the enclosing side
The student walks the portal landscape's edge before looking back from an accessible cave opening. Bringing field boundaries, transforms and collision, they would alter the burial of one supplied ring field while preserving its size, then trace where it meets the ground. The terrain recipe, extractor and player remain supplied. This deepens the difference between a hole, an entrance and a usable route; the neighbouring cave is a comparison, not a duplicate recipe. The student carries an explicit entrance condition into their own cave study.

**Short AI alternative**
Use landscape edge and accessible cave opening. Reuse field boundaries, transforms and collision; vary burial of a supplied ring without resizing it. Trace ground intersections. Teach hole versus entrance versus usable route. Supply terrain recipe, extractor and player. Carry entrance conditions and bodily clearance. Open: accessible comparison location; neighbouring cave uses another recipe.

*For correction:* Choose an accessible comparison location before promising a route through either specimen.

### ISO_CaveGeneration — Give noise a spatial scale
The generated cave stands beside a striped tunnel built from rings. Bringing noise, sampling and enclosure, the student would prepare two cave fields with the same domain and level but different coordinate scales, predicting which passages or ridges will change. The noise evaluator, extractor and paired display are supplied. They learn that a noise setting gains physical scale through its relation to the sampled domain, while a similar-looking tunnel may use another construction altogether. They carry a reproducible field recipe into the study of changing fields.

**Short AI alternative**
Use generated cave beside ring-built tunnel. Reuse noise, sampling and enclosure; compare coordinate scales with domain and level fixed. Predict changed passages or ridges. Teach noise's physical scale and distinct cave constructions. Supply noise evaluator, extractor and paired display. Carry reproducible recipe. Supply controlled study: existing specimens change several settings together.

*For correction:* The existing specimens change several settings together; the proposed paired study must supply the controlled comparison.

### ISO_AnimatedNoise — Keep an address while the image changes
The student watches one block-sized address fill and empty, then tries following an apparent traveller through the same display. Bringing grid addresses and time-dependent functions, they would retain a short history of occupancy at a chosen cell while a supplied noise sampler changes its offset. The grid display and clock are supplied. Their small recorder distinguishes changing values at fixed locations from persistent particles moving between them. That distinction carries into later animated fields without claiming that this block display already extracts a moving triangle surface.

**Short AI alternative**
Use one block address filling and emptying. Reuse grid addresses and time-dependent functions; record occupancy while noise offset changes. Teach fixed-location values versus persistent moving particles. Supply noise sampler, grid display and clock. Carry a history tied to an address. Use occupancy artifact as source; older mesh-animation tutorial describes another construction.

*For correction:* Choose the occupancy display as the teaching source; the older tutorial describes a different mesh animation.

### ISO_Metaballs — Sum influences before drawing bodies
A narrow neck joins two lobes before their source centres touch. Reusing lists, distance and accumulation, the student would write the loop that sums supplied falloff contributions at a sample position, then arrange the same sources into a pair and a ring. The falloff functions, extractor and held-copy display are supplied. They learn that one boundary can arise from several overlapping influences, and separate changing source positions from changing their reach. Their source list and sum become a reusable field description for comparing surface representations.

**Short AI alternative**
Use neck joining lobes before centres touch. Reuse distance, lists and accumulation; sum supplied falloffs at each sample. Arrange sources as pair and ring; distinguish source position, reach and visible lobe. Supply falloffs, extractor and held-copy display. Carry source list and summed field. Open: one finite, well-behaved kernel; retain others for comparison.

*For correction:* Choose one finite, well-behaved falloff first; the other kernels remain comparative material.

### ISO_ImplicitModeling — Let one description meet two renderers
The student circles a smooth join and notices that its convincing surface offers no matching bodily resistance. Bringing distance fields and extracted meshes, they would compose a two-part field and send the same description to supplied mesh and raymarch views in a prepared comparison. Rendering, normal estimation and collision construction are supplied separately. They learn that a rule for space can produce different representations, each with its own affordances. The field remains theirs to alter; the next hall asks what more is required when that description must contain a visitor.

**Short AI alternative**
Use smooth join without matching bodily resistance. Reuse distance fields and extracted meshes; compose one two-part field for proposed mesh and raymarch comparison. Teach field versus representation and rendering versus collision. Supply views, normal estimation and separate collider builder. Carry one editable description. Current hall partly relies on remembered specimens; paired study remains proposed.

*For correction:* This paired use of the same field is proposed; the current hall's comparison relies partly on remembered earlier specimens.

### ISO_RhizomeBody — Draw the route you could walk
The student enters the rhizome body and tries to return to a junction through another passage. Bringing generated surfaces and bodily clearance, they would sketch the junctions and connections actually encountered, marking where a promised connection could not be established. The chamber generator, shell extraction and player are supplied. They then propose narrowing one passage and predict which drawn connection would remain while access changes. This is a reflective synthesis of construction and encounter, carrying the distinction between a planned relation and an inhabitable passage into Boolean architecture.

**Short AI alternative**
Use a walk through rhizome body and attempted alternate return. Reuse surfaces and clearance; sketch encountered junctions, passages and unconfirmed connections. Predict how narrowing changes access while a drawn edge remains. Supply chamber generator, shell extraction and player. Carry route sketch distinguishing planned relations from usable passages. Open: paper or project record; no existing recorder assumed.

*For correction:* Decide whether the route sketch stays on paper or becomes a small in-project record; do not invent an existing map recorder.

## 19. Boolean Surfaces: CSG as Composition
Three operations become a vocabulary for making forms, comparing their authored alternatives and carving space at bodily scale. The final construction keeps the pleasures of hollows and dark interiors alongside the practical question of what a visitor can enter, see and leave.

### Boolean_Verbs — Choose what a solid keeps
The recurring box and sphere let the student look for a vanished seam, a shared remainder and a new cavity wall. Bringing composed fields and meshes, they would build one supplied pair of CSG operands and select union, intersection or ordered subtraction while holding their transforms fixed. The prepared display and collision comparison are supplied. They learn the set operations through what survives, including an empty intersection, then reverse subtraction. The reusable two-operand construction gives the gallery's authored variants a vocabulary without treating its differently sized exhibits as controlled experiments.

**Short AI alternative**
Use box-and-sphere seam, remainder and cavity. Reuse fields, meshes and transforms; compare union, intersection and ordered subtraction with operands fixed. Include empty intersection; reverse subtraction. Supply CSG pair, display and collision comparison. Carry reusable two-operand construction. Existing differently sized exhibits are not controlled comparisons. Open: closing bench or prepared study host.

*For correction:* Choose whether the small construction lives beside the closing bench or in a prepared study scene.

### Boolean_Gallery — Author a sequence of alternatives
The student crosses a row of four variants, then walks the same row in an order that tells a different story. Bringing CSG operations and lists, they would make a short ordered collection of one family's configurations, choosing which version arrives first and whether its operands remain visible. The artifact factory and display stands are supplied. They learn to distinguish a parameter that changes geometry from a presentation that explains it. Their authored comparison travels onward as a way to make a construction legible without assuming the default is its only possible form.

**Short AI alternative**
Use four variants in two walking orders. Reuse CSG and lists; order configurations from one family and choose when operands remain visible. Teach geometry changes versus explanatory presentation and authored defaults. Supply artifact factory and stands. Carry a deliberate comparison. Keep existing ordering disagreements as material; no registry repair.

*For correction:* Keep the existing gallery's ordering disagreements available as material; avoid turning this into registry repair.

### Boolean_Works — Make a cut that can be inhabited
The student enters the level-floor burrow, compares the raised cavern, then looks into an egg whose dark material hides a real concavity. Bringing Boolean operations, transforms and collision, they would compose a small room around a shared cutter and adjust its position to make a deliberate opening. The wall construction, player and material comparison are supplied. They test entry, withdrawal and sightline before changing the cavity's lighting response. The gain is an inhabitable composition whose geometry, contact and appearance can be changed separately, carrying those choices into later bodies.

**Short AI alternative**
Use burrow, raised cavern and dark concave egg. Reuse Boolean operations, transforms and collision; position a shared cutter to open a small room. Test entry, withdrawal and sightline. Then change the same cavity's depth cues. Supply walls, player and material comparison. Carry separate choices about geometry, contact and appearance. Keep two short lessons.

*For correction:* This hall deserves two short lessons: carve a usable opening, then change how the same cavity presents depth.

## 20. Swarm Intelligence: Where Coordination Lives
Coordination is rebuilt through shared trails, supplied directions, neighbours, state changes and remembered objectives. Each construction identifies where information lives and what support it needs; the closing ecosystem leaves room to ask how an apparently autonomous population is maintained.

### SwarmIntelligence_PhysarumColony — Let movement leave a usable memory
The student follows a bright trail that persists after the agents making it have passed. Bringing grids, fields and movement, they would give a small supplied agent population three trail samples to compare, then deposit a value where each agent moves. The agent renderer, diffusion step and fixed anchors are supplied. They learn how a shared record can steer later actions without residing in one agent, then compare two decay choices. This environmental memory carries onward as one particular mechanism of coordination, not evidence that the simulation proves biological optimality.

**Short AI alternative**
Use trails persisting after agents pass. Reuse grids, fields and movement; compare three trail samples and deposit at each new position. Compare decay choices. Teach shared environmental memory without claiming biological optimality. Supply small repeatable population, renderer, diffusion and fixed anchors. Carry readable trail memory. Defer automatic anchor tour.

*For correction:* Choose a small repeatable population and fixed anchors before studying the existing automatic anchor tour.

### SwarmIntelligence_FlowFields — Write the direction an agent will find
At the visible arrows, the student predicts an agent's next turn and checks another agent reaching that place later. Bringing grid lookup and steering, they would author a small vector field that curls around one region and guides agents through another. The agent display and steering integrator are supplied; the learner writes the direction returned for each address. They learn that coordinated motion can follow supplied infrastructure without agents consulting each other. That field-versus-neighbour distinction prepares the next flock, while goal-cost construction remains an optional later study.

**Short AI alternative**
Use arrows to predict agents' turns at one address. Reuse grid lookup and steering; author directions that curl around one region and guide through another. Teach shared infrastructure versus neighbour consultation. Supply agent display and steering integrator. Carry purposeful vector field into flocking. Defer obstacle routing and cost propagation to a separate lesson.

*For correction:* Choose a direct field construction first; the exhibit's obstacle route-finding would require a separate cost-propagation lesson.

### SwarmIntelligence_Boids_Algorithm — Let neighbours become the reference
The student follows the yellow-ringed boid's three arrows, then watches which neighbours disappear when it crosses the small box's boundary. Bringing steering and lists of moving positions, they would compute separation, mean heading and mean position for a small neighbourhood, combining the results deliberately. The boid renderer, update loop and boundary policy are supplied. They learn that both neighbour selection and weighting shape the flock, and compare alignment with room or body avoidance that the rule does not provide. Local relationships become reusable agent behaviour for the next hall.

**Short AI alternative**
Use ringed boid's arrows and neighbours lost across box boundary. Reuse steering and position lists; compute separation, mean heading and mean position, then weight them. Teach neighbour selection and flocking limits: alignment supplies neither room nor body avoidance. Supply renderer, update loop and boundary policy. Carry local behaviour. Open: split selection from force combination.

*For correction:* Split neighbour selection from force combination if the three-rule construction becomes too large.

### SwarmIntelligence_Agent_Based_Modeling_ABM — Separate travellers from their traces
The student replaces the colony's agents and sees old trails remain, then resets and watches both population and field begin again. Bringing state records and trail updates, they would give a small agent two named states with different sensing and depositing actions. The movement loop, field display and repeatable starting arrangement are supplied. They learn that individual state and shared history can change independently, testing the same evaporation rule under both kinds of restart. The state transition becomes the tool for explaining outward and returning travellers in the next colony.

**Short AI alternative**
Use agent replacement retaining trails, then full reset. Reuse state records and fields; give a foraging agent two states with different sensing and deposition. Compare the same evaporation under both restarts. Teach individual state versus shared history. Supply movement loop, field display and repeatable start. Carry explicit transitions into outward and returning travel.

*For correction:* Use the hall's foraging states rather than introducing a generic society simulator.

### SwarmIntelligence_Ant_Colony_Optimization — Give a trail two directions of meaning
The student follows an outward ant towards food and a returning ant towards home, noticing that they seek and leave different traces. Bringing agent states and shared fields, they would add separate home and food channels to the previous small colony, switching which channel is read and written on arrival. Destination detection, movement and the two-colour display are supplied. They learn how changing state changes the meaning of the same act of deposition. This usable communication mechanism travels toward remembered scores without being presented as a demonstrated shortest-tour solver.

**Short AI alternative**
Use outward and returning ants' different traces. Reuse states and fields; add home and food channels to the small colony. Switch read and write channels on arrival. Teach state-dependent communication and deposition. Supply destination detection, movement and two-colour display. Carry two-channel foraging; do not claim demonstrated shortest-tour optimisation.

*For correction:* The map name suggests optimisation; keep the teaching claim to demonstrated two-channel foraging.

### SwarmIntelligence_Particle_Swarm_Optimization — Remember a place and the rule that scored it
The student switches CONVERGE to SPREAD while the same particles keep moving, then repeats from the same beginning. Bringing state, vectors and scores, they would store each particle's best position separately from its score and combine motion towards personal and shared remembered positions. The repeatable population, landscape and motion display are supplied. They learn that changing the objective requires reconsidering what counts as best, especially when a novelty archive changes. A named objective and accountable memory become prerequisites for the machine-learning sequence rather than a claim that one landscape models a politics.

**Short AI alternative**
Use CONVERGE/SPREAD and repeated starts. Reuse state, vectors and scores; store best position separately from score. Combine motion toward personal and shared memories. Teach objective-dependent best; reconsider memory when objective changes. Supply repeatable population, landscape and motion display. Carry candidate with scoring rule. Teach fixed objective first; defer changing novelty archive to second comparison.

*For correction:* Teach a fixed objective first; novelty's changing archive needs an explicit second comparison.

### SwarmIntelligence_Swarm_Intelligence_Algorithms — Notice what keeps a population going
The student follows one feeding or birth event, then checks the population count and its record of support. Bringing agent state and event histories, they would compose a small account that keeps local births and losses distinct from population-level replenishment, using the supplied ecosystem and event feed. The display and organisms remain supplied. This is a reflective synthesis: the learner explains one recovery only as far as the recorded events allow, then names what is still unknown. They carry visible support and inherited traits into evolution without treating continued activity as proof of autonomy.

**Short AI alternative**
Use feeding or birth, population count and support record. Reuse events and histories; distinguish local births and losses from replenishment. Explain one recovery within recorded evidence; name unknowns. Supply ecosystem, event feed and display. Carry enabling interventions toward evolution; continued activity does not prove autonomy. Open: construct an account or annotate existing support record.

*For correction:* Decide whether students construct the account from a supplied event stream or annotate the existing support record.

## 21. Machine Learning: What Changes, and Why?
The student makes candidate descriptions, scores and updates, then examines what gets retained as a learned state. Small working models accompany clustering, perception and memory; the staged generative encounter stays honest about its limits. The sequence ends with an unusual case that a score can flag but cannot explain away.

### ML_Evolution — Decide what gets another generation
The student compares drifting bodies that reproduce through energy conditions with creatures selected by a declared score. Bringing agent state, inheritance and randomness, they would encode a small movement recipe as a list, copy it with bounded mutations and choose a stated selection rule. The creature body, trial arena and generation display are supplied. They learn to separate variation, evaluation and replacement, retaining a comparison with survival conditions that have no final target. Their explicit candidate-and-score construction prepares optimisation without making simulated reproduction stand for all biological evolution.

**Short AI alternative**
Use energy-conditioned reproduction beside scored creatures. Reuse agent state, inheritance and randomness; encode movement as a list, copy with bounded mutation and choose selection rule. Teach variation, evaluation and replacement separately from untargeted survival conditions. Supply body, trial arena and generation display. Carry explicit candidates and scores. Open: small recipe with observable short-trial consequence.

*For correction:* Choose a small movement recipe that produces an observable consequence within one short trial.

### ML_Gradient_Landscape — Write what downhill means
The student follows three points fitting the same observations under different error measures. Bringing functions and numerical scores, they would make a straight-line predictor, sum one chosen loss over a supplied sample, and estimate its local slope by comparing nearby parameter values. The observation set and landscape renderer are supplied. A short update moves opposite that estimated slope; a second loss changes what improvement means. They learn that the surface is an authored evaluation of candidate parameters, carrying prediction, loss and update as separate operations into later learning.

**Short AI alternative**
Use points fitting identical observations under different losses. Reuse functions and scores; build line predictor, sum one loss and estimate slope from nearby parameter values. Update against slope; compare another loss. Teach prediction, evaluation and update separately. Supply observations and landscape renderer. Carry inspectable descent. Begin with one parameter; defer slope-and-intercept landscape.

*For correction:* Keep the first descent to one adjustable parameter before extending the landscape to slope and intercept.

### ML_Classification — Move a centre without moving the points
At the stepped k-means display, the student chooses a stationary point that changes colour when a centre moves. Bringing distance, lists and averages, they would alternate nearest-centre assignment with recomputing each centre from its assigned positions. The point cloud and coloured display are supplied, with an explicit rule for an empty group. They learn that these groups are constructed by the chosen representation and procedure, rather than discovered labels supplied by an authority. Their small clustering loop carries forward a concrete example of adjustable model state.

**Short AI alternative**
Use stationary point recoloured as centres move. Reuse distance, lists and averages; alternate nearest-centre assignment with centre updates. Teach constructed clustering versus supplied class labels. Supply point cloud, colours and empty-group policy. Carry adjustable clustering loop. Open: dataset small enough for one hand-calculated update; keep supervised classifiers secondary.

*For correction:* Choose a dataset small enough to calculate one update by hand; supervised classifiers remain secondary encounters.

### ML_Neural_Networks — Change a connection that changes an answer
The student watches activity pass through a connection and asks what remains after that signal has gone. Bringing weighted sums, function composition and loss, they would build a tiny two-layer forward calculation from retained weight lists, then trace one weight's change and its effect on the next prediction. The sample set, network drawing and training-step calculation are supplied and explained at their interfaces. They learn to distinguish activations from learned state, comparing a held-out example with training error. A working forward model becomes material for inspecting what its inputs actually contain.

**Short AI alternative**
Use passing activity and retained connections. Reuse weighted sums, composition and loss; build two-layer forward calculation from weight lists. Trace one changed weight into prediction; compare held-out result with training error. Teach activations versus weights and fitting versus generalisation. Supply samples, drawing and explained training-step interface. Carry forward model. Supply repeatable host; exhibit controls cannot restart training.

*For correction:* Provide a repeatable teaching host; the current exhibit's finite training run cannot be restarted from its hall controls.

### ML_Perception — Construct a local question for an image
The student follows the moving window from a uniform patch to the edge of a cross or disk. Bringing nested lists and weighted sums, they would apply a small supplied Sobel kernel to one pixel neighbourhood, then traverse the image to build an edge-strength map. The input image, boundary policy and paired image display are supplied. They learn exactly which local intensity differences the operation preserves, and identify an edge fragment compatible with several objects. That interpretable intermediate representation travels onward without being mistaken for an object recognition result.

**Short AI alternative**
Use moving window crossing uniform patch and shape edge. Reuse nested lists and weighted sums; apply supplied Sobel kernel locally, then traverse image for edge strengths. Teach intensity differences versus object interpretation; find an ambiguous fragment. Supply image, boundary policy and paired display. Carry interpretable feature operation. Keep fixed detection distinct from learned CNN recognition.

*For correction:* Keep fixed edge detection distinct from the neighbouring CNN display's claims about learned recognition.

### ML_Sequence_Memory — Choose what survives another input
The student carries pale and dark tokens through the cell, watching a slab retain part of its earlier height. Bringing state updates and weighted sums, they would write the simplified memory recurrence, separating the retained contribution from the admitted input and the exposed output. Token input, gate handles and slab display are supplied. Comparing two histories with the same last token makes the role of accumulated state visible. They learn a usable gated memory operation while keeping the hand-set linear teaching cell distinct from a trained LSTM.

**Short AI alternative**
Use tokens and slab retaining earlier height. Reuse state updates and weighted sums; write linear gated recurrence separating retained state, admitted input and exposed output. Compare histories sharing the last token. Supply token input, attainable gate handles and slab display. Carry inspectable memory. State hand-set simplification; trained LSTM requires further operations.

*For correction:* Use attainable gate values and state the linear simplification; a trained LSTM needs additional operations.

### ML_Generative — Make a candidate and inspect its judge
The student traces the exchange between generator and discriminator, recognising that the displayed losses are scripted. Bringing random inputs, forward models and explicit losses, they would make a small candidate generator in a prepared study and compare its outputs with supplied reference samples using a fixed, inspectable critic. Sampling, the comparison display and critic are supplied. They learn to separate producing candidates from learning how to produce them, then specify which two states would need updating for an adversarial loop. The critic's reference set remains a choice carried into the final classification question.

**Short AI alternative**
Use generator/discriminator exchange with scripted losses. Reuse random inputs, forward models and losses; propose small candidate generator judged against reference samples by fixed critic. Teach generation versus training; name both states needing adversarial updates. Supply samples, comparison display and inspectable critic. Carry explicit evaluator and reference choice. Open: later real alternating training.

*For correction:* Decide whether a later second lesson supplies real alternating training; the museum animation alone cannot demonstrate it.

### ML_Synthesis — Keep an unusual point available
The student finds a raised point and asks why its neighbour remains low. Bringing data summaries and thresholds, they would calculate the hall's score from a supplied point sample, retaining each coordinate's contribution before comparing the total with a chosen threshold. The display and zero-spread convention are supplied. They learn how the reference population, scaling and decision rule together produce a flag, then keep one flagged case for further inquiry instead of discarding it. This synthesis carries a habit of naming a representation's omissions into graph relations.

**Short AI alternative**
Use raised point beside low neighbour. Reuse data summaries and thresholds; calculate score, retain coordinate contributions and compare total with threshold. Teach reference population, scaling and decision rule versus judgement. Supply sample, display and zero-spread convention. Carry flagged case for inquiry, preserving omissions. Open: change reference sample or only threshold first.

*For correction:* Confirm whether students change the reference sample or only the threshold in the first study.

## 22. Graph Theory: What Connections Permit
Lists become relations that survive changes of drawing. The student builds traversal, routes, counts, return groups, a spanning tree and revisable allocations, always stating the question each procedure answers. The final matching makes an accepted local choice available for reconsideration before the route turns to formal limits.

### GT_Foundations — Keep the connections, change the visit order
The student follows the tide and the diver across the same lamps, keeping one waiting destination in view. Bringing lists and retained state, they would describe a small graph as named vertices and neighbour lists, then make a pending-work list choose either its oldest or newest entry. The lamp display and step control are supplied. They learn breadth-first and depth-first traversal through a deliberate change in ordering, while the graph remains fixed. Their connection record becomes the durable structure underneath drawings, routes and later assembly bodies.

**Short AI alternative**
Use tide and diver visiting the same lamps. Reuse lists and state; introduce vertex identifiers and neighbour lists. Select oldest or newest pending entry to teach breadth-first versus depth-first traversal on a fixed graph. Supply lamps and step control. Carry connection record independent of visiting order. Defer bridge problem to optional application.

*For correction:* Introduce vertex identifiers before traversal; keep the bridge problem as a separate optional application.

### GT_Layout — Move the drawing while keeping the graph
As the cube-like network settles, the student follows one edge by its endpoints instead of calling it left or above. Bringing graph records and spring forces, they would give each vertex a position and velocity, apply attraction only along its listed edges and use supplied repulsion for spacing. The edge renderer and integrator are supplied. They learn to separate a graph's connections from one arrangement that makes them visible, then compose another readable layout. That distinction protects later claims about routes and importance from changes in presentation.

**Short AI alternative**
Use settling network; identify edges by endpoints. Reuse adjacency and spring forces; retain vertex positions and velocities, attracting only along edges. Compose another readable layout. Teach topology versus drawing. Supply repulsion, edge renderer and integrator. Carry unchanged connections across layouts. Keep graph small enough to check every relation; defer efficient layout algorithms.

*For correction:* Keep the graph small enough that every relation can be checked before discussing efficient layout algorithms.

### GT_Pathfinding — Rebuild a route after a stone goes
The student predicts the spark's next crossing, removes a stone and watches another route replace the first. Bringing graph traversal, they would retain each newly reached vertex's predecessor, then reconstruct a path by walking those references backwards. The stone graph, availability input and traveller display are supplied. They learn that a route is a result of search, not the search itself, and handle a case with no available connection. The reusable path record carries into network questions without requiring three search algorithms in one room.

**Short AI alternative**
Use spark's replacement route after a stone disappears. Reuse traversal and references; store predecessors during unweighted breadth-first search, then reconstruct backwards. Teach search versus resulting path; handle unreachable destination. Supply stone graph, availability input and traveller display. Carry route record and explicit no-route result. Defer weighted costs and A*.

*For correction:* Use unweighted breadth-first search first; weighted costs and A* can be a later extension.

### GT_Network_Analysis — Make a relation answer to a record
The student compares a conspicuous vertex with its actual connections, then turns to the fictional evidence network. Bringing edge lists and counting, they would record a small set of directed relations with source labels and compute incoming and outgoing counts from those records. The curved-line renderer and layout controls are supplied. Removing one relation changes the count; moving the drawing does not. They learn one precise measure of connection while keeping provenance available, carrying that discipline into directed reachability instead of treating a central-looking point as inherently important.

**Short AI alternative**
Use conspicuous vertex and fictional evidence network. Reuse edge lists and counting; record directed, source-labelled relations and count incoming/outgoing edges. Remove a relation, then move the drawing; distinguish changed counts from presentation. Supply curved-line renderer and layout controls. Carry traceable measures without equating prominence with importance. Open: filtering before or after first count.

*For correction:* Use invented records; choose whether relation filtering precedes or follows the first count calculation.

### GT_Connectivity — Ask for a way back
At the directed display, the student traces a route to another vertex and searches for a return before trusting the component colour. Bringing adjacency and traversal, they would compute the vertices reachable from a chosen start in both the original and reversed graph, keeping their intersection. The arrow display and small graph are supplied. They learn mutual reachability through a manageable construction, then compare their group with the supplied Tarjan traversal. The resulting component means that routes exist; it leaves their cost and bodily accessibility open for later choices.

**Short AI alternative**
Use directed routes and attempted returns before trusting colours. Reuse adjacency and traversal; intersect reachability from one start in original and reversed graphs. Teach mutual reachability; compare with supplied Tarjan traversal. Supply small graph and arrows. Carry checked component; leave route cost and bodily access open. Defer Tarjan's low-link invariant.

*For correction:* Prefer the two-reachability construction first; teaching Tarjan's low-link invariant can be a separate deeper lesson.

### GT_Spanning_Trees — Choose which extra route to give up
The student predicts whether a yellow candidate edge joins separate groups or closes a cycle. Bringing weighted relations and reachability, they would sort a small edge list and accept a candidate only when its endpoints are not already connected. The graph display and step control are supplied; ordinary traversal can answer the first cycle checks. They learn how a minimum spanning tree follows a stated objective, then restore one rejected edge for an explicitly chosen alternative route. This carries the difference between economical connection and resilience into constrained flow.

**Short AI alternative**
Use yellow candidate joining groups or closing a cycle. Reuse weighted edges and reachability; sort edges, accepting only disconnected endpoints. Use traversal for cycle checks. Restore one rejected edge for a stated alternative route. Supply display and stepping. Carry objective-based tree and deliberate redundancy. Defer union-find until repeated reachability becomes useful.

*For correction:* Introduce union-find only if repeated reachability becomes the next useful problem; the first construction can remain small.

### GT_Flow — Give a junction somewhere to send its excess
The student watches a junction accumulate excess and predicts whether its next action will push or relabel. Bringing directed graphs and state updates, they would implement one push between two vertices, limited by available excess and residual capacity, including the reverse adjustment that permits revision. The network, height-selection rule and stepped display are supplied. They learn to distinguish capacity, assigned flow, excess and algorithmic height through an operation they can calculate. A small rerouting example carries the power to undo an early allocation into matching.

**Short AI alternative**
Use junction excess and push/relabel choice. Reuse directed graphs and state; implement one push bounded by excess and residual capacity, including reverse adjustment. Teach capacity, flow, excess and algorithmic height separately. Supply network, height-selection rule and stepped display. Carry revisable allocation into matching. Open: example requiring rerouting; current animation may not expose it.

*For correction:* Select a supplied example that actually requires rerouting; the present animation alone may not expose it.

### GT_Matching — Undo one pair to make room for two
The student watches a valid pair leave two outer points waiting, then compares the same graph with spokes considered first. Bringing graph edges and occupied-state checks, they would write the greedy pairing loop and construct a short alternating path that replaces one selected edge with two. The ring-and-spokes graph and stepped display are supplied. They learn why local validity and a maximum number of pairs are different claims, without pretending the exhibit runs a complete blossom algorithm. This capacity to revise an acceptable answer prepares the foundations crisis.

**Short AI alternative**
Use valid pair leaving outer points waiting; compare spokes-first order. Reuse edges and occupancy checks; write greedy pairing and replace one edge with two along an explicit augmenting path. Teach validity versus maximum size. Supply ring-and-spokes graph and stepping. Carry revisable pairing. Defer weighted assignment, preferences and full blossom contraction; exhibit does not implement blossom.

*For correction:* Choose one explicit augmenting path; weighted assignment, preference and full blossom contraction are separate subjects.

## 23. Foundations Crisis: The Limits of Formalization
Construction becomes a way to examine the grounds of a claim. The student compares geometric assumptions, bounded collections, proof checking, visual closure, unfinished choices and conflicting reports. These encounters remain distinct; their limits do not prove the project's formula, but give the next laboratory better questions to answer.

### Euclid_Parallel — Name the assumption beneath a construction
The student reads the fifth postulate beside the parallel lines and triangle, noticing that the room's flat coordinates already provide a setting. Bringing point, line and angle constructions, they would make one triangle and state which construction rules and distance convention it uses before checking its corners. The existing plaque, line display and angle readout are supplied. This reflective return separates an assumption, a generated example and a general proof. The triangle travels onward as a construction to revisit under a different geometric model, not as a machine for proving an axiom.

**Short AI alternative**
Use fifth postulate, parallel lines and triangle in flat coordinates. Reuse points, lines and angles; name construction rules and distance convention before checking corners. Distinguish assumption, example and proof. Supply plaque, lines and angle readout. Carry triangle for another model. Open: construct in prepared study or document existing triangle; neither proves an axiom.

*For correction:* Decide whether the learner constructs the triangle in a prepared study or documents the existing one's assumptions.

### NonEuclidean_Spaces — Let the model define a straight route
At the curvature workbench, the student compares the same triangle task on plane, sphere and disk, predicting each angle sum before reading it. Bringing coordinates and angles, they would supply endpoints to three provided geodesic samplers and display the returned paths, then measure corner directions using the supplied model-aware routine. The geometric samplers and angle routine are explicitly supplied. They learn that a straight route belongs to a distance model, not simply to its picture in the room. The comparison carries a habit of naming the rules that make a construction meaningful.

**Short AI alternative**
Use plane, sphere and disk triangles; predict angle sums. Reuse coordinates and angles; pass endpoints to geodesic samplers, display paths and measure corners with model-aware routine. Teach model-dependent straightness versus room projection. Supply samplers, angle routine and display. Carry explicitly different geometric rules. Do not substitute a warped Euclidean grid.

*For correction:* Do not teach a warped Euclidean grid as a replacement for these geometry-specific constructions.

### Russell_Paradox — Try the rule on its own collection
The student chooses IN and OUT at the workbench and follows why each contradicts the proposed membership rule. Bringing Boolean conditions and list filtering, they would write the two-case check, then filter a supplied finite collection whose domain is stated before applying the condition. The membership examples and workbench display are supplied. They learn the difference between testing a condition over available objects and assuming that every description creates a set. The finite construction offers a useful alternative while the contradiction prepares a separate question about what proof systems can establish.

**Short AI alternative**
Use IN/OUT contradictions at membership workbench. Reuse Boolean conditions and filtering; write two-case check, then filter a supplied finite domain. Teach testing available objects versus assuming every description creates a set. Supply examples and display. Carry membership with explicit domain into proof questions. Restricted construction does not implement arbitrary set theory.

*For correction:* The finite alternative illustrates restricted construction; it must not claim to implement arbitrary set theory.

### Godel_Incompleteness — Separate a stopped search from a limit
The student watches the sentence machine jam, then asks what its stopped arm has established. Bringing lists, functions and the previous contradiction, they would inspect a supplied finite proof candidate step by step and compare that check with a bounded search that finds none. The small rule system, candidate checker and machine remain supplied. This reflective lesson distinguishes a failed search from a reason no proof can exist, while a carefully scoped account introduces incompleteness. The student carries that distinction into impossible images without making the sculpture a demonstration of Gödel's theorem.

**Short AI alternative**
Use jammed sentence machine as a question about evidence. Reuse functions, lists and contradiction; inspect finite proof candidate, then compare bounded unsuccessful search. Teach checking versus searching and failure versus impossibility. Supply tiny rule system, checker and machine. Carry scoped proof claims. Open: formal example and careful incompleteness account; sculpture is no theorem demonstration.

*For correction:* Choose a tiny formal example that clarifies checking and search without pretending to construct Gödel's sentence in a few lines.

### Escher_Impossible — Measure the return that the image conceals
The student follows the staircase marker and predicts where its apparent ascent must be returned. Bringing coordinate differences and closed paths, they would record the height change between successive tread centres and sum a complete circuit, then inspect the same object from another viewpoint. Tread references, the marker and comparison sculptures are supplied. They learn to separate what a projection invites them to see from the geometry actually constructed, while retaining the pleasure of the impossible image. The closed-loop check travels into the question of what it means to construct an asserted object.

**Short AI alternative**
Use staircase marker's apparent ascent. Reuse coordinate differences and closed paths; sum height changes between tread centres around full circuit. Change viewpoint. Teach projection versus constructed geometry while preserving impossible image's pleasure. Supply treads, marker and comparison sculptures. Carry whole-circuit check. Open: another small construction; do not treat staircase as incompleteness proof.

*For correction:* Choose whether a second small impossible-looking construction is useful; do not present the staircase as an incompleteness proof.

### Brouwer_Intuitionism — Leave the next term unmade
The student waits at the empty next position, then chooses a zero or one and sees the row grow only through that decision. Bringing ordered lists and search, they would retain their own prefix and make a query that returns a position witnessing a one when one has been chosen. The choice controls and bead display are supplied. They learn to separate evidence about a finite construction from a claim about every possible continuation. The unfinished row carries a constructive question onward without declaring that a missing witness proves a negation.

**Short AI alternative**
Use empty next position and chosen binary beads. Reuse lists and search; retain own prefix and query for a position witnessing one. Teach finite evidence versus every possible continuation; missing witness does not establish negation. Supply choice controls and display. Carry unfinished construction. Keep introduction distinct from blanket rejection of proof by contradiction.

*For correction:* Keep the mathematical introduction distinct from the old tutorial's incorrect blanket rejection of proof by contradiction.

### Florensky_Paraconsistent — Keep two reports and inspect what follows
The student adds OPEN and CLOSED at the same doorway while the unrelated alarm remains without support. Bringing state records and conditions, they would retain two source-tagged reports independently and query each without overwriting the other. The ghost-door display and a small declared consequence table are supplied. They learn that preserving contradictory information and choosing inference rules are different operations, testing whether an unrelated conclusion has any support. The reflective comparison with Florensky remains available without equating overlapping meshes, quantum superposition and a complete paraconsistent logic.

**Short AI alternative**
Use OPEN/CLOSED doorway reports and unsupported alarm. Reuse records and conditions; retain source-tagged reports independently and query both. Teach conflict storage versus inference and support versus truth. Supply ghost doors and declared consequence table; test unrelated conclusion. Carry sources and permitted consequences. Open: minimal table and scope; Florensky reflection supplies neither quantum superposition nor general logic.

*For correction:* Choose a minimal consequence table and state its scope; the existing storage demonstration does not supply a general logic.

### Crisis_Synthesis — Give one sentence another public form
The student meets the formula after the sequence's unsettled claims, then follows one sentence across label, moving strip and wall. Bringing strings, lists and timed display, they would write a short statement and give it three presentations through the supplied sentence apparatus, comparing what scale and rhythm invite them to accept. The typography, projection surfaces and controls are supplied. This reflective composition distinguishes an argument's force from its warrant. They carry a question for the QFEP laboratory: which quantities and relationships would make this project's proposed formula accountable?

**Short AI alternative**
Use formula and sentence across label, strip and wall. Reuse strings, lists and timed display; give one original statement three presentations. Compare scale and rhythm with evidential warrant. Supply sentence apparatus, typography, surfaces and controls. Carry accountability questions into QFEP. Open: sentence tied to learner's construction; formula remains a research proposal.

*For correction:* Choose an original sentence tied to something the learner has made; the formula remains a research proposal.

## 24. QFEP Laboratory: The Formula Made Interactive
The project formula becomes material for calculable, revisable experiments. The learner preserves contributions hidden by totals, builds a predictor and a branching possibility structure, distinguishes a change from its weighting, and gives a supplied body an explicit response. QFEP's ethical inquiry stays open to these encounters without being reduced to their scores.

### QFEP_Introduction — Keep what one total forgets
The student keeps one four-axis arrangement, then finds another with nearly the same total. Bringing functions and records, they would implement the workbench's short arithmetic and retain its separate inputs alongside the result, including the supplied constant change value. Controls, reference display and kept-outline renderer are supplied. They learn how weights create dependencies and how compensating contributions disappear into a scalar summary. This introduces Ada's QFEP as a revisable project proposal; their explicit calculation and preserved record travel onward to experiments that ask what is actually measured.

**Short AI alternative**
Use different four-axis arrangements with similar totals. Reuse functions and records; implement arithmetic while retaining inputs, including constant change, beside result. Teach weights, dependencies and scalar compression. Supply controls, reference display and kept outline. Carry revisable QFEP calculation and evidence questions. Open: formula's introductory scope; authored reference names confer no evidential support.

*For correction:* Keep authored reference names outside the calculation's evidential claims; decide how much of the formula to introduce before the experiment.

### QFEP_F_Term — Change the predictor before changing the world
At the bit workbench, the student compares equally uncertain sources with opposite dominant bits, then changes EXPECT 0 to EXPECT 1 without changing the displayed sample. Bringing loops and error scores, they would write a constant predictor and count its mistakes over a retained bit list. The seeded source, binary entropy calculation and bit display are supplied. They learn to distinguish source uncertainty, realised mistakes and expected error, improving the predictor rather than editing away inconvenient observations. That precise distinction travels onward without naming this elementary score a measurement of variational free energy.

**Short AI alternative**
Use opposite dominant bits with equal uncertainty; switch predictor on unchanged sample. Reuse loops and scores; count constant predictor's mistakes over retained bits. Teach uncertainty, realised mistakes and expected error separately. Supply seeded source, binary entropy and display. Carry revisable predictor with fixed evidence. Open: derive or supply expected error; no variational-free-energy measurement claim.

*For correction:* Decide whether expected error is derived here or supplied initially beside the counted mistakes.

### QFEP_E_Term — Construct the possibilities you will count
The student follows two leaves back to their shared branch, then watches an early closure remove several possible endings. Bringing trees and recursion, they would describe a small branching choice structure and write a leaf counter, retaining which branch was closed. The fan renderer and equal-weight logarithm calculation are supplied. They learn what outcome counting includes, what equal probabilities assume and why a reopened diagram does not recover an actual lost history. Their own tree can then add a previously undrawn alternative, carrying revision beyond the supplied menu of choices.

**Short AI alternative**
Use shared branch and closure removing endings. Reuse trees and recursion; author branching choices, count leaves and retain closed branch. Add an undrawn alternative. Supply fan renderer and equal-weight logarithm. Teach probability assumptions; reopening diagram cannot recover lost history. Carry revisable possibility structure. Open: useful example; more leaves imply no moral conclusion.

*For correction:* Choose a useful learner-authored branching example; avoid treating a larger leaf count as a moral conclusion.

### QFEP_Lambda_Spectrum — Move the recommendation and keep the room
The student finds a dependable interval on the ordered side and a surprising relation among the moving forms, before shifting the lit strip. Bringing spatial composition, they would author a different recommended route while leaving the surrounding geometry visible, then test where that invitation meets an obstruction or another useful possibility. The spectrum's forms, lighting control and player are supplied. This reflective composition teaches how a display can recommend a value without measuring a universal regime. The student carries the difference between a weighting, an invitation and a body's available route into change over time.

**Short AI alternative**
Use ordered interval, moving forms and shifted lit strip. Reuse spatial composition and weights; propose another recommendation, keeping geometry visible. Test obstruction and alternatives. Supply forms, lighting control and player. Teach weighting, invitation and available route versus universal measurement. Carry tested recommendation. Open: change strip only or also author second viable route.

*For correction:* Decide whether the first proposal changes only the lit strip or also authors a second viable route.

### QFEP_Phi_Term — Name the change before weighting it
The student moves the signed rail across zero, then notices the nearby pattern continuing independently. Bringing retained samples and arithmetic, they would calculate a difference between two supplied entropy readings, keep the interval beside it and optionally divide to obtain a rate. The readings, time display and signed rail are supplied. Multiplying the same change by opposite weights reveals what the sign does to a stated calculation. They learn to distinguish change, rate, weight and receiver, carrying these distinctions onward without assigning a political attitude to a slider direction.

**Short AI alternative**
Use signed rail crossing zero beside independent pattern. Reuse samples and arithmetic; subtract entropy readings, retain interval and optionally calculate rate. Compare opposite weights. Teach change, rate, weight and receiver; avoid political meaning from direction. Supply readings, time display and rail. Carry weighted change with intended use. Open: reading source, never decorative pattern.

*For correction:* Choose the source of the paired entropy readings; they must not be inferred from the independent decorative pattern.

### QFEP_Edge_Of_Chaos — Ask whether the pattern survives another step size
At the paired screens, the student chooses a feature to follow while both fields start alike and run for the same simulated duration. Bringing grid updates and time stepping, they would arrange a comparison between one update interval and a smaller one, using the supplied Gray–Scott update and common initial state. The reaction-diffusion model and displays are supplied. They learn to separate changing model parameters from changing numerical execution, preserving a pattern only as far as the comparison supports it. The authored lambda route remains an experimental choice, carried into accountable control.

**Short AI alternative**
Use paired patterns over equal simulated duration. Reuse grid updates and time stepping; track chosen feature at two update intervals. Distinguish model parameters from numerical execution. Supply Gray-Scott update, common initial state and displays. Carry recorded comparison conditions. Open: intervals and stopping rule showing meaningful difference; lambda remains authored choice, not universal edge band.

*For correction:* Choose an interval pair and equal-time stopping rule that show a meaningful difference without implying a universal edge band.

### QFEP_Sandbox — Build another response to a control
The student moves a handle while its route is cut, then connects it and watches the reactor use the present value. Bringing function inputs and retained state, they would connect the same supplied control to a small receiver of their own, such as a light whose intensity follows an explicit mapping, then interrupt and restore that connection. Handle input, light body and connection indicator are supplied. They learn to design a parameter's consequence rather than merely repeat its display, carrying an understandable input-to-response relation into the final specimen.

**Short AI alternative**
Use cut connection, moving handle and reactor receiving restored present value. Reuse function inputs and state; map control to a small receiver, then interrupt and restore connection. Teach receiver mapping versus held input. Supply handle, light body and connection indicator. Carry rewritable consequence. Open: fully inspectable receiver; retain reactor comparison.

*For correction:* Choose a useful receiver the learner can inspect completely; retain the existing reactor as a comparison.

### QFEP_Synthesis — Give a body a response worth keeping
The student stops the specimen's imposed pressure pulse and watches which motion continues, then compares resisting deformation with losing motion. Bringing forces, constraints and explicit control mappings, they would choose a response for a supplied soft body and map their controls to stiffness and damping separately, keeping a short deformation trace. The body solver, pressure source and trace display are supplied. They learn to state which mechanical property changed and which response they observed. The resulting body is an authored experiment that carries a question about its remaining permissions into post-crisis making.

**Short AI alternative**
Use stopped pressure pulse and continuing motion. Reuse forces, constraints and mappings; propose separate stiffness and damping controls, retaining deformation trace. Teach resisting deformation versus losing motion; drive versus response. Supply soft-body solver, pressure source and trace display. Carry mechanical intention, observed response and questions about remaining permissions. Expose existing lambda/phi coupling across coefficients when proposing teaching mapping.

*For correction:* The existing lambda and phi each affect several coefficients; the proposed teaching mapping should expose that choice rather than imply isolation.

## 25. Post-Crisis: Applied Limits
Earlier operations return as choices about distinguishability, participation, disagreement, provenance and shared construction. The route moves beyond interfaces into walking and altering relations: a passage becomes possible, a hand acquires another neighbour, and the final record keeps enough of that work to begin again. No simulation substitutes for the people and histories its questions concern.

### CriticalAlgorithms_Algorithmic_Bias_Visualization — Give a distinction enough room
The student holds the compression handle still and changes viewpoint, then moves the handle and watches two labels become harder to distinguish. Bringing interpolation and indexed positions, they would compose two arrangements of a small chosen label collection and preserve one distinction that the compressed arrangement obscures. The label renderer, handle and comparison frame are supplied. They learn to separate changing represented geometry from changing a view, while naming this as an authored spatial analogy. Their readable arrangement carries into the distribution of places from which people might address one another.

**Short AI alternative**
Use fixed compression while viewpoint changes, then compress labels. Reuse interpolation and indexed positions; compose two arrangements preserving an obscured distinction. Teach representation versus view through authored spatial analogy. Supply labels, handle and comparison frame. Carry readable distinctions. Open: labels respecting internal differences; this is no measurement of trained embeddings.

*For correction:* Choose labels without silently treating a broad social category as internally interchangeable; this is not a measurement of trained embeddings.

### CriticalAlgorithms_Applied_Ethics — Arrange a place to address someone
The student compares the head chair and circle, then removes their persuasive colours before choosing a place to speak from. Bringing generated positions and transforms, they would arrange the same supplied chairs at the same scale into two different plans, tracing approach routes and lines of sight from a chosen seat. The chair models, room boundary and view markers are supplied. They learn what the geometry guarantees and what participation would still require from people using it. Their composition carries a specific design question into the next hall's unresolved reports.

**Short AI alternative**
Use head chair and circle without persuasive colours. Reuse generated positions and transforms; arrange identical chairs at equal scale in two plans. Trace approach and sightlines. Teach geometric invitation versus participation. Supply chairs, room boundary and view markers. Carry explicit access question. Open: participant activity to test; equal count and scale do not establish equal authority.

*For correction:* Choose which participant activity to test first; equal count and scale improve comparison but do not establish equal authority.

### SpeculativeComputation_Paraconsistent_Engineering — Let a resolution keep its alternatives
The student watches RESOLVED leave one branch tall and reduce the other to a named stump. Bringing source-tagged reports and the earlier distinction between storage and inference, they would keep both reports plus a separate decision record naming the chosen action and its reason. The branch sculpture, report input and comparison display are supplied. They learn to change a decision without silently deleting what made it difficult, then identify what further evidence might revise it. This reflective construction carries provenance onward without treating unresolved disagreement as automatically desirable or overlapping meshes as a logic.

**Short AI alternative**
Use RESOLVED branch and named stump. Reuse sourced reports and storage/inference distinction; retain both reports beside decision, action and reason. Identify evidence for revision. Supply sculpture, report input and comparison. Carry revisable decision with alternatives. Open: conflict with known time, source and subject; neither overlapping meshes nor unresolved disagreement establishes a logic or virtue.

*For correction:* Choose a concrete conflict whose time, source and subject are known before introducing contradictory propositions.

### SpeculativeComputation_Situated_Computation — Keep where and when an image was made
The student compares the four assigned verdicts, then moves a witness camera while its delayed and held images retain earlier views. Bringing records, coordinates and time, they would keep an image reference with its source, exposure time and camera transform, then compose two such accounts side by side. The cameras, pickup system and frame capture are supplied. They learn that moving a receiver or changing a present viewpoint does not rewrite an earlier record. Those located observations become material for shared work without turning an authored confidence percentage into earned evidence.

**Short AI alternative**
Use assigned verdicts and delayed/held witness images. Reuse records, transforms and time; retain image reference, source, exposure time and pose. Compare two accounts. Teach present view versus earlier record. Supply cameras, pickup and frame capture. Carry located observations; authored confidence is no earned evidence. Open: annotation now or collective hall.

*For correction:* Keep the first record small; decide whether the learner adds an annotation now or in the collective hall.

### SpeculativeComputation_Collective_Knowledge — Make an addition that keeps its source
The student follows a coloured facet back to its rim node, then visits the commons table whose open centre has not removed its authored categories. Bringing indexed records and source-tagged observations, they would assemble a small shared form from contributions that retain source and version, counting arrivals separately from distinct contributors. The facet builder, arrival stream and table remain supplied. They learn what accumulation can record and what it cannot settle about knowledge or authority. Their construction leaves one rule open for another contributor to revise, carrying that invitation into the network.

**Short AI alternative**
Use facet's source node and commons table's authored categories. Reuse indexed, sourced records; assemble contributions retaining source/version. Count arrivals separately from contributors. Supply facet builder, arrival stream and table. Teach accumulation's limits for knowledge and authority. Carry shared form with revisable rule. Open: rule participants can change; automatic stream alone proves no shared authority.

*For correction:* Choose a rule participants can actually revise; an automatic stream alone cannot demonstrate shared authority.

### SpeculativeComputation_Rhizome_Network — Make another way through
The student enters the cave, finds a coloured junction and returns by another passage before using the small grower's controls. Bringing graphs, fields and clearance, they would choose two places they wish were neighbours and add one connection to a supplied chamber description, then inspect the extracted passage through a prepared study. The chamber fields, shell builder and player are supplied. They learn how an extra edge can become a different bodily route, while growth without a named root still has boundaries and uneven access. That desire to revise a relation travels into assembly.

**Short AI alternative**
Use cave walk and alternate return before grower controls. Reuse graphs, fields and clearance; propose one connection between chosen chambers, then inspect extracted passage in prepared study. Teach edge versus bodily route; rootless growth retains boundaries and uneven access. Supply chamber fields, shell builder and player. Carry tested relation. Open: feasible chamber pair.

*For correction:* Select two chambers with a feasible new passage; preserve walking as the first encounter rather than making the control desk the lesson.

### AdvancedLaboratory_Lab_Equipment_Simulation — Give the body another neighbour
The student moves the amber body's hand, then reroutes a connection while leaving every joint where it stands. Bringing local coordinates, edge pairs and constraints, they would alter one position and one endpoint in the body's retained description, comparing each with the original. The handles, bond renderer and persistence are supplied. They learn that changing pose differs from changing belonging, then pull the neighbouring constrained doll or chair to feel a relation transmit consequences. Their own revised body, including its connections, is kept for the final hall rather than replaced with a demonstration.

**Short AI alternative**
Use amber hand movement, then rerouted bond with joints fixed. Reuse local coordinates, edges and constraints; edit one position and endpoint separately, comparing original. Pull neighbouring doll or chair. Teach pose versus connectivity, drawn versus constraining relation in separate beats. Supply handles, bond renderer and persistence. Carry same saved learner body and connections across exit.

*For correction:* Give pose, connectivity and the dynamic-body comparison separate beats; keep the same learner record across the exit.

### PostCrisis_Synthesis — Keep another possible return
The student meets the amber body they changed beside its blue starting arrangement, then reads what the ledger remembered and what the gesture left out. Bringing positions, connections and retained records, they would extend a prepared version of that record to keep one earlier arrangement alongside the latest, with an optional note about the change. The reconstruction renderer and file persistence are supplied. They learn to choose what a future return can recover, then name another body or passage they want to make. The museum closes with usable material and an unfinished desire.

**Short AI alternative**
Use revised amber body, blue starting arrangement and ledger's omissions. Reuse positions, connections and records; extend prepared record to retain earlier and latest arrangements, optionally annotated. Supply reconstruction renderer and file persistence. Teach versioned recovery versus lived gesture. Carry two recoverable arrangements and desired next body or passage. Open: final construction or independent-work proposal.

*For correction:* Decide whether version history is the final short construction or a proposal the learner carries into independent work.

## Source and route differences

The current spine JSON defines the reading order. The saved Endless Museum plan is compared separately; it is not automatically promoted into a curriculum. Lab_Path and LSystems_Shape_Grammars are in the spine but absent from that plan. Chamber_Color remains in the saved plan despite the author removing it from Colour. The other saved-plan extras are biome side encounters, not additional tutorial chapters.

Photographs show attributed museum views. Earlier photographs may predate changes. New standing-camera captures establish an image of a loaded hall, not a successful lesson, complete route traversal or physical-headset test.

The older subject register remains planning material. First teaching, supplied use and later return must be reconciled after the teaching choices are agreed. Source correctness does not certify teaching progression.

Next: correct these paragraphs, then write and verify one full tutorial at a time. Do not expand the full course automatically.
