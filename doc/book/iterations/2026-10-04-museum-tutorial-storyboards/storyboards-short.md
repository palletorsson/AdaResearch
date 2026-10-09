# Ada · Tutorial storyboards · Short AI alternatives

4 October 2026. Day Zero + 204 halls, current spine order. Teaching proposals, not approved lessons.

## Shared brief

Summaries only. Do not change code logic, artifacts, maps, order, tutorial.md or final.md. Agree each teaching choice before drafting a full lesson. Imperatives below guide future writing; they do not authorize implementation.

Host: existing Endless Museum. Counter, rooms, player and artifacts already exist. Select useful operations; do not duplicate the world. Tutorial, reflection and wider museum material overlap without matching one-to-one. Reflective halls may reuse known tools without new syntax.

Use = encounter. Reuse = prior learning. Teach/Do = selected operation. Supply = named support, not a prerequisite already mastered. Carry = reusable result. Open = unresolved choice. Defer = later learning. Keep proposed adapters distinct from verified behavior.

Keep types and reference frames explicit. A value is not its mesh; a surface is not collision. Prefer code-created teaching geometry and direct references; no hidden scene lookups. Source conflicts become notes, not runtime edits. Read the full summary and review note when resolving a choice.

## Day Zero
Open Endless Museum on desktop; prepare XR deployment if used. Teach edit/save/run/return. Explain supplied player, camera and lighting. Verify a saved change appears. Carry: working environment. Open: choose the small hello-world check. Complete setup before hall lessons.

## 1. Primitives: Points Build Worlds

### Point_Zero
Use existing frame counter. Prior: running museum. Teach initialization in _ready() and per-frame updates in _process(delta). Compare one reading with repeated readings. Supply player, room and display. Carry: execution timing. Reflection: arrival, borrowed time.

### Point_One
Use corridor: unseen point, visible sphere, solid sphere. Teach position variable; distinguish value, mesh and collider. Change position; compare visibility and contact. Supply corridor, lighting and variant system. Carry: represented point. Open: where reduced learner code belongs. Keep the light switch as a visibility encounter.

### Point_Coordinates
Use existing black point and coordinate frame. Reuse position variable and body. Teach the supplied grab connection; move along X, Y, Z and read positions in one named frame. Supply XR rig and readout. Carry: movable, readable point. Open: grab interface and extent of local/world comparison. Defer decimal formatting.

### Point_Lines
Use existing adjustable line. Reuse two positions in one frame. Teach displacement = end - start; distance = displacement.length(). Move endpoints; find another direction with equal distance. Supply handles and visible segment. Carry: connect neighbouring positions in Trace. Zero displacement has no direction.

### Point_Trace
Use existing drawing pen. Reuse positions and segments. Teach ordered list: append accepted positions, read an entry, loop over neighbours. Draw a bend or return; follow its order. Supply input, sampling and session storage. Carry the student's retained drawing into Grid. Respect cumulative recording across pickups.

### Point_Line_Grid
Use existing grid and the student's released trace. Reuse list and loop. Teach list index versus spatial address; follow XYZ rounding. Supply session transfer and display fitting. Existing order: centre/resize, then round displayed positions. Compare coincident addresses; retain source separately. Carry: organize positions. No restart-persistence claim.

### Point_Triangle_Context
Use small drawing tool and enlarged twin. Reuse points or recorded positions and segments. Select three non-collinear corners; close outline, then submit a face in explicit corner order. Distinguish boundary from surface. Supply mirroring, material and input. Carry: triangular face. Defer arbitrary polygon filling.

### Primitives_Polythedra
Use the hall's solids. Reuse triangular faces and position list; add one point to make a small enclosure. Teach face indices referencing stored corners. Distinguish position edits, connectivity and collision. Supply rendering wrapper; retain bodily comparisons for reflection. Carry: editable mesh. Open: select the first enclosure.

### Point_Animatedcube
Use cube and comparison display. Reuse positions and face lists. Move a shared corner; inspect affected faces; compare diagonals across one side. Distinguish vertex edits from whole-object motion. Carry: mesh editing. Keep prefab shelf as a reuse/repetition encounter; defer scene packaging.

### Primitives_Ignorance
Use solids and columns. Reuse position lists and loops. Teach function: radius in, symmetric positions out. Supply face connections. Compare editing a result with changing its rule. Carry: reusable generator. Keep resolution, proportion and aesthetic judgement distinct. Open: separate profile-and-rings follow-up.

### Primitives_Portals
Use ring display; supply circle sampler. Reuse generated positions and distances. Compare segment counts; choose sufficient resolution for a stated visible or bodily purpose. Carry: a justified tolerance. Keep resolution, proportion and aesthetic preference distinct. Preserve reflective pacing; defer trigonometric construction and portal rendering.

### Primitives_Melencolia
Use existing Durer encounter and prepared materials. Reuse known forms and placement to compose a small arrangement. Require no new syntax. Preserve reflection on geometric desire, exact forms and the difficulty of making. Carry composition into Transformation. Open: scale must be supplied or deferred if not yet taught.

## 2. Transformation: What Stays the Same When Everything Changes

### Trans_Pre
Use four pickup demonstrations. Reuse the created cube reference. Teach elapsed seconds, bounded height/size interpolation and a timed turn. Compare sine arrival speed at equal endpoints and duration; explain its range. Supply room, readout and collection. Carry reusable animation. Keep the museum encounter linear; place sine in the companion study. Defer circular meaning.

### Trans_Introduction
Use moving cube, growing support, turning plank and adjustable landing. Reuse animation and endpoint calculations; hold plank motion fixed while moving the destination. Teach surface motion versus carried displacement. Supply banks, controls and physical deck with rider adapter. Carry a crossing specification with fixed references. Open: choose the smallest supported deck interface before drafting code.

### Trans_Translation
Use seven carrier journeys. Reuse positions, lists and interpolation. Teach waypoints in one frame, leg subtraction and direction = leg/length for nonzero legs. Compare waypoint travel with the direct route. Supply carrier, rider connection and preview marker. Carry a route generator preserving intermediate travel. Open: choose marker preview or visitor carrying; carrying needs the preceding deck interface.

### Trans_Rotation
Use blades, marked cubes and composition workbench. Reuse positions, functions and timed angles. Teach pivoted construction: rotate an offset around a named axis, then add its centre. Reverse two turns to test order. Supply angle display and physical ride; retain the hinge as a quiet return. Carry pivoted construction distinct from whole-object motion. Defer full rotated arrays and ride physics.

### Trans_Scale
Use the bottle enlarging the room around an unchanged visitor. Reuse uniform scale and pivoted forms. Teach parent-child transforms through one created group beside a fixed doorway; compare dimensions and child spacing. Supply room, bottle and relocation; distinguish relocation from scaling. Carry a bounded grouped construction. Open: choose the small composition.

### Trans_Body
Use opening slats, retained lattice removal and shrinking blocks. Reuse distance and interpolation. Teach clamped distance-to-size mapping on one adjacent block, keeping its base grounded. Supply visitor-position query and matching collision updater with explicit inputs/outputs. Compare walking away with retained removal. Carry a proximity function and state distinction; keep carving infrastructure supplied.

### Trans_Pit
Use the level-ground timed pushers, slabs, growers and airlock. Reuse timed/proximity transforms. Compose two leaves whose position, angle and size share one opening fraction; hold an intermediate pose to inspect clearance. Supply frame, occupancy input and physical leaf wrapper. Carry an authored opening sequence toward arrays. Require no new syntax; discard obsolete pit/death framing.

## 3. Arrays and Regularity

### Array
Use row and indexed grid. Reuse Trace list/loop and positioned bodies. Teach retained slots, then grid_data[x][z]; separate occupancy, node reference and spacing. Supply display adapter/collection event. Check: empty one slot, vary spacing, preserve addresses. Carry record + reader. Optional: stored Molnár departures. Floor writer stays an encounter. Open: reduced learner binding; Array tutorial absent.

### Tutorial_3D
Use flight enclosure. Reuse occupancy record. Teach displayed [x,y,z] → values[y][z][x]; explicitly convert earlier [x][z] plane into a [z][x] layer. Supply flight/selection/collection. Check unequal indices; write/read one slot without shifts. Carry storage-to-space mapping. Open structures/suspension remain comparisons. Open: reduced study binding; an added dimension grants no flight.

### Tutorial_Tiling_Floor
Use paired 4×4 samples. Reuse indices/rotation. Teach address → quarter-turn via remainder; zero means orientation, not vacancy. Supply motif/image renderer. Predict one result, add one exception, enlarge field with same rule. Carry motif + turn rule + exception. Other fields compare. Existing tiling rasterizes images; no per-tile body or stored occupancy implied. Open: learner-rule binding.

### Tutorial_Tiling_Walls
Use wall fields, eye chart and turning wall. Reuse floor motif/rule/image on supplied upright receiver. Compare distance and apparent scale; no new syntax. Predict image-turn versus carrier/collision-turn. Supply hinge/landing. Carry source–appearance–access distinction. Preserve the outside pause. Open: learner image assignment; no new tiling or wall-construction lesson.

### Tutorial_Disco
Use separate sequencer and changing floor. Reuse lookup/remainder/time. Teach score[track][step] plus timed playhead; false = no new trigger. Supply sound receiver/display. Move event at fixed tempo; change tempo with score fixed; stop score and predict floor. Carry timed reader. 16 steps/12 columns can share a flash address. No footstep recording. Open: old tutorial contradicts current encounter.

## 4. Color and Composition

### Color_Context_Placed
Use fixed-geometry columns. Reuse primitives/transforms/lookup. Teach palette selection separately from material assignment and placement. Supply part/material references; numeric categories optional after index selection. Check: regroup separated parts without moving them. Carry palette + selection rule. Rich stacks remain encounters. Open: reduced host binding; no dictionary lesson assumed.

