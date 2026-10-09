"""Authoring snapshot: complete learner files and separate encounter text."""
from pathlib import Path
import re
R=Path(__file__).resolve().parents[1]
S=R/'doc/book/studies/cellular-automata-through-the-hands/CA_BeyondBinary'
M=R/'commons/maps/CA_BeyondBinary'
t='''# A pattern visits an address

## Learning elements

- A two-dimensional present: X and Y are sites, not generations.
- Eight surrounding neighbours; exclude the centre.
- Birth and survival: B3/S23.
- Fixed address, changing occupancy, apparent movement.
- A separate output: one cell controls one lamp.

## Enter with the point

The last hall kept each new row as history. Here both grid directions belong to the **same present**. Five cells wait in a dish, repeated on the floor. Press STEP four times. The arrangement returns one address farther along both directions. No mesh has moved. Different fixed cells have become occupied.

Take the small black point beside the controls. Carry it to a gold square on the floor and use its trigger to STEP. Follow the address while the pattern passes. The point carries the control; its position does not write into the automaton. REPLAY returns to the beginning. The floor remains solid whether a cell is empty or occupied.

We will reconstruct this relationship at table scale: the same 24 × 24 rule and beginning, one marked address, one lamp and the familiar PointBody. The installation has three lamps, RUN, TRACE and preset buttons. The compact study uses one lamp and manual steps. Those other controls are not needed to understand this operation.

Save the previous lesson. Attach `life.gd` to your existing `PointStudy` Node3D in the museum; keep unit scale and about 3 × 3 metres clear. Face its positive Z side. Keep the unchanged `point_body.gd` beside it. The established museum provides camera, light, player and XR Tools. These two files create all of the study's geometry and behaviour; no prepared child nodes are required.

## Count the surroundings

`current` holds 576 Boolean values. `index(x, y)` finds one address in that flat array. Both coordinates wrap at the boundaries. Logical Y becomes depth Z in `cell_position`; the table's physical height stays fixed. Unlike the previous lesson, stepping does not add a row behind the others.

`neighbours` reads a 3 × 3 patch. The condition `dx != 0 or dy != 0` excludes only its centre, leaving eight neighbours. Their count, together with the centre's old state, selects the answer:

| Current cell | Occupied neighbours | Next cell |
| --- | --- | --- |
| Empty | Exactly 3 | Occupied: birth |
| Occupied | 2 or 3 | Occupied: survival |
| Either | Any other count for that state | Empty |

This is Conway's Game of Life, written B3/S23. `evolve` uses the buffer agreement we already know: read every neighbourhood from `old`, write every answer into a new array, then replace `current`. Reading the answers you have just written would produce a different process, dependent on loop order.

## Connect an address

`SITE` is (10,10). Its gold frame stays in place. `redraw` colours the existing cell instances and passes this site's value to `receive`. That function changes the lamp and its globe. It cannot change the next state of any cell.

Press L while the lamp is lit. The connection is off, so the lamp goes dark. STEP still evolves the cells. Press L again: the lamp reads the current value immediately, without advancing time. REPLAY resets the beginning and generation counter, but preserves your link setting.

We separate a rule from a use of its answer. The same false value that removed support in the previous hall now makes a dark patch on a solid table. `make_display` builds that support once; `redraw` never removes it.

## Complete study — life.gd

The rule is in `neighbours`, `next_state` and `evolve`. The remaining code creates its visible receivers and connects the controls. The full file is included so the example runs; the new lesson does not require memorising the furniture construction.

'''
t+='```gdscript\n'+(S/'life.gd').read_text(encoding='utf-8').rstrip()+'\n```\n\n'
t+='''## Carried file — point_body.gd

This file is unchanged from the previous hall. Keep it, rather than rebuilding the point. Its inherited pickable action supplies the trigger signal. Release returns this study's point to its local parking position.

'''
t+='```gdscript\n'+(S/'point_body.gd').read_text(encoding='utf-8').rstrip()+'\n```\n\n'
t+='''## Follow what stays

Use the held trigger or Enter to step. After four generations, the glider has the seed's arrangement shifted by (1,1). At generation eight, A is occupied and its linked lamp is lit. At generation twelve, A is empty again. Each tile's position stayed fixed throughout. R replays; the forty-eight-step limit holds the last state.

## Make another beginning

Replace `seeds` with three positions: (9,10), (10,10), (11,10). Predict the first answer before running: a vertical line at (10,9), (10,10), (10,11). Step again to recover the horizontal line. The centre survives both phases, so A's lamp stays lit. Disconnect the lamp and repeat. Explain why the cells still alternate.

Now connect a different address by changing `SITE` to (9,10). The frame, wire and lamp reading move together. The same blinker should make this lamp alternate. The rule and the cell record do not need to change. You have changed which state the room receives.

## What travels onward

A pattern can travel while its addressed receivers stay put. A Boolean rule can answer a separate object without accepting any influence back from it. In the next hall, proximity becomes an input: the observer's body will enter the conditions of the update.
'''
(M/'tutorial.md').write_bytes(t.encode('utf-8'))
f=(M/'final.md').read_text(encoding='utf-8')
f=f.replace('Press STEP four times.', 'Take the small black point beside the controls. Its trigger carries STEP with you. Press it four times.')
f=f.replace("Each cell has eight neighbours: the second choice, widened from two.", 'Each cell reads the eight surrounding sites in its plane. The centre is not counted among its neighbours.')
f=re.sub(r' These are the lines that choose its next state:\n\n```gdscript\n.*?\n```','',f,flags=re.S,count=1)
f=re.sub(r"The lamp's relation to this world has been written separately:\n\n```gdscript\n.*?\n```", 'The lamp receives the state of one fixed address. Disconnecting it changes that relation, not the rule.',f,flags=re.S,count=1)
start=f.index('Conway chose these rules');end=f.index('\n\nThere is pleasure',start)
f=f[:start]+'''Gardner's 1970 account describes Conway searching for rules whose small beginnings could develop for a while without making their outcome obvious. This was a design ambition, not a proof that growth must always stop. Our finite, wrapped board adds its own conditions. A small experiment can keep a question open without standing for every possible world.'''+f[end:]
f=f.replace('Further in, past the mould network and the dark sphere, a table holds a hexagonal field.', 'The floor continues into a level gallery. The mould and growth networks have space around them; past the dark sphere, a table holds a hexagonal field.')
start=f.index('[^ca-conway]:')
f=f[:start]+'''[^ca-conway]: Martin Gardner, “Mathematical Games,” *Scientific American* 223 (October 1970), [original article](https://www.scientificamerican.com/article/mathematical-games-1970-10/), [article reproduction](https://ibiblio.org/lifepatterns/october1970.html). Gardner reports Conway's exploratory criteria, including the absence of a simple proof of unbounded growth for a starting pattern. That criterion should not be recast as a theorem forbidding unbounded growth. Our installed work uses finite periodic boundaries and a local observation limit.
'''
assert '```' not in f
(M/'final.md').write_bytes(f.encode('utf-8'))
print('Complete two-file tutorial; reflective text remains separate.')
