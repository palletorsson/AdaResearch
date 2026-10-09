# Transformation — the reflective sequence

6 October 2026 · Revised drafts for paired reading and independent review. Repeated procedural explanations have been shortened. These revisions have not replaced the canonical manuscripts.



---

<!-- hall:Trans_Pre -->

# What survives its movement?

In Melencolia, the pyramids stayed still while your viewpoint changed. Here, stay a moment and let an object change in front of you. What survives its movement?

The cubes are black, white and gray. Light catches an edge; a shadow changes as a face turns. Four cubes are spaced down the middle of the hall. Smaller markers stand beside the row. Beyond the cubes, wedges lead up to a raised path. Here we can follow how a game pickup gets its animation.

<!-- @pick_up_cube -->

The first cube holds still. Pause before approaching and watch a corner: nothing shifts. Then walk into it: even without an animation, it can be collected. Keep its shape in mind as you go to the next one.

This cube moves up and down. Follow it through a complete rise and fall. Its position changes while its size and facing stay the same. Moving an object from one position to another is **translation**. Here that movement follows the vertical Y direction.

Each rise and fall takes it through the same heights, at a steady speed on each leg. At the top and bottom it reverses. The shape has kept its dimensions while its place changes.

The third cube keeps moving up and down. What has been added?

Follow a corner. The cube turns as well. Changing its orientation — which way it faces — is **rotation**. This line adds a small turn around the upright Y axis on each update:

```gdscript
rotate_y(rotation_speed * delta)
```

The turn keeps pace with elapsed time. A longer interval between updates calls for a larger turn.

The rise and the turn continue together. Follow the same corner once more: it travels around the upright axis as well as up and down.

At the fourth cube, watch the edges move apart and come together. It grows and shrinks while it rises and turns. Changing size is **scale**.

Its size moves between 0.7 and 1.3 times the starting size. All three dimensions change together, so it keeps its cube shape.

Beside each moving example, a smaller marker isolates the operation just added: one moves up and down, one turns in place, one grows and shrinks. They let us separate movements that the larger cubes combine.

Look back along the four stations. The still cube has gone if you collected it; the three moving examples remain.

Walk up the wedges. Four more cubes wait above the raised path, rising, turning and changing size. Pick one to approach. As you walk into it, it swells briefly and disappears with a pickup sound. The others keep moving.

The three moving demonstrations behind you stay in place for another look.

Translation kept its size and facing. Turning kept the distances between its corners. Multiplying all three dimensions by the same factor kept its proportions. Each operation has left something to recognise. The next hall asks which of these changes can give us somewhere to stand.

<!-- @ -->



---

<!-- hall:Trans_Introduction -->

# The far bank is already there

In the previous hall, a cube learned to rise, turn and swell. You could watch those movements, walk around them, leave them running.

Here the floor is missing. Fire glows at the bottom of the basins. If you fall into the fire, you die. The museum returns you to a save point, and you can try the crossing again.

Stand at the first gap. Look across, then down. The far side is already there. What would have to change for it to become somewhere you can go?

<!-- @tc -->

A cube travels between the banks. Let it make a journey without you. Its top meets the floor at each end; between them, it is a small piece of floor with nothing beside it.

Step onto it when it returns. Watch the bank you left. Now look down at the cube.

Relative to the room, you are moving. Relative to the cube, you may be standing still.

For each small displacement of the cube, the program moves the supported rider by the same amount. The bank recedes while the surface beneath you stays close. Moving the cube alone would leave you behind.

Step off at the far bank. The cube waits, then goes back. The gap has not closed. You crossed with a temporary surface under your feet.

<!-- @sc -->

At the next gap, a cube grows about a fixed centre below the floor. Watch its upper face rise and its edges approach the banks.

Wait until the surface is level with the floor, then walk across during its pause. Look back as it shrinks. What made a floor a moment ago is withdrawing below it.

The cube grows from half a metre to three metres on each side. Its visible surface and the collision box that supports your feet grow together. What you see arriving becomes something you can stand on.

The centre sits below the floor so that the upper face reaches it at full size. Growth spreads downwards as well as upwards. From the bank, you might notice only the part that arrives to meet you.

