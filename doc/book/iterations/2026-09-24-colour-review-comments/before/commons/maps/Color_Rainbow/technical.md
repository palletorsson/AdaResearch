# Re-dividing one arch

The map places `rainbow:0:0:1#stage:celebration#plinth:0` at (7,13). The registered scene remains `algorithms/primitives/rainbow/rainbow.tscn`. Its script detects the opt-in stage and creates `rainbow_celebration.gd`. Other placements retain the existing rainbow behaviour.

The stage reuses rainbow.gd's band generator at scale 0.23. RE-DIVIDE cycles `six`, `roygbiv`, `continuous`, `two` (6, 7, 48, 2 bands). `_band_thickness()` divides the original 5.6-unit total thickness by the current palette length. Each band uses 64 angular segments. The secondary arc reverses the palette; its root is displaced slightly in depth to prevent coplanar flicker where opaque bands overlap.

The 48-band option samples `Color.from_hsv(t * 0.78, 1.0, 1.0, 1.0)`, with t=i/(count-1). This is colour assignment to mesh vertices, not a spectral simulation. The celebration uses opaque unshaded band materials. There is no collision attached to the arch, despite its opaque appearance.

The same palette recolours fourteen step/paver meshes without changing their transforms. Eight optional steps have collision, rising by 0.18 m to 0.9 m and then descending. The centre route remains level.

A canonical ControlPanel provides RE-DIVIDE and CELEBRATE. A welcome Area3D recognises em_walker, player, player_body and vr_player groups. Its physics overlap calls the same celebration function. Confetti uses one 96-instance MultiMesh, with a 3.5-second lifetime; another activation restarts that pool. There are no new scores, unlocks or global NextCube listeners.

The museum probe exercises the actual button signals, all four generated partitions, fixed width and route geometry, bounded/repeatable confetti, physics overlap with the museum walker, and a level-route sweep using its capsule dimensions. Tracked-hand button use and headset comfort remain untested. See field_notes.md for the run and capture.

## Native comparison, 23 September 2026

The shared book figure shows the four generated partitions from one camera in the actual museum. The generator's 5.6-unit band thickness is local: scale 0.23 makes it approximately 1.288 metres in this hall, while the inner opening spans 6.9 metres. These values were measured from the world-transformed mesh. Changing the band count preserves both dimensions; the fourteen step/paver transforms stay fixed as their colours change.

The focused run passes 40 assertions. Supplied pressed/released pointer events operate the actual RE-DIVIDE and CELEBRATE buttons. The ordinary museum controller walks the level centre path into the welcome volume, beneath the arch and back through the welcome volume. Both passages trigger the existing celebration. The confetti reuses 96 instances and expires after its configured lifetime. Static comparison captures suppress confetti, while a separate native view retains it. No production source or placement changed.

Evidence and native views: `doc/book/iterations/2026-09-23-rainbow-room-for-another/`. The under-arch camera uses the reached walker position plus 1.65 metres. Supplied desktop input and selected camera views do not establish tracked-hand reach, headset comfort, learner experience or performance.
