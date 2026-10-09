# cellularautomata: the chapters

## CA Introduction

*CA_Introduction*

### What will the next row do?

The rug is already changing. On the other side of the dividing wall, a board holds one green cell and waits. Two ways of making a pattern occupy the same hall. Begin with the one that has left you time to answer.

Keep the pleasure of the blob. Bring an unfinished question with it.


The board waits in the left-hand corridor near the entrance. The newest row sits along its far edge; the rest of the board is room for a past. Three small marks pick out a cell and its two neighbours. Read their states on the side plate, but leave STEP for a moment. What would you make from these three?

Press STEP. One generation arrives, and the previous row moves towards you. The pink mark stays at the same address. Its state may change. The plate now reads this new generation and predicts the one that could follow it. We have advanced the local machine; the rug has kept its own time.

On the smaller CA RULES panel, between the study buttons and the board, press 90. Keep the single seed.[^CA_Introduction--ca-wolfram] STEP once, then again. Follow one of the diagonal edges. Choose CELL to move the witness along the current row, and check a neighbourhood inside the pattern as well as one at its edge. Counting the green cells is tempting. Keep their order too: left, self, right.

The explorer consults its rule through these actual lines:

```gdscript
func _apply_rule(left: bool, center: bool, right: bool) -> bool:
	var neighborhood = (int(left) << 2) | (int(center) << 1) | int(right)
	return (rule >> neighborhood) & 1 == 1
```

Three on/off states make eight possible arrangements. The shifts place them into an index from zero to seven. The rule number stores eight answers, one bit for each arrangement. Reading the selected bit gives this cell's next state.

For Rule 90, compare `100` with `010`. Each contains one occupied cell. The first makes the next cell occupied; the second leaves it empty. A count would have discarded a relation that this rule uses. A neighbourhood is already a decision about what information may matter.

Press 30 on that rule panel and keep the single seed. Its rows quickly become harder to anticipate by eye. The board still asks the same small question at every position. A more tangled picture has not made the instruction longer. RUN lets the generations arrive automatically; pressing it again holds them, and STEP always leaves this study held after one update.

The update writes a separate row. Here is the loop inside `_advance`, followed by the moment the new row becomes current:

```gdscript
for i in range(cells_x):
    var left = _current_row[(i - 1 + cells_x) % cells_x]
    var center = _current_row[i]
    var right = _current_row[(i + 1) % cells_x]
    new_row[i] = _apply_rule(left, center, right)

_current_row = new_row
```

All the questions go to the old row. An answer written at the left cannot slip into the question being asked at the right. This installation builds that separation into its update step, the same under every rule number. A different update order would be another experiment to specify.

Press SEED. Two adjacent cells now occupy the starting row. The rule has stayed where you left it. Advance again and compare what happens where their consequences meet. Changing the beginning explores something that changing the rule alone could leave unseen. RST returns to the selected beginning and clears the visible history.

Keep stepping until a pattern reaches the boundary. The witness can cross it too: after cell 31 comes cell 0. The modulo operations in the loop join the two ends. What looks like a line on the desk is a ring to the calculation. Twenty-four rows fit on this board; older rows leave the display while their consequences remain in the current state. Once again, the visible past is smaller than the past that brought us here.

Just beyond the desk, the same row hangs overhead in a ring. Step underneath and find cells 31 and 0. They stand beside each other, as close as any other pair. The end of the line was where we had cut the picture. The calculation had already joined it.

STEP changes the lowest band as well as the board. Older rows rise above it. Let RUN continue while you walk underneath: the history gathers around an opening you can look through. Height marks how many updates ago a row was current. We have given time a direction in the room; the cells still belong to a one-dimensional neighbourhood. RST leaves only the starting ring again.

![Stored cellular-automaton rows hanging around the museum visitor](images/neighbour-ring.png)

*The board and ring show the same held Rule 90 history. The lowest band is current; the bands above retain earlier rows.*

The ring does not ask where you stand. You can feel enclosed by a neighbourhood without belonging to it. Our body receives the rule’s consequences as light; the cells still consult only other cells. That distance is also something we have built.


Across the entrance, an opening in the dividing wall leads to the rug. A detail in one quarter has partners across the cloth. Find them before naming the symmetry. The pink border and golden interior are another division to follow. Both can change, but they do not consult identical conditions.

This work has a two-dimensional grid, several states and two sets of local rules. The border and interior decide differently when activity begins, continues or fades. After calculating a generation, the program also mirrors one quarter into the others. In `_enforce_quadrant`, one value is written into three reflected positions (comments between these assignments are omitted):

```gdscript
grid[row_offset + (width - 1 - x)] = val
grid[mirror_row_offset + x] = val
grid[mirror_row_offset + (width - 1 - x)] = val
```