The cube keeps its proportions throughout. It is recognisably the same shape when it is too small to carry your walk and when it reaches both banks. Your way across appears and disappears within that sameness.

<!-- @rc -->

The third gap has a thin plank. A control marked MOVE THE BANK stands at the approach. Leave its slider at the starting setting for now and watch a turn before stepping onto the plank. At first the plank lies across your route, its ends pointing to either side. A quarter-turn brings those ends towards the banks.

Cross while it holds that alignment. The same length of plank now reaches the places you need it to reach, with its centre still in the middle of the gap.

The visible plank and its collision body turn together between zero and ninety degrees, with a four-second pause at each end. The plank is three metres long, one metre wide and twenty centimetres thick. Its upper face stays level with the floor; its ends meet the banks when aligned.

From the bank, follow one end with your eyes as it turns away again. The centre stays in place while the end sweeps a curve around it, carrying the edge of your crossing out of reach.

<!-- @ -->

<!-- @adjustable_landing -->

Return to MOVE THE BANK at the near bank. The far landing rests on rails. Slide BANK a little, then watch the plank make its usual turn.

The plank has the same length, the same centre, the same quarter-turn. You have moved the place it needs to reach.

At the starting setting, the aligned plank meets the landing edge to edge. Move the bank and a gap opens between their surfaces. The readout measures how far apart they have become.

![The aligned plank meets the landing at BANK +0.00 m.](/book-review/doc/book/figures/Trans_Introduction/bank-edges-meet.png)

![A gap opens beyond the same plank at BANK +1.00 m.](/book-review/doc/book/figures/Trans_Introduction/bank-full-gap.png)

*The same crossing at two bank settings: meeting edges, then a one-metre gap. The plank holds the same quarter-turn in both views. The camera has not moved.*

Let the plank turn again. An operation that worked a moment ago keeps running exactly as before. The crossing has lost one of its agreements.

The landing travels along its rails, taking its visible surface and support with it. You can move it up to one metre from its starting place. The side aisles let you return to the control while the gap stays open.

<!-- @ -->

Bring the landing back with RESET. The plank has kept making the same turn through both crossings. The bank was part of what made one of them work; giving it a handle lets us find out how.

The travelling cube asks you to board and stay with it. The growing cube asks you to wait until it reaches the banks, then cross before it shrinks. The turning plank gives you a pause in which to cross. A place to stand can also be a moment you have to meet.

The timers keep going while you think. The simulation supplies an opening and a duration. It does not know how long you need to understand what just carried you.

There is more to examine beside the route: measurements, matrices, the order of operations. For now, take the experience of crossing into the next hall, where displacement has more work to do.



---

<!-- hall:Trans_Translation -->

# Translation: seven journeys

The far bank is familiar now. In the last hall, a moving surface carried you across. Here seven carriers link a chain of islands, rising to an upper route and descending again.

Before boarding, follow the small waiting cubes with your eyes. Some hang over the fire basin. Others mark the upper route, beyond the reach of a hand from the floor. The carriers give you a way to meet them.

<!-- @tc -->

The first carrier travels into depth. Step aboard and let the room pass. Look at the cube under your feet: it keeps its facing and size. Along this journey, only its z coordinate changes.

At the next island, the route turns sideways. The carrier moves along x. You can keep looking towards the far end of the hall while travelling across it. Direction of travel and direction of attention have separated.

Then the way goes up.

Stand on the lift and watch the lower landing descend from view. It is still where it was. The carrier changes y; the room gives that change a consequence. You arrive beside an upper platform, three metres above the ground route.

Near the entrance, three small axis markers show x, y and z separately. Along the route, those directions have become sideways travel, a lift and a passage into depth.

A starting position, a direction and a distance determine each destination. Three metres up and three metres forward use the same relation with different directions.

On the upper route, another carrier travels along z. It repeats a direction you have already travelled near the floor. Now you can look down past its edge to the route that brought you here.

A sideways return carries you back across x in the opposite direction. Then the next carrier moves down and forward together, like an escalator. Its surface stays level while its path slopes: three metres down, two metres further along z. Watch the pickup approach as the lower landing comes towards you.

<!-- @pick_up_cube -->