### Color_Flashlight
Use existing lamp/board/faceted sphere. Reuse colour assignment and transforms. Follow current bounded light-colour edit; retain named light reference. Vary colour with receiver fixed, then aim with colour fixed. Supply grabbing/room/renderer. Carry illumination versus albedo distinction. Timed lamp optional. No new room; no spectral-optics claim.

### Color_Nails
Use RGB point and salon hands. Reuse local position/bounded mapping. Teach positive box sizes; clamp/divide X→R, Y→G, Z→B; return Color → named preview albedo. Supply grabbing/hands/signals. Predict another point, revisit it; keep nails fixed while changing skin. Carry function + recorded colour. Preserve Lorde/embodied difference. Open: reduced preview binding; no automatic Rainbow transfer.

### Color_Rainbow
Use RE-DIVIDE; celebration stays unconditional. Reuse palette; manually record/reuse Nails colour. Optional: replace palette entry, compare nonempty lengths at fixed total width. Supply curved-strip builder and route. Predict seams versus opening. Carry palette/partition distinction. Many bands remain discrete; HSV sampler optional before Pillar. No automatic transfer or optics claim.

### Color_Pillar
Use moving sampler and constant swatch. Reuse Nails function pattern, change convention: field X→H, Z→S, Y→V; convert HSV→Color. Supply explicit hand-height adapter (.65–1.85 → .46–4.60 m), card/readouts. Predict between columns; vary V alone. Movement resamples; stationary card keeps latest. Carry function + recorded result. Black has many source addresses; HSV is not perceptually uniform. No automatic Grid handoff.

### Color_Grid_Pallet
Use edited floor square. Reuse address/lookup and recorded Nails/Pillar Color. Propose write through named address→instance receiver; selection only reads. Check leave/return, then predict RULE overwrite. Current COLOUR cycles four inks; custom input needs binding. Carry stored assignment versus live evaluation. Optional protected exception; no history/current protection. Keep 25-site control versus wider rule and unchanged support.

### Color_Paint
Use existing automatic path/manual cans. Reuse time/sine/address distinctions. Edit one UV rate or amplitude; predict path width or pace with other coordinate fixed. Supply UV→hit mapping and shared draw_spray surface. Compare quick versus repeated deposits. Carry path rule and evolving-image distinction, not recoverable gesture history. No second brush; defer spray/feedback shader. Albers remains an encounter.

### Color_Walls
Use switchable panes and existing companion edit. Reuse materials/transforms/palette. Vary one pane angle or palette while other condition stays. Explain alpha; supply transparency/light/collision. Predict view versus passage. Carry palette separate from arrangement into Pattern_Disco. RGB/HSV models/interpolation optional; preserve privacy/authority questions. No new composition required. Open: companion spacing prose/code mismatch.

## 5. Patterns: Dress the Architecture

### Pattern_Disco
Reuse existing value_at and Colour palette lookup. Hold floor/stop score; change colour pair, then phase alone. Predict unchanged relationships. Supply floor/controls/separate score clock. Carry value versus appearance. Triangle drawing optional and distinct from whole-cell values. No new floor/clock; reduced palette-edit entry still to be chosen.

### Pattern_Foundry
Use one 4×4 tile. Reuse addressed writes/palette lookup. Teach source[row][column] palette indices, wrap address then choose colour. Predict a repeated pair after one edit. Supply input/image preview. Carry motif + reader. Optional return: independent nested copy versus live reference. Loom has separate 5×5 source; HOLD image differs from SAVE. Later teaching stations use fixed seeds.

### Tutorial_Pattern
Use PM versus FLIP X. Reuse motif/wrapping. Teach alternate-column reflected read without source mutation; separately reverse entries within each source row, not row order. Predict asymmetric neighbour; inspect unchanged versus changed source. Supply editor/displays/shader. Carry read transform versus data transform. Symmetric motif may hide the operation; shader authorship waits.

### Array_Patterns
Use fixed-source tunnel; no preceding-edit transfer. Reuse wrapped read/reference frames. Teach position→surface row/column with named origin/axes and metre cell width. Predict .4→.6 m cells means 1.6→2.4 m motif. Wall directions differ; corners restart. Supply tunnel/collision/shader/selector. Carry explicit surface conversion. Distinguish cell width from whole-repeat width; optional import remains unbuilt.

### Symmetry_Seventeen
Use P1/PM/PG live-held comparison. Reuse reflected reader; on alternate reflected blocks shift source row by two and wrap four. Predict adjacent blocks and generic two-block X period. Supply editor/panels/image hold/cage. Alter asymmetric mark to hide/reveal operation. Carry diagnostic motif + tested period. Keep classification/cultural history distinct; no proof of seventeen renderers.

### Ribbon_Patterns_01
Reuse volume[y][z][x]; source plane is SOURCE[z][x]. Repeat then shift lookup SOURCE[z][(x+y)%4]. Predict unequal indices before marker check. Supply cubes/selection/slicing. SLICE:16 visible,64 stored; zero=pale colour, not absence. Carry layer reader and value meaning. Fixed familiar motif, no previous-edit import. Missing full companion remains to write.

### Ribbon_Patterns_02
Keep reflective comparison. Equal target values, changed surrounds; same source and surface spacing, flat/curved carriers. Separate numerical equality, arc length and projected appearance. Supply controls and dot-product shading; teach operation later. No required perceptual result or new code. Carry controlled comparison to studio; no spectral-metamerism claim.

### Ribbon_Patterns_03
Use existing studio wall/skirt host. Teach tiny fragment: UV×repeat+offset → repeating nearest texture → ALBEDO. Supply palette-index→texture conversion, material assignment, meshes/wardrobe. Predict repeat versus offset; UV counts are not metres. SAVE stores bounded cells/settings; WEAR explicitly applies snapshot to Skirt. No shader-code export or general garment transfer. Cut-out/finish/deformation optional; full companion absent.

## 6. Change: Rate, Accumulation, and Flow

### Change_Intro
Reuse functions/differences/loops. Supply smooth f(x), plots, tangent and controls. First: finite rate over nonzero h; predict sign elsewhere. Next: sum f(sample)*width over fixed interval; vary count or sample fraction alone; predict one contribution. Carry rate/sum functions with units. x=position, not time. Reference=finite 4096-midpoint sum. Bridge uses DIFFERENT arch: supplied signed-rate comparison, net change not total travel. Exact learner edit location pending.

### Flow_Field
Use FIELD HELD: field clock stops, particles continue. Reuse position/delta/retained list. Supply field_direction(Vector2 canvas_position), renderer/boundary policy; declare frame. Teach unit direction*speed*seconds→displacement; next address→next lookup. Predict two updates from another start. Carry follower/record, no inertia. Optional return: dt versus two dt/2, same start/field/speed/duration; SPEED is not time step and RESET rescatters. Current trails join wraps; segment break only proposed. Defer noise/angle construction and Forces velocity state.

## 7. Vectors & Forces: From Direction to Dynamics

### Vectors_Act1_WhatAVectorIs
Use SHIFT and the existing sample_vector(); reuse positions and translation. Predict a tip movement in supplied XY/XZ views, then reveal PARTS. Use SHORT/LONG/ZERO to distinguish magnitude and direction. Briefly explain normalization and its threshold at the companion. Carry a world displacement with stated display scale; require no new projection display or force controller.

### VFM_02_Operations
Use GO/SWAP/PATH/CANCEL on room_sum. Reuse displacement and accumulation. Own result=a+b and compare summed leg lengths with direct length in the existing refresh path; keep movement and drawing supplied. Check against the actual travelled counter. Carry destination and distance separately, with local forward mapped to -Z and GO's reset excluded. No new carriage or transport binding.

### Vectors_Act2_VectorArithmetic
Return to SWAP/SHIFT/SAME, then use the actual gap-to-projection connection. Teach signed dot reading, kept vector and subtracted remainder in the existing refresh path; recombine and predict SLIDE/TURN/FLIP. Supply unit rail, controls and diagrams. Carry a projection plus remainder. Keep FRIEND and torque as brief comparisons, not extra builds or evidence of mastered cross products.

### VFM_05_Launch
Use FIRE/PAIR, then trace existing flight_position(). Reuse time, vector components and rate. Supply the analytic position formula, angle conversion, duration and receiver; introduce acceleration's units without deriving a ballistic solver. Vary one beginning, inspect PATH/PARTS and distinguish SLOW from changed gravity. Carry a position-at-time function with assumptions. Launch stays before Motion; no integration or collision response is claimed.

### VFM_03_Motion
Reuse Launch’s initial velocity, timed callbacks and Change rates. Own a finite force schedule for a supplied rigid body; predict delta-v = (F/m)T, then compare masses from rest with drag off before contact. COAST ends the command while velocity remains. A perpendicular pulse meets existing motion. Supply engine integration, chamber and readouts. Carry the schedule and prediction into Fields. Keep the friction ramp a separate comparison; do not teach a second solver.

### Vectors_Act3_FieldsAndMotion
Reuse Flow Field sampling and Motion’s retained velocity. In a proposed small position/velocity study, own assignment versus accumulation and the subsequent position update. Predict two uniform-field steps before the sink comparison; reverse influence without erasing state. Supply dimensionless field, unit adapters, fixed runner, markers and trails. Carry the update convention manually toward Oscillation. Installed markers have no mass or collisions, and no shared learner state travels between halls.

### Vectors_Act4a_KineticForces
Own one drag function, F = -b v, with b in kg/s. Reuse Motion’s force receiver and Fields’ operation distinction. Predict initial acceleration for two masses at equal speed and fixed b; compare before frame exit. Supply engine integration, launcher and readouts. Carry resistance into spring damping. Keep walking, mower work and prescribed circular motion optional comparisons; the material names are not measured fluid properties.

