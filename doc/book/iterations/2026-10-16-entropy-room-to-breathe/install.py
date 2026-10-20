"""Adopt the retained revisions without changing route order or magnet positions."""
import hashlib
import json
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
MAPS = ['Random_Entropies', 'Random_Entropy']
REVIEW = '../../../doc/book/iterations/2026-10-16-entropy-room-to-breathe/index.html'
notes = {
    'entropy_chairs_shannon': 'The entrance chair shares our floor. Moving chairs leaves colour shares unchanged; attending to the rare black chair is different from predicting the next colour. What account would retain places?',
    'entropy_chairs_boltzmann': 'Only one assignment stands in each version, although thirty-six fit the same brief. The count cannot identify this arrangement. A recipe must retain more.',
    'entropy_chairs_description': 'The apparently irregular chairs have a short seeded recipe if its generator comes too. How exact must a beginning be when the rule repeatedly uses its own result?',
    'entropy_door_dynamics': 'A shared STEP contracts or expands a starting difference; the history can preserve differences after the leaves meet. RESET supplies a beginning rather than retracing the path. What would return require after heat passes elsewhere?',
    'entropy_cooling_cup': 'Five fixed milk stages give time to look back. A separate two-body model accounts for cooling: cup entropy falls, surroundings gain more. Reloading a digital snapshot does not reverse physical heat transfer. What can the surface alone tell us?',
    'entropy_frosted_chair': 'Five panes separate visibility from a declared record. Different frost can retain the same information. If the record cannot identify the chair, which answer should we give?',
    'entropy_ball_pit': 'Armrests split a less likely category without improving the best guess. The all-pink ending changes composition while colour remains certain, preparing a question about neighbours in the next hall.',
    'shannon_entropy_meter': 'SORT changes neighbours while shares stay fixed; the retained strip keeps earlier relations available. CONTRAST changes shares. To include position, the next account must say what about position is known.',
    'entropy_jar_states': 'Four beginnings wait, then slowly mix. Height and core/rim addresses disclose different colour relations. PAUSE lets us search for what remains of a beginning; the next jar brings intervention within reach.',
    'entropy_jar': 'Shaking changes where beads sit without changing the population. A gesture, positions and the gauge would be different records. How much would a shorter description leave open?',
    'entropy_sorting_table': 'Four cubes let us inspect all six arrangements. A divider changes the account before any cube moves; exchanging two cubes then changes its counts. A larger cabinet tests the same counting question beyond easy enumeration.',
    'entropy_compartments': 'SAME k moves colours without changing either dial. KEEP retains distinctions those dials omit. Exact replay restores positions, but which lines we see through them still depends on where we stand.',
    'entropy_axiom': 'We move while the points stay. Alignments appear or disappear with viewpoint; displacement itself follows a rule. At the stone bed, relations will have consequences beyond what is visible.',
    'entropy_ruin': 'One selected stone can move others. PULLED and MOVED separate; pausing selection leaves gravity active. RESTORE rebuilds a beginning without guaranteeing identical landings. The composed museum wall offers a different procedure.',
    'signal_room': 'ROWS and CELLS keep the same colour shares while neighbour counts change. Unlike the stones, changing the image leaves support intact. The next removal asks which objects are eligible and what depends on them.'
}

def text(path):
    return path.read_text(encoding='utf-8')

def put(path, value):
    path.write_text(value, encoding='utf-8')

def replace(path, old, new):
    value = text(path)
    assert old in value or new in value, (path, old)
    put(path, value.replace(old, new))

