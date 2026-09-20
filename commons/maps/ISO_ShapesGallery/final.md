# The same tool makes a cup

<!-- @mc_shapes_gallery -->

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

<!-- @ -->

The next room leaves the household repertoire and examines a surface whose repetition extends through three directions without being assembled from separate repeating objects.
