"""Editorial revision only: retain every printed code block and museum source."""
from pathlib import Path
import hashlib, json, re, shutil

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-09-soft-bodies-complete-readings'
MAPS = json.loads((R/'commons/maps/sequences/softbodies.json').read_text(encoding='utf8'))['sequences']['softbodies']['maps']
O.mkdir(exist_ok=True)
assert not (O/'editorial-receipt.json').exists(), 'Revision already applied; do not overwrite its baseline.'
before = {}
for name in MAPS:
    for kind in ['tutorial', 'final']:
        p = R/'commons/maps'/name/(kind+'.md')
        before[p] = p.read_text(encoding='utf8')
        q = O/'before'/name/p.name
        q.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(p, q)

protected = [R/'commons/maps/sequences/softbodies.json']
protected += list((R/'doc/book/studies/soft-bodies-through-the-hands').rglob('*.gd'))
protected += [R/'commons/maps'/name/'map_data.json' for name in MAPS]
hashes = {p.relative_to(R).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in protected}
(O/'protected-hashes.json').write_text(json.dumps(hashes, indent=2), encoding='utf8')
texts = dict(before)

def replace(name, kind, old, new):
    p = R/'commons/maps'/name/(kind+'.md')
    assert texts[p].count(old) == 1, (name, old[:80])
    texts[p] = texts[p].replace(old, new)

cloth = 'SoftBodies_Cloth_Physics'
replace(cloth, 'tutorial',
    'The first `PINS` action removes six attachments from the running sheet. The next rebuilds it with the whole row held again. Changing pin flags alone does not restore a moving sheet to its original shape. `REBUILD` deliberately creates a new body, while retaining the same point. The gold dots follow the actual physics positions each step, including after a change.\n\n`REBUILD` has a different job. It removes the old sheet and constructs a fresh one from the reference mesh, with the top row fixed. The same black point and visible bar survive. This is the distinction we met at the cube: changing a condition and starting a new run are different operations.',
    'The first `PINS` action releases six attachments on the running sheet. The next constructs a fresh sheet with the top row held again, just as `REBUILD` does. Changing pin flags alone would leave its folds and motion in place. The same black point and visible bar survive; the gold dots follow the new sheet’s actual pinned positions.')
replace(cloth, 'tutorial',
    'The following installed membrane is an optional return. It changes load while preserving four anchors and uses its own supplied constraint solver. It is not another implementation of the sheet above.',
    '<details markdown="1">\n<summary>Optional museum return — A little give</summary>\n\nThe main lesson ends with the sheet and its selected boundary. This separate encounter changes load while preserving four anchors. Its supplied constraint solver is not required for Carusell; return when you want to compare what the same anchors are asked to carry.')
p = R/'commons/maps'/cloth/'tutorial.md'
texts[p] = texts[p].rstrip()+'\n\n</details>\n'
replace(cloth, 'final',
    "The rule that holds that edge never looks at the frame. It reads the strip's original geometry in its own coordinates and finds the highest row. A point is held if its height matches that top to within a hundredth of a metre — eight points of the hundred and twelve in each strip. The strip is a mesh of triangles; its points are linked, and the pin rule chooses which must stay. That rule does not consult the frame. The apparent reason for the cloth to hang was built for you to see.\n\nA convincing support does not prove how a simulation is attached to it. You have just taken the support away and watched the attachment survive it.",
    'The attachment rule reads the strip’s original coordinates and holds its eight upper points. The frame was built for you to see. You have taken the apparent support away and watched the attachment survive it.')
replace(cloth, 'final',
    'The material never changed while the pins did. The solver and its coefficients remained the same; the boundary changed. What changed is how many of its points were forbidden to move — eight, then two, then none. Boundary conditions are not a detail of the setup. Here they are most of what you have been looking at.',
    'The material settings remained the same. Eight points were forbidden to move, then two, then none. What looked like a quality of the cloth belonged partly to the arrangement holding it.')
replace(cloth, 'final',
    "Worth knowing before you read too much into any held shape: the stop raises damping and stiffness rather than recording the vertex positions, so what you are looking at is partly the solver's and not a destination the material was travelling toward.",
    'Their stop raises damping and stiffness. The quiet shape is still a simulated body. Later we will keep a separate record of a surface; here we have changed the conditions under which it moves.')
replace(cloth, 'final',
    "Beyond these encounters, the earlier room remains inside the enlarged hall. Its raised cells ask your feet to negotiate another kind of boundary. The curtain's pins and the floor's supports belong to different constructions; you meet their consequences in the same body.",
    'The raised cells farther into the hall ask your feet to negotiate another boundary. What the pins hold for the cloth, the floor must supply for you.')
replace(cloth, 'final',
    '<!-- study-spine:tension_membrane -->',
    '<details markdown="1">\n<summary>Further encounter — A little give</summary>\n\n<!-- study-spine:tension_membrane -->')
replace(cloth, 'final',
    'Carry the fixed edge into the next hall. There, the support itself moves, and the bodies hanging from it will know.',
    '</details>\n\nCarry the fixed edge into the next hall. There, the support itself moves, and the bodies hanging from it will know.')

sampling = 'SoftBodies_Playground_of_Joy'
replace(sampling, 'tutorial',
    "We use the vessel's construction and custom particle solver for this lesson. Its `positions` array is directly readable. This is a change of implementation from the previous Jolt panel, not a claim that those two solvers have interchangeable properties. The operation carried forward is sampling a moving body. Our black PointBody also returns, unchanged, as the capture control.",
    '**We carry the act of sampling into a different supplied body.** The previous panel used Jolt. This vessel uses the museum’s custom particle solver, whose `positions` array we can read directly. Its construction and solver are given in full below; we do not transfer the panel’s damping or pressure settings to them. The new work is copying a moving surface. Our black PointBody returns unchanged as the capture control.')
