# Phi's real body, derived from source — and the contract class it needs

> Research note, 2026-08-10. Companion to `lambda_phi.md` finding F3. No files
> outside `ada_run/lineage_research/` were touched. **Nothing here has been
> rendered** — every number is arithmetic over declared constants in
> `phi_slider.gd` and `lambda_slider.gd`. The method is validated against a
> known-good measurement before being applied to the unknown one.

## The method is checked before it is trusted

`commons/artifacts/dressing_rooms/lambda_slider.json` carries a *captured*
measurement, `production_grade: featured_aaa`:

```
lambda_slider   [0.69, 0.33, 1.31]
```

Rebuilding that from `lambda_slider.gd` alone:

| axis | derivation | result |
|---|---|---|
| width | `w = rail_length + 0.13` = 0.63; side rails at `±(w*0.5 + 0.015)`, thickness `0.030` → 0.315 + 0.015 + 0.015 | **0.69** |
| depth | `CONSOLE_DEPTH = 0.30`; side rails `d + 0.016` = 0.316; ember line and stencil at `face_z + 0.004…0.005` | **~0.33** |
| height | `deck_height = 0.95` + wedge shoulder (`+0.045`, `0.11` tall) + backboard `0.30` | **~1.31** |

Three of three reproduce the captured figure. So the dressing-room footprint
convention is **[width X, depth Z, height Y]**, and source-derivation is a valid
substitute for a capture on this artifact class.

## Phi, same method

`phi_slider.gd` has no cabinet, no column, no deck — a single incidental match
across every `HangarKit` / `Cabinet` / `console` / `deck_height` / `floor` term
in the file. Counting `MeshInstance3D` content only, as the capture AABB does:

| part | extent |
|---|---|
| rail `BoxMesh(0.5, 0.02, 0.05)` at `x = 0.25` | x 0…0.5 · y ±0.01 · z ±0.025 |
| 10 gradient segments `(0.045, 0.022, 0.025)` at `z = 0.015` | z 0.003…0.028 |
| handle sphere `r = 0.03`, travelling `0…rail_length` | x −0.03…0.53 · y ±0.03 |
| calibration plate, `CALIB_PLATE_H = 0.13`, at `z = −rail_depth*0.62` | y −0.005…0.125 · z ≈ −0.031 |

```
phi_slider  DERIVED   [0.56, 0.07, 0.16]      (0.16 with the scale plate; 0.06 without)
phi_slider  DECLARED  [8,    8,    1]
```

Four `Label3D` word-marks sit at `y = −0.05` and a `GPUParticles3D` at
`y = +0.12`; neither is a `MeshInstance3D`, so neither enters the capture AABB —
worth knowing before someone re-measures in Godot and gets a different answer for
a legitimate reason.

**Declared floor area 64 m². Derived floor area 0.039 m². The declaration is
about 1,600× too large** — and about 280× larger than Lambda's captured
footprint, which is the comparison I made earlier and stated loosely as "~100×".
The corrected figure is 281×.

## The finding is not that Phi is small

It is that **Phi has no body that can stand up.**

Lambda is a lectern: a column to the floor, 1.31 m to the top of its backboard,
self-supporting, and it genuinely offers the choice its contract claims —
`allowed_modes: [against_wall, freestanding]` is true of it.

Phi is a bare rail 0.16 m tall in total. It cannot be freestanding, and
"against_wall" does not describe it either, because a wall posture still assumes
the object reaches the floor or hangs from a fixing of its own. Phi does neither.
It has to be mounted **on** something — a plinth top, a bench, a console fascia —
and the museum currently has no way to say so.

That collides with a hard rule already written into the pilot:

> `props.hard_rules` — *interactive controls stay between 0.75 and 1.35 metres*

Phi cannot satisfy that rule on its own at any placement. It has no dimension
that reaches 0.75 m. The rule is correct; the artifact simply cannot meet it
unaided, and a negotiator that checks the rule against the object will either
reject Phi outright or — worse, if it reads `[8, 8, 1]` — grant it an eight-metre
gallery and then find the control at floor height inside it.

## What this asks the contract layer for

A third value in `allowed_modes`, or a separate field:

```
requires_host: { host_class: [plinth, bench, console_fascia],
                 mount_height_m: [0.95, 1.10],
                 host_supplies: [footprint, floor_contact] }
```

The distinction is the one the handover already drew between **support** and
**dressing** — and it needs one more step. Lambda's `show_dressing: false` says
*keep my support, drop the museum's extras*. Phi needs to say something Lambda
never has to: *I have no support of my own; the room must supply one, and my
footprint is the host's footprint, not mine.*

`deck_height = 0.95` in `lambda_slider.gd` is the number to reuse. It is the
height the project already chose for a grabbable rail, it sits inside the
0.75–1.35 band, and using it would make the two dials meet the hand at the same
height in different rooms — which is the physical form of the argument that they
are one axis in two files.

## Caveats

- Derived, not rendered. A capture through `capture_dressing_room.gd` should
  confirm it before anything is written to the dressing room. I did not run one:
  `ada_run/dr_viewer_alive.txt` is live in the working tree and two Godot
  instances at once kills the second on the `user://` lock.
- The handle's x-extent assumes full travel. At the shipped default
  (`phi = 0.3` → slider position 0.325) the static body is `[0.53, 0.07, 0.16]`.
  Travel is the right figure for a clearance envelope, static for a body.
- `[8, 8, 1]` is not unique to Phi. It also stands in the dressing rooms for
  `qfep_sandbox_console`, `edge_of_chaos_orb`, `chaos_particles`, `edge_core` and
  `qfep_reactor`. Any of those could be a lectern or a rail; nobody has looked.
