# Follow an edge, then follow a centre

At the first court, identify each coloured axis before watching a turn. Predict which bank the panel will reach. Try the crossing when the panel holds flat. Compare the centre-mounted y swing with the bottom-hinged x and z panels. What changed besides the axis?

The pivot node fixes where the axis passes. Its child panel supplies the surface. Turning the pivot turns the visible mesh and the collision body together:

```gdscript
station.pivot.basis = Basis(station.axis,deg_to_rad(angle*float(station.sign)))
```

Reach the broad landing before starting the second comparison. Follow the centres of cubes one and five in EACH CUBE, then in WHOLE ARRAY. Both rows receive the same y angle. Predict which row will align with the far bank.

```gdscript
var turn := Basis(Vector3.UP,deg_to_rad(angle))
for cube: Node3D in bays[0].cubes:
    cube.basis = turn
bays[1].group.basis = turn
```

The loop changes five local orientations while their centres stay fixed. The last line changes one parent orientation and moves the noncentral cubes around its origin. Local positions can stay unchanged while world positions move.

Return to what you walked: the solid kept its form, but its relation with the banks changed. An angle needs an axis and a location; a rotation also needs a decision about which object or grouping receives it. `technical.md` records dimensions and endpoint tests; `final.md` carries the book's walking voice.
