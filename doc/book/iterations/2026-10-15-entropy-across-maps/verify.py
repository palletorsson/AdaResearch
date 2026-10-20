"""Exact authored fixtures and source inventory; not a Godot or human trial."""
from pathlib import Path
from collections import Counter
import hashlib
import json
import math
import re
import shutil

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
PROPOSAL = Path('C:/Users/palle/.codex/attachments/d9227646-7f9d-4b00-ac76-f80fd3756582/Pasted text.txt')

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def entropy(values):
    counts = Counter(values)
    return -sum((n / len(values)) * math.log2(n / len(values)) for n in counts.values())

checks = []

def check(name, condition):
    checks.append({'name': name, 'passed': bool(condition)})
    assert condition, name

x = [-0.75, -0.25, 0.25, 0.75]
clipped = [max(v, 0.0) for v in x]
remapped_from_raw = [(v + 1.0) * 0.5 for v in x]
remapped_from_clip = [(v + 1.0) * 0.5 for v in clipped]
joint = list(zip(x, clipped))
conditional = entropy(joint) - entropy(clipped)
mutual = entropy(x) - conditional
check('uniform signed four-symbol fixture has two bits', entropy(x) == 2)
check('clipping merges only the two negative symbols', clipped == [0, 0, 0.25, 0.75])
check('clipped histogram has 1.5 bits', entropy(clipped) == 1.5)
check('half a bit remains unknown about raw value given clipped value', conditional == 0.5)
check('clipped record retains 1.5 bits about raw symbol', mutual == 1.5)
check('remapping raw values keeps four distinguishable symbols', entropy(remapped_from_raw) == 2)
check('remapping clipped values cannot separate merged negatives', remapped_from_clip[0] == remapped_from_clip[1] and entropy(remapped_from_clip) == 1.5)

sampler = ROOT / 'algorithms/randomness/seed_replay/movement_seed.gd'
code = sampler.read_text(encoding='utf8')
version = re.search(r'const VERSION := "([^"]+)"', code).group(1)
check('current sampler declares inspected uint32 reduction', 'decode_u32(0) % 1000' in code)
check('current sampler retains sample array in its receipt', '"samples":samples.duplicate(true)' in code)
seen = {}
collision = None
for trial in range(1001):
    records = [[i * 16667, i * (trial + 1), 0, 0, 0, 0, 0, 1000000] for i in range(30)]
    encoded = version + '\ndesktop_movement\n' + ''.join(','.join(map(str, row)) + '\n' for row in records)
    raw = hashlib.sha256(encoded.encode('utf8')).digest()
    seed = int.from_bytes(raw[:4], 'little') % 1000
    item = {'synthetic': True, 'trial': trial, 'source': 'desktop_movement', 'recipe': version,
            'seed': seed, 'sha256': raw.hex(), 'samples': records}
    if seed in seen:
        collision = [seen[seed], item]
        break
    seen[seed] = item
check('two distinct synthetic records share a bounded seed', collision is not None and collision[0]['samples'] != collision[1]['samples'] and collision[0]['seed'] == collision[1]['seed'])
check('shared seed does not imply an identical full digest', collision[0]['sha256'] != collision[1]['sha256'])
check('seed alphabet bound is below ten bits', 9.965 < math.log2(1000) < 9.966)

fixtures = {
    'scope': 'Exact authored discrete examples and a Python transcription of the source digest recipe; no new Godot execution or human gesture evidence.',
    'checks': checks, 'passed': all(c['passed'] for c in checks),
    'noise': {'law': 'Uniform draw over four explicitly authored signed values; exact brightness factors before rendering.',
              'raw': x, 'clipped': clipped, 'remapped_from_raw': remapped_from_raw,
              'remapped_from_clipped': remapped_from_clip, 'H_X_bits': entropy(x),
              'H_Y_bits': entropy(clipped), 'H_X_given_Y_bits': conditional, 'I_X_Y_bits': mutual},
    'seed_alphabet_upper_bound_bits': math.log2(1000),
    'collision': collision,
    'sampler_sha256': digest(sampler),
}
(HERE / 'fixtures.json').write_text(json.dumps(fixtures, indent=2), encoding='utf8')

maps = ['Random_Definition', 'Random_Entropy', 'Noise_One', 'Point_Trace', 'WaveFunctions_Pendulum',
        'CA_ExpandingSpace', 'SwarmIntelligence_Boids_Algorithm',
        'ProceduralGeneration_Reaction_Diffusion_Systems', 'ML_Evolution']
plans = read(ROOT / 'commons/data/museum/em_plan.json')['plans']
inventory = []
for name in maps:
    path = ROOT / 'commons/maps' / name / 'map_data.json'
    data = read(path)
    rows = [p for p in plans if p.get('map') == name]
    assert rows, f'No generated plan entry for {name}'
    placed = [{'x': col, 'z': row, 'token': token} for row, values in enumerate(data['layers']['interactables'])
              for col, token in enumerate(values) if isinstance(token, str) and token.strip() and token.strip() not in ['0', '-1', '.']]
    inventory.append({'map': name, 'map_sha256': digest(path), 'placements': placed,
                      'generated_plan_entries': rows})
paths = [sampler,
    ROOT / 'algorithms/randomness/seed_replay/movement_sampler.gd',
    ROOT / 'commons/artifacts/random_return/random_return.gd',
    ROOT / 'algorithms/randomness/noisetorus/noisetorus.gd',
    ROOT / 'commons/artifacts/prefab_disorder/prefab_disorder.gd',
    ROOT / 'commons/artifacts/prefab_disorder/disorder_sample.gd',
    ROOT / 'commons/artifacts/entropy_compartments/compartment_model.gd',
    ROOT / 'commons/artifacts/boids_neighbour_lens/boids_neighbour_lens.gd',
    ROOT / 'commons/maps/Point_Trace/tutorial.md',
    ROOT / 'commons/maps/WaveFunctions_Pendulum/tutorial.md',
    ROOT / 'commons/maps/Noise_One/final.md',
    ROOT / 'doc/VR_VR_PT_2023.md']
audit = {'scope': 'Authored placements and generated plan entries, with hashes of the implementation/text sources inspected for this framework. Not an exhaustive active-branch audit or new runtime proof for all maps.',
         'maps': inventory, 'sha256': {p.relative_to(ROOT).as_posix(): digest(p) for p in paths}}
(HERE / 'source-audit.json').write_text(json.dumps(audit, indent=2), encoding='utf8')
if PROPOSAL.exists():
    if not (HERE / 'supplied-proposal.md').exists():
        shutil.copyfile(PROPOSAL, HERE / 'supplied-proposal.md')
    assert (HERE / 'supplied-proposal.md').read_bytes() == PROPOSAL.read_bytes()
(HERE / 'provenance.json').write_text(json.dumps({
    'supplied_path': str(PROPOSAL), 'supplied_sha256': digest(HERE / 'supplied-proposal.md'),
    'historical_proposal': 'doc/VR_VR_PT_2023.md', 'historical_sha256': digest(ROOT / 'doc/VR_VR_PT_2023.md'),
    'scope': 'Original proposal preserved; research framework and staged tasks added. No runtime artifact or canonical final/tutorial changed in this pass.'
}, indent=2), encoding='utf8')
print(f'{len(checks)} exact/source checks passed; {len(inventory)} authored maps and generated plan entries recorded.')
print('Synthetic collision seed:', collision[0]['seed'], '; positional progressions:', [c['trial'] + 1 for c in collision])
