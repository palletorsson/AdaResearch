# Trace ball ramp

Take the black ball, place it on the plank and release it. Gravity drives the ball; its measured positions leave a trace. A fresh ball waits on the stand once that space is clear.

Each ball and its ink remain for this artifact's lifetime. Pickup pauses that ball's recording; release begins another stroke without erasing earlier ink or drawing across the carried movement. Each ball has a separate 1,024-segment trace buffer. Balls collide with the ramp and one another.

There is one stand supply at a time. Releasing an older ball does not add a second supply. If a released ball still occupies the stand, refill waits until it is moved away. Balls that escape below local Y = −2 or beyond 16 local units are frozen where they are, keeping their ink; they are never recycled onto the stand.

Run the production-scene regression test:

```powershell
python -X utf8 tests/museum/run.py --only trace-ball-ramp
```

The test uses real Godot physics and XR Tools pickup/release with a synthetic hand. Controller buttons, full-hall appearance and long-session headset performance still require manual testing.
