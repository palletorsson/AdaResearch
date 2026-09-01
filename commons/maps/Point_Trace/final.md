You took the trace.

The other door led to the grid — the line made again and again until the making stopped mattering. This one leads here, where the line is made once, by a body, and cannot be made again.

<!-- @3t -->

**THE TRACE.** The room says its own name before you have done anything, which is unusual and deliberate: what happens here has no shape until you move, so the only thing that can be said in advance is what it will be called.

<!-- @ -->

## What the line forgot

A segment keeps two ends and everything between them, and it keeps them as a *rule*: move either end and the between recomputes. That is its whole economy. It is why a line can be stored in six numbers and why it can be drawn a thousand times without getting tired.

The price is that a line has no history. It cannot tell you whether it was drawn quickly, whether the hand stopped halfway, whether it was drawn and undrawn and drawn again. Those are not lost in the drawing; there is nowhere in a line for them to be.

<!-- @draw_dot -->

Pick it up and move. Every frame, where you are is written down.

Not where you meant to be, and not where you ended up — where you *were*, at that instant, including the parts you would not have chosen to record. The hesitation is in there. So is the overshoot, and the small correction after it, and the place you slowed down because you were thinking.

This is the residue the line has no place to keep.

Derrida's word is nearby. Here, unusually, the machine makes the metaphor literal.

<!-- @ -->

## The same gesture, on four different grids

Four of them in a row, coarsening as you walk. They are not four artifacts — they are one artifact told, four times, where a reading is allowed to stand.

```gdscript
@export var resolution_mm: float = 0.0

func _shape_sample(p: Vector3) -> Vector3:
    if resolution_mm <= 0.0:
        return p                      # anywhere at all
    var s: float = resolution_mm / 1000.0
    return Vector3(snappedf(p.x, s), snappedf(p.y, s), snappedf(p.z, s))
```

Not how *often* the hand is read — **where a reading is permitted to land**. Every recorded point is pushed to the nearest corner of a world-aligned lattice, and what you see afterwards is the shortest way between corners.

Make the same movement at each. The one with no number keeps the position it was handed. At **10 mm** the lattice is fine enough that you have to go looking for it. At **40 mm** your curve has become a staircase. At **80 mm** whole passages of the gesture collapse onto a corner already occupied and are discarded as duplicates — not smoothed, not averaged, *never written* — and what is left is blocks.

Notice what that means. The room you did not choose is already in this one, running inside the last one in the row: quantisation, a lattice, and a remainder. You are looking at the grid from the inside of the trace.

None of them is the movement. And the machine never had the movement. It had measurements arriving one after another, each already rounded, and called their sequence a hand.

<!-- @draw_stick -->

And here it is as one continuous body rather than a row of deposits — the same record, drawn as a thing instead of a sequence. Which of the two you believe is a choice you make about what a movement *is*.

<!-- @ -->

## It forgets too

Read the code again, the last two lines.

```gdscript
    if trace.size() > MAX_POINTS:
        trace.pop_front()
```

Two hundred points, and then the oldest one is dropped. Not faded, not summarised — removed, in the same operation that records the newest.

The room's own claim is that the trace resists what the line does to a movement. It does resist it, and then it does its own version of it. There is no store that keeps everything; a trace with no horizon is a trace that fills the machine. So the honest form of "the trace remembers" is **the trace remembers for two hundred frames**, which at seventy-two frames a second is under three seconds of your life.

The horizon is counted in frames, not in seconds. If the machine slows down, your past gets longer. Even forgetting has a frame rate.

<!-- @floating_sphere_field -->

The field it accumulates in is bounded too. Four by three by ten metres, and outside that the record does not exist — not because nothing happened there but because nobody arranged for it to be written down.

Every archive is a decision about a boundary, taken before anything is in it.

<!-- @ -->

## Age as transparency

```gdscript
func render_with_fade() -> void:
    for i in range(trace.size() - 1):
        var age_fraction: float = float(i) / float(trace.size() - 1)
        var color: Color = Color.WHITE.lerp(Color.TRANSPARENT, 1.0 - age_fraction)
```

The old parts go faint. This is the friendliest lie in the room and it is worth naming as one.

Nothing about the stored position is weaker for being older. The `Vector3` from three seconds ago is exactly as precise as the one from this frame — same three floats, same certainty. The fade is a decision about *attention*: it makes recency legible by making the past look like it is dissolving, when what is actually happening is that it is being deleted, sharply, on a counter, out of sight.

<!-- @whiteboard -->

Write on it. Different rules entirely — not because nothing is sampled here, because it is, but because nothing ages out: the system treats what you put down as meant to remain until somebody explicitly erases it. It is the other way of keeping a mark, and it is in this room so the sampled kind stops looking like the only kind.

<!-- @origin -->

Zero is still here, unchanged, exactly where the first room excavated it. Everything you have traced was written as a departure from this point, and the point has no idea.

<!-- @ -->

## What the next room will do to this

```gdscript
func render_trace() -> void:
    if trace.size() < 2: return
    clear_previous_segments()
    for i in range(trace.size() - 1):
        spawn_line_segment(trace[i], trace[i + 1])
```

The trace, drawn, is already lines. Each pair of stored moments gets a segment, and what you see as a curve is a great many short straight things.

Two separate operations, and it matters which is which. **The loss happened when the samples were taken** — at the grain, at the lattice, before you looked. The lines perform the other one: they *invent* what happened in between. Nothing was recorded there, and a straight segment is the machine's guess, drawn at full confidence.

So the thing you are looking at is part record and part fabrication, and it does not distinguish them anywhere.

<!-- @science_screen -->

The screen says what was kept and what it cost.

<!-- @ -->

The grid is waiting through the other door and it will do this properly: take a movement and give back the nearest allowed positions, and call the difference error.

It will be right to. A grid is how two different movements are made comparable — how a thing that happened becomes a thing two people can discuss.

Your trace has no such power, and not because it cannot be sent. It sends perfectly: this is what a GPS track is, and a mocap take, and every gesture your phone has ever kept. **The trace is transmissible as data and irrecoverable as event.** Copy it exactly and it still never happens again.

The next room decides which of those two losses it can live with.
