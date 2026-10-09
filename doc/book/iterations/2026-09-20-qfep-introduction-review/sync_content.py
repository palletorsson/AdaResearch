from pathlib import Path
import json, hashlib

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
ROOM = 'QFEP_Introduction'
BASE = ROOT / 'commons/maps' / ROOM

def read(path):
    return json.loads((ROOT / path).read_text(encoding='utf-8-sig'))

def write(path, data):
    (ROOT / path).write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')

# Keep the earlier ambitions recoverable, explicitly separated from shipped behaviour.
# The frozen originals also retain every passage, including claims needing correction.
originals = HERE / 'before/commons/maps' / ROOM
archive = '# Earlier laboratory proposals — retained for development\n\n'
archive += ('Status: historical drafts, preserved on 20 September 2026. These are not instructions for the current hall and their scientific and philosophical claims are not validated by preservation. '
            'In particular, memory projections, room-wide responses and haptic weight are design ambitions, not verified interactions. '
            'The current technical.md, critical.md and final.md describe the implemented encounter.\n\n'
            'Development candidates: let a term recall earlier encounters; connect one measured simulation to the formula; record a visitor’s parameter trajectory. '
            'Each needs an explicit receiver and a comparison the learner can test. The formula need not absorb every earlier sequence to make those returns valuable.\n\n')
for name in ['technical.md', 'critical.md']:
    archive += '\n---\n\n## Preserved ' + name + '\n\n' + (originals / name).read_text(encoding='utf-8-sig') + '\n'
(BASE / 'design-proposals.md').write_text(archive, encoding='utf-8', newline='\n')

(BASE / 'technical.md').write_text('''# Keep a reading; change its arrangement

The previous hall let you question a formula. This workbench evaluates one small implementation of it. Its four rails supply F, E, lambda and phi, each between zero and one. None is a sensor measuring the surrounding room.

Move one rail. Watch its point on the four-axis diagram and the number below. Press KEEP: the pale outline and retained total stay while the coloured shape follows your next movements. The instrument holds one arrangement at a time. Pressing KEEP again replaces it.

The implemented calculation is:

```gdscript
return _F - _lambda * _E + _phi * rate_delta_e
```

Here `rate_delta_e` is fixed at 0.30. Its historical name does not make it a measured rate. F and E are supplied numbers too; this workbench neither estimates a probability distribution nor evaluates free energy from a model.

Try F = 0.4, E = 0.2, lambda = 0.5 and phi = 0.5. The result is 0.45. Keep it. Change F to 0.6 and E to 0.6. The total returns to 0.45, but the two outlines differ. Two increases have compensated in this calculation. The saved arrangement makes their difference available to inspection.

Then set lambda to zero. Moving E still changes the diagram, but no longer changes this total. Restore a nonzero lambda and repeat. A control’s consequence depends on the expression receiving it.

The name and colour are selected separately: the script compares your four values with seven authored reference tuples, using the sum of absolute differences. The closest example supplies the label. Equal totals need not receive the same name. These are project references, not physical phases detected by the instrument.

The nearby formula and separate lambda/phi rails remain secondary comparisons. They are not wired to the workbench’s four controls. The separate phi rail runs from -1 to +1; this console’s phi runs from 0 to 1. Read the particular instrument’s domain.

The current hall preserves the earlier term spheres and other works. Proposals for remembered scenes, a responsive room and a measured receiver remain in [design-proposals.md](design-proposals.md), clearly marked as development work. Next, the F hall can ask what a prediction would actually be compared against.
''', encoding='utf-8', newline='\n')

(BASE / 'critical.md').write_text('''# What the total cannot keep

The coloured shape changes. The number returns. Without the retained outline, this return could look like nothing happened.

Try it before giving it a larger name. Find two arrangements that nearly agree in their total. One may have more F, another less E. Their equality belongs to the calculation you are using. Your hand can still distinguish the paths that brought them here.

This is where the critical question enters the tutorial. A summary gives you something useful to compare, but it decides which differences can compensate for which others. If this number later selects a body, a route or an action, what differences would that selection leave behind? The present console does not make those decisions. It gives the question a visible beginning.

KEEP preserves an arrangement without requiring it to win. You can return to it, disagree with it, or pass through the same total from elsewhere. There is room here for an account of difference that does not immediately turn difference into a ranking. That possibility is part of Ada’s queer inquiry; a high entropy setting does not acquire it automatically.

The rail also draws a boundary. Phi cannot go below zero on this console, though the separate rail nearby permits it. Neither handle is the whole concept. A limit becomes available to thought when we can meet it, name it and build a comparison beyond it.

Even the reassuring names are choices. The instrument calls your setting the nearest of seven project references. Move across a boundary and its colour changes. Nothing in that colour change proves a natural division between kinds of life. It exposes a comparison rule, which can itself become material for another experiment.

The earlier proposal imagined the laboratory recalling scenes from your walk. That remains a promising encounter to build. It would be stronger if those returns could resist the formula as well as illustrate it: an earlier work might contain something this new summary cannot keep.
''', encoding='utf-8', newline='\n')

