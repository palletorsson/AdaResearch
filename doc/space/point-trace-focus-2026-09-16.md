# Point_Trace — what does the recorder keep?

Initial review after the Point_Lines checkpoint, `a99253f24`, on 16 September 2026. This examined the local files on `palm-scanner-door-entry`; the linked GitHub page could not be retrieved. The subsequent approved revision is recorded in [the implementation note](point-trace-focus-2026-09-16/README.md); the recommendations below document the initial review.

## The thread to retain

Lines leaves with a detour that two endpoints cannot remember. Trace adds an ordered selection of positions and draws straight segments between them. The further question is what this selection lets us recover, and what the drawing supplies between the samples.

The current final.md already has a useful encounter: draw a loop, pause, watch the count, inspect neighbouring rows, and try another recording grain. Keep this foundation. Coarse recording can also help someone repeat a chosen shape; greater detail is not the only useful outcome.

## A comparison already available

The drawing dots admit movement after a 5 mm threshold. Spatial rounding and consecutive-duplicate rejection happen afterwards. The stored list holds at most 4096 positions. In these placements fading is off, so the optional `_trail_times` list is not populated. Releasing the dot sends the positions to TraceData, without a timestamp for each point.

The hand telemetry display instead appends a time and position whenever its sampling timer reaches its interval, even if the tracked hand remains still. Its default interval is 0.12 seconds; actual sampling opportunities depend on process callbacks. Its footer distinguishes tracking from a demonstration feed.

This offers a precise return to the opening pause: one instrument can leave its count unchanged while another adds timed rows. Different rules give the pause different records. With no tracked controller, the synthetic feed cannot serve as evidence of the visitor's stillness.

Relevant source: `commons/primitives/point/draw_dot.gd`, its `.tscn` configuration, and `commons/primitives/hand_telemetry_display/hand_telemetry_display.gd`.

## What each artifact contributes

- **draw_dot, four placements:** main experiment in recording, count, selection and spatial grain.
- **draw_stick:** a concise variation that moves the sampling point to a tool's tip.
- **whiteboard:** contact selects which part of the hand's journey becomes an image; lifting leaves an intentional gap.
- **hand_telemetry_diptych:** a useful comparison for the pause and for the provenance of a record.
- **automatic_writing_desk:** a possible optional return about interpreting expressive marks. It need not become a further required theory of confession.

Keep the existing artifacts. A primary-role change should follow the revised reading, not a numerical limit on artifacts.

## Next editorial pass

1. Preserve the opening experiment and make the connection of retained samples explicit: the segments are constructed between measured positions.
2. Bring the telemetry comparison closer to the question about pausing; describe its source label before inviting interpretation.
3. Keep the stick and whiteboard as short variations. Let the automatic-writing desk remain an available detour.
4. Align intent.md and tutorial.md with the installed recorder. The tutorial's 200-element, every-callback example is a possible implementation, not the current tool; `append()` followed by `pop_front()` is not a circular-buffer implementation.
5. Rework the inherited assertions in critical.md that traces necessarily preserve duration, intention or resistance. Preserve the questions about memory and power, while asking which data and operations support each claim. The later section about the authority of a legible instrument is particularly useful.
6. Correct the map's stale artifact count: it has nine interactable placements across six token types; metadata still says five.

The exit remains concrete: release a dot or stick to send a copy of the selected positions onward. Grid receives that trace and asks where its positions can stand. The next room can build on the same record rather than asking us to start again.