The ornament has several makers: local updates, a chosen boundary, a palette, and this repeated act of copying. The mirror remains at work after the first seed. Knowing that can give us another way to enjoy the rug. We can follow a changing detail while noticing the procedure that makes its companions answer together.

The title invites an association with a textile tradition. These few operations do not account for that tradition, its materials or its makers. They produce this particular computational cloth. Its source offers other stencils and divisions to investigate later; the rug in this hall uses the mirrored quarters and frame.


Return to the board's corridor and follow it past the turmites painting a shared surface: Langton's ants, agents that move, each turning by the colour it stands on, flipping that colour and stepping off it.[^CA_Introduction--ca-langton] Further along, a small tangle of coloured lines waits above the floor. Approach it. Another set of lines arrives, then another. The figure unfolds over a few seconds, with time to keep an older connection in sight while new ones appear.

You are watching a saved growth history. The same fixed frame holds its twenty stages, so a line already present stays where it was. Move around it and let one apparent knot separate into lines at different depths. Some space that looked full can open when your viewpoint changes.

Its growth begins with a random walk. During a bounded burst of updates, occupied frontier positions may add a nearby cell. The drawing then connects each newly encountered position to one of its neighbours, if any neighbour has already been recorded. There is a detail worth keeping: the parent in the drawing is selected during the scan. The line does not prove which earlier cell caused the birth.

Chance proposes an addition; stored occupancy constrains where it can occur; the drawing supplies connections and colour. After twenty updates, the history stops and the whole network remains. **REPLAY** lets the same stages return. It repeats what was kept, rather than asking chance for another growth.

The stillness has a limit written into it. Twenty updates were allowed; the shape did not announce that every possibility was exhausted. We can enjoy its resemblance to an organic body while learning to ask what brought this particular body to rest.

We can begin to distinguish forms by the relations that sustain them. The board keeps a row and repeatedly rewrites it. The rug combines local activity with an imposed symmetry. The network retains occupied positions and draws a selected account of their connections. Their resemblance to living things can invite us closer; the code gives us further differences to explore.


Other works remain in the hall. The orb rests on the rug's edge, another is held on a low stand, and a showcase waits at the end of the passage that runs on beyond the rug's room. Past the network, a Rule 110 display stands near the corridor's far end. Let them offer further directions without asking this first encounter to explain them all.

For now, carry four choices: what a cell can hold, which neighbours it can consult, when its answer becomes available to others, and whether that answer is settled by the rule or by a draw. These choices will help us follow the variations ahead. Sometimes the rule changes; sometimes we give the same record another body. Our next comparison, the structure-growth specimen, makes the neighbourhood three-dimensional and gives disappearance more than one state. What forms need a little longer to go away?

[^CA_Introduction--ca-wolfram]: The numbered rules are Stephen Wolfram's elementary cellular automata: 256 of them, each named by its eight answers read as one byte, so that Rule 90 is 01011010. In the order 111, 110, 101, 100, 011, 010, 001, 000, its eight answers are 0, 1, 0, 1, 1, 0, 1, 0 (“Statistical mechanics of cellular automata”, *Reviews of Modern Physics* 55, 1983; *A New Kind of Science*, 2002). The RULE slider on the board's panel runs through all 256. The lattice of cells updated by their neighbours is older: Stanisław Ulam and John von Neumann at Los Alamos in the 1940s, von Neumann's with twenty-nine states a cell and built to reproduce itself.

[^CA_Introduction--ca-langton]: Christopher Langton, “Studying artificial life with cellular automata”, *Physica D* 22 (1986). The ant is the variation in which the cell that changes is the one a body stands on, and the neighbourhood is wherever the body goes next; the painters here are eight to sixteen of them on one surface, dealt at random each time the hall is built.

---

## CA ElementaryRules

*CA_ElementaryRules*

### A cell with a past

How would you recognise a cell that has stopped being active but has not yet disappeared?

The previous hall let three cells answer a question about the next row. Here the neighbourhood reaches behind what we can see. Two of the four choices change at once: a cell can hold three states, and it consults twenty-six neighbours instead of two. A small volume waits above the opening in the floor. Walk along its rim. Two marks that seemed to touch can separate as you move; another cell has been behind them all along.


Beside the volume, twenty-seven positions have been pulled apart. You can walk between them. They show one cell and its neighbours from the small structure, enlarged enough to follow without losing the address. The central position wears a golden frame; the finer outlines keep the empty places visible. Move around a cube that blocks your view. What looked like a crowded surface begins to give up its separate positions.

Begin at the console. The structure is held at its starting generation. Pink means active. Press STEP once and look for green. A green cell is still occupied, still drawn where the surface allows it, but it has stopped contributing to its neighbours' active count. Follow it through another step. What does it leave available?

