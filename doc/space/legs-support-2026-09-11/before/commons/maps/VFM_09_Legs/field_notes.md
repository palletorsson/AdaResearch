# VFM_09_Legs — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## The prose describes gaits the code never implements

The triage rated this room GOOD on the strength of its tutorial and intent, and
both are fiction about the walkers. Seven readers and seven skeptics went through
`commons/hazards/octapod_crawler/*.gd` on 2026-09-02 (workflow `legs-room-read`):

- **Two through six run one identical rule.** The planted foot furthest past
  1.5 m from its shoulder steps, one foot in the air at a time, 0.25 s, 1.0 m
  high, landing 0.5 m ahead. No phase offsets, no pairs, no tripods, no support
  polygon, no lean. The `@identity` headers and the registry descriptions
  (diagonal trot, alternating tripods, starfish, "physics engine") are prose
  nobody checked against the code; `six_leg_critter.gd:14` itself says "One leg
  at a time."
- **One leg never steps.** Its foot is a spring-arm cast straight down from a
  shoulder 2.2 m to the body's side, dragged along the floor. No pogo, no
  vertical motion anywhere in the family.
- **Eight is the only grouped gait**: two tetrapods alternate, four feet always
  down. It is `octapod_ik`, not the hunting `octapod_crawler` the intent and
  `artifacts.md` name; there is no hunt to switch off and it never stands still.
- **Nothing can fall.** The body is a `MeshInstance3D`, no physics body, no
  collider, height pinned; the feet are cosmetic and catch up. The visitor
  walks through them; their legs pass through the pillars and each other.
- **The intent's numbers**: the leash is 1.4 m (token), not 1.1; "same scale"
  fails on the eighth (see the clamp).

The text was therefore written **true to the code**: the rule on the wall is the
exam gravity would set, the probe answers it per count, and the visitor is the
one who applies it, because the animals cannot. Posted to the forum as
`260902-jyp5w`: keep the honest text, or re-author the walkers so each count
has its own gait and rewrite. Either way the registry descriptions, the identity
headers and `intent.md` should stop claiming the gaits.

## Two bugs found by reading, one fixed

- **Pace scaled with size.** `leg_walker_base.gd` advanced the body by
  `-basis.z * patrol_speed`, and the body's basis carries `walker_scale`
  (set on the same node), so the scale-4 octapod paced 1.40 m/s against the
  token's 0.35. Fixed: `-basis.z.normalised()` in both branches of `_walk`.
  `commons/testing/probe_walker_pace.gd` measures both formulas on the live
  basis: old 1.40 m in one second at scale 4, new 0.35 at either scale.
  Only this map sets a walker scale, so the fix changes one animal.
- **`walker_scale:8.0` is clamped to 4.0 in silence** (`leg_walker_base.gd:144`,
  `clampf(want, 0.02, 4.0)`). The octapod is authored at a twentieth of its
  siblings (bones 0.12 apart, ride 0.45); at 4.0 its leg is 2.4 m against 5.0
  and its ring 1.2 m against 2.2. Not fixed: at 8.0 the authored ride would be
  3.6 m in a hall with 3 m walls, so raising the clamp does not give "same
  scale" either. A ruling: re-author the octapod at its siblings' scale, or
  accept that the eighth rung is a different build, which is what the text says.

## Measured, not derived

- **The bodies stand 0.26 m above the floor**, not the authored 2.2 m: the
  grid's auto-ground shifted six walkers by -1.94 m and the octapod by -1.40
  (`ada_run/_legshot.log`, `legs_room.txt`, 2026-08-27). Feet at 0.00. What
  the visitor sees (`ada_run/leg_ladder_shots/`): a small box a hand above the
  floor and long arching legs reaching 2.2 m out, the arches taller than a
  person.
- **`probe_legs_tutorial.gd`** (PROBE OK) carries the tutorial's `can_lift`
  with a strict point-in-polygon: one and two planted, false; three down true
  and one lifted false; four with one lifted and the body centred, FALSE (the
  centre sits exactly on the diagonal), true after a 5 cm lean, diagonal pair
  false, one side false; five: one lifted true, 0 of 5 adjacent pairs, 5 of 5
  pairs apart; six: the other tripod true, one side false; eight: alternate
  four true, one half false.
- The probe found its own harness twice: `_settle_floor` reads the physics
  space, which is closed outside a physics tick and aborts `_walk`; and in a
  `SceneTree._init` the root is not live, so `global_position` reads zero.
  Measure `position`.

## Exactness decisions in the text

- "None of them fall" is stated as what the room is, not as a complaint.
- The four-leg "lean" is the probe's 5 cm, and the sentence says nothing here
  leans (true of the code).
- The five-leg claim is the pair count, not "unmirrorable".
- The eighth's "about half" is leg and ring; its authored body height ratio is
  0.82, so the text does not say half in every dimension.
- Burst-and-glide timing (steps 0.25 s apart, four to five seconds of glide,
  turns every 3 s triggering most steps) is derived from the constants, not
  measured in the hall; the text keeps it qualitative.

## Open

- The forum question above.
- Registry `hazards.json` descriptions for all six critters and the
  `geometry_spec.animation: physics` claim are wrong; `octapod_ik`'s registry
  measurement is stale (aabb 0). `artifacts.md` names `octapod_crawler`.
- `intent.md` (1.1 m, the crawler, same scale, the gaits) should be corrected
  once the ruling lands.
- The VFM_09_Legs pearl in `commons/data/book/forces.json` is empty; this text
  should seed it.
