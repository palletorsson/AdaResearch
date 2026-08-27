# Forces, dressed in props — the surreal applied gallery

> 2026-08-27, Palle: *"reduce the artifact in forces by removing all vector explanations but
> make one surreal applied object explaining every concept instead … think about props …
> with the physics engine as example of thing falling, thing we can move, obstacles are good,
> fountains, falling boxes, object hanging in mid air, like exploration of object paused,
> the calder mobile but in 3d and more beautiful, all ball examples make them with props
> instead … Try to remove the abstract but keep the force under breath … Think about Gary's
> mode in 2040 … dress all vector examples in real props … Make this a gallery with all
> principles that we then can put into the museum."*

The read: **the prop is the diagram.** No arrow-boards, no NOC example ports, no gauges.
Each concept gets ONE object that could stand in an art museum, whose physics is genuinely
the concept — force under breath: felt in the object's behaviour, spoken only on a small
placard, drawn (faintly) only when you grab.

## The census (measured 2026-08-27)

The forces sequence: 14 maps, 158 placements, 136 distinct tokens. Classified:

- **56 retire candidates** — the abstract explanation layer: every `example_*_vr` /
  `exercise_*_vr` NOC port (10), every `vector_*_demo` / `*_xl` / `*_xl_laser` size ladder,
  the boards (`adder_board`, `graphics_monitor`, `VectorBasics`, `basis_vectors_rig`,
  `coordinate_system_switcher`, `2d_in_3d_vectors_vis`), the `*_demo` force gauges
  (`normal_force_demo`, `spring_demo`, `torque_demo`, `harmonic_motion_demo`,
  `work_energy_demo`, `combined_forces_demo`, `orbital_mechanics_demo`). Full list:
  the session census (`forces_census.json`, scratchpad) — regenerate with the snippet in
  the session log.
- **80 keep** — the applied faces that already exist (see catalog), the catalyst/spawn/
  utility layer, and `head_crab` (a force with legs is a body, not a diagram).

**The small/medium/large list**: the operations already ship at three appended sizes —
hand (`vector_add`), XL (`vector_addition_xl`, `_xl_laser`), walk (`vector_addition_walk`),
and the 2026-08-25 fold's ladder runs the whole sequence at TWO scales (VFM bench /
Acts building). The gallery replaces the size ladder with ONE object per concept; scale
variety comes from the objects themselves (a 0.4 m cradle to a 7 m wind field).

**Nothing is deleted yet.** Retiring = editing 14 maps' interactables + the museum re-deals;
that swap happens only after Palle approves the casting below, one map at a time, with
reachability diffed before/after each write (the pathfinder has one error rule).

## The catalog — one object per concept

Two moves, honestly separated: **[ELEVATE]** an applied face that already exists in the
DNA galleries (give it a `cast` axis: same physics, dressed in real props), or **[NEW]**.
Props come from the corpus itself — the museum's own furniture doing impossible things:
`fire_extinguisher` (0.23×0.83 m, 5.5 kg), `crate` (0.76³, 8 kg), `chladni_plate`,
`control_pendulum`, `exit_sign`, `exhibit_vitrine`.

