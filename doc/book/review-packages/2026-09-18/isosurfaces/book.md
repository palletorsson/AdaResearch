# isosurfaces: the chapters

## ISO Introduction

*ISO_Introduction*

# A boundary made from values


Where does this surface come from if nobody drew its outline?

Move around the blue specimen with pink triangle edges. Choose a visible boundary and follow it across several triangular patches. Look for a place where the outline turns sharply, then compare it with a smoother region. The large form is continuous-looking, but its visible surface has been assembled from small pieces.

Choose a short edge between two visible triangles and follow it towards the next patch. Then step back until those small divisions become difficult to distinguish. The overall form remains readable even as its construction recedes from view. Return closer and compare the two readings. Neither distance is the uniquely correct way to see the specimen: one reveals an assembled boundary and the other its larger organisation. What matters is remembering that a smooth-looking silhouette at a distance does not erase the finite pieces from which this display is made.

Before those pieces exist, the generator samples a noise field throughout a volume. Each sample receives a number. A chosen level divides the samples into two classes: values below it and values on the other side. Where neighbouring samples cross that level, the program estimates positions for a boundary.

An isosurface is the set of locations at one selected value of a scalar field. This mesh is a finite approximation to such a set. Its triangles connect estimated crossings; they are not the field itself, and the regions where no triangle appears still have field values.

The porous specimen in the previous room introduced the same distinction between values and visible form. Here, keep it in view while examining the polygon structure. The threshold did not add a decorative skin to a finished cave. It helped determine which boundary would exist in the first place.

Return to the desk. Before pressing LEVEL, choose a neck, an opening or a patch of boundary to watch. LEVEL cycles through 0.50, 0.45 and 0.55. The source field stays fixed: the same seed, noise settings, domain and sample positions. What changes is the value at which we ask for a surface. A piece may retreat, join another or disappear; the button does not promise the same event at every place.

```gdscript
density = (noise_value + 1.0) * 0.5
if density < iso_level:
    config_index |= (1 << i)
```

The first line produces a sample value. The comparison in the second classifies one corner; its bit contributes to a local case number. Lowering the level means fewer samples satisfy this particular comparison. It does not mean that every visible opening must grow. Boundary, enclosed volume and passage are different things to inspect.

Press HOLD to leave a second specimen to the right. Then RESET the live one. The held mesh remains where it was: a record of the earlier level and sampling, labelled with both. It has no collision of its own. The live specimen retains its generated collider. CLEAR removes the copy, leaving the live field alone.

SAMPLES asks a different question. It cycles through 24, 16 and 32 sample positions on each axis: 13,824, 4,096 and 32,768 values. The noise recipe and the extent of the sampled box stay the same. The mesh is displayed at 0.18 of its source size, so that box spans 5.76 metres in the hall. More samples refine this approximation; they do not supply knowledge about an original object hidden behind the noise.

A small passage may depend on both level and sampling. Absence from the mesh does not establish absence from the underlying field, particularly where a feature falls between widely separated samples. Nor does a visible hole establish clearance for your body. Hold that uncertainty beside the usefulness of the procedure: a few rules have made a boundary we can encounter, and its exclusions are now specific enough to test.


The next room opens the local construction. Eight corner samples will select a case, and that case will tell the extractor which edges to join.

---

## ISO LookupTable

*ISO_LookupTable*

# Eight samples, one local decision


What can eight corner samples tell you about the space between them?

Compare two tiles in the fifteen-case display. Find their corner indicators before following their triangle edges. Look for a tile with one separated corner, then another in which several corners share a classification. How does the boundary change when the arrangement of classified corners changes?

Choose a pair of indicators on opposite ends of an edge and ask whether their classifications agree. If they disagree, locate the corresponding boundary crossing where it is visible. Repeat on another edge before trying to read the whole tile. This lets you build an explanation from a relation small enough to check directly. When the corner arrangement becomes more complicated, retain that edge-by-edge reading instead of guessing a familiar shape. The case table organises many such local questions, but each crossing still begins with values at particular sample positions.

The corner values used by the indicators also feed the surface generator. A comparison with the threshold turns each corner into a bit. Eight bits provide a case number, which selects a triangle arrangement from a table. Edge crossings are then positioned using the numerical values at their endpoints.

