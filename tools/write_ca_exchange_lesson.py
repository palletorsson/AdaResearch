"""One lesson: paired fractional fields, carried-point input, and exchange."""
from pathlib import Path
import re
R=Path(__file__).resolve().parents[1]
M=R/'commons/maps/CA_SoftRules'
S=R/'doc/book/studies/cellular-automata-through-the-hands/CA_SoftRules'
O=R/'doc/book/iterations/2026-10-08-ca-what-a-neighbour-offers'
intro='''# What a neighbour offers

## Learning elements

- Two fractional values at each address: U and V.
- A neighbour contributes a difference, rather than a count above a threshold.
- A small model class keeps state separate from its display.
- Matched beginnings isolate one changed operation.
- The carried point chooses an address for a shared intervention.

## Bring the point to the tables

In the previous room a healthy neighbour contributed to recovery. Here **how much it differs matters**. Two tables begin with the same square. Each table's field also covers a curved wall. A exchanges with its neighbours; B starts with exchange off. Both still perform the same local reaction.

Find W, the gold address just beside the starting square. At the side desk, press STEP. A receives a little V at W; B receives none. Press +100 to see that small difference develop. EXCHANGE B enables the missing operation and restores both beginnings. Step again: they now agree.

Take the black point beside the desk. Hold its centre just above either table and use its trigger. You plant the same small patch at the corresponding address in both fields. Moving the point without triggering does nothing. Release returns it to its shelf; use the desk to advance time. The floor crossing and INJECT offer a fixed patch instead. These are interventions in a running field, not a different rule.

## Reconstruct the comparison

Save the previous study. Put `field.gd`, `exchange.gd` and the unchanged `point_body.gd` together. Attach `exchange.gd` to the existing `PointStudy` Node3D in your Day Zero museum. Keep unit scale and about 3.3 × 2.4 metres clear, facing its positive Z side. The museum supplies the player, camera, lighting and XR Tools. These files create every child used by this study.

The compact reconstruction has two tables and two flat upright displays. The installed walls are larger and curved; they use the same operation. Use Enter for one step, Space for 100, E to change B's exchange and restart both fields, R to replay, and V to view U or V. In VR the point's trigger plants a seed. The compact model's clock and comparison controls use the keyboard; the installed exhibit has nearby VR desk controls. Desktop learners use the museum's pickup and I while holding the point.

## A field stores two values

`Field` is a small class extending `RefCounted`. Each instance owns two arrays, one for U and one for V. It needs no position or mesh because its job is calculation. `left` and `right` are separate instances, not two names for the same arrays.

The grid has 32 × 32 addresses. `index(x, y)` turns two coordinates into one array index. `posmod` wraps either coordinate to 0–31: the neighbour left of x = 0 is x = 31. This periodic boundary differs from the bounded bridge in the previous hall. The starting 6 × 6 square holds U = 0.5 and V = 0.25; elsewhere U = 1 and V = 0.

## Receive a difference

`laplacian` adds the four axial neighbours and subtracts four copies of the centre. Equivalently, it adds four neighbour-minus-centre differences. A uniform field gives zero. A higher neighbour contributes positively; lower neighbours contribute negatively. The centre is not an extra fifth neighbour.

The supplied Gray–Scott reaction in `next_pair` uses U × V × V to remove U and add V. Feed replenishes U; feed plus kill removes V. Exchange adds 0.16 times U's neighbour difference and 0.08 times V's. B can set just that exchange contribution to zero. `clampf` bounds both results to 0–1. The lesson uses this fixed reaction to compare exchange; deriving the chemical model and choosing a stable numerical scheme are later work.

One call is one numerical step with dt = 1, not one second of real time. `step` reads only the old arrays, writes both answers into new arrays, then replaces the old state. This keeps the simultaneous-update agreement from the earlier halls. A fresh pair of arrays makes that agreement visible; the larger installation reuses its spare buffers.

W is (12,15), just outside the square. Its U neighbours sum to 3.5 and its V neighbours to 0.25. Its own U = 1 and V = 0, so the reaction contributes nothing there. After one step:

| Field | U at W | V at W |
| --- | --- | --- |
| A, exchange on | 0.92 | 0.02 |
| B, exchange off | 1.00 | 0.00 |

That first difference is small enough to predict before watching it spread.

## Complete model — field.gd

'''
between='''
## A position becomes an address

The point keeps its pickup behaviour. `target_site` converts its world position into the study's local space, checks whether it is near either tabletop, and divides its offset into 0.04-metre cells. Logical grid Y becomes tabletop Z. An invalid target returns (-1,-1), so an unheld point or a trigger away from the tables plants nothing.

`seed_at` replaces a 3 × 3 patch with U = 0.5, V = 0.25. It does not add concentrations and does not advance the clock. Both fields receive the same intervention, but can retain different histories elsewhere. R restores the original square. E changes B's exchange and resets both histories for a fair comparison; R alone keeps that choice.

`paint` reads state without changing it. Each table and its upright display share one texture. The initial palette maps V × 2 into colour, clamped at one; U has another palette. V changes the view, not the simulation. A saturated colour need not mean a stored concentration of one. These surfaces are pictures of the field; the tables keep their physical support.

## Complete study — exchange.gd

Read `target_site`, `plant`, `advance` and `paint` first. `box` and `make_display` provide the complete staging. There is one `_ready`, and no required child is hidden in a scene reference.

'''
point='''
## The same carried object — point_body.gd

This file is unchanged from the previous hall. Keep your existing copy. It appears here so the three-file example is complete.

'''
end='''
## Predict, intervene, compare

Replay with B's exchange off and step once. Check W's two answers against the table above. Press V: the colours change while the tick and stored values remain the same. Press E and step once: with exchange on for both, every address should agree.

Now restore B's exchange-off comparison. Carry the point to a different address, outside the starting square, and plant. Step 100 times. Find a site just beyond that second patch. Can anything make its first V arrive without exchange? At an untouched site, V = 0 makes the local reaction product zero. An address can receive its first V from its neighbours.

Make one independent edit: in `reset`, after `right.reset()`, add `left.seed_at(Vector2i(0, 0))` and `right.seed_at(Vector2i(0, 0))`. Predict all nine addresses before replaying. The patch appears at x = 31, 0, 1 and y = 31, 0, 1. Its split appearance is one neighbourhood crossing the periodic boundary, not four unrelated seeds. After replay, find which side can send V into an adjacent unseeded address. Remove those two added lines to return to the original beginning.

Both clocks stop at 2,400 steps. Reset to make another comparison. You leave with a field class that can be shown on more than one surface, a point that can intervene without replacing the rule, and a distinction between what happens at an address and what can arrive from elsewhere. The next hall compares a cellular history with recursive construction: similar forms can have different ways of becoming.
'''
def block(name):return '```gdscript\n'+(S/name).read_text(encoding='utf-8').rstrip()+'\n```\n'
(M/'tutorial.md').write_bytes((intro+block('field.gd')+between+block('exchange.gd')+point+block('point_body.gd')+end).encode('utf-8'))
s=(O/'before/final.md').read_text(encoding='utf-8')
s=re.sub(r'\n```gdscript\n.*?\n```\n','\n',s,flags=re.S)
s=s.replace('For each field, the sum is its neighbours minus four copies of itself:', 'For each concentration, it adds the four neighbours and subtracts four copies of the centre.')
s=s.replace('now exposed one update at a time:', 'now exposed one update at a time.')
s=s.replace('Even the right-hand square\'s seeded cells cannot keep their V: at feed .037 and kill .060 the reaction alone has no resting state other than full U and no V, so by the end of the first hundred updates that square has nearly faded.', 'By the end of the first hundred updates, the right-hand square has nearly faded. The same local reaction has had a different future without exchange.')
s=s.replace('Stay on the mark.', 'There is also the small black point beside the desk. Take it to either table and hold it above a place you choose. Its trigger gives both fields a seed at that address. We have brought the same object onward, but changed what its position can do. On the bridge it helped remove support; here it introduces a concentration. Neither consequence belongs to the sphere alone.\n\nStay on the mark.')
s=s.replace('images/ca-seed-crossing.png','images/exchange-seed.png')
s=re.sub(r'\n{3,}','\n\n',s)
(M/'final.md').write_bytes(s.encode('utf-8'))
print('CA_SoftRules: three complete files; prose reflection; same carried point.')