The small pickups have been waiting along these journeys. They rise and fall without turning. Their small vertical loop continues as the carrier brings you into contact with them, and each collected cube disappears with a sound.

Take one, then look back while the carrier moves on.

Each small displacement of the carrier moves your supported body with it. The pickup detects your arrival and disappears. Ride back to its place. The carrier can repeat the journey; the cube is gone.

<!-- @ -->

At the last crossing, the waiting cubes run diagonally over the pit. Watch an edge of the carrier as you travel. It does not turn.

This direction changes x and z together. The destination lies eight metres across and eight metres further into the hall. Both coordinates change during the same journey. We have combined directions without adding rotation.

Thirteen pickups mark this passage through seven rides. By the final terrace, the cubes you collected have left empty places along the route. Another arrangement of carriers and pickups could lead you elsewhere using the same operations.

<!-- @translation_cube_demo -->

Step onto the final terrace. Two pairs of small doors stand on plinths, a left door and a right door in each frame. One pair has rails; the other shows translucent panels where its doors can end up. Try the same upward-and-sideways gesture on a square handle in each frame. A pale line stays behind the moving handle.

At the rail-guided door, the line rises. The sideways part of your gesture has gone missing. Beside it, the other mechanism lets the handle move in both directions together. Its line can cross the opening diagonally.

Lift the guided handle to the corner of its rail, then move it sideways. A bend leads to the place the other handle could reach directly. The translucent panel beside the second door marks its destination. Compare the two handles in their frames: they have the same distance to travel up and across.

The guided door retains the part of a displacement that runs along its current axis:

```gdscript
var t = (knob_pos - start).dot(phase1_dir)
knob_pos = start + phase1_dir * t
```

Here `phase1_dir` points upwards. `.dot()` extracts the part of your movement along that direction; the next line puts the handle there. The full implementation also limits how far it can go.

The trail records the handle after this correction. Your hand can propose a diagonal and leave a vertical line.

In the trace hall, movement left positions behind. Here the handle has already been corrected before its position is kept. The line can be an accurate record of where the handle went without showing everything your hand tried.

Bring the free handle back towards its starting corner, then try a curved route to the translucent panel. The recent lines remain together as you try another way. There is room to take the long way within the frame.

![Two door mechanisms leave different traces for different permitted paths.](/book-review/doc/book/iterations/2026-09-23-translation-paths/translation-paths.png)

*A guided bend, a direct diagonal, and a curved route to the same relative endpoint. Each panel records a separate gesture at the handle.*

Up followed by sideways reaches the same position as sideways followed by up. Translation itself does not impose this order. The first mechanism does. The second gives both freedoms together. A destination can be shared by journeys with very different permissions.

<!-- @ -->

The torus beside the course already turns while its cylinder rises and falls. It offers a glimpse of the next question. Our carriers have kept their facing throughout; this neighbouring object combines the operations. Keep the difference between travelling and facing in mind. In the next hall, the turn itself will become the question.



---

<!-- hall:Trans_Rotation -->

# Rotation: room for a turn

The transport cube carried you without needing to turn. Here, a blade stays attached to its middle while its ends sweep across the gap. Follow one end. The other moves away.

<!-- @rotation_wall_crossings -->

## Staying upright

The level blade turns around the vertical y axis. At ninety degrees it pauses, its length reaching across your route. Walk over while the crossing holds.

At the X-axis blade, one end descends as the other rises. It turns around x, like a paddle wheel. The far landing is three grid cubes higher. During the pause, the blade offers a slope you can climb. Through vertical, your feet lose their agreement with it.

Beside its lower end is a small level platform. Board it and stay through the turn. You rise, move forward, and arrive beside the higher grid. Your head has stayed upright.

The platform follows an arc while keeping its surface level. It is mounted to one side so the blade can pass through vertical without sweeping through your body. Keeping you upright requires a rule alongside the turn.

The platform carries you until you step off or jump.

The sideways ride's blade turns around z. Board from the left: this ride carries you sideways along x and up. Turning around z cannot advance you along z. The destination is another bank.

Both rides pause for twelve seconds, then take twelve for the half-turn. Staying aboard brings you back along the upper arc. The grid wedges and still aisles offer other returns.