### Vectors_Act4b_Oscillation
Return to Fields’ proposed position/velocity study in one dimension; add restoration and Kinetic Forces’ damping. Own F = -kx - cv, then v += (F/m)dt and x += vdt. Supply runner, rail and handle; release starts from rest. Predict force direction and crossing, compare damping from equal beginnings, and carry the oscillator toward later waves. Distinguish computed motion from prescribed sine; no shared museum-state or hand-throw transfer is implied.

### Change_Choreography
Keep rods, conveyor and paired dials in their existing order. Reuse indexed repetition and elapsed time; introduce period and phase at the rods. Follow the existing DRIFT_RATIO edit from 1.04 to 1.02; predict thirty seconds of separation, then preserve the gap with SAME RATE. Supply display and controls. Carry offset versus accumulated rate difference. Conveyor contacts and the clocks' historical reference remain comparisons, not extra builds or claims of bodily simulation.

### VFM_07_Gravity
Use the held source and mutual-body stations. Reuse separation and force-to-acceleration. Own the two receiver contributions in the existing pair pattern; supply softened attraction, loop and integrator. Check equal/opposite forces with unequal receiving masses. Read the omitted response for body zero. The stations change beginnings as well as recipients. Keep third-body and NUDGE as comparisons; require no new gravity solver.

### VFM_09_Legs
Use FEET, SHIFT and RELEASE on the existing plate. Reuse geometry, mass centre and physical response. Predict adjacent versus diagonal support with the same centred mass; check the initial finite-pad outline against release. Supply hull and solver. Compare the commanded walker without treating it as balance validation. Carry an explicit support hypothesis and its limits; add no hull or gait implementation obligation.

### VFM_08_Arena
Keep Arena a comparison. Reuse distances, conditions and commanded-body distinctions. Before feeding starts, hold positions fixed, insert the screen and predict selection versus completed-meal history. Read the supplied selector and event record; build no new controller. The five-meal stop is authored. Keep collision carts a separate model and interpretation open. Carry a distinction between eligibility, retained events and attributed agency.

### Vectors_Act5_ForceAsPlace
Use cubes before the visitor crossing. Reuse sampled fields and retained velocity; compose acceleration with supplied controls and inspect the cube update. Predict zero field versus immediate stopping, keeping damping and contacts explicit. Compare the visitor's separate receiver. Carry membership, units and state. Prepare the change to Form Finding: its gradient descent stores no velocity, and its step size is not elapsed physical time.

## 8. Form Finding: Rules, Constraints and Possible Shapes

### FormFinding_Descent
Use STEP on the cost surface. Reuse finite differences and vector updates. Estimate two-axis gradient of an editable cost; subtract step times gradient. Compare beginnings, large steps and stopping thresholds. Supply surface, controls and trails. Carry an optimiser with declared cost, step and stopping reason. Keep iteration separate from physical time; small slope does not certify lowest cost.

### FormFinding_Catenary
Use drafted cable, formula washing lines and fixed catenoid. Reuse generated/constrained positions. Compare construction inputs; vary an anchor in a small span/sag curve and test retained constraints. Supply anchors, sampler, tube renderer and analytic examples. Carry a specification distinguishing drawn, evaluated and settled shapes. Open: whether code is needed; neither spline nor catenoid is an interactive equilibrium solver.

### FormFinding_Relaxation
Use cloth responding to correction-pass count. Reuse position arrays/history. Build a short chain with current/previous positions and neighbour rest lengths; teach distance correction, zero-distance guard and pinned-endpoint effects. Supply fixed-step runner, line renderer and wind. Repeat passes, vary count and disable wind. Carry a constrained network and explicit computation budget; defer full cloth and exact-solution claims.

### FormFinding_Equilibrium
Use the mobile's heavier disc nearer its pivot. Reuse distance, mass, functions and line/point construction. Calculate two arm lengths across a chosen span; check equal mass-distance products. Supply modelled disc masses, geometry and larger mobile. Carry a balance function for later hierarchy. Omit rod/wire mass explicitly; display is not dynamic simulation. Defer recursion; production use does not require teaching it.

### FormFinding_Annealing
Use wrinkled descent and annealing tables. Reuse cost and stored random choice. Propose candidates; accept improvements. For worse candidates, compare zero-to-one draws with supplied temperature-dependent probability thresholds. Keep current/best records separate; compare cooling. Supply landscape/controls. Carry probabilistic search without optimality or physical-heat claims. Open: best-so-far host display. Defer distribution quality and seeded replay to Randomness; explain probability here.

### FormFinding_Forge
Use the quiet low stack failing height requirements. Reuse timers, conditions and physical/prescribed distinctions. Write height-and-low-movement-duration success criteria; test a rejected construction. Supply contacts and measurements. Carry a declared criterion without new syntax or claims of life/universal optimality. Compare restarting optimiser and clock-driven forge. Open: measurement interface; MAX Q is a clock effect, not an optimisation measure.

## 9. Wavefunctions: What Returns

### WaveFunctions_Intro
Use opposite-velocity pendulum crossings and prescribed sine cubes. Reuse spring integration and dot projection. Teach angle/angular-velocity state; project hand release along swing and compare equal angles with different velocities. Supply bob, constrained hold, hand samples and restoring-acceleration rule. Carry angular state beyond position alone. Open: timestep and damping; current texts identify frame-dependent damping.

### WaveFunctions_Pendulum
Use the pendulum's receding teal record. Reuse Trace and elapsed time. Teach named position/timestamp fields, sampling interval and count/age bounds; draw age on a separate axis. Compare fine, coarse and near-period sampling. Supply pendulum state and renderer. Carry a bounded timestamped recorder with temporal resolution/span. Keep display direction separate from body path; do not silently encode time in position components.

### WaveFunctions_Sine_Space
Use the tray and collision-disabled corridor walls. Reuse grid samples, triangles and sine. Multiply two spatial sines into grid heights; join neighbours. Supply static mesh-to-collision creation, sphere release and counts. Compare relief with body size within the observation window. Carry a sampled height field distinguishing spatial frequency, visible surface and contact. Defer moving construction until mesh/collision updates are explained.

### WaveFunctions_Unit_Circle
Use rotating point, two projections and graph. Reuse sine and pivot/radius. Teach centre plus radius-scaled cosine/sine; predict quarter turns to establish radians/phase. Supply circle, angle control and graph receiver. Carry an understood sampler replacing those supplied in Primitives and curved strips. One projection cannot recover full position; do not generalise uniform rotation to all periodic motion.

### WaveFunctions_3D_Wave_Propagation
Use the current coupled lattice. Reuse spring updates and indexed states/copies. Teach acceleration from adjacent displacement differences in a short oscillator row; read all old states before committing updates. Supply fixed-step runner, impulse control and markers. Compare linked/independent runs. Carry local transmission distinct from imposed phases. Keep older dropped-pebble/distance-delay proposals separate.

### WaveFunctions_Effect_Sound
Use two desks and held-note comparison. Reuse sampled functions and sine phase. Fill a finite sample list with a carrier receiving a second sine inside phase; hold frequency while varying depth. Supply encoding, playback, envelope and audition controls. Carry phase modulation distinct from tone addition. Open: responsive note length and desktop input; the scope does not prove listening experience.

### Wavefunctions_Bernini
Use the twisting, rotating column. Reuse circle sampling and connected faces. Build a reduced ring stack beside it with angular offset depending on height; connect corresponding corners. Pause/restart whole-object rotation without rebuilding geometry. Supply reference column and lighting. Carry spatial twist distinct from temporal animation. Open: source-check reduced geometry; avoid the old incomplete triangle-strip construction.

### WaveFunctions_John_Cage
Use continuous sound and intermittent events; attend to intervals. Reuse bounded choice and timed scores. Propose a retained event list with chosen vocabulary/interval bounds; replay to distinguish authored options from performance choices. Supply sounds and playback. Carry inspectable chance composition toward Randomness without new syntax. Open: replay extension; current soundscape records no visitor sound and implements no particular Cage score.

### WaveFunctions_AirMusic
Use ringing bars, retriggers and overlapping strikes. Reuse sine notes and event state. Give two supplied players separate start times; multiply each sine by a decaying envelope. Compare retrigger/overlap; keep chosen frequency independent of visible length. Supply strike events, bodies and encoding. Carry independently aged voices. Open: desktop strike input; the synthesised model does not derive frequency from material.

### Wavefunctions_Sky_Stairs
Use uniform rise and sine-modulated stair radius. Reuse circle sampling, spatial sine and repeated bodies. Build three-to-six treads beside the stair; calculate centres, widths, orientations and separate collision boundaries. Supply tread components, staircase and viewing floor. Compare inner/outer edges. Carry a tested support segment beyond centre spacing; do not infer complete climbing or headset comfort.

### WaveFunctions_TrigWalkingPath
Use the three-row beat exhibit. Reuse sine, frequency and phase. Sample two close frequencies at shared times; add signed values into a third record with separate display scale. Supply rows and controls. Exchange higher frequency and predict envelope pace. Carry superposition/cancellation without a third source or audio claim. Keep walking paths secondary: finite and circulating, not endlessly generated.

### WaveFunctions_Synthesis_Lab
Use five harmonic rows and their pale sum. Reuse addition, lists and functions. Sum weighted harmonics from coefficients at shared phase; predict a marked sample and build a finite shape, naming nonnegative-coefficient limits. Supply sliders, plot and held comparison. Carry a wave recipe. Keep room-memory repeat/reprocess comparison separate; this visual bench neither shares specimen state nor generates its waveform's audio.

## 10. Randomness: What Can Chance Change?

