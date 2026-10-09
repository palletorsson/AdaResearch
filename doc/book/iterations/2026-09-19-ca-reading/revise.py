"""A small, guarded reading pass; museum and artifact files are read-only here."""
from pathlib import Path
import difflib
import hashlib
import json
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
BASE = HERE.relative_to(ROOT).as_posix()
maps = json.loads((ROOT / 'commons/maps/sequences/cellularautomata.json').read_text(encoding='utf-8'))['sequences']['cellularautomata']['maps']
for folder in ['before', 'after', 'diffs']:
    (HERE / folder).mkdir(parents=True, exist_ok=True)
originals = {}
for name in maps:
    source = ROOT / f'commons/maps/{name}/final.md'
    saved = HERE / 'before' / f'{name}.md'
    if not saved.exists():
        saved.write_bytes(source.read_bytes())
    originals[name] = saved.read_text(encoding='utf-8')

changes = []
def change(name, title, reason, old, new):
    assert originals[name].count(old) == 1, (name, title)
    changes.append(dict(map=name, title=title, description=reason, before=old, after=new))

change('CA_SoftRules', 'A room can wear a field',
       'Let the same texture become an encounter at another scale, with room for desire and another possible use. Keep the fixed-floor fact here and the additional implementation limits in a note.',
       'Now walk between the two curved displays. COAT removes their colour surfaces while the table fields continue. Bring them back. Nothing has moved from the table into the architecture: each pair uses the same texture. The fixed museum floor carries you through both versions. The room can wear this process, and later another body could wear it, but a material assignment has not supplied sensation, growth or agency.',
       '''Now walk between the two curved displays. Find a patch on a wall, then look for it on the table. Each pair shares the same texture. At the desk you could take in the small field; here you turn within its enlarged image.

Press COAT. The colour surfaces disappear while the table fields continue. Bring them back. The fixed museum floor carries you through both views.[^ca-soft-coating] The field has become something the room can wear. Perhaps you would keep it here, or want it closer, as a lining against a body. What would you change for that other use?''')

change('CA_SoftRules', 'Carry an unfinished resemblance forward',
       'The declared book order goes to the local-rule/pyramid comparison before the paired-difference study. Carry a question towards that comparison without claiming that the missing museum hall is already restored.',
       'The local study holds after 2,400 updates. The museum goes on. Carry the matched beginning and the visible clock into the next hall: when a small intervention changes an outcome, how will we tell what actually changed?',
       'The local study holds after 2,400 updates. The museum goes on. We have watched a field change and a room wear its image. Carry a question from those surfaces: could a similar form have another way of becoming?')

change('CA_AgentsCircuits', 'Give the gap a neighbour to remember',
       'Keep the review\'s careful comparison of one relation, including where it fails. Replace assessment-like instructions with a small act of looking and carrying something to the second work.',
       'Before leaving the rule display, choose one gap whose position you could describe to someone else. Describe the occupied cells around it as well as the empty region itself. A pattern can appear similar because its holes correspond, because its filled parts correspond, or because its outline does. Those are different comparisons. Carry that description to the pyramid and test only the relation you chose first. If it fails, locate the precise mismatch before choosing another relation; otherwise resemblance can become a moving target that never risks being wrong.',
       'Choose one triangular gap in the rule display. Keep a few occupied cells around it in mind, so there is more to recognise than the outline. Carry that small arrangement to the pyramid. Where would it fit? If one part refuses the match, stay with that part before choosing a different resemblance. We have found something the shared appearance did not tell us.')

change('CA_AgentsCircuits', 'Let recognition invite another experiment',
       'Keep the different procedures and the proposed seed experiment. Move the warning about computing claims into a note, and correct the transition to the existing paired-difference study rather than reintroducing graded states.',
       '''Both encounters produce organised patterns, but neither appearance alone proves the presence of an agent, a circuit or a general-purpose computer. Those claims require additional structure: states that can represent something, operations that transform them, and a way of checking the result.

A useful variation would keep the pyramid fixed while trying several different seeds in Rule 90. Some seeds preserve familiar triangular relations; others overlap them. The comparison would expose how much the resemblance depends on the starting condition.

<!-- @ -->

Next, the sequence asks what happens when a local update admits graded states and disturbance. Keep asking whether a name describes an observed relation or simply encourages you to see one.''',
       '''The row's next state and the pyramid's smaller copies can lead the eye towards a related form. The pleasure of recognising it gives us a reason to compare their making. A name for the resemblance can accompany that inquiry without finishing it.[^ca-resemblance]

A useful variation would keep the pyramid fixed while trying several different seeds in Rule 90. Some seeds preserve familiar triangular relations; others overlap them. The comparison would expose how much the resemblance depends on the starting condition.

<!-- @ -->

We will return to the pyramid's way of making in Fractals. First, two almost matching volumes will let us follow one changed value through the same procedure. We have asked how similar appearances can be made differently. What happens when we keep the making the same and alter one small part of the beginning?''')