Each position consults a cube of three by three by three positions. Remove the position itself and twenty-six neighbours remain: through faces, along edges, across corners. The source gathers their activity with this test:

```gdscript
for offset in neighbor_offsets:
    if current_state[idx + offset] == 1:
        neighbors += 1
```

The comparison is to `1`. A green neighbour holds `2`. Being present and being counted have parted company.

The inscription `6-8/6-8/3/M` names this installation's agreement. An active cell survives with six, seven or eight active neighbours. An empty cell becomes active with those same counts. Three states are available: empty, active, fading. `M` denotes the surrounding Moore neighbourhood, which this implementation fixes at twenty-six positions.

REPLAY, then STEP once. The cell inside the golden frame is green. Walk around its enlarged neighbourhood and count the pink cells: seven. This is a reading of position `(26, 22, 24)` in the original volume, following the same updates. Seven would be enough for an empty cell to begin. Will this one become pink at the next step? Birth is tempting, but the code has already sent it down another branch. These are the lines for a state above one:

```gdscript
if state < rule_states - 1:
    next_state[idx] = state + 1
else:
    next_state[idx] = 0
```

Here `rule_states` is three, so state two goes to zero. Press STEP again and return to the golden frame. The place remains; the cell has gone. It must first become empty. Only a later generation can consider its birth again. Disappearance takes time, and that interval changes where new activity is possible. We have acquired another means of shaping a body: a position can retain a past that temporarily prevents a beginning.

![The enlarged address is green after the first step, with seven active neighbours.](images/lingering-cell.png)

![After the next step, the cell is empty and its golden address remains.](images/available-address.png)

*The golden frame keeps the address while the rule changes what can occupy it. The two views follow successive generations from the same position.*

Every answer is written into a second array. The old volume supplies all the questions before the arrays exchange places. There is no privileged first cell whose new answer reaches its neighbours early. STEP gives this local agreement one generation; the rest of the museum keeps running.

Press VIEW. The structure and its enlarged neighbourhood take on a gradient from dark to light with height. Nothing has advanced. The same cells can look like one continuous material now that their different states share a colour scale. Press VIEW again and recover the distinction. The finish has changed what we can readily recognise. Which reading did we take for the object itself?

The console also separates ACTIVE, FADING and DRAWN. The last number can be smaller than the first two added together. The renderer omits occupied cells surrounded on all six faces by occupied cells. Their state remains in the calculation. What the surface conceals can still help determine its next form. These visible cubes have no individual collision bodies; their appearance is not a promise of footholds.

Try RUN, then hold it. REPLAY returns to the same seeded beginning, so a second observation can follow a detail missed the first time. Twenty steps fit the initial observation budget. At that limit the machine holds; +20 permits another interval without reseeding. Read the generation count, and CHANGED on a line below it, beside DRAWN. A stopped clock alone cannot tell us whether the configuration has stopped changing. Zero changed cells, after an update under these fixed conditions, gives stronger evidence: that whole state reproduced itself.

There is an edge to this world too. Its outer cells stay empty. They do not wrap around to the opposite face as the previous board did. Near that boundary, a cell cannot find the same company it might find in the interior. The body has a rule, a beginning, an edge and a chosen duration of observation. Its organic appearance does not tell us which of these has made a particular feature possible.


The dark orb remains beside the route as a further encounter. For now, carry the difference between an active cell, a lingering cell and a cell hidden by the drawing. The familiar wish to give something life has opened into more particular questions. What must remain? What must become available again? In the next hall, generations will themselves become a structure laid out in space. A past we have just replaced will become something we can approach.

---

## CA GameOfLife

*CA_GameOfLife*

### A history you can inhabit


A gap in the screen lets you see through. The same gap in the floor asks something else of your body.

Stand at the desk before the basin. Its small coloured bars have relatives ahead: tiles laid across the recess, and a lattice standing along its side. Find the gold line in all three places. Press ROW. The line moves into an earlier part of the pattern. Nothing has been recalculated. You are moving your attention through a record.

The room greets you with twelve rows already made. Stay on the museum floor and press REPLAY. The record returns to one occupied square. There is less floor now, and less ornament. This button resets the experiment; the museum's clock continues.

Before STEP, look at the three positions around that square. Which squares will appear in the next row? Press once. A short line arrives on the desk, another row of support appears ahead, and the screen receives a vertical strip. Make one more prediction before asking it to continue.

The rule reads left, centre and right in one row. Their ordered bits select an answer:

```gdscript
var index = (a << 2) | (b << 1) | c
```

Here `a`, `b` and `c` are the three states, read into one index as the board in the first hall did. The bridge's `_apply_rule` reads bit `index` from the number 30. Each answer is written into a new row while the old row remains available to its other neighbours.

The study keeps that new row:

