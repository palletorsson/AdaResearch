## A door, at last

<!-- @scale_me -->

In the rotation hall, you tried the openings against the size of your body. Here, something waits to be taken.

A figure stands behind a tower of food. Crystal grows through her suit; broad panels lean around her body. The food has begun to flower. Porcelain plates climb above it, and smaller serving plates wind down the side. These are familiar enough to approach, strange enough to keep looking at. In the far wall, beside the figure, a little gold frame surrounds a door.

Try to put yourself through it.

You can see the opening. You can point to the space beyond. Your body will not follow. For the moment, calling it an exit describes somebody else's possibility.

There is a bottle on the highest plate. DRINK ME. Take it.

A cut. Now the plate is under your feet. The figure rises beyond you, her leaning panels large enough to seem architectural. The table has become a place to stand. Look down along the serving plates. What could be read at a glance now asks for a journey.

The bottle is gone. You have not watched the room swell through the sizes between. Everything around it is suddenly four times as large: the food, the figure, the room, the spaces between them. Your body has kept its size. The effect may feel like shrinking. The program has made that feeling by changing the other side of the comparison.

```gdscript
room.scale = Vector3.ONE * FACTOR
```

`FACTOR` is four. The food and the figure belong to `room`, so the same multiplication reaches their positions as well as their dimensions. The figure is farther from the table now. Increasing only their dimensions would have left the distance between them unchanged.

The arrival on the plate is another operation. Scaling the room would not put you there. The program takes the top plate's local position and asks where it has arrived in the enlarged world:

```gdscript
var feet := table.to_global(landings[0]) + Vector3.UP*0.08
```

Then it moves your body to that position. The multiplication and the relocation arrive together as an encounter, but they do different work. One changes the room; the other chooses where you meet it again. A small clearance keeps your feet out of the porcelain.

Follow the plates down. Their winding descent was already present when they were small. Nothing in their arrangement needed to be invented after you took the bottle. Yet the distance from one to the next now belongs to balance, gravity and the time spent falling. The program did not multiply your walking speed or the gravity with the room. Uniform scaling has left a very uneven experience.

Find the little door again. It was forty-five centimetres wide and sixty high. Now it is 1.8 metres wide and 2.4 high. Walk through.

Just beyond it stands a second gold frame, also 1.8 metres wide and 2.4 high. Pass through that one too. It stood at this size before you took the bottle.

![The tiny gold doorway and its enlarged version viewed from the same standing height and distance.](/book-review/doc/book/iterations/2026-09-23-scale-door-and-body/door-and-body.png)

*The camera stays 1.65 metres above the floor and 2.5 metres from the opening in both views. On the right, the second gold frame beyond the doorway has stayed at its original size.*

The little doorway has kept its proportions. There is a difference between preserving a shape and preserving what someone can do there. If the bottle had enlarged you by the same factor, would that doorway have become an exit?

The figure has not become hostile by becoming enormous. Her unfamiliar body remains with you through the change. The same is true of the food: its strangeness preceded its usefulness as a landscape. You can learn a route through something without exhausting what it is.

Beyond the two frames, turn toward the museum's own exit. The little door has brought you out of the furnished room; there is still a short walk to the next hall. The museum continues at its ordinary scale. The second frame belongs to it. That boundary belongs to the code too: this room was chosen as the thing that could grow. The next hall returns the question to the body that made the comparison possible.

<!-- @ -->
