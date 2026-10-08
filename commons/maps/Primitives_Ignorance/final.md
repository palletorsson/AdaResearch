# Limits of Geometric Knowledge

You left a cube whose connections could outlast its name. Now try the name sphere. What are you accepting when you recognise something as round?

<!-- @sphere -->

Begin with the ordinary sphere near the entrance. Look at it from a distance, then approach. Follow its silhouette against the room beyond it. Where does the outline give you something to inspect that the name had allowed you to pass over?

Above the entrance: **Let No One Ignorant of Geometry Enter.** It recalls the motto traditionally associated with Plato's Academy.[^ignorance-inscription] Here we have entered with a little geometry. We will use it to inspect the limits of the forms that seemed to admit us. You are not ignorant of geometry any more; you have built it from a point to a solid. What you are about to find out is what the building left out, and that ignorance is not a lack. It is a structure. A model keeps by omitting, and the omitted does not vanish. It stands around in here, on plinths.

<!-- @geometry_courtyard -->

Inside, five solids have been given five places. Tetrahedron, cube, octahedron, dodecahedron, icosahedron. Off-white and almost black, each rests on a plain block. You can lift one and bring a face toward you. Its edges remain sharp. There is nothing unfinished about that sharpness.

Why five? Not because someone chose. Two rooms ago you learned that a corner must be missing something, and that a closed solid has 720 degrees of missing to spend. Ask for regular faces and the same number at every corner, and the arithmetic leaves exactly five ways to do it: three, four or five triangles at a corner, three squares, three pentagons. Six triangles lie flat. Four squares lie flat. Three hexagons lie flat. And 720 divided by what each corner is missing is how many corners the solid has: four, six, twelve, eight, twenty. The ideal set is not a list. It is a remainder.

Six corners, twelve edges, eight faces. Now say the cube's numbers backwards: eight corners, twelve edges, six faces. The octahedron is the cube with its corners and faces exchanged, and the exchange is called duality. Put one inside the other and every corner of one points at a face of the other. Two of the five are one shape read two ways.

Columns surround the group. Near the entrance their sides are easy to count; farther along, the corners draw closer together. Four divisions, then five, six, eight. Eventually the column looks round. Walking along the court, you pass through several constructions of the same architectural name.

Four sides can be a poor approximation to a round column and the outline we wanted to keep. A proportion gives us a relation between dimensions. It does not tell us whether that relation is beautiful. Before asking for more detail, what are we asking the form to give us?

The solids do not take that journey. An icosahedron has twenty faces because it is an icosahedron. Adding more would give you something else. In the next room, the sphere keeps its name while the number of faces changes. What did the name ask us to preserve?

<!-- @sphere_high -->

The next room holds three pairs of spheres. Start with the first pair in the resolution display. One sphere wears lines along its triangle edges; the other has plain shading. Predict whether removing the lines also changes the sphere's outline. Walk around the pair and compare.

The two meshes have the same vertex positions and triangle connections. The lines are an added overlay. They make a construction easier to follow without rebuilding its surface.

Choose one place where the silhouette changes direction. Step back until that distinction becomes difficult to see, then approach again. Your distance changed. The mesh did not.

<!-- @sphere_mid -->

Continue to the middle pair. Inspect it from a comparable distance. Which distinctions are easier to find now? Compare the marked example with its plain neighbour before comparing it with the finer pair behind you.

The finer pair uses sixteen rings and sixteen radial segments; this pair uses seven of each. Those two settings divide different directions of the surface. Changing them changes the positions and connections available for making it.

<!-- @sphere_low -->

At the coarsest pair, follow one flat patch toward its edge. Is this merely a sphere missing something, or is there a feature here you would choose to keep?

Its construction uses one ring and ten radial segments. One direction is divided more often than in the middle example, the other much less. Resolution has a distribution. It does not arrive as a single quantity called detail.

The machine has no circle. Every cylinder, every capsule, every sphere it has ever drawn is a number of segments, and at any finite number a round body is a prism: n side faces and two caps, and vertices minus edges plus faces is two, the way it always is. Lower the number far enough and the sphere is a prism with a name: triangular, square, hexagonal. Resolution is not detail laid on a form. It *is* the form, and the form was decided by whoever typed the integer.

The script gives the two choices separate names:

```gdscript
sphere_mesh.radial_segments = segment_count
sphere_mesh.rings = ring_count
```

