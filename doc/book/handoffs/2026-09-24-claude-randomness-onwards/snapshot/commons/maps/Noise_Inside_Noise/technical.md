# Noise Inside Noise — coordinate composition before surface mapping

This chapter follows Noise_6_Wall's weighted accumulation and prepares the terrain questions of Noise_Space_10. The original noisesphere directly sampled value noise in its shader and did not implement domain warping. Its unchanged scene and shader remain the default legacy configuration. The new stand:warp option builds warp_study.gd, reusing the authored sphere's mesh resolution as a private outward-facing support and retaining the original sphere node as the direct member of the pair.

## An explicit sampler

The study uses three FastNoiseLite instances. All explicitly set FRACTAL_NONE and have automatic domain warping disabled by the engine default. The base uses TYPE_VALUE, seed 4, frequency 1.2. The two displacement components use TYPE_PERLIN, seeds 19 and 47, frequency .45. These are newly declared fields, not the old dome shader's hash realization or a transfer of the voxel hall's stored samples. The same sampler serves every image, witness, small sphere and enclosing surface in this instrument.

displacement_at(p) returns Vector2(warp_x(p), warp_z(p)). address_at(p, amount) returns p + amount × displacement_at(p). value_at samples the base at that displaced address. Strength is in the input coordinate system; it is not a physical displacement of the display. Distinct seeds select distinct realizations but do not prove probabilistic independence. There is one warp pass, no recursive loop and no automatic time input.

The four strength presets are 0, .35, .8 and 1.4. At zero, q=p exactly and the direct baseline is recovered. WARP changes strength only, ZERO returns it to zero, SAMPLE changes the selected witness only, and RELIEF changes the output mapping only. Each control is local to this study. No group broadcast retunes another hall.

## The visible record

Each 96 × 96 image samples cell centres in the coordinate square [-4,4]². Image row zero is positive z, so the visible upward direction matches the coordinate witness. The left samples N(p); the right samples N(q(p)). Both use the same purple-to-mint colour mapping, clamp((value+1)/2,0,1). The image can interpolate neighbouring texels during rendering. A numerical witness evaluates the selected address directly rather than reading a displayed pixel back.

The coordinate plot keeps an original cyan grid and a displaced pink grid over the central [-2,2]² region. Nine lines per direction are divided into 32 segments each; both grids and the selected p-to-q link produce 2306 line vertices. This is a sampled drawing of the coordinate map. It does not certify global injectivity or locate every possible fold. The pink marker on the left image points to q; the yellow marker on the right remains at p. Five sample directions on the sphere provide the witnesses.

## Applying the same values to a body

Sphere direction x and z, multiplied by three, provide the 2D input. The y component is omitted, so directions mirrored across the xz plane share an address. In SKIN mode, both meshes have radius .94 m. Colours differ only through their source samples before lighting and interpolation. In RELIEF, each radius becomes .94 + .16 × value metres. Mesh normals are regenerated after rebuilding. The square images retain the same values through a relief toggle.

The sphere retains the authored 128 radial segments and 64 rings. Its finite vertices sample at different positions from the image grid; colour interpolation across triangles is not a pixelwise copy of the flat image. The marker is placed at the selected direction's evaluated radius, slightly outside the surface for visibility. It is a coordinate witness, not a promise that the selected direction is a mesh vertex.

The images and mesh data are rebuilt synchronously when strength or relief changes. SAMPLE updates only the witness. There is no per-frame regeneration in this study, and no new performance claim about GPU parallelism or Quest frame rate. A later continuously animated version would need its own cost and precision checks.

## Place and reach

The optional stage provides a 7.2 × 5.6 m floor with two plinths and a low, tilted cased instrument. The floor surface is .06 m above the hall's base floor. A narrow museum-only apron passes beside the stage and reconnects the original ramp approach. An added east boundary brings the cropped hall to its declared 13 m width. Every pre-existing structure cell and utility is retained; the original exit landing remains. One new ground row wraps around its adjacent wall to reach the museum exit. The small sphere surfaces themselves have no collision, and neither warp nor relief changes the stage's collision shapes.

The EnclosingSphere node adds a spherical wall and ceiling of radius 5 m, centred locally at (0,1.5,.2). The surface begins at floor y=.06; a cylindrical floor reaches that exact spherical intersection, radius approximately 4.788 m. Two opposite openings centred on the x axis span angular half-width .24 radians and extend from the floor to y=2.5, providing about 2.28 m clear width at floor height. Portal edges are explicit angular boundaries in the generated mesh, and those faces are also absent from its fixed, two-sided concave collision. The circular floor has matching cylinder collision.

The enclosure contains 37,248 triangle vertices. Each direction's x/z × 3 feeds the same warped sampler as the small sphere. Colours are multiplied by .65 and drawn unshaded on both sides, so interior visibility does not depend on outside lighting. ArrayMesh encodes the colour channels as 8-bit UNORM: readback is compared with that encoding rather than the input float. WARP refreshes colours without moving the enclosing vertices; RELIEF leaves both its colours and vertices unchanged. The original small-pair comparison and the dark orb are inside this larger room. There is no new autonomous animation or shader clock.

The original book sequence named this hall, while the active map-authored museum plan skipped it. Its reviewed row is reconnected after Noise_6_Wall. Noise_Space_10 remains the next development target and has not been silently inserted by this pass.

## Limits of the argument

A deterministic map need not be invertible. Composition does not guarantee information preservation, and a 2D coordinate cannot in general be recovered from a single scalar value. Conversely, a small coordinate warp is not automatically noninvertible. The present controls and sampled witness let us inspect a particular mapping without calling every curved line a topological tear or assigning an entropy value to its appearance.

Rendered-run evidence is recorded in doc/space/inside-review-2026-09-13. Headset reach, comfort, legibility and Quest performance remain unverified. The separate dark orb retains its original sine-driven pulse and clock.