```gdscript
var next_row: Array = work._calculate_next_row(history.back())
history.append(next_row)
```

These lines come from `history_study.gd`, which calls the original bridge's solver. The record holds fifteen sites across and at most twenty-four rows. At the edges, left and right wrap. At the end of the record, this instrument stops adding rows. The first boundary belongs to the neighbourhood; the second belongs to our viewing budget.

Leave the desk and walk along the margin beside the basin. The gold line meets your row. It crosses the tiles and climbs the lattice; back on the desk, the same generation is marked. Walk farther, then turn back. An earlier row returns to the gold, but the later rows have not gone away. Your return has undone nothing.

Depth is doing the work of time. In the earlier volume, neighbours surrounded a cell within one three-dimensional state. Here a nearby row is an earlier or later moment. A solid-looking arrangement can hide that difference. None of the four choices has changed in this hall: it is Rule 30 again, three cells in a row, one row at a time. What has changed is where the past is kept.

Stop beside a gap. The line can pass through it; your foot would need support. Beyond the last recorded row, the marker stays behind. Walking cannot supply a generation the machine has not made. If RUN is on, the record can keep growing while you revisit an earlier part. Looking back and running backwards are different acts.

![The walking visitor selects one generation across the floor tiles and wall lattice.](images/walking-history.png)

*The gold line follows a place in the record. The same pattern meets us as an image and as possible support.*

The same record is dressed three ways. On the desk, a one becomes a coloured bar. In the basin, it becomes a tile with collision. In the lattice, it becomes coloured infill in a bronze frame. There is one stored history, but its uses have different consequences. The frame stands independently; the pattern does not calculate structural engineering. The basin has a lower collecting floor and end ramps, and the museum passage continues alongside it.

Try SEED, which changes the beginning while keeping Rule 30. Or return to SINGLE and press FLIP X9: one additional site in the starting row changes. STEP through the consequences. Later rows are made again from this beginning; we cannot honestly keep the old descendants and call them the same experiment.

Would you choose the same beginning for a screen and a crossing? You may want the holes in one and resist them in the other. A body we liked as ornament becomes awkward underfoot. This is a way of testing our desire against an implementation: change its use and discover what the beautiful surface had allowed us to overlook.

Beyond the basin the hall continues: columns, the orb again, a lab, a mirrored automaton. The lab arranges a tape, a head and a state register as a model of a machine. Its sign asks what counts as computation. A familiar arrangement gives us somewhere to begin asking; it cannot do the work of a proof.

The next hall holds a two-dimensional present. A pattern will seem to travel while its cell addresses stay still. Keep the distinction between a recorded body and the procedure that continues it.

---

## CA BeyondBinary

*CA_BeyondBinary*

### A pattern visits an address


Five green cells wait in the dish. A larger version spreads across the floor beyond it. Three lamps stand along its edge. They are dark.

Press STEP four times. The arrangement has changed at every step; now something about it has returned. Compare its position with one of the gold squares. What has travelled?

REPLAY brings the five cells back. This time keep your attention on the square marked A, at address (10,10). Step towards it. A cell becomes occupied; a lamp lights. Step again. Follow the square for a while, even when the more recognisable figure tempts your eye away. The address keeps its place. The pattern is already elsewhere.

You can cross the large display. Its empty cells still support your feet. In the previous room, occupancy became a stepping tile over a lower basin. Here it becomes colour on an ordinary floor. We have carried the array forward and given it another job. A zero does not contain an instruction to make a hole.

Stay beside one of the gold squares as its value changes. The pattern visits; the place continues to hold you. A lamp answers the cell, while your weight makes no difference to its next state. Sharing an address with the calculation has not made you one of its conditions.

![The Life floor fills the front bay, with fixed gold addresses connected to three lamps.](images/life-floor.png)

*The same present has room around it now. An empty square remains somewhere to stand.*

Try BLINKER. Three cells lie in a line. One step turns the line; another brings it back. Watch A, the middle cell. The surroundings alternate while this address remains occupied. Its lamp stays lit. Returning, travelling and staying can belong to different parts of the same small event. The names for these, now that you have watched them, are still life, oscillator and spaceship: the block the glider will meet is the first, the blinker the second, the glider the third.

The dish runs Conway's Game of Life.[^CA_BeyondBinary--ca-conway] Each cell has eight neighbours: the second choice, widened from two. An occupied cell survives with two or three occupied neighbours; an empty cell becomes occupied with exactly three. These are the lines that choose its next state:

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


Further in, past the mould network and the dark sphere, a table holds a hexagonal field. Here the neighbourhood and the birth condition both change: six neighbours instead of eight, birth on two. The Random Flip control allows occasional reversals of the rule’s answer. Generations stack upward into a terrain. Time has acquired thickness again, through another agreement.

