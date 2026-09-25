# An edge is not yet an object

At which point does a difference between pixels become a claim about what is there?

<!-- @computer_vision_vr -->

Find an edge of the cross or disk in the input image. Compare that location with the neighbouring edge image. Follow the small moving window and look at what happens when it crosses a boundary rather than a uniform patch.

The edge image emphasises abrupt changes in intensity. The exhibit applies horizontal and vertical Sobel filters to a small pixel grid, combines their responses into a gradient magnitude, and displays that result. A bright response says that nearby pixel values change sharply; it does not by itself say “circle” or “cross”.

Compare the interior of the disk with its boundary. Both belong to what you recognise as the same object, yet the filter treats them differently because its question is about local change. Then compare a short fragment of the disk’s edge with a fragment of the cross. The image-wide identity that seems obvious to you is not present as a complete object inside either tiny neighbourhood. The window makes that difference of scale inspectable.

The moving window helps you connect a local neighbourhood with a local calculation. The whole boundary is assembled from many such responses. At the outer border, this implementation leaves the result at zero, which is another reminder that an image-processing rule includes a decision about what happens where neighbours are missing.

Now read the object names and confidence percentages. In this exhibit those names and percentages are supplied in advance. They are not predictions learned from the computed edges. The room currently places a real filtering operation beside an illustrated classification claim; the link between the two remains to be built.

That separation gives us a precise question for developing the encounter. What evidence would a recogniser need before it could justify the name, and how would its confidence be checked? A future interaction could alter the input while exposing which stages actually change, allowing an unsupported label to become visible as a broken dependency.

For now, use your own observation: identify one edge fragment that could belong to more than one object. Local contrast can be real while its interpretation remains ambiguous. Adding a confident word does not remove that ambiguity.

<!-- @ -->

The sequence-memory room adds another source of evidence: what happened before the current input arrived.
