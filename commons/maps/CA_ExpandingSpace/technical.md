# Proximity, graded state and the timing of recovery

This primary continues the Life dish's distinction between state and mapping. `decaying_bridge:0:0#study:proximity#plinth:0` opts into a 5 × 16 study, with 0.6 m cell pitch, a separate health frieze and an instrument. The original scene's unconfigured dimensions and sequential update mode remain available. Player tracking and material reuse are repaired in the shared script.

## Inputs and state

`grid` maps Vector2i addresses to health in [0,1]. Cell centres lie at y=-0.1 m; their collision tops align with the ordinary floor. The visitor resolver first follows a real player camera to its physical body, including XRToolsPlayerBody for an XR camera; otherwise it checks em_walker, player_body and player groups. A capture camera is not treated as a visitor. When no body exists, no origin-position substitute causes decay. The XR path is implemented but has not been tested in a headset.

The study can use VISITOR, a nominated PROBE position, NONE, or HAND. The fourth source samples the held PointBody centre; when released it has no proximity input. The point trigger selects HAND and steps once. The point parks on release, and release itself does not step. Probe NEAR is (0,0.05,3.6) in bridge space; FAR is (-3,0.05,3.6). The sphere is drawn above that nominated coordinate so it can be seen. Distance includes y; it is not a pressure sensor or horizontal-only footprint. The witness W=(2,6) is at local (0,-0.1,3.6), so the near probe is 0.15 m from it.

## One update

The radius is 1.35 m. Inside it, health decreases by decay_speed × dt × 5. The configured decay_speed is 0.08 and dt is 0.1, giving 0.04 lost per step. Outside it, recovery adds regrow_speed × dt × 0.1 × N, with regrow_speed=1 and N the number of four axial neighbours above 0.5. Missing boundary neighbours do not wrap. Values clamp to [0,1]. A zero field with no healthy neighbour remains zero.

SYNC reads the whole previous field and writes another. SCAN reads the growing result in place, preserving the original algorithm's scheduling choice. REVERSE changes traversal direction. ORDER and REVERSE restore the current beginning, allowing comparisons from the same values. CHAIN creates a depleted field with (1,6)=0.600, (2,6)=0.495, (3,6)=0, disables external input and holds the clock. After one forward SCAN step the third value is 0.010; after reverse SCAN or either synchronous direction it is zero. The original pre-edit solver exhibited the same scan dependence.

RUN attempts one 0.1-second update per 0.1 seconds of frame time, without catch-up. Slow rendering can therefore stretch real time. STEP performs one update. The 300-step limit represents 30 simulated seconds, not a claim of equilibrium. RESTORE resets the FULL beginning and holds; source and scheduling choices remain selected. CHAIN resets its own beginning. SOURCE and NEAR/FAR change the input without resetting health.

## Three consequences of health

- Recovery participation: a neighbour contributes only above 0.5.
- Support: collision is enabled at health ≥0.2 and disabled below, applied through deferred physics updates.
- Appearance: colour interpolates between the configured depleted and healthy colours. Below 0.2 the study retains a transparent ghost, with alpha 0.18+health. At zero, an address is still visible.

Each cell has one reused material. The eighty frieze panels reference those exact materials; they do not run another simulation or create support colliders. The gold witness stays fixed. Its readout reports current health, support, healthy neighbours, source distance, input, update mode, direction and local clock. A small light reflects the witness's support threshold.

## Architecture and verification

The map is 15 × 28. An added front bay contains the bridge, a 0.6 m collecting basin, two closed convex recovery wedges and an independent museum margin. The original seven artifacts remain, with the other six staged individually in a level rear gallery. The chair is scaled to 0.12, crossway to 0.25 and tree to 0.35. Crossway is lifted 0.8 m as a small relief; it no longer crosses the exit wall. The old automatic arrangement removed crossway_ca to reopen its path; authored placement now retains it. The retained tree's optional host_lighting configuration disables its standalone sun/environment in this placement, preventing it from overexposing the hall. Geometry and growth parameters remain.

Real desktop checks exercise tracking, the rule, thresholds, matched schedules, all eight pointer controls, support/basin rays, a body losing support, a climbed ramp and a margin walk. Evidence is under `doc/space/ca-proximity-review-2026-09-13/`. Headset testing and the retained secondary encounters remain further work. Existing catalyst viewport-texture diagnostics are separate from this primary; the final run must have no runtime script errors.

## 25 September: locating the same cell with the body

W now has a fixed gold frame and address on the frieze at the existing panel for (2,6). The frame has no collision, state or clock. The panel still shares the exact floor-cell material. Four lining faces close the collecting basin below floor height; the basin bottom, both recovery ramps, tile collision, rule and console are unchanged. No global floor policy changes. See `encounter-notes.md` for current native checks and their limits.


## Complete learner reconstruction — 8 October 2026

`tutorial.md` prints `presence.gd` and the unchanged PointBody, maintained under `doc/book/studies/cellular-automata-through-the-hands/CA_ExpandingSpace`. The full 5 × 16 float dictionary keeps the installed primary's pitch, radius, rates, axial bounded neighbourhood and thresholds. A one-fifth-scale view maps the held point back into simulation units. The model has manual steps, a lower receiving tray, corresponding wall panels and a complete collision construction. Unlike the installed VISITOR mode, its input is deliberately the held point centre. It is a tabletop reconstruction, not a miniature walking platform.

The lesson introduces external input first; SYNC/SCAN is a later return to the existing buffer agreement. Independent exercises raise the point above the radius and change CHAIN W from .495 to .49. Two deliberately faulty variants discard height or read newly written answers in SYNC; the tests reject their predicted outcomes.

The installed proximity study adds `proximity_hand.gd` only through its opt-in study mounting. VISITOR, PROBE and NONE remain in the same order; HAND is fourth. The original bridge solver is unchanged in this pass. The rear chair receives optional `host_lighting:1`, like the tree, to disable its standalone sun/environment. Its cellular algorithm is unchanged.

All seven authored works remain. Rear floor/partition cells are levelled, incidental sculpture is reserved out of circulation, and portals move to the entry/exit thresholds with no additional generic gate. The basin and recovery wedges retain their geometry. Only this hall's generated plan row is rederived.

32 exact-printed-code checks and 37 installed-museum checks pass in Godot 4.6. There are 255 samples on four routes for layer-1 capsule clearance (0.56 m wide / 1.7 m high) and level floor. A supplied physical body loses support at W, lands at approximately -0.63 m and climbs the exit wedge to the museum floor. Both source types at the same coordinate produce the same field. Final runs have no SCRIPT ERROR or Parse Error; existing unrelated engine warnings remain.


Earlier diagnostic runs are retained: the learner parity fixture initially omitted the production study-coordinate flag; the first museum pass exposed a duplicate configuration hook added to the chair and a route intersecting the desk foot. The hook is merged into the existing function; the final route goes around the furniture. These are corrected integration/harness defects, not grounds for claiming the first runs passed.

Evidence: `doc/book/iterations/2026-10-08-ca-the-surface-includes-you/index.html`, exact printed code, receipts, logs, before/after overhead/raised/visitor views and review ZIP. No physical headset, Quest performance, independent student, complete secondary-artifact interaction audit or full portal transfer is claimed.
