# The tutorial lineage

5 October 2026. A teaching route read against the current tutorials. Selected lessons are revised in the eight-interaction pass; the rest retain their review status. Learning-element lists select the teaching; they do not inventory the artifact's code.

207 halls · 25 sequences · 65 focus/text matches · 132 need revision · 10 tutorials missing.

**Builds on → adds or deepens → carries forward.** Aligned means the focus is supported by the inspected text. It does not mean author approval, implemented museum transfer or demonstrated learner competence. Saved author decisions override these proposals.

[Five revised halls, eight interaction topics: images and full lessons](../../iterations/2026-10-05-eight-interaction-lessons/index.html).

## Primitives: Points Build Worlds

### [Point Zero](http://localhost:3003/tutorial-cards?map=Point_Zero)

Initialization · Per-frame updates · Function calls

- **Builds on:** Prepared museum and supplied player
- **Adds/deepens:** Introduces when a callback runs and how a call returns a reading.
- **Carries:** A complete counter program and the distinction between initialization and repeated execution.
- **Review:** Focus fits the text. One complete printed counter plus one exact move for the once-only experiment. Both executable states are assembled from the lesson and tested in isolated Godot; no repeated _ready listing and no production-script completion.

### [Point One](http://localhost:3003/tutorial-cards?map=Point_One)

Position values · Variables and constants · Object references · Visible and physical boundaries

- **Builds on:** Point Zero: Initialization gives the construction a known execution point.
- **Adds/deepens:** Introduces named values, assignment, object references and the separation of position, appearance and collision.
- **Carries:** The complete point.gd: one created body with an explicit position, mesh and collider. Coordinates continues this exact construction.
- **Review:** Focus fits the text. 5 October: the complete printed script runs in isolated Godot with behavioural assertions, including actual collision queries and the printed small edits. No production artifact fills missing construction. Native evidence verifies this code, not learner comprehension.

### [Point Coordinates](http://localhost:3003/tutorial-cards?map=Point_Coordinates)

Pickable · 3D coordinate system · Local and world position

- **Builds on:** Point One: A position, mesh and collider already have distinct roles.; Point Zero: Repeated updates can read a moving body's current property.
- **Adds/deepens:** Adds pickup and release, distinguishes the body from the hold, and converts positions between explicitly named frames.
- **Carries:** The same authored point construction, now pickable and releasable, with live positions in explicitly named frames.
- **Review:** Focus fits the text. 5 October: declared edits compose current Point One into the complete printed Coordinates script byte-for-byte. Native Godot tests exercise real XR Tools overlap, pickup, movement, release and frame conversion using a synthetic controller. Hardware buttons, headset feel and learner understanding remain untested.

### [Point Lines](http://localhost:3003/tutorial-cards?map=Point_Lines)

Endpoints and a segment · Displacement and distance · A class and its instances · Parallel, cross and X · Position in depth

- **Builds on:** Point Coordinates: Both endpoints must be expressed in the same reference frame.; Point One: Named position values can be passed through expressions.
- **Adds/deepens:** A class extracted from familiar construction; independent instances; displacement and distance between endpoints.
- **Carries:** PointBody class, two independent pickable instances, coordinate readout and live segment. Trace reuses the class unchanged.
- **Review:** Focus fits the text. The complete printed script extracts the tested Coordinates construction into point_body.gd and creates two instances. The class construction is checked against the predecessor. Each point owns its mesh and collider; native XR pickup, resource independence and line relations are verified.

### [Point Trace](http://localhost:3003/tutorial-cards?map=Point_Trace)

Reusing the point class · Arrays of positions · Appending and reading an index · A distance condition with if · Neighbour loops with for

- **Builds on:** Point Lines: Displacement length decides whether a new sample is far enough away.; Point Zero: A per-frame callback is different from one traversal of a list.
- **Adds/deepens:** An ordered typed array, append/index access, a threshold condition and neighbouring-index traversal.
- **Carries:** Unchanged PointBody class, coordinate readout and a station-local position array separate from its segment drawing. The record lasts with this station; no Grid transfer yet.
- **Review:** Focus fits the text. The complete printed Trace script continues the verified class-based Lines program. PointBody and LineSkin are carried byte for byte. The lesson owns the array, threshold and neighbour loop. This source-code continuation does not transfer a running museum session.

### [Point Line Grid](http://localhost:3003/tutorial-cards?map=Point_Line_Grid)

Reusing a retained list · Display coordinates · Snapping in X, Y and Z · Source and derived positions

- **Builds on:** Point Trace: An ordered retained list can be read again without repeating the gesture.; Point Coordinates: A position's meaning depends on its named frame.
- **Adds/deepens:** Adds fit-before-snapping, a three-dimensional display address distinct from list order, and separation of original and derived positions.
- **Carries:** A source drawing and its fitted and snapped representations, without claiming lossless inversion or cross-run persistence.
- **Review:** Focus needs revision. 5 October: the current Trace lesson produces a station-local learner array. This older Grid text reads the production pen’s world-coordinate session store. Preserve its real museum behaviour, but write and test the explicit learner continuation before claiming a current Trace-to-Grid handoff. Source fitting and snapping remain distinct operations.

### [Point Triangle Context](http://localhost:3003/tutorial-cards?map=Point_Triangle_Context)

Corners and edges · Closed boundaries · Triangular faces · Vertex order

- **Builds on:** Point Lines: A segment connects each pair of corners.; Point Trace: A list can retain and select position values.; Point One: A visible surface and a physical boundary are separate.
- **Adds/deepens:** Adds a triangular face to connected corners; order belongs to the mesh construction.
- **Carries:** Three chosen corners usable as a boundary or a face.
- **Review:** Focus needs revision. The starter teaches corners, edges and faces, but the museum drawing-tool binding is unresolved. Its two-sided material does not support the foundation plan's proposed visible-side winding test.

### [Primitives Polythedra](http://localhost:3003/tutorial-cards?map=Primitives_Polythedra)

Shared vertices · Face indices · Nested traversal · Enclosure

- **Builds on:** Point Triangle Context: A face consists of three ordered corners.; Point Trace: Indices and traversal can address a retained list.
- **Adds/deepens:** Adds connectivity stored separately from coordinates and traversal through face rows.
- **Carries:** A mesh description with separately editable positions and connections.
- **Review:** Focus needs revision. The face-list lesson is written in a starter scene using saved TraceMemory. Its relationship to the museum's existing solids must be declared before treating this as the museum exercise.

### [Point Animatedcube](http://localhost:3003/tutorial-cards?map=Point_Animatedcube)

Triangulation · Shared-corner edits · Mesh and node transforms

- **Builds on:** Primitives Polythedra: Face indices connect shared positions.; Point One: The displayed object has a position distinct from its mesh data.
- **Adds/deepens:** Practice of indexed meshes; deepens how the same corners can define different surfaces.
- **Carries:** A deliberate choice of connectivity and an explanation of which faces an edit affects.
- **Review:** Focus needs revision. The starter supplies a clear diagonal exercise; bind it to the museum comparison without claiming the existing cube/net/prefab encounters are one portable learner construction.

### [Primitives Ignorance](http://localhost:3003/tutorial-cards?map=Primitives_Ignorance)

Functions · Parameters and arguments · Return values · Generated positions

- **Builds on:** Primitives Polythedra: A position list can be displayed through separately supplied face connections.; Point Trace: A loop builds an ordered list of values.
- **Adds/deepens:** Introduces a learner-readable returning function, its parameter, local values and explicit call.
- **Carries:** A geometric generator with a named input and a reusable list result.
- **Review:** Focus needs revision. The function is taught in the portable primitive_rules study. The existing museum host remains to be aligned; the function returns data and does not discover faces or constrain later hand edits.

### [Primitives Godot](http://localhost:3003/tutorial-cards?map=Primitives_Godot)

Classes and instances · Mesh resources · Resource properties · Scene composition

- **Builds on:** Point One: Resource creation and node references have distinct roles.; Primitives Ignorance: A generated result can be separated from the rule producing it.
- **Adds/deepens:** Practice of existing classes and instances; adds inspection of an engine-supplied resource contract.
- **Carries:** A choice of supplied geometry with understood settings and scene responsibilities.
- **Review:** Focus needs revision. This file is a teaching-intent stub. Choose the small edit host and demonstrate independent resources; the fixed library has no universal parameter controls. Reuse the class/instance distinction now introduced through PointBody in Lines.

### [Primitives Columns](http://localhost:3003/tutorial-cards?map=Primitives_Columns)

Profiles · Height · Radial resolution · Nested repetition

- **Builds on:** Primitives Ignorance: Parameters can control a reusable geometric generator.; Primitives Polythedra: Repeated rings need connections as well as positions.
- **Adds/deepens:** Composition of known generators and traversal; separates shape inputs from sampling density.
- **Carries:** A column recipe whose profile, height and side count can change independently.
- **Review:** Focus needs revision. The file only points to the reduced column study. Its straight intervals differ from the museum's curved sections; the learner column's museum placement and nested-loop explanation remain unresolved.

### [Primitives Profiles](http://localhost:3003/tutorial-cards?map=Primitives_Profiles)

Source outlines · Section routes · Scale along a route · Construction limits

- **Builds on:** Primitives Columns: A profile is distinct from height and sampling resolution.; Primitives Ignorance: A generator has explicit inputs that can be varied separately.
- **Adds/deepens:** Composition and selected exploration of a profile under another construction rule.
- **Carries:** A profile-plus-route specification with stated openings and use limits.
- **Review:** Focus needs revision. The file is a teaching-intent stub and defers its bounded edit host. Preserve the O sill, missing vessel bottom and disconnected colon; do not promise a general topology or sweep lesson.

### [Primitives Portals](http://localhost:3003/tutorial-cards?map=Primitives_Portals)

Perimeter accumulation · Finite resolution · Tolerance · Stopping criteria

- **Builds on:** Point Lines: Each edge length comes from two positions.; Point Trace: Neighbour traversal provides the boundary order.; Primitives Ignorance: A function can accept a list and return a number.
- **Adds/deepens:** Deepens loops through a running total and a chosen numerical acceptance threshold.
- **Carries:** A finite construction justified against an explicit tolerance.
- **Review:** Focus needs revision. The perimeter lesson is in the portable starter. Declare its museum connection; the tolerance compares lengths, not visual edge distance, exactness or artistic quality.

### [Primitives Melencolia](http://localhost:3003/tutorial-cards?map=Primitives_Melencolia)

Repeated construction · Spatial arrangement · Viewpoint · Composition

- **Builds on:** Primitives Polythedra: A body can be assembled from known positions and face connections.; Primitives Ignorance: A reusable construction can provide another instance.; Point Coordinates: Whole-body placement has a reference frame.
- **Adds/deepens:** Composition and independent practice of values, lists, loops and placement.
- **Carries:** An authored arrangement whose placement is distinct from its constituent geometry.
- **Review:** Focus needs revision. The written composition runs in the portable starter. Keep the reflective museum encounter and decide how the student's arrangement is encountered there; defer unfamiliar scale controls.

## Transformation: What Stays the Same When Everything Changes

### [Trans Pre](http://localhost:3003/tutorial-cards?map=Trans_Pre)

Elapsed time · Conditions · Interpolation · Timed transforms · Sine interpolation

- **Builds on:** Point Zero: Repeated updates supply frame intervals.; Point One: A retained object reference gives properties to change.; Point Trace: A condition controls whether an operation runs.
- **Adds/deepens:** Develops time-based state and bounded interpolation; gives sine a small usable preview before Waves.
- **Carries:** A timed transformation rule with separately chosen extent and duration.
- **Review:** Focus needs revision. The main lesson uses a portable starter; sine is only taught in the linked companion. The foundations plan's duration-boundary if/else exercise is not the present stage-switch exercise. Align one museum teaching path.

### [Trans Introduction](http://localhost:3003/tutorial-cards?map=Trans_Introduction)

Signals and event handlers · One function for shared behaviour · Target and current state · Gradual reset · Readout feedback

- **Builds on:** Trans Pre: A timed transformation has state that can be restarted.; Primitives Ignorance: A named function runs when called.; Point One: Displayed and physical constructions need separate responsibilities.
- **Adds/deepens:** Adds event-to-handler connections, one shared function, target/current state and feedback of current motion.
- **Carries:** A way to separate a request from its execution, reuse a setter for reset and read feedback without confusing it with the target.
- **Review:** Focus fits the text. Rebased on the installed adjustable_landing script. RESET requests zero and the bank returns gradually; the readout describes gap geometry, not a proof of safe passage. Source checked; no new runtime test.

### [Trans Translation](http://localhost:3003/tutorial-cards?map=Trans_Translation)

Waypoint lists · Direction and length · Guard conditions · Route state

- **Builds on:** Point Trace: A route is an ordered position list.; Point Lines: A leg has displacement and length.; Trans Pre: Elapsed time can advance a position between endpoints.
- **Adds/deepens:** Deepens list traversal into retained route state and introduces a guarded normalized direction.
- **Carries:** A route follower that preserves waypoints and handles repeated positions.
- **Review:** Focus needs revision. The current tutorial lists translation/tween utilities and door constraints. It does not teach the proposed waypoint index, zero-length guard or reduced route binding; choose preview or carrying explicitly.

### [Trans Rotation](http://localhost:3003/tutorial-cards?map=Trans_Rotation)

Pivots · Axes and angles · Rotated offsets · Operation order

- **Builds on:** Point Coordinates: An offset and centre must use a named frame.; Primitives Ignorance: A small function can return generated positions.; Trans Pre: Angles can advance with elapsed time.
- **Adds/deepens:** Adds pivoted position construction and noncommuting rotation composition.
- **Carries:** A reusable rotation-about-centre rule with an explicit operation order.
- **Review:** Focus needs revision. The companion describes existing arrays, rides and the composition workbench, but does not present the selected small returning position function. Keep ride physics and full arrays supplied.

### [Trans Scale](http://localhost:3003/tutorial-cards?map=Trans_Scale)

Uniform scale · Parent-child transforms · Fixed references

- **Builds on:** Trans Pre: Uniform scale changes a body's proportions together.; Point Coordinates: Local positions belong to a parent frame.; Point One: A visible change and a physical boundary have different roles.
- **Adds/deepens:** Deepens transform ownership through a parent and its children; practice of controlled comparison.
- **Carries:** A prediction of what a grouped scale changes and which outside references stay fixed.
- **Review:** Focus fits the text. 

### [Trans Body](http://localhost:3003/tutorial-cards?map=Trans_Body)

Proximity mapping · Boolean conditions · Retained flags · Reversible response

- **Builds on:** Point Lines: Distance supplies a scalar proximity input.; Trans Pre: Interpolation maps one value into a transform.; Point Trace: A condition decides what to retain.
- **Adds/deepens:** Develops current conditions versus retained state and simple combined conditions.
- **Carries:** A bounded response function and a distinction between present input and remembered change.
- **Review:** Focus needs revision. Current prose documents slats, deletion and scaling but does not teach the proposed learner block or boolean/flag comparison. Bind the small update without asking learners to implement visitor recognition or carving.

### [Trans Pit](http://localhost:3003/tutorial-cards?map=Trans_Pit)

Shared control values · Coordinated transforms · Occupancy conditions · Reset sequences

- **Builds on:** Trans Pre: A bounded fraction drives timed transforms.; Trans Body: Current occupancy and remembered state differ.; Trans Introduction: An event can invoke a deliberate reset.
- **Adds/deepens:** Composition and practice of known functions, conditions and timed state; no new syntax.
- **Carries:** An authored opening sequence whose intermediate clearance can be inspected.
- **Review:** Focus needs revision. The current tutorial covers timed pushers, slabs and growers, not the proposed two-leaf airlock composition. The hall is a level-ground study; the new learner binding and preceding reset lesson remain open.

## Arrays and Regularity

### [Array](http://localhost:3003/tutorial-cards?map=Array)

Independent instances · Object references · Indexed writes · Nested traversal · Occupancy records

- **Builds on:** Point Trace: Lists, indices and traversal already have a proposed first encounter.; Primitives Melencolia: Repeated construction can make separately placed bodies.; Trans Pre: A retained reference lets an update address one body.
- **Adds/deepens:** Develops value versus reference, independent object state, indexed writes and nested collection traversal.
- **Carries:** An addressed record and a declared reader, with object ownership kept separate.
- **Review:** Tutorial missing. Array/tutorial.md is absent. Choose the reduced creation/display contract. The proposed reference and nested-loop foundation cannot be counted as delivered, and no random draw is assigned here.

### [Tutorial 3D](http://localhost:3003/tutorial-cards?map=Tutorial_3D)

Three-dimensional addresses · Storage order · Indexed reads and writes

- **Builds on:** Array: A plane record separates occupancy from object references and placement.; Point Coordinates: Three spatial axes require a named frame.
- **Adds/deepens:** Extends addressing by one dimension and makes storage order explicit.
- **Carries:** A reliable conversion between displayed XYZ and stored YZX indices.
- **Review:** Focus needs revision. The existing file has a date line instead of an H1 and mostly operating/return-study notes. It does not explain converting grid_data[x][z] to values[y][z][x]; Array's prerequisite lesson is also missing.