### Random_Definition
Use paired colour grids. Reuse RGB lists, loops and bounded draws. Teach a local seeded recipe with explicit request order; insert an unused request to change the picture. Supply displays, replay controls and generator internals. Carry recipe plus seed. Open: verify the proposed colour-list adapter and witness grid; promise neither existing transfer nor cross-version replay.

### Random_Entropy
Use the ledger's sorting tiles. Reuse retained seeded samples. Teach frequency counting and copying before sorting; compare changed neighbours against unchanged counts and entropy. Supply ledger, tiles and entropy calculation. Carry a snapshot and separate frequency account; entropy does not measure freedom. Open: Definition's colour-record transfer is proposed; the ledger owns its sample.

### Random_Remove
Use the amber board, sampling hoppers and removal floor. Reuse addresses, conditions and seeded draws. Teach an eligible list; predict excluded choices, then draw with or without replacement. Supply displays, animation and floor. Carry candidate list and removal policy; distinguish visual removal from lost collision. Open: choose the board adapter or a compact supplied display.

### Randomness_10_PRINT_Algorithm
Use printing screen and slab arrangement. Reuse grid traversal, lines and retained draws. Teach mapping each draw to two diagonal endpoints; vary threshold or mark separately. Supply screen, large display and navigation study. Carry an address-to-mark rule. Distinguish the screen's sine-driven bias from fixed learner probability; maze appearance proves neither connected routes nor bodily clearance.

### Random_Cubes
Use physical and continuing dice: six continues, another face ends the sum. Reuse state, sums and retained outcomes. Teach a bounded accumulator invoked once per accepted landing; report unfinished chains at the limit. Supply physics, landing connection and columns. Carry sequence, total and stopping rule. Preserve physically read faces; no RNG substitution, waiting loop or fair-release claim.

### Random_Rotate_Random_XYZ
Use turning stacks and wear rig. Reuse transforms, time steps and draws. Compare fresh-angle assignment with accumulated in-plane increments; record orientation and inspect RESET. Supply stack renderer and controls. Carry persistent state versus increment into Walk. Identify the production update's frame dependence; the historical XYZ title misleads, and the wear rig changes without randomness.

### Random_Walk
Use terrarium and paired rails. Reuse vector addition, accumulated state and Trace's list. Teach sampled displacements and recorded endpoints; predict a step and state its boundary rule. Supply bead, timing and boundary comparison. Carry walker and separate record; smooth travel need not affect decisions, nor trails guide them. Open: choose a reduced boundary example before full folding.

### Random_Gaussian
Use the bead cabinet. Reuse retained samples and counts. Teach numerical bins; redraw boundaries without resampling. Supply uniform/Gaussian samplers with stated ranges, cabinet and animation. Carry a reusable histogram; separate sampling law, finite sample, clipping and binning. Treat the bell shape as a question. Defer sampler mathematics; decide whether an optional derivation follows.

### Random_Mushrooms
Use specimen bed, wardrobe and garment comparison. Reuse generated forms, transforms and sampling. Teach separate template, position and scale records; vary repertoire independently from distribution. Supply specimen builders, bed and wardrobe interfaces. Carry a population recipe with visible discrete kinds, continuous variation and limits. Open: select the smallest honest builder interface; follow the fourteen-map sequence.

### Random_Space_Geometry
Use WHITE NOISE and PERLIN NOISE grids. Reuse addresses, seeded draws and height mapping. Teach matched profiles from independent draws and a coherent field; measure adjacent differences and vary coordinate spacing. Supply bench and Perlin sampler. Carry spatial comparison; correlation is not memory, and matching displays do not establish matching distributions. Open: verify perlin_noise_bridge's reduced interface.

### Randomness_Examples_of_Randomness
Use the dartboard among paintings, pipes and particles. Reuse coordinates, sampling, conditions and counts. Teach a bounded square-sampling experiment: test centre distance, count hits and compare successive estimates. Supply dartboard, plotting and controls. Carry sample-test-count estimation; contrast its numerical purpose with marks or paths. Keep finite-sample error visible: extra draws need not improve each estimate.

### Random_Pheromone
Use terrain console. Reuse walker, grid addresses and stored values. Teach a separate signal field: deposit, decay, read neighbours, choose a step. Supply terrain renderer, stepped clock and walker display. Carry feedback into future choices; distinguish fading signal from accumulated height, without optimal-route claims. Open: reusing the learner's walker is proposed; current artifacts own separate states.

### Random_Space
Use the noise mixer. Reuse sine, loops and field sampling. Teach a finite weighted sum across coordinate scales; retain contributions for removal and recombination. Supply base sampler and mixer display. Carry a field recipe separating frequency from amplitude into Noise. Disclose the mixer's display rescaling; distinguish this sine-based construction from geology or stored visits.

### Random_Game
Use crossing and door timing trials. Reuse state, elapsed time and seeded choices. Teach drawing one duration, storing its deadline and reporting remaining time. Supply crossing, trials and collision timing. Carry a readable schedule separating state order, decision and disclosure; choose what a future interaction reveals. Open: existing-process trace or executable teaching adapter.

## 11. Noise: Fields and Possible Bodies

### Random_Noise_Types
Use the constrained point and placement slab. Reuse coordinates, distances, conditions and draws. Teach proposing, distance-checking and accepting/rejecting positions against a retained list. Supply point, slab and attempt counter. Carry a budgeted sampler; failed attempts do not prove impossibility. Distinguish admission from enforcement every update. Defer spectral/audio galleries to comparisons unless separately approved.

### Noise_Columns
Use three columns and independently pulsing orb. Reuse sine, elapsed time and generated geometry. Teach scalar driver and explicit shaft receiver; compare two drivers before changing the recipient. Supply column builder, local clock and marble. Carry source/use separation; stopping one clock need not stop the museum. Follow the actual shaft driver, without invented vertex erosion or loading.

### Noise_One
Use paired relief/colour rings and layered basin. Reuse scalar drivers, positions and colour mapping. Teach two receivers for one retained signed sample; compare offset geometry with remapped colour and inspect negative-value clipping. Supply ring construction, probes and sampler. Carry reusable mappings. Open: select directly referenced vertices; the basin's different resources are not identical octaves.

### Noise_Voxel
Use small voxel body and enlarged receiver. Reuse arrays, fields and conditions. Teach occupancy from explicit height bias and threshold; hold a sample while changing its classification. Supply cells, section screen and collision receiver. Carry binary volume separate from display. Display cuts need not alter occupancy; connected cells cannot certify access. Open: choose smaller array and receiver.

### Noise_6_Wall
Use the pink enclosure; freeze its finish. Reuse layered fields, colour mappings and Ribbon_Patterns_03's sampler. Teach signed-value colour mapping against the cloud material. Supply shader host, cloud sampler and room collision. Carry appearance/support distinctions; visible folds need not bear weight. Keep this 2D field distinct from Noise_Voxel's volume; dedicated Shaders deepens the supplied setup later.

### Noise_Inside_Noise
Use enclosing sphere and fixed direction witness. Reuse coordinates, functions and sampling. Teach p-to-q address transformation before querying the same field; inspect addresses before colour or relief. Supply offset fields, paired images, witnesses, receivers and collision reconstruction. Carry domain warping separate from receiving. Preserve fixed floor and doorway edges; the study is static between actions.

### Noise_Space_10
Use gold proposal and pink walking record. Reuse Trace positions, height sampling and surfaces. Teach sampling a chosen line through the actual triangle-height query; compare its profile with a walk at another body scale. Supply terrain collision, player tracking and recording. Carry profile and separate passage record; continuity cannot certify access. Open: cross-hall export remains proposed.

### Noise_Perlin_Simplex
Use paired cubes and arches. Reuse seeded fields and explicit receivers. Teach matched addresses and recorded differences with declared seed, scale and output mapping. Supply Perlin/OpenSimplex2 generators, arches and markers. Remove relief to inspect authored arch geometry. Carry comparison conditions into Shaders; preserve correlation versus stored state, without ranking one field as more natural.

### Lab_Path
Use optional dark-sphere corridor as a proposed reflection; its museum portal is inactive. Reuse one Noise encounter and source/receiver distinctions. Describe both felt view or movement and changed values, addresses or receivers; choose a return experiment. Supply corridor and sphere. Carry a specific unfinished comparison question. Require no new code or compulsory conclusion.

## 12. Shaders: What a Surface Answers To

### Shader_01_Shaping
Use graph panels to explain a circular mark. Reuse point distance, functions, colour mapping and garment UVs. Teach coordinate → distance → mask; expose centre/radius and compare sharp/soft edge. Supply panel/material binding. Check: move centre without changing radius; explain unchanged mesh. Carry mask + settings. Optional band/box; defer clock analysis. Open: learner binding; softened edge needs valid bounds.

### Shader_05_Patterns
Use tiled panels; return to floor/garment sampling. Reuse mask, transforms and array addresses. Offset/turn an asymmetric mark, then repeat 4×4. Teach floor = tile ID; fract = local coordinate. Check: turn one tile only. Carry mask + transform + address rule. Supply host; garden projection stays world-based. Open: binding/transfer adapter. Deferral: no new Shapes/Matrices halls.

### Shader_11_QueerRubber
Use ring and staged primitives. Reuse faceted sphere, curved garment, transforms, dot product and retained material. Compare one material on sphere/cube; teach rim from unit normal/view vectors in one frame. Check: predict changed rim with body/viewpoint changed and material fixed. Carry receiver-aware material. Supply geometry/vectors/lamps. Open: shared-material and hold controls absent; emission is not a lamp.