(BASE / 'summary.md').write_text('''# QFEP Introduction — four controls, one result

The opening laboratory hall follows Crisis Synthesis with a manipulable calculation. Its primary work is the QFEP balance workbench: four normalised controls, a four-axis display, and KEEP to retain one outline and total. The learner seeks different arrangements with the same total, then tests why E stops contributing when lambda is zero.

The map is 13 by 12 cells. The workbench at (6,4) and formula at (6,8) face the entrance. A level approach, side passage and exit connect the encounter. Raised cells that blocked the control row and exit have been lowered. All eleven placed artifact families remain; the formula, separate rails, spheres and other works provide secondary comparisons.

The console evaluates F − lambda × E + phi × 0.30. Its inputs are supplied values, not measurements. Its coloured name is the nearest of seven authored references. The separate phi rail has a signed range, unlike the console.

The declared next hall is QFEP_F_Term, on prediction. It and QFEP_Sandbox still need restoration to the authored museum route; the eight-hall sequence intention is retained. Desktop Godot checks cover controls and selected walking routes. Headset reach, comfort and learner understanding remain unverified.
''', encoding='utf-8', newline='\n')

(BASE / 'blurb.md').write_text('''*Can two different arrangements give the same number?*

Move a control. Keep an outline. Change the arrangement and try to bring its total back.

The formula offers a way to compare. Your hands may find something it leaves out.
''', encoding='utf-8', newline='\n')

p = 'commons/artifacts/registry/qfep.json'
d = read(p)
a = d['artifacts']['qfep_balance_workbench']
a.update(description='Four normalised controls evaluate F - lambda*E + phi*0.30. A four-axis diagram keeps the contributions visible; the colour/name comes from the nearest of seven authored project references. Opt-in comparison adds KEEP for one retained outline and total. No entropy measurement or physical phase detection.', interaction='grab_slide; press KEEP in comparison mode')
a['parameters']['comparison'] = 'Optional on/off; default off. KEEP retains one four-value arrangement and its total. Enabled in QFEP_Introduction.'
a['parameters']['settling'] = 'Initial example: edge, order, entropy, integration or synthesis. These are authored tuples, not detected physical phases.'
write(p, d)

p = 'commons/data/artifact_roles.json'
d = read(p)
d['roles'][ROOM]['orange_and_apples'] = 'secondary'
if 'orange_and_apples' not in d['order'][ROOM]['secondary']:
    d['order'][ROOM]['secondary'].append('orange_and_apples')
write(p, d)

p = 'commons/data/museum_core_encounters.json'
d = read(p)
r = d['rooms'][ROOM]
r.update(reason='Keep one outline and total, then find another arrangement with the same total. Test the zero-weight case; distinguish supplied quantities and authored reference names from measurements.', status='encounter_and_text_revised', learner_verified=False, review_evidence=HERE.relative_to(ROOT).as_posix()+'/SUMMARY.md')
for key, name in [('text_sha256', 'final.md'), ('map_sha256', 'map_data.json')]:
    r[key] = hashlib.sha256((BASE / name).read_bytes()).hexdigest()
write(p, d)

lines = {
 'qfep_balance_workbench':'The outline remembers what the total cannot. Keep one arrangement; find another that gives the same number.',
 'tt':'Read a term, then ask which operation receives it.',
 'grab_sphere_F':'A term can be held before its quantity has been measured.',
 'grab_sphere_E':'What would count as an outcome here?',
 'grab_sphere_lambda':'A weight belongs to a relation. What is it weighting?',
 'lambda_slider':'A separate rail offers another example; it does not drive the four-control console.',
 'phi_slider':'This rail lets you go below zero. The console does not.',
 'qfep_formula_3d':'The same symbols return. What would make their quantities accountable?'
}
p = 'commons/data/book/qfeplaboratory.json'
d = read(p)
pearl = next(x for x in d['pearls'] if x['map'] == ROOM)
pearl.update(hero='qfep_balance_workbench', lines=[{'token':t,'text':s,'by':'hand'} for t,s in lines.items()])
write(p, d)
for p in ['commons/data/trunk_branches.json', 'commons/data/museum/trunk_branches.json']:
    d = read(p)
    node = next(n for n in d['trunk'] if n['node'] == 'qfeplaboratory')
    for pearl in node['pearls'] + d.get('hand_pearls', {}).get('qfeplaboratory', []):
        if pearl.get('map') == ROOM:
            pearl.update(hero='qfep_balance_workbench', says=lines, says_by={t:'hand' for t in lines})
    write(p, d)

p = 'commons/maps/sequences/qfeplaboratory.json'
d = read(p)
s = d['sequences']['qfeplaboratory']
s.update(description='Investigate Ada’s QFEP research proposal through particular implemented calculations and encounters. Ask what is supplied, what is measured, and what each comparison leaves out.', truth='A manipulable formula becomes accountable through explicit quantities, receivers and tests.', qfep_connection='Keep the project’s research proposal open to testing. Slider examples and preferred bands are authored choices; their values do not establish universal conditions for life.', formula='QFE = F − λE(S) + φΔE(S,t)', learning_objectives=['Compare distinct arrangements that yield the same scalar total.', 'Distinguish supplied values from measured quantities and specify the system being measured.', 'Investigate how a weight changes the consequence of another input.', 'Compare change values, rates and their receivers.', 'Ask what an authored reference or preferred interval includes and leaves out.'])
s['content'][0] = 'QFEP_Introduction: Four controls, one result'
g = next(g for g in s['artifact_groups'] if g['map'] == ROOM)
g.update(artifacts=list(read('commons/data/artifact_roles.json')['roles'][ROOM]), rationale='Keep and compare arrangements on the central workbench. All existing secondary works remain; separate rails are independent comparisons.')
write(p, d)

print('Intro prose, retained proposals, primary speech, metadata and sequence framing aligned.')
