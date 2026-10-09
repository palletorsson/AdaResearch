# Gravity: two encounters, one interaction law

Start with RUN, watch, then use the left bank to change a beginning. PARTS and RULE reveal the model after observation. Stable primary tokens are orbital_mechanics_demo and three_body_problem. Both opt into commons/artifacts/orbital_mechanics_demo/gravity_relations.gd; the original standalone scenes remain available without the lesson metadata.

## Controls

| Control | Effect |
| --- | --- |
| RUN | Pause/resume retained state; a frame exit requires RESET. |
| RESET | Reset both copies and their clocks/trails, retaining selected parameters; wait paused. |
| SPEED, first station | Reset with 0.6, 1, 1.25 or 1.6 times this softened model's circular speed at radius 3 m. |
| REVERSE, first station | Negate current satellite velocity without resetting position or time. |
| BODIES, second station | Toggle two/three equal 4 kg masses; reset. The first pair's initial states remain the same. |
| NUDGE, second station | Reset paired copies with 0, 0.03 or 0.15 m added only to the last body's initial X in copy B. |
| PATH | Hide/show history; recording continues. |
| PARTS | Show acceleration arrows, scaled 0.30 m per m/s² and capped at 2 m; baseline maximum acceleration stays numerical on the board. |
| RULE | Reveal softened law, units, integration frequency and fixed/mutual response. |

## Model and retained state

G=1 m³/(kg s²), epsilon=0.25 m. Pair force is G mi mj r/(r²+epsilon²)^(3/2). The first experiment assigns no acceleration to source zero (12 kg); satellite mass is 1 kg. The second adds equal and opposite pair forces before dividing by each 4 kg receiving mass. This is a changed model of close attraction, not an exact point-gravity solver.

Velocity Verlet advances at 1/240 s. Each step computes all accelerations, half-kicks velocity, drifts positions, recomputes accelerations and finishes the kick. Frame-delta catch-up caps at 0.25 s, so a longer stall does not simulate all elapsed wall time.

The equal pair begins at X=-2/+2 with opposite tangential velocities calculated for a softened circular pair. The third begins at (0,0,2.6), velocity zero. A nudged comparison retains its changed centre of mass: no recentering or velocity adjustment. RMS separation measures corresponding positions at the same model time; it is not a Lyapunov exponent.

Both models calculate in X–Z. Opaque bodies render at Y=1.45; translucent comparison bodies at Y=2.10. This offset is display only. Bodies have no mutual collision or player-force coupling. The visitor can stand within the plan.

Trails sample at 20 Hz, retain 240 positions per body and reuse mesh resources. The entire experiment freezes when any body's absolute X or Z exceeds 5.2 m. Outgoing velocity is preserved. This is an observation cutoff, neither a wall response nor a proof of escape.

## Evidence

The actual-museum desktop probe commons/testing/probe_gravity_relations.gd passes 51 checks: circular motion, reversal, conservation tolerances, third-body contributions, controlled nudges, deterministic replay, frame cutoff, bounded trails, controls and sampled capsule approaches. At four seconds, the selected three-body baseline has momentum residual 0.00001985 kg m/s and energy ratio 0.99992286 relative to its beginning. Tested momentum tolerance is 0.001 kg m/s; the solver uses finite-precision Vector3 state. These bounds describe this checked interval, not all possible configurations. Headset reach, comfort, performance and detailed secondary review remain open.