### [Tutorial Tiling Floor](http://localhost:3003/tutorial-cards?map=Tutorial_Tiling_Floor)

Remainder · Address-to-turn rules · Exceptions · Nested traversal

- **Builds on:** Array: Nested traversal visits an addressed plane.; Trans Rotation: A turn changes a motif's orientation.; Point Trace: A condition can select an exception.
- **Adds/deepens:** Adds remainder as a repeating address rule; composes known traversal and conditions.
- **Carries:** A motif, repeat rule and explicit exception independent of the renderer.
- **Review:** Focus needs revision. The file has a date line and redirects to final.md. It does not teach remainder or the reduced rule binding; the museum rasterizes images rather than building colliding per-tile bodies.

### [Tutorial Tiling Walls](http://localhost:3003/tutorial-cards?map=Tutorial_Tiling_Walls)

Source images · Receiving surfaces · Image and body rotation · Appearance and access

- **Builds on:** Tutorial Tiling Floor: A generating rule can supply an image.; Trans Rotation: Turning a body differs from changing the data it displays.; Point One: Visible surface and collision are separate constructions.
- **Adds/deepens:** Composition and reflection using the same image on another receiver; no new syntax.
- **Carries:** A distinction between a source rule, its viewed appearance and physical access.
- **Review:** Focus needs revision. The date-led operating note explains current receivers but does not bind the learner's generated image. Existing floor and wall generators do not establish automatic transfer of the student's result.

### [Tutorial Disco](http://localhost:3003/tutorial-cards?map=Tutorial_Disco)

Boolean scores · Playhead indices · Tempo · Cyclic reads

- **Builds on:** Array: An addressed record can be read without moving its entries.; Trans Pre: Elapsed seconds advance a retained state.; Tutorial Tiling Floor: Remainder wraps an index through a finite range.
- **Adds/deepens:** Composition of indexed data and time into a repeatable event reader.
- **Carries:** A score whose stored events remain distinct from their playback timing.
- **Review:** Focus needs revision. The tutorial still describes a 17x17 footstep-recording floor and Chamber_Arrays. The current instrument has four tracks of sixteen boolean steps and a separate twelve-column floor; rewrite from the actual score.

## Color and Composition

### [Color Context Placed](http://localhost:3003/tutorial-cards?map=Color_Context_Placed)

Palette lookup · Colour assignment · Grouping · Geometry and appearance

- **Builds on:** Array: Indices can address retained values and object references.; Primitives Melencolia: An arrangement has separately chosen positions and parts.; Tutorial Disco: An index can select a value under a repeated rule.
- **Adds/deepens:** Practice of lookup and assignment with colour as the stored value.
- **Carries:** A palette and selection rule separable from geometry and placement.
- **Review:** Focus needs revision. The companion mainly describes comparisons and source inventories. Choose one small part/material binding before claiming the learner can author the assignment; do not require the richer dictionary records.

### [Color Flashlight](http://localhost:3003/tutorial-cards?map=Color_Flashlight)

Light colour · Material colour · Receiving surfaces · Controlled comparison

- **Builds on:** Color Context Placed: Colour assignment is distinct from geometry.; Point One: Lighting and a surface's physical boundary are separate.; Point Coordinates: A held object's position changes within a frame.
- **Adds/deepens:** Practice of property assignment; deepens the distinction between a light value and surface appearance.
- **Carries:** A bounded light-colour edit and a comparison with controlled viewing conditions.
- **Review:** Focus fits the text. 

### [Color Nails](http://localhost:3003/tutorial-cards?map=Color_Nails)

Function contracts · Coordinate-to-colour mapping · Clamping · Returned colours

- **Builds on:** Primitives Ignorance: Functions take parameters and return data.; Point Coordinates: Input positions need a stated local frame.; Trans Body: A bounded mapping limits input before assignment.
- **Adds/deepens:** Develops a complete reusable calculation separately from its material receiver.
- **Carries:** A tested position-to-colour function with explicit bounds and return type.
- **Review:** Focus needs revision. The existing text offers observation and signal tracing, not this authored function or preview binding. The salon's retained colours do not automatically feed Rainbow or Grid.

### [Color Rainbow](http://localhost:3003/tutorial-cards?map=Color_Rainbow)

Palettes · Partitions · Fixed total width · Optional composition

- **Builds on:** Color Context Placed: A palette chooses appearance without determining all geometry.; Array: A list can contain a chosen number of entries.
- **Adds/deepens:** Reflection and optional composition; distinguishes list length from the span it partitions.
- **Carries:** A palette/partition distinction without a new syntax requirement.
- **Review:** Focus fits the text. 

### [Color Pillar](http://localhost:3003/tutorial-cards?map=Color_Pillar)

HSV coordinates · Function substitution · Coordinate adapters · Sampling

- **Builds on:** Color Nails: A function can return a bounded colour for a position.; Point Coordinates: A coordinate frame and its scale must be named.; Color Flashlight: Equal assigned values do not imply equal appearance.
- **Adds/deepens:** Deepens function reuse through another coordinate convention and an explicit input adapter.
- **Carries:** An interchangeable colour function whose coordinate assumptions are visible.
- **Review:** Focus needs revision. The companion explains sampling well but does not teach the proposed returning function or its learner binding. Keep physical hand height distinct from field height and avoid an automatic Grid transfer claim.

### [Color Grid Pallet](http://localhost:3003/tutorial-cards?map=Color_Grid_Pallet)

Classes · Instance state · Methods · Palette indices · Addressed assignment

- **Builds on:** Point Lines: PointBody introduced an authored class and independent instances; Palette adds methods that change each instance’s own state.; Primitives Ignorance: Parameters and return values give methods a readable function contract.; Array: Independent references and indexed values must be distinguished.; Color Nails: A returned Color can be assigned by a separate receiver.
- **Adds/deepens:** Deepens the authored class introduced in Lines with changing instance state and methods; separate palettes keep independent indices.
- **Carries:** Two palette instances and a colour result that can be written to a named address.
- **Review:** Focus needs revision. The proposed Palette class, methods and two-instance exercise are absent. Current COLOUR cycles four INKS and writes MultiMesh instance colours; no per-cell material or custom function binding is delivered.

### [Color Paint](http://localhost:3003/tutorial-cards?map=Color_Paint)

Named actions and interaction states · Ray targets · Surface coordinates · Shared drawing methods · Interaction feedback

- **Builds on:** Point Coordinates: Pickup/release and conversion between local and world frames.; Point Trace: A retained position list provides a contrast with an evolving image.; Trans Introduction: Signals call handlers; state and feedback describe different stages.; Color Nails: A colour value can be supplied to a shared operation.
- **Adds/deepens:** Adds named actions, held/active conditions, eligible ray targets, world-to-surface coordinates and a reusable receiver method.
- **Carries:** An input-to-receiver chain with distinct action and hit feedback; manual and automatic callers can use the same drawing operation.
- **Review:** Focus fits the text. Manual interaction now leads; the automatic path returns as a second caller of draw_spray. The canvas is an evolving image, not a stored gesture list. Renderer, input bindings and device setup remain supplied; no new headset test.

### [Color Walls](http://localhost:3003/tutorial-cards?map=Color_Walls)

Palette composition · Independent state · Part arrangements · Transparency and passage

- **Builds on:** Color Grid Pallet: A palette instance owns its current state.; Color Nails: A returning function separates calculation from assignment.; Primitives Melencolia: Placement changes relationships among fixed forms.
- **Adds/deepens:** Composition and practice of foundation concepts; no required new syntax.
- **Carries:** An explained arrangement combining functions, assignment and separate state.
- **Review:** Focus needs revision. The existing pane and palette edits remain useful, but the proposed class-instance synthesis is absent because Grid's class is not taught. The spacing prose says 0.18 while its example uses 0.21; resolve during lesson revision.

## Patterns: Dress the Architecture

### [Pattern Disco](http://localhost:3003/tutorial-cards?map=Pattern_Disco)

Palette substitution · Pattern values · Phase · Independent clocks

- **Builds on:** Color Walls: A palette can change while an arrangement stays fixed.; Tutorial Disco: A score and its clock have separate state.; Color Grid Pallet: A lookup selects an assigned colour.
- **Adds/deepens:** Practice and comparison of value, reader and appearance; no new data structure.
- **Carries:** A controlled distinction between palette substitution and a changed pattern input.
- **Review:** Focus fits the text. 

### [Pattern Foundry](http://localhost:3003/tutorial-cards?map=Pattern_Foundry)

Source arrays · Wrapped lookup · Palette indices · Copies and references

- **Builds on:** Array: An indexed write changes one retained entry.; Pattern Disco: A palette reads values without changing their pattern.; Tutorial Tiling Floor: Remainder supplies repeating addresses.
- **Adds/deepens:** Deepens addressed data into a source-and-reader pair, then independent copies versus shared references.
- **Carries:** A motif with an explicit reader and a stated copy/reference relationship.
- **Review:** Focus needs revision. The current companion documents many studio receivers and save/hold controls, but does not teach the reduced source array or copy exercise. A held texture is not the implementation of a copied nested source array.

### [Tutorial Pattern](http://localhost:3003/tutorial-cards?map=Tutorial_Pattern)

Reflected lookup · Source mutation · Asymmetric motifs · Translation period

- **Builds on:** Pattern Foundry: A source record is distinct from the rule reading it.; Tutorial Tiling Floor: Address rules repeat a motif.; Trans Rotation: A spatial operation changes orientation.
- **Adds/deepens:** Deepens source-versus-reader reasoning through reflection and an observable two-column repeat.
- **Carries:** A diagnostic motif that distinguishes transformed reads from changed data.
- **Review:** Focus fits the text. 

### [Array Patterns](http://localhost:3003/tutorial-cards?map=Array_Patterns)

Surface addresses · Local axes · Physical cell width · Repeat span

- **Builds on:** Tutorial Pattern: Wrapped reads can repeat one source without altering it.; Point Coordinates: Different surfaces need named frames.; Tutorial Tiling Walls: The receiver affects appearance and physical access separately.
- **Adds/deepens:** Deepens address conversion by giving one source cell an explicit physical scale.
- **Carries:** A surface-to-source mapping with stated axes, origin and cell width.
- **Review:** Focus fits the text. 

### [Symmetry Seventeen](http://localhost:3003/tutorial-cards?map=Symmetry_Seventeen)

Reflection · Glide reflection · Symmetry-breaking marks · Translation periods

- **Builds on:** Tutorial Pattern: An asymmetric source can reveal a reflected read.; Pattern Foundry: A palette-index source is sampled through a chosen rule.
- **Adds/deepens:** Adds a bounded glide operation and deepens construction rule versus resulting symmetry.
- **Carries:** A tested motif and period with limits on what the comparison establishes.
- **Review:** Focus fits the text. 

### [Ribbon Patterns 01](http://localhost:3003/tutorial-cards?map=Ribbon_Patterns_01)

Layered arrays · Storage conventions · Height-dependent lookup · Value meaning

- **Builds on:** Tutorial 3D: Displayed XYZ and stored YZX have an explicit conversion.; Pattern Foundry: A source array can be read repeatedly through another address.
- **Adds/deepens:** Composition of volume addressing and wrapped lookup; adds height as an input to the reader.
- **Carries:** A layered reader whose storage order and value meaning are declared.
- **Review:** Tutorial missing. tutorial.md is absent. Keep sixteen visible slice entries distinct from sixty-four stored entries; this uses a fixed motif rather than importing the student's earlier edit.

### [Ribbon Patterns 02](http://localhost:3003/tutorial-cards?map=Ribbon_Patterns_02)

Numerical equality · Surrounding colour · Surface spacing · Projected appearance

- **Builds on:** Color Flashlight: Appearance depends on receiving and viewing conditions.; Array Patterns: Physical cell spacing differs from the whole repeat span.; Pattern Foundry: The same source can have different receivers.
- **Adds/deepens:** Reflective practice of controlled comparison; no new code or dot-product prerequisite.
- **Carries:** An explanation separating equal values and distances from viewed appearance.
- **Review:** Tutorial missing. tutorial.md is absent. A short comparison lesson is enough; no perceptual response, spectral-metamerism result or new shader authorship is required here.

### [Ribbon Patterns 03](http://localhost:3003/tutorial-cards?map=Ribbon_Patterns_03)

Texture coordinates · Repeat and offset · Fragment output · Saved recipes

- **Builds on:** Array Patterns: Physical spacing and repeated source cells have separate meanings.; Pattern Foundry: A source and saved version are distinct from their current receiver.; Ribbon Patterns 02: Equal UV counts need not give equal physical spacing.
- **Adds/deepens:** Introduces a small fragment sampling operation through an explained existing host.
- **Carries:** A repeat-and-offset shader operation plus a bounded saved appearance recipe.
- **Review:** Tutorial missing. tutorial.md is absent. Select the excerpt and edit location in the existing host. SAVE stores supported cells/settings, not palette, shader source, mesh or a general garment; deformation waits for Shaders.

## Change: Rate, Accumulation, and Flow

### [Change Intro](http://localhost:3003/tutorial-cards?map=Change_Intro)

Finite differences · Signed intervals · Finite sums · Sample rules · Numerical references

- **Builds on:** Point Lines: A difference describes change between two values.; Primitives Portals: Traversal can accumulate a scalar total.; Primitives Ignorance: A function has explicit inputs and a returned value.
- **Adds/deepens:** Adds rate per input unit and numerical accumulation as two separate mathematical operations.
- **Carries:** Small rate and sum functions with declared domain, units and sampling rule.
- **Review:** Focus needs revision. The current companion describes the workbenches and calculations, but no exact learner edit/receiver binding. Keep the bridge's different arch and signed-rate sum separate; the 4096-sample reference is finite.

### [Flow Field](http://localhost:3003/tutorial-cards?map=Flow_Field)

Field sampling · Position updates · Prescribed velocity · Retained trails

- **Builds on:** Trans Pre: Elapsed seconds determine a time-based displacement.; Point Trace: A retained trail connects ordered sampled positions.; Change Intro: An update has stated input units and finite step size.
- **Adds/deepens:** Adds repeated lookup at the newly reached address; velocity is prescribed rather than retained.
- **Carries:** A field follower and record with a declared canvas frame and boundary policy.
- **Review:** Focus needs revision. The companion names the sampler but omits the selected learner update binding. Canvas y maps to local Z before display rotation. Existing wrap lines and RESET/SPEED do not implement a controlled timestep comparison.

## Vectors & Forces: From Direction to Dynamics

### [Vectors Act1 WhatAVectorIs](http://localhost:3003/tutorial-cards?map=Vectors_Act1_WhatAVectorIs)

Displacement · Magnitude and direction · Normalization · Display scale

- **Builds on:** Point Lines: Subtracting positions gives a displacement and scalar length.; Point Coordinates: World and display frames must be distinguished.
- **Adds/deepens:** Practice of displacement with an explicit normalization return and threshold.
- **Carries:** A direction-and-magnitude account that separates measured data from its scaled drawing.
- **Review:** Focus needs revision. The companion lists normalization thresholds but does not explain division by length as the selected learner operation. Translation has not yet delivered its proposed normalization practice; supply or teach this short return explicitly.

### [VFM 02 Operations](http://localhost:3003/tutorial-cards?map=VFM_02_Operations)

Vector addition · Resultant displacement · Route length · Coordinate conversion

- **Builds on:** Point Lines: Displacement and length retain different information.; Primitives Portals: A running sum can accumulate neighbouring distances.; Trans Translation: An ordered route preserves intermediate travel.
- **Adds/deepens:** Deepens vector addition by separating summed destination from summed travelled lengths.
- **Carries:** A result vector and route-distance account in a declared local frame.
- **Review:** Focus fits the text. 

### [Vectors Act2 VectorArithmetic](http://localhost:3003/tutorial-cards?map=Vectors_Act2_VectorArithmetic)

Signed dot product · Projection · Remainders · Recombination

- **Builds on:** Point Lines: Subtraction gives the gap between positions.; Vectors Act1 WhatAVectorIs: A normalized axis supplies direction independently of length.; VFM 02 Operations: Vector sums can recombine contributions.
- **Adds/deepens:** Adds signed scalar projection, its vector component and complementary remainder.
- **Carries:** A projection-plus-remainder construction with an explicit receiving axis.
- **Review:** Focus fits the text. 

### [VFM 05 Launch](http://localhost:3003/tutorial-cards?map=VFM_05_Launch)

Position functions · Initial velocity · Acceleration · Model assumptions

- **Builds on:** Trans Pre: Elapsed time is an input to a prescribed position.; Change Intro: Rate has declared units.; Vectors Act1 WhatAVectorIs: Vector components and display scale have separate meanings.
- **Adds/deepens:** Adds velocity and acceleration units in a supplied analytic prediction; no integrator is introduced.
- **Carries:** A position-at-time function with equal-height, uniform-gravity and no-drag assumptions.
- **Review:** Focus fits the text. 

