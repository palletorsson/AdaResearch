# Organism — bone, tendon, muscle

The cube left us with a body built around its own origin: eight corners measured from a node, and the node placed in the room. So far every node has stood still. Here three of those cubes, stretched into bars, hang from one another as a limb, and each joint turns a little every frame. It is the first body of the course that moves by itself. Three ideas make it work: a node's transform, its basis, and delta.

In the hall, [the reading](../../../../commons/maps/Trans_Rotation/final.md) starts at a blade that "stays attached to its middle while its ends sweep across the gap. Follow one end. The other moves away." The middle is the blade's pivot. One hall on, [The Body](../../../../commons/maps/Trans_Body/final.md) holds a block of small cubes that gives way where a visitor walks: "Moving a cube would leave it somewhere. Here, the count changes." This study has a small lattice of its own, and the limb's toe is its visitor.

This study takes two sessions. The first builds the chain, makes it move and lets it cut the lattice. It ends at **Stop here**. The second asks where a pivot sits, stretches a joint, and carries the limb.

Every message and number on this page comes from running the study in Godot 4.6. Parts marked *(editor)* describe the editor's own windows and were not watched.

## Open the study

Open the [Organism study](README.md), then `organism.tscn`. It inherits `cube.tscn`, the finished Cube study. The root still runs `plane.gd`, the cube stands where it stood, and the walk, Enter, F, the marble on M and the view from below on V are the ones we left there. There are no new keys.

`organism.tscn` adds one node, `Organism`, with two things under it:

```
Organism                  runs organism.gd: ours
├── Hip                   a pale point, at (-0.9, 1.12, 0.8)
│   └── Upper             a pin
│       ├── Bar           our cube, stretched, with its Body
│       └── Lower         a pin
│           ├── Bar
│           └── Foot      a pin
│               ├── Bar
│               └── Toe   a pink point
└── Lattice               runs lattice.gd: supplied
    └── Count             a label
```

The limb is not made by code. It is made by nesting: in the Scene dock a node dragged onto another becomes its child *(editor)*. `Upper`, `Lower` and `Foot` are the joints, each drawn as a thin upright pin. Each has a `Bar`, and each `Bar` runs `cube.gd`, last chapter's script, unchanged.

Run it. On the left an orange limb of three bars curls up like a finger and straightens again. Where its pink toe passes, the blue lattice loses cells, and the label under it counts what is left. After one whole turn, about ten and a half seconds, it reads `55 of 88 cells` and stays there.

`organism.gd` is ours. The download holds the finished version. We will take it apart and build it again.

## Three bars from one cube

Replace everything in `organism.gd` with this:

```gdscript
extends Node3D

func _ready() -> void:
	var bar: Node3D = $Hip/Upper/Bar
	print("corner 6 in the list: ", bar.corners[6])
	print("the bar's transform: ", bar.transform)
	print("corner 6 in the room: ", bar.to_global(bar.corners[6]))
```

Run it. The limb lies still and straight, pointing towards us, and the lattice is whole. The Output panel reads:

```
corner 6 in the list: (0.25, 0.25, 0.25)
the bar's transform: [X: (0.16, 0.0, 0.0), Y: (0.0, 0.16, 0.0), Z: (0.0, 0.0, 0.6), O: (0.0, 0.0, 0.15)]
corner 6 in the room: (-0.86, 1.16, 1.1)
```

The list did not change. Corner 6 is still a quarter of a metre from the middle, in the bar's own numbers. What makes the cube a bar is the node's `transform`: the rule that takes the node's own numbers to its parent's. It holds four vectors. X, Y and Z are the `basis`: where the node's own three directions point, seen from the parent, and how long one unit of each is. O is the origin: the node's `position`.

Here X, Y and Z point where the parent's do, and they are 0.16, 0.16 and 0.6 long. That is the node's `scale`, and it turns a cube of 0.5 m into a bar of 0.08 by 0.08 by 0.3 m. The origin lies 0.15 m along z, half a bar's length, so the bar begins exactly at its parent, the pin.

`to_global()` takes a position in a node's own numbers through every transform above it, as far as the room. Coordinates called the two readings local and world. Here four parents lie between them.

## A child moves with its parent

Replace `_ready()` with this:

```gdscript
func _ready() -> void:
	$Hip/Upper.rotation.y = deg_to_rad(30.0)
	print("foot position ", $Hip/Upper/Lower/Foot.position)
	print("foot global_position ", $Hip/Upper/Lower/Foot.global_position)
```

