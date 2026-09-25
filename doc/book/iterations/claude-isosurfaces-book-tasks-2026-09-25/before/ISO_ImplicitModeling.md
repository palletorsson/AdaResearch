# A surface found by looking

<!-- @implicit_surface_modeling -->

Must a surface exist as a triangle mesh before you can see it?

Move around the rounded, changing form and inspect a smooth join between lobes. Compare its silhouette with the metaball specimen in the preceding room. Both can look like a continuous body assembled from influences, but their images do not establish that the same calculation produced them.

Keep one rounded join in view as you change position and watch the silhouette and shading change together. The image responds to the viewing direction, yet that alone cannot tell you whether a detailed collision surface exists there. Compare this observation with the earlier wireframe specimen, where small polygon boundaries supplied direct evidence of one representation. Here the smooth image leaves that representation question open until the rendering method is explained. Looking carefully can identify the evidence you have and the evidence a particular kind of display does not supply.

Here, each sphere contributes a signed distance description. A smooth minimum combines those distances, rounding the joins between their regions. That differs from adding the inverse-square influences of the previous specimen. Similar-looking blends can arise from different field definitions.

The display also takes a different route from field to image. For each viewing ray, a shader repeatedly queries the distance-like field and advances towards a possible boundary. When it reaches a sufficiently small value, it shades a surface point. The box used to host the shader does not become the detailed boundary of the visible body.

Earlier rooms sampled a lattice, selected local cases and assembled triangles. This encounter queries the field from the viewer's direction instead. It makes the separation between a geometric description and one way of displaying that description especially clear.

The distinction has practical limits. The ray search stops after a bounded number of steps and distance, and its hit test has a finite tolerance. A visible boundary is also not automatically collision geometry. Seeing a smooth enclosure does not prove that another object, or your hand, can meet that enclosure physically.

A useful extension would show the same distance field through this shader and through a marching-cubes mesh at two resolutions. Compare silhouettes and the geometry available for contact, keeping the underlying description fixed.

<!-- @ -->

The next room turns a description into a building-like body. Its graph will specify intended connections, while its extracted shell must make those connections into passages a visitor can actually use.
