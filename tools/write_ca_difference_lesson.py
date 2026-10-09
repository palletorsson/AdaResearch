"""Write the focused reconstruction from its maintained learner scripts."""
from pathlib import Path
import re
R=Path(__file__).resolve().parents[1];M=R/'commons/maps/CA_EdgeOfChaos';O=R/'doc/book/iterations/2026-10-08-ca-what-a-difference-keeps';S=R/'doc/book/studies/cellular-automata-through-the-hands/CA_EdgeOfChaos'
intro='''# What a difference keeps

## Learning elements

- Copy a beginning and change one address.
- Keep the update and forcing identical in two runs.
- Measure how many addresses differ and how large the difference is.
- Compare integer truncation with retained fractional values.
- Select a spatial section without advancing time.
- Read display gain separately from the values it makes visible.

## Bring the comparison forward

In the previous room, a changed seed altered the row history while the copied pyramid stayed fixed. Here both volumes use the same procedure. We change one starting value in B and follow what happens to that difference.

Begin in the existing paired study. Set SEED to UNIFORM, DRIVE to zero, PULL to 0.25 and ONE CELL on. Both volumes start at four, except B's centre, which starts at five. Their update counter is still zero.

Walk between the volumes. At Z=5, the selected section contains that centre; at Z=6, it does not. The floor and wall can lose sight of a difference without the arrays losing it. Take the familiar black point beside the console to choose the section by hand instead. While it is held, the hand takes priority. Release it to resume walking as the reader. Its trigger advances one update.

## Reconstruct this experiment

Keep the Day Zero museum and save the previous study. Put `paired.gd`, `difference.gd` and your unchanged `point_body.gd` together. Attach `difference.gd` to the existing `PointStudy`, at unit scale. Approach from positive Z; leave about 3.2 × 2.5 metres clear. The existing museum supplies the player, camera, lighting and XR Tools. Every study mesh, material, label and collider is created below.

The miniature keeps both complete 11³ volumes and their three section images. Move the held point forward and back along the middle rail to select Z. Trigger or Enter advances one update. It starts with the quiet, uniform, integer comparison above; the full exhibit initially uses its scattered, driven beginning. The miniature uses keyboard controls for parameters. The installation retains its nearby VR buttons and walking reader, plus the enlarged difference floor.

## Copy, then intervene

`a` and `b` are packed arrays of 64-bit floating-point numbers. One index represents `x + N*y + N*N*z`. `b = a.duplicate()` makes an independent copy. Only then does B gain one at `site`.

For each address we keep a list of valid neighbours. This is the 26-neighbour volume from the second CA hall, with positions outside the box omitted. A corner has seven neighbours. It does not wrap to the opposite side.

One update keeps three quarters of the present value and adds one quarter of the neighbours' average. More generally, `pull` selects that fraction. Both next arrays are completed from the old arrays before either becomes the present.

The supplied `sample` function returns a reproducible forcing value for an address and generation. A and B receive the **same** value. It is a finite arithmetic schedule, not a claim of independent random samples. Its number recipe is supplied so this lesson can focus on a fair comparison.

`integer_storage` describes what answers we retain, not the array's machine type. In that mode, `int(value)` discards the fractional part before the result returns to the floating-point array. Fractional mode retains that part, subject to finite floating-point precision. Both modes clip answers to the range 0–9.

## Complete paired model — paired.gd

'''
middle='''
## Measure before judging the picture

`report` subtracts the arrays address by address. The count includes only absolute differences greater than 0.000001. Maximum and mean use every stored difference, including those below that threshold. These quantities answer different questions: how widely detectable difference is distributed, how large the largest difference is, and its average over the whole volume.

The A and B palettes use the same fixed 0–9 scale. The third image magnifies absolute difference by `gain = 1 / max(maximum, 0.000001)`. Gain changes only the image. It is printed beside the measurements because a bright picture can accompany a fading difference.

`select_slice` changes an address in the receiver, not a generation in the model. At each selected Z, X and Y remain spatial coordinates. Gold frames locate that plane in both volumes. Moving the point alone changes neither array; its trigger calls `step`. On release it parks at the selected slice.

## Complete study — difference.gd

Read `step`, `select_slice` and `paint` first. `make_display` supplies the staging. As before, the model and its display have separate jobs.

'''
point='''
## Carried object — point_body.gd

Keep your existing PointBody. Its unchanged code is included so the three-file reconstruction is complete.

'''
end='''
## Make three predictions

**First, keep INTEGER, UNIFORM, PULL 0.25 and DRIVE 0.** At the changed centre, the calculated answer is 4.75. Integer storage keeps four. Its neighbours' small increases also lose their fractions. After one update the count and maximum difference are zero. Both complete arrays agree.

**Now press I.** This selects FRACTIONAL and replays the same beginning. After one update, predict a smaller peak spread over more addresses: the centre differs by 0.75; each of its 26 neighbours differs by 0.25/26. The count is 27. Continue to update 20. Read the maximum beside the gain before calling the larger lit region an amplification.

**Press P to set PULL to zero.** With DRIVE still zero, this replays the beginning and then preserves the original difference at one address through every step. An unchanged picture can retain something that the smoothing update distributes.

Press C to remove the one-cell intervention. A and B should agree. Press N to enable the shared drive; they should still agree. This is a control for the comparison. Press B to switch to the supplied scattered beginning. C, N, B, I and P all replay both arrays after changing their setting. R replays while preserving settings. None changes the selected slice. The model stops at 100 updates.

## Make an independent change

In `paired.gd`, change `site` to `Vector3i(0, 0, 0)`. Run in UNIFORM, FRACTIONAL mode with PULL 0.25 and DRIVE zero. Select Z=0 to see the beginning. Before STEP, predict which addresses can receive it.

After one step, **eight** addresses differ: the corner itself and its seven valid neighbours. The corner difference is still 0.75. A receiving cell averages its own neighbour list: the adjacent edge cell (1,0,0) receives 0.25/11; the interior cell (1,1,1) receives 0.25/26. There is no wrap to the far face. The changed location exposes a boundary choice hidden by the central example. The scaffold expects `site` inside 0–10 on each axis; its +1 experiment is compared from the uniform beginning.

Explain three different disappearances: moving to a slice that misses the changed address, integer storage discarding the difference, and a stored difference falling below the count's threshold. They require different evidence.

This finishes the cellular-automata passage with a testable comparison. In the unforced fractional case, averaging spreads and reduces the peak; brightness alone does not establish chaos. Fractals returns to explicit repetition: what changes when the procedure calls itself instead of waiting for neighbouring states to exchange values?
'''
def block(name):return '```gdscript\n'+(S/name).read_text(encoding='utf-8').rstrip()+'\n```\n'
(M/'tutorial.md').write_bytes((intro+block('paired.gd')+middle+block('difference.gd')+point+block('point_body.gd')+end).encode('utf-8'))
s=(O/'before/final.md').read_text(encoding='utf-8')
s=s.replace('images/ca-walking-slice.png','images/one-difference.png')
s=s.replace('Return to the console. Press STEP.', 'The black point waits beside the console. Take it and choose a section with your hand. The walking reader yields while you hold it; release returns that choice to your body. The same sphere has carried a mark, planted a seed and inspected a row. Here it changes what we can see without changing what is there. Its trigger lets the next update arrive.\n\nReturn to the console. Press STEP.')
s=re.sub(r'Here is the local instruction, before storage:\n\n```gdscript.*?```\n\n`sa` is the sum of A\'s valid neighbours\.', "Each cell keeps part of its present value and moves the remainder toward its neighbours' average. Both volumes receive the same added disturbance, then their calculated values are clipped to the allowed range.",s,flags=re.S)
s=re.sub(r'The fork is one short line:\n\n```gdscript.*?```', 'The two versions part at the moment of storage.',s,flags=re.S)
s=s.replace('each cell is infected with a fixed probability per infected neighbour and recovers with another', 'a susceptible cell with at least one infected neighbour is infected with a fixed probability, and an infected cell recovers with another')
(M/'final.md').write_bytes(s.encode('utf-8'))
print('Three complete learner scripts; reflection keeps encounter and removes two code blocks.')
