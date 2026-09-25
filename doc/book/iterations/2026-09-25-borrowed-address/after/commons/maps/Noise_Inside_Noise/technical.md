# Noise Inside Noise — coordinate composition before surface mapping

This chapter follows Noise_6_Wall's weighted accumulation and prepares the terrain questions of Noise_Space_10. The original noisesphere directly sampled value noise in its shader and did not implement domain warping. Its unchanged scene and shader remain the default legacy configuration. The new stand:warp option builds warp_study.gd, reusing the authored sphere's mesh resolution as a private outward-facing support and retaining the original sphere node as the direct member of the pair.

## An explicit sampler

The study uses three FastNoiseLite instances. All explicitly set FRACTAL_NONE and have automatic domain warping disabled by the engine default. The base uses TYPE_VALUE, seed 4, frequency 1.2. The two displacement components use TYPE_PERLIN, seeds 19 and 47, frequency .45. These are newly declared fields, not the old dome shader's hash realization or a transfer of the voxel hall's stored samples. The same sampler serves every image, witness, small sphere and enclosing surface in this instrument.

displacement_at(p) returns Vector2(warp_x(p), warp_z(p)). address_at(p, amount) returns p + amount × displacement_at(p). value_at samples the base at that displaced address. Strength is in the input coordinate system; it is not a physical displacement of the display. Distinct seeds select distinct realizations but do not prove probabilistic independence. There is one warp pass, no recursive loop and no automatic time input.

The four strength presets are 0, .35, .8 and 1.4. Arrival uses .8 with RELIEF enabled. At zero, q=p exactly and the direct baseline is recovered. WARP changes strength only, ZERO returns it to zero, SAMPLE changes the selected witness only, and RELIEF changes the output mapping only. Each control is local to this study. No group broadcast retunes another hall.

## The visible record

Each 96 × 96 image samples cell centres in the coordinate square [-4,4]². Image row zero is positive z, so the visible upward direction matches the coordinate witness. The left samples N(p); the right samples N(q(p)). Both use the same purple-to-mint colour mapping, clamp((value+1)/2,0,1). The image can interpolate neighbouring texels during rendering. A numerical witness evaluates the selected address directly rather than reading a displayed pixel back.

The coordinate plot keeps an original cyan grid and a displaced pink grid over the central [-2,2]² region. Nine lines per direction are divided into 32 segments each; both grids and the selected p-to-q link produce 2306 line vertices. This is a sampled drawing of the coordinate map. It does not certify global injectivity or locate every possible fold. The pink marker on the left image points to q; the yellow marker on the right remains at p. Five sample directions on the sphere provide the witnesses.

## Applying the same values to a body

Sphere direction x and z, multiplied by three, provide the 2D input. The y component is omitted, so directions mirrored across the xz plane share an address. In SKIN mode, both meshes have radius .94 m. Colours differ only through their source samples before lighting and interpolation. In RELIEF, each radius becomes .94 + .16 × value metres. Mesh normals are regenerated after rebuilding. The square images retain the same values through a relief toggle.

The sphere retains the authored 128 radial segments and 64 rings. Its finite vertices sample at different positions from the image grid; colour interpolation across triangles is not a pixelwise copy of the flat image. The marker is placed at the selected direction's evaluated radius, slightly outside the surface for visibility. It is a coordinate witness, not a promise that the selected direction is a mesh vertex.

The images and mesh data are rebuilt synchronously when strength or relief changes. SAMPLE updates only the witness. There is no per-frame regeneration in this study, and no new performance claim about GPU parallelism or Quest frame rate. A later continuously animated version would need its own cost and precision checks.

## Place and reach

The optional stage provides a 7.2 × 5.6 m floor with two plinths and a low, tilted cased instrument. The floor surface is .06 m above the hall's base floor. A narrow museum-only apron passes beside the stage and reconnects the original ramp approach. An added east boundary brings the cropped hall to its declared 13 m width. Every pre-existing structure cell and utility is retained; the original exit landing remains. One new ground row wraps around its adjacent wall to reach the museum exit. The small sphere surfaces themselves have no collision. Neither warp nor relief changes the stage floor, plinths or instrument collision; the enclosing shell has separate, now-deformed collision.

The EnclosingSphere node adds a spherical wall and ceiling of radius 5 m, centred locally at (0,1.5,.2). The surface begins at floor y=.06; a cylindrical floor reaches that exact spherical intersection, radius approximately 4.788 m. Two opposite openings centred on the x axis span angular half-width .24 radians and extend from the floor to y=2.5, providing about 2.28 m clear width at floor height. Portal edges are explicit angular boundaries in the generated mesh, and those faces are also absent from its two-sided concave collision, which follows the displaced vertices. The circular floor has matching cylinder collision.

The enclosure contains 37,248 triangle vertices. Each direction's x/z × 3 feeds the same warped CPU sampler as the small sphere. The base mesh stays spherical. UV.x carries the signed sample; UV.y carries a spatial weight. enclosing_relief.gdshader applies VERTEX += normalize(VERTEX - sphere_centre) × UV.x × UV.y × relief_depth. The depth uniform is .8 m in RELIEF and zero in SKIN. This is real GPU vertex displacement from CPU-generated field samples, not an independent GPU noise realization.

The weight fades from zero at the floor seam over .5 m. Around each doorway it fades out towards the jamb and lintel, using angular and height margins of .16 radians and .55 m. Matching CPU positions are supplied to the concave collider after each configuration change. Floor and doorway boundaries remain fixed. The custom render AABB includes the full possible ±.8 m displacement. There is no autonomous animation or shader clock.

Colours retain gain .65 and ArrayMesh's 8-bit UNORM encoding. The shader derives face normals from displaced fragment positions, faces them towards the viewer, and adds emission at .12 times the colour. Both SKIN and RELIEF use this same lighting. See [Godot 4.6 spatial shader reference](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/spatial_shader.html) for vertex and fragment coordinate spaces. The original small-pair comparison and supporting orb remain inside the room.

The selected direction now has an enclosing-surface witness. `select_direction` makes an open yellow band 25 mm inside the sampled support: radius 4.975 m in SKIN, following each ring vertex's displaced radius in RELIEF. Its angular radii are .036 and .045 radians (roughly 36–45 cm across), with 48 quads / 288 triangle vertices, unshaded and two-sided. It has no collision. Its empty centre names the selected direction; it does not substitute an exact colour swatch for the interpolated surface. The same `PROBES[sample_index]` supplies all three spherical witnesses. WARP and RELIEF retain this direction. In SKIN, WARP/ZERO leave the ring mesh unchanged; in RELIEF, its radial drawing follows the new samples. SAMPLE rebuilds only the witness drawing and existing coordinate plot, retaining the field images, sphere meshes and collider.

The original book sequence named this hall, while the active map-authored museum plan skipped it. Its reviewed row is reconnected after Noise_6_Wall. Noise_Space_10 remains the next development target and has not been silently inserted by this pass.

## Limits of the argument

A deterministic map need not be invertible. Composition does not guarantee information preservation, and a 2D coordinate cannot in general be recovered from a single scalar value. Conversely, a small coordinate warp is not automatically noninvertible. The present controls and sampled witness let us inspect a particular mapping without calling every curved line a topological tear or assigning an entropy value to its appearance.

Earlier rendered-run evidence is recorded in doc/space/inside-review-2026-09-13. Current native shader/collision, synthetic desktop pointer, door-ray and sampled walking evidence is in doc/book/iterations/2026-09-25-borrowed-address. Headset reach, comfort, legibility and Quest performance remain unverified. The separate dark orb retains its original sine-driven pulse and clock.
