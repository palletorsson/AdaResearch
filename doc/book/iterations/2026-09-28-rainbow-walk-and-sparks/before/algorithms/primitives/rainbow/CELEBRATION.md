# Every Body / More Colour

Color_Rainbow opts into `rainbow:0:0:1#stage:celebration#plinth:0`. Other rainbow placements keep the existing scene. The opt-in root creates `rainbow_celebration.gd`, which reuses the original band generator at 0.23 scale with an opaque, unshaded material for clear candy colour.

RE-DIVIDE cycles `six`, `roygbiv`, `continuous`, `two`: 6, 7, 48 and 2 bands. Each primary and reversed secondary arc keeps its existing radius rule; total band thickness remains 5.6 local units. Floor paver and step colours sample the current palette. Route geometry does not change.

CELEBRATE starts a bounded 96-instance MultiMesh burst lasting 3.5 seconds. Pressing it again restarts the same pool. The centre welcome Area3D recognises the museum's `em_walker` alongside player, player_body and vr_player groups. There is no room transition, score requirement, damage or global NextCube signal subscription in this installation.

The optional stepping route rises in 0.18 m increments to 0.9 m; a level centre path remains available. Steps and the control plinth have collision. The arches, mushrooms, pearls, banners, stars and confetti are visual scenery. The arch's opaque material does not imply physical collision.

The original small rainbow / dark sphere / MarioCube / catalyst-vent arrangement is archived under `doc/space/rainbow-celebration-2026-09-10/before/Color_Rainbow/`. Pickup cube and catalyst pedestal remain at the far side of the room. The old global reveal event is not needed for the repeatable celebration.

`probe_rainbow_celebration.gd` checks actual museum loading, button signals, all four partitions, fixed route transforms, bounded/repeatable confetti, physics welcome overlap, and a centre-route sweep using the museum walker's capsule dimensions. Headset interaction remains a separate test.