These are two different uses of the samples. Their signs choose a connection pattern; their magnitudes help decide where a crossing lies along an edge. Two cells can choose the same table case while placing its triangle vertices at different positions.

The previous room showed the assembled surface. This display makes some of its recurring local decisions easier to inspect. The fifteen examples show selected arrangements, while the complete corner classification contains two hundred and fifty-six masks. Symmetries help relate cases; they do not remove every ambiguity about a continuous surface between samples.

There is another scale to attend to: the displayed pieces include surrounding sampled cells. Read the marked corners as the local question under study, rather than assuming every visible triangle belongs to one isolated cube.

Press TRACE. Gold markers appear where the cage edges cross the selected level. Choose one before pressing MARGIN. The values change from 0.30/0.70 to 0.14/0.54, then 0.44/0.84 and 0.48/0.88. The threshold remains 0.50. Every low value stays below it and every high value stays above it.

From the high endpoint toward the low endpoint, the crossing moves through 0.50, 0.10, 0.85 and 0.95 of the edge. Watch the marker before looking at the entire sheet. Its movement follows a small calculation:

```gdscript
t = (threshold - d0) / (d1 - d0)
position = p0.lerp(p1, t)
```

OPERANDS hides the extracted sheets, leaving the cages and samples. SURFACE removes those guides and shows the generated result. RESET restores the complete display and evenly spaced values. MARGIN changes the values in any of these views. Which view lets you explain what just happened, and which invites you to forget the construction?

The labels expose another convention. The inherited arrangement number sets bits for high-valued corners. The extractor sets bits for values below 0.50. Those masks are complements: arrangement 1 has table mask 254. The positions and values agree; the two names count opposite classes. “Inside” has not arrived with an independent physical meaning.

These are fifteen selected arrangements, including empty and full classifications, not a demonstrated exhaustive catalogue of distinct topologies. On alternating faces, corner classifications alone leave a connectivity question for the algorithm. This display shows the installed table’s choice; it does not compare every ambiguity-resolution strategy. Keep that limit available for a later experiment.


Next, the field will describe familiar objects. The triangle-making procedure can remain the same even when the description supplied to it changes between different shape descriptions.

---

## ISO ShapesGallery

*ISO_ShapesGallery*

# The same tool makes a cup


Can the procedure that makes a chair also make a hollow cup?

Compare the labelled Chair and Cup in the shapes gallery. Find a junction between parts of the chair, then look for the cup's inner boundary and its handle. Move to a second viewpoint where a hollow and a projecting part are easier to distinguish. Describe those relations before naming their ingredients.

Inspect a junction on the chair from a second angle. A seam can disappear in the combined surface even though the description still contains separate ingredients. Then compare the cup's hollow with the empty space around its handle. Both are absences in a familiar object, but they arise from different parts of its description. You need not recognise every primitive to establish that these relations differ. Naming one junction and one opening gives you a smaller, more testable account than saying that the generator understands household objects.

Press HOLD. The middle-column chair and cup are copied beside the desk. They keep their current geometry when the live gallery changes. Choose a gap between the chair's legs, or the opening of the cup. What do you expect LEVEL to do there?

Press LEVEL once. The extraction level moves from zero to minus two. Compare the live objects with the held pair. Look for a part that has narrowed or disappeared, then one that still carries the object's name. LEVEL affects all six fields; it does not know which part you meant to protect. Further presses choose plus four and plus ten before returning to zero.

The chair is described by combining box-like fields for a seat, back and legs. The cup uses a different composition: an inner cylinder is subtracted from an outer one, then a ring-like handle is joined to the result. These descriptions provide values throughout space. The same extraction apparatus samples them and builds the visible boundary.

In the shader, joining two fields takes their minimum. Subtracting the interior takes the maximum of the outside field and the negated inside field. The cup's description can be read in one short expression. Here the variable names stand for the fields evaluated at the same point:

```glsl
float cup = min(max(-inside, outside), handle);
```

That line describes a relation at a point. Sampling repeats the question across space; the extractor connects the crossings. Moving the selected level changes the question asked of the whole composition. It is not a command to thicken only the cup wall.

