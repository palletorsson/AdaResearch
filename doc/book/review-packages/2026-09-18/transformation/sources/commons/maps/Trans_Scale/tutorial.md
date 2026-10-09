# What changed enough to let you through?

Enter the room and inspect the tiny door beside the standing figure. Try it before taking the bottle. Look at the food tower's plates and at the distance between the table and the figure.

Take the DRINK ME bottle on the top plate: VR grip/pickup, or the museum's desktop right-button carry gesture. The room changes size in a cut, and your next position is on the enlarged table. You do not see the sizes between. Find the figure and door again before descending the porcelain steps.

Only after comparing the two views, inspect the implementation:

```gdscript
room.scale = Vector3.ONE * FACTOR
var feet := table.to_global(landings[0]) + Vector3.UP*0.08
```

The first line multiplies the room and its children's dimensions and relative positions. The second computes the arrival point; moving the body is a separate operation. `FACTOR` is four. The assignment changes the scale at once. After a physics frame, the program relocates the body to the enlarged table; it does not animate growth. The museum, body, gravity and walking speed are outside that multiplication.

Descend the serving plates and walk out of the room through the former tiny door. It has changed from 0.45 by 0.60 metres to 1.8 by 2.4 metres. Pass through the equally sized gold frame beyond it: that frame remained fixed throughout. Then turn toward the museum exit. The fixed wall at the room entrance makes this a route through the experiment; it does not scale with the room. Which proportions survived? Which distances became tasks? If the body and its movement had also scaled, would the door have become usable?
