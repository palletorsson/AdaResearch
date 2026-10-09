# Trans_Scale: Drink Me

The before folder preserves the map and manuscripts immediately before this redesign. The previous grid gauntlet has become one composed scale_me encounter, with encounter:drink_me opting into the new behavior. Legacy pill instances remain unchanged.

The requested seeded dream variants are built inside a 6 x 6 m room. Taking the bottle scales this room by ten and places the body on the food tower. Thirteen visible porcelain serving plates form a descending route. The small door at local x=2, z=6 grows from 18 x 24 cm to 1.8 x 2.4 m. The museum reserves the expanded footprint; the floor remains 4 cm above its deck.

Source: algorithms/primitives/scaleme/drink_me_room.gd and drink_me_bottle.gd. Map: commons/maps/Trans_Scale/map_data.json. One primary family, scale_me, matches final.md and the book register; the exact dream variants are composed contents, not duplicate map placements.

The shared desktop pointer has an opt-in on_desktop_grab hook. Museum distance culling accepts optional local em_visibility_bounds so a large spatial artifact does not disappear while someone is inside it. Other artifacts keep the existing point-distance behavior.

Verification is in commons/testing/probe_drink_me_room.gd and ada_run/drink_me_checks.json. It exercises the desktop crosshair ray and pickup, both door states, the actual museum body's descent through all thirteen plates, the floor route out, unchanged body/museum scales, and visibility near the exit. Screenshots: ada_run/Trans_Scale_drink_me_before.png, after.png and overview.png. Content inventory tests: 27 passed. Learner/headset verification remains open.