### [VFM 03 Motion](http://localhost:3003/tutorial-cards?map=VFM_03_Motion)

Force schedules · Mass · Retained velocity · Engine integration

- **Builds on:** VFM 05 Launch: Initial velocity is distinct from a position evaluated at time.; Change Intro: Rate and accumulated change have stated units.; Trans Pre: A timed condition can delimit a command.
- **Adds/deepens:** Adds a force receiver whose velocity persists after the command ends.
- **Carries:** A force schedule and quantitative velocity-change prediction.
- **Review:** Focus needs revision. The existing operating/source companion explains the engine force command but does not provide the proposed learner schedule binding. Pass force in newtons without another dt factor; COAST alone leaves optional damping active.

### [Vectors Act3 FieldsAndMotion](http://localhost:3003/tutorial-cards?map=Vectors_Act3_FieldsAndMotion)

Position and velocity state · Assignment and accumulation · Acceleration updates · Reset conditions

- **Builds on:** Flow Field: A follower resamples at its current position.; VFM 03 Motion: Velocity can survive a changed command.; Change Intro: A finite update accumulates a rate over time.
- **Adds/deepens:** Adds explicit position/velocity state and an assignment-versus-accumulation comparison.
- **Carries:** A small update convention reusable by later forces, with its receiver units stated.
- **Review:** Focus needs revision. The source rules are described, but the proposed reduced learner function and runner connection are absent. The markers have no mass or collisions and sample different values after their positions diverge; no learner state travels between halls.

### [Vectors Act4a KineticForces](http://localhost:3003/tutorial-cards?map=Vectors_Act4a_KineticForces)

Velocity-dependent force · Linear drag · Mass response · Receiver contracts

- **Builds on:** VFM 03 Motion: The engine integrates force commands for a body with mass.; Vectors Act3 FieldsAndMotion: Force, acceleration and assigned velocity require different receiving operations.
- **Adds/deepens:** Adds a force that depends on the receiver's current velocity.
- **Carries:** A reusable linear resistance calculation with coefficient units and receiver responsibility.
- **Review:** Focus needs revision. The companion documents -b*v but does not bind a learner drag function. WALK uses a separate multiplier, mower work is nominal and the ring prescribes motion; none substitutes for the chosen force exercise.

### [Vectors Act4b Oscillation](http://localhost:3003/tutorial-cards?map=Vectors_Act4b_Oscillation)

Restoring force · Damping · Equilibrium · State integration

- **Builds on:** Vectors Act3 FieldsAndMotion: The proposed explicit state update separates velocity from position.; Vectors Act4a KineticForces: Resistance depends on velocity.; Point Lines: Displacement can measure distance from a chosen centre.
- **Adds/deepens:** Adds F=-kx-cv to an existing state-update pattern; equilibrium need not mean rest.
- **Carries:** A spring-damper calculation distinct from a prescribed sine animation.
- **Review:** Focus needs revision. The current model is explained but the common learner update/binding is still proposed. DAMP selects a ratio, so fixed-ratio changes of mass or stiffness also change the coefficient; release starts from rest.

### [Change Choreography](http://localhost:3003/tutorial-cards?map=Change_Choreography)

Period · Phase · Relative rate · Accumulated angle

- **Builds on:** Trans Pre: An angle can advance with elapsed seconds.; Change Intro: A rate difference accumulates a change.; Vectors Act4b Oscillation: Returning motion motivates a cycle without already teaching phase.
- **Adds/deepens:** Introduces period and phase; deepens assigned offsets versus accumulated rate difference.
- **Carries:** A quantitative prediction of two stored angles under changed rates.
- **Review:** Focus fits the text. 

### [VFM 07 Gravity](http://localhost:3003/tutorial-cards?map=VFM_07_Gravity)

Pair contributions · Receiving masses · Equal and opposite forces · Held sources

- **Builds on:** Point Lines: Separation supplies an interaction's direction and length.; VFM 03 Motion: Force and receiving mass determine acceleration.; Vectors Act3 FieldsAndMotion: Independent bodies need separately retained state.
- **Adds/deepens:** Adds distributing one interaction to two recipients rather than writing a new gravity solver.
- **Carries:** A pairwise contribution pattern with explicit fixed or responsive recipients.
- **Review:** Focus needs revision. The tutorial describes the model but does not teach the proposed two-contribution exercise. The fixed and mutual stations also change masses and initial states, so their paths cannot isolate source release alone.

### [VFM 09 Legs](http://localhost:3003/tutorial-cards?map=VFM_09_Legs)

Support polygons · Mass projection · Static balance · Model limits

- **Builds on:** Point Triangle Context: A boundary can describe a geometric region.; VFM 03 Motion: Engine-integrated motion differs from prescribed placement.
- **Adds/deepens:** Practice and physical comparison of geometry and mass; no new hull or gait implementation.
- **Carries:** An explicit support hypothesis with assumptions about pads, load and contact.
- **Review:** Focus fits the text. 

### [VFM 08 Arena](http://localhost:3003/tutorial-cards?map=VFM_08_Arena)

Eligibility conditions · Occlusion · Event history · Authored thresholds

- **Builds on:** Point Lines: Distance can enter a condition.; Trans Body: A current test differs from retained state.; VFM 09 Legs: Commanded behaviour and physical validation are different kinds of evidence.
- **Adds/deepens:** Reflective practice of conditions and retained events; no new controller syntax.
- **Carries:** A distinction between eligible targets, recorded events and attributed agency.
- **Review:** Focus fits the text. 

### [Vectors Act5 ForceAsPlace](http://localhost:3003/tutorial-cards?map=Vectors_Act5_ForceAsPlace)

Field membership · Acceleration · Retained velocity · Receiver adapters

- **Builds on:** Vectors Act3 FieldsAndMotion: Acceleration changes stored velocity rather than replacing it.; VFM 03 Motion: A body retains motion when a command ends.; Point Coordinates: The field and recipient need named coordinate frames.
- **Adds/deepens:** Composition of field input with declared receivers and entry/exit rules.
- **Carries:** A receiver-aware account of acceleration, membership and persistent motion.
- **Review:** Focus fits the text. 

## Form Finding: Rules, Constraints and Possible Shapes

### [FormFinding Descent](http://localhost:3003/tutorial-cards?map=FormFinding_Descent)

Cost functions · Finite-difference gradients · Search steps · Stopping reasons

- **Builds on:** Change Intro: Finite differences estimate local rates.; Vectors Act3 FieldsAndMotion: An update's state and units determine its meaning.; Vectors Act5 ForceAsPlace: Retained velocity provides a contrast with this velocity-free search.
- **Adds/deepens:** Adds a two-axis cost gradient and descent update with separate slope, frame and budget stops.
- **Carries:** A local search rule with a declared objective, step and reason for stopping.
- **Review:** Focus fits the text. 

### [FormFinding Catenary](http://localhost:3003/tutorial-cards?map=FormFinding_Catenary)

Boundary conditions · Drafted curves · Evaluated curves · Physical constraints

- **Builds on:** Primitives Profiles: A profile or path can be evaluated by a supplied construction.; Primitives Ignorance: A function's inputs determine generated positions.; FormFinding Descent: A computed objective must be distinguished from a drawn result.
- **Adds/deepens:** Reflective comparison of drawn, evaluated and physically settled constructions; no required new syntax.
- **Carries:** A curve specification that names its inputs and absent physical tests.
- **Review:** Focus needs revision. Current prose calls the drafted sag curve gravity-derived and the fixed catenoid an instantly solved minimum. Align it with the actual spline/formula/static-surface comparison; decide whether a bounded code exercise is needed.

### [FormFinding Relaxation](http://localhost:3003/tutorial-cards?map=FormFinding_Relaxation)

Position history · Rest lengths · Constraint corrections · Pinned endpoints · Iteration budgets

- **Builds on:** Point Trace: Position history can be retained in ordered lists.; Point Lines: Neighbour distance gives a measurable error.; Primitives Polythedra: Connections are data separate from positions.
- **Adds/deepens:** Adds repeated local distance correction under a finite computation budget.
- **Carries:** A constrained network with explicit anchors, rest lengths and correction count.
- **Review:** Focus needs revision. The current tutorial jumps through full cloth and frozen forms, divides by cur without a zero guard and overstates a one-over-passes law. The proposed short-chain binding and pinned-end correction explanation are absent.

### [FormFinding Equilibrium](http://localhost:3003/tutorial-cards?map=FormFinding_Equilibrium)

Lever balance · Mass-distance products · Solved arm lengths · Model assumptions

- **Builds on:** Point Lines: Distances can become inputs to a numerical constraint.; Primitives Ignorance: A small returning function can generate geometry parameters.; VFM 09 Legs: Static balance is conditional and differs from a demonstrated dynamic response.
- **Adds/deepens:** Adds an algebraic balance function; recursion and larger structural construction remain supplied.
- **Carries:** A lever calculation with omitted rod/wire mass and other assumptions stated.
- **Review:** Focus needs revision. The lever calculation is present, but the tutorial expands into untaught recursion and claims strength and force balance from prescribed geometry/scale motion. Select the small function and separate display from mechanical validation.

### [FormFinding Annealing](http://localhost:3003/tutorial-cards?map=FormFinding_Annealing)

Bounded random draws · Candidate proposals · Acceptance conditions · Temperature · Current and best states

- **Builds on:** FormFinding Descent: A cost function evaluates a proposed search address.; Point Trace: A condition selects which value to retain.; Trans Body: Current state and remembered state can serve different purposes.
- **Adds/deepens:** Introduces a local bounded random draw and probability comparison before Randomness, then non-greedy search.
- **Carries:** A probabilistic acceptance rule with separate current and best records.
- **Review:** Focus needs revision. The tutorial uses randf/randf_range before explaining range and draw timing, and lacks the selected best-so-far exercise. Stagnation is not proof of entrapment and cooling does not guarantee escape or optimality.

### [FormFinding Forge](http://localhost:3003/tutorial-cards?map=FormFinding_Forge)

Success predicates · Duration thresholds · Restart conditions · Physical and prescribed outcomes

- **Builds on:** Trans Body: A current condition can update remembered state.; Trans Pre: Elapsed time can accumulate while a condition holds.; FormFinding Descent: A search stop does not itself establish a satisfactory outcome.
- **Adds/deepens:** Composition of conditions, timers and criteria; no new syntax or universal optimum is introduced.
- **Carries:** An explicit success criterion and a counterexample it correctly rejects.
- **Review:** Focus needs revision. The tutorial omits the stack's height requirement and presents the clock-driven target/jitter as optimised physical form. Confirm the measurement interface and distinguish stability detection, search restarts and prescribed MAX Q appearance.

## Wavefunctions: What Returns

### [WaveFunctions Intro](http://localhost:3003/tutorial-cards?map=WaveFunctions_Intro)

Angular state · Release velocity · Restoring acceleration

- **Builds on:** Vectors Act4b Oscillation: Retained velocity, restoration and damping.; VFM 02 Operations: Projection of a velocity onto a chosen direction.
- **Adds/deepens:** Extend the retained motion state to angle and angular velocity.
- **Carries:** An angular update with explicit initial state.
- **Review:** Focus fits the text. 

### [WaveFunctions Pendulum](http://localhost:3003/tutorial-cards?map=WaveFunctions_Pendulum)

Timestamped records · Sampling intervals · Memory limits

- **Builds on:** Point Trace: An ordered list of retained positions.; WaveFunctions Intro: A moving source whose angle and velocity remain distinct.
- **Adds/deepens:** Attach a time to each sample and distinguish sample count from retained duration.
- **Carries:** A bounded recorder with an explicit sampling contract.
- **Review:** Focus needs revision. The lesson stores time in Vector3.z; the proposed named position/time record needs an explicit data contract and learner edit.

### [WaveFunctions Sine Space](http://localhost:3003/tutorial-cards?map=WaveFunctions_Sine_Space)

Spatial sine sampling · Height fields · Collision boundaries

- **Builds on:** Point Line Grid: Addresses for neighbouring samples.; Primitives Polythedra: Vertex and face connectivity.; Trans Introduction: A first usable sine rule.
- **Adds/deepens:** Apply a periodic function to spatial coordinates and separate sampled geometry from physical contact.
- **Carries:** A static sine height field with a stated collision receiver.
- **Review:** Focus needs revision. The current text explains the existing tray and corridor; a reduced learner grid and face-building operation are not yet supplied.

### [WaveFunctions Unit Circle](http://localhost:3003/tutorial-cards?map=WaveFunctions_Unit_Circle)

Circular coordinates · Radians · Phase · Coordinate projections

- **Builds on:** Trans Rotation: Rotation about a centre.; WaveFunctions Sine Space: Sine already used as a spatial rule.
- **Adds/deepens:** Derive two coordinate offsets from one angle and radius.
- **Carries:** An understood circle sampler with a named centre.
- **Review:** Focus needs revision. The recipe omits a centred learner function and contains an incorrect quarter-turn chord claim; the supplied runner reference and phase account need alignment.

### [WaveFunctions 3D Wave Propagation](http://localhost:3003/tutorial-cards?map=WaveFunctions_3D_Wave_Propagation)

Neighbour coupling · Synchronous updates · Disturbance propagation

- **Builds on:** Vectors Act4b Oscillation: A restoring state update.; Tutorial 3D: Addressed state collections; revisit the indexing convention.
- **Adds/deepens:** Let neighbouring state differences transmit a disturbance without an imposed delay formula.
- **Carries:** A local interaction rule with separate old and next states.
- **Review:** Focus needs revision. The existing lesson builds distance-delayed sources and pebble emitters, not the storyboard's coupled lattice.

### [WaveFunctions Effect Sound](http://localhost:3003/tutorial-cards?map=WaveFunctions_Effect_Sound)

Signal sampling · Phase modulation · Amplitude envelopes

- **Builds on:** WaveFunctions Unit Circle: Angle, phase and sine evaluation.; WaveFunctions Pendulum: Sampling with an explicit time coordinate.
- **Adds/deepens:** Compose functions inside phase and distinguish that operation from adding two output signals.
- **Carries:** A readable phase-modulated signal and its envelope.
- **Review:** Focus fits the text. 

### [Wavefunctions Bernini](http://localhost:3003/tutorial-cards?map=Wavefunctions_Bernini)

Ring sampling · Height-dependent twist · Spatial and temporal variation

- **Builds on:** WaveFunctions Unit Circle: Circular coordinate sampling.; Primitives Polythedra: Faces connect known vertex addresses.
- **Adds/deepens:** Compose circular sampling with a height-dependent angular offset.
- **Carries:** A short shaft generator separating shape from its motion.
- **Review:** Focus needs revision. The current recipe displaces ring centres instead of rotating their profiles and has an incomplete triangle strip; the intended short shaft still needs a sound construction.

### [WaveFunctions John Cage](http://localhost:3003/tutorial-cards?map=WaveFunctions_John_Cage)

Chance scores · Event intervals · Prepared vocabularies

- **Builds on:** Tutorial Disco: A clock reading an ordered score.; FormFinding Annealing: A bounded random proposal, to be re-explained if unfamiliar.
- **Adds/deepens:** Compose earlier timing and random choice; distinguish a chosen vocabulary from its sampled order.
- **Carries:** An inspectable finite chance score.
- **Review:** Focus needs revision. The current lesson claims ambient breath measurement and a Cage performance; it does not implement the proposed replayable score from supplied sounds.

### [WaveFunctions AirMusic](http://localhost:3003/tutorial-cards?map=WaveFunctions_AirMusic)

Event-driven voices · Independent clocks · Decay envelopes · Signal addition

- **Builds on:** WaveFunctions Effect Sound: A sampled sine multiplied by an amplitude envelope.; Trans Introduction: Elapsed time and conditional state changes.
- **Adds/deepens:** Give each event its own beginning and distinguish restarting one voice from adding another.
- **Carries:** A voice-state account with separate start times and summed signals.
- **Review:** Focus fits the text. 

### [Wavefunctions Sky Stairs](http://localhost:3003/tutorial-cards?map=Wavefunctions_Sky_Stairs)

Helical sampling · Tread orientation · Clearance

- **Builds on:** WaveFunctions Unit Circle: Circular positions from angle and radius.; Trans Body: A visible body and its collision boundary.
- **Adds/deepens:** Compose known sampling and transforms into a support arrangement.
- **Carries:** A short route segment with separate geometry and support decisions.
- **Review:** Focus needs revision. The current opening corrects the installed radial modulation, but the preserved lesson builds an obsolete variable-rise proposal; a reduced tread construction is absent.

### [WaveFunctions TrigWalkingPath](http://localhost:3003/tutorial-cards?map=WaveFunctions_TrigWalkingPath)

Signal superposition · Beat envelopes · Display scales