### Shader_09_FBM
Use noise panels and glass-covered basin. Reuse mask, weighted sums and Noise. Teach bounded octave loop; keep frequency/amplitude separate. Perturb mask boundary; compare zero contribution before adding time. Check: change fine detail while retaining broad form. Carry field + range. Supply base noise/material host and basin displacement/normals. Glass supplies support. Defer vertex teaching; coordinate warp optional.

### Shader_12_PinkExtravaganza
Use pink water, sagging sphere and plural body. Reuse Melencolia composition + retained form, repetition, rim and field. Compose limited known effects on supplied body; record choices. Check: make an alternate appearance with geometry fixed; distinguish transform/vertex/fragment. Carry material recipe. Supply lamps/geometry/deformation. Open: composition binding absent. No new compulsory syntax; pink alone is not a theory of queerness.

### Shader_10_ReactionDiffusion
Use green panel and apparently grown frost. Reuse retained form, Paint history and old/new state. Trace inputs; name what a changed mark must leave for next update. Check: explain clock restart versus state restore. Carry old-state → rule → new-state contract into CA. Supply panels/texture-reading excerpts. Host lacks previous-frame feedback; no promise of evolving chemistry or implemented transport.

## 13. Cellular Automata: Local Rules, Global Patterns

### CA_Introduction
Use held rule explorer and overhead history. Reuse lists, loops, conditions and Shaders' old/new-state contract. Teach reading three old values to write one next value; swap arrays after completing the row. Predict one cell; declare boundaries. Supply display, controls and wrapped-ring receiver. Carry synchronous engine with separate history. Open: choose readable rule table before bit encoding; rug symmetry is separate.

### CA_ElementaryRules
Use active/fading/empty volume and enlarged neighbourhood. Reuse synchronous updates and multidimensional addresses. Teach three-state transition table; trace one count through the supplied twenty-six-neighbour enumerator. Supply renderer and witness. Carry state transitions separate from colour; inactive fading cells can remain visible, so rendered, occupied and active counts differ. Follow the installed 3D study despite its historical title.

### CA_GameOfLife
Use Rule 30 desk, stepping tiles and screen. Reuse row engine, copied snapshots and colour mapping. Teach retained history with flat-image and piece-placement receivers; select earlier rows without rerunning. Supply desk, collision tiles, screen and placement interface. Carry history-to-space mapping; zero may mean no mark or no support. Open: learner connection remains proposed; actual Life follows in CA_BeyondBinary.

### CA_BeyondBinary
Use binary Life dish, fixed gold addresses and lamps. Reuse arrays, neighbour rules and receivers. Teach birth/survival from a supplied count with eight addresses explained; connect one fixed cell reference to lamp output. Supply dish, floor image and lamps. Carry state-to-object connection; patterns move across fixed cells, empty colour leaves solid floor, and lamps provide no feedback.

### CA_ExpandingSpace
Use decaying bridge and matching frieze; choose probe for repeatability. Reuse synchronous arrays, distances and outputs. Teach bounded health changes near supplied positions; separate neighbour recovery from colour/support receivers. Compare shared-old-state and in-place updates to expose scan order. Supply position interface, bridge renderer and collision thresholds. Carry body-to-field input; keep player tracking supplied.

### CA_SoftRules
Use matched concentration fields. Reuse graded state and synchronous buffers. Teach neighbour-difference sums combined with supplied local reaction; track two concentrations at one witness before interpreting texture. Supply displays, Gray-Scott reaction and one-time body seed. Carry exchange separate from reaction; diffusion differs from occupied-neighbour counts. Table and curved wall share state. Defer reaction equations to Soft Bodies.

### CA_AgentsCircuits
Use Rule 90 history and Sierpinski pyramid. Reuse row engine and retained history. Describe cell calculation versus copying smaller pieces; vary the row seed while holding the pyramid fixed. Supply explorer, enlarged floor history and pyramid. Carry procedural questions into Fractals without new syntax. Preserve resemblance as inquiry; Wireworld is an older proposal, not an installed circuit.

### CA_EdgeOfChaos
Use paired volumes and selected slices. Reuse arrays, synchronous updates and matched comparisons. Teach copied beginnings with one altered value; run identical updates and forcing schedules, recording maximum difference and differing-site count. Supply solver, slices and body-selected depth. Carry magnitude versus spread; inspect integer storage and display gain. Claim no universal critical threshold from the image.

## 14. Fractals: Rules, Scale and Room to Move

### Fractal_Recursion
Use nested-square desk and doorframes. Reuse functions, scale and geometry. Teach self-calls reducing size and remaining depth; trace base cases and compare one descendant with several. Supply lines, layout comparison and doorframe receiver. Carry bounded recursion; distinguish work budget, visual resolution and bodily clearance. Keep the actual square rule; branching rings may form a separate lesson.

### Fractal_RecursiveTrees
Use unfinished trunk and enlarged canopy. Reuse bounded recursion, vectors and rotations. Teach branch records with position, direction and length; generate two children and vary inherited length separately from count. Supply segments, generation controls and collision. Carry explicit parent/child construction. Mark the recursive teaching version as proposed comparison: the installed tree uses a generation queue, without biological growth claims.

### Fractal_CantorSet
Use stepped bars and pagoda. Reuse lists, endpoints and bounded repetition. Teach retaining first and last thirds into a new interval list; keep history separate. Compare increasing piece count with decreasing retained length. Supply bars, counters and collision. Carry finite replacement and complement; hiding old rows leaves the current set unchanged. Distinguish construction from limit. Open: endpoint pairs or centre/length records.

### Fractal_KochSierpinski
Use Koch desk and Sierpinski comparison. Reuse vectors, triangle corners and separate next lists. Teach equilateral segment replacement across retained segments; measure endpoint distance separately from route length. Supply lines, steps and comparison triangle. Carry segment-to-segments transformation; inspect midpoint-face replacement separately. Defer optional box counting. Keep this rule distinct from the later five-segment right-angle L-system preset.

### Fractal_MengerSponge
Use the cube's opening passages. Reuse 3D addresses, scale and recursive replacement. Teach retaining twenty cells from a 3-by-3-by-3 block across bounded levels; compute retained volume within fixed bounds and inspect the complement. Supply blocks, collision and flight enclosure. Carry subdivision; test holes against visitor size/abilities. Preserve the existing restriction on rebuilding while occupied.

### Fractal_GoldenSpiral
Use numbered towers, addition witness and rectangle study. Reuse arrays, accumulation and mappings. Teach finite Fibonacci recurrence with two height mappings; compare displayed heights against fixed-unit sums. Supply tower display, logarithm input/output and rectangle construction. Carry numbers separate from representation. Ask what further choices create spiral arcs; claim no universal natural recipe. Defer optional logarithm derivation.

### Fractal_Synthesis
Use Cantor desk and fixed block tree. Reuse replacement functions, parent records and stopping rules. Describe input, descendants, placement and budget without naming the form; predict the next step. Supply intervals, tree and history controls. Carry a precise recipe into L-systems; hiding records differs from changing construction. Require no new syntax. Defer editable cross-procedure comparison as future work.

## 15. L-Systems: Rules Grow Structure

### LSystems_Grammar_Lab
Use held/live editor drawings. Reuse lists, traversal and geometric replacement. Teach one rewriting pass from old string to new; vary production separately from turn angle. Supply turtle with stated commands, display and witness. Carry symbolic generator and interpreter contract; undrawn symbols may rewrite later. Open: visitor-authored productions are not exposed; the learner-editable connection remains proposed.

### LSystems_Growth
Use parametric tree's bracket steps. Reuse rewriting, directions and copied snapshots. Teach a stack: push copies position, orientation and length; pop restores them. Supply sentence, stepping witness and ordinary draw/turn dispatch. Carry explicit branching state; nesting differs from rewriting generations, and restoration covers only saved fields. Open: learner bracket handlers' connection to the interpreter remains proposed.

### LSystems_Grammars_And_Curves
Use gold-heading turtle and sideways blue reader. Reuse saved state and transforms. Teach replaceable heading-to-displacement interpretation; compare direct/reflected readings of one sentence and check segment lengths/connectivity. Supply synchronized readers, arrows and tube receiver. Carry interpreter variation; changed silhouette need not change branching. Open: transferring learner trace into tube_painting is proposed; current controls change ring sides on supplied geometry.

### LSystems_Architecture
Use dungeon centrelines and BUILD. Reuse turtle segments, offsets and collision distinctions. Teach an orthogonal path-to-footprint rule with stated width and open ends; test bodily passage. Supply wall builder, junction handling and collision with explicit inputs. Carry usable corridor footprints; duplicate room records need not create distinct rooms or uses. Defer arbitrary-angle joins and editable grammars.

### LSystems_Competition
Use amber/blue stems sharing one grammar. Reuse rewriting, updates and resources. Teach two requests consulting/consuming one mutable record; record state before each and reverse turn order. Supply forest kernel, soil display and specimens. Carry conditional execution and explicit schedule; unequal outcomes need not mean unequal instructions. Open: shared-snapshot comparison is a new experiment; claim no ecological equilibrium.

### LSystems_Living
Use held tree's Depth rounding steps. Reuse parameter records, rewriting and mappings. Teach bounded generation, angle and fork conversion; retain the design record for a planted specimen. Supply builder, witness and local planting interface. Carry reproducible design with visible vocabulary limits; DNA naming does not establish biology. Open: distinguish local specimens from DNA export; cross-hall transport remains proposed.

### LSystems_Shape_Grammars
Use fixed cubes and strip canopy. Reuse face lists, transforms and saved configurations. Specify selected face indices and an inset/extrusion sequence; predict resulting connections and inspect the inherited diagonal. Supply builders with explicit inputs/outputs, including curved strips. Carry a shape recipe; some desired forms require new operations. Open: editable learner recipe and preview remain proposed.