Run it. The whole limb has swung to the right, as one straight rod, about the hip:

```
foot position (0.0, 0.0, 0.3)
foot global_position (-0.6, 1.12, 1.319615)
```

We turned one node, and three bars, two pins and a toe moved. `rotation.y` is a turn about the node's own upright axis, the line its pin draws. It is counted in radians; `deg_to_rad()` converts from degrees.

`position` is where the foot is seen from its parent, `Lower`: 0.3 m along Lower's z, one bar's length. The turn did not change it. `global_position` is where the foot is in the room. At rest it was (−0.9, 1.12, 1.4). Now it lies 0.6 m from the hip in a new direction, and we can work it out by hand: −0.9 + 0.6 × sin 30° = −0.6, and 0.8 + 0.6 × cos 30° = 1.3196.

Add a second turn under the first:

```gdscript
	$Hip/Upper/Lower.rotation.y = deg_to_rad(30.0)
```

Run it. The limb bends at the knee. The foot's `global_position` is now (−0.490192, 1.12, 1.209808), and its `position` is still (0, 0, 0.3). A turn swings everything below a node around that node's origin: its pivot. We tried five angles on `Lower`: the foot stayed 0.3 m from the knee, and the knee did not move.

Turn the wrong nodes once. Change the two paths to `$Hip/Upper/Bar` and `$Hip/Upper/Lower/Bar` and run. Each bar spins about its own middle, because its corners were measured from there, and the chain comes apart: the two bar ends that met at the knee are 0.155 m apart. The foot has not moved from (−0.9, 1.12, 1.4). Nothing hangs from a `Bar`. Put the two joints back.

## Which way a bar points

Replace `_ready()` with this:

```gdscript
func _ready() -> void:
	$Hip/Upper.rotation.y = deg_to_rad(30.0)
	$Hip/Upper/Lower.rotation.y = deg_to_rad(30.0)
	$Hip/Upper/Lower/Foot.rotation.y = deg_to_rad(30.0)
	var foot: Node3D = $Hip/Upper/Lower/Foot
	print("foot basis.z ", foot.basis.z)
	print("foot global_basis.z ", foot.global_basis.z)
	print("by hand ", foot.global_position + foot.global_basis.z * 0.3)
	print("to_global ", foot.to_global(Vector3(0, -0.13, 0.3)))
	print("the toe ", $Hip/Upper/Lower/Foot/Toe.global_position)
```

Run it. The limb bends like a finger, and its last bar points to the right:

```
foot basis.z (0.5, 0.0, 0.866025)
foot global_basis.z (1.0, 0.0, 0.0)
by hand (-0.190192, 1.12, 1.209808)
to_global (-0.190192, 0.99, 1.209808)
the toe (-0.190192, 0.99, 1.209808)
```

Every bar lies along its joint's z. `basis.z` is that direction seen from the parent: the foot is turned 30 degrees from `Lower`. `global_basis.z` is the same direction seen from the room. Three turns of 30 degrees make 90, so the foot points along +x: (1, 0, 0).

A basis is how we walk along a body. The far end of the foot's bar is the foot's `global_position` and 0.3 m along its `global_basis.z`: the third line. The toe hangs 13 cm lower; its `position` is (0, −0.13, 0.3). `to_global()` does the whole sum, basis and origin, for any position we give it. In the hall's Translation tutorial the same sum is written out as `reference.global_transform.basis * offset_local`.

## It moves by itself

Replace everything in `organism.gd` with this:

```gdscript
extends Node3D

var angle := 0.0

func _process(_delta: float) -> void:
	angle += 0.01
	$Hip/Upper.rotation.y = angle
	$Hip/Upper/Lower.rotation.y = angle
	$Hip/Upper/Lower/Foot.rotation.y = angle
```

Run it. The limb curls up, passes through its own hip, uncurls and begins again. One number drives three joints.

This is Point Zero's counter. Its tutorial said of it: "A hundred updates add a hundred, however long they took." So how fast does the limb turn? That depends on how many frames the computer draws in a second. We ran this script at four frame rates with `second.gd`, which the download includes:

| frames in one second | angle after one second |
| --- | --- |
| 30 | 0.30 rad: 17 degrees |
| 60 | 0.60 rad: 34 degrees |
| 90 | 0.90 rad: 52 degrees |
| 144 | 1.44 rad: 83 degrees |

One script, four limbs. At 90 frames a second, a headset's rate, the limb turns 1.5 times as far as on a screen at 60.

## Seconds, not frames

Add a line above `var angle`, and change two lines of `_process`:

