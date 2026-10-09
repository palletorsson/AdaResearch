"""One-time assembly of an authored plan. Refuse to replace saved editorial work.

Existing curated choices supply hall context, not artifact-name inference. The
placements and opening contracts below are editorial proposals. No lesson edits.
"""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
def read(p): return json.loads((ROOT / p).read_text(encoding='utf-8-sig'))
def digest(b): return hashlib.sha256(b).hexdigest()
def dump(p, data): p.write_text(json.dumps(data, indent=2, ensure_ascii=False)+'\n', encoding='utf-8')

# Each sequence has a capacity, a continuing object, and an exit demonstration.
SEQUENCES = {
'primitives': ('Build and describe a body from positions, records and faces.', 'Point → two endpoints → retained trace → grid copy → face list → generated family.', 'Build a different small arrangement with a reusable generator; explain position, reference, face and resolution separately.', 'Finish Trace → Grid before expanding the untested mesh lessons. Keep the last composition free of new syntax.'),
'transformation': ('Write a changing rule with time, branches, events and retained state.', 'The made body gains a clock, route, pivot, hierarchy and reset.', 'Make a bounded motion and reset it twice; explain what is recomputed and what is retained.', 'Sine is a range-and-period preview here. Its circular derivation belongs in Waves. Do not require riding physics to learn interpolation.'),
'array_tutorial': ('Address and change many independent things.', 'Known point/mesh instances become a row, plane, volume and timed score.', 'Change one stored value and one object through their indices, preserving unrelated entries; explain aliasing.', 'Array has no tutorial. This missing foundation precedes sophisticated 3D storage. Split the row and plane into two beats within the hall.'),
'color': ('Separate a calculated value, its receiver and its retained state.', 'A colour function becomes a palette object; addressed colour becomes a painted surface.', 'Create two independent palettes, advance one, and apply a returned colour to a new receiver; explain the surface-painting states.', 'PointBody already introduces a class. Palette deepens methods and owned state; do not call it the first class. Reflection on skin is not reducible to RGB.'),
'tiling': ('Separate a source from its repeated interpretations.', 'A known array and palette become a motif, lookup rule and surface recipe.', 'Keep the motif fixed while changing one lookup; predict a 4×4 sample and a larger result.', 'Three ribbon tutorials are missing. One shader lookup can be supplied as a preview; shader execution is taught in its own sequence.'),
'change': ('Distinguish a difference, a rate and an accumulated change.', 'The line difference and trace return as measurements of a sampled curve and a followed field.', 'Compare finite differences and finite sums at two step sizes, with units and a retained source.', 'Field-following assigns a prescribed velocity here. Forces later stores velocity and changes it through acceleration.'),
'forces': ('Connect position, velocity, acceleration and applied forces.', 'A moving body becomes a state update with mass and a declared receiver.', 'Compare the same timed force under two masses; reset and distinguish force, velocity assignment and engine integration.', 'Reintroduce vector operations through use. A force law is a model; a Godot solver is a supplied implementation with its own contract.'),
'formfinding': ('Change parameters by a criterion rather than draw a desired result directly.', 'A body or curve becomes a candidate, evaluated and revised under constraints.', 'Change a step size or boundary and distinguish convergence, a limit and a failed search.', 'Annealing needs a small bounded-draw preview before Randomness. Keep current state, best state and evaluator separate.'),
'wavefunctions': ('Read periodic change in position, time and coupled state.', 'The motion rule becomes a sampled signal, wave and finite composition.', 'Predict amplitude, period and phase changes; combine two known signals and explain the sampling limits.', 'This sequence owns the unit circle and sine derivation. Sound output, spatial clearance and wave coupling are distinct receivers.'),
'randomness': ('Make chance reproducible and examine distributions and consequences.', 'A rule and seed produce samples, walks, populations and feedback.', 'Replay a saved recipe; change draw order and compare distributions without claiming identical outcomes across engines.', 'A short random call can precede this sequence. Here teach the generator, draw order, distributions, sampling policies and inference.'),
'noise': ('Sample related values and distinguish the field from its display.', 'The sampler drives points, occupancy, skin and route comparisons.', 'Hold sample positions fixed while changing a generator setting; compare neighbour differences and preserve original values.', 'Do not infer continuity from smooth colour. Spatial spacing, threshold and domain warp are separate choices.'),
'shaders': ('Run a small spatial rule for every fragment.', 'Known distance, colour, tiling and noise rules move onto a surface.', 'Write a distance mask, repeat its coordinates and compare a stateless fragment rule with an explicitly supplied feedback image.', 'Use The Book of Shaders as an inspiration for operations, translated to Godot. GPU feedback storage is not automatic. Four lessons are missing.'),
'cellularautomata': ('Give a local rule a stored state and a generation boundary.', 'The grid gains current/next buffers, neighbours and recorded generations.', 'Update a tiny known state by hand, then match it in code; reverse traversal order and preserve the result.', 'Hall names do not certify algorithms. Verify actual installed rules before calling a specimen elementary CA or Life.'),
'fractals': ('Describe repeated construction with a stopping rule.', 'Known lists and functions become recursive branches and replacement histories.', 'Predict growth at a small depth and impose a node budget; distinguish recursion depth from physical size.', 'A visible fractal is not evidence of infinity. Keep base cases and finite budgets explicit.'),
'lsystems': ('Separate rewriting a description from interpreting it.', 'A word, stack and recipe construct a branching body.', 'Rewrite a short word in parallel; copy/restore turtle state at a branch and inspect the resulting connections.', 'Dictionaries, strings and stacks need explicit small introductions. Shape grammar is currently a missing lesson, not a prerequisite for all growth.'),
'proceduralgeneration': ('Keep the representation, evaluator and construction rule visible.', 'Candidate records and branch/voxel records generate selections and passages.', 'Change a fitness criterion or growth condition and explain which candidates or connections it excludes.', 'Add minimal adjacency at the first network use; Graph Theory later formalizes traversal. Full graph theory need not be moved forward.'),
'softbodies': ('Distinguish a deformable state from the constraints applied to it.', 'Mesh vertices and forces become a constrained sheet, pressure body or coupled field.', 'Hold material and load fixed while changing pinned boundaries; explain solver response versus an authored animation.', 'Teach a bounded constraint experiment; do not reproduce the full cloth solver in the first lesson.'),
'isosurfaces': ('Turn sampled scalar values into a chosen boundary.', 'A field and a threshold produce a surface and a clearance test.', 'Classify one cell, interpolate one crossing, then vary level without mutating samples.', 'Extraction tables are supplied first. Continuous description, finite samples and walkable collision remain distinct.'),
'boolean_surfaces': ('Compose solids with ordered set operations.', 'Known forms become operands and inhabitable differences.', 'Swap A−B and B−A; compare with union/intersection and test passage separately from appearance.', 'Boolean logic already exists. CSG adds solid representations and noncommutative difference, not a fresh introduction to if.'),
'swarmintelligence': ('Give many agents local decisions and shared consequences.', 'The moving body gains sensing, steering, neighbours and environmental memory.', 'Predict one agent update, then compare traversal orders and neighbourhoods in a small population.', 'Seek/flee/arrive are candidate small studies in the Boids hall; pursuit/evade may remain optional. Do not claim the current lesson already contains them.'),
'machinelearning': ('Separate prediction, error and parameter updates.', 'An evaluated candidate becomes a model with data, loss and learned weights.', 'Train on one declared sample set and evaluate on held-out cases; explain what the score cannot establish.', 'Clustering is not supervised classification. Keep the installed centroid lesson correctly named in the prose. Perceptron/backprop extensions need verified hosts.'),
'graphtheory': ('Separate identity and connectivity from drawing positions.', 'Known relation records become adjacency, traversals and constrained allocations.', 'Reconstruct a route from predecessors; test an unreachable target; move the layout without changing connectivity.', 'Earlier adjacency previews are useful. Here own queues, traversal order, invariants and complexity.'),
'foundationscrisis': ('Distinguish a finite computation, an assumption and a warranted claim.', 'Known programs become experiments on geometry, membership and proof checking.', 'State what a bounded experiment establishes and what it cannot prove; change an assumption explicitly.', 'Several halls should be reflective investigations with tiny witnesses, not grand algorithms that supposedly demonstrate entire theorems.'),
'qfeplaboratory': ('Inspect a proposed research model and its measurement choices.', 'Retained observations become weighted expressions and revisable experiments.', 'Preserve inputs, vary one weight, compare a stated measure and record the interpretive limit.', 'QFEP is the project’s research proposal. Do not promote a convenient scalar or metaphor into an established physical law.'),
'postfoundationscrisis': ('Make a revisable work with accountable records and other people.', 'Known objects, relations and recipes become situated assemblies and recoverable versions.', 'Compose an original work, retain its source/decisions and explain whose observations or participation are absent.', 'This is synthesis and critical reflection. Do not add new compulsory syntax simply to make every hall a lesson.'),
}

