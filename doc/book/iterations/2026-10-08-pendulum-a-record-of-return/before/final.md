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

One swing on this length of line takes about two and four-fifths seconds; at 0.6 metres a second it leaves about 1.7 metres of record. A period has become a length: a wavelength, the word for a return measured along a direction instead of along time.

Look at the two intervals on the plate. FINE requests 25 milliseconds. The actual gaps, at a desk, are 16.7 and 33.3 milliseconds. Which rhythm is in the drawing?

The recorder works on the physics clock: sixty ticks a second at a desk, and in a headset as many as the display draws, seventy-two or ninety. Its request falls between ticks either way, so the gaps alternate between two neighbouring tick counts: at sixty, 16.7 and 33.3 milliseconds; at ninety, 22.2 and 33.3. The small mismatch has a place in every swing's record. The cyan joins can make it easy to overlook.

Press COARSE and let a few swings leave their marks. Now find two crossings of the record's centre line that go the same way, one full swing apart. There are far fewer marks to count between them. Divide the measured period on the plate by the requested interval: does it come close to your count?

Keep watching as the older marks move away. Compare how far the oldest gets before disappearing. The rougher line can reach further into the past.

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

This can become an instrument for finding repetition. It can also make repetition look like stillness. Film cameras did this to wagon wheels for a century: a wheel whose spokes advance by one spoke-spacing between frames photographs as still, and by a little less as turning backwards. STROBE is that fault chosen on purpose.[^wagon-wheel] Try reading the marks before glancing back at the bob. The same setting helps with one question and makes another difficult to answer.

RESET begins this experiment again: starting angle, local time, empty list. The museum continues. We have already seen how useful it is to make a beginning without beginning everything.

<!-- @ -->

Across from the sampler panel, a drum turns beneath a pen. There, time takes an angle instead of a depth. In the point rooms, the drawing dot asked whether a hand had moved far enough to keep another position. These recorders ask different questions of what passes them.

Across the hall a pendulum draws a rosette because the paper under it turns while its plane does not. In Paris in 1851 that turning was the Earth's, and the pendulum was the proof; here no floor turns, so the program turns the paper, in three minutes instead of a day and a half.[^foucault] And three pendulums hung from pendulums paint on wet canvases: their rule is as fixed as this one's, and no second release will paint the same picture.

We could stay and change what a record values. Ahead, rising and falling are being given yet another direction: two walls carry waves along a passage. A line that helped us read time will become something we read with a moving body.

[^wagon-wheel]: The wagon-wheel effect is temporal aliasing: any sampler misses what returns between its samples, and a sampler timed to the return misses all of it (Nyquist and Shannon, 1949). *Nature of Code* names it in passing in its chapter on oscillation.

[^foucault]: Léon Foucault hung his pendulum in the Panthéon in 1851. A swing plane turns at the Earth's rate times the sine of the latitude: at 45 degrees, once in about 34 hours; the artifact here (foucault_pendulum) turns its canvas at 0.05 radians a second times that sine, once in about three minutes, some seven hundred times faster. The painters are WavePaintings, three double pendulums with the middle bob grabbable.
