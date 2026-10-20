# Opening progression — 12 October 2026

User asked to build and add the beginning of the full catalyst/counterpart progression. Implemented a new isolated F6 museum route, `commons/testing/catalyst_opening_progression.tscn`, retaining the earlier supplied-power route and direct-entry arena.

Playable: same first point → hollow field → empty hands form a sphere → charged wall rod → real recorded line kept on the next plinth → same point at primitive station → hold to reduce rings/segments → trigger a quiet receiver → same Dürer head flies into arena → translation, added rotation, added scale in three explicit rounds → interrupted head remains, physical passage opens.

The test map is 13 × 44 m, four rooms. It compresses selected spine moments; it does not reorder curriculum, replace book text, or install these encounters throughout the main teaching halls. Arrays is the next proposed continuation, not implemented. No autonomous opponent learning, health damage or friendship conversion.

Implementation: `opening_progression.gd` extends `proving_ground.gd`; `progression_point.gd` gates the existing resolution catalyst; `practice_receiver.gd` implements the actual two-argument catalyst receiver protocol. The existing first field accepts an optional local capability owner. The existing rod has a default-enabled charging permission. Shared defaults preserve earlier trials.

State is local. Main capability save and TraceData are unchanged. The persistent two-hand ability is temporarily hidden/suspended and restored on exit. Reset cancels transit, clears permissions/data/shots, restores head, surface and gate. Held tools remain held. Released point returns first to its entry plinth, then to the later plinth once a drawing is kept.

Validation:
- Opening native-render probe: **71/71**, 9 native captures, exit 0.
- Existing supplied-power route: **37/37** headless, exit 0.
- Existing direct-entry arena: **31/31** headless, exit 0.
- Report links, image paths and 15 source hashes verified.
- No script errors in successful runs. Existing engine warnings include Jolt custom solver bias and legacy SpatialMaterial specular remapping.

Run `python -X utf8 tools/test_catalyst_first_abilities.py --progression --render` to repeat. Build the local report with `python -X utf8 doc/book/iterations/2026-10-12-catalyst-opening-progression/build.py`.

Native captures confirm placement/readability; poses and controller actions are supplied by the probe. Human headset reach, grip, timing, aim, performance and enjoyment remain unverified. Test these before distributing encounters into canonical spine maps.

Next design work: decide whether the acquired sphere is useful enough between summoning and drawing; test if keeping the trace gives continuity; judge the silent target and three encounters; extend to Arrays only after that loop feels right. Keep the sphere/ability distinct from a permanently fixed weapon shape.