The lookup table does not need to know what a cup is. It receives corner values and performs the local work you examined in the previous room. Recognition belongs to the larger arrangement of those values and to the person reading the resulting form.

This separation makes procedural modelling reusable. A new description can enter an existing extraction process. It also lets us ask whether an error belongs to the description, the sampling, or the way the generated mesh is displayed.

A familiar silhouette is not a complete design for use. A thin handle may disappear at coarse resolution; a chair-like figure may have no suitable support or dimensions for sitting. The label supplies a proposed interpretation, not evidence that the object fulfils every function associated with its name.

Try REPERTOIRE. Household gives way to laboratory, abstract and survey arrangements, using the same extraction machinery. The held pair stays beside you. A field can describe an operator and an instrument through the same numerical substrate; that shared description does not give them the same capabilities.

RESET restores the household at level zero and keeps your comparison. CLEAR removes the held pair. Hold a different pair after changing repertoire, then ask what the new names encourage you to see. At level minus two, the sampled cup disappears entirely. Its labelled place remains empty; a replacement sphere would conceal the result. Even at level zero, gaps in its thin wall expose the coarseness of the mesh. The display samples a finite domain at 64 points per axis. A narrow feature can be absent from the mesh while still present in its formula. Which loss came from the rule you changed, and which was already waiting in the sampling?

We have added another way to make a body, and another way to mistake an available shape for an exhausted possibility. The cup need not remain a cup. But escaping its name will take more than changing the label.


The next room leaves the household repertoire and examines a surface whose repetition extends through three directions without being assembled from separate repeating objects.

---

## ISO TorusGyroid

*ISO_TorusGyroid*

# Repetition without separate pieces


Begin with the torus. Follow the tube around its opening until you return to the part where you started. The empty centre has a boundary you can trace. Move sideways: the visible opening narrows, although the object has not changed.

This reference uses the existing torus field with its distortion weights set to zero. We have temporarily put aside the noise that made the earlier sculpture irregular. The ring lets us keep a relation in view while the next specimen makes repetition harder to separate into individual things. An opening is visible here; whether your body can pass through it is another question, involving orientation, size and collision.


Does a repeating surface have to be a collection of repeating objects?

Choose an opening in the gyroid specimen and follow the surrounding fold into the next region. Change viewpoint wherever a crossing obscures the connection. Look for repetition along another direction, then compare its scale with the first. The pattern is not organised only across a flat face.

Keep one opening as a landmark and compare it with the next recognisable opening along a fold. Look at their orientation as well as their apparent size. Repetition in a volume can carry a relation around a bend, so matching silhouettes are not the only evidence available. If the two features differ, consider whether the difference might come from viewpoint before attributing it to the field's perturbation. A second angle can resolve some of that uncertainty while also revealing another layer of the repeating structure behind the first.

The field begins with three linked trigonometric terms: sine in one direction multiplied by cosine in another, repeated cyclically across the coordinates. Together they create a periodic spatial relation. A threshold selects a surface from that relation, and the extractor turns the sampled boundary into triangles.

Start with FORMULA and SHEET, the desk's initial settings. No noise perturbation is applied. The selected level is still one: this is a sampled trigonometric gyroid level set, not a demonstration of an exact minimal surface. Even “formula” has a chosen boundary and a finite sampling grid.

Press HOLD before changing PERIOD. A copy remains behind the live specimen. PERIOD cycles through coordinate multipliers 0.5, 1, 2 and 4. Choose a fold and compare how much of the repeating relation now fits inside the same domain. The specimen has not simply been scaled as a whole. Its sampling budget remains 64 points per axis while the expression asks those samples to describe more repetition.

The shader's central operation is short enough to carry with you:

```glsl
vec3 gp = p * periodScale;
float gyroid = dot(sin(gp), cos(gp.yzx));
```

The dot product adds sin(x)cos(y), sin(y)cos(z) and sin(z)cos(x). Each term couples two coordinates. The extractor compares the combined value with one; it does not assemble a separate little object for every opening.

INTRUSION restores the complications one step at a time: fine noise erosion, then broader field modulation, then coordinate warp as well. Follow the same region through those changes. Noise can make the surface less regular, but what did it add to the relation you could already describe? What did it make harder to follow? RESET restores FORMULA and SHEET while leaving your held comparison intact.