# Source inventory topic → first explicit teaching proposal, later/deeper use.
# None means deliberately unplaced; never claim the inventory is fully delivered.
PLACEMENTS = {}
def place(ids, first, later='', note='', scope='core'):
    for i in ids: PLACEMENTS[i] = (first, later.split() if later else [], note, scope)
place([0,6,90,104], 'Point_Zero', 'Point_Trace Trans_Pre Vectors_Act3_FieldsAndMotion', 'State/update start small; the full sense/decide/integrate architecture comes later.')
place([1,18,115], 'Point_Coordinates', 'Trans_Rotation Trans_Scale', 'Day Zero supplies camera/light/XR. Teach 3D frames immediately; no detour through Processing screen coordinates.')
place([2], 'Point_One', 'Point_Lines Point_Triangle_Context', 'Select the actual lineage of sphere, segment and face; do not teach every drawing primitive.')
place([4,5], 'Point_One', 'Point_Lines Point_Trace Tutorial_Tiling_Floor', 'Name assignment, value, reference, units and arithmetic as used. Remainder is later.')
place([7,33], 'Trans_Pre', 'Trans_Translation Vectors_Act3_FieldsAndMotion', 'First prescribed motion; later integrate retained velocity.')
place([8,11,20,21], 'Point_Trace', 'Point_Line_Grid Array', 'Godot Array is already dynamic. Teach append/index/if/neighbour loop in separate beats; no Java ArrayList detour.')
place([9,10], 'Trans_Introduction', 'Color_Paint', 'Input actions and handlers in the shared museum. Physical mouse/keyboard bindings are Day Zero support; avoid a second desktop-only course.')
place([12], 'Point_Line_Grid', 'Array Tutorial_3D', 'First grid addresses derived from retained positions; then independent addressed objects and storage order.')
place([13], 'Primitives_Ignorance', 'Primitives_Columns Color_Nails Color_Pillar', 'Calling functions precedes this. Here author parameters, locals and return in a geometric generator.')
place([14], 'FormFinding_Annealing', 'WaveFunctions_John_Cage Random_Definition', 'A bounded draw is a short explicit preview. Randomness owns seed, sequence, distribution and sampling policy.')
place([15,32], 'Random_Gaussian', 'Randomness_Examples_of_Randomness', 'Uniform/weighted previews occur earlier; Gaussian comparison is not proof that every process is Gaussian.')
place([16], 'Random_Space_Geometry', 'Noise_One Noise_Inside_Noise Noise_Perlin_Simplex', 'Preview spatial correlation, then own noise sampling and domain composition.')
place([17,45], 'Trans_Pre', 'WaveFunctions_Unit_Circle WaveFunctions_TrigWalkingPath', 'Use a bounded sine expression here; Waves owns radians, projection, frequency and phase.')
place([19], 'Point_Triangle_Context', 'Primitives_Polythedra Point_Animatedcube', 'Triangle corners/winding first; shared vertex data and indexed faces next.')
place([22], 'Point_Lines', 'Point_Trace Color_Grid_Pallet', 'PointBody is already authored here. Palette adds methods and independent retained state.')
place([23], 'Array', 'Tutorial_3D SwarmIntelligence_Boids_Algorithm', 'Two PointBody instances preview plurality. Array owns collections, aliasing and independent resource state.')
place([24,25,27,28], 'Point_Lines', 'Vectors_Act1_WhatAVectorIs Vectors_Act2_VectorArithmetic', 'A difference is displacement; its magnitude is distance. Zero displacement has no direction.')
place([26], 'Trans_Translation', 'VFM_02_Operations', 'Use position + displacement first; later compare result and travelled route.')
place([29], 'Trans_Translation', 'Vectors_Act1_WhatAVectorIs', 'Guard zero length before normalizing; separate direction from speed.')
place([30,56,57,58], 'SwarmIntelligence_Boids_Algorithm', '', 'Propose one moving agent before the flock: desired velocity minus current velocity; bound speed/steering. Verify the host before writing.')
place([31], 'Random_Walk', 'Random_Pheromone', 'Carry an actual ordered position record and name the boundary rule.')
place([34,36,38], 'VFM_03_Motion', 'Vectors_Act3_FieldsAndMotion', 'Constant applied force can stand for wind. Distinguish engine force application from a learner-owned integrator.')
place([35], 'Vectors_Act3_FieldsAndMotion', 'SwarmIntelligence_Boids_Algorithm', 'Target acceleration is not automatically steering or arrival; compare their state updates.')
place([37], 'VFM_05_Launch', 'VFM_07_Gravity', 'Constant downward acceleration first; inverse-square attraction later.')
place([39], 'Vectors_Act4a_KineticForces', '', 'Candidate bounded comparison: speed-independent friction versus linear drag. Existing focus is drag; inspect before extending.', 'optional')
place([40], 'Vectors_Act4a_KineticForces', 'Vectors_Act4b_Oscillation')
place([41,42], 'VFM_07_Gravity', '', 'Pairwise accumulation; test symmetry and close-range guard. Declare the O(n²) cost before scaling the population.')
place([43,44], 'Trans_Rotation', 'Change_Choreography WaveFunctions_Unit_Circle', 'Radians/axis and rate now; angular acceleration later only where used.')
place([46], 'WaveFunctions_TrigWalkingPath', 'WaveFunctions_Synthesis_Lab')
place([47], 'WaveFunctions_Intro', 'WaveFunctions_Pendulum')
place([48], 'Vectors_Act4b_Oscillation', 'FormFinding_Relaxation SoftBodies_Cloth_Physics')
place([49,50,51,52,53,55], 'Color_Paint', 'SwarmIntelligence_Swarm_Intelligence_Algorithms', 'Paint uses supplied particle feedback; candidate later mini-study owns emit/update/expire records. This is NOT a delivered particle-systems tutorial.', 'optional')
place([54], 'Point_Coordinates', 'Point_Lines Color_Grid_Pallet', 'Explain inherited pickup behaviour when changing the base type. Prefer composition for palette/receiver; polymorphism is optional later, not required now.')
place([59,60,63], 'SwarmIntelligence_Boids_Algorithm', '', 'Candidate small variations after one-agent seek; do not crowd the first flock exercise.', 'optional')
place([61,62], None, '', 'Pursuit/evade need prediction of another body. Defer until there is a chosen encounter and a reason to teach them.', 'defer')
place([64], 'Trans_Translation', 'SwarmIntelligence_FlowFields', 'Waypoints first; nearest segment/projection is a later steering extension, not the same implementation.')
place([65,97], 'Flow_Field', 'Vectors_Act5_ForceAsPlace SwarmIntelligence_FlowFields', 'First sample a supplied vector field; later distinguish field construction and different receivers.')
place([66,110], 'SwarmIntelligence_Boids_Algorithm', '', 'Small population; independent updates from one snapshot; explain neighbour range.')
place([67,69,70], 'CA_Introduction', 'CA_BeyondBinary CA_GameOfLife', 'Verify live rules and state encoding. Topic names are not proof of implementation.')
place([68], 'CA_ElementaryRules', '', 'Candidate rule-bit row study only after source inspection. The installed hall currently documents three-state neighbour transitions.', 'optional')
place([71,73], 'Fractal_Recursion', 'Fractal_Synthesis')
place([72], 'Fractal_RecursiveTrees')
place([74], 'Fractal_CantorSet')
place([75], 'Fractal_KochSierpinski')
place([76], 'LSystems_Grammar_Lab', 'LSystems_Shape_Grammars')
place([77], 'LSystems_Growth', 'LSystems_Grammars_And_Curves')
place([78,79,80,81,82,83], 'PG_Genetic_Evolution', 'ML_Evolution', 'Split representation/evaluation from selection/reproduction. Crossover and mutation require separate observable edits; no claim that one giant lesson already teaches all six.')
place([84], 'LSystems_Living', 'PG_Genetic_Evolution', 'Human selection and saved design records can preview evaluation. Do not label every saved specimen an evolutionary algorithm.', 'optional')
place([85,88], 'ML_Neural_Networks', 'ML_Generative', 'Start with one weighted unit and forward evaluation; backprop only after a concrete loss/update test.')
place([86], 'ML_Neural_Networks', '', 'Candidate threshold classifier beside the network. Keep the existing centroid clustering lesson separate.', 'optional')
place([98], 'FormFinding_Descent', 'ML_Gradient_Landscape ML_Neural_Networks', 'First numerical gradient and step on a cost; training later names data, prediction and loss.')
place([87], 'ML_Gradient_Landscape', 'ML_Neural_Networks', 'Reuse descent, now with a dataset, predictions and aggregated loss. A changing sculpture alone is not model training.')
place([89], 'ML_Evolution', '', 'Optional neural-weight encoding after both genetic representation and network evaluation are understood. Requires a later return, not a forward prerequisite.', 'optional')
place([91], 'Trans_Body', 'Color_Paint SwarmIntelligence_Agent_Based_Modeling_ABM')
place([92], 'Vectors_Act4b_Oscillation', 'Random_Pheromone CA_SoftRules', 'Restoring response, environmental memory and iterative field updates have different states and clocks.')
place([93,94], 'Tutorial_Tiling_Floor', 'CA_Introduction SwarmIntelligence_Boids_Algorithm', 'Start by predicting a small rule’s global pattern; emergence later requires an interacting model, not a slogan.')
place([95], 'Random_Definition', 'CA_EdgeOfChaos')
place([96], 'CA_EdgeOfChaos', 'QFEP_Edge_Of_Chaos', 'Use paired finite experiments and numerical limits. Visual complexity alone does not establish chaos.')
place([99], 'Trans_Pre', 'Color_Pillar ISO_LookupTable')
place([100], 'Point_Line_Grid', 'Primitives_Portals WaveFunctions_Synthesis_Lab CA_Introduction', 'Addresses/rounding first; samples, approximations and time steps return with different meanings.')
place([101], 'Change_Intro', 'Vectors_Act3_FieldsAndMotion', 'Finite sums preview accumulation. Later compare explicit/semi-implicit update order and time-step error.')
place([102], 'Trans_Pit', 'VFM_07_Gravity SwarmIntelligence_Boids_Algorithm', 'Shared control coordinates a small mechanism before mutual interactions between many bodies.')
place([103], 'VFM_07_Gravity', 'Fractal_Recursion SwarmIntelligence_Boids_Algorithm GT_Pathfinding', 'Count pair contributions first; compare recursive construction budgets and neighbour search later. Measure work before proposing spatial partitioning.')
place([105,106], None, '', 'No necessary current lesson identified. Voronoi/Delaunay may become a chosen spatial-partition branch; do not insert them to complete a checklist.', 'defer')
place([107], 'CA_SoftRules', 'ProceduralGeneration_Reaction_Diffusion_Systems Shader_10_ReactionDiffusion', 'CPU synchronous coupled fields own the update; shader feedback is a preview with storage supplied. Later return to its state implementation.')
place([108], None, '', 'DLA is not space colonization. Leave unplaced until an encounter explicitly needs diffusion and sticking.', 'defer')
place([109], 'SwarmIntelligence_Ant_Colony_Optimization', 'SwarmIntelligence_PhysarumColony')
place([111], 'SwarmIntelligence_Agent_Based_Modeling_ABM', '', 'Possible resources/birth/death study after basic state transitions; inspect actual agent rules first.', 'optional')
place([112], 'Primitives_Ignorance', 'LSystems_Grammar_Lab PG_Genetic_Evolution', 'Generation starts with a small position function. The later sequence deepens representation, evaluation and construction.')
place([113], 'Tutorial_Tiling_Floor', 'Color_Paint ML_Perception', 'Addressed motif/image values first; brush coordinates later; convolution in Perception.')
place([114], 'Tutorial_Disco', 'WaveFunctions_Effect_Sound WaveFunctions_AirMusic', 'Score entries and sound trigger first; signals/synthesis later. FFT is an optional extension, not currently promised.')
place([3], 'Color_Context_Placed', 'Color_Nails Color_Pillar', 'Earlier simple material colours are supplied; here distinguish palette assignment, RGB function and HSV convention.')

