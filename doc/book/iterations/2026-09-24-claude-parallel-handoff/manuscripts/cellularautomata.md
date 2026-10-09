# cellularautomata: current chapters

Snapshot for the 24 September 2026 Claude assignment. Reconcile with live final.md before editing. Anchors retained; image binaries not included. Resolve original image paths in the live project.

## CA_Introduction
Source: `commons/maps/CA_Introduction/final.md` · SHA-256 `6f1d7de34b510fa4f6071ed4ec96432632e8fc8750bcbbecd260ef2574516b82`

# What will the next row do?

The rug is already changing. Across the room, a small board holds one green cell and waits. Two ways of making a pattern occupy the same hall. Begin with the one that has left you time to answer.

We have carried noise a long way: across a sheet, into a volume, around the body and under a foot. A little variation can satisfy the first wish for something organic. Its ease is part of its power. It can also make that first answer so familiar that other possible forms remain in its shadow. Keep the pleasure of the blob. Bring an unfinished question with it.

<!-- @ca_rule_explorer -->

Find the board near the entrance side of the hall. The newest row sits along its far edge; the rest of the board is room for a past. Three small marks pick out a cell and its two neighbours. Read their states on the side plate, but leave NEXT for a moment. What would you make from these three?

Press STEP. One generation arrives, and the previous row moves towards you. The pink mark stays at the same address. Its state may change. The plate now reads this new generation and predicts the one that could follow it. We have advanced the local machine; the rug has kept its own time.

Begin with Rule 90 and the single seed. STEP once, then again. Follow one of the diagonal edges. Choose CELL to move the witness along the current row, and check a neighbourhood inside the pattern as well as one at its edge. Counting the green cells is tempting. Keep their order too: left, self, right.

The explorer consults its rule through these actual lines:

```gdscript
func _apply_rule(left: bool, center: bool, right: bool) -> bool:
	var neighborhood = (int(left) << 2) | (int(center) << 1) | int(right)
	return (rule >> neighborhood) & 1 == 1
```

Three on/off states make eight possible arrangements. The shifts place them into an index from zero to seven. The rule number stores eight answers, one bit for each arrangement. Reading the selected bit gives this cell's next state.

For Rule 90, compare `100` with `010`. Each contains one occupied cell. The answers differ. A count would have discarded a relation that this rule uses. A neighbourhood is already a decision about what information may matter.

Choose Rule 30 and keep the single seed. Its rows quickly become harder to anticipate by eye. The board still asks the same small question at every position. A more tangled picture has not made the instruction longer. RUN lets the generations arrive automatically; pressing it again holds them, and STEP always leaves this study held after one update.

The update writes a separate row. Here is the loop inside `_advance`, followed by the moment the new row becomes current:

```gdscript
for i in range(cells_x):
    var left = _current_row[(i - 1 + cells_x) % cells_x]
    var center = _current_row[i]
    var right = _current_row[(i + 1) % cells_x]
    new_row[i] = _apply_rule(left, center, right)

_current_row = new_row
```

All the questions go to the old row. An answer written at the left cannot slip into the question being asked at the right. This installation makes that separation part of its rule. A different update order would be another experiment to specify.

Press SEED. Two adjacent cells now occupy the starting row. The rule has stayed where you left it. Advance again and compare what happens where their consequences meet. Changing the beginning explores something that changing the rule alone could leave unseen. RST returns to the selected beginning and clears the visible history.

Keep stepping until a pattern reaches the boundary. The witness can cross it too: after cell 31 comes cell 0. The modulo operations in the loop join the two ends. What looks like a line on the desk is a ring to the calculation. Twenty-four rows fit on this board; older rows leave the display while their consequences remain in the current state. Once again, the visible past is smaller than the past that brought us here.

<!-- @persian_rug -->

Now approach the rug. A detail in one quarter has partners across the cloth. Find them before naming the symmetry. The pink border and golden interior are another division to follow. Both can change, but they do not consult identical conditions.

This work has a two-dimensional grid, several states and two sets of local rules. The border and interior decide differently when activity begins, continues or fades. After calculating a generation, the program also mirrors one quarter into the others. In `_enforce_quadrant`, one value is written into three reflected positions (comments between these assignments are omitted):

