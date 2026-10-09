# Told, or finding out

[Random Mushrooms](random-mushrooms.html) → **Random Game** → [Noise Types](random-noise-types.html)

[Two primary encounters and their book passages](/necklace/thread?map=Random_Game&role=primary) · [Sequence progress](/research/waves-chance-noise/index.html#Random_Game)

Three stones draw how long they will stand. Further into the hall, an emitter draws where cubes begin their flights. The room now carries both as primary encounters. Their relationship gives the book its question: **which decision is already made, and what lets you act on it?**

![The actual crossing from its near lip](random-game-probe_game_live.png)

## First, a pause with a chosen end

Watch the stones. Then turn to their tablet. A current wait has already been sampled, although the next one has not. The ring announces the final 1.2 seconds before movement; the beacon reports movement. CUE removes the rings while leaving the tablet available.

The review below steps through recorded transitions from the actual engine. The coloured blocks are a state account, not collision geometry or a new game simulation. A wait shown during LEAVES or RETURNS is the preceding drawn pause.

<!-- trace -->

![The crossing's state tablet](random-game-probe_game_tablet_live.png)

REPLAY now cancels old movement, restores standing positions and support, then repeats the first waits. All three stones retain movement beacons. The longer threshold reaches its landing before the player's capsule meets the first stone. A deliberate fall and the west recovery ramp are checked separately from the approach.

## Then, a source that can stop

![The local controls on their plinth](random-game-field-controls.png)

RUN / STOP changes emission. CLEAR removes existing flights. Stopping first and clearing second leaves an empty field. Clearing a running field allows new arrivals to follow.

The timer attempts a launch every half-second, with at most 24 active bodies. It draws initial centres within the marked 8×8 region and initial downward speed between 1.6 and 2.6 m/s. The rectangle marks starts, not containment. Bodies can drift beyond it.

<!-- field -->

The two sets above come from 24 synchronous calls per set to the actual spawner at seed 31415; they exercise initial construction and the cap. A separate real-timer check verifies arrivals through the local RUN button. The positions and velocities repeat exactly. Each projectile's later jitter generator is randomized independently, so the initial repeat is not a claim about matching full trajectories.

![The falling field and its marked initial-position region](random-game-falling-field.png)

## What this pass establishes

**88 desktop checks passed, with zero assertion failures and engine exit 0.** The review uses the actual museum and a project desktop rig for pointer input, walking and falling. That rig is a test lane; the museum's default walker and a tracked headset are separate interfaces.

The first pass found a blocked threshold, a frame of stale crown light, missed field button rays and early configuration of an unbound Timer. Those failures are retained, along with the later control-position investigation. The final source and run fingerprints are recorded. Existing engine startup diagnostics remain listed in the handover.

Nine artifacts are named in the map; the live museum omits `monte_carlo` because it has no living scene in this lane. Its extra mode implementations are also unfinished. It stays a recorded secondary candidate. The six creatures remain; their ability to interfere with the two experiments still needs a controlled activation/separation pass. No combat balance, headset comfort or Quest performance result is claimed.

<!-- book -->

[Download the chapter](random-game-final.md) · [Technical account](random-game-technical.md) · [Critical account](random-game-critical.md) · [Captured evidence](random-game-encounters.json) · [Run receipt](random-game-run.json)