notes = {
    'CA_SoftRules': [('ca-soft-coating', 'COAT toggles the wall display meshes. Their geometry stays fixed and has no collision shapes; the museum floor supplies support. Sharing a field texture does not create a sensing or growing body. Those would require additional operations.')],
    'CA_AgentsCircuits': [('ca-resemblance', 'An organised appearance alone does not demonstrate an agent, a circuit or a general-purpose computer. Such claims require an account of states, operations and the results they can produce. This comparison establishes a question about resemblance and procedure, not a proof of computational universality.')]
}

pending = []
for name in maps:
    text = originals[name]
    for item in [c for c in changes if c['map'] == name]:
        text = text.replace(item['before'], item['after'], 1)
    if name in notes:
        text = text.rstrip() + '\n\n' + '\n\n'.join(f'[^{key}]: {body}' for key, body in notes[name]) + '\n'
    assert re.findall(r'<!--\s*@.*?-->', text) == re.findall(r'<!--\s*@.*?-->', originals[name]), name
    assert re.findall(r'```.*?```', text, re.S) == re.findall(r'```.*?```', originals[name], re.S), name
    source = ROOT / f'commons/maps/{name}/final.md'
    current = source.read_text(encoding='utf-8')
    assert current in [originals[name], text], f'{name} changed during the reading pass'
    if text != originals[name]:
        (HERE / 'after' / f'{name}.md').write_text(text, encoding='utf-8')
        patch = ''.join(difflib.unified_diff(originals[name].splitlines(True), text.splitlines(True), fromfile=f'before/{name}/final.md', tofile=f'after/{name}/final.md'))
        (HERE / 'diffs' / f'{name}.diff').write_text(patch, encoding='utf-8')
    if current != text:
        old = source.read_bytes()
        data = text.encode('utf-8')
        if old.count(b'\r\n') == old.count(b'\n') and b'\n' in old:
            data = data.replace(b'\n', b'\r\n')
        pending.append((source, data))
for source, data in pending:
    source.write_bytes(data)

sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
record = {
    'date': '2026-09-19', 'scope': 'Eight chapters read; four passage interventions in two chapters; no engine or map changes.',
    'chapters': {name: {'before_sha256': sha(HERE / 'before' / f'{name}.md'), 'after_sha256': sha(ROOT / f'commons/maps/{name}/final.md')} for name in maps},
    'source_checks': 'Current exchange_study.gd supports the shared table/wall texture, COAT and delayed A/B explanation. Declared sequence order and effective museum order were read separately. No new runtime or headset test.'
}
(HERE / 'record.json').write_text(json.dumps(record, indent=2) + '\n', encoding='utf-8')
(HERE / 'passages.json').write_text(json.dumps(changes, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
items = [dict(title='Six chapters already carry the investigation', description='Preserve the first five chapters and Edge of Chaos. Their questions arise from ordered neighbours, lingering states, a history underfoot, a travelling pattern, lost support and a difference altered by storage. Keep every code block and artifact marker in this sequence.', report=BASE+'/READING.md', report_label='Reading decisions and the outstanding spatial task')]
for item in changes:
    items.append(dict(title=item['map'].replace('_', ' ')+' · '+item['title'], description=item['description'], before=item['before'], after=item['after'], text_kind='book passage', after_label='Applied', report=f'commons/maps/{item["map"]}/final.md', report_label='Read the complete current chapter'))
items.append(dict(title='A missing room is a spatial task', description='CA_AgentsCircuits remains in the declared book sequence but is absent from the effective museum order. Preserve its Rule 90/pyramid comparison and restore or deliberately place that encounter in a spatial pass. Text changes do not repair the route. The Soft Rules label reveal already exists from a separate pilot; this pass preserves it.', report=BASE+'/READING.md', report_label='Scope and remaining work'))
comparison = dict(status='two chapters revised · six preserved', summary='The encounter already carries most of this sequence. Four local changes make room for inhabiting an image, carrying a resemblance and choosing another experiment. The original passages remain beside the applied revisions; artifact and route tasks are tracked separately.', items=items)
(ROOT / 'doc/book/iterations/2026-09-19-review-comparison/cellularautomata.json').write_text(json.dumps(comparison, indent=2, ensure_ascii=False)+'\n', encoding='utf-8')
print(f'Cellular Automata: applied {len(pending)} chapters; six preserved; four passage comparisons saved.')