replace(sampling, 'tutorial',
    'You can turn one state of a process into a separate object, state when you selected it, and name what you left out. In the next hall, organic-looking forms invite another inference: does looking alive tell us how something was made?',
    'You can turn one state of a process into a separate object, state when you selected it, and name what you left out. Keep the four files. The next lesson reconstructs their step-40 shape as a common starting point; it does not automatically carry your latest trigger capture between halls. We will keep that geometry fixed while changing its appearance: does looking alive tell us how something was made?')

affect = 'SoftBodies_Affect_Theory_Visualization'
for file in ['vessel_surface.gd', 'point_body.gd', 'solver.gd']:
    p = R/'commons/maps'/affect/'tutorial.md'
    pattern = r'### '+re.escape(file)+r'\n\n(<!-- student-code:'+re.escape(file)+r' -->\s*```gdscript\n.*?\n```)'
    texts[p], count = re.subn(pattern, lambda m: '<details markdown="1">\n<summary>'+file+' — unchanged</summary>\n\n'+m[1]+'\n\n</details>', texts[p], flags=re.S)
    assert count == 1, file

reaction = 'ProceduralGeneration_Reaction_Diffusion_Systems'
replace(reaction, 'final',
    'The names tempt us to recognise a living skin: spots, stripes, something dividing. Calling this a metabolism draws attention to what must continue for a form to persist. It does not make the field an organism. These quantities stand in for a limited chemical model. No cell here eats, suffers or decides what it needs.',
    'The names tempt us to recognise a living skin: spots, stripes, something dividing. Metabolism offers an association with what must continue for a form to persist. The quantities here belong to a limited chemical model; the association asks us to attend to its exchanges.')
replace(reaction, 'final',
    'Change a rate, then return to the same beginning. Change the beginning, then keep the rates. Neither comparison gives a complete account of the world. Each lets one relation become legible. Even the edge has been arranged: a value leaving one side meets the other. The field\'s apparent continuity depends on that return.',
    'Change a rate, then return to the same beginning. Change the beginning, then keep the rates. Each comparison lets one relation become legible. Even the edge has been arranged: a value leaving one side meets the other. The field’s apparent continuity depends on that return.')
replace(reaction, 'final',
    'The next hall makes such a crossing explicit. Values become a surface you can move around. Carry this question with you: what did the passage into a body preserve, and what did it require us to choose?',
    'The next hall begins with a different field: a rule evaluated throughout three-dimensional space. We leave these concentrations here and carry the question of how values become visible form. There, choosing a boundary will give us a surface to move around. Who chooses where it appears?')
p = R/'commons/maps'/reaction/'tutorial.md'
sentences = re.findall(r'[^\n]*The next hall maps values[^\n]*', texts[p])
assert len(sentences) == 1, sentences
replace(reaction, 'tutorial', sentences[0],
    'The next hall starts a different field: a three-dimensional sine-and-noise rule. We carry the same PointBody and the method of matched comparison; these concentration arrays stay here. The new lesson separates changes to that spatial rule from changes to the cut that selects its surface.')

replace('SoftBodies_Soft_Body_Deformation', 'final',
    'There is no modeled flesh behind the skin. This is a closed surface responding through the engine\'s soft-body rules.',
    'The closed surface responds through the engine’s soft-body rules.')
replace('Topology_Entropy_Morphogenesis', 'final',
    'Its appearance may suggest growth; the mechanism does not remember a body growing. The distinction matters because it tells us what kinds of intervention are available.',
    'Its appearance may suggest growth, but each reconstruction begins from the rule. We can intervene by changing that description.')

changed = []
for p, s in texts.items():
    assert re.findall(r'```.*?```', s, re.S) == re.findall(r'```.*?```', before[p], re.S), p
    assert p.read_text(encoding='utf8') == before[p], 'Concurrent edit: '+str(p)
    if s != before[p]:
        p.write_bytes(s.encode('utf8'))
        changed.append(p.relative_to(R).as_posix())

plan_path = R/'doc/book/course/execution-plan/plan.json'
raw = plan_path.read_bytes()
plan = json.loads(raw)
shutil.copyfile(plan_path, O/'before/execution-plan.json')
row = next(x for x in plan['lessons'] if x['id'] == reaction)
row['next'] = 'Topology_Entropy_Morphogenesis: a different three-dimensional sine-and-noise field. Carry PointBody and matched comparison; no concentration-array transfer. Separate field parameters from the surface cut.'
row['summary'] = row['summary'].replace('Carry the difference between field state, update rule and its image into the next hall’s surface construction.', 'Carry PointBody and matched comparison into a different three-dimensional field; leave these concentration arrays here. Separate the new field’s parameters from the cut selecting its surface.')
assert plan_path.read_bytes() == raw
plan_path.write_bytes((json.dumps(plan,ensure_ascii=False,indent=2)+'\n').encode('utf8'))
for path, digest in hashes.items():
    assert hashlib.sha256((R/path).read_bytes()).hexdigest() == digest, path
(O/'editorial-receipt.json').write_text(json.dumps({'changed':changed,'printed_code_unchanged':True,'protected_files':len(hashes),'order_unchanged':True,'plan_rows_changed':[reaction]},indent=2),encoding='utf8')
print(json.dumps({'changed':len(changed),'code_unchanged':True,'protected_files':len(hashes)}))