So far the visitor has chosen a beginning and watched an output. In the next room, approaching a surface enters the calculation. What happens when the body doing the observing becomes one of the conditions?

[^CA_BeyondBinary--ca-conway]: John Conway's rules were announced in Martin Gardner's “Mathematical Games” column, *Scientific American* 223 (October 1970), with the three conditions Conway set himself: no starting pattern for which there is a simple proof that it grows without limit; patterns that apparently do; and simple patterns that grow and change for a while before ending by fading away, settling, or oscillating.

---

## CA ExpandingSpace

*CA_ExpandingSpace*

### The surface includes you


The path looks available. Five tiles across, a longer line ahead. Its colours repeat in panels on a free-standing frieze beside the path. Beneath it lies a shallow basin, already drawn with the addresses of tiles that have not yet disappeared.

Begin at the desk. SOURCE can nominate the pink probe in your place. With PROBE / NEAR showing, press RUN. Follow the gold square W. The number falls. The tile changes colour, then becomes a faint sheet through which the basin is visible. Stop the local experiment. How much of a path is still there?

Use NEAR/FAR to withdraw the probe and run again. Watch the edge of the depleted region before its centre. Something returns through what remained around it. There is no separate instruction ordering this particular patch to grow back into its old outline.

RESTORE prepares a full bridge. Change SOURCE to VISITOR and start RUN. Your position now takes the probe's place. Approach the marked region, wait, move away. The ordinary museum floor continues alongside the basin; recovery ramps rise at either end of its right-hand edge, on the desk's side. On the bridge, lingering can cost you support. The faint tile can still be seen after it can no longer carry you.

Look up to find W again. A gold frame holds its place on the frieze. Wait above the tile while watching its colour there. The change stays in front of you; the consequence arrives beneath your feet. When the surface gives way, you are still looking at the same address from a little lower down.

![The gold address W remains visible on the wall and the depleted bridge.](images/ca-presence-depleted.png)

*One cell, two surfaces. The basin receives the body when the bridge can no longer carry it.*

The bridge's variable is called health. Here that means a number between zero and one. The name lends it a small biological story, but the operations are available to read. Nearby cells lose a fixed amount on each update:

```gdscript
if present and cell_position(coord).distance_to(local_visitor) < decay_radius:
    next[coord] = maxf(0.0, health - decay_speed * dt * 5.0)
```

Distance is measured in three dimensions from a cell's centre to the tracked body's origin. No scale weighs your feet. The surface can respond before your body is standing on the cell you are watching. The pink probe can produce the same numerical influence without a person above it. Which part of our first explanation came from the event, and which part did the appearance of a bridge invite us to supply?

Outside that radius, a cell can recover through its four immediate axial neighbours. Each neighbour above 0.5 contributes to recovery. At 0.3 a tile can support you, yet it cannot contribute as a healthy neighbour. Below 0.2, its collider is disabled:

```gdscript
colliders[coord].set_deferred("disabled", health < 0.2)
```

One changing value meets two different thresholds. Being visible, carrying a visitor and helping a neighbour recover are separate permissions. The frieze uses the same health materials, but its coloured panels supply no bridge collision. A room can wear an answer without offering the same way through it.

There is another condition hidden in “each update.” Choose CHAIN for a small prepared comparison. The bridge begins mostly depleted; three adjacent values are 0.600, 0.495 and 0.000. SOURCE becomes NONE. We can attend to recovery without moving the input at the same time.

STEP once in SYNC. The middle value crosses 0.5. Has the next cell been allowed to use that change already? ORDER switches to SCAN and restores the same beginning. Step again, then use REVERSE and repeat. A different answer can appear even though the neighbouring cells and the amount of time are unchanged. The loop has a direction too.

SYNC reads the previous field throughout the update. SCAN reads answers already written during the same pass. In this study, changing scan direction leaves the synchronous result unchanged; in-place recovery can change. The choice sits in a single line:

```gdscript
var read_states: Dictionary = previous if snapshot_reads else next
```

We have returned to the Life dish's two buffers. Their separation now changes when a weakened surface can help another part of itself. The rule includes a schedule, even when the picture conceals it.

Restore the full bridge and return to the visitor input. There is pleasure in architecture answering us, and a stranger pleasure when its answer interrupts the role we expected it to play. We can study that relation without deciding that a responsive surface must be alive. A fully depleted field with no healthy neighbours remains depleted. Withdrawal alone does not promise repair.

At thirty simulated seconds this study holds. The museum continues. We leave with a more precise question than whether the path is living: which relations let it carry a body, recover, or become unavailable? Three of the four choices moved in this hall: a cell holds a fraction, the visitor's position is among what it consults, and the order of the loop decides when an answer counts.


