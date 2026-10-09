# The surface includes you

<!-- @decaying_bridge -->

The path looks available. Five tiles across, a longer line ahead. Its colours repeat in a panel along the wall. Beneath it lies a shallow basin, already drawn with the addresses of tiles that have not yet disappeared.

Begin at the desk. SOURCE can nominate the pink probe in your place. With PROBE / NEAR showing, press RUN. Follow the gold square W. The number falls. The tile changes colour, then becomes a faint sheet through which the basin is visible. Stop the local experiment. How much of a path is still there?

Use NEAR/FAR to withdraw the probe and run again. Watch the edge of the depleted region before its centre. Something returns through what remained around it. There is no separate instruction ordering this particular patch to grow back into its old outline.

RESTORE prepares a full bridge. Change SOURCE to VISITOR and start RUN. Your position now takes the probe's place. Approach the marked region, wait, move away. The ordinary museum floor continues alongside the basin; recovery ramps rise from its left side. On the bridge, lingering can cost you support. The faint tile can still be seen after it can no longer carry you.

The bridge's variable is called health. Here that means a number between zero and one. The name lends it a small biological story, but the operations are available to read. Nearby cells lose a fixed amount on each update:

```gdscript
if present and cell_position(coord).distance_to(local_visitor) < decay_radius:
    next[coord] = maxf(0.0, health - decay_speed * dt * 5.0)
```

Distance is measured in three dimensions from a cell's centre to the tracked body's origin. No scale weighs your feet. The surface can respond before your body is standing on the cell you are watching. The pink probe can produce the same numerical influence without a person above it. Which part of our first explanation came from the event, and which part did the appearance of a bridge invite us to supply?

Outside that radius, a cell can recover through its four immediate axial neighbours. Each neighbour above 0.5 contributes to recovery. At 0.3 a tile can support you, yet it cannot contribute as a healthy neighbour. Below 0.2, its collider is disabled:

```gdscript
colliders[coord].set_deferred("disabled", health < 0.2)
```

One changing value meets two different thresholds. Being visible, carrying a visitor and helping a neighbour recover are separate permissions. The wall uses the same health materials, but its coloured panels supply no bridge collision. A room can wear an answer without offering the same way through it.

There is another condition hidden in “each update.” Choose CHAIN for a small prepared comparison. The bridge begins mostly depleted; three adjacent values are 0.600, 0.495 and 0.000. SOURCE becomes NONE. We can attend to recovery without moving the input at the same time.

STEP once in SYNC. The middle value crosses 0.5. Has the next cell been allowed to use that change already? ORDER switches to SCAN and restores the same beginning. Step again, then use REVERSE and repeat. A different answer can appear even though the neighbouring cells and the amount of time are unchanged. The loop has a direction too.

SYNC reads the previous field throughout the update. SCAN reads answers already written during the same pass. In this study, changing scan direction leaves the synchronous result unchanged; in-place recovery can change. The choice sits in a single line:

```gdscript
var read_states: Dictionary = previous if snapshot_reads else next
```

We have returned to the two arrays from the Life dish. Their separation now changes when a weakened surface can help another part of itself. The rule includes a schedule, even when the picture conceals it.

Restore the full bridge and return to the visitor input. There is pleasure in architecture answering us, and a stranger pleasure when its answer interrupts the role we expected it to play. We can study that relation without deciding that a responsive surface must be alive. A fully depleted field with no healthy neighbours remains depleted. Withdrawal alone does not promise repair.

At thirty simulated seconds this study holds. The museum continues. We leave with a more precise question than whether the path is living: which relations let it carry a body, recover, or become unavailable?

<!-- @ -->

The next room asks what a cell can receive from its neighbourhood when counting healthy neighbours is no longer enough. A softer-looking surface will need another working rule to earn that difference.
