# Field notes — Vectors_Act5_ForceAsPlace

2026-09-03. One full turn of the museum loop on one hall: order, space, code,
text, curation. Findings only; nothing here is a proposal unless it says so.

The room's claim is good and I would not change it:

> Falling isn't a property of the void; it's a property of the field over it —
> and the field is a vector you can turn.

The room does not currently deliver it. Its teaching loop is three moves —
**dial, throw a cube to test, then step in yourself** — and each of the three is
broken by something different, which is why no single pass had found it.

---

## 1. Dial — the machine cannot be aimed across, as shipped

`vector_machine.gd:88` composes the field as
`Vector3(cos(pitch)·sin(yaw), sin(pitch), cos(pitch)·cos(yaw)) · mag`.

**The yaw slider is dead in the shipped state.** `:57-58` park PITCH and YAW at
normalised 0.0 — slider position 0.0 of a 0.0–0.14 track, overwriting the slider
scene's own centred default of 0.07 (`slider_smooth.tscn:69`). Pitch 0.0 maps to
−90°, where `cos(pitch)` is zero, so both horizontal components are multiplied
by nothing. On the machine as a visitor first finds it, dragging yaw across its
entire 14 cm changes the field not at all. Nothing on the console says so.

**The yaw control wraps.** `:86` puts a full 360° on a linear 14 cm fader, so
its two ends are the same answer, and the one direction that crosses this chasm
(−Z) sits at 0.5 — the exact middle of the track, unmarked.

**The arrow's upper clamp is unreachable.** `:106` allows a 1.0 m arrow at
|F| ≥ 19.6, but `force_max` ships at 15.0 (`:20`), so the longest arrow in the
room is 0.765 m. The lower clamp does bite: below |F| 3.92 every setting draws
the same 0.2 m stub.

## 2. Throw a cube to test — the probe cannot fall

`force_cube.gd:57` sets `gravity_scale = 0.0`.

In a room whose entire claim is about falling, **the test mass is weightless
before it is thrown.** Throwing it into the field demonstrates the field, but it
cannot demonstrate the contrast the room is built on, because it would not have
fallen either way.

Two more that compound it. A held cube is invisible to the field —
`force_field_zone.gd:218` skips any `RigidBody3D` whose `freeze` is true, and a
held pickable is frozen. And on desktop the pointer can carry but not throw, so
a desktop visitor cannot perform the room's central action at all.

The registry also promises a trail this artifact does not draw.

## 3. Step in yourself — you do not have to