<!-- @ -->

Beyond the blades, the cubes hold their angles. You bring the movement.

<!-- @rotation_array_compare -->

## An angle underfoot

Four bands each contain two columns and six rows of cubes. Begin at zero and walk forward along z.

Eighteen degrees. Thirty-six. Fifty-four.

The centres keep their spacing; each row adds an angle. X makes rises and falls across your route. Z makes ridges along it. Y turns the square footprints while keeping their tops horizontal. The fourth band combines x, then y, then z.

The row supplies the angle; the band supplies the axis or combination. Waiting will not change the slope. The still aisles let you inspect a difficult row from beside it.

A stand in the central aisle starts another walk. Narrow capsules, 0.44 metres wide, set off along all four bands. Wider capsules follow from the same places, now 1.20 metres wide. Their height, speed, gravity and forward instruction stay the same. Rings retain their endpoints; the trial repeats, and **REPLAY** starts it again.

Watch the z band. The narrow body catches on a ridge; the wider one can slide sideways and continue. Wider need not mean less room to move. These bodies neither jump nor choose a detour: the collision solver supplies their slides. You can walk through them and try a route they did not take.

<!-- @ -->

The last row reaches ninety degrees. In the Y band, compare it with the first. The cube's outline returns, but the pale L on its top points another way. That flat-looking row still waits beyond all the tilted ones.

Each cube has kept its shape throughout. What changes is how it meets its neighbours and your body.

<!-- @transform_composition_workbench -->

## Two turns

Beyond the combined band, two finned forms stand beside a pale version of their starting shape. The workbench opens on pair four: thirty degrees around X and forty-five around Y. The left form receives X first; the right receives Y first.

Follow the fin through the smaller intermediate forms. In the two results it points different ways. The display separates the forms for us; both calculations use the same origin.

```gdscript
var left_xform: Transform3D = t2 * t1
var right_xform: Transform3D = t1 * t2
```

The operation on the right acts first. In Translation, upward and sideways movements could exchange order and share a destination. These two turns cannot: the second receives the orientation left by the first.

Move the pair slider to two. A turn and a uniform enlargement now end in the same form whichever comes first. Their intermediate forms still differ. The fin gives you something to follow through both journeys.

<!-- @axial_sweep -->

## What returned?

A small cube turns on a spindle beside the way onward. Follow the pale L on its face. After a quarter-turn, the cube fits the space it occupied before. The marked face has gone around the corner.

What returned depends on what you were following.

![The same cube at zero and ninety degrees, photographed from the same viewpoint. Its outline returns; the marked face moves.](/book-review/doc/book/iterations/2026-09-23-rotation-return-and-sweep/marked-return.png)

*Two paused moments from one place. The mark moves from the left-hand face to the right.*

Press **BOUNDARY**. A cylinder appears around the turn. A corner reaches its round side, then leaves. The contour keeps that place while the corner is elsewhere.

Pause. Part of the cylinder is empty. It describes the outside of all the positions the cube occupies over a full turn. A turn needs room that a single pose leaves empty.

Change **SHAPE** to the triangle. Its upright edge lies on the axle. As the face turns, the wide bottom sweeps a circle and the sloping edge describes a cone. Hide the boundary and follow the sweep with your eyes; bring it back. The outline helps you keep a whole turn in view. It has made no new solid wall.

![The rotating cube inside its cylindrical boundary and the triangular face inside its conical boundary.](/book-review/doc/book/iterations/2026-09-23-rotation-return-and-sweep/spaces-of-a-turn.png)

*In this earlier colour study, the contours describe full turns. Each solid body is paused in one position. The museum now shows these studies in grayscale.*

The triangle from Primitives has acquired another possibility without acquiring another corner.

<!-- @ -->

Walk on into the last court.

<!-- @boolean_tunnel -->

## Inside the turns

Look through the first hollow cube. Four more stand beyond it. Each adds eighteen degrees.

```gdscript
angle_deg = i * rotation_per_segment
```

Subtracting an inner box made each cube hollow. The turns arrange those openings around a continuous floor. Walk inside and follow a corner with your eye.

