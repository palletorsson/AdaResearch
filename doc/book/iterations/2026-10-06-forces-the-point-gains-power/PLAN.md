# Forces — the point gains power

6 October 2026 · Design proposal following the author's sphere / flight / vortex / combat direction. Existing museum code, manuscripts and thirteen-hall order are unchanged. Eight proposed encounters below are teaching units, not eight newly installed maps. Images are existing comic plates and earlier museum captures, not renders of the proposed upgrades.

The point has become a body, a drawing instrument and a catalyst. Here it becomes something that can move another body—including yours. Keep its familiar shape and finish. Introduce one ability at a time. A second sphere is another instance of the same object; it is not another system to learn.

## The route

**Push → launch → fly → release and brake → swirl → shoot → return → combine.**

The eight editable storyboards are in [encounters.json](encounters.json), with one new operation, a learner variation, a test obligation and a reflective opening per encounter. They are also printed in the [illustrated reading](index.html#route).

Begin by pushing the familiar sphere while the visitor stands on firm ground. Then make the visitor a receiver. This deliberately proposes a short Motion encounter before Launch, rather than adopting the reviewer's preferred analytic-launch-first order. The launch comparison remains useful inside the launch room; the author wants the continuing point to lead.

The physics vocabulary stays small: position, velocity, acceleration, force, mass and impulse. Vector subtraction and addition return from earlier sequences when they become useful. Dot products, projection and torque need not all become compulsory prerequisites to taking off. We can preserve their installations as optional studies.

### Flight control — chosen by the author

Aim down/back and hold the triggers to thrust up/forward. Each held sphere contributes thrust opposite its controller's aim. Add the two contributions before updating the player once. Releasing either trigger removes only that sphere's thrust; velocity and gravity continue. Releasing both triggers lets the player coast and fall. Dropping a sphere must also clear its contribution.

Teach one hand first, then the sum of two hands. Keep firing as a distinct action or an explicitly selected mode so the flight trigger does not unexpectedly fire a projectile. The control choice is accepted; the flight implementation and broader proposed map order remain to be developed.

## The enemies I would choose

### 1. A rolling or drifting sphere — first and most useful

Use the point's silhouette and material family. Let it approach through a visible, limited driving force; a shot changes its velocity. Start with a passive version, then switch on its pursuit force. Compare two otherwise identical bodies of different declared masses. During the controlled comparison, disable the pursuit force so it cannot conceal the effect being measured.

The play is immediately readable: a light body is easy to divert, a heavy body is difficult to move, a missed shot continues into the room. Mass is a response parameter, not a synonym for size, health or moral importance. Keep the same geometry in the first comparison. Health, damage and cosmetic cracks can come later; the first successful hit must visibly change motion.

This is the best new enemy for the Forces tutorial. It can reuse the sphere's visual construction, but a tested dynamic enemy receiver is still needed. Do not label the existing kinematic crab a mass demonstration.

### 2. A tethered sphere — the same body, another relation

Give the body an anchor and a restoring force. A shot pushes it away; it returns, overshoots and settles according to damping. The player can interrupt its sweep to cross a passage. Change the anchor to change what counts as its resting place. This earns the spring lesson through a useful encounter.

Its critical edge is precise: who established the place to which this body must return? The spring law models a relationship; it does not establish a natural social order. The installed spring study supplies a reduced law, not a ready-made three-dimensional enemy.

### 3. A sentry — optional arena adversary

Reuse the existing sentry's appearance and targeting work. Give it slow, legible projectiles and a declared firing interval. Deflect a shot, push a movable sentry off its aim, or use cover and a launch pad to pass it. Make projectile deflection a visible additional capability, not an assumed feature of the current code.

The question becomes: what makes you a target—distance, visibility, a group assignment? That continues the museum's concern with classification. Keep these selectors out of the first force lesson. The vector turret currently presents many operations at once; reduce its main display to aim and incoming motion here.

**Do not begin with a zoo.** One sphere enemy, its tethered variant, and at most one sentry are enough. Keep the familiar crab as an optional encounter or a later agent lesson. Its current sensing/feeding logic is interesting, but it would introduce a competing subject.

## What moves where

| Current hall | Proposed job |
| --- | --- |
| Vectors_Act1_WhatAVectorIs | Short returning-point prelude inside Push; retain the displacement study nearby. |
| VFM_03_Motion | Main source for Push: finite force, mass, motion after release. |
| VFM_05_Launch | Launch-pad level; preserve analytic trajectory as a comparison, then meet the actual player controller. |
| VFM_02_Operations | Two hand contributions add in Fly; route/destination study remains optional. |
| Vectors_Act2_VectorArithmetic | Reuse aim direction as needed; projection, classification and turning studies remain side encounters. |
| Vectors_Act4a_KineticForces | Release / fall / brake. One drag example; mower and prescribed circle leave the required tutorial. |
| Vectors_Act3_FieldsAndMotion | Vortex. Preserve assign-versus-accumulate comparison to expose the change in the receiver. |
| VFM_08_Arena | Shoot a dynamic sphere; later combine with sentry. Keep the crab outside the main force construction. |
| Vectors_Act4b_Oscillation | Tethered return. One spring and damping law, carried into the enemy variant. |
| Change_Choreography | Candidate for Waves / timing; no relocation performed. |
| VFM_07_Gravity | Keep constant downward acceleration in Launch; retain mutual attraction as an optional deeper gravity study. |
| VFM_09_Legs | Optional support / gait comparison; no gait implementation required for the flight route. |
| Vectors_Act5_ForceAsPlace | Final course: launch pads, field, landing ledges and familiar targets. |

This proposes a shorter required tutorial, not deletion of everything outside it. Reflective writing may still visit those works. Physical map consolidation should follow a playable pilot, not precede it.

## What the current code actually supplies

Source inspected for this proposal; not newly runtime-tested.

| Source | Present behaviour | Implication |
| --- | --- | --- |
| `commons/artifacts/ignorance_gallery/resolution_catalyst.gd` | Held sphere simplifies; trigger sends a copy of its current form. | Strong visual / interaction ancestor. Preserve identity; do not teach construction again. |
| `commons/primitives/point/interactive_point_origin_force.gd` | Held point attracts nearby RigidBody3D objects with a capped inverse-square force; supports projectile firing. | Useful existing force-point work. This is not two-sphere player flight. |
| `commons/artifacts/force_pad/force_pad.gd` | Writes a launch velocity to the player. | Reuse pad and aim presentation. A velocity assignment is not a force integration. |
| `commons/scenes/mapobjects/jump_pad.gd` | Solves a flight, locks horizontal velocity, then snaps to the target and clears velocity on landing. | Useful guided crossing. It cannot silently stand in for free flight or a physically emergent landing. |
| `commons/artifacts/force_vortex/force_vortex.gd` | Replaces player velocity with inward + tangential + upward terms; ejects at the core. | Reuse spatial idea and visuals; an accumulating force vortex requires a changed receiver. |
| `commons/artifacts/force_field_zone/field_carry_provider.gd` | Exclusive XR movement provider passes incoming velocity through the active zone and calls move_player. | Existing integration seam. Hand thrust, gravity, drag and fields must share one movement owner. |
| `commons/hazards/becoming_catalyst/modes/forces_projectile.gd` | On hit, damps nearby rigid bodies and immediately scales their velocities down. | A mixed braking effect, not a clean impulse demonstration. Keep as a later power or replace locally for the lesson. |
| `commons/hazards/catalyst_foe/catalyst_foe.gd` | Catalyst hits advance an authored personality progression and grant mode-dependent powers. | Existing hit/state infrastructure; conversion is not evidence of momentum transfer. Its README describes an older one-hit conversion. |
| `commons/artifacts/hl_turret_vectors/hl_turret_vectors.gd`, `commons/artifacts/sentry_turret/sentry_turret.gd` | Existing tracking / firing artifacts. | Reuse selectively; deflection and a dynamic receiver remain to be built and tested. |

For a rigid body, use the engine's force/impulse API. For the player, name the explicit locomotion model: CharacterBody3D does not supply the same mass-based integration. If it receives forces in newtons, supply a documented virtual mass and convert the accumulated force to acceleration once. If it receives acceleration directly, label it accordingly. Do not run a second position integrator beside XR Tools. Godot distinguishes continuous force calls from one-off impulses. [RigidBody3D reference](https://docs.godotengine.org/en/4.6/classes/class_rigidbody3d.html)

The compact conceptual rule is: add the current contributions, obtain acceleration, update retained velocity, then let the receiver move and collide. Recompute transient contributions next step. Do not clear velocity when the trigger is released. This is the useful backbone to take from [The Nature of Code, Forces](https://natureofcode.com/forces/). Position and velocity are state, not a complete record of the path or the forces that produced them.

## Keep the two texts distinct

**tutorial.md:** name the inherited point class and exact prior state; print the complete small continuation and every new dependency; declare the museum host and bindings. One new operation per encounter. Show what the learner changes and what observation would prove that change. Supplied XR plumbing must be named, not hidden behind an unexplained scene lookup.

**final.md:** stay with the encounter. The push stops but the body continues. Two hands can support or oppose each other. The room catches you; the same room lets you fall. A body labelled enemy can be displaced, passed, defended against or converted. Let those differences carry reflection; do not turn the chapter into another API lesson.

The queer opening is not that flying or swirling is inherently queer. It is that the world has authored a normal direction, a permitted body, a default control arrangement and a category of enemy. Give the player a way to encounter and alter those conditions. Two hands should be expressive without becoming the only permitted body: offer one-hand and desktop control of the same two contributions. Keep the camera level while the path curves. Offer a ground-level observation route through the flight installation.

Do not automatically call calming, taming or making a friend care. Those may also be demands for compliance. A passage that can be crossed without converting everything makes that question playable. These are proposed critical openings, not conclusions claimed from physics.

## First build and its evidence

Build a small museum pilot spanning **Push → Launch → Fly**, using the existing point appearance and the current XR player. Start with one shared movement provider and one test lane. Use the author's selected control: aim down/back and hold the triggers to thrust up/forward.

1. Prove the sphere response with gravity and damping disabled: a known finite force gives the predicted change of velocity; twice the mass halves that change. Release removes the push, not the motion.
2. Prove a pad applies its launch event once; no accidental repeat per physics tick. Verify which velocity components it adds or replaces. Match the prediction to actual controller gravity.
3. Prove two hand contributions add before one update. Parallel contributions reinforce; opposing horizontal contributions cancel without cancelling gravity. Hover requires upward thrust to balance weight and zero vertical velocity initially.
4. Prove disabling a hand, dropping a sphere or leaving the field clears only its own contribution. Collision-adjusted velocity must be used next step. No two movement providers may both move the player.
5. Run the printed learner code and a new learner variation. Deliberately break accumulation, delta handling and trigger release; tests must reject those faults. Separate a pure force-law test from a native Godot receiver test and a physical headset playtest.

Only then expand to braking, vortex and enemies. Headset comfort and learnability need actual play; mathematical assertions alone cannot certify them. The report establishes the plan and source distinctions; no new runtime assertions have been run for it.

## Feedback taken, feedback resisted

Keep the reviewer's emphasis on force accumulation, mass, retained velocity, clear model limits and a cumulative learner body. Keep the spring as a useful return rather than requiring a complete oscillation catalogue. Resist turning the sequence into thirteen separate physics lectures. Do not move a hall simply because another textbook orders it differently. The author’s continuing sphere and the existing Endless Museum determine the encounters; the physics reference helps make their mechanisms exact.


## New illustrated atlas

[Browse the ten new plates and thirteen existing hall illustrations](../2026-10-06-forces-illustrated-atlas/index.html). The eight encounter cards now use the new concept plates. The two beyond pages explore further possibilities. Images are proposals, not native screenshots or proof of installed mechanics.
