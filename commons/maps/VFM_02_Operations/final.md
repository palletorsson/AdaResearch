You arrive in the middle of the row.

The spawn is at the eleventh column of the north wall, and there are instruments on both sides of you before you have taken a step — five to the west, five to the east, all at arm's height, all facing the same way. Twenty-seven in the room. Until this afternoon not one of them said a word about itself.

This is a bench. Everything on it is true, and almost nothing on it is the lesson. The lesson is next door, where the same operations stand at the size of a room with a caption panel each. What a bench is for is the other thing: to let you hold six answers to one question at once and find out that they disagree.

## Pick one up before you read its label

<!-- @sub:intro -->

The first panel asks you to do exactly that, and it is not a rhetorical move. Every instrument in here is a vector operation rendered as furniture: a board, a barrel, a crank, a rail, a gauge. The rendering is not decoration and it is not neutral. It is a claim about what the operation *is like*, made before any arithmetic is shown, and you can test it with your hands before anyone tells you the answer.

Walk east first — the floor takes you that way, because there is more room on that side.

<!-- @ -->

## Add by walking

<!-- @adder_board -->

The one artifact in this room ruled primary. Two operands go in, a sum comes out, and the board's own export decides how much of that you are allowed to see:

```gdscript
# adder_board.gd
@export_enum("outcome", "trace", "operands", "expression") var workings: String = "expression"
```

Four settings, and they are four different pedagogies. `outcome` shows the answer. `operands` shows what went in. `trace` shows the path. `expression` — the shipped default — shows the whole sentence, both sides of the equals.

That export is not unique to this board. `torque_crank` has the same four values and ships set to `trace`. So two instruments in one room have been given opposite instructions about how much of their own working to show, and nothing in the room announces which is which. You are standing in a bench where the answer to *show your work?* was decided per object, by whoever built each one.

<!-- @sub:ask_add -->
<!-- @sub:truth_add -->

The caption at the third row asks where you end up if you walk a then b; the answer waits two rows further south, at row five, so the question is behind you by the time it is answered. That is deliberate and it is the room's method: you are meant to have done the walking in the gap.

<!-- @ -->

## Find out what the gauge is blind to

<!-- @agreement_gauge -->

This is the instrument worth staying with, because it is the one that admits the room has a problem.

```gdscript
# agreement_gauge.gd
const MEASURES: Array[String] = ["cosine", "projection", "angle"]
const SHIPPED_A: Vector3 = Vector3(0.9, 0.55, 0.2)
const SHIPPED_B: Vector3 = Vector3(0.35, 0.85, 0.6)
```

Three measures of the same thing. Grab either tip, change the angle, and the gauge reports how much the two arrows agree — as a cosine, as a projection, or as an angle. They are not interchangeable. The source says so in its own comment: cosine is *magnitude-blind*, and under `projection` "length now contaminates" the reading.

So the question the room keeps asking — *how much do these two agree?* — has three answers, and picking one is picking what you are willing to ignore. The shipped default is `cosine`, the blind one. Make one arrow four times longer and the needle does not move. That is either the correct abstraction or a discarded fact, and the gauge cannot tell you which, because the decision was made before you arrived.

Two arrows agreeing is a·b = |a||b|cos θ. Divide the magnitudes out and you have kept the angle and thrown away the size. Every instrument on this bench has made a trade of that shape. Most of them do not have a switch on the front to show you it happened.

<!-- @dot_aligner -->

The barrel beside it takes the same number and gives it a job. Where the gauge reports agreement, the aligner *hunts* for it: turn the rig until the reading peaks and the lock beam fires, and the foe turns from red to green. The dot product stops being a measurement and becomes a targeting condition — the first place in the chapter where an operation is used for something rather than shown.

<!-- @sub:truth_sub -->
<!-- @sub:truth_scale -->
<!-- @sub:truth_dot -->

<!-- @ -->

## Watch a shadow do the arithmetic

<!-- @projection_shadow -->

```gdscript
## projection_shadow.gd
## proj_n(a) = (a · n̂) n̂ — the shadow's distance from the origin IS a · n̂
```

A rail, a vector, and a light. The shadow the vector casts along the rail is not an illustration of the projection; it is the projection, at full size, and its distance from the origin is the dot product itself. Nothing is computed for display here that is not already the thing.

That is the strongest claim this bench makes and it is made without a caption panel, in a comment, in a file. Slide the vector until it stands perpendicular to the rail and the shadow collapses to a point: the two share nothing, the dot product is zero, and the geometry and the arithmetic arrive at zero together and for the same reason.

<!-- @sub:truth_cross -->
<!-- @sub:close -->

<!-- @ -->

## Turn the crank and watch what is left over

<!-- @torque_crank -->

```gdscript
# torque_crank.gd
@export_range(0.0, 1.0, 0.01) var leverage: float = 0.78
@export_enum("outcome", "trace", "operands", "expression") var workings: String = "trace"
```

An arm, a push, and an axis that appears when the two refuse to line up. `leverage` runs 0 to 1 and the flywheel turns hardest in the middle of that range, not at the end of it — push along the arm and nothing happens at all, because a cross product of two parallel vectors is the zero vector.

Set to `trace`, this one shows you the path rather than the sentence. The board across the room shows you the sentence. Between them the room has quietly taken both positions on how an operation should be taught, and left you to notice.

<!-- @ -->

## Twenty-six other answers

<!-- @vector_add -->
<!-- @vector_dot_product_xl -->
<!-- @vector_cross_product_xl -->
<!-- @vector_projection_reflection_xl -->
<!-- @vector_addition_demo -->
<!-- @vector_addition_xl -->
<!-- @vector_subtraction_demo -->
<!-- @VectorSubtraction -->
<!-- @vector_magnitude_demo -->
<!-- @stretch_bench -->
<!-- @basis_vectors_rig -->
<!-- @coordinate_system_switcher -->
<!-- @2d_in_3d_vectors_vis -->
<!-- @VectorWorkbench -->
<!-- @VectorTorque -->
<!-- @torque_demo -->
<!-- @dot_product_projector -->
<!-- @opening_pair -->
<!-- @vector_translation_demo -->
<!-- @example_1_4_vector_multiplication_vr -->
<!-- @exercise_5_9_angle_between -->
<!-- @vector_projection_demo -->

Every one of these is ruled secondary, and the ruling is not a demotion. Each says something the room has already said, or will say again next door at walk-in scale, and the arrangement records that so a reader knows this is a bench and not a curriculum. Six of them carry `_xl` in the name and delegate to the algorithm scenes at five times the size; two of them are the same operation as `adder_board` with different furniture around it.

A room can afford to say a thing six ways. What it cannot afford is to leave you unable to tell which of the six you were supposed to learn from. That is what the thread is: the one order through here that somebody decided, and everything else standing beside it.

<!-- @ -->

## Who decided these seven

The bench closes on a question rather than a summary, at the last panel before the door:

> Seven operations, laid out in a row like a shop. ? who decided these seven were the operations ?

Add, subtract, scale, dot, cross, project, torque. It is a good list. It is also a catalogue, and a catalogue is a claim about what exists — the same claim a marketplace of purchasable bodies makes when you go looking for a model and find that the categories were waiting for you. There are other operations. Nothing in this room is the reason you have not met them.

The door goes to `Vectors_Act2_VectorArithmetic`, where these same seven stand at the size of a room, each under its own caption, down a single corridor in the order somebody chose. This room is where they are all true at once. The next one is where they are taught.
