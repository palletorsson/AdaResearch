# Trans_Pit / The Moving Boundary (floor 2) → Void: HANDOFF

Owner: Claude Opus, 2026-10-21. Files: `floor-2.json`, in the `floors[2]` shape, and this
note. Nothing else was written. **No Godot run; nothing here is native-tested.**
Static checks: `floor-2.json` substituted into this trial's `rooms.json` validates against
`rooms.schema.json`. All 13 inventoried floor-2 IDs appear once, including your
`f2_rc_4_12` and `f2_rc_10_12`. Every `#` config is retained. The two slabs carry their
utility token verbatim as `utility_params`, the key `rotation_void.gd` reads.

## Placement

The hall is turned 180°: `x = 7 - col`, `z = 13 - row`, `facing = rotation + 180`.
- **Arrival.** Source row 1, the spawn row, lands on the arrival row (z 12); column 7 lands at x 0.
- **Width.** The 15 cells span x -7.5..7.5, which are exactly the shaft-hole edges. cx 7
  is therefore the only x that keeps the hall off both holes.

| id | at | facing | height | config |
|---|---|---|---|---|
| `f2_pusher_block_3_3` | 4, 10 | 180 | 0.49 | axis z, distance 2, speed 1.5, pause 1.5 |
| `f2_pusher_block_7_3` | 0, 10 | 180 | 0.49 | axis z, distance 2, speed 2, pause 1 |
| `f2_pusher_block_5_5` | 2, 8 | 180 | 0.49 | axis -z, distance 2, speed 1.8, pause 1.2 |
| `f2_free_ball_launcher_1_10` | 6, 3 | 90 | **2** | steady, lob |
| `f2_free_ball_launcher_13_10` | -6, 3 | 270 | **2** | brisk, level |
| `f2_rc_4_12` | 3, 1 | 180 | 0 | `utility_params` 90:y:4:-0.6 |
| `f2_rc_10_12` | -3, 1 | 180 | 0 | `utility_params` 90:y:3:-0.6 |
| `f2_free_ball_launcher_1_14` | 6, -1 | 90 | **2** | brisk, level |
| `f2_free_ball_launcher_13_14` | -6, -1 | 270 | **2** | slow, lob |
| `f2_grower_block_3_21` | 4, -8 | 180 | 0 | min 0.3, max 3.5, speed 0.15, anchor floor, plinth 0 |
| `f2_grower_block_7_21` | 0, -8 | 180 | 0 | same |
| `f2_grower_block_11_21` | -4, -8 | 180 | 0 | same |
| `f2_transformation_airlock_7_29` | **0, -13** | 180 | 0 | plinth 0 |

**Heights** are the museum support (`em_plan` `support_height_m`) plus the token's y:
- **Pushers (0.49).** This is the token's y; the 0.98 m block's bottom sits on the floor.
- **Launchers (2.0).** This is the 2 m ledge they stood on (structure "3"). The ledges are
  not transferred, so the posts float with 2.0 m headroom beneath. This height keeps the
  original throw. At 0 the balls would land at about 4.7 m (level) and 5.8 m (lob) instead
  of 7.0 m and 7.9 m.

**Fit exception: the airlock.** At its rigid position (0, -16) the airlock's centre is on
the slab's south edge and its exit runway is off it. I moved it 3 m north to (0, -13);
x and facing are unchanged.
- **Approach shortened.** The gap from the grower faces (at maximum size) to the
  airlock face is 2.75 m, down from 5.75 m.
- **Runway open to the edge.** Beyond the leaves, 2.5 m of slab runs to the open south
  edge. The source had a 2.5 m runway too, but it ended at a wall with the exit
  teleporter at (7,31).
- **Columns as jambs.** The columns at (±5, -14) stand 0.05 m outside the collars.
- **Side walls not transferred.** The source closed row 29 with walls at cols 0-2 and
  12-14. Here the 9 m bulkhead can be walked around.

## Clearance issue (flagged, not fixed): the throw lines end in the shafts

The rotation zone (source rows 8-16) lands between the shafts. In the source, side walls
at x ±7 stopped the balls. Here, after landing 7-8 m out, the balls roll on:
- **`1_14` (6, -1), throwing west, level.** It rolls along z -1 ± 0.7 into shaft A,
  **across the floor-2 landing pad** (boards x -9.07..-7.53, z -3.0..-0.8,
  `_build_corner_pad`).
  - A visitor who has just landed there can be shoved off the pad (up to 6 m/s,
    `_on_ball_touched`) and fall to floor 3.
  - Stepping off the pad eastward also enters the launcher crossfire.
- **`1_10` (6, 3), throwing west, lob.** It runs along the hole's north edge (z 3). About
  half its balls drop into the hole. The rest roll to the slab edge at x -21 and fall off.
