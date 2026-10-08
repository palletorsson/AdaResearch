# Borrowed Outlines — museum artifact

Lookup: `glyph_profile_gallery`.

Scene: `res://commons/artifacts/glyph_profile_gallery/glyph_profile_gallery.tscn`.

This adapts the six sculptures from `doc/book/studies/glyph-form-atlas/` for the existing Endless Museum. The standalone study is preserved. Its profile mesher, six frame recipes, font, source profiles and sculpture colours are reused without changing the generated forms. Only their museum placement, captions and collision are added.

The artifact creates no player, camera, input handler, environment, light, enclosing wall or floor. The museum supplies those. A plinth under each sculpture is part of the exhibit, not a replacement room floor.

## Placement

- Put the root at the museum's finished floor height: local **y=0**.
- Local mesh AABB: origin **(-11.4, 0, -15.3)**, size **(22.8, 5.64, 30.6) m**. This includes the six plinths and profile boards; labels are excluded from mesh bounds.
- Provide at least **28 m width × 36 m length**, with **7 m clear height** or an open roof. The assigned **29 × 37 m** room gives 3.1 m at each side and 3.2 m at each end.
- Put entrance and exit on **local x=0**, at opposite Z ends. The uninterrupted central aisle is **5.2 m wide**. Cross-aisles at **z=-5.5 and +5.5** are **2.4 m wide**.
- The six plinths are 8.6 × 8.8 m and 0.24 m high. Stations sit at x=-7/+7 and z=-11/0/+11, facing their captions and source profiles toward the central aisle. Preserve these margins when adding other museum furnishings.

The sculptures use static triangle collision so the holes and disconnected pieces are not closed by convex proxies. Plinths and profile backings use box collision. There are 18 static bodies on collision layer 1 by default. Neither the labels nor the thin displayed profile introduces a separate obstruction beyond its backing board.

## Six comparisons

1. **O + depth:** an upright opening with its original lower stroke. That stroke is a sill; this has not become a level doorway.
2. **O + changing width:** a hollow flared vessel. Both ends remain open.
3. **B + rising turn:** two separate winding channels, without a connecting branch.
4. **C + curved path:** a curved open-sided channel, not an automatically closed hole.
5. **I + closed path:** closing the path creates a hole absent from the starting profile.
6. **Colon + shared path:** two separate bodies remain separate despite sharing one character and one mesh resource.

These are the existing construction's limits. This adaptation performs no new Boolean operation, sill cut or topology change.

## Verification

`doc/book/iterations/2026-10-04-primitives-expanded/verify_glyph_gallery.gd` instantiates this scene in Godot 4.6 and writes `glyph-gallery-verification.json`. All 15 checks passed, including unchanged frame recipes and mesher, six sculptures and source profiles, placement bounds, the clear central/cross aisles, the open O centre and its colliding sill. The sculptures contain 71,132 triangles in total.

This is artifact-level instantiation and physics evidence, with XR disabled for that probe. It does not stand in for the separate Endless Museum run or headset comfort testing. The full-project probe also reports the existing unresolved audio-bus UID; it reports no artifact parse errors.

## Font and origin

The included, unmodified **JetBrains Mono Medium** is copyright 2020 The JetBrains Mono Project Authors and distributed under **SIL Open Font License 1.1**. Its complete license is included as `JetBrainsMono-OFL.txt`. The original study explains the profile construction, inherited type design and topology distinctions in more detail.
