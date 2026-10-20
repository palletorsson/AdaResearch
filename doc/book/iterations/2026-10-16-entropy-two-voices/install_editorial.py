"""One-time editorial migration. Refuse to replace a subsequently changed final."""
from pathlib import Path
import copy
import hashlib
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
NOTES = {
    'Random_Entropies': {
        'entropy_chairs_shannon': 'A familiar chair gives the comparison a bodily scale. We keep the rare black chair in sight while the colour prediction favours pink. Moving chairs can leave the colour reading unchanged.',
        'entropy_chairs_boltzmann': 'Two arrangements meet the same brief: two pink on the left. Thirty-six assignments fit it; the count cannot identify the arrangement before us. That omission leads to the description wall.',
        'entropy_chairs_description': 'The scatter has a short seeded recipe, provided its generator comes too. A sketch retains a view; a recipe retains a construction. The next rule moves.',
        'entropy_door_dynamics': 'Nearly coincident door leaves converge or separate under different rules. LOW/HIGH records follow distinctions through eight steps. We pass through the open centre doorway.',
        'entropy_cooling_cup': 'Five cups keep stages that one cooling drink cannot retain side by side. Milk remains one quarter in every surface; the separate heat calculation introduces thermodynamic entropy and joules per kelvin.',
        'entropy_frosted_chair': 'The pink chair returns behind five panes. Different frost can accompany the same colour-only record. The printed uncertainty does not measure our attempt to recognise the chair.',
        'entropy_ball_pit': 'At the all-pink tray, the colour answer is settled while the positions remain visible. We could rearrange every ball without changing that answer. Workshop begins by performing such a change.',
    },
    'Random_Entropy': {
        'shannon_entropy_meter': 'SORT changes neighbours while the bars and colour entropy stay still. The retained strip keeps an earlier arrangement available. The next instruments give position more than one address.',
        'entropy_jar_states': 'The core remains visible through its rim before mixing begins. Height and core/rim records disagree about the same beads. The names on the plinth gradually describe a past harder to find in the mixture.',
        'entropy_jar': 'After watching four mixtures, we lift and shake a jar. Its whole colour inventory stays balanced while height readings change. Keeping all its positions would require a longer record.',
        'entropy_sorting_table': 'The divider removes possible pictures without moving a cube. Exchanging the middle pair then changes the counts in the boxes. Four places make every surviving possibility inspectable before the larger cabinet.',
        'entropy_compartments': 'At balance, 4,900 assignments fit the account. SAME k changes the arrangement without moving either dial. KEEP must retain site lists and generator states that the readings omit.',
        'entropy_axiom': 'We move sideways through points whose displacement has a spatial rule. The view changes while the arrangement remains. There is no entropy gauge here.',
        'entropy_ruin': 'One selected support leaves; contact and gravity can move others. PULLED and MOVED can diverge while all 116 stones remain. The neighbouring wall has composed landing places, a different procedure.',
        'signal_room': 'Counts and neighbours return at room scale. Unlike the removed support, a changed black or white patch leaves the floor firm. The next hall will make the boundary of an eligible removal explicit.',
    },
}

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

if __name__ == '__main__':
    for name in NOTES:
        current = ROOT / 'commons/maps' / name / 'final.md'
        assert current.read_bytes() == (HERE / 'before' / name / 'final.md').read_bytes(), \
            f'{name}: final changed since the retained original; merge rather than overwrite.'

    evidence = {'date': '2026-10-16', 'maps': {}}
    for name, updates in NOTES.items():
        directory = ROOT / 'commons/maps' / name
        wall_path = directory / 'writing_wall.json'
        before = json.loads(wall_path.read_text(encoding='utf-8-sig'))
        wall = copy.deepcopy(before)
        by_id = {magnet['id']: magnet for magnet in wall['magnets']}
        for artifact, note in updates.items():
            by_id[artifact]['final'] = note
        # Record what was actually current immediately before this narrow edit.
        (HERE / 'before' / name / 'writing_wall-at-install.json').write_bytes(wall_path.read_bytes())
        evidence['maps'][name] = {
            'map_sha256': sha(directory / 'map_data.json'),
            'tutorial_sha256': sha(directory / 'tutorial.md'),
            'original_final_sha256': sha(directory / 'final.md'),
            'edited_final_notes': list(updates),
        }
        (directory / 'final.md').write_bytes((HERE / f'{name}-final.md').read_bytes())
        wall_path.write_text(json.dumps(wall, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        plan = directory / 'plan.md'
        addition = '''
## Two final chapters in the encounter voice · 16 October 2026

The [paired reading](../../../doc/book/iterations/2026-10-16-entropy-two-voices/index.html) adopts the situated “we” voice of Random Definition. Both canonical finals and the magnets' final notes now follow the existing room orders. Earlier versions are retained beside the revisions. The first 48-value bench remains the first research pilot.

Types carries the chair through colour, arrangement, description and incomplete records. Its last all-pink tray leads into Workshop's SORT: a changed arrangement can leave a colour answer unchanged. Workshop then follows interventions, preserved states and consequences the readings omit. These are overlapping questions with different work in each hall, not exclusive subject territories.

Reading check: read both chapters, then mark the first transition where the next encounter feels unnecessary, and the first technical term that interrupts the encounter. At the join, what would we now want to change or record? Record the response verbatim, including a wish to stay, skip or investigate something else. Revise the weakest passage once and compare it with this retained edition. Do not infer successful reading from accurate arithmetic or a working scene.

This pass verifies source claims, numerical examples, artifact order and links. It changes no apparatus or placement. Existing runtime receipts remain separate; headset comfort, independent reconstruction and the new prose's effect still need human evidence. The tutorials remain reconstruction texts and are unchanged by this voice pass.
'''
        assert '## Two final chapters in the encounter voice' not in plan.read_text(encoding='utf-8')
        with plan.open('a', encoding='utf-8', newline='\n') as out:
            out.write(addition)

    (HERE / 'installation.json').write_text(json.dumps(evidence, indent=2) + '\n', encoding='utf-8')
    state = ROOT / 'doc/book/STATE.md'
    text = state.read_text(encoding='utf-8')
    heading = '## Two entropy finals in the encounter voice · 16 October 2026'
    entry = heading + '''

The [paired reading](iterations/2026-10-16-entropy-two-voices/index.html) revises both canonical entropy finals using Random Definition's situated “we” voice. Entropy Types becomes *What remains uncertain*; Entropy Workshop becomes *What the gauge forgets*. The first ends with rearranging an all-pink tray; the second starts with SORT and unchanged colour entropy. The room orders remain, with seven Types encounters and eight Workshop encounters; hybrids and hardware stay optional. Writing-wall final notes and both plans follow the revision. Original chapters and the reference voice are retained with before/after pages. Source and numerical checks support the prose; no new runtime or reader result is claimed. Next: identify the first transition that fails to create a need for the next encounter. The first 48-value pilot is unchanged. No commit or push requested.

'''
    assert heading not in text
    first_break = text.index('\n\n') + 2
    state.write_text(text[:first_break] + entry + text[first_break:], encoding='utf-8')
    print('Installed both finals; updated only final magnet notes, appended reading plans and book state.')
