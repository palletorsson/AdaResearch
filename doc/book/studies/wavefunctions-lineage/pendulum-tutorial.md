# A swing keeps a record

**Learning elements**

- Angular state and a restoring acceleration
- Records with named position and time fields
- Sampling intervals
- Count and age limits
- Drawing time as distance

Watch the pendulum in its frame. Choose one teal mark behind it. The bob turns back; the mark keeps travelling down the hall. The bob has not visited that depth. The drawing gives its past somewhere to go.

## What you bring

Keep the cube from the previous hall and the list from Trace. There, a distance condition decided when to keep another position. Here a time condition does that job. Each entry needs both the position and the time it was observed.

**Build:** let the familiar cube swing beneath a pivot, then keep a bounded record of its positions. The installed exhibit uses a spherical bob; our cube remains a recognisable marker for the same point-mass model.

**Investigate:** change the recording interval while keeping the movement rule. Predict whether you will retain more detail, more duration, or both.

## Work inside the museum

Keep the opening script. Save this next version as `02_pendulum_record.gd` and attach it to your `PointStudy` Node3D in the Pendulum hall. Use hall-local position `(10, 0, 21.8)`, zero rotation and unit scale. Its history extends towards local negative Z. The museum supplies the room, light, camera and player.

The complete script below creates every object it uses. The cube construction returns unchanged at 0.4 metres across. A pivot and a thin rod give it a constraint. Small teal copies mark the recorded positions; their meshes are allocated once, then reused. No named scene children, external classes or scene references are required.

## Complete code — 02_pendulum_record.gd

{CODE}

## From a prescribed cycle to a responding swing

In the opening, elapsed time directly supplied a height. Here the next angle depends on the current angle and angular velocity. The update follows the integration we used in Forces: acceleration changes velocity; velocity changes position. Both steps multiply by `delta` in seconds. Angle is measured in radians and angular velocity in radians per second.

The acceleration `-(gravity / length) * sin(angle)` points back towards the hanging position. Start on the right: acceleration is negative. At the bottom it is zero, but the accumulated velocity carries the cube through. The cube slows on the other side before returning. Change its angular velocity and you change what follows; a clock prescribing its position would overwrite that intervention.

The pivot rotates around Z. Its child cube stays one metre below it in the pivot's coordinates. We therefore need `to_local(cube.global_position)` to record the moving centre in the **study's** coordinates. Recording `cube.position` would repeatedly save the unchanged offset beneath the pivot.

This is a numerical, undamped, fixed-length pendulum model. The cube represents a point mass; its shape, rotational inertia, air resistance and collisions are absent. It is not a Jolt rigid body and cannot be grabbed. Small numerical energy errors remain. Keep the room's existing pendulum as the encounter; the small reconstruction isolates its update and recorder.

## One observation has two fields

`Sample` groups a position with a time. `Array[Sample]` says what kind of entry belongs in `history`. Position is a three-dimensional vector in metres; time is a separate number in seconds. Z remains a spatial coordinate.

Each physics update advances the local clock. When the sampling interval has elapsed, `append` saves the cube's current centre and the current time. Oldest records stay at the beginning of the list, so `pop_front` removes the oldest.

`fmod` keeps the unused fraction of the sampling interval. We save at most one observation per physics update. If an update is late, we keep the position actually observed; we do not invent several earlier positions from that one observation.

With a 60 Hz physics tick, a requested interval of 0.025 seconds falls between ticks. Actual gaps alternate between approximately 0.0167 and 0.0333 seconds. A headset's display rate does not, by itself, set the physics tick rate. The timestamps describe the observations we obtained, not the ideal schedule we requested.

## Two limits on a record

The first `while` loop keeps no more than 120 entries. The second removes entries older than six seconds. Either condition can shorten the history.

At 0.025 seconds per sample, 120 entries cover about three seconds. At 0.2 seconds, the six-second age limit is reached with about thirty entries. The exact oldest-to-newest span depends on the retained timestamps. The count limit gives fine sampling less duration here.

`set_sampling` clears the record and sampling clock while keeping angle, angular velocity and elapsed time. `reset_experiment` also resets those movement variables. The museum's own clock continues in either case.

## Give age a direction

`display_position` starts from a stored position, then displaces its **drawing** along negative Z. Age in seconds times `trail_speed` in metres per second becomes distance in metres. At 0.6 metres per second, a two-second-old mark is drawn 1.2 metres behind its recorded position.

The stored position never changes. Changing the display speed rearranges the same record; it does not make the pendulum swing faster. This distinction carries Trace's original-data rule into another representation.

## Build and compare

Run the original values. Predict where a mark will be drawn two seconds after its timestamp. Check a record in Godot's Remote Inspector: compare its saved position with the corresponding mesh in `marks`.

Place a second study across the hall, at `(2.5, 0, 22.2)`, with the same script and initial state. Set its exported sampling interval to `0.2` before running. After eight seconds, both cubes should still swing together. The coarse record should contain fewer marks and reach further back. Explain both results using the two limits, not the appearance alone.

Now set the second study's `trail_speed` to `0.3`. Its history occupies half as much depth for the same ages. The period, stored positions and sample count do not change. This is a change to the drawing.

For an independent variation, edit the second script to request `0.1` seconds and retain at most twenty samples. Predict which limit will end its history. Then change only the count limit until all six seconds fit. Use the actual timestamps to judge the result.

## Read the installed exhibit

The hall's enlarged `PendulumWave` uses the same update and recording principle with a 2.8-metre pendulum, up to 300 records and ten seconds of history. Its FINE, COARSE and RESET controls make the comparisons available in the existing museum. Our shorter study uses smaller limits so the record fits beside it.

The floor beneath the installation carries a second drawing of its record. It retains horizontal position and age while omitting height. Compare that projection with the suspended marks. The floor drawing and measured-period control belong to the installed exhibit; the printed reconstruction builds the small swing and its suspended record.

The exhibit also has STROBE: it measures a period from successive crossings in the same direction, then samples approximately once per return. Watch the moving bob while its marks almost line up. Much of the motion happened between observations. That measured-period control is an encounter here; it is not concealed inside the printed reconstruction.

## What travels onward

Keep the timestamped list and the distinction between data and its drawing. The next hall, Sine Space, gives a repeating rule a spatial coordinate directly. Here depth described a record's age; there position in space will be an input to the rule.