- **Builds on:** WaveFunctions Effect Sound: A sampled time-to-signal function.; WaveFunctions AirMusic: Addition of independently timed signals.
- **Adds/deepens:** Compare cancellation and reinforcement without inventing a third oscillator.
- **Carries:** A two-signal comparison with its raw sum retained.
- **Review:** Focus needs revision. The current introduction names the beat exhibit; the main recipe still teaches an archived endless walking path rather than the proposed sum.

### [WaveFunctions Synthesis Lab](http://localhost:3003/tutorial-cards?map=WaveFunctions_Synthesis_Lab)

Harmonic coefficients · Weighted sums · Finite representations

- **Builds on:** WaveFunctions TrigWalkingPath: Signed addition at a shared sample time.; WaveFunctions AirMusic: A sum depends on levels and phase.
- **Adds/deepens:** Generalize two-signal addition to a list of weighted harmonics.
- **Carries:** A finite wave recipe with explicit range and phase limitations.
- **Review:** Focus fits the text. 

## Randomness: What Can Chance Change?

### [Random Definition](http://localhost:3003/tutorial-cards?map=Random_Definition)

Seeded generators · Draw order · Value assignments

- **Builds on:** FormFinding Annealing: A bounded draw already used for a proposal.; Color Grid Pallet: Addressed colour values.; Color Nails: A value passed to a declared receiver; revisit the planned function interface.
- **Adds/deepens:** Deepen random choice into a reproducible reset-request-assign procedure.
- **Carries:** A seed kept with its ordered requests and assignments.
- **Review:** Focus fits the text. The making lesson is substantive, but its standalone study still needs the proposed museum colour-list adapter.

### [Random Entropy](http://localhost:3003/tutorial-cards?map=Random_Entropy)

Frequency tables · Copied records · Marginal entropy

- **Builds on:** Random Definition: A retained seeded sample and declared request order.
- **Adds/deepens:** Reduce a sequence to counts without confusing that reduction with its arrangement.
- **Carries:** A sample-to-count operation and a separately retained original record.
- **Review:** Focus fits the text. 

### [Random Remove](http://localhost:3003/tutorial-cards?map=Random_Remove)

Eligibility filters · Sampling without replacement · Replacement policies

- **Builds on:** Random Definition: A bounded draw from a local generator.; Point Line Grid: Spatial addresses separate from list indices.
- **Adds/deepens:** Make the set of possible choices and its evolution explicit.
- **Carries:** A remaining-candidates list and a stated replacement rule.
- **Review:** Focus needs revision. The current board clearly teaches filtering and removal; the with-replacement comparison and its small learner receiver remain to be written.

### [Randomness 10 PRINT Algorithm](http://localhost:3003/tutorial-cards?map=Randomness_10_PRINT_Algorithm)

Binary choices · Grid traversal · Mark interpretation

- **Builds on:** Point Lines: Two endpoints define a line.; Random Definition: Ordered draws and replay.; Tutorial Tiling Floor: One assigned value selects a tile's orientation.
- **Adds/deepens:** Compose known traversal, conditions and random choice into a two-mark pattern.
- **Carries:** An addressed binary-mark generator.
- **Review:** Focus fits the text. The current recipe's infinite-pattern and maze claims exceed its finite drawing; route connectivity is not established.

### [Random Cubes](http://localhost:3003/tutorial-cards?map=Random_Cubes)

Event accumulators · Stopping conditions · Outcome histories

- **Builds on:** Random Entropy: A retained outcome list differs from its summary.; WaveFunctions AirMusic: An event starts or changes state once.
- **Adds/deepens:** Accumulate asynchronously supplied outcomes under a conditional stopping rule.
- **Carries:** A bounded die-chain record with total and completion state.
- **Review:** Focus needs revision. The current tutorial constructs random cube-edge profiles; it does not teach the physical die chain or accepted landing-event accumulator.

### [Random Rotate Random XYZ](http://localhost:3003/tutorial-cards?map=Random_Rotate_Random_XYZ)

State accumulation · Random increments · Orientation histories

- **Builds on:** Trans Rotation: An angle changes orientation.; Random Definition: Explicit draw requests.
- **Adds/deepens:** Deepen the difference between assigning state and accumulating a change.
- **Carries:** An orientation record with an explicit update cadence.
- **Review:** Focus needs revision. The historical XYZ recipe differs from the current accumulated in-plane rotation and mistakes a clock-bit expression for hardware entropy.

### [Random Walk](http://localhost:3003/tutorial-cards?map=Random_Walk)

Random displacements · Boundary rules · Position histories

- **Builds on:** Random Rotate Random XYZ: An increment changes retained state.; WaveFunctions Unit Circle: Direction from sine and cosine.; Point Trace: Retained positions do not themselves control the next step.
- **Adds/deepens:** Move the accumulation into position and make enclosure corrections part of the rule.
- **Carries:** A walker whose proposal, accepted position and history stay distinct.
- **Review:** Focus fits the text. 

### [Random Gaussian](http://localhost:3003/tutorial-cards?map=Random_Gaussian)

Histograms · Distribution comparisons · Clipping and binning

- **Builds on:** Random Entropy: Counts summarize a retained record.; Random Walk: A draw and its stored observation are different operations.
- **Adds/deepens:** Group numerical samples by interval while retaining values for another partition.
- **Carries:** A rebinning procedure with a declared sampling and display range.
- **Review:** Focus fits the text. 

### [Random Mushrooms](http://localhost:3003/tutorial-cards?map=Random_Mushrooms)

Population records · Discrete templates · Continuous variation

- **Builds on:** Random Gaussian: State which sampling law generates a parameter.; Random Definition: Preserve draw consumption while changing a value's use.
- **Adds/deepens:** Compose separate sampled assignments into a reproducible population recipe.
- **Carries:** A population record separating kind, placement and scale.
- **Review:** Focus needs revision. The lesson supports controlled specimen comparisons but does not yet build the proposed retained population description or expose its builder contract.

### [Random Space Geometry](http://localhost:3003/tutorial-cards?map=Random_Space_Geometry)

Spatial correlation · Matched sample coordinates · Neighbour differences

- **Builds on:** Random Definition: Independent draw requests.; Point Line Grid: A declared grid of sample coordinates.
- **Adds/deepens:** Investigate relations among neighbouring values instead of only their distribution.
- **Carries:** A matched profile comparison with stated coordinate spacing.
- **Review:** Focus needs revision. The current tutorial creates random panel chambers; the storyboard centres the white-noise/Perlin comparison bench.

### [Randomness Examples of Randomness](http://localhost:3003/tutorial-cards?map=Randomness_Examples_of_Randomness)

Monte Carlo estimates · Hit tests · Finite-sample error

- **Builds on:** Random Entropy: A sample count and proportion.; VFM 02 Operations: Distance from a chosen centre.
- **Adds/deepens:** Use a random sample to estimate an area ratio.
- **Carries:** A sample-test-count estimate with its sampling assumptions stated.
- **Review:** Focus needs revision. The existing survey explains the estimate but does not provide the bounded learner sampler and hit-test operation.

### [Random Pheromone](http://localhost:3003/tutorial-cards?map=Random_Pheromone)

Signal fields · Deposition and decay · Feedback

- **Builds on:** Random Walk: Position updates and a record independent of the next step.; Random Remove: Eligible alternatives precede a choice.
- **Adds/deepens:** Make a retained trace participate in future decisions.
- **Carries:** A walker-to-field feedback rule distinct from terrain height.
- **Review:** Focus needs revision. Weighted choice and coordinate helpers are unexplained; the function called trail_entropy computes a mean and cannot support the claimed entropy interpretation.

### [Random Space](http://localhost:3003/tutorial-cards?map=Random_Space)

Multiscale sampling · Weighted field sums · Retained contributions

- **Builds on:** WaveFunctions Synthesis Lab: A weighted sum over a list.; Random Space Geometry: Field sampling at declared coordinates.
- **Adds/deepens:** Transfer harmonic composition to a finite field recipe with separate scale and amplitude.
- **Carries:** A field recipe whose layers can be inspected and recombined.
- **Review:** Focus needs revision. The current lesson assembles unrelated finale specimens instead of the noise mixer's weighted layers.

### [Random Game](http://localhost:3003/tutorial-cards?map=Random_Game)

Stored deadlines · Decision timing · State disclosure

- **Builds on:** WaveFunctions John Cage: Timed event choices.; Random Definition: A seed and procedure locate draw decisions.
- **Adds/deepens:** Deepen timed state into a distinction between deciding, retaining and revealing.
- **Carries:** A readable event schedule with explicit decision times.
- **Review:** Focus fits the text. The tutorial supports tracing the existing wait; an executable learner schedule remains a separate proposed adapter.

## Noise: Fields and Possible Bodies

### [Random Noise Types](http://localhost:3003/tutorial-cards?map=Random_Noise_Types)

Rejection sampling · Minimum spacing · Attempt budgets

- **Builds on:** Random Remove: An admission rule defines eligible choices.; Random Walk: Distance and an explicit boundary rule.
- **Adds/deepens:** Use the growing accepted set to constrain the next random proposal.
- **Carries:** A bounded placement sampler with an honest failure count.
- **Review:** Focus needs revision. The encounter compares spacing and clipping, but the actual proposal/acceptance loop and learner-owned attempt budget are not taught in this file.

### [Noise Columns](http://localhost:3003/tutorial-cards?map=Noise_Columns)

Scalar drivers · Receiving functions · Local clocks

- **Builds on:** WaveFunctions Sine Space: Sine controls a spatial form.; Color Nails: A scalar-to-appearance function; revisit its declared receiver.
- **Adds/deepens:** Separate a source function from the operation that receives its value.
- **Carries:** A driver/receiver pair with a local clock.
- **Review:** Focus fits the text. 

### [Noise One](http://localhost:3003/tutorial-cards?map=Noise_One)

Signed-value mappings · Position offsets · Colour ranges

- **Builds on:** Noise Columns: A scalar source and recipient.; Color Nails: Position and value-to-colour functions.
- **Adds/deepens:** Give the same sample different consequences without changing its source.
- **Carries:** Two explicit mappings from one signed value.
- **Review:** Focus needs revision. The present tutorial is an encounter guide; it does not supply the small learner receiving functions or directly referenced vertices.

### [Noise Voxel](http://localhost:3003/tutorial-cards?map=Noise_Voxel)

Occupancy arrays · Thresholds · Display cuts

- **Builds on:** Tutorial 3D: Multidimensional addressing.; Noise One: A scalar can feed more than one receiver.
- **Adds/deepens:** Convert sampled values into stored occupancy decisions.
- **Carries:** A binary volume inspectable independently of its display.
- **Review:** Focus needs revision. The current text sends the occupancy contract to final.md/technical.md; the reduced learner array and threshold loop still need a tutorial.

### [Noise 6 Wall](http://localhost:3003/tutorial-cards?map=Noise_6_Wall)

Layered fields · Colour composition · Appearance and support

- **Builds on:** Ribbon Patterns 03: An initial texture-sampling shader, still a proposed foundation where unwritten.; Noise One: Separate colour and displacement receivers.; Random Space: A finite weighted field sum.
- **Adds/deepens:** Compose known field and colour operations on a supplied material receiver.
- **Carries:** A colour rule separated from room geometry and support.
- **Review:** Focus needs revision. The lesson exposes the cloud accumulation loop and controls but not the proposed learner colour composition or declared shader host.

### [Noise Inside Noise](http://localhost:3003/tutorial-cards?map=Noise_Inside_Noise)

Domain warping · Function composition · Sampling coordinates

- **Builds on:** Noise One: Separate a sampled value from its output mapping.; Trans Translation: Add an offset in a declared coordinate frame.
- **Adds/deepens:** Compose a coordinate-transform function with a field query.
- **Carries:** A domain-warp function with inspectable input and output addresses.
- **Review:** Focus needs revision. The encounter explains q and p but sends the actual address_at/value_at code to final.md; the learner's two-function construction remains absent.

### [Noise Space 10](http://localhost:3003/tutorial-cards?map=Noise_Space_10)

Terrain sections · Proposed routes · Recorded passage

- **Builds on:** Point Trace: A movement record.; WaveFunctions Sine Space: Sampled surfaces and their collision boundaries.
- **Adds/deepens:** Use an explicit terrain query to compare a geometric proposal with actual passage.
- **Carries:** A terrain-section tool with a declared height query.
- **Review:** Focus needs revision. The existing walking exercise is useful; the reduced profile sampler and triangle-height interface are still not taught here.

### [Noise Perlin Simplex](http://localhost:3003/tutorial-cards?map=Noise_Perlin_Simplex)

Matched comparisons · Generator settings · Value differences

- **Builds on:** Random Space Geometry: Neighbouring field values at declared coordinates.; Noise One: One value can appear as colour or relief.
- **Adds/deepens:** Practice controlled comparison across field implementations.
- **Carries:** A comparison procedure recording coordinates, settings and signed differences.
- **Review:** Focus fits the text. The route sentence still skips the intervening Shader sequence.

### [Lab Path](http://localhost:3003/tutorial-cards?map=Lab_Path)

Encounter accounts · Operation accounts · Return experiments

- **Builds on:** Noise Inside Noise: A distinction between input coordinates and output mapping.; Noise Space 10: A distinction between proposed and experienced passage.
- **Adds/deepens:** Reflect with known tools; no new syntax is required.
- **Carries:** A concrete comparison question for revisiting a Noise hall.
- **Review:** Focus needs revision. The old tutorial builds a generic exit corridor; the storyboard proposes optional reflection and records that this portal is inactive.

## Shaders: What a Surface Answers To

### [Shader 01 Shaping](http://localhost:3003/tutorial-cards?map=Shader_01_Shaping)

Distance masks · Thresholds · Soft edges

- **Builds on:** VFM 02 Operations: Distance between positions.; Ribbon Patterns 03: A first shader host and texture lookup, to be established where missing.
- **Adds/deepens:** Turn a scalar distance into an inside/outside appearance.
- **Carries:** A small mask function and its parameters.
- **Review:** Tutorial missing. No tutorial.md exists. The mask and its host binding remain proposed.

### [Shader 05 Patterns](http://localhost:3003/tutorial-cards?map=Shader_05_Patterns)

Coordinate transforms · Tile addresses · Local coordinates

- **Builds on:** Shader 01 Shaping: A retained mask function; its lesson is currently missing.; Array Patterns: An address selects a sampling rule.; Trans Rotation: Rotation about a named centre.
- **Adds/deepens:** Separate a tile's integer address from the fractional coordinates inside it.
- **Carries:** A mask, coordinate transform and variation rule kept separately.
- **Review:** Focus needs revision. The present companion only changes the garden's phase parameter; it does not teach the proposed transformed mask or integer/fractional tiling.

### [Shader 11 QueerRubber](http://localhost:3003/tutorial-cards?map=Shader_11_QueerRubber)

View-dependent appearance · Dot-product rims · Material receivers

- **Builds on:** VFM 02 Operations: Dot products as alignment.; Shader 01 Shaping: A scalar mapped to appearance; opening lesson still missing.; Color Flashlight: Appearance changes with lighting and viewpoint.
- **Adds/deepens:** Use alignment to make a view-dependent appearance and examine the receiving shape.
- **Carries:** A material rule whose body and viewpoint remain explicit.
- **Review:** Tutorial missing. No tutorial.md exists. A shared learner material switch and vector interface are proposed.

### [Shader 09 FBM](http://localhost:3003/tutorial-cards?map=Shader_09_FBM)

Multiscale loops · Weighted contributions · Boundary disturbance

- **Builds on:** Random Space: Finite weighted field composition.; Shader 01 Shaping: An inspectable mask boundary; its lesson is missing.
- **Adds/deepens:** Move a known finite field sum into a shader and disclose its contribution range.
- **Carries:** A bounded shader field function usable by a mask.
- **Review:** Tutorial missing. No tutorial.md exists. The learner mask-to-field connection remains proposed.

### [Shader 12 PinkExtravaganza](http://localhost:3003/tutorial-cards?map=Shader_12_PinkExtravaganza)

Material composition · Retained recipes · Interpretive choices

- **Builds on:** Shader 05 Patterns: A pattern separated from its coordinates.; Shader 11 QueerRubber: A receiver-aware material; lesson missing.; Shader 09 FBM: A finite field contribution; lesson missing.
- **Adds/deepens:** Compose known operations and explain aesthetic choices without adding compulsory syntax.
- **Carries:** A material recipe and a reasoned alternate version.
- **Review:** Focus needs revision. The current companion edits one limb-unfolding expression; the material-composition lesson and adapter remain proposed.

### [Shader 10 ReactionDiffusion](http://localhost:3003/tutorial-cards?map=Shader_10_ReactionDiffusion)

Retained images · Feedback inputs · State contracts

- **Builds on:** Color Paint: A retained image can preserve previous marks.; WaveFunctions 3D Wave Propagation: Separate old-state reads from next-state writes; proposed lesson needs alignment.; Shader 09 FBM: A function recomputed from coordinates.
- **Adds/deepens:** Specify the memory required by an evolving image without claiming the missing feedback works.
- **Carries:** An explicit previous-state contract for the next simulation.
- **Review:** Tutorial missing. No tutorial.md exists. The storyboard identifies an unbound previous-frame texture; this is a reflective threshold, not a completed reaction-diffusion build.

