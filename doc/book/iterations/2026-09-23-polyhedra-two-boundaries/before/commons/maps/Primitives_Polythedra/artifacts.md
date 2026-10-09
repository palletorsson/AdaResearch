# Primitives_Polythedra — current inventory

16 September 2026. All 34 placements remain. Five artifact types carry the book's first passage; repeated instances keep their configurations. Role order is the authored route, while the grid coordinates below record actual placement. Coordinates are (column, row).

| Artifact | Role | Positions | Scene |
| --- | --- | --- | --- |
| `grab_trihedron` | primary | (9, 5) | [source](../../../commons/primitives/trihedron/grab_trihedron.tscn) |
| `grab_tetrahedron` | primary | (6, 7) | [source](../../../commons/primitives/tetrahedron/grab_tetrahedron.tscn) |
| `prism_block` | primary | (5, 1), (2, 5), (3, 5) | [source](../../../commons/primitives/prismes/prism_block.tscn) |
| `concrete_barrier` | primary | (5, 10), (6, 10), (7, 10), (4, 11), (8, 11), (4, 12), (8, 12), (4, 13), (8, 13), (5, 14), (6, 14), (7, 14) | [source](../../../commons/artifacts/concrete_barrier/concrete_barrier.tscn) |
| `street_sign` | primary | (3, 9), (6, 9), (2, 11), (3, 15), (7, 15) | [source](../../../commons/artifacts/street_sign/street_sign.tscn) |
| `path_watchdog` | secondary | (4, 1) | [source](../../../commons/hazards/path_watchdog/path_watchdog.tscn) |
| `path_game_controller` | secondary | (6, 2) | [source](../../../commons/hazards/path_game/path_game_controller.tscn) |
| `interactive_point_origin_force` | secondary | (4, 4) | [source](../../../commons/primitives/point/interactive_point_origin_force.tscn) |
| `becoming_catalyst` | secondary | (6, 4) | [source](../../../commons/hazards/becoming_catalyst/becoming_catalyst.tscn) |
| `pyramid_edit` | secondary | (4, 7) | [source](../../../commons/primitives/pyramid/pyramid_edit.tscn) |
| `cube_scene` | secondary | (8, 7) | [source](../../../commons/primitives/cubes/cube_scene.tscn) |
| `diamonds` | secondary | (6, 12) | [source](../../../commons/primitives/combines/diamonds.tscn) |
| `trafficcone` | decoration | (3, 16), (7, 16) | [source](../../../commons/primitives/trafficcone/trafficcone.tscn) |
| `if_not_exist_create` | secondary | (10, 18) | [source](../../../commons/artifacts/if_not_exist_create/if_not_exist_create.tscn) |
| `rock_spawner` | secondary | (4, 20) | [source](../../../commons/primitives/rockfactory/RockSpawner.tscn) |
| `rock_scanner` | secondary | (4, 22) | [source](../../../commons/primitives/rockfactory/RockScanner.tscn) |

## Configuration and purpose

- `prism_block`: the example at (5, 1) is solid; (2, 5) is quartered; (3, 5) is a shell. Their visible grain differs while the original collision surface remains.
- `grab_trihedron`: rotated 90 degrees with a 0.90 m plinth request; `grab_tetrahedron` requests a 0.90 m plinth. These are token parameters, not a measured reach result.
- Twelve `concrete_barrier` sections: 1 m long, 0.85 m high, 0.60 m wide at the base, with blocking enabled. They surround the preserved central opening.
- Five `street_sign` placements: STOP/WAIT at (6, 9); both ways at (3, 9); ahead at (2, 11); left at (3, 15); right at (7, 15). All face toward earlier rows by a 180-degree rotation and request 1.70 m poles.
- `pyramid_edit`, `cube_scene`, `diamonds`, `rock_spawner` and `rock_scanner` are now secondary return visits. Their placements and settings have not changed. See [tutorial.md](tutorial.md#return-visits) for what to try and which claims remain unverified.
- `rock_spawner` requests thirty rocks. `rock_scanner` animates a plane with a collider; its own process path does not activate the cross-section display.
- `if_not_exist_create` requests a future primitive gallery. Its presence does not mean that gallery has been constructed.

Four `wp` utility wedges remain at (1, 3), (1, 12), (2, 12), (3, 12). They are floor infrastructure supporting the prism encounter, not extra artifact cards. Entry is (7, 0), exit (4, 27). The three text utilities and their wording remain unchanged.

The old inventory listed `lab_room`, `snap_tetrahedron_puzzle`, `floating_sphere_field` and `tentacle_placer`; none is a current interactable placement here. The stored role file also retains some dormant historical entries. They are not counted as present objects. All original text is retained in the iteration archive.
