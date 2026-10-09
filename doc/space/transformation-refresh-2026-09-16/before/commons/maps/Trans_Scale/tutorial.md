# What changed enough to let you through?

Enter the room and inspect the tiny door beside the standing figure. Try it before taking the bottle. Look at the food tower's plates and at the distance between the table and the figure.

Take the DRINK ME bottle on the top plate: VR grip/pickup, or the museum's desktop right-button carry gesture. Your next position is on the enlarged table. Find the figure and door again before descending the porcelain steps.

Only after comparing the two views, inspect the implementation:

```gdscript
room.scale = Vector3.ONE * FACTOR
var feet := table.to_global(landings[0]) + Vector3.UP*0.08
```

The first line multiplies the room and its children's dimensions and relative positions. The second computes the arrival point; moving the body is a separate operation. FACTOR is ten. The museum, body, gravity and walking speed are outside that multiplication.

Descend the serving plates and walk out through the former tiny door. Which proportions survived? Which distances became tasks? If the body and its movement had also scaled, would the door have become usable?