## Cellular Automata: Local Rules, Global Patterns

### [CA Introduction](http://localhost:3003/tutorial-cards?map=CA_Introduction)

Local transition rules · Synchronous buffers · Boundary conditions

- **Builds on:** Point Line Grid: Addressed values and neighbours.; Shader 10 ReactionDiffusion: The proposed need for retained previous state; tutorial missing.
- **Adds/deepens:** Make a synchronous local-state engine with an explicit edge rule.
- **Carries:** A small row automaton and separate history display.
- **Review:** Focus needs revision. The current encounter refers to _apply_rule and _advance without teaching the learner's readable rule table, array allocation or swap.

### [CA ElementaryRules](http://localhost:3003/tutorial-cards?map=CA_ElementaryRules)

Three-state transitions · Neighbour counts · State and display

- **Builds on:** CA Introduction: An old-state/next-state update.; Tutorial 3D: Three-dimensional cell addresses.
- **Adds/deepens:** Let a state remain visible after it ceases to participate in the active count.
- **Carries:** A three-state transition function with stated participation rules.
- **Review:** Focus needs revision. The encounter supports tracing the three-state volume, but the transition function and neighbourhood contract are not taught; the historical title does not describe an elementary row.

### [CA GameOfLife](http://localhost:3003/tutorial-cards?map=CA_GameOfLife)

History snapshots · Generation coordinates · State receivers

- **Builds on:** CA Introduction: A row engine.; Random Entropy: A copied record must not alias a changing state.; Noise Voxel: Occupancy and its receiver have different responsibilities.
- **Adds/deepens:** Give stored generations a spatial mapping without rerunning the process.
- **Carries:** A retained history with two explicit receivers.
- **Review:** Focus needs revision. The current primary is a Rule 30 history, not Conway Life; the file is an encounter guide rather than the proposed snapshot-and-receiver construction.

### [CA BeyondBinary](http://localhost:3003/tutorial-cards?map=CA_BeyondBinary)

Birth and survival · Fixed addresses · Output connections

- **Builds on:** CA Introduction: Synchronous cell updates.; Noise Columns: A value and its recipient are distinct.
- **Adds/deepens:** Connect a simulation address to an external object without adding feedback.
- **Carries:** A binary transition rule and one declared output connection.
- **Review:** Focus needs revision. The installed dish remains binary despite the map name; its actual branch and receiver call are delegated to final.md rather than taught here.

### [CA ExpandingSpace](http://localhost:3003/tutorial-cards?map=CA_ExpandingSpace)

External inputs · Graded state · Update order

- **Builds on:** CA BeyondBinary: An explicit simulation output.; VFM 02 Operations: Distance to a named position.
- **Adds/deepens:** Add external input to a graded state and expose scan-order dependence.
- **Carries:** An input-update-output pattern with separate support thresholds.
- **Review:** Focus needs revision. The guide offers a strong PROBE/SYNC/SCAN comparison but not the reduced input function or recovery update the learner would own.

### [CA SoftRules](http://localhost:3003/tutorial-cards?map=CA_SoftRules)

Diffusion · Coupled fields · Synchronous exchange

- **Builds on:** CA ExpandingSpace: Graded state and synchronous update order.; WaveFunctions 3D Wave Propagation: Neighbour differences can transmit change; revisit the proposed construction.
- **Adds/deepens:** Exchange graded quantities rather than count occupied neighbours.
- **Carries:** A two-field update with the reaction function named as supplied.
- **Review:** Focus needs revision. The present comparison explains disabled exchange but does not teach the neighbour sum and two-buffer update.

### [CA AgentsCircuits](http://localhost:3003/tutorial-cards?map=CA_AgentsCircuits)

Procedural comparison · State histories · Repeated construction

- **Builds on:** CA Introduction: A local rule over an ordered neighbourhood.; CA GameOfLife: A displayed history differs from the current state.
- **Adds/deepens:** Practice comparing procedures that can produce similar shapes; recursion remains a preview.
- **Carries:** A precise question about what repeats and what each step reads.
- **Review:** Focus needs revision. The current tutorial teaches proposed Wireworld gates, whereas the storyboard uses the Rule 90 history and Sierpinski comparison.

### [CA EdgeOfChaos](http://localhost:3003/tutorial-cards?map=CA_EdgeOfChaos)

Paired-state experiments · Difference measures · Numerical storage

- **Builds on:** Random Entropy: Independent retained copies.; CA ElementaryRules: State and its display counts differ.; Noise Perlin Simplex: Matched conditions make comparisons interpretable.
- **Adds/deepens:** Measure a perturbation with separate magnitude and affected-site counts.
- **Carries:** A paired-state experiment with stated storage and display gain.
- **Review:** Focus needs revision. The current guide enables observation but omits the learner's copying and difference-measurement operations; it does not establish a universal critical point.

## Fractals: Rules, Scale and Room to Move

### [Fractal Recursion](http://localhost:3003/tutorial-cards?map=Fractal_Recursion)

Recursive calls · Stopping conditions · Construction budgets

- **Builds on:** Color Nails: An input-to-output function, re-established if still only planned.; Trans Scale: A size change with a retained construction rule.
- **Adds/deepens:** Introduce bounded self-calls through visible geometry.
- **Carries:** A recursive constructor with explicit stopping and work limits.
- **Review:** Focus needs revision. The current survey starts with factorial and expands to memoisation and tail recursion; the proposed nested-square construction is not provided.

### [Fractal RecursiveTrees](http://localhost:3003/tutorial-cards?map=Fractal_RecursiveTrees)

Branch records · Inherited parameters · Recursive branching

- **Builds on:** Fractal Recursion: A bounded recursive call.; Trans Rotation: Turn a direction around a stated axis.
- **Adds/deepens:** Pass geometric state from a parent to multiple descendants.
- **Carries:** A branching constructor with inspectable parent records.
- **Review:** Focus needs revision. The current file is a short encounter order; the recursive learner constructor must be distinguished from the installed generation queue.

### [Fractal CantorSet](http://localhost:3003/tutorial-cards?map=Fractal_CantorSet)

Interval replacement · Retained length · Current state and history

- **Builds on:** CA GameOfLife: Retained rows differ from the current state.; Fractal Recursion: A finite repeat count and stopping condition.
- **Adds/deepens:** Replace one interval with two while tracking count and total length independently.
- **Carries:** A bounded interval replacement with an explicit removed complement.
- **Review:** Focus needs revision. The current encounter compares cuts, history and gaps; it does not teach the interval record and replacement function.

### [Fractal KochSierpinski](http://localhost:3003/tutorial-cards?map=Fractal_KochSierpinski)

Segment replacement · Endpoint distance · Path length

- **Builds on:** Fractal CantorSet: A replacement builds new data from old.; Point Lines: Endpoints, direction and distance.; Trans Rotation: Turn a displacement.
- **Adds/deepens:** Replace a relation with a longer connected route while retaining its endpoints.
- **Carries:** A geometry-replacement function with two distinct length measures.
- **Review:** Focus needs revision. The current encounter surveys Koch, Sierpinski and box counting; the learner's endpoint-to-four-segments function is absent.

### [Fractal MengerSponge](http://localhost:3003/tutorial-cards?map=Fractal_MengerSponge)

Volume subdivision · Cell selection · Retained volume

- **Builds on:** Tutorial 3D: Three-dimensional address conventions.; Fractal Recursion: Bounded recursive construction.; Fractal CantorSet: Count and retained measure can change differently.
- **Adds/deepens:** Apply replacement to volume and explicitly identify the removed cells.
- **Carries:** A finite volume-subdivision rule with fixed outer bounds.
- **Review:** Focus needs revision. The guide explains the 27-to-20 rule but does not provide the selection predicate and bounded learner construction.

### [Fractal GoldenSpiral](http://localhost:3003/tutorial-cards?map=Fractal_GoldenSpiral)

Numerical recurrence · Value mappings · Geometric interpretation

- **Builds on:** Point Trace: An ordered numerical record can be extended.; Noise Columns: One source can feed distinct receiving functions.
- **Adds/deepens:** Separate a recurrence from the geometry chosen to represent its values.
- **Carries:** A finite recurrence with explicitly named display mappings.
- **Review:** Focus needs revision. The encounter supports the comparison but omits the learner's recurrence loop and explicit supplied logarithmic mapping.

### [Fractal Synthesis](http://localhost:3003/tutorial-cards?map=Fractal_Synthesis)

Construction recipes · Descendant rules · Stopping conditions

- **Builds on:** Fractal CantorSet: Interval replacement and retained history.; Fractal RecursiveTrees: Parent/child construction and inherited parameters.
- **Adds/deepens:** Synthesize known procedures; no new syntax is required.
- **Carries:** A reconstructable account of repeated geometric work.
- **Review:** Focus fits the text. 

## L-Systems: Rules Grow Structure

### [LSystems Grammar Lab](http://localhost:3003/tutorial-cards?map=LSystems_Grammar_Lab)

Symbol rewriting · Parallel replacement · Interpretation

- **Builds on:** Fractal Synthesis: A recipe distinguishes descendants and placement.; Fractal CantorSet: Build new data separately from the old list.
- **Adds/deepens:** Separate symbolic production from geometric interpretation.
- **Carries:** A one-pass symbolic generator and a declared command vocabulary.
- **Review:** Focus needs revision. The current guide compares existing presets but does not teach the rewriting function or expose a learner rule connection.

### [LSystems Growth](http://localhost:3003/tutorial-cards?map=LSystems_Growth)

State stacks · Copied snapshots · Branch restoration

- **Builds on:** LSystems Grammar Lab: Symbols and their interpretation.; Random Entropy: An independent copy preserves an earlier state.
- **Adds/deepens:** Use last-in-first-out state storage for nested branches.
- **Carries:** A stack of explicit turtle-state records.
- **Review:** Focus needs revision. The encounter explains the saved state but does not supply the learner's copied record, push/pop functions or their interpreter binding.

### [LSystems Grammars And Curves](http://localhost:3003/tutorial-cards?map=LSystems_Grammars_And_Curves)

Geometric interpretation · Swept surfaces · Ring resolution · Explicit connections

- **Builds on:** LSystems Growth: A turtle's saved heading differs from its emitted geometry.; Point Trace: An ordered path of positions.; WaveFunctions Unit Circle: Circular sampling supplies ring vertices.
- **Adds/deepens:** Compose known traces, circular samples and faces into a sweep; record a connection explicitly.
- **Carries:** A path-to-surface construction whose resolution and connections remain inspectable.
- **Review:** Focus fits the text. The new sweep lesson is substantial. Its frame transport and signal routing remain supplied; the storyboard's learner interpreter adapter is a separate proposal.

### [LSystems Architecture](http://localhost:3003/tutorial-cards?map=LSystems_Architecture)

Path footprints · Passage width · Open boundaries

- **Builds on:** LSystems Growth: Branches produce retained segments.; LSystems Grammars And Curves: A line acquires width through an explicit construction.; Trans Body: Collision boundaries and a body's dimensions.
- **Adds/deepens:** Turn an interpreted path into a bounded empty passage.
- **Carries:** A path-to-footprint rule with a clearance question.
- **Review:** Focus needs revision. The current encounter compares the generated dungeon but does not teach the reduced footprint operation or its wall-builder interface.

### [LSystems Competition](http://localhost:3003/tutorial-cards?map=LSystems_Competition)

Shared resources · Execution order · Conditional growth

- **Builds on:** LSystems Grammar Lab: A production defines possible growth.; CA ExpandingSpace: Order can matter when later work reads changed state.
- **Adds/deepens:** Make the conditions for executing a rule and consuming a resource explicit.
- **Carries:** A two-request schedule with a resource trace.
- **Review:** Focus needs revision. The guide supports order comparisons, but the small learner schedule and consume-before-gate state record are not yet taught.

### [LSystems Living](http://localhost:3003/tutorial-cards?map=LSystems_Living)

Design records · Parameter quantisation · Retained specimens

- **Builds on:** LSystems Growth: Branch depth and saved parameters.; Random Mushrooms: A population description separates kinds and numerical variations.
- **Adds/deepens:** Expose rounding and bounds between a continuous control and discrete construction.
- **Carries:** A reproducible design record with stated reachable changes.
- **Review:** Focus needs revision. The guide identifies gene mappings and snapshots but does not teach the proposed record-to-parameter conversion or learner binding.

### [LSystems Shape Grammars](http://localhost:3003/tutorial-cards?map=LSystems_Shape_Grammars)

Face selection · Operation sequences · Shape recipes

- **Builds on:** Primitives Polythedra: Indexed faces and shared vertices.; LSystems Grammar Lab: A production is distinct from its interpretation.; LSystems Living: A retained design record defines a reproducible construction.
- **Adds/deepens:** Describe shape changes as operations over selected faces.
- **Carries:** A face-operation recipe with explicit builder inputs.
- **Review:** Tutorial missing. No tutorial.md exists. Fixed museum specimens do not yet provide the proposed editable learner recipe.

### [Assemblage Same Desire](http://localhost:3003/tutorial-cards?map=Assemblage_Same_Desire)

Retained decisions · Mark vocabularies · Interpretive paths

- **Builds on:** Randomness 10 PRINT Algorithm: A two-mark choice at each grid address.; LSystems Grammar Lab: A sentence and its geometric reading can change independently.
- **Adds/deepens:** Synthesize sample, decision and mark as separate operations; no new syntax is required.
- **Carries:** A comparison account separating choices from their interpretation.
- **Review:** Focus fits the text. 

## Procedural Generation: Rules Build Worlds

### [PG Genetic Evolution](http://localhost:3003/tutorial-cards?map=PG_Genetic_Evolution)

Candidate records · Evaluation functions · Selection criteria

- **Builds on:** LSystems Living: A retained description generates a body.; Assemblage Same Desire: One record can have different readers.; FormFinding Descent: A chosen objective determines what counts as improvement.
- **Adds/deepens:** Separate generating a candidate from scoring and selecting it.
- **Carries:** An evaluator with an explicit criterion and known omissions.
- **Review:** Focus needs revision. The current encounter sends the score formula to final.md; the learner evaluator/ranking operation is absent and must preserve the estimator's approximations.

### [PG Space Colonization](http://localhost:3003/tutorial-cards?map=PG_Space_Colonization)

Direction accumulation · Growth eligibility · Branch records

- **Builds on:** Vectors Act2 VectorArithmetic: Add and normalize direction vectors.; Fractal RecursiveTrees: A child begins at a parent endpoint.
- **Adds/deepens:** Combine several directional invitations into one growth decision.
- **Carries:** A direction accumulator with a declared eligibility policy.
- **Review:** Focus needs revision. The guide explains the first decision but delegates actual accumulation lines to final.md; the proposed assigned-list function needs teaching here.

### [PG Branching Growth](http://localhost:3003/tutorial-cards?map=PG_Branching_Growth)

Nearest-target search · Parent records · Coincident positions

- **Builds on:** PG Space Colonization: A growth decision can combine assigned directions.; Random Remove: Eligibility precedes selection.
- **Adds/deepens:** Replace accumulated invitations with nearest-target selection and retain its provenance.
- **Carries:** A selection-and-growth record naming parent and target.
- **Review:** Focus needs revision. The current lesson shows direction normalization but not the nearest-eligible search or retained target record needed for the proposed learner operation.

### [PG Percolation Network](http://localhost:3003/tutorial-cards?map=PG_Percolation_Network)

Six-neighbour adjacency · Local transmission · Reachability

- **Builds on:** Noise Voxel: Stored occupancy differs from its visible surface.; CA Introduction: A synchronous neighbourhood update.
- **Adds/deepens:** Test transmission under a declared adjacency without conflating contact and access.
- **Carries:** A local propagation step over a separately retained lattice.
- **Review:** Focus needs revision. The tutorial lists the six neighbours and explains the experiment but lacks the learner's transmission branch and complete buffer operation.

### [PG Caves Mazes](http://localhost:3003/tutorial-cards?map=PG_Caves_Mazes)

Carving footprints · Headroom · Path and empty volume

- **Builds on:** Random Walk: A retained path records positions.; Noise Voxel: A grid stores solid or empty decisions.; LSystems Architecture: A connected centreline needs width and clearance.
- **Adds/deepens:** Map a position record to removed volume instead of drawn lines.
- **Carries:** A path-to-empty-volume operation with explicit clearance.
- **Review:** Focus needs revision. The existing text explains carving and backtracking but leaves _carve_ball and _set_air unspecified; the learner footprint operation still needs implementation and explanation.

### [PG Sculpted Forms](http://localhost:3003/tutorial-cards?map=PG_Sculpted_Forms)

Coordinate conversion · Voxel sampling · Exposed faces