The shapes gallery assembled descriptions of recognisable parts. Here, repetition arises directly from a field expression. There need be no separately stored object corresponding to each opening you recognise.

That shift changes what it means to edit the form. Adjusting the period changes a repeating relation across the volume. Altering a threshold can change thickness and connections. Distorting coordinates changes where the expression is evaluated. Those operations may all affect an opening, but they are different explanations for its altered shape.

A thin gold line marks one straight test through the live specimen. PROBE changes the radius of an upright capsule from 0.20 to 0.35 to 0.60 metres; its height stays 1.70 metres. The readout reports how far this capsule can travel along the marked twelve-metre segment before the gyroid's collider stops it. The warm marker locates that stop. A larger body asks more of the same visible opening.

This is a deliberately narrow question. The probe does not search for a winding route, test footing, or reproduce every part of the player's controller. A blocked straight path does not prove that no route exists. If the generator omitted collision because the mesh was too costly, the desk says the probe is unavailable; an untested wall must not become evidence of freedom.

We now have three accounts in the same room: a periodic expression, a visible surface and a limited test of bodily clearance. They can disagree. That disagreement gives the next experiment its location. Rather than adding roughness until the object seems alive, we can ask which change makes a passage, a refuge, a barrier, or a relation we do not yet have a name for.


The next room introduces a more direct gesture. Instead of changing a repeating expression, your hand will add local contributions and watch the extracted surface join them together.

---

## ISO Sculpting

*ISO_Sculpting*

# Add a contribution


When two rounded deposits meet, where does their seam go?

Begin with the two deposits inside the framed volume. Their centres are 0.90 metres apart and each radius is 0.30 metres. There is room between them. Press PAIR to bring their centres to 0.65 metres apart, then 0.45. Before each change, predict whether a neck will appear. The deposits keep their radii; the relation between them changes.

HOLD keeps the current surface beside the live volume. Now press ADD. A gold point marks where the desk places its quarter-metre brush contribution. Inspect the join from another angle before adding again. A short, located edit gives you something you can explain; repeated deposits combine before their effects become easy to separate.

In VR, move a controller into the framed volume and hold its trigger briefly. The active ADD or ERASE mode also applies to this hand gesture. The desk offers a repeatable location for comparison; the controller supplies your own. Move outside the volume and the brush no longer deposits. That frame is a limit of this instrument, not the edge of space.

The brush does not push a particular triangle into a new position. Its location is translated into the generator's coordinates and stored as a contribution with a centre and radius. The field combines sphere-like distance descriptions with a smooth blending operation, then extracts the surface again.

The changed join is therefore a result of several decisions: where you deposited, how wide the contribution is, how contributions are blended and how finely the field is sampled. Your gesture participates in the form without directly specifying every point of its boundary.

The gyroid changed a repeating spatial expression. This sculptor adds local descriptions to a collection. Both approaches return to the same task of finding a visible boundary from values, but they distribute authorship differently across the volume.

Press ERASE. It uses the same marked centre and nominal radius as ADD. Look for the new inward-facing boundary, then compare with your held surface. The earlier implementation accidentally turned erasure into another addition by discarding a negative sign. Here that sign survives into the field calculation.

At the lesson's selected level of zero, the distinction can be written as two operations. The brush field is distance from its centre minus its radius:

```glsl
// deposit
field = smooth_union(field, brush, blend);
// cut
field = max(field, -brush);
```

The cut is a new contribution to the recorded history. It does not remove a record of the earlier gesture. ADD after ERASE can fill some of the cut again; ERASE after ADD leaves the cut. Order has become part of the form. Subtraction also has a sharper junction here than the smooth addition. They are different operations, not perfect opposites or an undo command.

PAIR replaces the live history with the next pair of deposits. RESET returns the wide pair and ADD mode; both keep the held surface. The display records how many contributions remain. Two different histories can leave a similar-looking boundary, and the same number of records can describe quite different bodies.

The extractor still samples 64 points per axis. Your hand moves between samples and between recorded strokes. The brush cannot promise to keep every distinction in the gesture. There is also a less visible limit: after five hundred contributions the generator drops the oldest. A cut may remain in the history after the deposit it once cut has been forgotten. This instrument's memory helps make the body, and also decides what it can cease to remember.