receipts = {}
for name in MAPS:
    folder = ROOT/'commons/maps'/name
    original = HERE/'before/commons/maps'/name/'final.md'
    revision = HERE/f'{name}-final.md'
    current = folder/'final.md'
    assert text(current) in (text(original), text(revision)), f'Concurrent final edit: {name}'
    anchors = re.findall(r'<!-- @([a-z_]+) -->', text(revision))
    wall_path = folder/'writing_wall.json'
    wall = json.loads(text(wall_path))
    final_ids = {m['id'] for m in wall['magnets'] if 'final' in m.get('tags', [])}
    final_order = [token for token in wall['order'] if token in final_ids]
    assert anchors == final_order, (name, anchors, final_order)
    for magnet in wall['magnets']:
        if magnet['id'] in notes:
            magnet['final'] = notes[magnet['id']]
    put(wall_path, json.dumps(wall, ensure_ascii=False, indent=2)+'\n')
    put(current, text(revision))
    receipts[name] = {
        'before_sha256': hashlib.sha256(original.read_bytes()).hexdigest(),
        'revision_sha256': hashlib.sha256(current.read_bytes()).hexdigest(),
        'room_and_final_order': anchors
    }
    plan = folder/'plan.md'
    heading = '## More room for the encounters · 16 October 2026'
    if heading not in text(plan):
        target = ('doors → coffee: RESET supplies starting values; the coffee asks what restoring heat would require. Milk stages and the separate heat model remain distinct'
                  if name == 'Random_Entropies' else
                  'cabinet → points: exact replay preserves positions, while the alignments available to a moving observer depend on viewpoint. Points → stones then changes a visible relation into a load-bearing dependency')
        put(plan, text(plan)+f'\n{heading}\n\nThe [retained before/after reading]({REVIEW}) revises the complete final, with more observation around definitions and transitions. The central revision tests {target}. Final notes on the writing wall follow the new prose; order, tags, conceptual links and optional encounters stay. Length follows the work each encounter needs, with no new hard cap. The 48-value bench remains the first research pilot.\n\nRead the current-before and revised-after chapters separately. At the transition, record what the reader wants to investigate next, including a wish to stay or skip. Identify the exact sentence that creates or fails to create that need; do not supply the intended answer. After the room walk, note any action or view that the text invents or misdescribes. Revise one weak passage and preserve both the response and the previous wording. Accuracy and a clear walking route do not establish literary necessity. Human reading, headset comfort and independent reconstruction remain pending.\n')

registry_path = ROOT/'commons/artifacts/registry/ordinary_entropies.json'
registry = json.loads(text(registry_path))
registry['artifacts']['entropy_chair_reference']['description'] = 'A full-size pink chair on the visitor floor, in front of a wall label. No raised shelf or platform. It establishes colour versus arrangement before the Shannon/Boltzmann comparisons.'
put(registry_path, json.dumps(registry, ensure_ascii=False, indent=2)+'\n')
replace(ROOT/'commons/maps/Random_Entropies/summary.md',
        'A full-size chair specimen at (3,2)', 'A full-size chair specimen on the visitor floor at (9,3)')
replace(ROOT/'commons/maps/Random_Entropies/artifacts.md',
        '`entropy_chair_reference` at (3,2) is a full-scale wall specimen',
        '`entropy_chair_reference` at (9,3) is a full-scale chair on the visitor floor in front of its wall label')
replace(ROOT/'commons/maps/Random_Entropies/artifacts.md',
        '../../../doc/book/iterations/2026-10-16-doors-and-one-guess/index.html', REVIEW)
replace(ROOT/'commons/maps/Random_Entropies/map_data.json',
        'three pits with visible chance tickets.', 'four tables of miniature chairs for the best-guess comparison.')

floor_note = '\nThe full-size entrance chair at (9,3) is on the visitor floor. Its raised shelf and the one-metre platform cell beneath it are removed; the divider continues behind the wall label. Other full-size chair groups remain on the floor. The final guessing studies intentionally use miniature chairs on reachable 0.75 m tables.\n'
for file in ['plan.md', 'tutorial.md']:
    path = ROOT/'commons/maps/Random_Entropies'/file
    if floor_note.strip() not in text(path): put(path, text(path)+floor_note)
put(HERE/'installation.json', json.dumps(receipts, ensure_ascii=False, indent=2)+'\n')
print('Installed both revisions; final notes updated; route order and magnet geometry preserved.')