```gdscript
grid[row_offset + (width - 1 - x)] = val
grid[mirror_row_offset + x] = val
grid[mirror_row_offset + (width - 1 - x)] = val
```

The ornament has several makers: local updates, a chosen boundary, a palette, and this repeated act of copying. The mirror remains at work after the first seed. Knowing that can give us another way to enjoy the rug. We can follow a changing detail while noticing the procedure that makes its companions answer together.

The title invites an association with a textile tradition. These few operations do not account for that tradition, its materials or its makers. They produce this particular computational cloth. Its source offers other stencils and divisions to investigate later; the rug in this hall uses the mirrored quarters and frame.

<!-- @line_network_ca -->

Further along, the line network gives the cell another body. Occupied positions are joined by coloured segments. Move around it and let one apparent knot separate into lines at different depths. Some space that looked full can open when your viewpoint changes.

Its growth begins with a random walk. During a bounded burst of updates, occupied frontier positions may add a nearby cell. The drawing then chooses a recorded neighbour to connect to each newly encountered position. There is a detail worth keeping: the parent in the drawing is selected during the scan. The line does not prove which earlier cell caused the birth.

This is another construction of an organic form. Chance proposes an addition; stored occupancy constrains where it can occur; the renderer supplies connections and colour. The work may already have finished its twenty growth updates when you reach it. A still network can be the consequence of that programmed limit. Stillness alone cannot tell us that growth exhausted every possibility.

We can begin to distinguish forms by the relations that sustain them. The board keeps a row and repeatedly rewrites it. The rug combines local activity with an imposed symmetry. The network retains occupied positions and draws a selected account of their connections. Their resemblance to living things can invite us closer; the code gives us further differences to explore.

<!-- @ -->

The other works remain in the room: agents painting a shared surface, a Rule 110 display, the showcase and the orb. Let them offer further directions without asking this first encounter to explain them all.

For now, carry three choices: what a cell can hold, which neighbours it can consult, and when its answer becomes available to others. Our next comparison, the structure-growth specimen, makes the neighbourhood three-dimensional and gives disappearance more than one state. What forms need a little longer to go away?

---

## CA_ElementaryRules
Source: `commons/maps/CA_ElementaryRules/final.md` · SHA-256 `2638c5ee9765bb8da3c16c383f559b1b35eb7f09dee94dda64005c770c8f3f69`

# A cell with a past

How would you recognise a cell that has stopped being active but has not yet disappeared?

The previous hall let three cells answer a question about the next row. Here the neighbourhood reaches behind what we can see. A small volume waits above the opening in the floor. Walk along its rim. Two marks that seemed to touch can separate as you move; another cell has been behind them all along.

<!-- @structure_growth -->

Begin at the console. The structure is held at its starting generation. Pink means active. Press STEP once and look for green. A green cell is still occupied, still drawn where the surface allows it, but it has stopped contributing to its neighbours' active count. Follow it through another step. What does it leave available?

Each position consults a cube of three by three by three positions. Remove the position itself and twenty-six neighbours remain: through faces, along edges, across corners. The source gathers their activity with this test:

```gdscript
for offset in neighbor_offsets:
    if current_state[idx + offset] == 1:
        neighbors += 1
```

The comparison is to `1`. A green neighbour holds `2`. Being present and being counted have parted company.

The inscription `6-8/6-8/3/M` names this installation's agreement. An active cell survives with six, seven or eight active neighbours. An empty cell becomes active with those same counts. Three states are available: empty, active, fading. `M` denotes the surrounding Moore neighbourhood, which this implementation fixes at twenty-six positions.

Now find a place that has turned green and imagine it surrounded by seven active neighbours. Will it become pink at the next step? Birth is tempting, but the code has already sent this cell down another branch. These are the lines for a state above one:

```gdscript
if state < rule_states - 1:
    next_state[idx] = state + 1
else:
    next_state[idx] = 0
```

Here `rule_states` is three, so state two goes to zero. It must first become empty. Only a later generation can consider its birth again. Disappearance takes time, and that interval changes where new activity is possible. We have acquired another means of shaping a body: a position can retain a past that temporarily prevents a beginning.

