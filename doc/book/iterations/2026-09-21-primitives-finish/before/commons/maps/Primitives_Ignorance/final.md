You left a cube whose connections could outlast its name. Now try the name sphere. What are you accepting when you recognise something as round?

<!-- @sphere -->

Begin with the ordinary sphere near the entrance. Look at it from a distance, then approach. Follow its silhouette against the room beyond it. Where does the outline give you something to inspect that the name had allowed you to pass over?

The room carries an instruction: **Let no one ignorant of geometry enter here.** It recalls the motto traditionally associated with Plato's Academy.[^ignorance-inscription] Here we have entered with a little geometry. We will use it to inspect the limits of the forms that seemed to admit us.

<!-- @sphere_high -->

Start with the first pair in the resolution display. One sphere wears lines along its triangle edges; the other has plain shading. Predict whether removing the lines also changes the sphere's outline. Walk around the pair and compare.

The two meshes have the same vertex positions and triangle connections. The lines are an added overlay. They make a construction easier to follow without rebuilding its surface.

Choose one place where the silhouette changes direction. Step back until that distinction becomes difficult to see, then approach again. Your distance changed. The mesh did not.

<!-- @sphere_mid -->

Continue to the middle pair. Inspect it from a comparable distance. Which distinctions are easier to find now? Compare the marked example with its plain neighbour before comparing it with the finer pair behind you.

The finer pair uses sixteen rings and sixteen radial segments; this pair uses seven of each. Those two settings divide different directions of the surface. Changing them changes the positions and connections available for making it.

<!-- @sphere_low -->

At the coarsest pair, follow one flat patch toward its edge. Is this merely a sphere missing something, or is there a feature here you would choose to keep?

Its construction uses one ring and ten radial segments. One direction is divided more often than in the middle example, the other much less. Resolution has a distribution. It does not arrive as a single quantity called detail.

The script gives the two choices separate names:

```gdscript
sphere_mesh.radial_segments = segment_count
sphere_mesh.rings = ring_count
```

A mathematical sphere consists of points at a fixed distance from a centre. The mesh joins sampled positions with flat triangles. Adding triangles can improve that approximation; no finite collection of flat patches acquires the sphere's continuous curvature. Shading can soften their appearance while the polygonal outline remains.

This is where ignorance turns around. Plato distinguishes the drawn figure from the geometric object considered in thought. Here we turn our attention toward the constructed figure: what its polygons leave out, and what their particular arrangement makes available.[^ignorance-plato]

The formula specifies a sphere. The mesh gives us one finite construction through which to encounter it. The ridge is available too. We can learn from its shape without requiring it to disappear into a smoother answer.

<!-- @budget_of_smoothness -->

Return to the counter by the inscription. Four numbered spheres turn at the same rate. Keep the counts hidden at first. Choose one for a distant background and one for someone to inspect close to their face. The spheres stay on their stands; you are choosing possible uses.

Press **SHOW / HIDE COUNTS**. Did the numbers change your choice? Then press **SHOW / HIDE EDGES** and follow the lines toward a pole.

Each tag gives two triangle counts. Even counting depends on what the instrument agrees to include.[^ignorance-counts]

Hide the counts while keeping the edges visible, then try the reverse. What becomes easier to judge? Both controls alter what is shown while keeping the sphere meshes in place.

A triangle count does not measure frame time or tell us which object deserves to exist. For your proposed use, name the distinction worth spending geometry on. You might spend more on a close silhouette, or keep a facet because it makes this body recognisable.

<!-- @capsule -->

Before leaving, find the five-sided capsule. Let it turn. When a ridge faces you, picture the other side. Would the same ridge be waiting there? Follow the silhouette as another side comes into view.

Five segments divide the body around its long axis. Opposite a ridge is the middle of a facet. Half a turn does not bring this cross-section back onto itself. The divisions are evenly spaced, but their odd number interrupts that particular symmetry.[^ignorance-capsule]

You cannot fold your understanding around this corner by simply repeating the front at the back. The shortcut fails. You have to follow another side, or learn the rule well enough to work it out. The object remains knowable; recognising a capsule was not yet knowing this one.

Stay with what the five divisions produced. Between the familiar pill and its polygonal construction, a body appears that the name did not prepare you for. Its surprise is made within the restriction. What would you miss if you corrected it into the capsule you expected?

This gives ignorance another direction: a limit in our expectation becomes somewhere to look. The same small set of instructions that confines the form can make more available than we first knew to ask of it.

<!-- @ -->

The five regular solids and the irregular rock remain around this experiment. Their symmetry and construction offer [return visits](/book?map=Primitives_Ignorance&section=tutorial). We do not need to settle every shape before leaving.

Carry a more specific question than whether the sphere is good enough: **enough to hold which distinction, for whom, at what distance?**

The polygonal model has a limit; our first understanding of its possibilities has one too. The next room follows a finite sequence of round-looking objects toward a boundary none of its examples reaches.

[^ignorance-inscription]: The Academy motto is a later tradition, not a securely documented inscription from Plato's lifetime. See [The Academy of Plato](https://mathshistory.st-andrews.ac.uk/Societies/Plato/), MacTutor History of Mathematics. The museum stages the familiar wording as an instruction whose authority we can question.

[^ignorance-plato]: Plato, [Republic, Book VI](https://classics.mit.edu/Plato/republic.7.vi.html), Benjamin Jowett translation, the divided-line discussion: drawn figures serve reasoning about geometric objects rather than being its ultimate objects. Ada's reversal is methodological: stay with the implemented figure and investigate its limits and possibilities. This does not establish that Plato was unaware of imperfect drawings, or that geometry cannot describe curves.

[^ignorance-counts]: Some generated triangle triples collapse at the poles. The counter distinguishes all submitted triples from those with measurable area in [Godot 4.6 SphereMesh](https://docs.godotengine.org/en/4.6/classes/class_spheremesh.html) arrays. “With area” excludes triangles below a local squared-cross-product tolerance of `1e-16`; it is a practical threshold. The [technical chapter](/book?map=Primitives_Ignorance&section=technical) records all four measured pairs of counts. Overlays and counter furniture are excluded. Analytic sphere descriptions and this finite polygonal rendering are different representations.

[^ignorance-capsule]: The installed `capsule.tscn` uses a [CapsuleMesh](https://docs.godotengine.org/en/4.6/classes/class_capsulemesh.html) with five radial segments and five rings. Its regular pentagonal cross-section repeats after 72 degrees, but not after 180 degrees about the long axis. The absent half-turn symmetry does not make all symmetry disappear. The scene turns at 45 degrees per second. These are the authored mesh and spin settings, not controls available on the plinth.