- **`13_10` and `13_14`, throwing east.** They end at or in shaft B's hole, which has no
  pad on floor 2.
- **Retired balls.** `kill_y` -12 is a world height and equals floor 2's level, so a ball
  dropping down a shaft is retired at once. A ball resting on this slab sits 0.34 m above
  `kill_y`; on a floor at -18 every shot would retire on firing.
- **Options (curation, yours).**
  - Low catch kerbs at x ±7 on the throw lines; these must leave the pad's egress open.
  - Or put the floor-2 pad on the outer side of shaft A: `descent.pad_x_sides {"2": -1}`
    gives x -12.09..-10.55, beyond the hole.

## Dependencies and interactions (handler bodies read)

- **Pushers need your `pusher_void.gd`**, through a catalog/scene override of `pusher_block`.
  The original axis is in world space, so with the verbatim `axis:z`, `7_3` would sweep
  (0,10)→(0,12), onto the arrival. With the adapter the lanes are:

  | pusher | lane |
  |---|---|
  | 3_3 | (4,10)→(4,8) |
  | 7_3 | (0,10)→(0,8) |
  | 5_5 | (2,8)→(2,10) |

  - The arrival is 1.5 m from the nearest block face, the same distance as from the
    source spawn row to the pusher row.
  - The bounding row 2 and row 6 solids and the eastern bypass are structure, not
    transferred, so the lanes are open on every side.
- **Slabs (`rotation_void`), using `configure_before_ready` (your catalog entry).**
  `y_offset` -0.6 and the **3 s first pause of `10_12`** must be applied before
  `rotation_cube._ready()`, which copies `pause_duration` into `pause_timer` and adds
  `y_offset` to the position.
  - **Seating.** The origin is at the walking surface (`GridCommon.surface_world_y`) and
    the centre 0.6 m below it. The 2.2 x 2.2 x 1.0 wall cube therefore shows 0.5 m above
    the floor and sweeps a 1.21 m radius.
  - **Timing.** It turns 90° about Y at 45°/s (2 s), pauses 4 s (`4_12`) or 3 s
    (`10_12`), then turns back. Collision follows the mesh in `_process`.
  - **Below the slab.** The lower 1.34 m hangs beneath the 0.36 m slab at (±3, 1) into
    floor 3's airspace, with its bottom 4.3 m above floor 3, where it is visible. In the
    source, the same part hung under the floor cube with nothing below it. I kept it as
    authored.
- **Launchers.**
  - **Rates.** Steady is 2.6 s, brisk 1.7 s and slow 4.0 s, each ±22%, all seed 7 as in
    the source. Lob has rise 0.42 and level 0.18.
  - **Configuration.** Config arrives after `_ready` and rebuilds; the pool is built on
    the first physics frame.
  - **Shove.** The shove reaches both Void bodies. The desktop walker is in
    `player_body` on layer 20, and the `velocity +=` push decays through walker drag. The
    XRTools body is found through its `XROrigin3D` ancestor. There is no damage.
- **Growers.** The cycle is 6.67 s and floor-anchored growers start small. The three
  stay in phase because they are built in the same frame. A deferred build skews them by
  at most a few frames. At 3.5 m the gaps between them are 0.5 m, as in the source
  (4 m spacing). The top stays under the 5.64 m ceiling.
- **Airlock.**
  - **Sensor.** `VisitorClearance` (8.8 x 4.6 x 9 m) masks layers 1 and 20, and
    `is_visitor` accepts any `CharacterBody3D`. The sensor reaches z -8.5, so a visitor
    at the growers' south faces starts the opening.
  - **Floors.** The sensor stays within this floor (local y -0.3..4.3).
- **Not transferred:**
  - the structure ledges, walls and obstacles;
  - the `3t` labels (CHOOSE A LANE / ROTATION / ONE RHYTHM);
  - spawn `s`, `sp`, and the exit `t` at (7,31);
  - lighting and audio.

## Focused checks

`probe.gd` `boundary_checks` already covers most of this. Two adjustments for this
placement:
1. **Shove check (line 130).** `floor_point(cannon, 0, -3.0)` stands under the arc: at
   height 2, a level ball passes 3 m out at about 3.05 m high. Use `floor_point(cannon,
   0, -7.0)`, which is world (1, 3) for `13_10` and clear of the slabs.
2. **Slab pauses per ID.** Check `station("f2_rc_10_12").pause_duration == 3.0` and
   `station("f2_rc_4_12").pause_duration == 4.0`. The current `in [3.0,4.0]` would pass
   if the 3 s slab fell back to 4.

Optional: record that the pad lies on `1_14`'s line, for example
`launchers[2].last_travel().x < 0` with the pad z-range at -3.0..-0.8. This keeps the
clearance issue visible until curation decides.