You once held a point and decided where it would stay. Two points gave you a span. To make a face, positions needed an order; to make a mesh, faces needed connections. Here two settings ask the engine to distribute positions and connect them across a whole surface. A small decision reaches many places at once.

The vertices remain finite and countable. A hand places a corner; a rule places a family of corners in relation. We choose a procedure, let it make the placements, then return to what appeared. Knowing the rule gives us another way to know the form, while its particular surface still asks to be looked at. Which differences can we make through the rule, and which require us to return to a particular point?

<!-- @sphere_resolution_atlas -->

Across the room, twelve smaller spheres spread the two choices out in space. Across each row, more rings divide the height. Along each column, more segments divide the circumference. Their triangle edges remain visible. You can follow one change while the other holds still.

A crowded equator can belong to a sparsely divided body. One figure has a broad flat face where another gathers many narrow triangles. Both answer to sphere. Before deciding which is more convincing, look for a shape you had not expected to find there.

A mathematical sphere consists of points at a fixed distance from a centre. The mesh joins sampled positions with flat triangles. Adding triangles can improve that approximation; no finite collection of flat patches acquires the sphere's continuous curvature. Shading can soften their appearance while the polygonal outline remains.

![The existing high, middle and low sphere artifacts in matched views: triangle edges visible above, hidden below. Each column keeps the same mesh.](/book-review/doc/book/figures/Primitives_Ignorance/sphere-visible-construction.png)

*The lower row keeps every triangle in the upper row. The lines disappear; the construction remains.*

This is where ignorance turns around. Plato distinguishes the drawn figure from the geometric object considered in thought. Here we turn our attention toward the constructed figure: what its polygons leave out, and what their particular arrangement makes available.[^ignorance-plato]

The formula specifies a sphere. The mesh gives us one finite construction through which to encounter it. The ridge is available too. We can learn from its shape without requiring it to disappear into a smoother answer.

<!-- @budget_of_smoothness -->

At the far end of this room, a counter makes the cost of these choices countable. Four numbered spheres turn at the same rate. Keep the counts hidden at first. Choose one for a distant background and one for someone to inspect close to their face. The spheres stay on their stands; you are choosing possible uses.

Press **SHOW / HIDE COUNTS**. Did the numbers change your choice? Then press **SHOW / HIDE EDGES** and follow the lines toward a pole.

Each tag gives two triangle counts. Even counting depends on what the instrument agrees to include.[^ignorance-counts]

Hide the counts while keeping the edges visible, then try the reverse. What becomes easier to judge? Both controls alter what is shown while keeping the sphere meshes in place.

A triangle count does not measure frame time or tell us which object deserves to exist. For your proposed use, name the distinction worth spending geometry on. You might spend more on a close silhouette, or keep a facet because it makes this body recognisable.

<!-- @capsule_reliquary -->

At the centre, the five-sided capsule turns above a stepped pedestal. Eight pale tiers carry it: cylinders with four divisions through eleven, each smaller than the one beneath. Corners shift around the stack. The support is making its own argument about roundness.

The capsule is taller now, nearly the height of a person. Its dark surface receives the light slowly as it turns. A small, awkward construction has been given the place of an object worth lingering before. Its five divisions did not require this ceremony. We gave it height, a pedestal, room around it. How much of what holds your attention have we built between you and the object?

When a ridge faces you, picture the other side. Would the same ridge be waiting there? Follow the silhouette as another side comes into view. The arrangement draws you closer to a construction you can inspect. Knowing how the encounter was made can give you another reason to stay.

Five segments divide the body around its long axis. Opposite a ridge is the middle of a facet. Half a turn does not bring this cross-section back onto itself. The divisions are evenly spaced, but their odd number interrupts that particular symmetry.[^ignorance-capsule] Odd is a way of not equalling yourself.

You cannot fold your understanding around this corner by simply repeating the front at the back. The shortcut fails. You have to follow another side, or learn the rule well enough to work it out. The object remains knowable; recognising a capsule was not yet knowing this one. The back of this thing is genuinely unknown from here, which is the name of the room.

Stay with what the five divisions produced. Between the familiar pill and its polygonal construction, a body appears that the name did not prepare you for. Its surprise is made within the restriction. What would you miss if you corrected it into the capsule you expected?

The thing that refuses the ideal is not outside the set. It is in the standard kit, under the dullest name in it, and one integer away from the ones that comply.

This gives ignorance another direction: a limit in our expectation becomes somewhere to look. The same small set of instructions that confines the form can make more available than we first knew to ask of it.

