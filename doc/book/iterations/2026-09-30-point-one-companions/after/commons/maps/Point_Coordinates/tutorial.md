# Point Coordinates — carry a position

Point One separated a position, its surface and its physical boundary. Begin this room by taking the black sphere. The label stays behind. The point now follows a hand.

## Borrow a working hold

The museum uses the supplied `point_held.tscn`. Inside it is the existing XR Tools pickable point. It already knows how to receive a grab, follow its holder and be released. We can use that relation before writing it ourselves.

Carry it sideways, lift it, then bring it towards you. The point remains one body while its address changes. Holding supplies the movement we are about to read.

In an already configured Ada XR scene, instance `commons/primitives/point/point_held.tscn` under the room root. Keep its scale at one and put its root on the floor; the wrapper places the sphere at hand height. Run with the prepared player and use its existing grab input. In a practice scene without the museum cards, make a second instance somewhere else to try the same interaction again. Do not add a second player or rebuild the controller here. The `point_one_main` identity belongs to the museum's reporting link, not to the generic act of grabbing; only the original point should use that reporting channel when working with the museum's cards.

The separate [coordinate study](../../../doc/book/studies/point-coordinates/README.md) supplies the following desktop exercises. It does not include an XR player or reproduce the museum's pickup. A self-contained portable XR starter remains to be supplied; the in-project exercise above uses Ada's installed player and add-on.

## Change one component

The desktop study opens with two prepared sphere markers and red, green and blue guides for X, Y and Z. The museum uses pink, grey and black; the letters and directions identify the references in either palette. Open `points.gd`. The position called `a` is:

```gdscript
var a := Vector3(-0.75, 1.12, 0.0)
```

The numbers are X, Y and Z. Change only `1.12` to `1.7`. Marker A rises. Restore it, then change `-0.75` to `-1.2`. It moves along another direction. Change the last number to `0.5` and watch it move along the blue guide.

The guide does not move the point. It gives us a direction with which to read the change. We borrow its construction.

The supplied script places the marker with:

```gdscript
$A.position = a
```

`$A` finds the child node named A in this scene. `position` is its position relative to its parent. We are giving a visible body the three numbers we kept under a name.

## One body, two addresses

In the museum, compare WORLD and LOCAL while moving the same black point. WORLD reads its position in the scene. LOCAL describes it relative to the coloured frame. A different reference can give the same place different numbers.

In the desktop study, select the root `CoordinateStudy`. Its parent is the scene's world. Change the root's X position in the Inspector to `2.0`, then run. Both markers and their guides move together. The value of `a` in the script has not changed.

These two lines are already in `points.gd`:

```gdscript
print("local ", $A.position)
print("world ", $A.global_position)
```

Read the output. The first address is still `a`; the second includes the parent's shift. Return the root's X position to zero. We can now change a point within its frame, or move the frame that contains it. The later Transformation sequence will make more of that distinction.

The view may look unchanged: the supplied camera also belongs to that root and travels with it. The world address can change while the relation between camera and point stays the same.

The museum cards round their numbers for display. Their apparent stillness during a tiny movement does not mean the point stopped. Reporting is another attachment to the position, with its own limits.

## Keep another position

The next line in the supplied script gives B its own address:

```gdscript
var b := Vector3(0.75, 1.12, 0.0)
```

Change B while leaving A alone. Then give B the same three numbers as A. One sphere may hide the other; the scene still contains two markers. Restore their separation.

We leave with two positions we can change independently and a reason to name their reference. Point Lines will connect them and introduce distance. The target in this room already uses a distance threshold. It asks whether a position is close enough, not whether two objects have the same identity. We can enjoy its falling response before calculating distance in Lines.