The next room asks what a cell can receive from its neighbourhood when counting healthy neighbours is no longer enough. A softer-looking surface will need another working rule to earn that difference.

---

## CA SoftRules

*CA_SoftRules*

### What can a cell receive?


Two small squares wait on the tables. Behind them, the same squares wait on curved walls. The room has already enlarged their answer, although neither field has taken a step.

At the side desk, find W. It lies just outside the seeded square. Its V reading is zero in both fields. Press STEP once. On the left, a little arrives. On the right, nothing. Look back at the pictures: can you find that difference without the numbers?

Press +100 and let the local clock complete its hundred updates. The fields begin to part. They began with the same values, at the same addresses. They have the same reaction. What has the right-hand square been denied?

EXCHANGE B turns its neighbourhood exchange on and restores both beginnings. Advance again. The two fields now agree. Switch exchange off, replay, and look for the first place where they differ. We can locate the missing relation before giving the result a name.

In the previous hall a neighbour above half health counted as one contribution to recovery. Here a cell stores two concentrations, U and V. It receives differences in concentration from the four sites beside it. For each field, the sum is its neighbours minus four copies of itself:

```gdscript
return a[y*N+(x+N-1)%N]+a[y*N+(x+1)%N]+a[((y+N-1)%N)*N+x]+a[((y+1)%N)*N+x]-4.0*a[y*N+x]
```

The repeated subtraction matters. If all five values agree, this part of the update contributes zero. A higher neighbour can send a positive contribution; a lower neighbourhood can draw one away. No neighbour has to cross a health threshold to count. How much it differs is now part of what it can offer. Two choices have changed: a cell holds two fractions instead of one bit, and what it consults is not a count but a difference.

There is also a reaction at the address itself. The product U × V × V removes some U and adds some V. A feed term replenishes U; another term removes V. The installation uses the same arithmetic as the project's existing Gray–Scott generator,[^CA_SoftRules--ca-gray-scott] now exposed one update at a time:

```gdscript
var uvv:float=a*b*b
```

```gdscript
next_u[i]=clampf(a+coupling*0.16*lap_u-uvv+FEED*(1.0-a),0.0,1.0)
next_v[i]=clampf(b+coupling*0.08*lap_v+uvv-(KILL+FEED)*b,0.0,1.0)
```

With exchange off, the right-hand field still reacts. But at an unseeded address V is zero, so U × V × V is also zero. Nothing in that local reaction can make its first V arrive. The left-hand field can receive it. This difference is small enough to calculate and large enough to alter the wall. Even the right-hand square's seeded cells cannot keep their V: at feed .037 and kill .060 the reaction alone has no resting state other than full U and no V, so by the end of the first hundred updates that square has nearly faded.

Keep that distinction in hand. “Soft” is not a promise that the rule is gentle or that every boundary has disappeared. Both fields still occupy a 32-by-32 grid. The arithmetic writes into separate next arrays before swapping them into the present. Values are clamped between zero and one. At an edge, the remainder operator wraps the neighbour index to the opposite side. The wall has a visible border that the calculation does not share.

Use VIEW U/V. Another distribution appears without a single new update. The initial view doubles V before mapping it into colour; the U view has its own palette. A colour can saturate while the stored value still has room to change. An image is already an interpretation of the field.

Now walk between the two curved displays. Find a patch on a wall, then look for it on the table. Each pair shares the same texture. At the desk you could take in the small field; here you turn within its enlarged image.

Press COAT. The colour surfaces disappear while the table fields continue. Bring them back. The fixed museum floor carries you through both views.[^CA_SoftRules--ca-soft-coating] The field has become something the room can wear. Perhaps you would keep it here, or want it closer, as a lining against a body. What would you change for that other use?

Try INJECT. Both fields receive the same small second patch. Let it run. We are no longer only watching a prepared beginning; we have entered another event into its history. REPLAY can restore that beginning. It cannot make our first encounter with the difference happen again.


Further on, the clockmaker has laid out trays, stencils and small worlds. The brass shapes make reading and writing almost look like trades we could perform with our hands. Find the fractional ring. It is a still radial diagram. Its graded appearance does not demonstrate a running Lenia field,[^CA_SoftRules--ca-lenia] and the ornamental crank cannot advance it.

Compare that invitation with the walls we have just left. Both offer pleasure in a patterned body; their means of producing it differ. We need neither reject the ornament nor grant it an operation it does not have. A diagram can help us imagine the machine, then leave us with something still to build.


The local study holds after 2,400 updates. The museum goes on. We have watched a field change and a room wear its image. Carry a question from those surfaces: could a similar form have another way of becoming?

[^CA_SoftRules--ca-soft-coating]: COAT toggles the wall display meshes. Their geometry stays fixed and has no collision shapes; the museum floor supplies support. Sharing a field texture does not create a sensing or growing body. Those would require additional operations.