EXTRA = [
('xr-pickup','Pickup/release and grip alignment','Point_Coordinates',['Point_Trace'],'Follow the inherited body, declared hand interface and release state. Test synthetic transitions; separately observe headset comfort.'),
('actions','Named actions, events and interaction states','Trans_Introduction',['Trans_Body','Color_Paint'],'Name input → handler → state → receiver. Keyboard/controller bindings are Day Zero support.'),
('targeting','Targeting, snapping and feedback','Point_Line_Grid',['VFM_08_Arena','Color_Paint'],'Grid teaches quantisation; painting teaches a ray hit and local surface coordinates. Do not confuse a highlighted target with a valid action.'),
('ownership','Object identity, shared resources and ownership','Point_Lines',['Array','Color_Grid_Pallet'],'Changing one PointBody must not resize another. State explicitly what is shared, copied, freed or retained.'),
('frames','Units, reference frames and coordinate adapters','Point_Coordinates',['Point_Line_Grid','Color_Pillar'],'Every position names its frame; every rate names its time unit. Test a translated/rotated parent.'),
('handoff','Code, data and lifetime handoffs','Point_Trace',['Point_Line_Grid','PostCrisis_Synthesis'],'Saved code is not a live object; an array in one station is not automatic cross-hall persistence. Supply and test any bridge you claim.'),
('contracts','Function contracts, invariants and failure cases','Primitives_Ignorance',['Color_Nails','ISO_LookupTable'],'Name input/output and invalid cases. One mathematical operation can have several valid software representations.'),
('tests','Observation, assertions and independent transfer','Point_Zero',['Point_Line_Grid','Color_Walls'],'The AI tests exact printed code and deliberate faults. The learner predicts, explains and makes a variant. Keep these evidence types separate.'),
('buffers','Snapshot/update separation','CA_Introduction',['SwarmIntelligence_Boids_Algorithm'],'One generation reads the same old state. Detect order dependence with a reversed traversal.'),
('models','Model, implementation, display and critical claim','Point_One',['VFM_05_Launch','foundations-placeholder'],'Use concrete differences: visible sphere versus collider; physical assumption versus solver; experiment versus proof.'),
]
EXTRA[-1]=(EXTRA[-1][0],EXTRA[-1][1],EXTRA[-1][2],['VFM_05_Launch','Godel_Incompleteness'],EXTRA[-1][4])