| # | concept (rung) | object | status |
|---|---|---|---|
| 1 | the vector, components (R1) | **force_cube** — grab it, your shove draws itself; `cast` axis: hold a fire extinguisher instead | ELEVATE |
| 2 | magnitude, normalize (R1) | **length_lantern** — lamplight reaches exactly \|v\|; normalize = the same lamp dimmed to radius 1 | ELEVATE |
| 3 | addition, subtraction (R2) | **tug_of_war** — the load a museum bench, ropes to unseen pullers; the third rope closes the sum to zero: stillness as arithmetic | ELEVATE |
| 4 | dot product (R2) | **revolving_door** — the door takes only the component of your push along its swing; a shove across the swing does nothing. v·n, bodily | NEW (later) |
| 5 | cross product, torque (R2) | **prop_mobile** — Calder in drag: museum props hung genuinely balanced, τ = w·d solved at every arm, heavier prop rides the shorter arm | **NEW — BUILT** |
| 6 | projection, reflection (R2) | **projection_shadow** — the prop's shadow as a solid marble inlay on the floor | ELEVATE |
| 7 | velocity, acceleration, derivative (R3) | **paused_fountain** — a fountain of museum objects frozen along their own parabolas; spacing IS speed, the shared bend IS g; press and one throw finishes its sentence | **NEW — BUILT** |
| 8 | F = ma, mass (R4) | **prop_spigot** — Garry's mode 2040: crates rain from a ceiling duct, pile at friction's angle of repose, and you drag the wedges that redirect the fall | **NEW — BUILT** |
| 9 | gravity 9.8 (R4) | **three_gravities** — the same object falling forever in three glass columns: Moon, Earth, Jupiter | NEW (later) |
| 10 | friction (R4) | **brake_skid** — the sled recast as a grand piano, four floor strips, stop distances chalked | ELEVATE |
| 11 | drag (R4) | **drag_corridor** — air / water / honey; chandeliers sinking at three rates | ELEVATE |
| 12 | springs, Hooke (R4) | **spring_tower** — the bob recast as an armchair, T = 2π√(m/k) unchanged | ELEVATE |
| 13 | attraction, n-body (R4) | **parlour_orbits** — a bowling-ball sun on a rug that dips (the well made of fabric), teacups in orbit | NEW (later) |
| 14 | momentum, collision (R4) | **momentum_cradle** — bobs recast unequal: kettlebell → teapot → balloon; the balloon barely carries the line | ELEVATE |
| 15 | field, force-as-place (R5) | **umbrella_field** on the wind ladder — open umbrellas straining down-wind, canopy strain = local magnitude; rung 5 stays the arrow you stand inside | ELEVATE (wind_room) |

Also standing: **pendulum_hall** (period you can watch), **calder_mobile** (the disc
original — the prop_mobile is its louder sibling, not its replacement), **catapult**,
**bounce_well**, **launch_arc**, **force_pad**, **head_crab**.

## The three built today

All three extend `_embodied/embodied_prop.gd` by path, carry `@identity`, a TextScreen
placard (mode PAD), `apply_grid_config`, and are seeded — no unseeded `randf` anywhere,
so a sweep photographs one object, not five.

- `paused_fountain` — arcs of frozen props from a basin mouth; a push_button releases one
  live RigidBody throw at a time (real engine gravity), which lands and fades. No frees
  mid-generation: the live throw is a plain body freed only after it sleeps.
- `prop_mobile` — binary tree solved leaf-first exactly like calder_mobile's lever law,
  masses from the props' registry bodies; slow drift per arm; plaque states total kg.
- `prop_spigot` — pooled RigidBody crates (no queue_free ever — the GPU-teardown scar),
  spawn at the duct, sleep in the pan, recycle by teleport; two heavy wedge obstacles you
  can shove/carry redirect the rain.

Registered in `commons/artifacts/registry/vectors_demos.json` (surgical append, tab+CRLF
preserved). No `dna.axes` declared yet — axes get DERIVED from the code with
`apply_dna_block.py` after Palle approves the casting (the science_screen rule).

## The gallery map, and the museum

Next steps in order:
1. Palle walks the three (headless probe first, then `Forces_PropGallery` bench map).
2. Casting pass on the ELEVATE rows (each needs its `cast` axis derived, then swept).
3. Build `Forces_PropGallery`: one map, five phases, all 15 on the necklace order.
4. THEN the retire swap, map by map, reachability diffed per write.
5. The ribbon re-packs forces from the changed maps (coordinate with the museum session —
   `map_authored.json` is theirs and uncommitted right now).

## Sieve

- **Thicken?** Yes — force becomes something the body already knows (a fountain, a shove,
  a mobile), and the placard only names what was felt. Relational handles multiply.
- **Foreclosed?** Reading the symbolic layer. The arrows still exist under breath (grab =
  faint vector), but a learner who needs the notation drills loses the boards — the book
  and tutorial pages carry that layer now, not the rooms.
- **Dark spot?** The engine itself. Godot's friction/restitution are approximations wearing
  the costume of law; the placards say "the pile's slope is friction's angle" and the slope
  is Godot's, not Coulomb's. Keep ONE honest object (calder_mobile, arithmetic solved in
  code, not simulated) as the witness that law and engine are different things.
