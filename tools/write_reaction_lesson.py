from pathlib import Path
import shutil
R=Path(__file__).resolve().parents[1];M=R/'commons/maps/ProceduralGeneration_Reaction_Diffusion_Systems';S=R/'doc/book/studies/soft-bodies-through-the-hands'/M.name
CA=R/'doc/book/studies/cellular-automata-through-the-hands/CA_SoftRules'
S.mkdir(exist_ok=True)
field=(CA/'field.gd').read_text(encoding='utf8').replace('var exchange := true','var exchange := true\nvar local_terms := true')
start=field.index('func next_pair(');end=field.index('func step()',start)
field=field[:start]+'''func next_pair(a: float, b: float, lap_u: float, lap_v: float) -> Vector2:
	# Keep the CA lesson's four-neighbour exchange; one numerical step has dt = 1.
	var coupling := 1.0 if exchange else 0.0
	var du := coupling * 0.16 * lap_u
	var dv := coupling * 0.08 * lap_v
	if local_terms:
		var conversion := a * b * b
		var supply := FEED * (1.0 - a)
		var removal := (KILL + FEED) * b
		du += -conversion + supply
		dv += conversion - removal
	return Vector2(clampf(a + du, 0.0, 1.0), clampf(b + dv, 0.0, 1.0))

'''+field[end:]
(S/'field.gd').write_bytes(field.encode())
host=(CA/'exchange.gd').read_text(encoding='utf8').replace('right.exchange','right.local_terms').replace('change_exchange','change_local_terms').replace('KEY_E:','KEY_C:').replace('B EXCHANGE','B LOCAL TERMS').replace('E: EXCHANGE B','C: LOCAL TERMS B').replace('Vector2i(12, 15)','Vector2i(15, 15)').replace('W (12,15)','W (15,15)')
host=host.replace('title.text = "A" if side == 0 else "B"','title.text = "A / REACTION + EXCHANGE" if side == 0 else "B / EXCHANGE + OPTIONAL REACTION"').replace('title.font_size = 52','title.font_size = 22')
(S/'reaction.gd').write_bytes(host.encode())
shutil.copyfile(CA/'point_body.gd',S/'point_body.gd')
(S/'study.tscn').write_text('[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="reaction.gd" id="1"]\n\n[node name="ReactionStudy" type="Node3D"]\nscript = ExtResource("1")\n',encoding='utf8')
def code(n):return '\n<!-- student-code:'+n+' -->\n```gdscript\n'+(S/n).read_text(encoding='utf8').rstrip()+'\n```\n'
t='''# What keeps a pattern changing?

## Learning elements

- Local reaction, supply and removal
- Exchange and reaction as separate contributions
- Old state and next state
- Matched starts and equal step counts
- A concentration field and its colour display

<!-- @turing_pattern_generator -->

At the desk, press STEP, then 100 STEPS. The little patch changes slowly. RESET brings it back. REGIME changes two rates and restarts; SEEDING changes the starting arrangement. Compare one intervention at a time.

In the previous hall you changed the appearance of a saved surface without changing its data. Here the data change. Return to the two fields from **CA — What a neighbour offers**. Both contain U and V at every address. That lesson compared neighbour exchange while a supplied reaction ran in both. Now keep exchange in both and open that reaction function.

## Keep the field; open the local rule

Reuse the CA lesson's `field.gd`, two-table display and PointBody. Replace the field with the complete version below; use `reaction.gd` for this comparison. A keeps reaction, supply and removal. B begins with those local terms off, so it only exchanges with its neighbours. Both start from the same 6 × 6 patch and advance the same number of steps.

The new work is in `next_pair`. `conversion = a * b * b` removes an amount from U and adds the same amount to V. With no V present, this conversion is zero. `supply = FEED * (1 - a)` replenishes U toward one. `removal = (KILL + FEED) * b` removes V: in this model, feed also contributes to V's removal. These are the local Gray–Scott terms.[^model]

Neighbour exchange is added separately. The four-neighbour stencil, diffusion coefficients, wrapping boundary and starting square are carried from CA. The installed hall display uses weighted contributions from eight neighbours and different default rates. It demonstrates the same kind of model; it is not an identical numerical run. We keep the learner's known stencil so this lesson changes one part of their program.

One call remains one numerical step with dt = 1, not one second of physical time. Read old U and V, write next U and V, then replace both arrays. The clamp keeps the output in 0–1; it does not make arbitrary coefficients or larger timesteps accurate or stable.

## Predict one address

W is now (15,15), inside the patch. All four neighbours initially match its U = 0.5 and V = 0.25, so both neighbour differences are zero. This position isolates the local terms for the first step.

| Term | Amount |
| --- | --- |
| Conversion from U to V | 0.5 × 0.25 × 0.25 = 0.03125 |
| Supply of U | 0.037 × (1 − 0.5) = 0.0185 |
| Removal of V | (0.060 + 0.037) × 0.25 = 0.02425 |

After one step, A has **U = 0.48725, V = 0.257** at W. B stays **U = 0.5, V = 0.25** there. B still changes around the patch boundary through exchange. Turning off local terms does not freeze the whole field.

## Complete field.gd
'''+code('field.gd')+'''
## Run the comparison in the museum

Use your existing museum project with its player, camera, lighting and XRTools. Keep the three files together. Attach `reaction.gd` to a Node3D at floor level and unit scale, facing its positive Z side, with about 3.3 × 2.4 metres clear. The downloadable `study.tscn` contains only that root and script attachment. Every display, material, label and control point used here is created in code.

The staging is carried from CA. W moves inside the patch; the comparison switch now controls local terms instead of exchange. The unchanged black point still selects an address. Hold it just above either table and trigger to replace a 3 × 3 patch at the corresponding address in both fields. Away from the table, or when unheld, it changes nothing. A new patch changes state without changing the rule or the clock. Release parks the point on its shelf.

- **Enter:** one step. **Space:** 100 steps, up to 2,400.
- **C:** enable/disable B's local terms and restart both fields together.
- **R:** replay from the starting square, preserving the comparison setting.
- **V:** display U or V. This changes the view, not the state.
- **Point trigger / I while holding:** plant the same patch in both fields.

The compact learner uses keyboard controls for time and comparison, with XR/desktop pickup for planting. The installed hall supplies its own nearby VR desk. This reconstruction does not claim that its clock is operated by the point trigger.

## Complete reaction.gd

Read `advance`, `change_local_terms` and `plant` first. The display helpers are the carried construction, not a second task to learn here. Each table and its upright panel share a texture. V is mapped through V × 2 before colouring: a saturated colour is not proof that the stored concentration is one.
'''+code('reaction.gd')+'''
## Make a comparison of your own

Set FEED to `0.050`, leaving KILL, the initial patch and exchange unchanged. Predict the first step at W: U should become **0.49375**, V **0.25375** in A, while B's first-step values stay unchanged. Feed appears in two places, so increasing it both supplies more U and removes more V.

Run from reset. Compare the numbers after one step before comparing the patterns after 100 or 1,000. To recover an identical pair, enable B's local terms and restart: every value in A and B should agree at the same step. If they do not, inspect their starting state, parameters and update order before interpreting the picture.

The next hall maps values into a three-dimensional surface. Carry a clear distinction: stored concentrations, a rule that changes them, and the display through which you see them.

## Carried point_body.gd — unchanged
'''+code('point_body.gd')+'''
<!-- @ -->

<!-- @reaction_diffusion -->

## Other encounters in this hall

The second reaction–diffusion display has its own implementation and clock. It is a comparison to explore, not a synchronized copy of this study. The soft-body samples, bulge and Confessing Body remain wider encounters. The tutorial follows one pair of fields; no additional artifact has to become a prerequisite.

<!-- @ -->

[^model]: John E. Pearson, [“Complex Patterns in a Simple System”](https://arxiv.org/abs/patt-sol/9304003), 1993, studies numerical Gray–Scott patterns. This tutorial uses the project's reduced discretization. Its two concentration variables and colour map are not measurements of chemicals in the room.
'''
f='''# What keeps a pattern changing?

<!-- @turing_pattern_generator -->

A small patch interrupts the pale field. Press STEP. Almost nothing seems to happen. Press a hundred steps. The boundary begins to matter. A name such as Spots or Maze may already have told you what to expect, but the field has not promised to become its label.

There is no finished drawing waiting underneath. Each address receives differences from its neighbours while local reactions consume, replenish and remove what is stored there. The pattern is something those operations make possible. The starting disturbance matters too: an entirely uniform field of U = 1 and V = 0 would remain uniform under this rule.[^model]

Last hall, a still surface acquired another presence when it turned or changed colour. Here, what persists may require continuing exchange. A familiar outline can survive while the values supporting it keep changing. A still image cannot tell us whether we have stopped a process, reached a steady state, or caught a brief resemblance.

Pause at the comparison. Both fields receive their neighbours' differences. In one, the local reaction, supply and removal continue; in the other they are absent. The second field has not stopped. Its initial difference spreads. What does the first keep making that exchange alone does not maintain?

The names tempt us to recognise a living skin: spots, stripes, something dividing. Calling this a metabolism draws attention to what must continue for a form to persist. It does not make the field an organism. These quantities stand in for a limited chemical model. No cell here eats, suffers or decides what it needs.

Still, the encounter changes the question. We have spent several rooms asking what a body keeps when it yields, falls or is recorded. Here we can ask what has to be supplied for a difference to remain. Independence looks less obvious when the conditions of persistence are visible beside the form.

Change a rate, then return to the same beginning. Change the beginning, then keep the rates. Neither comparison gives a complete account of the world. Each lets one relation become legible. Even the edge has been arranged: a value leaving one side meets the other. The field's apparent continuity depends on that return.

<!-- @ -->

<!-- @reaction_diffusion -->

Elsewhere in the room another field runs to its own clock. Similar marks do not make the two displays witnesses of the same event. Nor does a pattern on a surface give that surface the ability to bear your weight. A visible likeness can open an association; following it requires us to say which operation crosses the gap.

The next hall makes such a crossing explicit. Values become a surface you can move around. Carry this question with you: what did the passage into a body preserve, and what did it require us to choose?

<!-- @ -->

[^model]: The installed artifact implements a discretized Gray–Scott model. See John E. Pearson, [“Complex Patterns in a Simple System”](https://arxiv.org/abs/patt-sol/9304003), 1993. Its model belongs to the wider study of reaction–diffusion pattern formation; it is not Turing's original set of equations. The uniform-state claim follows directly from this implementation's update with U = 1 and V = 0.
'''
for name,s in [('tutorial.md',t),('final.md',f)]: (M/name).write_bytes(s.encode())
print('Reaction lesson: carried CA field/display, local terms exposed, unchanged PointBody; three complete code blocks.')
