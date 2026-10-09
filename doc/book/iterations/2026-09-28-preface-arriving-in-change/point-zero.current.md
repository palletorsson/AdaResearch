# Point Zero — You arrive late

… You arrive late.[^1]

<!-- @arrival_shaft -->

You fall through a dark shaft into a lit room. In front of you, a number is running. Like Alice, you have entered before you know what kind of place you have entered. The floor catches you; the number goes on.

<!-- @frame_counter_display -->

The number is already changing. Its first number for you is not its first number. While you find somewhere to stand, the room continues with whatever it was doing before you arrived.

You can stand in a room you did not build. Someone has made that possible. Their work gives us somewhere to begin, and brings decisions with it. We inherit possibilities before we know their conditions. What are we forced to borrow for now, and what must we understand to make the work our own?

Let it run while you look around. When you return to the number, it has moved on.

Where does the next one come from?

A small counter can begin here:

```gdscript
extends Node3D

var _count := 0

func _process(delta: float) -> void:
    _count += 1
```

Godot repeatedly calls `_process`. Each call runs `_count += 1`, adding one to the stored number: one, then two, then three. The starting value, `0`, is set outside the function, so each call keeps what the previous one left behind.

`delta` supplies this update's time interval, in seconds. Our counter ignores it. A hundred calls add a hundred, however long they took. The number keeps how many, leaving how long unanswered.

That example has its own count. The room's counter reads a total that began earlier:

```gdscript
var frames: int = int(Engine.get_process_frames())
```

`Engine.get_process_frames()` counts process frames since the engine started. The panel displays that total, including frames from before the panel existed, before you found the number.

We begin with a number that includes something we did not witness.

The view of this room has to be drawn again while you are in it. Turn your head and another view is drawn. That is the demand of real time here: the program must keep answering a body that has already moved. The counter gives this continuing work a visible trace. It does not count the years it took to make the room possible.

We have read the line that asks for that number. Much of the code making it readable remains unopened. It is like standing on the shoulders of giants in fog: other people's work has brought us here, but height alone does not give us a clear view.

<!-- @folding_past -->

Through the entrance window, rectangular frames recede within frames. They keep folding while you look elsewhere. There is a temptation to follow them back to a first frame, a place from which everything here might be explained in order.

Ten frames, scaled and moved through a repeating cycle, make this depth. They hold no record of the route you took to arrive here. A few repeated shapes can invite a much longer journey than the one their program keeps.

We could stay with the counter: how a digit gets its shape, how its glass is drawn. We would also like time to pick something up. The code we leave unread keeps working while our attention moves elsewhere. Who gets to decide which questions can wait?

<!-- @origin -->

## Somewhere to count from

We cannot follow everything back to its beginning. But we can choose somewhere to count from.

Find the black sphere with its pink glow and wireframe cube. Its label says “Point zero”. Zero has been given a place in this room too. This zero is a reference in space, not the first moment of the running clock.

```gdscript
var origin := Vector3.ZERO
```

`Vector3.ZERO` is shorthand for three zeroes: `(0, 0, 0)`. Used as a position, it names the origin of a coordinate system. From there we can measure where something else is. Nothing in those three zeroes explains why this place was chosen.

Nearby, three words are printed on the floor: “~~you~~ are here.” The first is struck through.

Take hold of the struck word. It lifts. The crossed-out “you” comes away as a thing you can carry, and the rest of the sentence stays exactly where it was printed, still saying *are here* to the room. Set it down somewhere else and look back at what is left behind.

The location remained legible without its visitor. That is not a trick of this decal; it is what an address is for. What part of you has arrived at this one?[^point-one-ahmed-reach]

<!-- @ -->

We have chosen a place to count from. In the next corridor, a label is waiting for something to appear above it.

Point one.

[^1]: Heidegger’s *thrownness* names finding ourselves already delivered into an existence we did not choose—not simply arriving after the clock started. Here, the room offers a small encounter with that condition. Genesis, first light: we look for a beginning. But is this the world beginning, or our first glimpse of something already underway? See [*Being and Time*, §29](https://www.beyng.com/pages/en/BeingandTimeMR/BeingandTimeMR.174.html).

[^point-one-ahmed-reach]: Sara Ahmed, [*Queer Phenomenology: Orientations, Objects, Others*](https://www.dukeupress.edu/queer-phenomenology) (Duke University Press, 2006), introduction. Ada’s questions about orientation and reach draw on her account of bodies finding their bearings through relations with objects, spaces and others. Lines will make this conversation more explicit.
