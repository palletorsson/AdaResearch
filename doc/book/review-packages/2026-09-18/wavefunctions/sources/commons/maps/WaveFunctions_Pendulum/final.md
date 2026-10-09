# Where a swing leaves its past

Behind the bob, something is leaving the room very slowly.

<!-- @PendulumWave -->

Stand beside the frame and follow the swing. Then choose one teal mark just behind it. The bob turns. Keep looking at your mark: does it turn too?

It continues away along the hall. Walk beside it. From here the whole record resembles a wave, although the bob has only swung in one plane. The long direction belongs to something the bob did not do.

Each mark keeps a position and a time. When the record is drawn, this line gives it depth:

```gdscript
var depth: float = (time - p.z) * time_speed
```

`p.z` holds the time of the sample. Subtract it from the present and an age appears; multiply by 0.6 metres per second and that age becomes a distance. An old moment is further away. We can walk beside a duration because a direction has been given another job.

Find two crossings of the record's centre line that go the same way, one full swing apart. Count the marks between them. The plate gives a measured period and a target sampling interval; dividing the first by the second should come close to your count.

Close is enough to notice another line on the plate. FINE requests 25 milliseconds. The actual gaps are about 16.7 to 33.3 milliseconds. Which rhythm is in the drawing?

The recorder works on a physics clock ticking sixty times per second. Its request falls between ticks, so the gaps alternate between one tick and two. The small mismatch has a place in every swing's record. The cyan joins can make it easy to overlook.

Press COARSE and watch the empty record fill again. The bob continues its swing. Compare how far the oldest mark gets before disappearing. The rougher line can reach further into the past.

Two endings are written into this list:

```gdscript
while trail_points.size() > max_trail_length:
	trail_points.pop_back()
while not trail_points.is_empty() and time - trail_points.back().z > max_history_seconds:
	trail_points.pop_back()
```

The newest samples enter at the front. These lines remove from the back: first anything beyond three hundred entries, then anything older than ten seconds. FINE fills the available entries in roughly 7.5 seconds. COARSE keeps around fifty under the age limit. We changed which detail was affordable, and gained duration. A person looking for a small tremor and a person looking for a long return would have different reasons to choose.

Walk to the far end and wait with one mark. It is there, then absent. No fading gives it a farewell. The pendulum carries on from its current angle and speed; this little piece of its accessible past has gone.

Now press STROBE. The sampler uses the period measured from the pendulum's own crossings. After a few swings, compare the moving bob with the sparse record behind it. The marks nearly line up. Tick-sized differences remain, but much of the movement has vanished from what was kept.

This can become an instrument for finding repetition. It can also make repetition look like stillness. Try reading the marks before glancing back at the bob. The same setting helps with one question and makes another difficult to answer.

RESET begins this experiment again: starting angle, local time, empty list. The museum continues. We have already seen how useful it is to make a beginning without beginning everything.

<!-- @ -->

On the west walkway a drum turns beneath a pen. There, time takes an angle instead of a depth. In the point rooms, the drawing dot asked whether a hand had moved far enough to keep another position. These recorders ask different questions of what passes them.

We could stay and change what a record values. Ahead, rising and falling are being given yet another direction: two walls carry waves along a passage. A line that helped us read time will become something we read with a moving body.