Five segments occupy fifteen metres. They stand still; your walk unfolds their differences. Turn back and the sequence unwinds.

Which edge did you take for a horizon?

<!-- @carousel_cake -->

Outside the tunnel, the stacks keep turning. Follow a stripe on a low layer, then near the top. Their relations change while you stand still.

The lowest layer turns at half a radian per second; each successive layer turns 1.2 times as fast. In the tunnel, eighteen degrees separated neighbours. Here, speed keeps changing the angle through time.

Eight layers make each of five profiles: a brim, a column, a taper, a pinched spindle, a flare. They share heights and turning speeds. Walk between them and compare the room each leaves around itself.

<!-- @ -->

<!-- study-spine:hinge_release -->

<!-- @hinge_release -->

A small plate waits on a hinge. Turn it; its neighbours travel with it. Release it under KEEP. The pose stays where you left it. Choose RETURN, turn again, then release. The joint moves towards the earlier angle, as if the object had a preferred answer.

The fixed support and stored angles make this an Ada response to Lygia Clark's articulated works. They give us a way to ask what an invitation permits. A joint can be available to your hand while the rule after release quietly takes the last word. Switch on TRACE and watch one corner: two journeys can arrive at the same pose without leaving the same line.

<!-- @ -->

In the next hall, the surroundings change size while your body stays the same. What will fit then?



---

<!-- hall:Trans_Scale -->

# A door, at last

<!-- @scale_me -->

In the rotation hall, you tried the openings against the size of your body. Here, something waits to be taken.

A figure stands behind a tower of food. Crystal grows through her suit; broad panels lean around her body. The food has begun to flower. Porcelain plates climb above it, and smaller serving plates wind down the side. These are familiar enough to approach, strange enough to keep looking at. In the far wall, beside the figure, a little gold frame surrounds a door.

Try to put yourself through it.

You can see the opening. You can point to the space beyond. Your body will not follow. For the moment, calling it an exit describes somebody else's possibility.

There is a bottle on the highest plate. DRINK ME. Take it.

A cut. Now the plate is under your feet. The figure rises beyond you, her leaning panels large enough to seem architectural. The table has become a place to stand. Look down along the serving plates. What could be read at a glance now asks for a journey.

The bottle is gone. You have not watched the room swell through the sizes between. The room and its contents are suddenly four times as large: the food, the figure, the spaces between them. Your body has kept its size. The effect may feel like shrinking. The program has made that feeling by changing the other side of the comparison.

```gdscript
room.scale = Vector3.ONE * FACTOR
```

`FACTOR` is four. The food and the figure belong to `room`, so the same multiplication reaches their positions as well as their dimensions. The figure is farther from the table now. Increasing only their dimensions would have left the distance between them unchanged.

The arrival on the plate is another operation. Scaling the room would not put you there. The program finds the top plate in the enlarged world, then places your feet eight centimetres above it. The room has changed size, and you have been given a new place from which to meet it.

Follow the plates down. Their winding descent was already present when they were small. Nothing in their arrangement needed to be invented after you took the bottle. Yet the distance from one to the next now belongs to balance, gravity and the time spent falling. The program did not multiply your walking speed or the gravity with the room. Uniform scaling has left a very uneven experience.

Find the little door again. It was forty-five centimetres wide and sixty high. Now it is 1.8 metres wide and 2.4 high. Walk through.

Just beyond it stands a second gold frame, also 1.8 metres wide and 2.4 high. Pass through that one too. It stood at this size before you took the bottle.

![The tiny gold doorway and its enlarged version viewed from the same standing height and distance.](/book-review/doc/book/iterations/2026-09-23-scale-door-and-body/door-and-body.png)

*The camera stays 1.65 metres above the floor and 2.5 metres from the opening in both views. On the right, the second gold frame beyond the doorway has stayed at its original size.*

The little doorway has kept its proportions. There is a difference between preserving a shape and preserving what someone can do there. If the bottle had enlarged you by the same factor, would that doorway have become an exit?

The figure has not become hostile by becoming enormous. Her unfamiliar body remains with you through the change. The same is true of the food: its strangeness preceded its usefulness as a landscape. You can learn a route through something without exhausting what it is.

<!-- @ -->