# Opening contracts are concrete enough to hand to the next writer/tester.
# Later halls retain their curated focus with a source-audit task before code.
CONTRACTS = {
'Point_Zero': ('Counter', 'Preserve the complete label/counter lesson; no new rewrite merely to fit the plan.', ['Label created and attached before update; reading once stays fixed while frames advance.', 'Run the exact printed source; omitted initialization must fail.'], 'Predict the once-only value, then explain what continues running.'),
'Point_One': ('One point', 'Preserve the minimal point construction; retain one radius for mesh and collider.', ['Mesh/collider exist and share the declared radius and centre.', 'Printed position/radius variants change the corresponding body; contact and visibility remain separable.'], 'Make another radius and position; predict visible and physical boundaries.'),
'Point_Coordinates': ('The same point, now pickable', 'Continue Point One; keep pickup and local/world coordinates as the lesson.', ['Synthetic pickup/release respects the declared freeze and collision settings.', 'Translated/rotated parent distinguishes local from world; no distance lesson added.'], 'Move the point outside a drawn axis; predict both coordinate readings.'),
'Point_Lines': ('Two PointBody instances and their segment', 'Preserve the tested class extraction; separate point construction from the relation between endpoints.', ['Changing one instance radius/material does not mutate the other.', 'Segment joins moved endpoints; distance matches displacement length; translated parent does not break the frame.'], 'Make parallel, crossed or X pairs; find two different directions with equal length.'),
'Point_Trace': ('PointBody plus an ordered position record', 'Preserve the tested array, append, if-distance and neighbour-loop lesson.', ['Pause/sub-threshold movement adds nothing; sufficient movement appends one position.', 'n retained positions produce n−1 neighbour segments; wrong-neighbour and missing-gate controls fail.'], 'Choose a different sampling distance; predict the record before drawing again.'),
'Point_Line_Grid': ('Original trace and a derived addressed copy', 'Continue the tested local Array[Vector3]. Start in the same PointStudy; supply a transfer only if it is explicitly required and verified.', ['Original values/order unchanged after snapping; grid positions are multiples of declared pitch in the same frame.', 'Test empty/single trace, negative coordinates, half-cell boundaries and coincident addresses.', 'Compare two pitches; a source-mutation or frame-mismatch fault fails ordinary assertions.'], 'Predict where a bend lands at another pitch; explain sample index versus spatial address.'),
'Point_Triangle_Context': ('Three retained positions and a face', 'Choose three non-collinear points; retain their identities while adding a closed edge cycle and one face.', ['Exactly three corners connect in order and produce a nonzero-area triangle.', 'Reversing winding changes orientation; collinear or repeated points are handled explicitly.'], 'Make a different valid triangle; predict front/back and explain why three arbitrary entries may fail.'),
'Primitives_Polythedra': ('Four shared vertices and four indexed faces', 'Build a tetrahedron before a general polyhedron factory; index triples refer to the stored positions.', ['Each face index is in bounds; each tetrahedron edge belongs to two faces.', 'Moving one shared corner updates all incident faces; winding and zero-area cases are checked.'], 'Edit one corner, predict affected faces and keep the enclosure valid.'),
'Point_Animatedcube': ('Eight vertices and twelve triangles', 'Reuse the indexed face list; separate a corner edit, diagonal choice and whole-node transform.', ['Both diagonals cover the same planar quad; neighbouring faces reuse corner entries.', 'Vertex edit changes intended incident faces; node transform preserves local vertex data.'], 'Choose another side diagonal and explain the difference between topology and pose.'),
'Primitives_Ignorance': ('A returning position generator', 'Replace a repeated block of coordinate data with one small function; keep face connectivity supplied and named.', ['Different radius inputs give distinct returned arrays with the promised count and symmetry.', 'Changing a returned list does not silently change the function or another result.'], 'Use the function twice with different inputs, then alter the rule rather than individual coordinates.'),
'Primitives_Godot': ('A chosen PrimitiveMesh resource', 'Inspect one resource class and one property, building on PointBody instances; keep the full library as museum context.', ['Two deliberately independent resources can vary separately; a shared-resource variant changes both receivers.', 'Changing the selected property affects the documented dimension/resolution, not unrelated scene state.'], 'Choose another documented primitive property and explain which object owns it.'),
'Primitives_Columns': ('A parameterised column family', 'Separate profile samples, full height and radial segment count; controlled comparison first, varied composition second.', ['At equal height/profile, 4/6/8/12/16 segment variants differ only in radial sampling.', 'Height/profile edits preserve a stated resolution; generated indices remain valid.'], 'Make one new silhouette; justify its height and resolution as separate choices.'),
'Primitives_Profiles': ('An outline plus a construction route', 'Choose one disclosed recipe input. Supply font contours, holes and sweep triangulation rather than conceal them.', ['Change route with outline fixed, then outline/scale with route fixed; inspect the two effects separately.', 'Check the chosen opening is actually passable or name why it is only visible.'], 'Predict how one letter hole or route change alters the resulting space.'),
'Primitives_Portals': ('A sampled ring with a tolerance', 'Accumulate neighbour distances; stop by a chosen numerical tolerance or budget, not by claiming arrival at infinity.', ['Closed loop includes last-to-first segment; count and radius are controlled.', 'Two tolerances terminate within a budget and report the actual approximation error.'], 'Choose sufficient resolution for a stated use and keep aesthetic preference separate.'),
'Primitives_Melencolia': ('An arrangement of known forms', 'Compose with tested generators and placement. Keep scale controls supplied until Transformation.', ['All instances derive from declared known constructors; arrangement is recoverable from saved parameters.', 'No unexplained new syntax or hidden production factory is needed to reconstruct the selected composition.'], 'Make an independent arrangement and explain what the framing asks the viewer to feel.'),
'Trans_Pre': ('A familiar body with a clock', 'Accumulate elapsed seconds; branch at a duration boundary; then compare linear interpolation with one bounded sine expression.', ['Start/middle/end positions match the declared duration; reset restores elapsed state.', 'Two frame-step sizes reach the same prescribed pose at the same elapsed time within tolerance.'], 'Change duration without changing endpoints; predict the arrival and return.'),
'Trans_Introduction': ('One shared reset action', 'Name action → signal/handler → target state. Let a complete small handler invoke the same reset from two inputs.', ['Both declared inputs reach the same handler; repeated reset returns all owned state consistently.', 'Feedback agrees with target/current state; a disconnected handler control fails.'], 'Add a second declared caller and explain why duplicating the reset logic is unnecessary.'),
'Trans_Translation': ('A body on a short waypoint route', 'Carry a route index through frames; guard zero-length legs before division; separate direction from distance.', ['Repeated waypoint does not divide by zero or stall; final and wrap behaviour are declared.', 'Travel is speed×elapsed time within tolerance; the whole route is not traversed in one frame.'], 'Add a repeated waypoint and predict how the guard handles it.'),
'Trans_Rotation': ('A body relative to a pivot', 'Use an offset, axis and angle; compare two operation orders using the same body.', ['Pivot stays fixed and the offset rotates in a named frame.', 'Use a non-symmetric witness so reversing operation order produces the predicted difference.'], 'Move the pivot while retaining the body and explain the changed sweep.'),
'Trans_Scale': ('A parent and known children', 'Scale a small group against a fixed external reference; distinguish local geometry and transformed placement.', ['Child offsets scale with the parent; external witness stays fixed.', 'Reset restores local transforms without replacing the child instances.'], 'Predict which distances change before applying another scale.'),
'Trans_Body': ('A response and a remembered visit', 'Compare a freshly evaluated proximity boolean with a retained flag; add and/not only when required.', ['Leaving reverses the current response but not the remembered visit; reset clears only the intended state.', 'Boundary equality and repeated entry have explicit outcomes.'], 'Make a reversible rule and a remembered rule from the same input.'),
'Trans_Pit': ('Two leaves driven by one value', 'Compose known timing and conditions; share an opening fraction and declare occupancy/reset behaviour.', ['Both leaves use the same control value; endpoints and intermediate poses agree.', 'Repeated occupancy/reset events do not leave an unintended half-state.'], 'Choose a new safe opening/reset rule and explain its shared state.'),
'Array': ('Independent bodies indexed in a collection', 'Write the missing lesson: short row first, then a plane. Distinguish values, object references and occupancy.', ['Two references to one object and two independent instances produce different edits.', 'Write one slot and preserve neighbours; empty/single collection and row boundaries are explicit.'], 'Change one body and one occupancy value; explain why the two changes are different.'),
'Tutorial_3D': ('A three-index collection', 'Extend the plane with explicit values[y][z][x] storage; use unequal coordinates to expose transposition.', ['Write/read one unequal XYZ address; all unrelated cells retain their values.', 'Separate rows/layers do not alias; bounds are checked.'], 'Choose another address and translate it correctly into storage indices.'),
'Tutorial_Tiling_Floor': ('A small rule repeated across a plane', 'Use remainder to choose tile orientation. Show a 4×4 prediction before expanding, with one explicit exception.', ['Rule gives expected orientation at selected addresses; expanded field matches the 4×4 witness.', 'The exception changes one address without altering the source motif or every copy.'], 'Change one rule term, sketch its local result and predict the large pattern.'),
'Tutorial_Disco': ('A score and a playhead', 'Keep boolean score separate from tempo; cycle the index and call a supplied sound receiver.', ['Score events occur in order and wrap; tempo changes spacing, not stored score.', 'Large elapsed steps follow the declared catch-up policy; reset clears the playhead deliberately.'], 'Move an event at fixed tempo, then change tempo without changing the score.'),
'Color_Nails': ('A position-to-colour function', 'Write a complete pure mapping with positive box dimensions, clamping and Color return; bind one receiver explicitly.', ['Origin/opposite corner/outside samples have predicted bounded RGB values.', 'Changing one coordinate changes its channel; a frame error is caught separately from a colour formula error.'], 'Reuse the function on another receiver without changing its calculation.'),
'Color_Grid_Pallet': ('A palette with independent state', 'Deepen PointBody’s class lesson: colours and index are owned state; current_colour() and next_colour() are methods.', ['Two palettes advance independently; a returned colour is assigned to a declared grid slot.', 'Nonempty palette precondition, wrap and addressed retention are explicit.'], 'Build a second palette and advance only one; predict both current values.'),
'Color_Paint': ('A brush, target and evolving image', 'Connect named action, interaction state, ray hit and local surface coordinates to one shared paint method.', ['Valid held/active/target state paints; inactive or invalid-target state does not.', 'Desktop/XR adapters call the same paint operation; transformed surface hits map to the intended pixels.'], 'Change brush radius or colour without changing targeting; explain which record retains the result.'),
'Color_Walls': ('An independent palette composition', 'Use a returning function, bounded condition and independently owned state in one small authored arrangement.', ['Different palette lengths remain valid; unrelated instances do not change together.', 'All selected basic operations are explained or explicitly inherited; no new compulsory syntax.'], 'Compose a new arrangement and explain each ownership and receiver choice.'),
}