```gdscript
var speed := 0.6   # radians per second
```

```gdscript
func _process(delta: float) -> void:
	angle += speed * delta
```

Run it. On a screen that draws 60 frames a second it looks as it did; on any other it now turns at this speed too. Measured again: after one second the angle was 0.6000 rad at 30, 60, 90 and 144 frames a second, and the toe was at the same place in all four runs, (−0.159, 0.99, 1.088).

`delta` is the time the last frame took, in seconds. Godot has handed it to `_process` since Point Zero, and we left it unused. `speed` is counted per second, so `speed * delta` is the share of the turn that belongs to this frame: many small shares at 144, fewer and larger ones at 30, the same sum. `mover.gd` has moved B this way since Trace. The hall's pickup turns by `rotate_y(rotation_speed * delta)`.

## Tell the lattice where the toe is

`lattice.gd` is supplied, and we use it without opening it. Its contract is one sentence: `carve(at)` takes a position in the room, removes every cell within 0.16 m of it, measured along the floor, and returns how many cells that removed. The limb slides 4 cm above the cells; only the toe dips in.

Add one line at the end of `_process`:

```gdscript
	$Lattice.carve($Hip/Upper/Lower/Foot/Toe.position)
```

Predict before you run: where will the cut be?

Run it. At once the label reads `82 of 88 cells`. Six cells are gone from the far side of the lattice, where the limb never comes. Then the toe sweeps through the cells and nothing more happens. In a whole turn the count stays at 82. Godot reports nothing.

Ask what we told the lattice. For one run, add `print($Hip/Upper/Lower/Foot/Toe.position)` under the line. It prints `(0.0, -0.13, 0.3)`, every frame the same. That is the toe seen from the foot, and a turning limb never changes it. Read as a position in the room, it is a spot 0.3 m in front of the middle of the room and 13 cm under the floor. The lattice took the six cells that stand over that spot.

The lattice asked for a position in the room. Change one word:

```gdscript
	$Lattice.carve($Hip/Upper/Lower/Foot/Toe.global_position)
```

Run it. Cells go where the toe passes. After one whole turn the label reads `55 of 88 cells`: 33 cells lost, none of them one of the six. A second turn takes nothing more: the cut stays. Walk B over the cut and press M: our marble fell through the lattice to the floor, `marble at 0.10 m`. Over cells that were left it came to rest at 1.14 m.

`to_local()` is `to_global()` backwards. The lattice uses it on the position we hand over, to find its own columns and rows.

## Stop here: what we have

This is the end of the first session. Run the study and check five things:

- The limb curls and straightens by itself, once in about ten and a half seconds.
- After one turn the label reads `55 of 88 cells`, and it stays there.
- The cut follows the toe. The far side of the lattice is whole.
- The cube stands where it stood. M with B under it: `marble at 1.71 m`.
- Nothing is printed.

If one of them fails, compare your script with this one:

```gdscript
extends Node3D

var speed := 0.6   # radians per second
var angle := 0.0

func _process(delta: float) -> void:
	angle += speed * delta
	$Hip/Upper.rotation.y = angle
	$Hip/Upper/Lower.rotation.y = angle
	$Hip/Upper/Lower/Foot.rotation.y = angle
	$Lattice.carve($Hip/Upper/Lower/Foot/Toe.global_position)
```

## The argument: where does the pivot sit?

So far each pin stands at the near end of its bar. Add four lines above `var speed`:

```gdscript
# 0 at the end   1 at one third   2 at the centre   3 outside
@export_enum("at the end", "at one third", "at the centre", "outside") var pivot := 0

var fractions := [0.0, 1.0 / 3.0, 0.5, -0.5]
var length := 0.3   # metres: one bar
```

and a `_ready()` above `_process`:

```gdscript
func _ready() -> void:
	var slide: float = fractions[pivot] * length
	$Hip/Upper.position.z = slide
	$Hip/Upper/Bar.position.z = length / 2.0 - slide
	$Hip/Upper/Lower/Bar.position.z = length / 2.0 - slide
	$Hip/Upper/Lower/Foot/Bar.position.z = length / 2.0 - slide
	$Hip/Upper/Lower/Foot/Toe.position.z = length - slide
```

The script is now the `organism.gd` in the download. `fractions[pivot]` says how far along its bar each pin stands: at its end, a third of the way, half way, or half a bar's length before the bar begins. Each bar slides back on its pin by `slide`, and the first pin moves forward by as much, so that the three bars rest exactly where they rested before. `Lower` and `Foot` stay one bar's length from their parents. We moved no corner and changed no angle. We moved the origins.