### Assemblage_Same_Desire
Use textile's retained 144 samples. Reuse draws, thresholds and interpreter separation. Teach two mark dictionaries for one binary decision list; compare apparent paths as diagonals become bars or blocks. Supply textile, witness and floor receiver. Carry sample/decision/mark separation without new syntax; perceived routes need not be checked or collidable. Open: sharing the earlier generator's record remains proposed.

## 16. Procedural Generation: Rules Build Worlds

### PG_Genetic_Evolution
Use six boxes under changing TARGET. Reuse design records, lists and measurement. Teach explicit candidate scoring and ranking without rebuilding the population; inspect ignored features and compare the leader with personal preference. Supply primitive builder, display and reproduction kernel. Carry generation/evaluation separation. Use the approximate estimator honestly; exact union volume and learner-selected witness retention are not installed.

### PG_Space_Colonization
Use three attraction points and cancelling sideways requests. Reuse vector operations and branch records. Teach summing assigned unit directions into a fixed-length child step; compare later site eligibility. Supply attraction display, nearest-site assignment and segment renderer. Carry a request-driven branch rule; consulted coordinates are not simulated forces or light-seeking biology. Defer nearest-site search to a separate follow-up.

### PG_Branching_Growth
Use nearest-attraction branching. Reuse direction accumulation and distance comparisons. Teach nearest-eligible search; retain parent and target index before making a fixed-length step. Supply attraction layout, renderer and stepped clock. Carry growth provenance; explain coincident children before jitter or pulsing, distinguishing record count from distinct positions. Open: shared attraction concepts exist, but transferring the learner's record remains proposed.

### PG_Percolation_Network
Use face-touching versus corner-touching cubes. Reuse grid neighbours, occupancy and synchronous updates. Teach six-neighbour transmission with flow state separate from random occupancy; retest the retained lattice from another source. Supply cube display, source and stepping. Carry local propagation; distinguish visible contact, permitted adjacency and global reachability. Infer no universal threshold from one finite seeded lattice.

### PG_Caves_Mazes
Use cave carving dots and maze comparison. Reuse walks, grid addresses and occupancy. Teach clearing footprint and headroom around retained centres; vary clearance, then test bodily access. Supply cave renderer, collision builder and backtracking demonstration. Carry path-to-empty-volume construction; never join separate walkers' dots into a fictitious trail. Defer optional maze implementation; introduce visited record and stack if chosen.

### PG_Sculpted_Forms
Use falling cubes becoming a frozen blocky surface. Reuse frames, voxel addresses and faces. Teach local-frame centre sampling, declared neighbourhood marking and exposed-face submission. Supply bodies, sampling control, mesh assembler and collision. Carry event-to-surface reconstruction with actual enlarged dimensions; rotation and contact shapes are omitted. Keep dome cuts as comparison; defer Boolean machinery.

### PG_Mirrored_Patterns
Use mirrored cellular field and network comparison. Reuse array addresses, transforms and retained inputs. Teach reading one region into a separate reflected result; check centre rows/columns. Supply field, network, tunnel surfaces and graph statistics. Carry explicit reflection boundaries; repeated image values differ from repeated access. Network collision is disabled. Defer formal graph measures; do not claim traversability.

## 17. Soft Bodies & Morphogenesis: Matter That Finds Its Shape

### SoftBodies_Soft_Body_Deformation
Use pinned jelly cube. Reuse mesh connectivity, forces and bodies. Teach attaching supplied subdivided mesh to solver, retaining its reference and pinning one point; compare resistance, damping and pressure on one deformation. Supply mesh generator, solver and hand-contact rig. Carry explicit deformable attachment; tracked hands need not receive reaction. Open: choose understandable vertex selection, not an unexplained index.

### SoftBodies_Cloth_Physics
Use hanging strips and tension membrane. Reuse coordinates, conditions and soft-body setup. Teach vertex-selection functions for upper edge versus corners on a supplied open sheet. Supply cloth, solver and support display; use known generated coordinates. Carry boundary-condition recipe; disappearing gantry does not remove pins, and an open surface encloses no inflatable volume. Compare loads between retained anchors.

### SoftBodies_Carusell
Use revolving ride. Reuse rotations, time steps and constraints. Teach an anchor driver in radians per second; stop or reverse it while retaining hanging-body state. Supply hub, hinges and solver. Carry prescribed motion versus simulated response; bodies cannot alter commanded hub rotation. Open: the reduced anchor connection remains proposed, with one-way authority explicit.

### SoftBodies_Obsticals
Use breathing room's fixed wall edges. Reuse sine, scalar receivers and pinned boundaries. Teach a bounded panel's pressure driver; hold phase while the solver settles, then inspect bodily clearance. Supply wall mesh, solver and support. Carry signal-to-force input separate from solver state and direct vertex displacement. Open: connecting the learner's driver to both full walls needs an adapter.

### SoftBodies_Obsticals_Part2
Use twelve falling-body cells and High Drag example. Reuse settings, collision geometry and repeatable setups. Teach a two-case comparison naming shared conditions and one changed factor; record a concrete consequence. Supply bodies, reset, solver and measurement support. Carry controlled experiment record; seeded construction does not guarantee identical cross-machine physics. Open: choose observable and supplied recorder.

### SoftBodies_Playground_of_Joy
Use volume-feedback body and frozen glass vessel. Reuse retained positions, faces and physical measurements. Teach copying current solver vertices into a static mesh with unchanged connectivity. Supply custom vessel solver's readable positions and mesh assembler; do not assume identical Godot access. Carry snapshot and conditions; compare lost motion with bounding-box volume proxy. Freezing closed geometry creates no opening.

### SoftBodies_Affect_Theory_Visualization
Use radiolaria row. Reuse primitives, seeded populations and effects. Compare two forms' recognition cues; vary one while retaining the construction seed. Supply geometric families, rotation and particles. Carry deliberate apparent-life composition without new syntax; resemblance, interaction and mechanism remain separate, potentially unresolved questions. COLOUR rebuilds geometry, so pin a seed before treating it as palette-only.

### ProceduralGeneration_Reaction_Diffusion_Systems
Use held concentration grid. Reuse CA_SoftRules' two-field buffers, neighbour differences and time steps. Teach Gray-Scott reaction, feed and removal terms; combine with known diffusion. Supply display, stable stepping and initial field. Compare one beginning across rules or one rule across seeds. Carry complete update with separate contributions. Defer numerical limits; claim neither Turing's original equations nor an organism.

### Topology_Entropy_Morphogenesis
Use folded field with S, NOISE, LEVEL and RESOLUTION. Reuse sine fields, thresholds and mappings. Teach explicit control returning named frequency, noise and cut-level values; compare bundled gesture with independent choices. Supply field generator, surface extractor and collision. Carry inspectable controls; entropy is a source name, not a measurement, and openings need clearance tests. Defer extraction to Isosurfaces.

## 18. Isosurfaces: Implicit to Explicit

### ISO_Introduction
Use blue specimen's pink triangle edges. Reuse sampled fields and faces. Teach a separate level-classification function; retain scalar magnitudes for extraction. Hold a comparison; change level before sample spacing. Distinguish field, boundary and finite approximation. Supply extractor, display and collider builder. Carry retained samples and comparison. Open: study host; one cell or small volume.

### ISO_LookupTable
Use fifteen-case display. Reuse classification and interpolation; calculate and mark one crossing edge. Change values without changing classifications; observe crossing motion with unchanged connections. Supply corner cage, case table and triangle display. Carry reusable edge-crossing function. Defer bit-mask construction to another short lesson if it obscures interpolation.

### ISO_ShapesGallery
Use chair joins and cup hollow. Reuse field functions and extraction; compose supplied box, cylinder and ring fields into a vessel with removable interior. State position-in, value-out contracts. Distinguish recipe changes from sampling or level. Supply primitive fields, extractor and comparison display. Carry vessel expression. Open: whole cup recipe or hollow first.

### ISO_TorusGyroid
Use torus opening and continuous gyroid fold. Reuse periodic functions and field composition; change coordinate scale, retain comparison, then add one intrusion. Teach spatial repetition versus copied objects; opening versus clearance. Supply gyroid expression, extractor and straight capsule probe. Carry controlled spatial frequency. Open: walking alongside the probe's single-segment test.

### ISO_Sculpting
Use joining deposits in sculpting volume. Reuse lists, positions and fields; record brush position, size and add-or-erase operation. Evaluate history in order; reverse two operations. Teach erase versus undo and history-dependent form. Supply input, brush field and extractor. Carry editable spatial history. Open: history limit and what happens when reached; retain sampling limits.

### ISO_FlatTerrain
Use column crossing terrain once, then folded surface repeatedly. Reuse noise and coordinate functions; combine height minus vertical position with supplied interior field. Teach height field versus volume and multiple crossings. Supply column sampler, noise source and extractor. Carry terrain with an interior. Treat second terrain as contrasting composition, not a matched one-parameter control.

### ISO_PortalLandscape
Use amber landscape and held copy; preserve a ridge while seeking an opening. Reuse terrain fields and weighted sums. Add masked contributions individually; predict affected regions and inspect above and below. Supply contributions, sampling, extractor and comparison. Carry an explainable opening recipe toward route testing. Open: first two terms; defer full five-term ladder.

### ISO_Caves
Use landscape edge and accessible cave opening. Reuse field boundaries, transforms and collision; vary burial of a supplied ring without resizing it. Trace ground intersections. Teach hole versus entrance versus usable route. Supply terrain recipe, extractor and player. Carry entrance conditions and bodily clearance. Open: accessible comparison location; neighbouring cave uses another recipe.

