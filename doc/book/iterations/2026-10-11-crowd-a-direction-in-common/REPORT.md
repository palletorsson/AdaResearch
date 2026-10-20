# A direction in common

Endless Museum · Flow Fields · 11 October 2026

Twenty-four figures turn toward the same destination. At their feet, arrows lead around a low island. Carry the black point toward A or B and the field changes. Drop it and the same bodies return.

## Try the encounter

Reload **Swarm Intelligence → Flow Fields**. Walk through the opening on the east side into the new court. The point stands beside the waiting group, at hand height.

- **Carry the point toward A or B** to choose a destination. A movement of more than 20 cm toward either side selects it. The neutral middle band keeps your selection.
- **Trigger**, or desktop left-click while carrying, shows or hides the arrows. Desktop right-click carries or drops the point.
- **Drop the point** to bring the group back. All twenty-four bodies remain; none are replaced. The point returns to its stand after 1.5 seconds.

Walk around the island and watch a body meet a turn. Then hide the arrows. The guidance remains active even when its marks disappear.

## What this adds

The fish and drone comparisons used neighbours as moving references. This crowd shows another source of collective movement: **a shared field prepared for everyone**. The same group can appear coordinated while each body consults only its own position and the directions supplied there.

The point keeps its existing pickup and action class. Its new role is to choose the destination that reorganises the field. The figures keep their identities, positions and velocities across changes. Their sphere heads retain the point’s visual role while their larger bodies make the room inhabitable.

This is an optional full-size encounter beside the existing Flow Fields lesson. The fourteen canonical tutorial/final files and seven-hall order remain unchanged. The original table, ant colony and ecosystem placements remain. The hall extends from 13 × 10 to 33 × 15 cells, with a three-cell opening to the east court and a low central island that visitors can walk around. The automatic entry partition is disabled so it does not span the new court; authored walls remain apart from that opening.

## Exact mechanism

The new model reuses the existing **FlowGrid cost propagation** from the table. All traversable cells here have equal cost. A local adapter selects cardinal neighbours with lower costs, keeping a margin around the island. Movers steer toward successive cell centres with bounded acceleration and speed. Near their destination, they move into assigned parking places. Those places are supplied staging; the parking pattern is not evidence of emergent agreement.

No mover reads another mover. A test changes all the other bodies while retaining the witness’s inputs; its trajectory remains identical. The figures are kinematic visual bodies and can overlap. This demonstrates shared route guidance, not pedestrian collision avoidance or crowd pressure.

The arrows come from the same field used to choose the next cell. Thin cylinders and cone tips give their direction a physical shape. The island and point stand have real collision for the visitor. Moving figures and floor arrows do not block the player.

## A short reflection to consider

The bodies turn together. You hide the arrows and the turn looks like something they decided among themselves. Yet none has asked where its neighbour is going. You move the point; the ground is rewritten. What looked like agreement was also an arrangement of the room.

This paragraph is an encounter note for review, not an automatic insertion into final.md.

## Evidence and limits

**43/43 checks passed:** 22 code checks and 21 native museum checks.

The code run covers 150 simulated seconds across A, B and RETURN, plus a 105-second mid-route reversal and return. All bodies arrive, stay outside the island, remain finite and obey the speed cap. Additional checks cover unchanged-target caching, neighbour independence, transformed coordinates, actual pickup/action/drop hooks, identity retention and agreement between displayed arrows and field vectors.

The museum run checks continuous floor and standing-capsule clearance through the entrance and around both sides, hand-height reach, live destination selection, arrival at A, redirection, and return of all original bodies. Six images come from native Godot rendering. The with/without-arrow photographs hold positions fixed; movement resumes afterward. This is a capture technique, not a player pause control.

The first native run exposed repeated physics writes returning an already-resting point to its stand, which could overwrite the first pickup movement. The artifact now returns it only when displaced. The final run rechecks the actual transition. A malformed placement parameter was also corrected before the final run. Earlier failed run folders remain available.

No script or shader errors occur in the final receipts. Existing project warnings remain in the logs. Physical headset use, portal crossing, Quest performance and an independent learner review remain open. These checks validate this encounter, not a new full-sequence ghost-student run.