if (OUT/'plan.json').exists():
    raise SystemExit('plan.json already exists: edit the plan through the UI; do not reseed it.')
spine = sorted(read('commons/maps/curriculum_spine.json')['spine']['sequences'], key=lambda x:x['order'])
lineage = {h['map']:h for n in ['opening','middle','later'] for h in read(f'doc/book/course/hall-cards/lineage-{n}.json')['halls']}
storyboards = {h['id']:h for n in ['opening','early','growth','later'] for s in read(f'doc/book/course/storyboards/{n}.json') for h in s['halls']}
state = read('doc/book/course/hall-cards/state.json')['cards']
sequences, lessons, protected = [], [], {}
for s in spine:
    name=s['name']; seqfile=f'commons/maps/sequences/{name}.json'; live=read(seqfile)['sequences'][name]
    aim,carry,exit_check,note=SEQUENCES[name]
    sequences.append(dict(id=name,aim=aim,carry=carry,check=exit_check,note=note))
    for m in live['maps']:
        h=lineage[m]; b=storyboards.get(m,{})
        codefile=ROOT/f'commons/maps/{m}/tutorial.md'
        subjects=state.get(m,h)['subjects']; focus=state.get(m,h)['focus']
        contract=CONTRACTS.get(m)
        mode='build' if b.get('mode') in ['make','deepen'] else 'compose' if b.get('mode')=='compose' else 'reuse'
        if m in ['Primitives_Melencolia','Color_Walls','PostCrisis_Synthesis']: mode='compose'
        if m in ['Color_Rainbow','Lab_Path'] or name=='foundationscrisis': mode='reflect'
        obj,change,checks,transfer=contract or (
            h['carries'],
            focus,
            [],
            'Select one independent variation of this operation after verifying the learner host; require prediction and explanation, not only successful execution.'
        )
        lessons.append(dict(id=m,decision='draft',mode=mode,object=obj,change=change,
            dependsOn=[x['map'] for x in h['builds_on']],
            reuses='; '.join(x['why'] for x in h['builds_on']) or 'Day Zero: running museum, a saved script and declared study location.',
            given='; '.join(b.get('supplied',[])) or 'Existing museum room and prepared player. Inspect and name any additional support before writing.',
            later='Do not explain every visible artifact. '+(b.get('review_note','') if not contract else 'Keep the reflective encounter in final.md; introduce only the selected operation here.'),
            checks=checks,transfer=transfer,carry=h['carries'],
            next='Preserve the current tested lesson; collect a learner prediction/transfer observation.' if m in ['Point_Zero','Point_One','Point_Coordinates','Point_Lines','Point_Trace'] else (
                'Pin the previous output; verify a named museum study host; write and test this bounded continuation.' if contract else
                'Source audit first: verify the selected artifact and learner edit location; replace broad scope with one minimal construction, a concrete behaviour assertion and a transfer task before writing code.'),
            notes=h['review'],
            baseline=dict(tutorial=digest(codefile.read_bytes()) if codefile.exists() else None,
                choice=digest(json.dumps([subjects,focus],separators=(',',':'),ensure_ascii=False).encode())),
        ))
        for filename in ['tutorial.md','final.md','map_data.json']:
            p=ROOT/f'commons/maps/{m}/{filename}'
            if p.exists(): protected[str(p.relative_to(ROOT)).replace('\\','/')]=digest(p.read_bytes())
    protected[seqfile]=digest((ROOT/seqfile).read_bytes())