### ISO_CaveGeneration
Use generated cave beside ring-built tunnel. Reuse noise, sampling and enclosure; compare coordinate scales with domain and level fixed. Predict changed passages or ridges. Teach noise's physical scale and distinct cave constructions. Supply noise evaluator, extractor and paired display. Carry reproducible recipe. Supply controlled study: existing specimens change several settings together.

### ISO_AnimatedNoise
Use one block address filling and emptying. Reuse grid addresses and time-dependent functions; record occupancy while noise offset changes. Teach fixed-location values versus persistent moving particles. Supply noise sampler, grid display and clock. Carry a history tied to an address. Use occupancy artifact as source; older mesh-animation tutorial describes another construction.

### ISO_Metaballs
Use neck joining lobes before centres touch. Reuse distance, lists and accumulation; sum supplied falloffs at each sample. Arrange sources as pair and ring; distinguish source position, reach and visible lobe. Supply falloffs, extractor and held-copy display. Carry source list and summed field. Open: one finite, well-behaved kernel; retain others for comparison.

### ISO_ImplicitModeling
Use smooth join without matching bodily resistance. Reuse distance fields and extracted meshes; compose one two-part field for proposed mesh and raymarch comparison. Teach field versus representation and rendering versus collision. Supply views, normal estimation and separate collider builder. Carry one editable description. Current hall partly relies on remembered specimens; paired study remains proposed.

### ISO_RhizomeBody
Use a walk through rhizome body and attempted alternate return. Reuse surfaces and clearance; sketch encountered junctions, passages and unconfirmed connections. Predict how narrowing changes access while a drawn edge remains. Supply chamber generator, shell extraction and player. Carry route sketch distinguishing planned relations from usable passages. Open: paper or project record; no existing recorder assumed.

## 19. Boolean Surfaces: CSG as Composition

### Boolean_Verbs
Use box-and-sphere seam, remainder and cavity. Reuse fields, meshes and transforms; compare union, intersection and ordered subtraction with operands fixed. Include empty intersection; reverse subtraction. Supply CSG pair, display and collision comparison. Carry reusable two-operand construction. Existing differently sized exhibits are not controlled comparisons. Open: closing bench or prepared study host.

### Boolean_Gallery
Use four variants in two walking orders. Reuse CSG and lists; order configurations from one family and choose when operands remain visible. Teach geometry changes versus explanatory presentation and authored defaults. Supply artifact factory and stands. Carry a deliberate comparison. Keep existing ordering disagreements as material; no registry repair.

### Boolean_Works
Use burrow, raised cavern and dark concave egg. Reuse Boolean operations, transforms and collision; position a shared cutter to open a small room. Test entry, withdrawal and sightline. Then change the same cavity's depth cues. Supply walls, player and material comparison. Carry separate choices about geometry, contact and appearance. Keep two short lessons.

## 20. Swarm Intelligence: Where Coordination Lives

### SwarmIntelligence_PhysarumColony
Use trails persisting after agents pass. Reuse grids, fields and movement; compare three trail samples and deposit at each new position. Compare decay choices. Teach shared environmental memory without claiming biological optimality. Supply small repeatable population, renderer, diffusion and fixed anchors. Carry readable trail memory. Defer automatic anchor tour.

### SwarmIntelligence_FlowFields
Use arrows to predict agents' turns at one address. Reuse grid lookup and steering; author directions that curl around one region and guide through another. Teach shared infrastructure versus neighbour consultation. Supply agent display and steering integrator. Carry purposeful vector field into flocking. Defer obstacle routing and cost propagation to a separate lesson.

### SwarmIntelligence_Boids_Algorithm
Use ringed boid's arrows and neighbours lost across box boundary. Reuse steering and position lists; compute separation, mean heading and mean position, then weight them. Teach neighbour selection and flocking limits: alignment supplies neither room nor body avoidance. Supply renderer, update loop and boundary policy. Carry local behaviour. Open: split selection from force combination.

### SwarmIntelligence_Agent_Based_Modeling_ABM
Use agent replacement retaining trails, then full reset. Reuse state records and fields; give a foraging agent two states with different sensing and deposition. Compare the same evaporation under both restarts. Teach individual state versus shared history. Supply movement loop, field display and repeatable start. Carry explicit transitions into outward and returning travel.

### SwarmIntelligence_Ant_Colony_Optimization
Use outward and returning ants' different traces. Reuse states and fields; add home and food channels to the small colony. Switch read and write channels on arrival. Teach state-dependent communication and deposition. Supply destination detection, movement and two-colour display. Carry two-channel foraging; do not claim demonstrated shortest-tour optimisation.

### SwarmIntelligence_Particle_Swarm_Optimization
Use CONVERGE/SPREAD and repeated starts. Reuse state, vectors and scores; store best position separately from score. Combine motion toward personal and shared memories. Teach objective-dependent best; reconsider memory when objective changes. Supply repeatable population, landscape and motion display. Carry candidate with scoring rule. Teach fixed objective first; defer changing novelty archive to second comparison.

### SwarmIntelligence_Swarm_Intelligence_Algorithms
Use feeding or birth, population count and support record. Reuse events and histories; distinguish local births and losses from replenishment. Explain one recovery within recorded evidence; name unknowns. Supply ecosystem, event feed and display. Carry enabling interventions toward evolution; continued activity does not prove autonomy. Open: construct an account or annotate existing support record.

## 21. Machine Learning: What Changes, and Why?

### ML_Evolution
Use energy-conditioned reproduction beside scored creatures. Reuse agent state, inheritance and randomness; encode movement as a list, copy with bounded mutation and choose selection rule. Teach variation, evaluation and replacement separately from untargeted survival conditions. Supply body, trial arena and generation display. Carry explicit candidates and scores. Open: small recipe with observable short-trial consequence.

### ML_Gradient_Landscape
Use points fitting identical observations under different losses. Reuse functions and scores; build line predictor, sum one loss and estimate slope from nearby parameter values. Update against slope; compare another loss. Teach prediction, evaluation and update separately. Supply observations and landscape renderer. Carry inspectable descent. Begin with one parameter; defer slope-and-intercept landscape.

### ML_Classification
Use stationary point recoloured as centres move. Reuse distance, lists and averages; alternate nearest-centre assignment with centre updates. Teach constructed clustering versus supplied class labels. Supply point cloud, colours and empty-group policy. Carry adjustable clustering loop. Open: dataset small enough for one hand-calculated update; keep supervised classifiers secondary.

### ML_Neural_Networks
Use passing activity and retained connections. Reuse weighted sums, composition and loss; build two-layer forward calculation from weight lists. Trace one changed weight into prediction; compare held-out result with training error. Teach activations versus weights and fitting versus generalisation. Supply samples, drawing and explained training-step interface. Carry forward model. Supply repeatable host; exhibit controls cannot restart training.

### ML_Perception
Use moving window crossing uniform patch and shape edge. Reuse nested lists and weighted sums; apply supplied Sobel kernel locally, then traverse image for edge strengths. Teach intensity differences versus object interpretation; find an ambiguous fragment. Supply image, boundary policy and paired display. Carry interpretable feature operation. Keep fixed detection distinct from learned CNN recognition.

### ML_Sequence_Memory
Use tokens and slab retaining earlier height. Reuse state updates and weighted sums; write linear gated recurrence separating retained state, admitted input and exposed output. Compare histories sharing the last token. Supply token input, attainable gate handles and slab display. Carry inspectable memory. State hand-set simplification; trained LSTM requires further operations.

### ML_Generative
Use generator/discriminator exchange with scripted losses. Reuse random inputs, forward models and losses; propose small candidate generator judged against reference samples by fixed critic. Teach generation versus training; name both states needing adversarial updates. Supply samples, comparison display and inspectable critic. Carry explicit evaluator and reference choice. Open: later real alternating training.

### ML_Synthesis
Use raised point beside low neighbour. Reuse data summaries and thresholds; calculate score, retain coordinate contributions and compare total with threshold. Teach reference population, scaling and decision rule versus judgement. Supply sample, display and zero-spread convention. Carry flagged case for inquiry, preserving omissions. Open: change reference sample or only threshold first.

## 22. Graph Theory: What Connections Permit

### GT_Foundations
Use tide and diver visiting the same lamps. Reuse lists and state; introduce vertex identifiers and neighbour lists. Select oldest or newest pending entry to teach breadth-first versus depth-first traversal on a fixed graph. Supply lamps and step control. Carry connection record independent of visiting order. Defer bridge problem to optional application.

### GT_Layout
Use settling network; identify edges by endpoints. Reuse adjacency and spring forces; retain vertex positions and velocities, attracting only along edges. Compose another readable layout. Teach topology versus drawing. Supply repulsion, edge renderer and integrator. Carry unchanged connections across layouts. Keep graph small enough to check every relation; defer efficient layout algorithms.

### GT_Pathfinding
Use spark's replacement route after a stone disappears. Reuse traversal and references; store predecessors during unweighted breadth-first search, then reconstruct backwards. Teach search versus resulting path; handle unreachable destination. Supply stone graph, availability input and traveller display. Carry route record and explicit no-route result. Defer weighted costs and A*.

### GT_Network_Analysis
Use conspicuous vertex and fictional evidence network. Reuse edge lists and counting; record directed, source-labelled relations and count incoming/outgoing edges. Remove a relation, then move the drawing; distinguish changed counts from presentation. Supply curved-line renderer and layout controls. Carry traceable measures without equating prominence with importance. Open: filtering before or after first count.

### GT_Connectivity
Use directed routes and attempted returns before trusting colours. Reuse adjacency and traversal; intersect reachability from one start in original and reversed graphs. Teach mutual reachability; compare with supplied Tarjan traversal. Supply small graph and arrows. Carry checked component; leave route cost and bodily access open. Defer Tarjan's low-link invariant.

