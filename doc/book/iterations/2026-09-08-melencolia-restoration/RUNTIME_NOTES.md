# Melencolia museum runtime inspection

Run `python ada_run/melencolia_restore/run_museum_probe.py --render --config=ada_run/melencolia_restore/validation_spec.json` from the repository root.

This boots the current `endless_museum.tscn` and its source in an isolated copy. The copied script changes only literal output paths for the museum's generated reports, cache and ledgers; `probe_runtime/source_manifest.json` records the original source and map hashes and every substitution. The live control values are copied, with only the starting map/chapter and camera mode changed. The actual necklace hand and overrides are copied from their real default paths. No live map, control or source file is written by the helper. The initial loader runs missed `em_showing_cards.json`; it was added to the redirected list after identifying that accumulated derived ledger.

The report contains actual rendered body positions, per-body extents, six physics rays, five CharacterBody3D walk trials and three pictures. The screenshot camera's own guard timer is stopped for capture; no geometry is hidden. Scene script/game input are stopped while the probe directs the body's motion.

The normal control has `grid_pack: 0`, but authored chapters still call `_transplant_from_map`; both utility ramps are therefore built without changing a user flag.

The map's `museum.wall_height: 4` makes numeric stacks 2 and 3 into walkable decks one and two metres above the museum floor. Unlike `p:N` support requests, these decks supply their own height to artifacts without generating individual plinths. The upper ramp's one `p:1` base is deliberate: the map utility branch reads its base height, and `_stamp_wedge` then registers a walkable climb to the adjacent height-3 deck.

The Dürer tableau's sphere rests at its root's floor. Its Polyhedron child is intrinsically 0.45 metres below that plane at scale 1, hence 0.225 metres below it at scale 0.5. Raising the entire tableau to the polyhedron's lowest point would float the sphere. The probe checks the tableau origin and sphere on the platform, and records the polyhedron's inherited penetration separately.

The six ray heights are the actual collider surface at the named coordinates. The stock wedge's mesh has a local shift and rotation; the centre sample is at 0.75 metres above its base, not half the rise. The meaningful access check is the museum's actual capsule climbing each ramp to its upper deck.

The east bypass is walked along x=10, with a turn at z=24.5 to the exit at x=6.5,z=26.5. Generated museum sculptures can stand at other points in the aisle; neither those bodies nor their plinths are removed by this restoration. Earlier straight-line trials found them and recorded their colliders.

These are engine geometry and locomotion checks, not claims about a human teacher, headset comfort or student understanding.
