# Fresh student's construction account — before running

I read only the supplied packet. I have not run Godot or inspected production code, prior student attempts, teacher probes, or solutions. This is an AI reconstruction, so it does not establish what a human beginner would find easy.

## Construction

I reconstructed 03_mass.gd and all three helpers directly from the printed blocks, preserving their code. For 03_mass_eight.gd I changed only the mass expression and heading requested under **Change one thing**. The exact reconstruction did not require a hidden scene recipe: shared-code.md supplies the three filenames, PointStudy setup and museum dependencies.

For comparison.gd I made two arrays of durations and remaining times, paired their indices with two point bodies, and copied the force application pattern inside that indexed loop. The instruction “Update each clock separately, keeping its index paired with the same point” was concrete enough to guide this. I kept starting-position values in _ready(), as Trace kept a first position. I added a pulse_started flag so the initial zero clocks do not create an end snapshot before the first press. The snapshot_taken flag preserves the distance readings after both clocks reach zero, and push() clears it for another pulse. I display current speeds, current distances, remaining times and the stored distance pair. The additional pulse_started guard is my own programming choice.

I made transfer.gd with one 3 kg point and a 3 s pulse from the same supplied button helper. I did not add a room, camera, player, RESET or trail. Those are assigned to the hall by **The hall adds**, not to this small reconstruction. Each script is intended to replace the script on the same stationary, unit-scale PointStudy; the saved originals remain available.

## Inherited and newly learned

From Lines I inherited a repeatable pickable point and displacement length; from Coordinates, local versus world positions; from Trace, arrays, retained values, indices, loops and if; from Point Zero, the label and callback pattern. Launch supplies both a running boolean and the constant-acceleration position formula. Transformation had already distinguished changing a property over time from constructing it once.

The new conceptual step is asking the engine to change a body's velocity by applying force during _physics_process. **Read the change** explicitly gives acceleration = force/mass and velocity change = force * duration/mass, then explains that the script never sets velocity back to zero. **Model notes** explains global_basis and interval/delta well enough to reuse them, though it does not teach the basis calculation itself.

My existing programming knowledge helped with typed float arrays, boolean conditions, composing a caption and guarding a once-only measurement. The readings show pieces of this syntax, but do not explicitly teach a two-condition event latch. I used prior algebra to rearrange the velocity-change rule for duration and to join an accelerating interval to a coasting interval. I do not claim to have discovered that mathematics merely by copying the example.

## Prediction and unresolved points

The exercise clearly specifies unequal pulse durations, both 1 s and 2 s observations, distance from the starting position and a persistent end snapshot. I could derive the predicted equal final speeds and unequal distances using Launch's formula. My numerical predictions are in predictions.md and were recorded before any execution.

I do not know the precise ordering of force integration and caption sampling from this text. I take the distance snapshot in the callback where the two clocks first reach zero, literally following the exercise, and accept its stated small physics-step boundary difference. The packet does not tell me the sign or exact size of that difference.

“Keep each starting position before the run” could mean a new origin on every press. I chose the scene's initial positions, consistent with restarting the study for a fresh comparison and with repeated presses continuing the existing journey. The next press refreshes the end snapshot, but does not reset the origins or motion. My caption describes distance from those original positions.

I cannot calculate an arbitrary held-point final speed without knowing how the hand moves and releases it. The text supports the missed-force interval and continuing clock, while free_point.gd only names physical release. I have left release-state effects as an explicit uncertainty instead of inventing a stationary release rule.

The supplied original caption rounds to two decimals, so the requested 0.125 m/s edit is not exactly visible there. I preserved it as printed and used three decimals in my exercises. I also read “distance” as displacement magnitude for these straight paths, because the exercise explicitly limits that measurement; after a detour it would not be total path length.

## Interpretation

Before execution, I can say what a successful run would support: a matched force and duration give different speed changes for different masses; changing duration can equalize final speeds while leaving different distances; and velocity persists when the force ends under the arranged conditions. I cannot yet report any of those as observed results.

The reflection's passages “The latest instruction does not contain the whole movement” and “A contribution to the present velocity can outlast the mark of where it began” add an account of present state and incomplete records. The repeated-press and catch experiments could make the first concrete. The second depends on the hall's recent trail; my small exercise does not construct that trail and cannot demonstrate its truncation. The reflection's observation that equal treatment yields different movements is tied here to mass, not evidence for a general social conclusion. RESET and remembered experience similarly belong to the larger apparatus and the reader's interpretation, rather than to a result measured by my caption.