Every answer is written into a second array. The old volume supplies all the questions before the arrays exchange places. There is no privileged first cell whose new answer reaches its neighbours early. STEP gives this local agreement one generation; the rest of the museum keeps running.

Press VIEW. The structure takes on a gradient from dark to light with height. Nothing has advanced. The same cells can look like one continuous material now that their different states share a colour scale. Press VIEW again and recover the distinction. The finish has changed what we can readily recognise. Which reading did we take for the object itself?

The console also separates ACTIVE, FADING and DRAWN. The last number can be smaller than the first two added together. The renderer omits occupied cells surrounded on all six faces by occupied cells. Their state remains in the calculation. What the surface conceals can still help determine its next form. These visible cubes have no individual collision bodies; their appearance is not a promise of footholds.

Try RUN, then hold it. REPLAY returns to the same seeded beginning, so a second observation can follow a detail missed the first time. Twenty steps fit the initial observation budget. At that limit the machine holds; +20 permits another interval without reseeding. Read CHANGED beside the generation count. A stopped clock alone cannot tell us whether the configuration has stopped changing. Zero changed cells, after an update under these fixed conditions, gives stronger evidence: that whole state reproduced itself.

There is an edge to this world too. Its outer cells stay empty. They do not wrap around to the opposite face as the previous board did. Near that boundary, a cell cannot find the same company it might find in the interior. The body has a rule, a beginning, an edge and a chosen duration of observation. Its organic appearance does not tell us which of these has made a particular feature possible.

<!-- @ -->

The dark orb remains beside the route as a further encounter. For now, carry the difference between an active cell, a lingering cell and a cell hidden by the drawing. The familiar wish to give something life has opened into more particular questions. What must remain? What must become available again? In the next hall, generations will themselves become a structure laid out in space. A past we have just replaced will become something we can approach.

---

## CA_GameOfLife
Source: `commons/maps/CA_GameOfLife/final.md` · SHA-256 `780fca9f4f6757699d528ddc4e5ab68f33f7585e93c32446deb403f1e2dceff8`

# A history you can inhabit

<!-- @ca_bridge -->

A gap in the screen lets you see through. The same gap in the floor asks something else of your body.

Stand at the desk before the basin. Its small coloured squares have relatives ahead: tiles laid across the recess, and a lattice standing along its side. Find the gold line in all three places. Press ROW. The line moves into an earlier part of the pattern. Nothing has been recalculated. You are moving your attention through a record.

The room greets you with twelve rows already made. Stay on the museum floor and press REPLAY. The record returns to one occupied square. There is less floor now, and less ornament. This button resets the experiment; the museum's clock continues.

Before STEP, look at the three positions around that square. Which squares will appear in the next row? Press once. A short line arrives on the desk, another row of support appears ahead, and the screen receives a vertical strip. Make one more prediction before asking it to continue.

The rule reads left, centre and right in one row. Their ordered bits select an answer:

```gdscript
var index = (a << 2) | (b << 1) | c
```

Here `a`, `b` and `c` are the three states. The shifts give their positions different weights: four, two, one. `100` and `001` both contain one occupied cell, but ask different questions of the rule. The bridge's `_apply_rule` reads bit `index` from the number 30. Each answer is written into a new row while the old row remains available to its other neighbours.

The study keeps that new row:

```gdscript
var next_row: Array = work._calculate_next_row(history.back())
history.append(next_row)
```

These lines come from `history_study.gd`, which calls the original bridge's solver. The record holds fifteen sites across and at most twenty-four rows. At the edges, left and right wrap. At the end of the record, this instrument stops adding rows. The first boundary belongs to the neighbourhood; the second belongs to our viewing budget.

Follow the gold line onto the tiles. Depth is doing the work of time. In the earlier volume, neighbours surrounded a cell within one three-dimensional state. Here a nearby row is an earlier or later moment. A solid-looking arrangement can hide that difference.

