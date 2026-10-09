# The previous ending and the next beginning

Current neighbouring manuscripts, included so the pilot can carry the learning journey forward. These are context, not assigned edits.

## Arriving from: proceduralgeneration / PG_Mirrored_Patterns

Source: commons/maps/PG_Mirrored_Patterns/final.md

# A repeated image, another way through

<!-- @mirror_cellular_texture_for_3d -->

An uneven cellular field lies before you. The opening is an authored arithmetic arrangement, held still so that we can inspect a comparison without chasing a changing picture. Press STENCIL. Much of what you see now comes from copying part of that same held field.

HOLD stores the current array. STENCIL always returns to that held array before applying the next arrangement: quadrant reflection, eight-way reflection, rotation, or no copying. It does not obtain a different random field and ask you to attribute all the differences to symmetry.

For the quadrant arrangement, the operation reads a cell from one quarter and writes its value to corresponding positions elsewhere:

```gdscript
new_grid[y][grid_size - 1 - x] = value
new_grid[grid_size - 1 - y][x] = value
```

There are consequences at the edges of this promise. This study uses an odd-sized grid; its centre row and column do not belong to every copying loop. The rotational operation also converts floating-point positions into integer addresses. A symmetrical intention still passes through a particular implementation.

STEP performs one cellular update and then its selected symmetry operation. In this desk study, eligible births and deaths have probability one, so the comparison isolates the update and copying rules. HOLD can keep that new result as the input for the next comparison. Cycling STENCIL to none restores the held field with copying disabled; it does not erase what you chose to hold.

We have returned to arrays, cellular neighbourhoods and transformation. Their combination makes a surface whose apparent unity can conceal how little independent information was consulted. That economy can be beautiful. It can also make one repeated fragment stand in for a difference we have not learned to construct.

<!-- @ -->

<!-- @rhizomatic_maze_space -->

Now move your attention from the surface to the network beside it. NETWORK changes the connection policy over six fixed starting positions. The opening is a tree. Its unique connections give one connected component and no cycle. The next policy admits more nearby connections; the third severs connections across a central gap and separates the remaining pieces.

Watch the counts before deciding what the silhouette means. The desk reports distinct undirected connections, components and independent cycles. The generator may store an edge in both directions; those duplicate records do not create another physical route. For this finite undirected graph, the cycle count is `edges - nodes + components`.

Changing NETWORK preserves the six initial positions. The severed result subsequently displaces positions as part of making its gap, so the final coordinates are not all held fixed. This is a comparison of construction policies, not a claim that every visible difference came from deleting one edge.

SURFACE alternates the bare connections with the tunnel surfaces constructed around them. The specimen's collision is disabled in both views: it is an observation model, not a secretly solid set of invisible tubes. Its gaps and curved surfaces are available to examine before we develop a full bodily traversal. A thick skin can obscure connections that were obvious in the skeleton.

The original generator can also add secondary growth. This opening study sets those iterations to zero so that we can inspect the connections between the six seeds first. We have made a restriction to gain a foothold, not discovered the network's final possibilities.

The pattern tunnel remains a bodily application in the collection. Its surface can be dressed while its supporting route persists. A reflected image does not by itself connect two rooms; a graph edge does not by itself guarantee that its tunnel has sufficient clearance. Geometry, connection and access can be composed, but they require their own checks.

Across this sequence, we have selected, guided, branched, connected, carved, sampled and copied. Each operation gives us something to build with and something more precise to question. What bodies are possible now? We can answer with a construction, try its limits, and carry the unresolved part into the next hall.

<!-- @ -->


## Continuing to: isosurfaces / ISO_Introduction

Source: commons/maps/ISO_Introduction/final.md

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

