You arrive late.

The room was running before you entered. You are here now. Before learning what a point is, try to locate one: what would you have to see, touch or read to be certain it had moved?

<!-- @frame_counter_display -->

Watch the counter long enough to see several increments. Pause for a breath, then look again. Does a change of one tell you how long you waited?

The counter's default reading is the engine's total processed frames since startup:

```gdscript
var frames: int = int(Engine.get_process_frames())
```

One more frame, one more count. The interval between counts can change. This is a count, not a frames-per-second reading. Equal increments can contain unequal waits. Already, something has happened that the number does not describe.

<!-- @ -->

## Hold a location

<!-- @interactive_point_origin_force -->

Pick up the dark point. Move it a little to one side, then back. Follow its position label and the line toward the origin. If the label disappears, put the point down and pick it up again: successive pickups cycle the display formats, including a hidden one.

The held object also changes its appearance and can act as a force catalyst. For this first experiment, follow the position through that change. What remains locatable when its visible form changes?

What you can see is a sphere. A mathematical point has no extension; it specifies a location. The sphere gives that location a visible body and something the hand can acquire. Its surface, collision shape and force behavior are properties of this artifact, added around the point it lets us investigate.

Three numbers can express the position in a chosen frame:

```gdscript
var p := Vector3(1.0, 0.5, 0.0)
```

Those numbers do not include the sphere's radius, the shape of your hand or why you moved. A `Vector3` stores three components; deciding to use them as a position gives those components their job.

<!-- @origin -->

Find the origin marker. Compare it with the moving point. One can move while the reference remains still.

```gdscript
var origin := Vector3.ZERO
```

The origin is a point made special by convention. What is chosen is that *this* one is called zero. A world can be described from that reference without making it the only possible reference.

<!-- @ -->

## Read where you are

The wall readout, the red target and the coloured frame belong to one experiment. Keep hold of the same point as you move between them.

<!-- @coordinate_readout -->

Move very slightly while looking at the white card marked `WORLD`. Find a movement small enough that a printed component stays still, then make a larger movement along the same direction. Compare the card with the point itself before reading on.

The numbers have moved away from the point and onto a white card. You have to look between the moving thing and the sentence that locates it. The readout's operation can be written as:

```gdscript
func report_position(point: Node3D) -> String:
    var p := point.global_position
    return "(%.2f, %.2f, %.2f)" % [p.x, p.y, p.z]
```

`%.2f` rounds the report to two decimal places. It leaves the stored position alone. The apparent stillness belongs to the display. How much movement can disappear inside a readable number?

<!-- @CoordinateSystem3M -->

Bring the point to the coloured frame. Red for X, green for Y, blue for Z. Move mainly along one axis and watch its marker, then move diagonally. Name which readings change before trying the next movement.

The axes name directions. Their common crossing supplies an origin, and their scale supplies units. Each marker shows a component of the position; the guide lines let you read the three together.

The white card reports world coordinates. The coloured frame has its own origin, orientation and scale; its script uses `to_local()` to describe the same position relative to that frame. Two addresses can locate the same point. The caption matters.

Carry the point past an arrow's end. Take it behind the crossing, into negative coordinates. The drawing has an edge, but the coordinate system continues.

An earlier version confined the point to the span of the arrows. Keeping the demonstration tidy had made its lines into walls. The frame can instead keep describing where the point went. Knowing a position need not mean keeping it in place.

<!-- @ -->

## Find out what “here” means

<!-- @drag_point_target -->

Carry the same point toward the red arrow. The instruction says “drag point here”. Predict how exact the arrival must be. Approach from one side, leave, and approach from another. Watch for the falling balls, then compare the two arrivals.

A coordinate has become a request. Here is the target's distance test, reduced to a function for one position:

```gdscript
@export var catch_radius: float = 0.45
@export var catch_height: float = 1.20

func accepts_position(p: Vector3) -> bool:
    var centre := global_position + Vector3(0.0, catch_height, 0.0)
    return p.distance_to(centre) <= catch_radius
```

“Here” is a region: a sphere of radius 0.45 metres, centred 1.20 metres above the target's origin. A hand has room to arrive. The test asks whether the point is close enough; it does not make that position identical to the centre.

The target requires no release and accepts points registered in its coordinate-point group. Your intention never enters the comparison. A careful delivery and an accidental pass can produce the same weather.

Take the point out and bring it back. The target is configured to rearm. The room asked you to complete a task; you can make a rhythm out of completing it. How long before the reward becomes the material you came to play with?

Try a detour before the next arrival. What would the target have to remember to distinguish that journey from a direct delivery? A success test can recognise a destination while leaving the journey unrepresented.

<!-- @ -->

## Follow the fold

<!-- @folding_past -->

Look into the nested frames. Follow the recession with your eyes, then turn back toward the point you moved. The frames offer a way to picture a past: a nesting, the present caught within what came before. That is an interpretation of their arrangement, not a history recovered from the point's coordinates.

You arrived late, but you can choose what happens next.

<!-- @ -->

Before leaving, choose a position and predict which readings will change if you move it upward. Make the movement. Then name one difference between two arrivals that the target cannot recognise.

One point gives a position. Two points make a relation. Repeated positions can become a trace; a grid limits where samples may land; three non-collinear points can close a triangle. Every step gains expressive power by deciding what to keep, and every decision leaves something at its edge.

The next room connects two points and asks what a line can be made to do.
