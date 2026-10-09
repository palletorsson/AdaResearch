"""Publish the focused prose around the complete maintained learner files."""
from pathlib import Path
import re
R=Path(__file__).resolve().parents[1]
M=R/'commons/maps/CA_ExpandingSpace'
S=R/'doc/book/studies/cellular-automata-through-the-hands/CA_ExpandingSpace'
O=R/'doc/book/iterations/2026-10-08-ca-the-surface-includes-you'
intro='''# The surface includes you

## Learning elements

- An external position becomes input to a cellular rule.
- A dictionary pairs each grid address with a fractional state.
- Four axial neighbours and a bounded field.
- Separate thresholds for recovery and physical support.
- Snapshot updates compared with a directional scan.

## Bring the same point

In the previous hall, carrying the point changed nothing in the cells. It carried STEP. Here **where you hold it matters**. The bridge and its wall frieze show the same field. Take the black point beside the desk, bring it near a tile and press its trigger. Each press selects HAND and advances one tenth of a simulated second. A nearby tile loses health. Release the point and STEP again: recovery now depends on what remains around the tile.

Try the installed bridge first. Its desk also offers a fixed PROBE and the actual VISITOR as input, RUN for repeated steps, and a full RESTORE. The gold address W appears on both floor and wall. Below 0.2, its floor tile loses collision support. The basin catches you; the ramps return you to the museum floor. A wall panel can show the same value without opening a hole in the wall.

We reconstruct this operation at one-fifth scale, with the same PointBody and rule. Save the previous lesson. Attach `presence.gd` to your existing `PointStudy` Node3D in the museum. Keep unit scale, about 2 × 3 metres clear, and face its positive Z side. Place the unchanged `point_body.gd` beside it. Day Zero's museum still supplies the player, camera, light and XR Tools. These two files create all study geometry; no prepared child nodes are needed. The small model has manual steps, one point input and a tray beneath its tiles. Walk on the installed bridge, not this table.

## An address keeps a fraction

`current[Vector2i(x, y)]` holds a number from 0 to 1. The dictionary makes the address explicit; it replaces the flat Boolean array used in Life. All 80 addresses exist throughout the experiment. A disappearing tile does not delete its entry.

Logical Y runs along the bridge, becoming physical Z in `cell_position`. `view_position` shrinks that simulation position and places it on the table. `input_position` reverses the conversion: world position → study-local position → simulation position. This lets the smaller model use the installed rule's distances. Moving or rotating the entire study does not alter those local relations.

The radius is 1.35 simulation metres, which appears as 0.27 metres on this model. Distance uses all three coordinates, including height. The input is the held point's centre. In the installed VISITOR mode it is the tracked body's origin. Neither measures weight or contact pressure.

## One update

For each address, `evolve` makes one choice. If the point is held and its centre is nearer than `RADIUS`, health falls by 0.04. Otherwise each healthy axial neighbour adds 0.01. The four directions are north, south, east and west; diagonals and the centre are excluded. Missing neighbours at the boundary contribute nothing. This field does not wrap as Life did.

`maxf` and `minf` keep the result between 0 and 1. Near the input, decay takes the whole branch: recovery is not added at the same time. Moving the point while the clock is stopped changes no cell. Trigger or Enter commits one update.

| Health | Helps neighbours recover? | Tile supports a body? |
| --- | --- | --- |
| Greater than 0.5 | Yes | Yes |
| 0.2 through 0.5 | No | Yes |
| Below 0.2 | No | No |

`redraw` uses the new value to change colour and collision. Each wall panel shares its floor tile's material. The wall backing and lower tray stay solid. Changing a state and deciding what that state permits remain separate operations.

## Complete study — presence.gd

Read `input_position`, `neighbours`, `evolve` and `step` first. They contain the new operation. `make_display` builds the two views and their support; it is included so the reconstruction is complete. There is one `_ready`, and every reference is created or declared here.

'''
tail='''
## Unchanged carried object — point_body.gd

This is the same PointBody file used in the previous hall. It keeps its small dark sphere, pickup behaviour and action signal. Copy it only if it is not already beside the new script.

'''
end='''
## Let the edge recover

Hold the point's centre about 0.05 metres above W and STEP 21 times without moving it. The value reaches 0.16; the faint tile no longer supplies support. Release the point. Each later Enter press advances recovery without a proximity input. The outer edge of the depleted patch recovers first because it still has healthy neighbours. A wholly empty field has none and will not repair itself merely because you leave.

Now hold the point directly above W but more than 0.27 metres from its centre. Predict the next update before pressing. Height alone can take it outside the radius. Lower it and repeat. You are testing a three-dimensional distance, not painting onto a two-dimensional grid. Desktop learners can use the museum's established grab operation and Enter while holding the point.

## Does the order count?

This comparison returns to the old-to-next agreement; it does not add another input. Press C. The field begins at zero except (1,6) = 0.600 and W = 0.495. Hand influence is disabled for this comparison. In SYNC, all recovery counts read `old`. STEP once: W becomes 0.505, but (3,6) remains zero because it read W's old value.

Press O to select SCAN and reset that same beginning. Now counts read `next`, including answers already written. STEP: (3,6) becomes 0.01. W's newly healthy value was available before the loop reached its neighbour. Press V to reverse the scan and reset; STEP again. That neighbour now stays at zero. SYNC gives the same answer in either order.

Make one independent edit: change W's CHAIN beginning from 0.495 to **0.49**. Predict whether the third cell gains anything in forward SCAN, then run it. W reaches exactly 0.5. The condition is strictly greater than 0.5, so the third cell still gains nothing. The threshold, not the rounded appearance of the colour, decides.

R restores the full field and permits hand input again. O and V preserve the chosen beginning while resetting time. At 300 steps—30 simulated seconds—the study holds its state until reset. Releasing the point does not advance time by itself.

You leave with an input connection you can name, and two consequences you can distinguish: a value can cease to help its neighbours before it ceases to hold you. The next room asks what happens when the neighbourhood offers more than a count above a threshold.
'''
text=intro+'```gdscript\n'+(S/'presence.gd').read_text(encoding='utf-8').rstrip()+'\n```\n'+tail+'```gdscript\n'+(S/'point_body.gd').read_text(encoding='utf-8').rstrip()+'\n```\n'+end
(M/'tutorial.md').write_bytes(text.encode('utf-8'))
s=(O/'before/final.md').read_text(encoding='utf-8')
s=re.sub(r'\n```gdscript\n.*?\n```\n','\n',s,flags=re.S)
s=s.replace('Nearby cells lose a fixed amount on each update:', 'Nearby cells lose a fixed amount on each update. The number records this particular rule, not a diagnosis of a body.')
s=s.replace('Below 0.2, its collider is disabled:', 'Below 0.2, the tile stops supplying collision support.')
s=s.replace('The choice sits in a single line:', 'What an update is allowed to know changes the result.')
s=s.replace("recovery ramps rise at either end of its right-hand edge, on the desk's side", "recovery ramps rise at either end on the desk's side")
s=s.replace('Look up to find W again.', 'You can bring the black point from beside the desk into this relation. Hold it near the surface and use its trigger to give the rule another position. The same object that carried STEP in the previous hall now brings a location as well. Release it and continue stepping: the input has withdrawn, but its consequences remain.\n\nLook up to find W again.')
s=s.replace('images/ca-presence-depleted.png','images/presence-depleted.png')
s=re.sub(r'\n{3,}','\n\n',s)
(M/'final.md').write_bytes(s.encode('utf-8'))
print('Complete tutorial and prose reflection written for CA_ExpandingSpace.')