The next room scales the same field-making idea towards terrain. Ask what additional relations a volume can describe beyond the single upper height of a conventional landscape.

---

## ISO FlatTerrain

*ISO_FlatTerrain*

# Look beneath the height


How many times can the ground be above the same place?

The turquoise landscape begins with hills. Walk around its edge. A gold line passes vertically through it; the small marks show where that line meets the generated surface. The desk reports one crossing. Choose another COLUMN. The height varies, but each tested column still has one answer.

Press HOLD. The earlier surface remains behind the live specimen. Now press INTERIOR once, then again. Look beneath the upper profile before reading the number. Something can disappear from the top view while becoming visible from the side. A fold may give the same vertical line more than one meeting with the boundary.

The first field begins with a familiar description:

```glsl
float terrainDensity = (surfaceHeight - worldPos.y) / 30.0;
float density = terrainDensity - caveNoise * params.caveStrength;
```

Here `surfaceHeight` depends on horizontal position. With cave strength zero, the second line leaves the first alone. Rise through a column and the density decreases steadily; at level zero it crosses at the assigned height. The hills can be rough or smooth. This description still gives each horizontal position only one height. It cannot independently specify a floor, an air gap and a ceiling there.

INTERIOR keeps that height function, sample domain and threshold unchanged. It changes the weight of a three-dimensional cave field: zero, 0.3, 0.4, then 0.8. Because that contribution varies with height too, the final field need no longer decrease steadily as you rise. A column can leave solid, enter air, and meet solid again.

Try the strongest setting. The marked column is chosen from a fixed set of 25 by 25 test positions, with the most crossings shown first after a rebuild. COLUMN moves through that set. These are intersections with the extracted triangles. They are evidence at particular positions, rather than a complete account of the continuous field or the whole landscape.

The cave term can also lower the upper surface. Holding the height function steady does not hold the final skyline steady: both terms contribute to the boundary. Compare with your held copy. Which difference did you notice first—the changed silhouette, or the space beneath it?

The earlier noise rooms gave us variation we could recognise as terrain. Here we ask what that variation is allowed to describe. Adding more detail to a height function cannot give it a second answer at the same position. Changing the description can. Even then, an enclosed pocket may offer no entrance. A visual opening may be too small for a body. This miniature's column counter does not decide either question for us.


The amber landscape starts from a height field too. Press TERMS and watch it acquire contributions one at a time: overhang, cave, arch, then outcrop. Keep the turquoise specimen as it is while you examine the amber one from the side.

Its description gathers several tendencies:

```glsl
density = baseTerrain - overhangDensity - caveStrength
        - archStrength + outcropStrength;
```

Each contribution has its own spatial mask and noise calculation. The two specimens share an extractor, but they are not a matched pair differing by one switch. The left experiment varies the weight of one interior field. The right experiment adds different terms to a composition. Distinguish those questions before comparing the results.

The names suggest things to look for. Does the setting called “arched” give you an arch you can recognise here? Where does it fail to do so? A word on the desk names an intention; the field, sampling and selected domain make the actual surface. The gap between those accounts is part of the encounter.

RESET returns both reference fields and keeps the held surface. Neither specimen is rescaled or lifted to improve its fit as the values change. Some differences are small. Come closer, change your viewpoint, or keep the question open. More terms need not produce more usable space.


The original CPU terrain and rhizome specimen remain further into the hall, offering other ways to return to this question. Our next stop is Portal Landscape: once an opening appears, where can it take us?

---

## ISO PortalLandscape

*ISO_PortalLandscape*

# An opening from overlapping terms


How can an opening appear without an instruction that draws a doorway?

Find a projecting ledge in the compound landscape, then compare it with a recess or apparent arch. Shift your viewpoint to test whether a dark patch is a hole, a shadowed face or an overlap in projection. Follow the boundary around a candidate opening before deciding what it connects.

Compare a recess with a neighbouring projection and describe which side of each boundary appears to contain material. An apparent arch seen from the front can be a shallow indentation rather than a passage; changing viewpoint tests that reading. Keep one landmark near the candidate opening so that you do not accidentally compare different features. The goal is a modest claim you can support: this boundary projects, this one recedes, or these visible edges appear to enclose a through-opening. The field's named terms can then help explain those observations without replacing them.