protected['commons/maps/curriculum_spine.json']=digest((ROOT/'commons/maps/curriculum_spine.json').read_bytes())

topics=[]
for t in read('doc/book/course/execution-plan/source-topics.json')['topics']:
    first,later,note,scope=PLACEMENTS[t['id']]
    topics.append(dict(id='topic-'+str(t['id']),title=t['title'],first=first,returns=later,scope=scope,note=note))
for key,title,first,later,note in EXTRA:
    topics.append(dict(id='ada-'+key,title=title,first=first,returns=later,scope='core',note=note))
assert len(PLACEMENTS)==116
maps={l['id'] for l in lessons}
assert all(t['first'] is None or t['first'] in maps for t in topics)
assert all(x in maps for t in topics for x in t['returns'])
plan=dict(schema='ada-execution-plan/1',title='A capability carried onward',date='2026-10-05',
    source='https://docs.google.com/document/d/1uh78AblFxm88Lldetq6YnbDMTVJCerEMhppNGTAB9tg/edit',
    scope='Proposed execution plan against the live spine. Source inventory headings, curated hall choices and inspected opening evidence; not a claim of 207 tested lessons.',
    sequences=sequences,topics=topics,lessons=lessons)
dump(OUT/'plan.json',plan)
dump(OUT/'protected-sources.json',protected)
print(json.dumps(dict(sequences=len(sequences),halls=len(lessons),source_topics=116,ada_topics=len(EXTRA),bounded_contracts=len(CONTRACTS),protected_sources=len(protected))))
