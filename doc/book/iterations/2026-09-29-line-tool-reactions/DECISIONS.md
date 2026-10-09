# Point Lines: tools and return

The author requested common destructibility and reactions to the catalyst, laser, axe/gun family, starting with the Point Lines examples. They chose automatic rebuilding after a short delay.

## Decision

Use an attachable component, not a replacement base class. Each artifact keeps its existing Godot inheritance and interaction script. Map configuration chooses participation and scope. Eight seconds is the pilot delay; a player occupying a returning physical boundary postpones its restoration.

34 study placements participate, with separate targets inside the line gallery. Seven tool/service placements keep their native behaviour. The glass crossing, architecture, passages and black-box reset remain available. Colour-only exceptions preserve the walk stripe and street talker. No artifacts were moved or removed; structure and utilities match the captured pre-edit map exactly.

The existing hammer provides melee interaction. A future axe can use the same receiver call. There was no separate axe scene to connect. The catalyst and pink gun tint; the held laser burns through after its existing dwell; three hammer strikes break the study. Catalogue-wide adoption is deliberately not enabled.

The implementation preserves the original scene during a break, including its original pickup and collision setup. Small slivers mark the break. It does not cut or physically fracture the source mesh. Catalyst modes share the tint response here; later responses can use the supplied mode ID.

## Text

The chapter no longer describes the barrier as staying permanently absent. It opens temporarily and returns when clear. Added one short paragraph about striking, colouring and taking up a returning rod. Code and framework detail remain in the component README, outside the main reading.

Before snapshots of `map_data.json` and `final.md` were taken at the start of this pass. Their diffs are exact to this pass. Other source snapshots record the tested state; they are not labelled as before/after comparisons because this shared worktree already contained earlier edits.

## Verification

73 native checks passed. Actual projectiles reach the study: the original base projectile, the pink gun's real `fire()` path and the transformation/primitives mode projectiles. Continuous collision detection fixed the fast gun's miss against the thin line. Checked laser dwell/held gating, repeated hammer calls, automatic eight-second restoration, pickup after rebuilding, barrier notification, occupied-space delay, ordinary-grid configuration, removal cleanup and the old projectile callback. Existing entrance, reset, readout and floor checks also pass.

Measured 115 components / 454 approximate hit proxies in the hall. This establishes functional behaviour in the native desktop render, not VR performance. Laser and hammer dispatch were driven by the native test rather than a person wielding them in a headset. Museum captures were visually inspected. Existing audio-bus UID warning remains; no new script error. No commit made.