**Write your prediction before you render.** Four limbs: the same three bars in the same place at rest, and every joint turned by the same 30 degrees. Which two will look most alike? In which does the chain stay in one piece? Which takes the most cells in one whole turn? Write it down, with a reason for each.

Then look. Select `Organism`, choose **Pivot** in the Inspector and run *(editor)*. For stills of all four, at rest, at 30 degrees and after a whole turn, run `sheet.gd` as the [README](README.md) says. It brings a camera of its own that looks straight down. This is what our sheet measured:

| `pivot` | toe at 30 degrees (x, z) | gap at the knee | cells lost in one turn |
| --- | --- | --- | --- |
| 0 at the end | (−0.19, 1.21) | none | 33 |
| 1 at one third | (−0.29, 1.31) | 0.052 m | 26 |
| 2 at the centre | (−0.34, 1.36) | 0.078 m | 23 |
| 3 outside | (−0.04, 1.06) | 0.078 m | 45 |

At rest the four stills differ on at most 0.18% of the frame: the pins, and nothing else. At 30 degrees the closest pair is one third and the centre. They differ on 1.27% of the frame from the top and 0.52% from the study's camera. We had expected the end and one third: both, we thought, would bend like a finger. They differ on 1.94% and 0.72%. Only the limb with its pins at the ends bends like a finger. At one third the bars have already parted at every joint, and each swings a short tail behind its pin. At the centre each bar turns on its own middle, like the hall's blade. Outside, the pins stand in the air and the bars travel round them: the limb orbits where the others bend, and it clears almost twice the cells the centre does.

The claim: a body's motion is decided by where its joints are, not by what its parts look like. The parts were the same twelve triangles each, in the same place. The origins they were hung from made four bodies.

## A stretch on a joint

Why does the stretch sit on each `Bar`, and not on the pin? Try it. For one run, set `speed` to `0.0` and `angle` to `deg_to_rad(30.0)`, and add to the end of `_ready()`:

```gdscript
	$Hip/Upper.scale = Vector3(1, 1, 2)
```

Run it. The upper bar is twice as long. The lower bar and the foot are longer too, and they lean: their ends are no longer square. A bar has become a slanted block.

For a number, add this as the last line of `_process` for one run:

```gdscript
	print(rad_to_deg($Hip/Upper/Lower.global_basis.x.angle_to($Hip/Upper/Lower.global_basis.z)))
```

It prints `123.004494272166`, and without the stretch `90.0000025044782`. `angle_to()` gives the angle between two directions. Lower's own x and z stood at a right angle; under a parent stretched along one direction they stand at 123 degrees, and they are 1.32 and 1.80 long. `Lower.scale` still reads (1, 1, 1): the lean is nowhere in Lower's own numbers. A child inherits its parent's whole basis, stretch included, and a stretch seen from a turned child is a shear. An even stretch, (2, 2, 2), kept the right angle.

So we stretch leaves. Nothing hangs from a `Bar` but its `Body`, and a ray sent down from above met that stretched collider at the bar's top, 1.16 m, at rest and after a turn. The editor marks such a body with a warning that begins "With a non-uniform scale this node will probably not function as expected" *(editor)*. Remove the two lines and set `speed` and `angle` back.

## What the organism owes

The first debt is to a ranking. Paul Klee's *Pedagogical Sketchbook* sorts the parts of a moving body into active, medial and passive: brain, tendon, bone. He lays the same three ranks over the sexes of a plant: "Male organs (anthers), active". The scene tree draws that command chain and calls it a hierarchy. The parent moves the child, never the reverse. We placed the foot by hand, `$Hip/Upper/Lower/Foot.global_position = Vector3(0.0, 1.12, 1.0)`: the foot went there, its `position` became (0.9, 0, −0.1), and the knee and the hip stayed where they were. No still shows who commands whom: at rest our four limbs differed by their pins alone. And somebody chose the root. We hung the limb from its hip because that was the first node we made. This chapter teaches that hierarchy. A later one inverts it.

The second debt is to the frame. Frames are not time, and delta is the repair Point Zero left open. But delta repairs the speed, not the sampling. The toe is only somewhere when a frame is drawn. One turn took 33 cells at 144, 60, 30 and 10 frames a second, 32 at 5, and 26 at 3: a slow computer's limb steps over cells a fast one's takes. And a frame is not even one length. A run fixed at 30 frames a second began with frames of 0.025, 0.033, 0.042 and 0.029 s before it settled.