Rows 9–13 are a chasm; columns 7 and 8 are **floor straight through it**. The
void is real (`GridBiomeComponent.gd:897` — *"ground strip — visual only, no
collision: the void stays the void"*), so the fall is real, but the catwalk
means no visitor ever has to set a field to reach the far side.

It was put there deliberately, in `9f6afb2e9`, for a real reason:

> The map's own crossing is a carry field, and the museum walker is layer 1 in
> group `em_walker`, which every carry area ignores in silence.

Before that commit the hall was severed and burning in the museum: 114 of 243
cells reachable, exit unreachable, all five artifacts stranded. The catwalk was
the second rung of a standing escalation and it was the right call for the
museum. **It is a genuine collision between two truths, not a mistake**, and it
needs a ruling rather than a fix.

One consequence the commit could not have foreseen: raising that cell **lifted
the field out of a standing player's reach.**

## 3b. And a visitor who did everything right would still miss, by 5 cm

Found by the cross-check, not by me, and it is the decisive one.

`GridInteractablesComponent.gd:2164` grounds a body by `correction = -min_y`.
The zone's corner spheres (`force_field_zone.gd:163`) hang 5 cm below its own
origin, so the grid lifts the whole volume by 5 cm: the field runs from y 0.55
to 5.55 over a catwalk deck at y 0.50. Containment is `_point_inside` on the
player's FEET, strict `< 2.5` (`gd:239-242`).

**A player standing on the catwalk is five centimetres below the field.** One on
the ledge is further below it. The crossing this hall is named for cannot be
taken on foot in the shipped map, by anyone, from either side, with the machine
aimed perfectly.

The zone's own named `crossing` preset compounds it. `gd:42` sets it to
`(7, 7, 0)`. Grid columns are X and rows are Z, and the chasm spans rows, so +X
runs **along** the trench. The vocabulary's own word for crossing would sail you
down the length of the gap.

## 4. The museum does not walk the room backwards. It deletes the words

I reported this as a reversal. **It is worse than that, and the cross-check was
right to correct me.** `endless_museum.gd:660` allows six utility codes
(`rc sc tc br jp wp`). `sub` is in neither the allowed nor the refused table, so
`_stamp_utility` prints a refusal and returns null for all four subtitle cells.
The `an` info board goes the same way, and `t` is refused explicitly at `:667`.
`ada_run/em_plan.json` plans[49] carries **seven bodies and no text**.

In the museum this hall says nothing at all. The reversal is a deletion, and
**the wall text is not one voice among several here. It is the only one.**

The reversal is still real for a player in the standalone map, where the
subtitles do fire, and there it arrives like this:

    authored : intro → truth_machine → truth_void → truth_complete
    walked   : truth_complete → truth_void → truth_machine → intro

One thing survives whichever end you come in from, and it is the part to fix
first: `truth_complete` reads *"You crossed on a field you set."* Anyone who
took the catwalk did not. The subtitle ORDER is the smaller problem; the
subtitle CONTENT is false as shipped.

This is **not** the corpus convention: of the 185 live halls, 81 agree with the
museum and only 6 go against it — and three of the six are Vectors_Act4a,
Act4b and Act5. It is a fault in three halls, not a design.

## 5. Two artifacts in this hall answer to the same group name

`vector_machine.gd:111-113` broadcasts by iterating group `"force_field"`. The
hazard artifact `force_field` at r19 c11 joins that same group
(`commons/hazards/force_field/force_field.gd:125`). The machine iterates it on
every update and is saved only by a `has_method("set_field_vector")` duck-type
check at `:112`. Two different artifacts, one group name, one 16×24 hall.

## 6. The existing tutorial teaches physics the code does not do

`tutorial.md` shows `@export var zone: Area3D` and
`b.apply_central_force(field_force * b.mass)`. Neither exists. The machine finds
the zone through a **node group**, not an export, and the zone adds acceleration
straight to velocity — `rb.linear_velocity += f * delta` (`gd:223`) — so it is
mass-independent *by construction* rather than by multiplying force by mass.

The tutorial's conclusion is right and its mechanism is invented. That matters
here more than usual, because the real mechanism is the better story.

`blurb.md` says "a chasm with no floor". There is a floor.

The registry and the artifact's own `@identity` both say the zone is **4 m**. It
is **5 m** — `Vector3.ONE * size` seated at y = size/2, so the volume runs from
the artifact's origin to +5 m and ±2.5 m in x and z.

## 7. invisible_hill is in the room and in none of its prose

`blurb.md` never mentions it; `intent.md`'s key-artifacts list omits it. It is
not a terrain, not a field and not a marker but a **diorama**: a 4.78 m dark
green disc with a brass lip, no collider and no signal, over which about four
glowing pucks glide in from the rim, bend away from an empty centre, and leave.

Its own code comment misstates its headline constant by 1.8×, which makes the
singularity guard beneath it dead code.

---

## FIXED, 2026-09-03, with the probes that prove it

**The 5 cm.** `auto_ground: false` on the registry entry (this artifact grounds
itself: its volume runs from its origin upward) and `_point_inside` made
inclusive at the base with 2 cm for the gap a controller leaves under its feet.
`commons/testing/probe_act5_reach.gd`: grounded, origin 0.55, feet 0.50,
OUTSIDE; self-grounded, origin 0.50, feet 0.50, INSIDE. PROBE OK. Fixes all ten
placements of force_field_zone.

**The yaw fader.** The default is not the fault, so it is unchanged: the machine
still ships as gravity straight down, which is the room's first lesson. What was
broken was that the degeneracy was SILENT. Now the readout says the fader is
idle and at what bearing it is waiting, and a dim ghost arrow on the stage holds
that bearing so you can aim before you lift. The early return in `_update` had
to learn about it too: it watched the FIELD, and at a pole the yaw does not move
the field, so the ghost would have frozen at whatever azimuth was set when the
vector last changed.

**The weightless probe.** `gravity_scale` now comes from a new `falls` export,
default 1.0, so a thrown cube drops. The old zero gravity was standing in for a
way home, and a chasm map has no floor to catch a cube and no reset cube, so the
way home is now said directly: `recover_below_m` (4 m) returns a fallen cube to
where it was placed, at rest. `_home` is captured on the first FRAME, not in
`_ready`, because the grid seats artifacts with call_deferred and a home read in
`_ready` would send a fallen cube to the origin of the world.
`commons/testing/probe_act5_controls.gd` asserts all of it: shipped field
(0, -9.80, 0); yaw mid-travel 180 degrees, the bearing across this chasm; ghost
(0, 0, -1); pitch lifted, field (0, 0, -9.80); gravity 1.00; home 10.00; fell
past the limit and came back to 10.00 frozen; a one-metre drop did not teleport.
PROBE OK.

**free_vector placed** at r21 c2, scale 0.7. Nothing fits at full size: 812 of
1232 candidate placements hit a wall or void. Across the whole chapter only
VFM_08_Arena has clear room at 1.0.

STILL OPEN: the plank, which needs the museum walker to learn about carry
volumes; the four subtitles the museum drops; `truth_complete`, which tells a
visitor they crossed on a field they set; and the zone's `crossing` preset,
(7, 7, 0), which points along the trench.

## What the loop recommends

**A ruling is needed first, and it is not mine to make.** Either the museum
walker learns to be carried — which is a change in `em_walker`, not in this map
— or this hall keeps its catwalk and the text says so. Everything else waits on
that, because the text cannot be honest until it is settled.

**The 5 cm is the first fix and the cheapest.** Until the field can be entered,
nothing else in this hall matters.

**Three one-line changes would restore the teaching loop** without touching the
argument: centre the pitch slider so yaw is live on arrival, mark −Z on the yaw
track, and give the test cube weight until it enters the field.

**One body is missing and it already exists.** `free_vector` — *"one arrow and
its ghost copies, carried to different origins to show a vector has no home… a
vector is a journey with no starting address"* — has **zero placements** in the
entire museum. This room's argument is that a vector attaches to a volume rather
than an object; `free_vector` is that premise stated as a thing you can walk
around, and this hall has 138 spare floor cells. Shot on 2026-09-03 before
recommending it: one cyan arrow at |v| = 2.78, θ = 30°, and three ghosts.
