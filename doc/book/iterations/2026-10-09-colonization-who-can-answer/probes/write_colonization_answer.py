from pathlib import Path
import re
R=Path(__file__).resolve().parents[1]
M=R/'commons/maps/PG_Space_Colonization'
S=R/'doc/book/studies/procedural-generation-through-the-hands/PG_Space_Colonization'
O=R/'doc/book/iterations/2026-10-09-colonization-who-can-answer'
def code(name):return f'<!-- student-code:{name} -->\n```gdscript\n'+(S/name).read_text(encoding='utf-8').rstrip()+'\n```\n'
text='''# Space Colonization — who can answer

## Learning elements

- Assign a request to its nearest eligible site
- Sum unit directions, then take a fixed-length step
- Store a branch as a position and a parent index
- Compare growing tips with all existing sites
- Keep a specimen while changing a rule

Genetic Evolution changed a score while keeping the candidates. Here we keep a set of positions and change which sites may answer them. The vectors return from Forces; the parent and child return from recursive trees. We will build a small version of the growth already in this hall.

## Predict one step

At the existing desk, press RESET. Three pink requests wait above the root: (−2, 3, 0), (2, 3, 0) and (0, 5, 0). Each contributes a direction of length one. The sideways components cancel; the upward components add. Predict the first child, then press STEP. It appears at (0, 0.5, 0). The root stays where it was.

Press FIELD once for eight known points. Under TIPS, each growing end is replaced by its successor. Starting with one root, this makes a strand. HOLD a specimen, then press POLICY. The field restarts under NETWORK. Older sites may now receive requests again, so one site can acquire several children across generations. Each site still adds at most one child in a generation.

These attraction points are coordinates. They exert no physics force. NETWORK names a control; each child still has one parent, so this construction does not join branches into loops.

## The complete small study

Keep the prepared Endless Museum and its player, floor, camera and XRTools. Save these three files together. Attach `colony.gd` to an empty, unit-scale Node3D in your working copy. A temporary study fits behind the main display at hall-local (9.5, 0, 17), facing the entrance with yaw 180 degrees. The branch model is displayed at 0.4 scale; its numerical half-metre step appears as 0.2 metres. No new branch collisions or floor are supplied.

Use the familiar point's held trigger, or SPACE, to advance one generation. Moving the point alone changes nothing. F switches between three and eight requests. P changes eligibility and restarts the same field. H keeps the current branch geometry. R restores the three-point opening and TIPS; the held specimen remains. The installed desk's 96-point canopy stays available as a larger comparison.

### A position remembers its parent

Each entry in `nodes` stores a position and a parent index. The root uses −1 because it has no parent. New entries are appended, so older indices remain valid. Following those indices recovers the branches without storing cyclic object references.

`eligible()` returns every site under NETWORK. Under TIPS it returns only sites that no existing entry names as a parent. The supporting nearest-site search is included in full: each active point chooses one eligible site strictly nearer than eight metres. Equal distances keep the first site in list order. A request within 0.32 metres of that chosen site is marked for removal.

The new operation is inside `decision()`. Subtract the site from the request, normalize that vector, then add it to the site's sum. Normalizing each request gives it a unit contribution; a faraway point gets no extra length. Normalizing the accumulated sum afterwards gives the direction of the next half-metre step.

All assignments read the same generation. `step()` collects children separately and appends them after the decisions, so a newborn site cannot attract another request during its own generation. Reached requests leave `active`; `points` keeps the original field for the dark witnesses.

'''+code('growth.gd')+'''
The two normalizations do different jobs: one controls each contribution, the other fixes the final step length. No contribution, or an exactly cancelling sum, yields no child in this small program. NETWORK also skips a proposed position already occupied or already proposed in this generation.

This is a declared edge in the reconstruction: the installed TIPS code can append a zero-length child when nonzero requests cancel exactly. Here we stop that site instead. The installed NETWORK code already rejects cancellation. We retain the museum code and test this difference explicitly; we do not hide it under an identical tree silhouette.

The limits are 192 sites and 60 generations. Reaching a limit does not mean every request has been reached. The readout distinguishes a budget from exhausted requests or a lack of new direction.

### Give the decisions a body

The following file joins the model to the museum. It draws a sphere at each request and a thin cylinder between each parent and child. Those construction helpers reuse our earlier geometry. They are here so the example runs; they are not another lesson in making a sphere.

For the first site with a nonzero sum, thin pink rods show the requests, gold rods show their contributions, and white shows the proposed step. The preview is calculated from the current state: after STEP it shows the next decision. HOLD makes a deep copy of positions and parent indices. The smaller witness is 0.6 times the live display scale. It preserves geometry, not the full field, policy or a resumable simulation state.

'''+code('colony.gd')+'''
### Keep the point we already made

This is the same `point_body.gd` used in Genetic Evolution, unchanged. The new behaviour belongs to its host: a held action asks the model for one step. XRTools remains the Day Zero dependency.

'''+code('point_body.gd')+'''
## Make a comparison you can explain

Start with three requests and one step. Check that the child is (0, 0.5, 0). Then switch to eight requests, step fifteen times under TIPS and HOLD. Switch to NETWORK and step fifteen times again. Find a parent with more than one child. The points, step length and influence radius stayed the same; the eligible set changed.

Now make one edit in `growth.gd`: remove `.normalized()` from the assignment to `direction` inside `decision()`. Keep the later normalization in `step()`.

Predict before running. In the symmetric three-point opening both versions still go straight up. Switch to the eight-point field to reveal the difference: longer displacement vectors now contribute more. From its root their raw sum is (−1.5, 29.5, 0.9), so the edited first child is approximately (−0.0254, 0.4991, 0.0152). It is still half a metre from the root. Compare this with the original unit-vote result and explain why changing one line changes the direction without changing the step length. The gold rods now represent distance-weighted contributions; do not call them unit directions.

Restore the original line before carrying the model onward. This experiment changed how requests count, not where they were placed. It supplies no evidence that the weighted version is a better tree.

## Return to the room

The existing desk has a third FIELD: an authored 96-point canopy. Compare it under both policies. More points can change the form, but do not guarantee forks or completion. Walk around the large specimen; the museum's ramp supports you independently of the branch drawing.

Carry the separation between the field, the eligible sites and the operation that combines requests. Branching Growth follows: a site will respond to one nearest invitation instead of accumulating several. We can locate that change before we compare the resulting forms.
'''
(M/'tutorial.md').write_bytes(text.encode('utf-8'))
final=(O/'before/commons/maps/PG_Space_Colonization/final.md').read_text(encoding='utf-8')
start=final.index('Start with one request.')
end=final.index('Here `segment_length`')
final=final[:start]+'''A distant request gets no greater weight merely because it is farther away. Each offers a direction; the three directions meet at the root. The sideward demands cancel here. What remains points upwards, and a child takes one small step along it. The tutorial rebuilds this decision, including the cases where nothing remains to follow.

'''+final[end:]
final=final.replace('Here `segment_length` is 0.5.', 'The step is half a metre.')
(M/'final.md').write_bytes(final.encode('utf-8'))
print('Tutorial has three complete files; reflection retains encounter and argument with code moved left.')