The landscape combines several terms in one density field. A base terrain term supplies an initial relation between ground and air. Other terms reduce density in ways intended to produce overhangs, caves and arches. An outcrop term adds material in selected regions. The extractor sees their combined value at each sample.

An opening can result where those contributions cross the threshold together. It need not exist as a separately modelled doorway. Conversely, adding a term associated with arches does not guarantee a useful opening at every location: its effect depends on the other terms already present.

The preceding terrain introduced a cave contribution beneath an upper surface. This specimen extends that composition. Rather than describing the final silhouette as a single mysterious noise, you can ask what each part of the field is allowed to change.

Despite the specimen's portal name, an opening here is geometry. It does not transport you somewhere else, and its appearance alone does not prove an accessible route through the mesh.

A useful extension would display the existing cumulative settings in order: hillside, overhung, quarried, arched and compound. Preserve common coordinates and scale so that a visitor can follow the consequences of each added term. A second experiment could remove one term from the compound version and ask which features depended on it.


Next, the same kind of boundary will be read as enclosure. The question moves from how an opening looks to what the space on its other side permits.

---

## ISO Caves

*ISO_Caves*

# On the enclosing side


The portal landscape is a promise made by a boundary. From the approach it looks like terrain with openings: stone rises, a ring declares a passage, and the field has been asked to join the two. Walk its edge first. Does the opening meet the floor, or does the name “portal” ask you to supply a route the mesh has not made?

The generator carries a count and a burial choice:

```gdscript
num_portals = 7
burial = "straddling"
```

Press PORTALS and watch the rings multiply. Press BURIAL to move the same family of portals from sunken to standing to floating. A change in count is a change in repetition. A change in burial is a change in the relation between a boundary and the floor. Neither word guarantees that a body can cross.


Now turn towards the enclosing cave. The same kind of sampled boundary is no longer a facade in front of you. It is above, beside and behind the eye. Press PLUMB once, then OCTAVES once. Notice which changes you can read from outside and which only become legible when the wall closes around your viewpoint.

```glsl
density = ridged_noise(p) - plumbScale * (p.y + 100.0) / 300.0;
```

`plumb` is a written vertical bias: bedded, overturned, weightless or steep. `octaves` decides how many scales of the ridged sum survive. The field is sampled at a level and extracted into triangles. It is not a cave because the label says so; it becomes an interior when the classified air has enough width, headroom and an entrance.

Press HOLD before changing the field. The earlier view stays behind the live specimen as a memory of the surface. A column can show several crossings, but a counter is not a body. Follow the wall, look back to the entrance, and test the route with your own clearance rather than with the most dramatic chamber in view.


The long cave in the rear aisle keeps a different vocabulary: bulge and resolution. It is a useful remainder, not a third answer to the same control panel. Its folds make the distinction felt: topology is not only whether a surface exists, but which bodies its passages permit.


An isosurface gives inside and outside one calculation. The museum makes the choice visible by changing your side of the boundary. A portal can be a hole that does not connect; an enclosing cave can be a room with no adequate entrance. The field supplies possibilities. A route is authored through width, collision and a body that can arrive.

---

## ISO CaveGeneration

*ISO_CaveGeneration*

# Designing the conditions of a cave


Who designed a corridor if nobody placed its walls one by one?

Compare this cave specimen with the one you have just inspected. Look at the scale of surface changes, the sizes of apparent passages and the relation between larger openings and smaller detail. Choose one difference you can describe without yet assigning it a cause.

Choose one comparison at a time: the width of a visible opening, the frequency of small surface ridges, or the way a cavity meets an outer boundary. Keep those descriptions separate, since they may respond differently to the changed settings. If a feature has no clear counterpart in the earlier specimen, say so rather than forcing a match. A useful comparison can establish that the two results differ without yet identifying a single cause. That restraint makes the proposed controlled experiments more informative when the room later provides them.

Both specimens belong to the same generating family. They combine multiple scales of noise with a vertical bias, then extract a threshold boundary. This scene uses different noise-scale and threshold settings from the preceding cave, as well as a different extent. The resulting difference is therefore not a clean experiment on a single parameter.

