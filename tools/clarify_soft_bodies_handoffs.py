"""Apply the external review's remaining editorial fixes; retain tested code."""
from pathlib import Path
import hashlib, json, re
from test_soft_sequence_ghost import ROWS

R = Path(__file__).resolve().parents[1]
O = R/'doc/book/iterations/2026-10-09-soft-bodies-complete-readings'
BEFORE = O/'before-feedback'
assert not BEFORE.exists(), 'One-time editorial revision already applied.'

def read(p): return p.read_text(encoding='utf8')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p, s):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_bytes(s.encode('utf8'))
def replace(s, old, new):
    assert s.count(old) == 1, old
    return s.replace(old, new)

# Keep the exact text associated with the existing engine-test receipt.
tested = json.loads(read(O/'ghost-checks.json'))
for row in tested['halls']:
    assert sha(R/'commons/maps'/row['map']/'tutorial.md') == row['tutorial_sha256']
for name, _, _ in ROWS:
    for kind in ['tutorial', 'final']:
        p = R/'commons/maps'/name/(kind+'.md')
        dest = BEFORE/name/p.name
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(p.read_bytes())

guides = [
    ('PointBody and cube construction.', 'Pin a reference vertex; compare stiffness, damping and pressure in `yielding_cube.gd` and its host.', 'The prepared museum and Jolt’s soft-body solver.'),
    ('PointBody and the previous SoftBody3D setup.', 'Build `hanging_sheet.gd`; select a row, two corners or no pins. The host makes those choices visible.', 'The prepared museum and Jolt’s solver.'),
    ('Unchanged `hanging_sheet.gd` and `point_body.gd`.', 'In `study.gd`, move the two attachments with a turning bar; let the sheet respond.', 'The prepared museum and Jolt’s solver.'),
    ('PointBody, closed-box construction and coordinate-based pin selection.', 'Build `pressure_panel.gd`; drive its pressure from a sine wave in `study.gd`.', 'The prepared museum and Jolt’s solver.'),
    ('Unchanged `pressure_panel.gd` and `point_body.gd`.', 'In `study.gd`, compare matched falls and retain a timed height reading.', 'The prepared museum and Jolt’s solver.'),
    ('PointBody and the idea of keeping a timed observation.', 'In `study.gd`, copy positions and face indices while their source continues.', 'The prepared museum; `vessel_surface.gd` and its particle solver replace the earlier Jolt panel.'),
    ('Unchanged vessel, solver and PointBody files; the step-40 recipe.', 'In `study.gd`, compare one turn or colour change while keeping geometry fixed.', 'The prepared museum. The inherited solver reconstructs the snapshot once.'),
    ('The earlier CA lesson’s four-neighbour field, display pattern and PointBody.', 'Expose local reaction, supply and removal in `field.gd`; compare both cases with `reaction.gd`.', 'The prepared museum. The vessel solver ends here.'),
    ('PointBody and the method of matched comparison.', 'In `recipe.gd`, separate frequency, noise and cut; preview, then commit.', 'The prepared museum and GyroidFieldGenerator’s field sampling, surface extraction and collision.'),
]

changed = []
for (name, _, _), (carry, new, supplied) in zip(ROWS, guides):
    p = R/'commons/maps'/name/'tutorial.md'
    old = read(p)
    learning = re.search(r'(?m)^- [^\n]+(?:\n- [^\n]+)*\n', old)
    assert learning
    guide = f'\n**Carry:** {carry}  \n**New work:** {new}  \n**Supplied:** {supplied}\n'
    s = old[:learning.end()] + guide + old[learning.end():]
    if name == 'SoftBodies_Cloth_Physics':
        marker = '<details markdown="1">\n<summary>Optional museum return — A little give</summary>'
        extension = '''<details markdown="1">
<summary>Optional composition — choose three places</summary>

Keep a two-corner sheet as your reference. On a second sheet, choose three attachment positions in the undeformed coordinates. Select the nearest existing vertices, check that the three indices are distinct, and clear every other pin. Keep the mesh and material settings shared. Predict which former corner can now move; do not prescribe the exact fold. Write the selection before opening the [tested three-attachment example](/book-review/doc/book/iterations/2026-10-09-soft-bodies-three-attachments/index.html), which includes the complete host and its checks. Restore the two upper corners for Carusell.

</details>

'''
        s = replace(s, marker, extension + marker)
    elif name == 'SoftBodies_Affect_Theory_Visualization':
        s = replace(s, 'Your captured surface supplies the material for testing it.', 'The previous lesson’s snapshot recipe supplies the material for testing it.')
        s = replace(s, '## Continue with your captured shape', '## Reconstruct the recorded shape')
    elif name == 'ProceduralGeneration_Reaction_Diffusion_Systems':
        s = replace(s, 'In the previous hall you changed the appearance of a saved surface without changing its data. Here the data change. Return to the two fields from', 'In the previous hall a copied surface remained while its source was no longer running. Here we ask what a pattern needs to keep happening. Return to the two fields from')
    assert re.findall(r'```.*?```', old, re.S) == re.findall(r'```.*?```', s, re.S)
    write(p, s)
    changed.append(p.relative_to(R).as_posix())

bridges = [
    ('SoftBodies_Affect_Theory_Visualization',
     'Next, a field changes through local exchanges. A pattern will persist while its values move. Carry both questions into that room: what process maintains the difference, and what have we learned to see in it?',
     'The copied surface can remain after its source has stopped. In the next room, a pattern may need continuing exchanges to persist. What must keep happening for a form to stay recognisable? Carry that question beside the one this room leaves us: what have we learned to see in it?'),
    ('ProceduralGeneration_Reaction_Diffusion_Systems',
     'The next hall begins with a different field: a rule evaluated throughout three-dimensional space. We leave these concentrations here and carry the question of how values become visible form. There, choosing a boundary will give us a surface to move around. Who chooses where it appears?',
     'Here we have watched what continuing exchanges can sustain. The next hall asks what a rule can reconstruct. We leave these concentrations here: a different field will be evaluated throughout three-dimensional space. Choosing a boundary gives us a surface to move around. Who chooses where it appears?'),
    ('Topology_Entropy_Morphogenesis',
     'In the previous hall, a pattern could require continuing exchange and supply. Here the surface waits. It is reconstructed from a spatial rule when you ask it to change. Its appearance may suggest growth, but each reconstruction begins from the rule. We can intervene by changing that description.',
     'The vessel kept a moment as a record. The previous room asked what continuing exchange could sustain. Here the surface waits until a changed description asks it to be built again. Its appearance may suggest growth, but each reconstruction begins from the spatial rule. What we preserve is a way of making the form; that description is also where we can intervene.'),
]
for name, old, new in bridges:
    p = R/'commons/maps'/name/'final.md'
    write(p, replace(read(p), old, new))
    changed.append(p.relative_to(R).as_posix())

for path, digest in json.loads(read(O/'protected-hashes.json')).items():
    assert sha(R/path) == digest, path
receipt = {'date': '2026-10-09', 'changed': changed, 'printed_code_unchanged': True,
           'runtime_changed': False, 'tested_texts_retained': 'before-feedback/',
           'engine_receipt_retained': 'ghost-checks.json',
           'scope': 'Editorial follow-up only: nine scope guides, three reflective bridges, optional tested composition.'}
write(O/'feedback-revision.json', json.dumps(receipt, ensure_ascii=False, indent=2)+'\n')
print(json.dumps(receipt, ensure_ascii=False))