![The five-segment capsule raised on eight cylinders, with resolutions four through eleven.](/book-review/doc/book/iterations/2026-09-27-ignorance-courtyard/five-on-four-to-eleven.png)

*The capsule keeps its five divisions. The pedestal changes the attention we give them.*

The old studies remain through the side opening: the rock, the star, the extra cubes and other studies. The choir joins the engine mesh library in the next hall, Primitives_Godot. The court has made a clear arrangement without exhausting what these forms might become.

<!-- @truncatedtetrahedron -->

Cut the corners off the smallest one. Each corner becomes a triangle, four new faces, and the solid is no longer ideal. It belongs to a bigger family, the Archimedean, indexed by how deep the cut goes. The ideal set is one cut away from a family the menu never mentions.

<!-- @roughrock -->

A solid whose corners were pushed off their ideal places. The rock is the remainder made into an object: everything the ideal set left out, standing on a plinth. What resists abstraction is not noise. It is signal.

<!-- @righttriangle -->

And the thing that does not resist, for contrast. Move it anywhere, turn it any way, and the right angle survives, the way it did three rooms ago. An invariant is what a model keeps. This room has been about what it drops.

<!-- @hole_with_cones -->

Three cones around nothing. There was a hole here, in the code, and it is no longer drawn; the cordon stayed. That is the room's emblem, and it is exact: a marker for the thing the model left out, standing where the thing was. Every primitive in this hall is three cones around something.

<!-- @form_in_hand -->

The last bay opens to the night. A torus hangs five metres above the floor, with sky visible through its centre. Its rings and segments change one count at a time. Watch the shadow: a rounded opening acquires corners without anything touching the ground. The moon carries a decision made overhead to the place where you stand.

Beside it, a black point hangs within reach. Take it. As you hold it, the rings and segments decrease; corners emerge where the surface seemed continuous. Its radius stays the same. The hand that examined the form now changes the terms of its construction.

Press the trigger and a copy leaves your hand, keeping the divisions it had at that instant. The point remains with you. Here is the beginning of a catalyst: a form we were learning to recognise becomes something we can act with. What do we want it to do, once understanding gives us that possibility?

<!-- @ -->

Carry a more specific question than whether the sphere is good enough: **enough to hold which distinction, for whom, at what distance?**

That is what a primitive is in a machine: not the simplest thing but the most *enclosed*, an interface that shows you a sphere and keeps thirty-two integers behind it. Calling something primitive is a move, not a description.

The polygonal model has a limit; our first understanding of its possibilities has one too. Godot’s supplied forms, a family of columns and borrowed letter outlines give these choices their own rooms. Portals then follows a finite sequence of round-looking objects toward a boundary none of its examples reaches.

[^ignorance-inscription]: The Academy motto is a later tradition, not a securely documented inscription from Plato's lifetime. See [The Academy of Plato](https://mathshistory.st-andrews.ac.uk/Societies/Plato/), MacTutor History of Mathematics. The museum stages the familiar wording as an instruction whose authority we can question.

[^ignorance-plato]: Plato, [Republic, Book VI](https://classics.mit.edu/Plato/republic.7.vi.html), Benjamin Jowett translation, the divided-line discussion: drawn figures serve reasoning about geometric objects rather than being its ultimate objects. Ada's reversal is methodological: stay with the implemented figure and investigate its limits and possibilities. This does not establish that Plato was unaware of imperfect drawings, or that geometry cannot describe curves.

[^ignorance-counts]: Some generated triangle triples collapse at the poles. The counter distinguishes all submitted triples from those with measurable area in [Godot 4.6 SphereMesh](https://docs.godotengine.org/en/4.6/classes/class_spheremesh.html) arrays. “With area” excludes triangles below a local squared-cross-product tolerance of `1e-16`; it is a practical threshold. The [technical chapter](/book?map=Primitives_Ignorance&section=technical) records all four measured pairs of counts. Overlays and counter furniture are excluded. Analytic sphere descriptions and this finite polygonal rendering are different representations.

[^ignorance-capsule]: The central installation reuses `capsule.tscn`, enlarged uniformly to 1.6 times its authored size. It uses a [CapsuleMesh](https://docs.godotengine.org/en/4.6/classes/class_capsulemesh.html) with five radial segments and five rings. Its regular pentagonal cross-section repeats after 72 degrees, but not after 180 degrees about the long axis. The absent half-turn symmetry does not make all symmetry disappear. The scene turns at 45 degrees per second. These are the authored mesh and spin settings, not controls available on the plinth.
