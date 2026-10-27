# Staging the Void: fixture types, the light circuit, and the list of what worked

*Started 2026-10-22. Palle: "make them real, as they were part of the environment …
boxes, slopes that stage some, interface that hang from the ceiling, place in shaft if
they are big or in the ceiling where there is floor, most of them on the floor, wall
scaffolding, not one hero … upgrade the light system to Dieter Rams style like in Point
One … we need to test, let's start with randomness … and we should keep a list of
successful strategies."*

This file is that list. Section 4 is the ledger; a strategy enters it only after a
headset test, with the floor and the date.

## 1. Fixture types — every artifact gets exactly one

| type | what it is | made from (already in `commons/void/catalog.json`) | for |
|---|---|---|---|
| **FLOOR** | stands on the slab, nothing added | — | the default; most things |
| **BOX** | a low plinth, one or two steps | `platform_block`, `step_box`, `crate`, `pallet` | small works that must reach the viewing band (knee to eye) |
| **SLOPE** | a ramp or wedge the work sits on or against | `wedge_blocker`, `cube_walkway` | things read from an angle: boards, traces, pages |
| **TABLE** | a bench at hand height | `workbench` (1.65 × 1.0 × 0.85) | hand-sized things used with the hands: a crank, a seed sampler, dice |
| **SHAFT** | in the tower's shaft, seen from the landing | the floor's `connects_next_floor` part | the big ones: a ride, a bridge, a terrain |
| **CEILING** | hung from the ceiling bus over walkable floor | `interface_ceiling_l/j` mounts, `ceiling_display_mount.gd` | frames, films, displays, anything flat you look up at |
| **WALL** | on wall scaffolding or an unfinished stud wall | `scaffold_tarp`, `unfinished_wall`, `chainlink_panel` | pages, shelves, marks, walls of numbers |
| **INTERFACE** | a hanging console, lowered to the hand when you stand in front; off-white rectangular buttons; one grammar for every artifact's controls | `interface_ceiling_l`, `interface_ceiling_j` (+ `interface_floor/wall/pillar` where a ceiling mount cannot reach) | any artifact with controls — the controls move OUT of the artifact into the console |
| **RAIL** | a track the work moves along | occasional, not a default | pushable things, only where pushing is the lesson |

Rules: no hero per floor; the fixture must look installed (supply cable from the bus,
a floor shoe, a mark label like `LIGHT CIRCUIT / 01`); an artifact's own furniture is
removed when a fixture replaces it (a plinth under a plinth is the museum's old fault).

## 2. The light circuit (the Rams system from Point One, made general)

What exists: `atmosphere.gd` (evening sun, `c4add7` ambient, fog), the tripod
`work_light` prop, `point_light_switch` (Point One's switch as a mains cabinet,
"LIGHT CIRCUIT / 01", PRESS / ON · OFF, scoped to the floor's lamps), `point_rod_light`,
`carried_point_light` (Model B), `line_touch_light`, `lines_light_tunnel`, `trace_light`,
`triangle_edge_light`, `live_junction`, `hardware_supply` (the ceiling bus every unit
connects to).

The upgrade: a **circuit per floor** —
- one switch cabinet at the floor's arrival (`point_light_switch`, circuit number printed),
- one lamp per staged artifact, chosen by fixture type: **rod light** from the bus over
  TABLE / BOX / WALL, **tripod** beside SHAFT and FLOOR works, **edge light** on SLOPE and
  CEILING frames; each lamp with its supply cable to the bus and its own number
  (`LAMP / 01 · 03`),
- the switch cycles circuit groups (all · work only · path only), so a floor can be read
  in three lightings without any new UI,
- the lamp is a field on the record (`staging.lamp`), so the editor, the live chain and
  the Blender import all see it; a render is the judge.

## 3. First test: the randomness trial, floor 1 (Random_Definition)

Thirteen artifacts, no props, no lights today. Proposed fixtures:

| id | artifact | fixture | lamp | why |
|---|---|---|---|---|
| seed | void_random_seed | TABLE + INTERFACE | rod | a sampler held in the hand; its seed readout on the console |
| touch | random_touch (five rods, marks on the wall behind) | WALL (the paper) + FLOOR (the rods) | rod | the marks are the lesson: wall-mounted, lit |
| crank | prng_crank_machine | TABLE + INTERFACE | rod | a machine with a handle |
| page | random_number_book_page_1955 | WALL | edge | a falling page read standing |
| shelf | randomness_tutorial_shelf | WALL | — | it is a shelf |
| geiger | geiger_counter | BOX + INTERFACE | rod | small, listened to; REPLAY on the console |
| slots-1..3 | slot_machine ×3 | FLOOR, in a row | tripod | machines stand |
| lava | lava_entropy_wall | WALL (or CEILING if it reads from below) | — | self-lit |
| film | film_prng_register | CEILING | edge | a film is looked up at |
| ride | void_random_return | SHAFT | tripod | it travels out and back; the shaft is its range |
| frames | void_random_frames | CEILING | edge | frames hang |

Test protocol: stage it in the editor, see it live on the desktop and the headset, render
it from Blender (`python tools/live_update_blender_test.py` style import, Cycles), walk it
in the headset, then write the verdict per fixture into section 4. One floor, then the
next randomness floor (Random_Entropies), then the other trials.

## 4. Successful strategies (the ledger — append only)

| date | floor | strategy | verdict | evidence |
|---|---|---|---|---|
| 2026-10-22 | Random_Definition | first fixture/lamp/circuit pilot (13 `staging` blocks, builder `staging.gd`, circuit switch, renders before/after) | **reverted the same evening** — Palle: "your last change does not work". Fixtures were placed from the mount origin instead of the work's measured bounds (a console mast stood against the seed cabinet, a 0.45 m cube under a 2.8 m geiger); the bounds fix was built but never judged. Backup of the code and records: this session's scratchpad `staging-revert-backup/`, eye-level shots in `ada_run/staging_shots/` | `public/book-images/live-update/randomness-staging-before.png` / `-after.png` |

Rules for a row: a strategy is one fixture type or one lighting rule applied to one
artifact; "successful" means it survived a headset walk and a render; a dropped strategy
is recorded too, with why.
