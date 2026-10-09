# A boundary made from values

<!-- @voxel_noise_demo -->

Where does this surface come from if nobody drew its outline?

Move around the glass and wireframe specimen. Choose a visible boundary and follow it across several triangular patches. Look for a place where the outline turns sharply, then compare it with a smoother region. The large form is continuous-looking, but its visible surface has been assembled from small pieces.

Choose a short edge between two visible triangles and follow it towards the next patch. Then step back until those small divisions become difficult to distinguish. The overall form remains readable even as its construction recedes from view. Return closer and compare the two readings. Neither distance is the uniquely correct way to see the specimen: one reveals an assembled boundary and the other its larger organisation. What matters is remembering that a smooth-looking silhouette at a distance does not erase the finite pieces from which this display is made.

Before those pieces exist, the generator samples a noise field throughout a volume. Each sample receives a number. A chosen level divides the samples into two classes: values below it and values on the other side. Where neighbouring samples cross that level, the program estimates positions for a boundary.

An isosurface is the set of locations at one selected value of a scalar field. This mesh is a finite approximation to such a set. Its triangles connect estimated crossings; they are not the field itself, and the regions where no triangle appears still have field values.

The porous specimen in the previous room introduced the same distinction between values and visible form. Here, keep it in view while examining the polygon structure. The threshold did not add a decorative skin to a finished cave. It helped determine which boundary would exist in the first place.

The displayed object offers one threshold at one sampling resolution. A small passage may depend on both. Absence from the mesh does not establish absence from the underlying continuous field, particularly where a feature falls between widely separated samples.

A useful extension would place the same field beside two other thresholds, keeping its seed and sampling grid fixed. You could then identify which connections changed without also changing the source of the values.

<!-- @ -->

The next room opens the local construction. Eight corner samples will select a case, and that case will tell the extractor which edges to join.
