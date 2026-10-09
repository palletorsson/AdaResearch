# A pattern visits an address

<!-- @game_of_life_petri -->

Five green cells wait in the dish. A larger version lies in the floor beyond it. Three lamps stand along its edge. They are dark.

Press STEP four times. The arrangement has changed at every step; now something about it has returned. Compare its position with one of the gold squares. What has travelled?

REPLAY brings the five cells back. This time keep your attention on the square marked A, at address (10,10). Step towards it. A cell becomes occupied; a lamp lights. Step again. Follow the square for a while, even when the more recognisable figure tempts your eye away. The address keeps its place. The pattern is already elsewhere.

You can cross the large display. Its empty cells still support your feet. In the previous room, occupancy became a stepping tile over a lower basin. Here it becomes colour on an ordinary floor. We have carried the array forward and given it another job. A zero does not contain an instruction to make a hole.

Try BLINKER. Three cells lie in a line. One step turns the line; another brings it back. Watch A, the middle cell. The surroundings alternate while this address remains occupied. Its lamp stays lit. Returning, travelling and staying can belong to different parts of the same small event. The names for these, now that you have watched them, are still life, oscillator and spaceship: the block the glider will meet is the first, the blinker the second, the glider the third.

The dish runs Conway's Game of Life.[^ca-conway] Each cell has eight neighbours: the second choice, widened from two. An occupied cell survives with two or three occupied neighbours; an empty cell becomes occupied with exactly three. These are the lines that choose its next state:

```gdscript
if alive:
    _next_grid[y][x] = neighbors == 2 or neighbors == 3
else:
    _next_grid[y][x] = neighbors == 3
```

Every answer goes into another array. Only when the whole plane has been read do the two buffers exchange places. A cell later in the loop cannot borrow an answer made earlier in this generation. At the edges, the neighbourhood wraps to the opposite side.

In the glider beginning, four generations reproduce the arrangement one address further along each axis. No instruction has moved a glider object. No cell carries a ticket for that journey. We recognise a body across successive relations among sites. The recognition is useful: it lets us anticipate a visit. It also leaves something out. Following the figure, we can miss the cells that cease to participate. Press TRACE. For one generation after each step, a cell that has just stopped is marked in red and one that has just begun in blue; the figure you were following is seen to be leaving a wake, and the wake is where the rule was working.

Try LINK while a lamp is lit. The light goes out; the figure remains. STEP still changes it. The lamp's relation to this world has been written separately:

```gdscript
var occupied: bool = work._grid[site.y][site.x]
receiver.receive(occupied, linked, count_event)
```

That address could have been connected to another object. Here it controls an opal lamp. The lamp does not recognise a glider: any occupied state at its assigned address will light it when connected. Nor does its light return an influence to the cells. We have made a small, one-way traffic between the simulation and the room. Its boundary is a decision we can inspect and change.

Press LINK again to reconnect the lamps. Choose MEET. The same glider begins with a four-cell block in its path. Predict which lamps will light. Advance, then compare with GLIDER. GLIDER, BLINKER and MEET each prepare a fresh beginning, so the difference can be revisited; LINK keeps whatever setting you last gave it. In this particular meeting the field is empty within six generations. Only A ever lights, and it was lit before the first step: the block already sat on its address. The rule has stayed the same; what the glider could continue to be depended on what it met.

Conway chose these rules so that no beginning could be proved to grow for ever while some seemed to, and so that small beginnings would grow, change, and end in one of three ways: fading away, settling, or repeating. You have just watched the first. The rule was tuned to sit at the edge of what it can do, which is the name of the hall called Edge of Chaos, ahead.

There is pleasure in the travelling figure and in the room answering it. We need not turn that pleasure into proof of a living creature, or ask a fluid-looking body to stand for every possible difference. This body has particular conditions. Another encounter may interrupt it; another connection may let it do something we have not yet tried.

RUN advances this local experiment slowly and holds it at generation 48. The museum clock continues. We leave a finite observation, not a verdict on everything the rule can make.

<!-- @ -->

Further in, past the mould network and the dark sphere, a hexagonal field changes the second choice only: six neighbours instead of eight, a birth on two, and its generations stacked upward into a terrain. The same procedure, a different world.

So far the visitor has chosen a beginning and watched an output. In the next room, approaching a surface enters the calculation. What happens when the body doing the observing becomes one of the conditions?

[^ca-conway]: John Conway's rules were announced in Martin Gardner's “Mathematical Games” column, *Scientific American* 223 (October 1970), with the three conditions Conway set himself: no starting pattern for which there is a simple proof that it grows without limit; patterns that apparently do; and simple patterns that grow and change for a while before ending by fading away, settling, or oscillating.
