# Proximity, graded state and the timing of recovery

This primary continues the Life dish's distinction between state and mapping. `decaying_bridge:0:0#study:proximity#plinth:0` opts into a 5 × 16 study, with 0.6 m cell pitch, a separate health frieze and an instrument. The original scene's unconfigured dimensions and sequential update mode remain available. Player tracking and material reuse are repaired in the shared script.

## Inputs and state

`grid` maps Vector2i addresses to health in [0,1]. Cell centres lie at y=-0.1 m; their collision tops align with the ordinary floor. The visitor resolver first follows a real player camera to its physical body, including XRToolsPlayerBody for an XR camera; otherwise it checks em_walker, player_body and player groups. A capture camera is not treated as a visitor. When no body exists, no origin-position substitute causes decay. The XR path is implemented but has not been tested in a headset.

The study can use VISITOR, a nominated PROBE position, or NONE. Probe NEAR is (0,0.05,3.6) in bridge space; FAR is (-3,0.05,3.6). The sphere is drawn above that nominated coordinate so it can be seen. Distance includes y; it is not a pressure sensor or horizontal-only footprint. The witness W=(2,6) is at local (0,-0.1,3.6), so the near probe is 0.15 m from it.

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

The map is 15 × 28. An added front bay contains the bridge, a 0.6 m collecting basin, two closed convex recovery wedges and an independent museum margin. The original seven artifacts remain, with the other six shifted together into the rear gallery. The old automatic arrangement removed crossway_ca to reopen its path; authored placement now retains it. The retained tree's optional host_lighting configuration disables its standalone sun/environment in this placement, preventing it from overexposing the hall. Geometry and growth parameters remain.

Real desktop checks exercise tracking, the rule, thresholds, matched schedules, all eight pointer controls, support/basin rays, a body losing support, a climbed ramp and a margin walk. Evidence is under `doc/space/ca-proximity-review-2026-09-13/`. Headset testing and the retained secondary encounters remain further work. Existing catalyst viewport-texture diagnostics are separate from this primary; the final run must have no runtime script errors.

## 25 September: locating the same cell with the body

W now has a fixed gold frame and address on the frieze at the existing panel for (2,6). The frame has no collision, state or clock. The panel still shares the exact floor-cell material. Four lining faces close the collecting basin below floor height; the basin bottom, both recovery ramps, tile collision, rule and console are unchanged. No global floor policy changes. See `encounter-notes.md` for current native checks and their limits.
