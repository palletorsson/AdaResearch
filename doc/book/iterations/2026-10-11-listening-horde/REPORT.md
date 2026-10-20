# They heard you there

Endless Museum · Agent-Based Modeling · 11 October 2026

Carry the black point. Send a pulse. Walk away. Twenty bodies investigate the place where the pulse happened, then return to their resting places. The familiar point now leaves a record inside another body.

## Try it in the museum

Reload **Swarm Intelligence → Agent-Based Modeling**. Enter the new court through the east opening in the existing hall. The point waits on a pale stand, 1.18 m above the floor.

- **VR:** grip the point, then press trigger to send a pulse.
- **Desktop:** right-click to carry/drop; left-click while carrying to pulse.
- Move the point somewhere else without pulsing again. Watch the gold rings: they keep the earlier place.
- Let go. The point returns to the stand after 1.5 seconds; the crowd completes its investigation.

**o Rest → ? Investigate → < Return → o Rest**

The heads change colour as well as carrying a state glyph. The floor circles show the original resting places. Each audible pulse stores a new destination for each listener that hears it. Hearing uses an eight-metre radius; a listener outside it retains its existing state. Three seconds spent within one metre of the remembered place starts the return.

## What the encounter carries forward

The sphere uses the existing PointBody class, with its existing pickup and action signals. The bodies reuse the visual idea of the point as a head. The new operation is **recording a position when an event occurs**, then letting a state choose what to do with that record. The pulse does not supply a live connection to the player.

This is an optional transfer encounter beside the foraging tutorial. The primary tutorial already teaches an internal state; the listening crowd gives that operation another concrete setting. All fourteen canonical tutorial/final files and the seven-hall order are unchanged. The original colony, navigator, utilities and their authored placements remain.

The new side court extends the hall from 13 × 10 to 24 × 10 floor cells. A three-cell doorway connects the rooms; the low partition gives the crowd a 2.2 m opening. Procedural decorative sculptures are excluded from the encounter floor so they cannot block the experiment. The original north–south route remains open.

## A record can outlast its source

You leave the place. They keep coming to it. Their movement is exact within the rule we gave them, yet it no longer meets your present position. A stored observation can keep directing action after the world has changed. These listeners remember a coordinate; that is the limit of what their apparent attention means.

This paragraph is a possible encounter reflection, not an insertion into the agreed final text.

## What is supplied

The court has a fixed single-door waypoint, bounded steering and separation. It is a controlled kinematic crowd, not a rigid-body collision simulation or a general pathfinder. The listeners cannot damage or physically trap the player. The wall and stand have actual collision. The pulse is audible, but hearing is an explicit distance rule: wall occlusion is not simulated. The gold marker shows the latest pulse; an out-of-range listener may still retain an earlier record.

## Evidence

**42/42 checks passed:** 23 production-code checks and 19 native museum checks, including four camera captures.

The code tests exercise the real state/movement model, finite and capped motion, hearing range, replacement of a record, passage constraints, complete return to rest, and arrival on the correct side of the wall. The actual PointBody action is tested under a translated and rotated host. Moving or releasing the sphere does not change stored destinations.

The museum run checks floor support, standing-capsule clearance from the existing room to the court, passage clearance, partition collision, point reachability, the original route and the live investigate/return cycle. All twenty listeners returned to their original resting places. The pictures are native Godot captures with the simulation running.

The first capture exposed a wrongly specified sculpture exclusion rectangle; decorative sculptures obstructed the new passage. That was corrected and the native checks rerun. The final run has no script errors. Existing unresolved UID, catalyst ViewportTexture and renderer/Jolt warnings remain in the logs; this is not a claim that the whole project is error-free.

Pickup and trigger events were supplied by the probes. Physical headset use, portal travel and Quest performance remain untested.