The same record is dressed three ways. On the desk, a one becomes a coloured square. In the basin, it becomes a tile with collision. In the lattice, it becomes coloured infill in a bronze frame. There is one stored history, but its uses have different consequences. The frame stands independently; the pattern does not calculate structural engineering. The basin has a lower collecting floor and end ramps, and the museum passage continues alongside it.

Try SEED, which changes the beginning while keeping Rule 30. Or return to SINGLE and press FLIP X9: one additional site in the starting row changes. STEP through the consequences. Later rows are made again from this beginning; we cannot honestly keep the old descendants and call them the same experiment.

Would you choose the same beginning for a screen and a crossing? You may want the holes in one and resist them in the other. A body we liked as ornament becomes awkward underfoot. This is a way of testing our desire against an implementation: change its use and discover what the beautiful surface had allowed us to overlook.

The next hall holds a two-dimensional present. A pattern will seem to travel while its cell addresses stay still. Keep the distinction between a recorded body and the procedure that continues it.

<!-- @ -->

---

## CA_BeyondBinary
Source: `commons/maps/CA_BeyondBinary/final.md` · SHA-256 `4e649666dbd3b3d6a10d68cf8a500aa15e2a6b62c2eaf4b80f50a55434a95c8d`

# A pattern visits an address

<!-- @game_of_life_petri -->

Five pale cells wait in the dish. A larger version lies in the floor beyond it. Three lamps stand along its edge. They are dark.

Press STEP four times. The arrangement has changed at every step; now something about it has returned. Compare its position with one of the gold squares. What has travelled?

REPLAY brings the five cells back. This time keep your attention on the square marked A, at address (10,10). Step towards it. A cell becomes occupied; a lamp lights. Step again. Follow the square for a while, even when the more recognisable figure tempts your eye away. The address keeps its place. The pattern is already elsewhere.

You can cross the large display. Its empty cells still support your feet. In the previous room, occupancy became a stepping tile over a lower basin. Here it becomes colour on an ordinary floor. We have carried the array forward and given it another job. A zero does not contain an instruction to make a hole.

Try BLINKER. Three cells lie in a line. One step turns the line; another brings it back. Watch A, the middle cell. The surroundings alternate while this address remains occupied. Its lamp stays lit. Returning, travelling and staying can belong to different parts of the same small event.

The dish runs Conway's Game of Life. Each cell has eight neighbours. An occupied cell survives with two or three occupied neighbours; an empty cell becomes occupied with exactly three. These are the lines that choose its next state:

```gdscript
if alive:
    _next_grid[y][x] = neighbors == 2 or neighbors == 3
else:
    _next_grid[y][x] = neighbors == 3
```

Every answer goes into another array. Only when the whole plane has been read do the two buffers exchange places. A cell later in the loop cannot borrow an answer made earlier in this generation. At the edges, the neighbourhood wraps to the opposite side.

In the glider beginning, four generations reproduce the arrangement one address further along each axis. No instruction has moved a glider object. No cell carries a ticket for that journey. We recognise a body across successive relations among sites. The recognition is useful: it lets us anticipate a visit. It also leaves something out. Following the figure, we can miss the cells that cease to participate.

Try LINK while a lamp is lit. The light goes out; the figure remains. STEP still changes it. The lamp's relation to this world has been written separately:

```gdscript
var occupied: bool = work._grid[site.y][site.x]
receiver.receive(occupied, linked, count_event)
```

That address could have been connected to another object. Here it controls an opal lamp. The lamp does not recognise a glider: any occupied state at its assigned address will light it when connected. Nor does its light return an influence to the cells. We have made a small, one-way traffic between the simulation and the room. Its boundary is a decision we can inspect and change.

Choose MEET. The same glider begins with a four-cell block in its path. Predict which lamps will light. Advance, then compare with GLIDER. Each button prepares a fresh beginning, so the difference can be revisited. In this particular meeting, by generation 24 the field is empty. The rule has stayed the same; what the glider could continue to be depended on what it met.

There is pleasure in the travelling figure and in the room answering it. We need not turn that pleasure into proof of a living creature, or ask a fluid-looking body to stand for every possible difference. This body has particular conditions. Another encounter may interrupt it; another connection may let it do something we have not yet tried.

