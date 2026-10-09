# A boundary made from values

<!-- @voxel_noise_demo -->

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

<!-- @ -->

The next room opens the local construction. Eight corner samples will select a case, and that case will tell the extractor which edges to join.
