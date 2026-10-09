# Control a flight from inside its diagram

**Learning elements**

- Position functions
- Initial velocity
- Acceleration
- Model assumptions

Primary launch_arc uses lesson:launch_chamber at source cell (17,7), yaw 180, floor placement without a plinth. All 17 artifact identities remain; the 16 supporting instruments keep their relative configuration shifted 14 rows behind the new arrival chamber. Footprint 34x38. gate_depth_rows=0 prevents an extra entrance partition from cutting through the flight lanes.

The visitor stands between two control banks, with analytic flight lanes at local Z=-3 and +3. Launches start at X=-5, Y=.3; landing is the same centre height. Local positions use metre scale. No collider, rigid-body force or player-velocity command belongs to the flight markers.

ANGLE-/ANGLE+ choose 15..75 degrees in five-degree steps. SPEED cycles 10→6→8→10 m/s. PAIR adds 90-angle at the same speed. GRAVITY toggles 10/15 m/s². These controls reset the current flight. FIRE restarts playback; SLOW toggles local elapsed-time speed 1/.25, and PATH/PARTS/RULE toggle representations without resetting flight.

Position is origin+v0*t+Vector3.DOWN*.5*gravity*t*t. Each lane clamps its own t at 2*v0.y/gravity. Landing freezes the pre-impact state, without collision resolution. Uniform gravity, equal endpoint heights and absent drag are explicit assumptions. Velocity arrows use 0.2 display m per m/s; acceleration arrows 0.1 display m per m/s². PATH draws 64 equal-time straight segments per trajectory; live markers are evaluated analytically at render time. Dynamic arrows reuse at most eight rigs during playback.

Discovery: launch before showing the prediction; compare complementary angles; observe different landing times; inspect zero vertical velocity at apex with continuing acceleration; vary one parameter at a time. Keep computed diagrams distinct from the other room's force pads and player-launch mechanisms.

Next on the unchanged route: VFM_03_Motion.

## Reading and retained detail

The canonical [chapter](final.md) follows the encounter. Exact control steps, arrow scales, timing, bounded histories and reset rules remain here. The complete [pre-pass chapter](../../../doc/book/iterations/2026-09-24-launch-and-motion/before/commons/maps/VFM_05_Launch/final.md) is retained for comparison. This reading pass does not claim a new runtime or headset test.