The program calculates many local values, but people choose the family of expressions, their ranges, the sampling budget and the conditions under which a result is accepted. Procedural generation shifts some design work towards specifying conditions. It does not make those conditions authorless.

The previous room read a threshold through embodied clearance. This comparison asks how the distribution of possible passages was shaped before any visitor approached them. A field can supply an abundance of cavities while supplying very few useful connections between entrances and destinations.

Do not judge a generator only by its most attractive specimen. One successful-looking opening cannot tell you how often the same settings produce inaccessible pockets or overly narrow routes. Likewise, two visually different caves do not isolate which parameter caused each difference.

A useful extension would hold the field coordinates, threshold and sampling fixed while varying noise scale. A second set could retain the scale and vary only the threshold. Mark a common location in every specimen so visitors can follow a particular change instead of comparing unrelated silhouettes.


Next, the field's sampling position will change over time. Ask whether the resulting movement belongs to persistent objects or to successive reconstructions of a changing description.

---

## ISO AnimatedNoise

*ISO_AnimatedNoise*

# Which block moved?


Are these blocks travelling, or are different blocks appearing?

Choose a small region of the animated display and keep its position in view through several updates. Watch for a block-sized location that changes from empty to occupied, then disappears again. Try following a particular block as if it were a particle. Notice where that reading becomes difficult.

Try looking at the display in two ways over similar intervals. First follow the apparent centre of a visible cluster, as you might follow a moving object. Then hold your attention on one fixed position and record its appearances and disappearances. These readings can produce different descriptions of the same updates. The second makes replacement easier to notice, while the first draws together successive shapes into an imagined traveller. Comparing them gives you an observable reason to question particle-like motion before learning how the representation is rebuilt.

The generator advances an offset through a deterministic spatial field built from several trigonometric terms. At intervals, it samples the field again and rebuilds the displayed geometry. It does not preserve a set of individual blocks and integrate their velocities through the volume.

The current extraction shows whole cells whose corner values lie on both sides of the threshold. Such a cell contains evidence that the boundary passes somewhere through it. Drawing its complete box marks that region without determining the interpolated surface inside it.

That is a coarser representation than the triangle surfaces earlier in the sequence. The blocks should be read as boundary-containing cells, not as a finished marching-cubes mesh with unusually square triangles. The distinction matters when estimating thickness or deciding whether neighbouring features actually connect.

The cave generation room compared different authored fields. This display changes where one field is sampled and lets you see successive representations. Apparent motion can come from replacement, even when no persistent object follows the path your eye invents.

A useful extension would freeze the offset and place this cell view beside the available edge-crossing markers. Those markers locate interpolated boundary positions without yet joining them into triangles. Compare both at the same resolution before asking what a finer sampling would improve.


Next, several local influences will contribute to one boundary. A connecting neck will make another apparently simple event, two bodies joining, available to read as a change in field values.

---

## ISO Metaballs

*ISO_Metaballs*

# A neck between sources


Can two sources make one body before their centres meet? Walk the primary field and look for the narrow neck between rounded regions. The surface does not mark ownership: it is the place where a sum crosses a threshold.

At the desk, press EMPLACE. The same ten sources move from a column to a ring, a pair, a shell and a scatter. Then press KERNEL. The contribution of each source changes from inverse square to Wyvill, Gaussian or cone. Keep the source count fixed while you change the arrangement; keep the arrangement fixed while you change the falloff. That separation is the lesson.

```gdscript
density(p) = sum(kernel(source_i, p))
surface = density(p) > iso_level
```

Press HOLD before making a change. The earlier boundary stays behind the live field, so a neck can be read as a relation rather than a special object. When a bridge pinches off, nothing has been cut from a mesh. A different set of samples simply crosses the same threshold in a different place.


The raymarched specimen nearby makes a related surface by another route: signed distance functions are blended while a ray advances. Its smoothness is not evidence that it shares the same field. Look for what the extracted field can show that a ray step keeps implicit, and what the ray can make continuous without storing triangles.


Nakama keeps the blob vocabulary but changes the implementation and the limits of the body. It is a comparison, not a third control on the desk.