RUN advances this local experiment slowly and holds it at generation 48. The museum clock continues. We leave a finite observation, not a verdict on everything the rule can make.

<!-- @ -->

So far the visitor has chosen a beginning and watched an output. In the next room, approaching a surface enters the calculation. What happens when the body doing the observing becomes one of the conditions?

---

## CA_ExpandingSpace
Source: `commons/maps/CA_ExpandingSpace/final.md` · SHA-256 `e862892a45edaa1f9a3e0752638b808873835f27f6bf4de0c94fe329f62b9726`

# The surface includes you

<!-- @decaying_bridge -->

The path looks available. Five tiles across, a longer line ahead. Its colours repeat in a panel along the wall. Beneath it lies a shallow basin, already drawn with the addresses of tiles that have not yet disappeared.

Begin at the desk. SOURCE can nominate the pink probe in your place. With PROBE / NEAR showing, press RUN. Follow the gold square W. The number falls. The tile changes colour, then becomes a faint sheet through which the basin is visible. Stop the local experiment. How much of a path is still there?

Use NEAR/FAR to withdraw the probe and run again. Watch the edge of the depleted region before its centre. Something returns through what remained around it. There is no separate instruction ordering this particular patch to grow back into its old outline.

RESTORE prepares a full bridge. Change SOURCE to VISITOR and start RUN. Your position now takes the probe's place. Approach the marked region, wait, move away. The ordinary museum floor continues alongside the basin; recovery ramps rise from its left side. On the bridge, lingering can cost you support. The faint tile can still be seen after it can no longer carry you.

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

One changing value meets two different thresholds. Being visible, carrying a visitor and helping a neighbour recover are separate permissions. The wall uses the same health materials, but its coloured panels supply no bridge collision. A room can wear an answer without offering the same way through it.

There is another condition hidden in “each update.” Choose CHAIN for a small prepared comparison. The bridge begins mostly depleted; three adjacent values are 0.600, 0.495 and 0.000. SOURCE becomes NONE. We can attend to recovery without moving the input at the same time.

STEP once in SYNC. The middle value crosses 0.5. Has the next cell been allowed to use that change already? ORDER switches to SCAN and restores the same beginning. Step again, then use REVERSE and repeat. A different answer can appear even though the neighbouring cells and the amount of time are unchanged. The loop has a direction too.

SYNC reads the previous field throughout the update. SCAN reads answers already written during the same pass. In this study, changing scan direction leaves the synchronous result unchanged; in-place recovery can change. The choice sits in a single line:

```gdscript
var read_states: Dictionary = previous if snapshot_reads else next
```

We have returned to the two arrays from the Life dish. Their separation now changes when a weakened surface can help another part of itself. The rule includes a schedule, even when the picture conceals it.

Restore the full bridge and return to the visitor input. There is pleasure in architecture answering us, and a stranger pleasure when its answer interrupts the role we expected it to play. We can study that relation without deciding that a responsive surface must be alive. A fully depleted field with no healthy neighbours remains depleted. Withdrawal alone does not promise repair.

At thirty simulated seconds this study holds. The museum continues. We leave with a more precise question than whether the path is living: which relations let it carry a body, recover, or become unavailable?

<!-- @ -->

The next room asks what a cell can receive from its neighbourhood when counting healthy neighbours is no longer enough. A softer-looking surface will need another working rule to earn that difference.

---

## CA_SoftRules
Source: `commons/maps/CA_SoftRules/final.md` · SHA-256 `32b4a5843bad091e62e8760a4640f524c53181636d3e9e290bae99ea315e454d`

# What can a cell receive?

<!-- @rd_artifact -->

Two small squares wait on the tables. Behind them, the same squares wait on curved walls. The room has already enlarged their answer, although neither field has taken a step.

At the side desk, find W. It lies just outside the seeded square. Its V reading is zero in both fields. Press STEP once. On the left, a little arrives. On the right, nothing. Look back at the pictures: can you find that difference without the numbers?

Press +100 and let the local clock complete its hundred updates. The fields begin to part. They began with the same values, at the same addresses. They have the same reaction. What has the right-hand square been denied?

