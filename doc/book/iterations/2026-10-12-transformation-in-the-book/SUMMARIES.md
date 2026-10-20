# Transformation — seven lessons in sequence

12 October 2026. Current canonical tutorials; existing museum host. Full code and fresh evidence accompany this reading.

## Trans_Pre — A cube that moves, turns and grows

Continue the cube shape from Primitives using one whole BoxMesh. Add a steady rise, a turn and a uniform pulse; compare what each operation changes. Elapsed time supplies the changing pose. Create an Area3D and connect its body_entered signal so walking into the cube collects it. The prepared museum supplies the player. Vary the period and explain why only rise and pulse slow down. Carry the box construction, three transforms and overlap collection onward.

**Short AI:** BoxMesh → rise → turn → pulse → overlap collection. Keep mesh. Supply museum player. Vary period; turn rate stays fixed. Carry transforms + sensor.

## Trans_Introduction — Three ways to make a crossing

Reuse the BoxMesh construction in three visual models beside the installed crossings. A returning box function creates independent parts. One bounded fraction moves a platform, grows a cube and turns a plank. Hold the near, halfway and far poses before watching the return. Move the far bank while leaving the transform unchanged and inspect the remaining gap. The models do not carry a rider; use the installed crossings for standing. Carry interpolation and the relation between a changed body and the place it must reach.

**Short AI:** Reuse box. Return instances from function. One fraction → move/grow/turn. Hold poses; move bank. Models visual; installed crossings supply riding. Carry interpolation.

## Trans_Translation — A level body on a sloping journey

Keep the travelling box and choose two positions in the study's local frame. Interpolate between them while retaining orientation and size. A condition selects either the direct diagonal or a two-part journey through a corner. Compare the intermediate positions and shared destination, including the different speeds produced by equal time for unequal legs. Change the destination along Z and predict the result. Recall Trace: positions previously recorded movement; here chosen positions prescribe it. Carry control over displacement and journey into Rotation.

**Short AI:** Keep box level. Two endpoints + lerp; branch via corner. Same finish, different journey/speed. Recall Trace's ordered positions. Carry displacement versus route.

## Trans_Rotation — Give the turn a centre

Keep the box and clock, remove the translation route and place the box under a pivot. Use a face mark to distinguish a returning outline from a returned orientation. Convert degrees to radians for the chosen axis. Offset the child to turn spinning into an orbit: its local position stays fixed while its world position changes. Change the axis and predict the quarter-turn. The museum's rider support remains supplied. Carry the parent-child relation and the importance of the origin into Scale.

**Short AI:** Box under pivot + face mark. Axis/angle; degrees → radians. Offset child: fixed local position, moving world position. Carry origin + hierarchy.

## Trans_Scale — Enlarge the opening, keep the witness

Return to the parent-child relation with three boxes forming a doorway. Keep a fixed black sphere mesh outside that parent as a size witness; it is not the grabbable PointBody. Compare uniform enlargement with width-only scale. Predict the opening while local mesh dimensions remain fixed and world dimensions change. The threshold origin keeps the posts on the floor. This model has no blocking collision; the installed enlarged room supplies the bodily comparison. Carry a deliberate scale factor into a response chosen by approach.

**Short AI:** Three boxes under doorway parent; fixed sphere mesh outside. Uniform versus unequal scale; local/world dimensions; origin at floor. No model collision. Carry factor.

## Trans_Body — Let your approach choose the transform

Return to one familiar box and replace the chosen scale factor with the horizontal world-space distance to the supplied museum body. Map a near/far range to a bounded fraction, then use it to shrink the box while keeping its base on the floor. Use the same input to turn the box instead. Predict near, midpoint and far responses, then extend the reach. Departure restores the pose, unlike Trace's kept positions or the installed lattice's retained cut. Carry a bodily input into a combined opening.

**Short AI:** World horizontal distance → bounded closeness → scale or turn. Keep base on floor. Return on departure; no history. Contrast retained cut. Carry bodily input.

## Trans_Pit — Make room with three operations

Combine two familiar boxes, a fixed frame and Pre's detection area into a solid opening. Continuing player overlap chooses a target; a bounded progress value moves, turns and shrinks both leaves over physics time. Match visible size and collision dimensions. Use aligned arrays of references to update each leaf while leaving the frame fixed. Vary duration and sideways travel, and inspect intermediate clearance. Keep this composition; Arrays returns to Pre's still collectible cube, gives copies addresses and retains the other addresses after collection.

**Short AI:** Two solid leaves + fixed frame + overlap. Progress → move/turn/shrink; resize collision with mesh. Arrays align parts by index. Next: still Pre cubes, address + retained presence.

## Into Arrays

Return to Trans_Pre’s still BoxMesh pickups; assign addresses and retain presence after collection. Arrays remains the next sequence to reconcile.