- **Builds on:** Point Coordinates: Local and global positions differ.; Noise Voxel: Occupancy records.; Primitives Polythedra: A surface is a set of connected faces.
- **Adds/deepens:** Sample an event into a finite surface while naming the lost rotations and contacts.
- **Carries:** A centre-to-surface pipeline with explicit approximation size.
- **Review:** Focus needs revision. The tutorial teaches to_local and the enlarged approximation but omits the learner occupancy and exposed-face operations.

### [PG Mirrored Patterns](http://localhost:3003/tutorial-cards?map=PG_Mirrored_Patterns)

Array reflection · Preserved inputs · Image and connectivity

- **Builds on:** CA Introduction: Read old data before writing a result.; Symmetry Seventeen: A symmetry depends on an explicit transformation.; Random Entropy: A held input permits another reading.
- **Adds/deepens:** Compose copying with stored cellular data and inspect odd-grid edge cases.
- **Carries:** A reflection operation with an unchanged witness array.
- **Review:** Focus needs revision. The excerpts show mirrored assignments, but a complete learner loop and explicit treatment of the omitted centre row/column still need alignment.

## Soft Bodies & Morphogenesis: Matter That Finds Its Shape

### [SoftBodies Soft Body Deformation](http://localhost:3003/tutorial-cards?map=SoftBodies_Soft_Body_Deformation)

Deformable meshes · Resistance and damping · Pinned attachments

- **Builds on:** Primitives Polythedra: Connectivity can remain fixed while positions change.; Vectors Act4b Oscillation: Resistance and damping have different roles.
- **Adds/deepens:** Let constituent positions respond while retaining face connections and attachments.
- **Carries:** A bounded soft-body setup with an explicit attachment.
- **Review:** Focus needs revision. The lesson compares coefficients but does not supply the reduced solver setup or reliable point-selection interface proposed by the storyboard.

### [SoftBodies Cloth Physics](http://localhost:3003/tutorial-cards?map=SoftBodies_Cloth_Physics)

Boundary conditions · Distributed loads · Compliance and damping

- **Builds on:** SoftBodies Soft Body Deformation: A solver moves vertices under fixed connectivity.; FormFinding Relaxation: Constraints and repeated geometric correction.; Vectors Act4a KineticForces: A force changes motion.
- **Adds/deepens:** Separate support selection, material response and applied load using existing tools.
- **Carries:** A controlled pin/load comparison and one authored load setting.
- **Review:** Focus fits the text. The new membrane edit supports this focus; deriving a general vertex-selection function remains a proposed extension.

### [SoftBodies Carusell](http://localhost:3003/tutorial-cards?map=SoftBodies_Carusell)

Driven anchors · Retained motion · One-way coupling

- **Builds on:** Trans Rotation: A rate advances an angle.; SoftBodies Cloth Physics: Pinned boundaries constrain a responding surface.
- **Adds/deepens:** Drive a boundary without prescribing the responding body's full motion.
- **Carries:** A driven-anchor rule distinct from the simulated response.
- **Review:** Focus needs revision. The current encounter explains speed and stopping but does not provide the learner's anchor-update function or its assembly connection.

### [SoftBodies Obsticals](http://localhost:3003/tutorial-cards?map=SoftBodies_Obsticals)

Pressure drivers · Solver response · Changing clearance

- **Builds on:** WaveFunctions Sine Space: A spatial sine can directly prescribe geometry.; Noise Columns: A driver and its recipient.; SoftBodies Soft Body Deformation: Pressure contributes to a solver response.
- **Adds/deepens:** Send a known sine rule into pressure rather than directly into vertex position.
- **Carries:** A readable signal-to-pressure mapping with independent solver state.
- **Review:** Focus fits the text. 

### [SoftBodies Obsticals Part2](http://localhost:3003/tutorial-cards?map=SoftBodies_Obsticals_Part2)

Controlled comparisons · Initial conditions · Shape observation

- **Builds on:** Noise Perlin Simplex: Matched conditions make a comparison interpretable.; SoftBodies Soft Body Deformation: Stiffness, damping and pressure have different roles.
- **Adds/deepens:** Practice controlled experimental description; no new syntax is required.
- **Carries:** A two-case comparison that distinguishes seeded setup from solver replay.
- **Review:** Focus fits the text. 

### [SoftBodies Playground of Joy](http://localhost:3003/tutorial-cards?map=SoftBodies_Playground_of_Joy)

Vertex snapshots · Process and sculpture · Measurement proxies

- **Builds on:** PG Sculpted Forms: An event sample omits part of the process.; SoftBodies Soft Body Deformation: Positions can change without new face connections.; Random Entropy: A copied snapshot differs from a live reference.
- **Adds/deepens:** Retain geometry from a chosen solver step without claiming to retain dynamics.
- **Carries:** A process-to-static-mesh snapshot with stated omissions.
- **Review:** Focus needs revision. The current chapter discusses the frozen result and bounding-box proxy but does not teach the copy/mesh operation or expose the custom solver's vertex interface.

### [SoftBodies Affect Theory Visualization](http://localhost:3003/tutorial-cards?map=SoftBodies_Affect_Theory_Visualization)

Apparent life · Construction cues · Controlled variation

- **Builds on:** Random Mushrooms: A repertoire and its parameter choices differ.; LSystems Living: A design record does not constitute biology.; SoftBodies Soft Body Deformation: Soft dynamics and organic appearance are different claims.
- **Adds/deepens:** Compose and interpret known procedures; no new syntax is required.
- **Carries:** A precise vocabulary for testing appearance without claiming a hidden mechanism.
- **Review:** Focus fits the text. 

### [ProceduralGeneration Reaction Diffusion Systems](http://localhost:3003/tutorial-cards?map=ProceduralGeneration_Reaction_Diffusion_Systems)

Local reactions · Diffusion · Feed and removal

- **Builds on:** CA SoftRules: Two synchronous concentration fields and a supplied reaction function.; Change Intro: A small step accumulates a rate.
- **Adds/deepens:** Open the previously supplied reaction function and distinguish its local terms from exchange.
- **Carries:** A small two-field update with explicit boundary and step settings.
- **Review:** Focus needs revision. The chapter exposes the reaction equations but not a complete reduced update or stable learner runner; those must be supplied before claiming the full simulation is authored.

### [Topology Entropy Morphogenesis](http://localhost:3003/tutorial-cards?map=Topology_Entropy_Morphogenesis)

Composed controls · Named parameters · Threshold comparisons

- **Builds on:** Noise Voxel: A threshold makes an occupancy decision.; Noise Columns: A scalar drives an explicit recipient.; WaveFunctions Sine Space: A periodic rule defines spatial variation.
- **Adds/deepens:** Compose known mappings while making the bundled choices inspectable.
- **Carries:** A named multi-parameter control recipe; surface extraction remains supplied.
- **Review:** Focus fits the text. 

## Isosurfaces: Implicit to Explicit

### [ISO Introduction](http://localhost:3003/tutorial-cards?map=ISO_Introduction)

Scalar fields · Level sets · Finite sampling

- **Builds on:** Noise Voxel: Reuse values sampled at volume addresses.; Point Triangle Context: Reuse the distinction between a surface and its triangular faces.
- **Adds/deepens:** Separate a field, a selected boundary and a finite mesh approximation.
- **Carries:** A controlled comparison of level and sampling for later surfaces.
- **Review:** Focus fits the text. 

### [ISO LookupTable](http://localhost:3003/tutorial-cards?map=ISO_LookupTable)

Corner classification · Linear interpolation · Local connectivity

- **Builds on:** ISO Introduction: Reuse level comparisons at sampled positions.; Trans Introduction: Reuse interpolation between two endpoints.
- **Adds/deepens:** Distinguish the values that select connectivity from the magnitudes that locate a crossing.
- **Carries:** An edge crossing calculation and an explicit corner convention.
- **Review:** Focus fits the text. 

### [ISO ShapesGallery](http://localhost:3003/tutorial-cards?map=ISO_ShapesGallery)

Field composition · Union and subtraction · Description versus sampling

- **Builds on:** ISO LookupTable: Keep the same extraction process while replacing its input field.
- **Adds/deepens:** Compose shape descriptions while separating a changed recipe from loss through sampling.
- **Carries:** A readable composition of fields, ready for periodic and Boolean forms.
- **Review:** Focus fits the text. 

### [ISO TorusGyroid](http://localhost:3003/tutorial-cards?map=ISO_TorusGyroid)

Periodic fields · Spatial frequency · Clearance probes

- **Builds on:** WaveFunctions Sine Space: Reuse spatial phase and frequency.; ISO ShapesGallery: Reuse a field expression as input to a common extractor.
- **Adds/deepens:** Produce repetition within a field and distinguish a visible opening from one bounded clearance test.
- **Carries:** A spatial frequency choice with explicit sampling and probe limits.
- **Review:** Focus fits the text. 

### [ISO Sculpting](http://localhost:3003/tutorial-cards?map=ISO_Sculpting)

Spatial contributions · Operation history · Ordered subtraction

- **Builds on:** ISO ShapesGallery: Reuse union and subtraction of evaluated fields.; Point Trace: Reuse an ordered record whose contents outlast an event.
- **Adds/deepens:** Read the surface as the result of an ordered history, where erasure adds a cut rather than undoing a gesture.
- **Carries:** An account of operation order and the limits of retained history.
- **Review:** Focus fits the text. 

### [ISO FlatTerrain](http://localhost:3003/tutorial-cards?map=ISO_FlatTerrain)

Height fields · Volumetric fields · Boundary crossings

- **Builds on:** Noise Columns: Reuse one assigned height at each horizontal address.; ISO Introduction: Reuse sampling and selected levels.
- **Adds/deepens:** Explain why a volume can contain floor, gap and ceiling at one horizontal address while a height field cannot.
- **Carries:** A distinction between an upper profile, an interior and an accessible entrance.
- **Review:** Focus fits the text. 

### [ISO PortalLandscape](http://localhost:3003/tutorial-cards?map=ISO_PortalLandscape)

Spatial masks · Signed field composition · Controlled comparisons

- **Builds on:** ISO FlatTerrain: Reuse a height field extended by a volumetric contribution.; Shader 09 FBM: Return to layered noise while separating a supplied sampler from the composition that uses it.
- **Adds/deepens:** Compose purposeful local changes through masks and weights rather than treating a named landform as guaranteed output.
- **Carries:** A terrain expression with named contributions and a predicted region of change.
- **Review:** Focus needs revision. The recipe calls fbm and ridged without contracts or definitions. It also describes intermediate terms as guaranteed passages despite its opening caveat; select a small supplied study and teach two contributions first. The proposed prior lesson also lacks tutorial.md: Shader_09_FBM.

### [ISO Caves](http://localhost:3003/tutorial-cards?map=ISO_Caves)

Entrance conditions · Enclosing boundaries · Bodily clearance

- **Builds on:** ISO PortalLandscape: Reuse composed openings without assuming that their names guarantee passage.; PG Caves Mazes: Reuse the distinction between connected space and room for a body.
- **Adds/deepens:** Treat burial, headroom, collision and arrival as separate conditions of an entrance.
- **Carries:** An explicit entrance condition for a later cave or room.
- **Review:** Focus fits the text. 

### [ISO CaveGeneration](http://localhost:3003/tutorial-cards?map=ISO_CaveGeneration)

Field scale · Sampling resolution · Construction methods

- **Builds on:** ISO TorusGyroid: Reuse a coordinate multiplier within a fixed sample domain.; ISO Caves: Reuse enclosure and entrance as questions to test.
- **Adds/deepens:** Relate field scale to physical domain and sample spacing without equating a similar silhouette with a shared construction.
- **Carries:** A reproducible field recipe with its scale and sampling declared.
- **Review:** Focus needs revision. The proposed controlled pair is absent. The tutorial treats detail beyond an octave as simply thrown away, leaves GPU/base-class machinery unexplained, and promises an entire cave from a dispatch; separate supplied extraction from the learner scale experiment.

### [ISO AnimatedNoise](http://localhost:3003/tutorial-cards?map=ISO_AnimatedNoise)

Fixed sample addresses · Time dependent values · Occupancy histories

- **Builds on:** ISO Introduction: Reuse values at fixed volume samples.; Point Trace: Reuse a bounded history over time.
- **Adds/deepens:** Distinguish changing values at places from the identity and motion of persistent particles.
- **Carries:** A short occupancy history tied to one address.
- **Review:** Focus needs revision. The current text teaches a remeshed triangle surface through undefined extract, while the storyboard studies block occupancy. Its two-field blend is not four-dimensional noise, and field animation is described as a derivative without a corresponding calculation.

### [ISO Metaballs](http://localhost:3003/tutorial-cards?map=ISO_Metaballs)

Influence accumulation · Source arrangements · Falloff functions

- **Builds on:** ISO Sculpting: Reuse located contributions to an implicit field.; Vectors Act2 VectorArithmetic: Reuse accumulation of contributions before interpreting the combined result.
- **Adds/deepens:** Build one boundary from multiple overlapping influences without counting lobes as separate sources.
- **Carries:** A source list and an accumulation loop for another field description.
- **Review:** Focus needs revision. The summation loop is present, but kernel(source, p) has no declared input contract, falloff or finite behaviour. Supply one bounded kernel and locate the editable source record before claiming the learner can construct the field.

### [ISO ImplicitModeling](http://localhost:3003/tutorial-cards?map=ISO_ImplicitModeling)

Signed distance fields · Shape composition · Surface representations

- **Builds on:** ISO Metaballs: Reuse a position-to-value description.; ISO ShapesGallery: Reuse union and subtraction at the same sample position.
- **Adds/deepens:** Keep a spatial rule distinct from the representations and physical affordances made from it.
- **Carries:** One field description with explicit rendering and collision receivers.
- **Review:** Focus needs revision. The paired receivers are asserted rather than supplied in the lesson. It promises walkability from marching cubes alone, gives smooth-union k=0 despite division by k, and overstates what implicit blending uniquely permits.

### [ISO RhizomeBody](http://localhost:3003/tutorial-cards?map=ISO_RhizomeBody)

Route records · Connectivity and clearance · Inhabitable surfaces

- **Builds on:** ISO Caves: Reuse entrance and body-clearance conditions.; ISO ImplicitModeling: Separate field, extracted surface and collider.
- **Adds/deepens:** Synthesize a planned connection with the routes a particular body can establish.
- **Carries:** A route sketch with uncertain or inaccessible connections marked.
- **Review:** Tutorial missing. tutorial.md is absent. Storyboard proposes a route sketch; its paper or in-project host remains undecided.

## Boolean Surfaces: CSG as Composition

### [Boolean Verbs](http://localhost:3003/tutorial-cards?map=Boolean_Verbs)

Union · Intersection · Ordered difference

- **Builds on:** ISO ShapesGallery: Reuse combining and subtracting implicit regions.
- **Adds/deepens:** Make the set-operation vocabulary explicit without mistaking different specimens for a controlled experiment.
- **Carries:** A two-operand vocabulary for reading and composing solids.
- **Review:** Focus fits the text. 

### [Boolean Gallery](http://localhost:3003/tutorial-cards?map=Boolean_Gallery)

Parameter variation · Presentation order · Visible operands

- **Builds on:** Boolean Verbs: Reuse the three set operations and operand order.; Array: Reuse an ordered collection interpreted by a receiver.
- **Adds/deepens:** Author a comparison whose explanatory order can differ from its geometric parameter order.
- **Carries:** A legible sequence of configurations for an architectural composition.
- **Review:** Focus needs revision. The current tutorial asks for code/registry/rendered catalogue comparison but supplies no learner-owned configuration list or factory interface. Keep that catalogue as material for the proposed presentation exercise. The proposed prior lesson also lacks tutorial.md: Array.

### [Boolean Works](http://localhost:3003/tutorial-cards?map=Boolean_Works)

Architectural subtraction · Shared transforms · Collision and appearance

- **Builds on:** Boolean Verbs: Reuse ordered subtraction.; ISO Caves: Reuse bodily clearance and entrance tests.; Color Flashlight: Reuse changing appearance while retaining geometry.
- **Adds/deepens:** Compose and inspect an inhabitable cut while separating geometry, contact and material response.
- **Carries:** A cut and an appearance choice whose different consequences can be explained.
- **Review:** Focus fits the text. The appended museum setter studies deliver this bounded focus; the earlier egg exercise still switches to a Day Zero duplicate and does not yet teach a new room composition.

## Swarm Intelligence: Where Coordination Lives

### [SwarmIntelligence PhysarumColony](http://localhost:3003/tutorial-cards?map=SwarmIntelligence_PhysarumColony)

Environmental memory · Local sensing · Deposition and decay

- **Builds on:** Random Pheromone: Reuse a trace that changes later motion.; CA Introduction: Reuse addressed state and repeated local updates.
- **Adds/deepens:** Use a shared field as memory that survives the agents that deposited it.
- **Carries:** A local sensing-and-deposit rule with a named decay choice.
- **Review:** Focus needs revision. sense_with_offset is undefined and the movement/boundary contract is unstated. Food sources are absent from the shown loop, yet the opening and ending promise shortest paths and a complete colony; limit the claim to local trail coordination.

