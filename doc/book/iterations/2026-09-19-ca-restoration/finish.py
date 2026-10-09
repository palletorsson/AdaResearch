"""Record the bounded repair and append its evidence to the shared reading page."""
from pathlib import Path
import difflib
import hashlib
import json
import re
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
RUN = ROOT/'ada_run/encounter_pilot/CA_AgentsCircuits'
def read(path): return json.loads(path.read_text(encoding='utf-8-sig'))
def write(path, data): path.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
declared = read(ROOT/'commons/maps/sequences/cellularautomata.json')['sequences']['cellularautomata']['maps']
checks = {}
for rel in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
    old, new = read(HERE/'before'/rel), read(ROOT/rel)
    checks[rel+': other sequences unchanged'] = [r for r in old['plans'] if r.get('sequence')!='cellularautomata'] == [r for r in new['plans'] if r.get('sequence')!='cellularautomata']
    rows = [r for r in new['plans'] if r.get('sequence')=='cellularautomata']
    checks[rel+': declared route'] = [r['map'] for r in sorted(rows,key=lambda r:r['pearl_index'])] == declared
    checks[rel+': all eight counts'] = len(rows)==8 and all(r['pearls_total']==8 for r in rows)
    by_map = {r['map']:r for r in rows}
    strip_order = lambda r: {k:v for k,v in r.items() if k not in ['pearl_index','pearls_total']}
    checks[rel+': seven existing halls preserved'] = all(strip_order(r)==strip_order(by_map[r['map']]) for r in old['plans'] if r.get('sequence')=='cellularautomata')
old_authored = read(HERE/'before/commons/data/map_authored.json')
new_authored = read(ROOT/'commons/data/map_authored.json')
checks['authored membership'] = new_authored['cellularautomata']==declared
checks['other authored memberships preserved'] = {k:v for k,v in old_authored.items() if k!='cellularautomata'} == {k:v for k,v in new_authored.items() if k!='cellularautomata'}
for rel in ['commons/scenes/endless_museum.gd','commons/data/artifact_roles.json','commons/maps/sequences/cellularautomata.json']:
    checks[rel+': untouched by restoration'] = sha(ROOT/rel)==sha(HERE/'before'/rel)
walk = read(RUN/'report.json')
control = read(RUN/'controls-report.json')
nav = read(HERE/'navigation.json')
checks['floor and controlled walks'] = walk['passed'] and len(walk['walks'])==7 and len(walk['rays'])==6
checks['live controls'] = control['passed'] and len(control['controls'])==7
checks['production route'] = not nav['failures'] and nav['route']==declared
old_text = (HERE/'before/commons/maps/CA_AgentsCircuits/final.md').read_text(encoding='utf-8')
new_text = (ROOT/'commons/maps/CA_AgentsCircuits/final.md').read_text(encoding='utf-8')
checks['book markers retained'] = re.findall(r'<!--.*?-->',old_text)==re.findall(r'<!--.*?-->',new_text)
checks['both works primary'] = read(ROOT/'commons/data/artifact_roles.json')['order']['CA_AgentsCircuits']['primary']==['ca_rule_explorer','sierpinski_pyramid']
write(HERE/'verification.json',checks)
assert all(checks.values()), checks
core_path = ROOT/'commons/data/museum_core_encounters.json'
core = read(core_path)
room = core['rooms']['CA_AgentsCircuits']
room['text_sha256'] = sha(ROOT/room['text_path'])
room['map_sha256'] = sha(ROOT/'commons/maps/CA_AgentsCircuits/map_data.json')
# Preserve draft status and learner_verified=false; bounded runtime checks are separate.
assert room['learner_verified'] is False
write(core_path,core)
for name in ['arrival.png','desk.png','comparison.png','report.json','controls-report.json','source_manifest.json']:
    shutil.copy2(RUN/name,HERE/name)
(HERE/'CA_AgentsCircuits.diff').write_text(''.join(difflib.unified_diff(old_text.splitlines(True),new_text.splitlines(True),fromfile='before/final.md',tofile='current/final.md')),encoding='utf-8')
page_path = ROOT/'doc/book/iterations/2026-09-19-review-comparison/cellularautomata.json'
page = read(page_path)
page['status'] = 'two chapters revised · comparison hall restored'
page['summary'] = 'Four local editorial changes preserve the investigative voice. The missing Rule 90/pyramid hall is now restored between Soft Rules and Edge of Chaos, with both works primary. Two further text changes invite the controls and seed comparison now available there.'
page['items'][0]['report_label'] = 'Earlier reading decisions and the spatial follow-up'
page['items'][2]['description'] = 'Carry the question from Soft Rules into the local-rule/pyramid comparison. That next hall has now been restored in the museum as well as the book order.'
page['items'] = [x for x in page['items'] if x['title'] not in ['A missing room is a spatial task','The comparison has its room again','From a future variation to a present encounter','Build the history at your own pace']]
base = HERE.relative_to(ROOT).as_posix()
page['items'].append(dict(title='The comparison has its room again',
    description='Rule 90 near the entrance; the recursive pyramid farther on; a continuous floor between them and room to walk around the volume. Both existing works remain primary. The desk has its own legs, with its controls about 1.08 m above the floor. All eight CA halls now appear in the declared museum order.',
    images=[base+'/desk.png',base+'/comparison.png'],
    captions=['The live Rule 90 desk after seven STEP presses. RUN and SEED are available beside it.','The existing recursive pyramid farther along the same hall, approached from the shared aisle.'],
    image_note='Two current Godot museum views, not before/after versions. Captured in an isolated copy of the actual museum scene. Six floor checks, seven controlled walking segments, seven control checks and the eight-hall route passed. Headset reach, continuous portal travel and learner experience remain untested.',
    report=base+'/SUMMARY.md',report_label='What changed, what passed, and what remains'))
old_paragraphs, new_paragraphs = old_text.split('\n\n'), new_text.split('\n\n')
for prefix,title in [('Set the rule explorer','Build the history at your own pace'),('A useful variation','From a future variation to a present encounter')]:
    idx = next(i for i,p in enumerate(old_paragraphs) if p.startswith(prefix))
    page['items'].append(dict(title=title,description='The prose now invites an operation supported by the restored desk.',
        before=old_paragraphs[idx],after=new_paragraphs[idx],text_kind='book passage',after_label='Applied',
        report='commons/maps/CA_AgentsCircuits/final.md',report_label='Read the current chapter'))
write(page_path,page)
print('Saved repair evidence, two text comparisons and current museum views; preservation checks passed.')