### GT_Spanning_Trees
Use yellow candidate joining groups or closing a cycle. Reuse weighted edges and reachability; sort edges, accepting only disconnected endpoints. Use traversal for cycle checks. Restore one rejected edge for a stated alternative route. Supply display and stepping. Carry objective-based tree and deliberate redundancy. Defer union-find until repeated reachability becomes useful.

### GT_Flow
Use junction excess and push/relabel choice. Reuse directed graphs and state; implement one push bounded by excess and residual capacity, including reverse adjustment. Teach capacity, flow, excess and algorithmic height separately. Supply network, height-selection rule and stepped display. Carry revisable allocation into matching. Open: example requiring rerouting; current animation may not expose it.

### GT_Matching
Use valid pair leaving outer points waiting; compare spokes-first order. Reuse edges and occupancy checks; write greedy pairing and replace one edge with two along an explicit augmenting path. Teach validity versus maximum size. Supply ring-and-spokes graph and stepping. Carry revisable pairing. Defer weighted assignment, preferences and full blossom contraction; exhibit does not implement blossom.

## 23. Foundations Crisis: The Limits of Formalization

### Euclid_Parallel
Use fifth postulate, parallel lines and triangle in flat coordinates. Reuse points, lines and angles; name construction rules and distance convention before checking corners. Distinguish assumption, example and proof. Supply plaque, lines and angle readout. Carry triangle for another model. Open: construct in prepared study or document existing triangle; neither proves an axiom.

### NonEuclidean_Spaces
Use plane, sphere and disk triangles; predict angle sums. Reuse coordinates and angles; pass endpoints to geodesic samplers, display paths and measure corners with model-aware routine. Teach model-dependent straightness versus room projection. Supply samplers, angle routine and display. Carry explicitly different geometric rules. Do not substitute a warped Euclidean grid.

### Russell_Paradox
Use IN/OUT contradictions at membership workbench. Reuse Boolean conditions and filtering; write two-case check, then filter a supplied finite domain. Teach testing available objects versus assuming every description creates a set. Supply examples and display. Carry membership with explicit domain into proof questions. Restricted construction does not implement arbitrary set theory.

### Godel_Incompleteness
Use jammed sentence machine as a question about evidence. Reuse functions, lists and contradiction; inspect finite proof candidate, then compare bounded unsuccessful search. Teach checking versus searching and failure versus impossibility. Supply tiny rule system, checker and machine. Carry scoped proof claims. Open: formal example and careful incompleteness account; sculpture is no theorem demonstration.

### Escher_Impossible
Use staircase marker's apparent ascent. Reuse coordinate differences and closed paths; sum height changes between tread centres around full circuit. Change viewpoint. Teach projection versus constructed geometry while preserving impossible image's pleasure. Supply treads, marker and comparison sculptures. Carry whole-circuit check. Open: another small construction; do not treat staircase as incompleteness proof.

### Brouwer_Intuitionism
Use empty next position and chosen binary beads. Reuse lists and search; retain own prefix and query for a position witnessing one. Teach finite evidence versus every possible continuation; missing witness does not establish negation. Supply choice controls and display. Carry unfinished construction. Keep introduction distinct from blanket rejection of proof by contradiction.

### Florensky_Paraconsistent
Use OPEN/CLOSED doorway reports and unsupported alarm. Reuse records and conditions; retain source-tagged reports independently and query both. Teach conflict storage versus inference and support versus truth. Supply ghost doors and declared consequence table; test unrelated conclusion. Carry sources and permitted consequences. Open: minimal table and scope; Florensky reflection supplies neither quantum superposition nor general logic.

### Crisis_Synthesis
Use formula and sentence across label, strip and wall. Reuse strings, lists and timed display; give one original statement three presentations. Compare scale and rhythm with evidential warrant. Supply sentence apparatus, typography, surfaces and controls. Carry accountability questions into QFEP. Open: sentence tied to learner's construction; formula remains a research proposal.

## 24. QFEP Laboratory: The Formula Made Interactive

### QFEP_Introduction
Use different four-axis arrangements with similar totals. Reuse functions and records; implement arithmetic while retaining inputs, including constant change, beside result. Teach weights, dependencies and scalar compression. Supply controls, reference display and kept outline. Carry revisable QFEP calculation and evidence questions. Open: formula's introductory scope; authored reference names confer no evidential support.

### QFEP_F_Term
Use opposite dominant bits with equal uncertainty; switch predictor on unchanged sample. Reuse loops and scores; count constant predictor's mistakes over retained bits. Teach uncertainty, realised mistakes and expected error separately. Supply seeded source, binary entropy and display. Carry revisable predictor with fixed evidence. Open: derive or supply expected error; no variational-free-energy measurement claim.

### QFEP_E_Term
Use shared branch and closure removing endings. Reuse trees and recursion; author branching choices, count leaves and retain closed branch. Add an undrawn alternative. Supply fan renderer and equal-weight logarithm. Teach probability assumptions; reopening diagram cannot recover lost history. Carry revisable possibility structure. Open: useful example; more leaves imply no moral conclusion.

### QFEP_Lambda_Spectrum
Use ordered interval, moving forms and shifted lit strip. Reuse spatial composition and weights; propose another recommendation, keeping geometry visible. Test obstruction and alternatives. Supply forms, lighting control and player. Teach weighting, invitation and available route versus universal measurement. Carry tested recommendation. Open: change strip only or also author second viable route.

### QFEP_Phi_Term
Use signed rail crossing zero beside independent pattern. Reuse samples and arithmetic; subtract entropy readings, retain interval and optionally calculate rate. Compare opposite weights. Teach change, rate, weight and receiver; avoid political meaning from direction. Supply readings, time display and rail. Carry weighted change with intended use. Open: reading source, never decorative pattern.

### QFEP_Edge_Of_Chaos
Use paired patterns over equal simulated duration. Reuse grid updates and time stepping; track chosen feature at two update intervals. Distinguish model parameters from numerical execution. Supply Gray-Scott update, common initial state and displays. Carry recorded comparison conditions. Open: intervals and stopping rule showing meaningful difference; lambda remains authored choice, not universal edge band.

### QFEP_Sandbox
Use cut connection, moving handle and reactor receiving restored present value. Reuse function inputs and state; map control to a small receiver, then interrupt and restore connection. Teach receiver mapping versus held input. Supply handle, light body and connection indicator. Carry rewritable consequence. Open: fully inspectable receiver; retain reactor comparison.

### QFEP_Synthesis
Use stopped pressure pulse and continuing motion. Reuse forces, constraints and mappings; propose separate stiffness and damping controls, retaining deformation trace. Teach resisting deformation versus losing motion; drive versus response. Supply soft-body solver, pressure source and trace display. Carry mechanical intention, observed response and questions about remaining permissions. Expose existing lambda/phi coupling across coefficients when proposing teaching mapping.

## 25. Post-Crisis: Applied Limits

### CriticalAlgorithms_Algorithmic_Bias_Visualization
Use fixed compression while viewpoint changes, then compress labels. Reuse interpolation and indexed positions; compose two arrangements preserving an obscured distinction. Teach representation versus view through authored spatial analogy. Supply labels, handle and comparison frame. Carry readable distinctions. Open: labels respecting internal differences; this is no measurement of trained embeddings.

### CriticalAlgorithms_Applied_Ethics
Use head chair and circle without persuasive colours. Reuse generated positions and transforms; arrange identical chairs at equal scale in two plans. Trace approach and sightlines. Teach geometric invitation versus participation. Supply chairs, room boundary and view markers. Carry explicit access question. Open: participant activity to test; equal count and scale do not establish equal authority.

### SpeculativeComputation_Paraconsistent_Engineering
Use RESOLVED branch and named stump. Reuse sourced reports and storage/inference distinction; retain both reports beside decision, action and reason. Identify evidence for revision. Supply sculpture, report input and comparison. Carry revisable decision with alternatives. Open: conflict with known time, source and subject; neither overlapping meshes nor unresolved disagreement establishes a logic or virtue.

### SpeculativeComputation_Situated_Computation
Use assigned verdicts and delayed/held witness images. Reuse records, transforms and time; retain image reference, source, exposure time and pose. Compare two accounts. Teach present view versus earlier record. Supply cameras, pickup and frame capture. Carry located observations; authored confidence is no earned evidence. Open: annotation now or collective hall.

### SpeculativeComputation_Collective_Knowledge
Use facet's source node and commons table's authored categories. Reuse indexed, sourced records; assemble contributions retaining source/version. Count arrivals separately from contributors. Supply facet builder, arrival stream and table. Teach accumulation's limits for knowledge and authority. Carry shared form with revisable rule. Open: rule participants can change; automatic stream alone proves no shared authority.

### SpeculativeComputation_Rhizome_Network
Use cave walk and alternate return before grower controls. Reuse graphs, fields and clearance; propose one connection between chosen chambers, then inspect extracted passage in prepared study. Teach edge versus bodily route; rootless growth retains boundaries and uneven access. Supply chamber fields, shell builder and player. Carry tested relation. Open: feasible chamber pair.

### AdvancedLaboratory_Lab_Equipment_Simulation
Use amber hand movement, then rerouted bond with joints fixed. Reuse local coordinates, edges and constraints; edit one position and endpoint separately, comparing original. Pull neighbouring doll or chair. Teach pose versus connectivity, drawn versus constraining relation in separate beats. Supply handles, bond renderer and persistence. Carry same saved learner body and connections across exit.

### PostCrisis_Synthesis
Use revised amber body, blue starting arrangement and ledger's omissions. Reuse positions, connections and records; extend prepared record to retain earlier and latest arrangements, optionally annotated. Supply reconstruction renderer and file persistence. Teach versioned recovery versus lived gesture. Carry two recoverable arrangements and desired next body or passage. Open: final construction or independent-work proposal.
