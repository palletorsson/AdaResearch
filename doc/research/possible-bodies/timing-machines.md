# Together, out of time

[Working route](index.html#Change_Choreography) · [Primary artifacts and book](/necklace/thread?map=Change_Choreography&role=primary) · [Museum Progress](/museum-progress?sequence=forces&room=Change_Choreography)

A new hall, **Change_Choreography**, follows **Vectors_Act4b_Oscillation** in Forces. It returns to Change's questions about rate and accumulation through two primary machines. The introductory Change sequence keeps its two consolidated halls.

The first machine makes a timing relationship visible. The second gives it physical consequences. Phase difference can produce a coherent wave; unequal delivery and collection rates can produce a queue. Neither difference becomes a failure until we name what the system is supposed to accomplish.

## Twenty clocks

Twenty light rods turn in a four-by-five array above a raised dark platform. White tips distinguish their ends. The standing console offers five actions:

| Control | What changes |
|---|---|
| ONE + | Rod ten advances by 45 degrees; its period remains six seconds. |
| WAVE | Adjacent columns differ by one fifth of a turn. All periods remain equal. |
| DRIFT | The back two rows rotate four percent faster; their agreement with the front rows gradually slips. |
| RESET | Shared frequency and phase return; elapsed time continues. |
| RULE | Reveal the angle equation after observing the movement. |

![A phase gradient across twenty rotating light rods](timing_rods_wave.png)

The difference between fixed phase and frequency drift matters. One preserves an offset; the other changes that offset over time. The two drift groups realign every 150 seconds. A preset may jump the rods to new angles; it does not rewind their clock.

![The front and back rows at different phases under drift](timing_rods_drift.png)

## The receiver

The conveyor reuses the project's existing belt geometry and adds a moving collision surface, rigid parcels, a receiving tray and a timed collector. Its sides are clear so the accumulated bodies remain visible.

Start with matched intervals. A box still takes time to cross the machine, so several boxes in transit do not mean it is malfunctioning. BACK UP changes collection from one opportunity every 1.2 seconds to one every three seconds, while deliveries continue. RECOVER makes collection opportunities every 0.6 seconds. Each opportunity can remove at most one parcel that has physically arrived.

![The receiving tray and belt after slower collection](timing_backlog.png)

![The existing backlog after faster collection](timing_recovered.png)

The feed waits when its inlet is occupied or the live-body count reaches 48. The console names these holds. Parcels are not secretly discarded to maintain frame rate. RESET explicitly clears this local experiment. Carrying the boxes and turning the heap into an intentional climbing route are future work.

## The hall

![The two primary machines in their museum hall](timing_hall.png)

The 25 by 27 cell hall has two separate bays, an open centre and consoles facing the approach. It is an experiment after oscillation, before the next gravity hall. The book follows the rods first and the conveyor second.

## Desktop evidence

**24 checks pass.** Observed live parcel counts: matched 6, backlog 17, recovered 5. The exact heap varies with physical contacts. [Read the runtime report](timing-check.json). Scripted pointer controls, the phase relationships, central walking lane, actual rigid-body transport, backlog growth, recovery and local reset are checked in the real museum. Captures use supplied viewpoints, and target-hall artifacts are made visible for inspection. Headset legibility, hand reach, comfort and sustained VR performance remain untested.

## Further experiments

These are proposals, not features already built:

- Twenty boxed floor eyes, with different response delays to the player's movement.
- A platform that repeatedly misses its connection, then becomes usable through a phase adjustment.
- An escalator whose promised destination ends at a wall, with an alternate way to leave the encounter.
- Two helpful machines whose clearing rules deliver their remainder to each other.

The next step is to walk this pair and judge the pacing: can the visitor anticipate a handover, notice the mismatch, and discover another use for the difference?

---

## The book passage

# Together, out of time

Can twenty repetitions make something that none of them does alone?

We have met oscillation: a movement returns. In Change we measured a rate and gathered contributions. Bring those ideas into a room where several processes continue at once. Before asking whether the room is working, choose what you expect it to do.

<!-- @phase_rod_array -->

Twenty light rods turn above their small square bases. Each has a white tip, so you can follow a full turn without confusing one end with the other. Begin by watching one. Then let your attention spread across a row.

Press **ONE +**. Rod ten moves a little ahead. The other nineteen continue their agreement. Press it again. Is this rod late, early, or simply somewhere else in its own cycle? You need another clock before those words can mean anything.

Each press adds forty-five degrees to that rod's phase. It keeps the same six-second period. The difference is an offset, not a growing delay.

Now press **WAVE**. Follow the five columns. A pattern travels across the array while every rod remains attached to its own base. Adjacent columns differ by one fifth of a turn; the four rows repeat that relation. None of these little machines travels across the stage. What you see travelling is a relationship between them.

Only now press **RULE**.

```gdscript
angle = TAU * frequency * time + phase
```

Frequency counts turns per second. `TAU` converts a turn into radians. Time advances the angle; phase places a rotor within its cycle. The array is indexed as four rows of five, carrying forward the addresses we learned to give a grid.

Press **DRIFT**. The back two rows now run four percent faster than the front two. A difference in frequency keeps changing the difference in phase. Watch agreement loosen. The rows need 150 seconds to gain one complete turn on each other and realign. Their clock was already running before you pressed the button, so this is an interval between alignments, not a countdown promised from your press.

These buttons select configurations immediately; a rod may jump to its new angle. After that change, watch the continuing motion. **RESET** restores common phase and frequency while the elapsed clock keeps advancing.

<!-- @ -->

The wave needed difference. Making every rod agree would destroy that particular pattern. Being out of phase becomes a fault only in relation to something we demand: meet here, leave an opening, arrive together. What other movement could your body make alongside this one?

These rods are driven by an angle formula. They do not keep time because a restoring force pulls them back. A spring and a scripted rotor may repeat, but the repetition has different causes. The resemblance is a place to begin investigating.

<!-- @conveyor_backlog -->

Walk to the conveyor. A parcel drops onto the belt, travels toward its end and reaches the collection tray. The receiver flashes when it collects a box. Follow a single parcel before reading the numbers.

The inlet attempts a delivery every 1.2 seconds. The matched receiver can collect one arrived parcel every 1.2 seconds. There will still be boxes on the belt: transport takes time. An occupied machine is not necessarily a congested one.

Press **BACK UP**. The inlet keeps its interval; the receiver now collects at most one box every three seconds. Wait. Which change becomes visible first: a longer stay in the tray, a neighbouring box touching it, or a parcel losing its straight route?

The parcels have rigid bodies. Friction carries them across a moving collision surface. Gravity and contacts determine how they fall, tilt and press against each other. The sculpture at the end is not a mesh that grows because we asked for a larger sculpture. Its shape is made by the deliveries that have not yet left.

Press **RULE** and compare the account with the pile.

```gdscript
here = admitted - collected
```

The receiver only collects a parcel that has physically reached its end of the machine. Its schedule cannot collect a promise. If the inlet is occupied, admission waits. At forty-eight live parcels the feed also waits, and the console says so. That finite capacity belongs to this implementation; the model does not hide extra boxes by deleting them.

Now press **RECOVER**. The receiver can collect one arrived box every 0.6 seconds. Existing boxes must still reach it. Watch the heap change before calling the repair complete. Increasing the collection rate and erasing the history are different operations.

**RESET** clears this local parcel experiment and restores matched intervals. It does not rewind the museum's elapsed time.

<!-- @ -->

Every box followed the same admission rule. Every collection followed the same receiver rule. A difference between their intervals nevertheless changed the space. What counted as a successful delivery upstream became somebody else's obstruction downstream.

There is comedy in anticipating a clean handover and watching a parcel arrive at the wrong moment. There is also another form appearing in the interruption. For whom is the heap only waste? What would have to change for it to become a shelter, a route, a body worth keeping?

We have made those questions available; this first machine does not yet let you carry away its boxes or climb its heap as a designed route. Carry the distinction forward: a parameter can change a pattern, but the permissions of the body still need to be built.


## Change wishes and the next sequence

[From an arrow to a room that acts](vectors-forces-plan.html): four if_not_exist_create proposals are now placed in Change_Choreography, and the first VectorBasics encounter connects its editable arrow to two wall views. The plan follows the accumulating method across Vector and Forces applications.
