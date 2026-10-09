"""Apply this pass's recorded manuscript revisions and align the teaching records."""
from pathlib import Path
import hashlib
import json
from update_metadata import replace_entry

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
def read(path): return json.loads(path.read_text(encoding='utf-8'))
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def write(path, data): path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')

changes = read(HERE / 'text-changes.json')
book_path = ROOT / 'commons/data/book/formfinding.json'
book_before = HERE / 'before/commons/data/book/formfinding.json'
if not book_before.exists():
    book_before.parent.mkdir(parents=True, exist_ok=True)
    book_before.write_bytes(book_path.read_bytes())
old_card = 'A room with a deep narrow DEAD well (rigid, one shape) and a shallow wide ALIVE well (soft'
new_card = 'Two wells with different receivers: compare the responses before INTERPRET.'
book_text = book_path.read_text(encoding='utf-8')
if old_card in book_text:
    assert book_text.count(old_card) == 1
    book_path.write_text(book_text.replace(old_card, new_card, 1), encoding='utf-8')
else:
    assert new_card in book_text, 'Concurrent Q wall-card edit'
for name, pairs in changes.items():
    path = ROOT / f'commons/maps/{name}/final.md'
    current = path.read_text(encoding='utf-8')
    original = (HERE / 'before' / path.relative_to(ROOT)).read_text(encoding='utf-8')
    target = original
    for before, after in pairs:
        assert target.count(before) == 1
        target = target.replace(before, after, 1)
    assert current in (original, target), f'Concurrent manuscript edit: {name}'
    if current != target: path.write_text(target, encoding='utf-8')

role_path = ROOT / 'commons/data/artifact_roles.json'
roles = read(role_path)
promotions = {'FormFinding_Catenary': ('laundry_line_cathedral', ['cable_builder', 'laundry_line_cathedral', 'catenoid']),
              'FormFinding_Relaxation': ('frozen_glass_vessel', ['verlet_workbench', 'mass_spring_bench', 'frozen_glass_vessel']),
              'FormFinding_Annealing': ('max_q_basin_room', ['energy_landscape_bench', 'simulated_annealing', 'max_q_basin_room'])}
for name, (token, order) in promotions.items():
    roles['roles'][name][token] = 'primary'
    roles['order'][name]['primary'] = order
    roles['order'][name]['secondary'] = [k for k in roles['order'][name]['secondary'] if k != token]
write(role_path, roles)

def sequence(seq):
    seq['v1_note'] = 'Local source and desktop pass, 2026-09-19. Six halls retained; manuscript, restored comparisons, controlled relaxation and explicitly separated search stops aligned. Source and capture scopes are recorded in doc/book/iterations/2026-09-19-formfinding-review/SUMMARY.md. Headset and learner validation remain open.'
    seq['learning_objectives'] = [
        'Measure a local gradient and distinguish slope, frame and budget stopping conditions',
        'Compare a hand-shaped spline with sampled analytic curves and surfaces; state which physical tests are absent',
        'Control a cloth correction budget and disturbance; compare mean and worst error with frozen process outputs',
        'Inspect encoded lever balance and distinguish a prescribed pose from demonstrated mechanical stability',
        'Compare uphill acceptance, adaptive cooling and a separate basin hop; question what the objective rewards',
        'Inspect a height-and-stability success detector and distinguish small slope from a boundary stop'
    ]
    seq['content'] = [
        'FormFinding_Descent: where does downhill take you, and why does it stop?',
        'FormFinding_Catenary: what is drafted, calculated or physically settled between supports?',
        'FormFinding_Relaxation: what does a finite correction budget leave in a connected shape?',
        'FormFinding_Equilibrium: what balances in the model, and what remains untested?',
        'FormFinding_Annealing: which rule permits escape, and which outcome is worth keeping?',
        'FormFinding_Forge: which arrangements count, and why does this search start again?'
    ]
    if 'curation_history' not in seq:
        old = read(HERE / 'before/commons/maps/sequences/formfinding.json')['sequences']['formfinding']
        seq['curation_history'] = [{'date': '2026-09-19', 'reason': 'Keep the six-hall arc; describe each implemented method accurately.',
            **{k: old[k] for k in ['v1_note', 'learning_objectives', 'content']}}]
replace_entry('commons/maps/sequences/formfinding.json', 'formfinding', sequence)

core_path = ROOT / 'commons/data/museum_core_encounters.json'
core = read(core_path)
reasons = {
    'FormFinding_Descent': 'Predict a local step; compare starts and stopping conditions. Preserve the verified manuscript and its five retained comparisons.',
    'FormFinding_Catenary': 'Move a drafted cable, compare an analytic washing line, then lift the generated surface. Distinguish a constructed form from a physical solve.',
    'FormFinding_Relaxation': 'Control passes and wind; compare average/local errors, then inspect finite histories kept as lattice and vessel.',
    'FormFinding_Equilibrium': 'Read the lever arithmetic and inspect the omissions of a static balance model; compare a prescribed pulse and recursive bracing.',
    'FormFinding_Annealing': 'Compare local settling, uphill acceptance and a separate hop; observe two differently driven basins before revealing their Q proposition.',
    'FormFinding_Forge': 'Question a height-and-stability success rule; compare optimizer histories and distinguish a boundary stop from small slope.'
}
for name, reason in reasons.items():
    item = core['rooms'][name]
    item.update(reason=reason, primary_tokens=roles['order'][name]['primary'], learner_verified=False,
        map_sha256=sha(ROOT / f'commons/maps/{name}/map_data.json'),
        text_sha256=sha(ROOT / f'commons/maps/{name}/final.md'),
        local_review='doc/book/iterations/2026-09-19-formfinding-review/SUMMARY.md')
    if name != 'FormFinding_Descent': item['status'] = 'desktop_checked_headset_pending'
    item['verification_scope'] = ('Historical 36-check museum run with unchanged primary/map/text/source fingerprints; current static-diagram label repair checked separately.'
        if name == 'FormFinding_Descent' else 'Bounded source, behavior and museum checks for the documented repairs; no complete headset visit or learner validation.')
    if name == 'FormFinding_Annealing':
        item['status'] = 'desktop_checked_native_teardown_unresolved'
        item['verification_scope'] = 'Documented behavior and museum placement checks; isolated Annealing/Q behavior checks complete but native teardown crashes. This is not a clean overall runtime pass. Headset and learner validation remain open.'
write(core_path, core)
print('Applied five manuscript revisions; three existing comparisons promoted; six-hall records aligned.')
