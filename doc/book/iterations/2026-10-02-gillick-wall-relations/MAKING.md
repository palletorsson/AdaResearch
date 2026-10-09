# A rule for the space between

These are original studies, with their gallery and controller supplied. The making return fits Colour / Color_Walls after Line, Coordinates, Transformation and Array. It adds no compulsory capability node. The first exercise uses only the spacing rule; the other structures can stay available for looking.

## 1. Keep 24 bars; change their pitch

The working component places each bar with:

```gdscript
intervals[i].position.x = (i - 11.5) * spacing
```

There are 24 indices, 0–23; subtracting their midpoint keeps the group centred. The controls change the distance between centres from 0.11 to 0.21 metres. The bars are 0.072 metres wide, so the actual gaps change from 0.038 to 0.138 metres.

Choose Tight intervals and Open intervals from the same view. The colours and bar dimensions stay fixed. A first student edit is a third spacing, `set_spacing(0.16)`. Predict the span before running it: 23 intervals plus one bar width. Does the result read as a surface or as separate members?

## 2. Let the third coordinate speak

Six horizontal members and six vertical members form the second study. The depth control changes the vertical members only:

```gdscript
for bar in uprights:
    bar.position.z = projection
```

Positive local Z points away from the wall. Their centres move from 0.18 to 0.52 metres from the study's origin. Their local X/Y coordinates, dimensions and colours stay fixed. The rendered perspective and shadows can still change. Compare the two frontal views, then choose Oblique.

The horizontal front faces meet the vertical back faces in the shallow configuration. Pulling the verticals forward separates them. This is a kinematic composition, not a load-bearing or joint simulation.

## 3. Leave one address empty

The final composition uses twelve supplied segments. Omit one rail hides the top segment and disables its collider. It remains in the array, ready to return at the same address.

```gdscript
rails[5].visible = not omitted
```

That is the visual decision. The working implementation also sets that rail's collision layer to zero while it is absent, and restores it to one when it returns. Hiding a mesh alone would leave an invisible obstacle. The rest of the wall is still solid.

Changing visibility here does not introduce Boolean mesh cutting or a graph solver. The sparse composition is built from straight segments, with a small front groove suggesting an extrusion. Its engineering cross-section is not reconstructed.

## Independent colour and supplied apparatus

Sequence repeats the six-colour palette. Groups assigns four successive indices to a colour; All pink assigns one material colour to every bar. These controls leave transforms untouched. Colour order restarts within each study's member list.

The component is `res://commons/artifacts/colour_wall_studies/colour_wall_studies.tscn`; the separate gallery is `study.tscn` in the same directory. Its viewer borrows the previous panel study's desktop walker. Lights, shadows, camera choices, collision setup and GUI construction are supplied apparatus rather than all being lessons at once.

[Download the portable Godot 4.6 project](wall-relations-study.zip). Import `project.godot` and run. Walk uses WASD and mouse; Escape releases the pointer. Step back from the wall before changing its geometry. Reset restores the initial geometry, colours and overview. Physical headset input and learner acceptance have not been tested.