### [SwarmIntelligence FlowFields](http://localhost:3003/tutorial-cards?map=SwarmIntelligence_FlowFields)

Vector fields · Grid lookup · Field following

- **Builds on:** Flow Field: Reuse position-to-vector lookup.; SwarmIntelligence PhysarumColony: Contrast shared environmental guidance with a trace changed by agents.
- **Adds/deepens:** Coordinate several agents through a retained direction field, keeping field construction separate from following it.
- **Carries:** A direction field and its sampling interface.
- **Review:** Focus fits the text. The direct radial construction supports these labels. The extra route-finding recipe leaves get_neighbours undefined and changes neighbourhood conventions; it should not be counted as a completed Dijkstra lesson.

### [SwarmIntelligence Boids Algorithm](http://localhost:3003/tutorial-cards?map=SwarmIntelligence_Boids_Algorithm)

Local neighbourhoods · Vector averages · Weighted steering

- **Builds on:** Vectors Act2 VectorArithmetic: Reuse vector sums, averages and differences.; SwarmIntelligence FlowFields: Reuse steering while replacing field lookup with neighbour observations.
- **Adds/deepens:** Make a changing neighbourhood determine the steering contributions received by each agent.
- **Carries:** A neighbourhood selector and three separately weighted steering rules.
- **Review:** Focus fits the text. The three-rule calculation is present; boundary policy and room/body avoidance are not taught, and in-place updates should not be described as simultaneous independent decisions.

### [SwarmIntelligence Agent Based Modeling ABM](http://localhost:3003/tutorial-cards?map=SwarmIntelligence_Agent_Based_Modeling_ABM)

Agent states · State transitions · Shared history

- **Builds on:** SwarmIntelligence PhysarumColony: Reuse environmental memory.; SwarmIntelligence Boids Algorithm: Reuse local perception that selects an action.
- **Adds/deepens:** Separate individual state from the persistent shared field and state which one a restart changes.
- **Carries:** A state record and transition rule for outward and returning travellers.
- **Review:** Focus needs revision. The current majority-copying society recipe differs from the foraging exhibit. dominant_state and initialise_swarm are undeclared; replacing a population is called a fresh start without any shared-field reset distinction.

### [SwarmIntelligence Ant Colony Optimization](http://localhost:3003/tutorial-cards?map=SwarmIntelligence_Ant_Colony_Optimization)

Two channel communication · Foraging states · Trail reinforcement

- **Builds on:** SwarmIntelligence Agent Based Modeling ABM: Reuse state-dependent behaviour.; SwarmIntelligence PhysarumColony: Reuse trail sensing, deposition and evaporation.
- **Adds/deepens:** Change the meaning of a deposited value through the traveller’s state and selected channel.
- **Carries:** A two-channel foraging rule with explicit destination transitions.
- **Review:** Focus needs revision. The tutorial instead builds a travelling-tour graph, assumes edge distances exist for candidate vertices and calls undefined tour_length. It does not teach the demonstrated two-channel foraging mechanism or establish shortest-tour convergence.

### [SwarmIntelligence Particle Swarm Optimization](http://localhost:3003/tutorial-cards?map=SwarmIntelligence_Particle_Swarm_Optimization)

Objective functions · Personal and shared memory · Weighted search motion

- **Builds on:** FormFinding Descent: Reuse an explicitly chosen scalar objective.; SwarmIntelligence Boids Algorithm: Reuse weighted vector steering.
- **Adds/deepens:** Guide search by evaluated memories and make their validity depend on the objective and reference state.
- **Carries:** An objective, candidate positions and accountable best-state records.
- **Review:** Focus needs revision. The fixed Rastrigin recipe does not cover the exhibit’s changing novelty archive. Global best is not evaluated before the first velocity update or cleared by reset_swarm, yet convergence to the global minimum is promised.

### [SwarmIntelligence Swarm Intelligence Algorithms](http://localhost:3003/tutorial-cards?map=SwarmIntelligence_Swarm_Intelligence_Algorithms)

Event provenance · Population accounting · External support

- **Builds on:** SwarmIntelligence Agent Based Modeling ABM: Reuse agent states and population counts.; Point Trace: Reuse a record of events over time.
- **Adds/deepens:** Compose an account of collective persistence that retains intervention and uncertainty.
- **Carries:** A population event account that identifies supplied support.
- **Review:** Focus needs revision. The current text is an abstract algorithm-interface gallery with empty hooks and missing comparison helpers. It does not teach the ecosystem’s support/event record, and its ending points to Chamber_Swarm outside this route.

## Machine Learning: What Changes, and Why?

### [ML Evolution](http://localhost:3003/tutorial-cards?map=ML_Evolution)

Heritable parameters · Variation and selection · Evaluation criteria

- **Builds on:** PG Genetic Evolution: Return to variation and selection in procedural generation.; SwarmIntelligence Swarm Intelligence Algorithms: Carry the distinction between reproduction and externally supported persistence.
- **Adds/deepens:** Separate the inherited candidate, its trial outcome and the replacement decision.
- **Carries:** A candidate-and-score record with a reproducible selection rule.
- **Review:** Focus needs revision. Genome has no fitness field although selection assigns and reads it. The creature’s set_weights interface does not explain how genes affect motion, and elitism is said to prevent regression without stating repeatable evaluation conditions.

### [ML Gradient Landscape](http://localhost:3003/tutorial-cards?map=ML_Gradient_Landscape)

Prediction functions · Loss aggregation · Numerical gradients · Descent steps

- **Builds on:** FormFinding Descent: Reuse moving against an estimated slope.; SwarmIntelligence Particle Swarm Optimization: Reuse separating a candidate from its score.
- **Adds/deepens:** Construct a learning objective from prediction errors rather than accepting an unexplained landscape.
- **Carries:** Separate predictor, loss and update functions.
- **Review:** Focus needs revision. The tutorial uses a preset Himmelblau function, then surveys momentum and Adam. It does not construct the exhibit’s data-dependent regression loss, and render_surface leaves triangulation omitted while mark_position is undefined.

### [ML Classification](http://localhost:3003/tutorial-cards?map=ML_Classification)

Nearest centre assignment · Centroid updates · Clustering

- **Builds on:** SwarmIntelligence Boids Algorithm: Reuse distance-based neighbourhoods and mean positions.; ML Gradient Landscape: Reuse an adjustable model state that is compared against data.
- **Adds/deepens:** Alternate discrete assignments with continuous centre updates instead of treating group labels as given truth.
- **Carries:** A small clustering loop with an explicit empty-group rule.
- **Review:** Focus fits the text. The k-means loop supplies this narrow operation. The surrounding SVM/neural survey overstates the scope of one hall, and its uninitialised network forward pass should not count as taught training.

### [ML Neural Networks](http://localhost:3003/tutorial-cards?map=ML_Neural_Networks)

Weighted sums · Function composition · Activations and weights · Prediction error

- **Builds on:** ML Classification: Reuse adjustable model state and a point representation.; ML Gradient Landscape: Reuse prediction and loss as separate operations.
- **Adds/deepens:** Distinguish transient activity from retained parameters and connect a parameter change to an observable prediction.
- **Carries:** A small forward model whose weights and outputs can be inspected separately.
- **Review:** Focus needs revision. Forward arithmetic is present, but the backward sketch omits hidden activation derivatives and uses already-updated weights while claiming general training. Provide a declared correct training-step interface and repeatable held-out comparison; do not label backpropagation as learned here.

### [ML Perception](http://localhost:3003/tutorial-cards?map=ML_Perception)

Image neighbourhoods · Convolution kernels · Edge magnitude

- **Builds on:** ML Neural Networks: Reuse a weighted sum.; CA Introduction: Reuse neighbourhood operations over an addressed grid.
- **Adds/deepens:** Make the selected local intensity differences visible as an intermediate representation.
- **Carries:** An inspectable edge-strength image with its retained and omitted information named.
- **Review:** Focus fits the text. The convolution and magnitude loops support this focus. Keep their fixed filters distinct from learned object recognition and avoid presenting the separate perceptron recipe as a prerequisite for the filter.

### [ML Sequence Memory](http://localhost:3003/tutorial-cards?map=ML_Sequence_Memory)

Retained state · Gated updates · History dependence

- **Builds on:** ML Neural Networks: Reuse weighted inputs and exposed outputs.; Point Trace: Reuse a state record accumulated over time.
- **Adds/deepens:** Make the present output depend on a controlled recurrence, distinguishing hand-set gates from a trained LSTM.
- **Carries:** A small gated recurrence and two histories that distinguish its behaviour.
- **Review:** Focus needs revision. The lesson surveys RNN and LSTM recipes rather than the linear hand-set cell. Vector helpers and gradient_at_timestep are undefined, and teacher forcing is only a comment although the ending claims it can be trained.

### [ML Generative](http://localhost:3003/tutorial-cards?map=ML_Generative)

Candidate generation · Reference samples · Critic scores · Learning updates

- **Builds on:** Random Gaussian: Reuse sampled random inputs.; ML Neural Networks: Reuse a forward model with retained weights.; ML Gradient Landscape: Reuse a declared loss for evaluating change.
- **Adds/deepens:** Separate producing samples from learning a distribution and identify the reference set embedded in the judgement.
- **Carries:** A candidate generator and an explicit account of what its critic compares.
- **Review:** Focus needs revision. Essential GAN backward methods and VAE encoder helpers are absent. The chapter claims training and decoding from those calls and adds diffusion without a learned reverse process; the museum’s scripted losses cannot supply evidence of learning.

### [ML Synthesis](http://localhost:3003/tutorial-cards?map=ML_Synthesis)

Reference populations · Coordinate scaling · Outlier scores · Decision thresholds

- **Builds on:** Random Gaussian: Reuse spread and deviation from a reference.; ML Classification: Reuse the distinction between data positions and algorithmically assigned groups.
- **Adds/deepens:** Compose a flag from representation, reference population and decision rule while preserving the case being judged.
- **Carries:** A flagged case with its reference, scaling and threshold still visible.
- **Review:** Focus needs revision. The entire current tutorial is an RL, language-model and retraining survey. It does not teach the storyboard’s outlier calculation; policy_gradient, compute_returns, lm_forward and other core helpers are undefined.

## Graph Theory: What Connections Permit

### [GT Foundations](http://localhost:3003/tutorial-cards?map=GT_Foundations)

Vertex identifiers · Adjacency lists · Pending work · Traversal order

- **Builds on:** Point Triangle Context: Return to vertices linked by explicit connections.; Point Trace: Reuse a list whose ordering controls how retained items are revisited.
- **Adds/deepens:** Make breadth and depth arise from the choice of pending-work order over the same relation record.
- **Carries:** A graph record and a traversal procedure ready to retain predecessors.
- **Review:** Focus needs revision. The current lesson teaches edge lists and an Euler walk test, not the storyboard’s queue/stack traversal. Its Euler condition also omits connectivity; introduce traversal in this hall before later recipes rely on unexplained neighbours and bfs_distances.

### [GT Layout](http://localhost:3003/tutorial-cards?map=GT_Layout)

Connectivity and position · Spring layouts · Damped motion

- **Builds on:** GT Foundations: Reuse vertex identifiers and edge pairs.; SoftBodies Cloth Physics: Reuse restoring forces, velocities and damping.
- **Adds/deepens:** Assign spatial positions to a graph without changing which vertices it connects.
- **Carries:** A layout whose moving picture remains separate from its relation record.
- **Review:** Focus fits the text. The force calculations support this focus. The optional stress calculation calls undefined bfs_distances and the visual update moves spheres without updating edges; neither should be counted as a completed rendering or stress lesson.

### [GT Pathfinding](http://localhost:3003/tutorial-cards?map=GT_Pathfinding)

Breadth first search · Predecessor records · Path reconstruction · Unreachable destinations

- **Builds on:** GT Foundations: Reuse a queue and adjacency lookup for traversal.
- **Adds/deepens:** Separate the explored search from the route recovered through a predecessor chain.
- **Carries:** A path record with an explicit unreachable case.
- **Review:** Focus needs revision. Graph.neighbours is never introduced by the earlier Graph class. reconstruct_path indexes a missing goal after failed search, and A* adds an undeclared PriorityQueue; teach one complete BFS path operation before claiming three search methods.

### [GT Network Analysis](http://localhost:3003/tutorial-cards?map=GT_Network_Analysis)

Directed relations · Incoming and outgoing counts · Source records · Layout invariance

- **Builds on:** GT Foundations: Reuse endpoint identifiers and edge records.; GT Layout: Reuse the separation between relation and drawing.
- **Adds/deepens:** Attach a precise count to recorded relations while retaining provenance and distinguishing visual prominence from the measure.
- **Carries:** A directed relation record with inspectable source and counts.
- **Review:** Focus fits the text. The appended evidence-network study supplies this focus. The preceding broad centrality survey still assumes helpers and generalises simple-graph normalisation to the earlier multigraph; those methods are outside these labels.

### [GT Connectivity](http://localhost:3003/tutorial-cards?map=GT_Connectivity)

Directed reachability · Reversed graphs · Mutual reachability

- **Builds on:** GT Pathfinding: Reuse visited-state traversal.; GT Network Analysis: Reuse directed source and destination records.
- **Adds/deepens:** Construct mutual reachability through two explicit searches before comparing with a supplied component algorithm.
- **Carries:** A component defined by routes in both directions, with costs and clearance left open.
- **Review:** Focus needs revision. The tutorial jumps directly to a recursive Tarjan lambda without teaching low-link invariants; it does not provide the proposed two-reachability construction. Room creation and directed arrows are also undeclared apparatus, not learner capabilities.

### [GT Spanning Trees](http://localhost:3003/tutorial-cards?map=GT_Spanning_Trees)

Weighted connections · Cycle checks · Minimum spanning trees · Alternative routes

- **Builds on:** GT Connectivity: Reuse reachability to ask whether endpoints are already connected.; SwarmIntelligence Particle Swarm Optimization: Reuse the need to state an objective before calling a result best.
- **Adds/deepens:** Distinguish economical connection under an edge-weight objective from the value of a redundant route.
- **Carries:** A selected connection set with its cost objective and deliberate extra route.
- **Review:** Focus needs revision. The code explains Kruskal but does not teach the proposed resilience comparison. verify_mst checks tree size and cycles, not minimum weight; Prim lacks a disconnected-graph exit. Separate a valid spanning tree from optimality before claiming verification.

### [GT Flow](http://localhost:3003/tutorial-cards?map=GT_Flow)

Capacity and flow · Residual capacity · Excess · Reversible allocation

- **Builds on:** GT Network Analysis: Reuse directed relation records.; GT Pathfinding: Reuse tracing routes through an available subgraph.
- **Adds/deepens:** Keep an edge’s limit, assigned amount and a vertex’s unallocated excess distinct while making revision possible.
- **Carries:** A reversible local allocation and a small rerouting example.
- **Review:** Focus needs revision. The current text teaches Edmonds–Karp augmenting paths while the proposed exhibit lesson uses push/relabel. Excess and algorithmic height are absent; all_vertices and visual helpers are undeclared. Choose and explain the local push interface before claiming the full solver.

### [GT Matching](http://localhost:3003/tutorial-cards?map=GT_Matching)

Pairing constraints · Greedy order · Augmenting paths · Validity and optimality

- **Builds on:** GT Foundations: Reuse vertices, edge pairs and occupied-state checks.; GT Flow: Reuse reversal of an earlier allocation.
- **Adds/deepens:** Improve a locally valid matching by revising a previous choice rather than confusing validity with maximum size.
- **Carries:** A concrete matching counterexample and one explicit augmentation.
- **Review:** Focus needs revision. The Hungarian loop is explicitly omitted; bfs_layers and dfs_augment are undefined. The tutorial still claims these methods and blossom contraction are learned, switches from the exhibit’s general graph to bipartite assignment, and incorrectly ends the curriculum here.

## Foundations Crisis: The Limits of Formalization

### [Euclid Parallel](http://localhost:3003/tutorial-cards?map=Euclid_Parallel)

Geometric assumptions · Constructed examples · Measurement and proof

- **Builds on:** Point Triangle Context: Reuse a triangle made from chosen points.; GT Matching: Reuse distinguishing a valid example from a general optimality claim.
- **Adds/deepens:** Identify which assumptions a geometric example already relies on before using it as evidence.
- **Carries:** A triangle with its construction rules declared for another geometry.
- **Review:** Focus needs revision. The current task builds plinths and toggles a chaos preview, then treats the picture as what follows from removing the fifth postulate. It does not supply the proposed triangle comparison or separate an authored preview from an independence argument.

### [NonEuclidean Spaces](http://localhost:3003/tutorial-cards?map=NonEuclidean_Spaces)

Distance models · Geodesics · Triangle comparisons