The small rear specimen is the compact reminder: several influences can become one visible mass, but the threshold still decides where the body ends.


A metaball has no outline to defend. It is a negotiation among sources, kernel, sampling grid and threshold. The next hall asks what happens when a boundary is not merely blended, but cut into a passage.

---

## ISO ImplicitModeling

*ISO_ImplicitModeling*

# A surface found by looking


Must a surface exist as a triangle mesh before you can see it?

Move around the rounded, changing form and inspect a smooth join between lobes. Compare its silhouette with the metaball specimen in the preceding room. Both can look like a continuous body assembled from influences, but their images do not establish that the same calculation produced them.

Keep one rounded join in view as you change position and watch the silhouette and shading change together. The image responds to the viewing direction, yet that alone cannot tell you whether a detailed collision surface exists there. Compare this observation with the earlier wireframe specimen, where small polygon boundaries supplied direct evidence of one representation. Here the smooth image leaves that representation question open until the rendering method is explained. Looking carefully can identify the evidence you have and the evidence a particular kind of display does not supply.

Here, each sphere contributes a signed distance description. A smooth minimum combines those distances, rounding the joins between their regions. That differs from adding the inverse-square influences of the previous specimen. Similar-looking blends can arise from different field definitions.

The display also takes a different route from field to image. For each viewing ray, a shader repeatedly queries the distance-like field and advances towards a possible boundary. When it reaches a sufficiently small value, it shades a surface point. The box used to host the shader does not become the detailed boundary of the visible body.

Earlier rooms sampled a lattice, selected local cases and assembled triangles. This encounter queries the field from the viewer's direction instead. It makes the separation between a geometric description and one way of displaying that description especially clear.

The distinction has practical limits. The ray search stops after a bounded number of steps and distance, and its hit test has a finite tolerance. A visible boundary is also not automatically collision geometry. Seeing a smooth enclosure does not prove that another object, or your hand, can meet that enclosure physically.

A useful extension would show the same distance field through this shader and through a marching-cubes mesh at two resolutions. Compare silhouettes and the geometry available for contact, keeping the underlying description fixed.


The next room turns a description into a building-like body. Its graph will specify intended connections, while its extracted shell must make those connections into passages a visitor can actually use.

---

## ISO RhizomeBody

*ISO_RhizomeBody*

# A connection has to fit a body


Can you return by a route different from the one you arrived along?

Identify an entrance to the rhizome body and trace a possible loop through its visible chambers. Where the passages are accessible, compare a return route with your approach. At each junction, look for evidence that two openings lead to distinct routes rather than different views of the same recess.

At a junction, identify the route you arrived along before choosing another opening. That simple reference helps distinguish a new route from a return that merely looks unfamiliar from the opposite direction. If you can complete a loop, compare the sequence of junctions rather than only the length of the walk. If you cannot establish a loop from accessible passages, record the point where the route became uncertain. A planned cycle and a demonstrated return are different kinds of evidence, and the comparison needs to retain that difference.

The plan begins as chamber positions and connections. A connecting tree joins the chamber graph, and additional edges introduce cycles. The generator checks that the graph is connected and includes more than a single tree's routes.

That graph is then given spatial form. Rounded chamber fields and capsule-like passages are blended together. A shell operation gives the boundary wall thickness, entrances are cut through it, and the resulting field is extracted into mesh and collision chunks.

The preceding room separated a visible field from collision geometry. Here the aim includes a body that can enclose a visitor, so the translation from intended connection to usable passage becomes part of the lesson. A line between two chamber centres describes an intention; its width, bends and joins determine what that intention permits in space.

Graph connectivity alone cannot certify access. Blending can merge features unexpectedly, a narrow passage can defeat an otherwise valid connection, and a collider can differ from what a view suggests. The loop you identify in the plan needs to be checked against the route available to a particular body.

A useful extension would display the connection graph beside a record of a visitor's actual route. Keep the graph fixed while changing one passage width. Then ask which mathematical connections remained and which practical choices changed.


This closes the sequence with a task that needs both description and experience. The next room names operations such as union, intersection and difference. You have already met their consequences in joined chambers, wall shells and cut entrances; now those operations can become explicit tools for composing space.

---