[^CA_SoftRules--ca-gray-scott]: The reaction is Peter Gray and Stephen Scott's (*Chemical Engineering Science* 39, 1984), diffused across a grid; the feed .037 and kill .060 the readout prints lie in the range John Pearson mapped in “Complex patterns in a simple system” (*Science* 261, 1993).

[^CA_SoftRules--ca-lenia]: Lenia (Bert Wang-Chak Chan, *Complex Systems* 28, 2019) is a continuous automaton: its cells hold fractions, read a ring-shaped neighbourhood weighted by distance, and grow by a smooth function of what they find there. The still ring on the tray pictures that neighbourhood; nothing in it is being updated.

---

## CA AgentsCircuits

*CA_AgentsCircuits*

### The same pattern, different work


Can two constructions resemble one another without doing the same calculation?

Press 90 on the explorer’s CA RULES panel, then RST to return to the central seed. Press STEP a few times. Follow the triangular gaps that develop between occupied cells. Choose a larger triangle and look for smaller ones arranged within its boundary. Add rows, up to fifteen steps, when you need more to compare; at the sixteenth the pattern's two diagonal edges meet around the ring and every new row from then on is empty.

Each new cell is still calculated from a local neighbourhood. No instruction tells the display to draw a large triangle and then decorate it with smaller triangles. The repeated structure becomes visible through many applications of the rule.

Choose one triangular gap in the rule display. Keep a few occupied cells around it in mind, so there is more to recognise than the outline. Carry that small arrangement to the pyramid. Where would it fit? If one part refuses the match, stay with that part before choosing a different resemblance. We have found something the shared appearance did not tell us.


Now turn to the Sierpinski pyramid. Find a small pyramid and compare where its neighbours sit. Then step back and look for the same arrangement at the next scale. This construction repeats its arrangement recursively at half the spacing: four copies at the lower corners, one at the apex and one more directly above it, which lifts the top into a spire. The cubes do not shrink with the spacing, so neighbouring copies overlap. Its procedure begins with a shape and a copying arrangement, rather than a row whose next state must be calculated. None of the four choices applies to it: the pyramid is not an automaton at all, which is the point of standing it here.

The resemblance is useful because it gives you a question to test. At which scales do gaps correspond? Which relations are altered by moving from a flat history to a volume? You need not force every visible feature into a match. A failed correspondence tells you where the analogy stops.

The row's next state and the pyramid's smaller copies can lead the eye towards a related form. The pleasure of recognising it gives us a reason to compare their making. A name for the resemblance can accompany that inquiry without finishing it.[^CA_AgentsCircuits--ca-resemblance]

Keep the pyramid fixed and press SEED at the desk. Two adjacent cells now begin the history. Build a few rows again. Where do the familiar triangular relations return, and do they ever overlap? Press SEED once more to return to the single cell. How much of the resemblance belonged to the rule, and how much to the beginning we gave it?

Before leaving the desk, turn RULE until the plate reads 222 and step from the single seed. The triangle fills solid, reaches round the ring, and stops changing. Turn it to 190: stripes, every cell repeating the same short cycle. Press 30: no row can be read off the one before it by eye. Press 110: structures that persist and travel, meeting and breaking, with no way to say from the picture when the next will appear. Stephen Wolfram sorted the 256 rules into four such classes in 1984 — uniform, repeating, random, complex — and set the last apart as the one that behaves like the things around us.[^CA_AgentsCircuits--ca-classes] The plate captions 110 “Turing Complete”; carry that word to the hall called Edge of Chaos, ahead, where the border between the third class and the fourth is the whole question.


We will return to the pyramid's way of making in Fractals. First, two almost matching volumes will let us follow one changed value through the same procedure. We have asked how similar appearances can be made differently. What happens when we keep the making the same and alter one small part of the beginning?

[^CA_AgentsCircuits--ca-resemblance]: The explorer's plate captions Rule 90 “Sierpiński” and Rule 110 “Turing Complete”. This comparison earns the first word only as a question about resemblance. The second is a theorem rather than a caption: Matthew Cook proved in 2004 that Rule 110 can carry out any computation (“Universality in elementary cellular automata”, *Complex Systems* 15), by reading its persisting structures as signals and their collisions as logic — an account of states, operations and results that no organised appearance supplies on its own. The Rule 110 display in the first hall is where to begin asking for it.

[^CA_AgentsCircuits--ca-classes]: Stephen Wolfram, “Universality and complexity in cellular automata”, *Physica D* 10 (1984).

---

## CA EdgeOfChaos

*CA_EdgeOfChaos*

### How far does one difference go?


Two volumes wait at the same update. Their colours almost agree. Somewhere in B, one address holds a value one greater than its counterpart in A. Can you find it without the instrument telling you where to look?