- **Builds on:** Euclid Parallel: Reuse the same triangle question while declaring its geometric assumptions.; Vectors Act1 WhatAVectorIs: Reuse coordinate positions and directions.
- **Adds/deepens:** Recognise that a straight route is defined by a distance model, not just its displayed shape.
- **Carries:** A geometric comparison whose samplers and angle convention remain explicit.
- **Review:** Focus needs revision. The lesson labels a radial Euclidean warp and repeated tangent heuristic as hyperbolic/elliptic geometry. That code does not establish the claimed models; supply model-specific geodesic/angle interfaces instead of equating a slider with curvature.

### [Russell Paradox](http://localhost:3003/tutorial-cards?map=Russell_Paradox)

Membership predicates · Finite domains · Self reference · Restricted construction

- **Builds on:** CA ElementaryRules: Reuse exhaustive checking of small Boolean cases.; GT Foundations: Reuse a declared finite collection of identified objects.
- **Adds/deepens:** Distinguish testing a predicate over available objects from asserting unrestricted self-containing collections.
- **Carries:** A finite membership construction with its domain and limits declared.
- **Review:** Focus needs revision. A filtered list of named boxes is treated as Russell’s unrestricted collection. The alarm and disabled inference are programmed effects, not consequences derived by a formal system; the finite alternative needs an explicit domain and scope.

### [Godel Incompleteness](http://localhost:3003/tutorial-cards?map=Godel_Incompleteness)

Proof checking · Bounded search · Unprovability claims

- **Builds on:** Russell Paradox: Carry the distinction between a constructed finite example and an unrestricted claim.; GT Pathfinding: Reuse a search result with a declared domain and failure condition.
- **Adds/deepens:** Separate checking a supplied derivation, failing to find one and establishing that none exists.
- **Carries:** A precise statement of what a stopped search has established.
- **Review:** Focus needs revision. search_proof calls undefined _derives and returns not found; evaluate_godel converts that directly to a true unprovable statement. The toy encoding and authored verdict do not supply a theorem or its assumptions; use the machine as a reflective prompt, not a proof.

### [Escher Impossible](http://localhost:3003/tutorial-cards?map=Escher_Impossible)

Closed path differences · Projection · Local and global claims

- **Builds on:** Point Lines: Reuse differences between endpoint coordinates.; GT Pathfinding: Reuse a complete route record.; Godel Incompleteness: Keep an illustrative device distinct from what its procedure establishes.
- **Adds/deepens:** Use a closed-loop check to locate the difference between an impossible-looking projection and the constructed geometry.
- **Carries:** A circuit with its height changes and viewpoint assumptions visible.
- **Review:** Focus needs revision. The code’s complete sum telescopes to zero, while the prose says all four rises are positive and the total is nonzero. The return edge descends; the lesson must retain this distinction and stop presenting the staircase as Gödel’s result.

### [Brouwer Intuitionism](http://localhost:3003/tutorial-cards?map=Brouwer_Intuitionism)

Finite prefixes · Witnesses · Open continuations

- **Builds on:** Point Trace: Reuse an incrementally retained ordered record.; Godel Incompleteness: Reuse distinguishing finite search failure from a general impossibility claim.
- **Adds/deepens:** Give a finite construction an inspectable witness while leaving its unmade continuation open.
- **Carries:** A prefix and a witness query with deliberately limited claims.
- **Review:** Focus needs revision. The lesson substitutes a required-string checklist and constructed flag for logical validity. It calls not-yet-constructed a third truth option and ends with blanket rejection of contradiction proofs; the proposed prefix/witness exercise is absent.

### [Florensky Paraconsistent](http://localhost:3003/tutorial-cards?map=Florensky_Paraconsistent)

Independent reports · Contradictory information · Consequence rules

- **Builds on:** Russell Paradox: Reuse checking the scope of a contradictory pair.; Brouwer Intuitionism: Reuse keeping the evidence for a conclusion explicit.
- **Adds/deepens:** Distinguish preserving contradictory data from choosing the rules that infer consequences from it.
- **Carries:** Two source-tagged reports and a bounded inference rule ready for practical disagreement.
- **Review:** Focus needs revision. The current probability pair is described as quantum superposition and paraconsistency. safe_infer is only a confidence filter; the example does not supply a consequence relation, and complementary probabilities do not preserve independent evidential support.

### [Crisis Synthesis](http://localhost:3003/tutorial-cards?map=Crisis_Synthesis)

Sentence arrays · Presentation scale · Display rhythm · Claims and warrant

- **Builds on:** Tutorial Disco: Reuse a timed reader over an ordered collection.; Primitives Portals: Return to the supplied geometry of written signs.; Godel Incompleteness: Retain the distinction between presenting a verdict and establishing it.
- **Adds/deepens:** Compose the presentation of a claim while preserving the question of its warrant.
- **Carries:** An authored sentence and a question about what would make the QFEP proposal accountable.
- **Review:** Focus fits the text. The appended sentence study teaches this composition and explicitly separates display from truth. The older summit/bifurcation recipe still leaves helpers unexplained and presents the formula more conclusively than the proposed research framing.

## QFEP Laboratory: The Formula Made Interactive

### [QFEP Introduction](http://localhost:3003/tutorial-cards?map=QFEP_Introduction)

Weighted expressions · Scalar summaries · Retained inputs · Research proposals

- **Builds on:** Crisis Synthesis: Carry a distinction between the authority of a formula’s display and its warrant.; Point Trace: Reuse a record that preserves what a summary leaves out.
- **Adds/deepens:** Expose compensating contributions to a scalar and treat the QFEP expression as a revisable project proposal.
- **Carries:** An explicit weighted calculation and its unreduced input record.
- **Review:** Focus needs revision. The tutorial builds labelled term spheres and prints a formula; it does not implement the calculation, preserve input records or compare equal totals. The supplied change value and reference names need explicit evidential limits.

### [QFEP F Term](http://localhost:3003/tutorial-cards?map=QFEP_F_Term)

Constant predictors · Mistake counts · Expected error · Source uncertainty

- **Builds on:** ML Gradient Landscape: Reuse prediction, observations and loss as different objects.; Random Entropy: Return to uncertainty defined over a stated source.
- **Adds/deepens:** Improve an explicit predictor without changing observations, separating observed mistakes from uncertainty and expectation.
- **Carries:** A retained sample, a predictor and a transparent error count.
- **Review:** Focus needs revision. The current text calls absolute distance variational free energy, moves observations toward targets and stages a zero-F dark room. It never supplies the proposed fixed-bit predictor comparison; the elementary score must retain its own name and limits.

### [QFEP E Term](http://localhost:3003/tutorial-cards?map=QFEP_E_Term)

Branching choices · Leaf counts · Equal probability assumptions · Retained exclusions

- **Builds on:** Fractal RecursiveTrees: Reuse branching records and recursive traversal.; Random Entropy: Reuse the dependence of entropy on probabilities, not just a picture.
- **Adds/deepens:** Relate outcome counting to declared equal weights while distinguishing a reopened diagram from recovery of a lost history.
- **Carries:** A choice tree with a leaf count, probability assumption and retained closure.
- **Review:** Focus needs revision. The current recipe measures positional spread, then its freeze handler sets the meter to 0.01 and calls that a finding about entropy. It contains no choice tree or leaf counter; neither spread nor a staged meter is the proposed equal-weight outcome calculation.

### [QFEP Lambda Spectrum](http://localhost:3003/tutorial-cards?map=QFEP_Lambda_Spectrum)

Spatial recommendations · Parameter mappings · Available routes

- **Builds on:** Boolean Works: Reuse separate geometry, appearance and clearance choices.; QFEP Introduction: Reuse the distinction between an authored weighting and evidence for it.
- **Adds/deepens:** Read a spatial recommendation as a design choice rather than a measurement of a universal regime.
- **Carries:** A route proposal with its recommendation and access conditions separated.
- **Review:** Focus needs revision. The tutorial programs complexity into a Gaussian centred at 0.4 and removes creatures away from it, then treats that authored effect as an edge-of-chaos result. Its distance ratio is also described as projection; the route-composition lesson is absent.

### [QFEP Phi Term](http://localhost:3003/tutorial-cards?map=QFEP_Phi_Term)

Finite differences · Rates of change · Signed weights · Receivers

- **Builds on:** Change Intro: Reuse the distinction between a difference and a rate.; QFEP Introduction: Reuse separating a weighted calculation from its interpretation.
- **Adds/deepens:** Track exactly what is changed, weighted and delivered to a receiver before assigning meaning to a sign.
- **Carries:** A change calculation with its interval, signed weight and receiver stated.
- **Review:** Focus needs revision. The lesson calls a finite difference an instantaneous rate, changes the formula’s delta to a rate without accounting for the choice, and assigns political identities and reward/penalty meanings directly to slider signs. The data source and receiver need explicit contracts.

### [QFEP Edge Of Chaos](http://localhost:3003/tutorial-cards?map=QFEP_Edge_Of_Chaos)

Time steps · Equal time comparisons · Model parameters · Numerical behaviour

- **Builds on:** ProceduralGeneration Reaction Diffusion Systems: Reuse a field changed by local reaction and diffusion.; Change Intro: Reuse elapsed time as part of an update’s meaning.
- **Adds/deepens:** Separate changes to a model from changes to its numerical execution.
- **Carries:** A paired numerical comparison with initial state, step size and duration declared.
- **Review:** Focus needs revision. The current recipe calls undefined _apply_rd, scripts an edge window and deletes patterns outside it while generalising to life and unrelated algorithms. It provides no equal-time step-size comparison and cannot establish a universal lambda band.

### [QFEP Sandbox](http://localhost:3003/tutorial-cards?map=QFEP_Sandbox)

Input routing · Retained inputs · Receiver mappings

- **Builds on:** Color Nails: Reuse an input-to-output mapping with a particular receiver.; QFEP Phi Term: Reuse keeping a numerical weight distinct from what actually receives it.
- **Adds/deepens:** Distinguish control position, connection state and the last value retained by a receiver.
- **Carries:** An account of one connected route and what its receiver changes.
- **Review:** Focus fits the text. The present control comparison supports these labels. Constructing a separate learner receiver, as proposed by the storyboard, still needs a declared control interface and a short mapping example.

### [QFEP Synthesis](http://localhost:3003/tutorial-cards?map=QFEP_Synthesis)

Stiffness and damping · Forcing and response · Coupled controls

- **Builds on:** SoftBodies Soft Body Deformation: Reuse a deforming body and restoring response.; QFEP Sandbox: Reuse separating displayed controls from the values a receiver uses.
- **Adds/deepens:** Read motion through forcing, restoring and dissipative choices without treating coefficient readouts as measured entropy.
- **Carries:** A specific body response with its changed and retained coefficients identified.
- **Review:** Focus fits the text. The current comparison teaches coupled controls honestly. The storyboard’s independently mapped stiffness/damping controls and retained trace remain a later construction, not an existing isolated experiment.

## Post-Crisis: Applied Limits

### [CriticalAlgorithms Algorithmic Bias Visualization](http://localhost:3003/tutorial-cards?map=CriticalAlgorithms_Algorithmic_Bias_Visualization)

Spatial interpolation · Viewpoint and geometry · Representational distinctions

- **Builds on:** Trans Introduction: Reuse interpolation between retained positions.; QFEP Lambda Spectrum: Reuse examining how an authored spatial mapping recommends an interpretation.
- **Adds/deepens:** Locate the consequences and exclusions of a chosen representation without treating a spatial analogy as a measured embedding.
- **Carries:** A named pair, viewpoint and representational distinction to preserve.
- **Review:** Focus fits the text. The written comparison and limits are present. Authoring two new label arrangements remains proposed; their renderer and indexed record need to be supplied explicitly for that extension.

### [CriticalAlgorithms Applied Ethics](http://localhost:3003/tutorial-cards?map=CriticalAlgorithms_Applied_Ethics)

Spatial arrangements · Comparison variables · Participation conditions

- **Builds on:** CriticalAlgorithms Algorithmic Bias Visualization: Reuse separating represented geometry from its presentation.; WaveFunctions Unit Circle: Reuse angular spacing for generated positions.
- **Adds/deepens:** State what equal spacing guarantees and what participation would still require people to test.
- **Carries:** A design question tied to a particular participant’s approach or sightline.
- **Review:** Focus fits the text. The lesson explicitly identifies confounded count/scale/position variables. A matched learner-built arrangement and testing with participants are correctly presented as a next experiment.

### [SpeculativeComputation Paraconsistent Engineering](http://localhost:3003/tutorial-cards?map=SpeculativeComputation_Paraconsistent_Engineering)

Source tagged reports · Decision records · Revisable resolutions

- **Builds on:** Florensky Paraconsistent: Reuse the distinction between storing contradiction and inferring consequences.; GT Network Analysis: Reuse provenance attached to a recorded relation.
- **Adds/deepens:** Make a practical resolution revisable without erasing the reports that made it difficult.
- **Carries:** Two retained reports and a separate decision with its reason.
- **Review:** Focus needs revision. The current lesson carefully distinguishes sculpture, storage and inference, but does not construct a source-tagged report/decision record. Its next experiment proposes an inference table instead; decide the bounded construction and its supplied record/display interface.

### [SpeculativeComputation Situated Computation](http://localhost:3003/tutorial-cards?map=SpeculativeComputation_Situated_Computation)

Observation provenance · Exposure time · Camera transforms · Retained views

- **Builds on:** Point Trace: Reuse retention of an earlier state.; Point Coordinates: Reuse a position in a declared frame.; SpeculativeComputation Paraconsistent Engineering: Carry a source and context with a report.
- **Adds/deepens:** Keep an observation’s source, time and viewpoint distinct from the current receiver or camera position.
- **Carries:** A located observation whose earlier exposure remains interpretable.
- **Review:** Focus fits the text. The appended delay edit and portable-camera explanation support this focus. Building a new image-reference record remains proposed; capture, buffer and pickup internals are supplied rather than counted as learned.

### [SpeculativeComputation Collective Knowledge](http://localhost:3003/tutorial-cards?map=SpeculativeComputation_Collective_Knowledge)

Event counts · Distinct contributors · Revision provenance · Shared authority

- **Builds on:** SpeculativeComputation Situated Computation: Reuse a source-tagged retained observation.; SwarmIntelligence Swarm Intelligence Algorithms: Return to separating visible activity from the support and history behind it.
- **Adds/deepens:** Account for contributions and revisions without making activity counts or an open centre stand for distributed authority.
- **Carries:** A contribution record with source, version and a question about who may revise the rule.
- **Review:** Focus fits the text. Counting and retained-source distinctions are taught. A learner-built shared form and a rule another participant can actually revise remain proposals; the automatic stream does not demonstrate collaboration.

### [SpeculativeComputation Rhizome Network](http://localhost:3003/tutorial-cards?map=SpeculativeComputation_Rhizome_Network)

Graph connections · Passage geometry · Alternative routes · Uneven access

- **Builds on:** GT Connectivity: Reuse connected groups and reachability.; ISO Caves: Reuse bodily clearance and entrances.; SpeculativeComputation Collective Knowledge: Reuse questioning how a shared form allocates access and revision.
- **Adds/deepens:** Compose graph and bodily accounts of a route while recognising how proximity and arrival order distribute opportunities.
- **Carries:** A proposed connection whose graph relation and inhabitable route must both be tested.
- **Review:** Focus fits the text. The present walking and link-control comparisons teach these distinctions. Adding a chamber connection is explicitly a further experiment; no existing cave-edit control or automatic graph-to-cave handoff is assumed.

### [AdvancedLaboratory Lab Equipment Simulation](http://localhost:3003/tutorial-cards?map=AdvancedLaboratory_Lab_Equipment_Simulation)

Pose and connectivity · Local coordinates · Relational constraints · Retained assemblies

- **Builds on:** GT Foundations: Reuse endpoint pairs as an explicit connection record.; SoftBodies Cloth Physics: Reuse constraints that transmit consequences.; SpeculativeComputation Rhizome Network: Reuse separating an altered connection from an altered spatial route.
- **Adds/deepens:** Compose a body through positions and relations, distinguishing a drawn bond from a constraining relation.
- **Carries:** The learner’s own revised body record, including its connection change.
- **Review:** Focus needs revision. The current tutorial follows catalogue docking and describes relation editing only as a future experiment. It does not teach the proposed joint/endpoint edit, dynamic-body comparison or retained learner record needed by the final hall.

### [PostCrisis Synthesis](http://localhost:3003/tutorial-cards?map=PostCrisis_Synthesis)

Versioned records · Recoverable arrangements · Counts and memory · Future revisions

- **Builds on:** AdvancedLaboratory Lab Equipment Simulation: Carry the same learner-authored positions and connections.; SpeculativeComputation Collective Knowledge: Reuse source/version distinctions and the limits of retained history.; Point Zero: Return to a running count while distinguishing it from remembered contents.
- **Adds/deepens:** Choose what a later return can recover and carry an unfinished construction into independent work.
- **Carries:** Two recoverable arrangements and a chosen next body or passage.
- **Review:** Focus needs revision. The text teaches a six-line scripted ledger and honestly says it saves no visitor decisions. It does not yet return the learner’s body, retain versions or teach reconstruction; that ending remains a proposed construction, not delivered persistence.