The third debt is the lattice's. It keeps the cut and not the reason. Sixteen centimetres of reach were chosen for it, as in the hall, and the record is whole cells: present or absent.

## Become it

The place this chapter asks for is to become the limb: attach the chain to your hand in a headset, or to the carried point, and walk it through the lattice, cutting a passage with your own movement.

On the desktop the carried point is B. Add one line at the top of `_process`:

```gdscript
	$Hip.position = $"../B".position
```

and set `speed` to `0.0`. Two dots step up to the parent, as in a folder path, and the quotes hold the path together. Run it. The hip sits on B and the limb points towards us. Hold A: B carries the limb to the left, and the toe ploughs through the lattice. In our run, with A held for about two seconds, the label read `72 of 88 cells`: a straight passage of 16 cells, two rows wide, from side to side. A marble dropped over the passage reached the floor. We moved one node, and the thirteen below it followed.

Set `speed` back to `0.6` and walk again: now two movements add up, ours and the limb's own.

Here is what was not checked. No headset was used, and no hand: B moves at one height and on four keys. Whether cutting with your own arm feels like becoming the limb, this study cannot say. In the hall the lattice stops a body at its solid cells; here the limb has no weight and passes through anything.

## Try

Give the joints different speeds: `2.0 * angle` for `Lower`. One turn took 41 cells in our run.

Turn `Upper` alone. The limb is a rod, and it took 34 cells.

Make `speed` negative. Before you run: which cells will go? Ours took the same 33, in the other order.

Replace the three `rotation.y` lines by `rotate_y(speed * delta)` on each joint. What becomes of `angle`?

Set **Pivot** to `outside`, and carry the limb with B.

## In your room

Give one body in your room a jointed part that moves.

Copy `room.tscn`, `room.gd` and `my_plane.tres` from your Cube folder into this one. In `room.tscn`, select `Cube` and copy it. Add a `Node3D` under `Cube`, name it `Joint`, and give it the position (0, 0.29, 0). Select `Joint` and paste; name the copy `Arm`, and give it the position (0, 0, 0.15) and the scale (0.16, 0.16, 0.6) *(editor)*. In `room.gd`, change `_delta` to `delta` and add one line at the top of `_process`:

```gdscript
	$Cube/Joint.rotation.y += 0.6 * delta
```

Run `room.tscn`. We made the same room by writing its scene file. An arm lies on the cube and turns like a clock's hand; in one second its far end went from (1.05, 1.66, 0.9) to (1.22, 1.66, 0.85). Drop the marble on the cube. With the arm held still, ours stayed on the top at 1.72 m. With the arm turning, the arm came round, pushed it off, and it ended on the floor.

Your room so far: the plane you walked, three points, one line, the repaired cube, and one part that moves. Decide where its pivot sits before you run, and say what it sweeps.

## What we borrowed

| Part | From | How far we go |
| --- | --- | --- |
| `cube.tscn` and all it inherits | Point Cube | Inherited. The root runs `plane.gd` unchanged. |
| `cube.gd` | Point Cube | Ours, unchanged. It now runs four times: on `Cube` and on three bars. |
| `Marble`, `Under` | Point Plane | Use: M drops, V looks. |
| `Hip`, the pins, `Toe`, and the nesting | Supplied in `organism.tscn` | Use: we turn the pins and move origins. Saving parts as scenes is the next chapter. |
| `Lattice`, `lattice.gd`, `Count` | Supplied here | Use: `carve(at)` takes a position in the room, removes the cells within 0.16 m of it along the floor, and returns how many. Its two loops and its cells made in code are opened in the chessboard chapter. |
| `second.gd`, `organism_frames.gd` | Supplied here | Use: one second at a frame rate of your choice, with and without delta. |
| `sheet.gd` | Supplied here | Use: it renders the four values of `pivot` and measures them. |

What we made is `organism.gd`: one angle that grows by `speed * delta`, three joints turned by it, one line that tells the lattice where the toe is in the room, and an axis that moves the origins.

## What we carry forward

We leave with a chain of nodes in which a parent's turn swings everything below it; with `position` and `global_position` told apart, and `to_global()` between them; with a basis read as a direction; with delta; and with one rule: stretch leaves, not joints.

The next stop, *A body of parts: the first assemblage*, saves what we have made so far as scenes, the point, the plane, the cube and this limb, and instances them under one root. The limb goes there as it stands here: one node, `Hip`, with its whole chain below it. Move that root and everything follows. We have just done it with B.