<!-- study-spine:reference_passage -->

<!-- @reference_passage -->

Another wall waits beyond the enlarged room. Its opening changes width; your body stays the same. At the narrow setting the strip on the floor continues through a passage you cannot take. Walk around the wall instead.

The displaced dark disc belongs to this sparse arrangement too. Following the supplied Bałka reference, a few architectural parts make the missing room present. The code can name a clearance. It cannot decide whose body ought to be the measure. Widen the opening and return to the same strip.

<!-- @ -->

Beyond the changing opening, turn toward the museum's own exit. There is still a short walk to the next hall. The museum and its second frame have kept their ordinary size. The code placed the furnished room inside the change and left them outside it. In the next hall, your approach will be enough to make the surroundings respond.

<!-- @ -->



---

<!-- hall:Trans_Body -->

# The Body

The corridor narrows, and then it stops.

<!-- @approach_wall -->

A wall of upright slats stands across the way. There is no handle. Walk towards it.

The slats nearest you turn. Step sideways along the wall and the opening follows; step back and it closes. A doorway has come to meet you.

The opening responds to two distances: along the wall from each slat to you, and out from the wall to where you stand. The response weakens towards the limits of its reach. Neighbouring slats turn with the ones closest to you, making room for more than a point.

Someone has chosen that width, that reach, and which bodies the wall will notice. The invitation has dimensions. Yet you can move its centre along the wall. Your position changes what this arrangement allows.

Pass through and look back. While you are still close, a slat may remain open for you. Go farther and wait. It settles into the wall again. You have crossed the boundary before you have left its attention.

<!-- @carve_grid -->

The next narrow passage holds a block of small cubes, about 1.3 metres high. You can see over it. Your legs still need a way through.

Press forward. A layer gives way, and another waits behind it. The missing cubes leave an open-topped trench. Your eyes had crossed this space before your body could.

Physics stops your body at the solid cells. To let the cut begin, the program gives its removal test a little extra reach:

```gdscript
@export var bite_m: float = 0.16
```

Sixteen centimetres beyond the collision shape used for your body. With cells spaced thirty-four centimetres apart, that margin clears roughly one layer at a time. The next step becomes possible because something has been removed.

Moving a cube would leave it somewhere. Here, the count changes. The lattice loses cells as you advance.

Turn back. The cut stays when you walk away. A return during the same session can reopen the cells kept in memory. Look along the stepped sides: they record where the lattice met your body's collision shape, widened by that small margin. Whole cubes are either present or absent. The record can have no finer edge than the cells that make it.

Some of you passed above the entire record.

![The low cube lattice before a passage and the open-topped cut left by a body, photographed from the same elevated viewpoint.](/book-review/doc/book/iterations/2026-09-23-body-what-remains/the-cut-remains.png)

*The body has left the second view. These elevated views show the missing cells; the opening was made by walking through the block.*

The cut keeps the route without keeping your reason for taking it. Its width includes an allowance you may never have noticed. Somebody following would meet an opening already shaped by another passage. Would their body fit, or would they need to widen it?

<!-- @approach_scale -->

Nine blocks stand ahead. At rest, the gap between neighbours is thirty-five centimetres.

Move closer. The nearest blocks shrink. Continue between them: the opening travels with you.

Each block answers the nearest body within its reach. It shrinks smoothly to about a third of its full size. The visible block and its collision box change together, lowering as they shrink to keep their feet on the floor. Their places in the horizontal grid stay fixed.

All nine blocks are still there. Your distance has become their size.

Look behind you near the last row. Some blocks may still be small. Take a few more steps towards the far end and watch them fill out. You can be through the gap and still be holding it open.

<!-- @ -->

Two boundaries return; one keeps the cut. Looking back finds a wall, a trench, a field of blocks. Each has answered the same approach differently.

The slats and shrinking blocks answer where you are now. The trench keeps a change made by your earlier passage. After you leave, the next visitor can still follow the opening your body made.

In the next room, growing blocks follow a clock. Coming closer will no longer ask them to make room. You will have to find your moment.



---

<!-- hall:Trans_Pit -->

# The Moving Boundary

A wall can arrive on level ground. You can wait beside its path, or step into the space it is about to occupy.

