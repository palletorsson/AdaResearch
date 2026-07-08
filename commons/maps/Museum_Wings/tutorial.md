# Tutorial — Museum_Wings

## Claim
A wall is an edge, not a cell. Declaring walls on cell edges — with doorways as exceptions — turns a floor plate into a floor plan.

## Idea
The new `layers.walls` grid holds a code per cell: letters n/e/s/w put a solid wall on that edge; an UPPERCASE letter puts a doorway in it. Shared edges dedupe (your "e" is your neighbor's "w"). The component builds collidable segments; the pathfinder blocks blocked edges and passes doors. Rooms, wings, streets — all from strings.

## Code
```json
"walls": [
  ["", "n",  "n",  "N",  "n"  ],
  ["", "w",  "",   "",   "e"  ],
  ["", "w",  "",   "",   "E"  ],
  ["", "sw", "s",  "S",  "se" ]
]
```
One room: solid north wall with a doorway (N), solid west, east wall with a doorway (E), solid south with a doorway (S).

## Try
1. Stand in the street and look down its length — the anchor gallery closes the axis. Count the four doorways you can see without moving.
2. Enter a wing and notice what happened to the other three: walls are the game's way of making attention finite.
3. Walk the cross corridor behind the wings — the service route, the museum's backstage.
4. Find the wing whose theme you'd re-hang. The walls are JSON; re-hanging is an edit.