EXCHANGE B turns its neighbourhood exchange on and restores both beginnings. Advance again. The two fields now agree. Switch exchange off, replay, and look for the first place where they differ. We can locate the missing relation before giving the result a name.

In the previous hall a neighbour above half health counted as one contribution to recovery. Here a cell stores two concentrations, U and V. It receives differences in concentration from the four sites beside it. For each field, the sum is its neighbours minus four copies of itself:

```gdscript
return a[y*N+(x+N-1)%N]+a[y*N+(x+1)%N]+a[((y+N-1)%N)*N+x]+a[((y+1)%N)*N+x]-4.0*a[y*N+x]
```

The repeated subtraction matters. If all five values agree, this part of the update contributes zero. A higher neighbour can send a positive contribution; a lower neighbourhood can draw one away. No neighbour has to cross a health threshold to count. How much it differs is now part of what it can offer.

There is also a reaction at the address itself. The product U × V × V removes some U and adds some V. A feed term replenishes U; another term removes V. The installation uses the same arithmetic as the project's existing Gray–Scott generator, now exposed one update at a time:

```gdscript
var uvv:float=a*b*b
```

```gdscript
next_u[i]=clampf(a+coupling*0.16*lap_u-uvv+FEED*(1.0-a),0.0,1.0)
next_v[i]=clampf(b+coupling*0.08*lap_v+uvv-(KILL+FEED)*b,0.0,1.0)
```

With exchange off, the right-hand field still reacts. But at an unseeded address V is zero, so U × V × V is also zero. Nothing in that local reaction can make its first V arrive. The left-hand field can receive it. This difference is small enough to calculate and large enough to alter the wall.

Keep that distinction in hand. “Soft” is not a promise that the rule is gentle or that every boundary has disappeared. Both fields still occupy a 32-by-32 grid. The arithmetic writes into separate next arrays before swapping them into the present. Values are clamped between zero and one. At an edge, the remainder operator wraps the neighbour index to the opposite side. The wall has a visible border that the calculation does not share.

Use VIEW U/V. Another distribution appears without a single new update. The initial view doubles V before mapping it into colour; the U view has its own palette. A colour can saturate while the stored value still has room to change. An image is already an interpretation of the field.

Now walk between the two curved displays. Find a patch on a wall, then look for it on the table. Each pair shares the same texture. At the desk you could take in the small field; here you turn within its enlarged image.

Press COAT. The colour surfaces disappear while the table fields continue. Bring them back. The fixed museum floor carries you through both views.[^ca-soft-coating] The field has become something the room can wear. Perhaps you would keep it here, or want it closer, as a lining against a body. What would you change for that other use?

Try INJECT. Both fields receive the same small second patch. Let it run. We are no longer only watching a prepared beginning; we have entered another event into its history. REPLAY can restore that beginning. It cannot make our first encounter with the difference happen again.

<!-- @the_clockmaker_of_rules -->

Further on, the clockmaker has laid out trays, stencils and small worlds. The brass shapes make reading and writing almost look like trades we could perform with our hands. Find the fractional ring. It is a still radial diagram. Its graded appearance does not demonstrate a running Lenia field, and the ornamental crank cannot advance it.

Compare that invitation with the walls we have just left. Both offer pleasure in a patterned body; their means of producing it differ. We need neither reject the ornament nor grant it an operation it does not have. A diagram can help us imagine the machine, then leave us with something still to build.

<!-- @ -->

The local study holds after 2,400 updates. The museum goes on. We have watched a field change and a room wear its image. Carry a question from those surfaces: could a similar form have another way of becoming?

[^ca-soft-coating]: COAT toggles the wall display meshes. Their geometry stays fixed and has no collision shapes; the museum floor supplies support. Sharing a field texture does not create a sensing or growing body. Those would require additional operations.

---

## CA_AgentsCircuits
Source: `commons/maps/CA_AgentsCircuits/final.md` · SHA-256 `b192cbe9b731e350850ef3a9d9dde90c649fe615d9edbe44f281734e2bfca3b1`

# The same pattern, different work

<!-- @ca_rule_explorer -->

Can two constructions resemble one another without doing the same calculation?

