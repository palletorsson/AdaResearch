The transport cube could carry you sideways while you kept looking ahead. Its journey and its facing were different things.

Here, follow an edge as it turns. Where does it go? What stays in place?

<!-- @rotation_wall_crossings -->

Three crossings wait in the first court. Each uses a panel with the same dimensions: 3.6 metres long, 1.2 metres wide, twenty centimetres thick. The mounting is different at each crossing. So are the axis and the position of the banks. Look for the coloured axis line before you try the passage.

At the green Y station, the panel lies flat. It begins across your direction of travel. Wait through its turn, watching one end approach the far bank. At ninety degrees it holds for six seconds. Walk across while it is still.

The centre has stayed where it was. The ends have travelled around it. That movement has put a length where your route needed one.

At the orange X station, the panel stands upright. The hinge runs across its lower edge. Watch the top descend and move forward together. The surface that faced you becomes the surface under your feet.

Cross when it has lowered. This time, the long edge has travelled through a vertical arc. The hinge stayed beside the near bank, and the panel reached towards the other one.

The blue Z station turns the question sideways. Go to the bank beside its bottom hinge. The panel stands up beside you, then lowers towards the opposite bank. Follow the far edge before crossing during the pause.

All three can make a passage. But an axis name alone did not make any of them work. The green panel was mounted flat about its centre; the other two stood upright on bottom hinges. Their banks were placed where the lowered panels could reach.

What would happen if you kept the banks and moved the hinge? Or made the same panel turn the other way?

The script applies each station's angle around its declared axis:

```gdscript
station.pivot.basis = Basis(
    station.axis,
    deg_to_rad(angle * float(station.sign))
)
```

The panel and its collision body are children of that pivot. Turning the parent turns both. The sign chooses the sense of the turn; the pivot's position chooses where the axis passes through the scene.

A wall becoming a floor is more than an image changing its attitude. Its physical surface must arrive where a body can step onto it. A small error at the bank can leave a ledge or a gap even when the drawing looks convincing.

<!-- @ -->

Leave the three crossings and reach the broad, still landing. The next study starts from a different arrangement.

<!-- @rotation_array_compare -->

Two rows of five cubes lie across two gaps. The rows have the same spacing. Each cube carries a number and a yellow mark along one edge.

Watch the row marked EACH CUBE first. The marks turn. Follow the centre of cube one, then cube five. Have their places changed?

Each cube receives the same rotation around its own centre:

```gdscript
for cube: Node3D in bays[0].cubes:
    cube.basis = turn
```

Their positions in the row stay fixed. At ninety degrees a square top fits its old outline again. The mark lets you see a turn that the outline alone would conceal. Five rotations have happened, but the row still lies across the route.

Now watch the row marked WHOLE ARRAY. Follow the numbered cubes through the same angle.

Here the code turns their shared parent:

```gdscript
bays[1].group.basis = turn
```

The middle cube stays at the pivot. The others travel around it. Each keeps its place within the array while changing its place relative to the room.

At ninety degrees the whole row reaches between the banks. Cross during its pause. The five cubes have become a way through by turning as one arrangement.

The two rows received the same angle around y. What differed was where the operation acted: on each cube, or on the parent that holds their relations. In one case the individual centres stayed; in the other, most of them moved. The surrounding floor did neither.

<!-- @ -->

Look back from the last landing. We have changed which banks a body can walk between by changing the orientation of a surface or an arrangement.

The solid panel has not been cut or joined. A rigid turn preserves its topology. Yet its meeting with the banks can connect places that were separated for the walker. That is the distinction we can investigate here: the form of the object, and the connections available through the space it occupies.

The pause will end. A passage can belong to a particular angle and a particular moment. There are more turns to try than this walk can hold.

Carry these two questions into the next hall: where does the axis pass, and what belongs to the thing being turned?