Three rooms in a row: translating blocks, turning slabs, growing cubes. There is a way around the first lanes and room to watch the others from beside them. The ground stays level. An opening can disappear while you stand still.

## Translation, from inside

<!-- @pusher_block -->

Three blocks, each with an arrow on its face. Follow one through a complete journey before entering its path. It travels, stops, returns and stops again. The pause is part of the movement you need to learn.

Each block travels two metres, but they take different times and their pauses differ. Two advance along Z; the third goes the other way. An opening that works for the first does not give you the timing of the next.

The block keeps its dimensions. Standing where it wants to be, you meet a wall that arrives. The displacement that carried you in an earlier hall can also occupy your place. Beside these lanes, open floor lets you walk around.

<!-- @ -->

## Rotation, from inside

<!-- @rc -->

The middle room has two turning slabs. Watch one end while the centre stays put. Each makes a quarter-turn, waits, then reverses. Their different pauses let one begin while the other still holds its place.

The collision follows the visible angle. These upright wall profiles offer a broad face to the route, then a narrow edge. Their dimensions stay the same as the clearance beside them changes. The middle route lets you keep your distance.

Look at the floor just beyond a slab's present edge. It is empty now. Follow the edge into it. The space this slab sweeps through is larger than the space one pose shows. Your place can become part of its turn without you taking a step.

Balls arrive from the side platforms as well. There is more than one clock here, and their movements do not wait for you to finish comparing them.

## Scale, from inside

<!-- @grower_block -->

The last room has three cubes sharing a tempo. Wait before approaching. They grow anyway.

The previous hall's blocks made room when you came close. Here their size follows elapsed time. Walking towards them, standing still and turning away all leave the same clock running.

All three cubes move from thirty centimetres to three and a half metres on a side, then return together. Their shared rhythm leaves different amounts of floor available around them.

![At its smallest, the cube leaves the final door visible down the lane.](/book-review/doc/book/figures/Trans_Pit/growers-small.png)

![At full size, the same cube fills the view from the same position.](/book-review/doc/book/figures/Trans_Pit/growers-large.png)

*The same view at two moments in the cycle. At its smallest, the cube leaves the final door visible beyond it. At its largest, it fills the view. The camera has not moved.*

Watch a bottom edge. It stays on the floor. The mesh and collision box grow together, with their centres kept half a side-length above that edge. Growth takes space upwards and sideways rather than passing through the ground.

As a cube expands, the gap beside it narrows, then widens again. All three axes scale equally, so the cube keeps its proportions. The gap has no such guarantee. Your available space is the remainder after its growth.

<!-- @ -->

## What returns

The block returns to its starting place, the slab to its earlier angle, the cube to its small size. You may still be waiting, or already be on the other side. An object can recover its pose while your encounter with it continues.

Which body can use the opening? Width, pace and the collision shape assigned to you all matter. A gap may admit you before you are ready to cross. There is room here to wait, watch or take the way around.

## Make room

<!-- @transformation_airlock -->

After the growing cubes, two armoured leaves meet inside a heavy frame. These wait for your arrival. Approach, then stop. Follow the bright strip along one leaf.

It moves sideways and up. It turns through a quarter-turn. Then it becomes smaller, drawing its armour into a recess beside the opening. The frame has stayed still. The passage has changed.

![The same door closed, partway through its turn, and fully open with the leaves reduced into their recesses.](/book-review/doc/book/iterations/2026-09-23-moving-boundary/make-room.png)

*Follow the bright meeting strip through the three views. Each leaf moves, turns and becomes smaller; the frame keeps its place. The opening appears before the whole movement is finished.*

The three movements overlap in time. Each leaf turns across the doorway's face and ends at thirty-four percent of its original size. Its collision shape changes with it: the visible opening is also an opening your body can use.

Walk through. The door stays open while someone is near it. Once everyone leaves its clearance area, it waits three seconds and reverses. You can return from the other side and open it again. Its welcome has a reach, a width and a waiting time, each chosen in advance.

These are the same three operations we added to the pickup cube at the beginning of the sequence. There they made a small object conspicuous. Here they make room for you.

<!-- @ -->