Walk between them. The floor carries a section of their difference; the cases ahead show A, B and the difference separately. These are ways of looking into the same two volumes. A wall is a slice through space. It is not the next generation. Use Z SLICE and watch what remains unchanged on the counter.

Return to the console. Press STEP. Follow the lit difference for a few updates, then use REPLAY to meet the same beginning again. ONE CELL removes the intervention, or restores it. With the intervention removed, both runs should agree through every update, even when the disturbance is loud. What would it mean if they did not?

The two runs receive the same forcing value at the same address and update. This is a deliberately shared, reproducible schedule. Without that agreement, a second source of difference would enter while we were trying to follow the first. The comparison makes a small experimental world inside a larger one whose clock continues.

Here is the local instruction, before storage:

```gdscript
var drive:float=disturbance*sample(i,tick)
var va:float=clampf(a[i]*(1.0-coupling)+sa/neighbours[i].size()*coupling+drive,0.0,9.0)
```

`sa` is the sum of A's valid neighbours. Interior cells have twenty-six; the corner has seven. Every cell reads the previous volume. PULL changes how far it moves toward that average. DRIVE changes the size of the added disturbance. The controls reset both runs, keeping the comparison legible. One gesture no longer changes both tendencies at once.

Bring DRIVE to zero. Choose the uniform beginning with SEED, leave PULL at 0.25 and ONE CELL enabled. In INTEGER storage, press STEP. The difference is gone. Replay, switch STORE to FRACTIONAL and take the same step. Now twenty-seven addresses differ, but the largest difference is smaller than before: 0.75 instead of one.

More places carry it. Less of it remains at any one place.

The fork is one short line:

```gdscript
na[i]=float(int(va)) if integer_storage else va
```

The integer conversion removes the fractional part of these nonnegative values. The pull that took five toward four produced 4.75. The stored integer is four. Around it, smaller fractional changes also fell away. A rule about neighbours was accompanied by another rule about what a value may keep. Of the four choices, this hall moves the first alone.

Continue the fractional run. The wall of difference becomes broad and luminous. Look up at the gain printed on the readout above the console. The display is increasing its sensitivity as the largest difference fades. Its brightness is a decision about visibility. Read the maximum alongside the number of affected cells: that count includes only differences above 0.000001. A trace may leave the counter before it leaves the stored values.

Turn PULL down to zero, with DRIVE still zero, and replay. The intervention stays at its original address. This stillness keeps whole a memory that the smoothing run spread thin. We would miss something if we arrived already certain that a moving, complicated-looking field must be the more interesting body.

The hall is called Edge of Chaos. The name is Christopher Langton's, from 1990: between the rules whose fields freeze or repeat and the rules whose fields boil, he measured a narrow band where structures persist long enough to carry and combine information, and put Wolfram's fourth class there.[^CA_EdgeOfChaos--ca-edge] Let the name remain a question here. The fractional update averages nearby values and adds matched forcing; that averaging is the operation a blur performs on a picture, each pixel pulled toward its neighbours, and an image filter is a cellular automaton run once. A spreading difference alone does not establish chaotic amplification. The integer conversion introduces thresholds of its own. We have measured some consequences of those choices. We have not located the one permissible region where life, computation or queerness can exist.

The other works remain in the rear gallery: a screen that keeps the successive states of a one-dimensional automaton as rows, local transmission and recovery drawn by chance — the susceptible, infected and recovered of 1927 laid on a grid, the fourth choice settled by a draw[^CA_EdgeOfChaos--ca-sir] — a fog field whose cell rule fills it solid within two updates, and cracks that finish spreading across their plate within a couple of seconds of being built. Each asks for its own account of what passes between neighbours, what is stored, and what the image omits. Similar-looking motion, where there is any, does not make their rules equivalent.


The next hall, the first of Fractals, changes the instruction. Instead of waiting for local exchanges to assemble a larger resemblance, a procedure explicitly asks for another instance of itself. Carry this distinction with you: a form can resemble its neighbour, inherit an earlier state, or be told to repeat. The resemblance does not yet explain the making.

[^CA_EdgeOfChaos--ca-edge]: Christopher Langton, “Computation at the edge of chaos: phase transitions and emergent computation”, *Physica D* 42 (1990). His measure was λ, the share of neighbourhoods a rule answers with a living cell; the band lies where λ is neither small nor large. PULL here is a different knob on a different rule, and the name is borrowed, not measured.

[^CA_EdgeOfChaos--ca-sir]: W. O. Kermack and A. G. McKendrick, “A contribution to the mathematical theory of epidemics”, *Proceedings of the Royal Society A* 115 (1927). In the rear gallery each cell is infected with a fixed probability per infected neighbour and recovers with another: two draws and a grid.

---