Set the rule explorer to Rule 90 and reset its central seed. Press STEP a few times. Follow the triangular gaps that develop between occupied cells. Choose a larger triangle and look for smaller ones arranged within its boundary. Add another row when you need more to compare.

Each new cell is still calculated from a local neighbourhood. No instruction tells the display to draw a large triangle and then decorate it with smaller triangles. The repeated structure becomes visible through many applications of the rule.

Choose one triangular gap in the rule display. Keep a few occupied cells around it in mind, so there is more to recognise than the outline. Carry that small arrangement to the pyramid. Where would it fit? If one part refuses the match, stay with that part before choosing a different resemblance. We have found something the shared appearance did not tell us.

<!-- @sierpinski_pyramid -->

Now turn to the Sierpinski pyramid. Find a small pyramid and compare where its neighbours sit. Then step back and look for the same arrangement at the next scale. This construction makes smaller copies recursively at selected corners. Its procedure begins with a shape and a copying arrangement, rather than a row whose next state must be calculated.

The resemblance is useful because it gives you a question to test. At which scales do gaps correspond? Which relations are altered by moving from a flat history to a volume? You need not force every visible feature into a match. A failed correspondence tells you where the analogy stops.

The row's next state and the pyramid's smaller copies can lead the eye towards a related form. The pleasure of recognising it gives us a reason to compare their making. A name for the resemblance can accompany that inquiry without finishing it.[^ca-resemblance]

Keep the pyramid fixed and press SEED at the desk. Two adjacent cells now begin the history. Build a few rows again. Where do the familiar triangular relations return, and where do they overlap? Press SEED once more to return to the single cell. How much of the resemblance belonged to the rule, and how much to the beginning we gave it?

<!-- @ -->

We will return to the pyramid's way of making in Fractals. First, two almost matching volumes will let us follow one changed value through the same procedure. We have asked how similar appearances can be made differently. What happens when we keep the making the same and alter one small part of the beginning?

[^ca-resemblance]: An organised appearance alone does not demonstrate an agent, a circuit or a general-purpose computer. Such claims require an account of states, operations and the results they can produce. This comparison establishes a question about resemblance and procedure, not a proof of computational universality.

---

## CA_EdgeOfChaos
Source: `commons/maps/CA_EdgeOfChaos/final.md` · SHA-256 `5851c73fa78f74690eb5019fdd7c4facdd6994abddcf995563661073fc30dce9`

# How far does one difference go?

<!-- @self_organization_ca -->

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

The integer conversion removes the fractional part of these nonnegative values. The pull that took five toward four produced 4.75. The stored integer is four. Around it, smaller fractional changes also fell away. A rule about neighbours was accompanied by another rule about what a value may keep.

Continue the fractional run. The wall of difference becomes broad and luminous. Look down at the gain printed on the readout. The display is increasing its sensitivity as the largest difference fades. Its brightness is a decision about visibility. Read the maximum alongside the number of affected cells: that count includes only differences above 0.000001. A trace may leave the counter before it leaves the stored values.

Turn PULL down to zero, with DRIVE still zero, and replay. The intervention stays at its original address. This stillness has kept a memory that the smoothing run lost. We would miss something if we arrived already certain that a moving, complicated-looking field must be the more interesting body.

The hall is called Edge of Chaos. Let the name remain a question. Here the fractional update averages nearby values and adds matched forcing; a spreading difference alone does not establish chaotic amplification. The integer conversion introduces thresholds of its own. We have measured some consequences of those choices. We have not located the one permissible region where life, computation or queerness can exist.

The other works remain in the rear gallery: a screen, local transmission and recovery, a cellular fog field and growing cracks. Each asks for its own account of what passes between neighbours, what is stored, and what the image omits. A shared visual restlessness does not make their rules equivalent.

<!-- @ -->

The next hall, Fractal_Recursion, changes the instruction. Instead of waiting for local exchanges to assemble a larger resemblance, a procedure explicitly asks for another instance of itself. Carry this distinction with you: a form can resemble its neighbour, inherit an earlier state, or be told to repeat. The resemblance does not yet explain the making.

---
