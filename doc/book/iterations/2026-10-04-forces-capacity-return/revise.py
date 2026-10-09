"""Revise Forces summary plans only; preserve runtime and full hall texts."""
from pathlib import Path
import copy, difflib, hashlib, json, re

ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
ROUTE=ROOT/'doc/book/iterations/2026-10-04-museum-tutorial-storyboards'
def load(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,d): p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

ARC = 'PROPOSED. Return to known positions, displacements and route records; re-explain any earlier operation that the learner has not yet owned. Separate an analytic launch from an engine-driven force pulse, then make velocity assignment versus retained velocity the central comparison. Reuse the small state update for restoration and damping. Treat work, support and targeting as selected comparisons rather than additional compulsory builds. The closing field names its cube and visitor receivers before Form Finding deliberately removes carried velocity. Keep all thirteen halls and their critical writing; reduced edit bindings and cross-hall learner-code transfer remain to be written.'
UPDATES = [h for name in ['updates-opening.json','updates-motion.json','updates-ending.json'] for h in load(OUT/name)]

HEADING = '## 7. Vectors & Forces: From Direction to Dynamics'
PATTERN = r'^## 7\. Vectors & Forces: From Direction to Dynamics.*?(?=^## 8\.)'
def replace_section(path, section):
    text = path.read_text(encoding='utf-8')
    assert len(re.findall(PATTERN, text, re.M|re.S)) == 1, path
    after = re.sub(PATTERN, lambda _: section.rstrip()+'\n\n', text, flags=re.M|re.S)
    assert re.sub(PATTERN, '', text, flags=re.M|re.S) == re.sub(PATTERN, '', after, flags=re.M|re.S)
    path.write_text(after, encoding='utf-8')

def main():
    p = ROOT/'doc/book/course/storyboards/early.json'; data = load(p); old = copy.deepcopy(data)
    seq = next(s for s in data if s['sequence']=='forces')
    before = next(s for s in load(OUT/'before/doc/book/course/storyboards/early.json') if s['sequence']=='forces')
    assert [h['id'] for h in seq['halls']] == [u['id'] for u in UPDATES]
    changes = []
    for hall, update in zip(seq['halls'], UPDATES):
        for path in update['source_refs']: assert (ROOT/path).is_file(), path
        for mid in update['prior_maps']: assert (ROOT/'commons/maps'/mid).is_dir(), mid
        hall.update({k:v for k,v in update.items() if k not in ['before','after','reason']})
        hall['change_reason'] = update['reason']
        changes.append(dict(id=hall['id'], title=hall['title'], **{k:update[k] for k in ['before','after','reason']}))
    seq.update(arc=ARC, status='Revised teaching proposals; review each map before full lessons', tutorial_guidance='doc/book/course/storyboards/FORCES.md')
    assert [s for s in data if s['sequence']!='forces'] == [s for s in old if s['sequence']!='forces']
    save(p, data); save(OUT/'changes.json', changes)

    p = ROOT/'commons/maps/sequences/forces.json'; meta = load(p); bmeta = copy.deepcopy(meta); s = meta['sequences']['forces']
    s['learning_objectives_status'] = 'Revised summary proposals; existing companion texts retained, reduced learner edit locations and lessons pending.'
    s['learning_objectives'] = ['Use displacement independently of display origin; name retained projection components and the installed small-vector threshold', 'Keep compatible vector sums distinct from travelled distance and intermediate route records', 'Construct an along-rail component and remainder; check they recombine without turning a diagram into a physical torque claim', 'Sample a supplied analytic flight formula with explicit initial state, constant acceleration and landing-height assumptions', 'Control a finite force pulse while the engine integrates a rigid body; distinguish ending force from stopping motion', 'Own the two numerical updates that either assign velocity or add acceleration to retained velocity', 'Reuse state-dependent resistance and restoration with named units, mass and update order; retain the supplied fixed-step runner', 'Introduce period and phase at the rods, then use the existing paired-dial rate edit to distinguish a fixed offset from growing separation', 'Distribute equal and opposite interaction forces while allowing different acceleration and fixed-source policies', 'Keep support and targeting as bounded comparisons; do not require a gait controller or creature reconstruction', 'Apply a local acceleration to a declared cube receiver; compare the separate visitor contract and preserve the departure into optimisation without inertia']
    report = 'doc/book/iterations/2026-10-04-forces-capacity-return/index.html'
    s['local_review_history'] = [h for h in s.get('local_review_history', []) if h.get('report')!=report]
    s['local_review_history'].append(dict(date='2026-10-04', report=report, decision='Keep the thirteen-hall order, share the state-update reasoning across Fields and Oscillation, and lighten support/arena obligations.', status='Proposed summaries only; no runtime or full companion changes'))
    for key in ['maps','prerequisites','unlocks','artifact_groups']: assert s[key] == bmeta['sequences']['forces'][key]
    save(p, meta)

    p = ROUTE/'route.json'; route = load(p); broute = copy.deepcopy(route); byid = {h['id']:h for h in seq['halls']}
    for hall in route['halls']:
        if hall['sequence']=='forces': hall.update(byid[hall['id']])
    next(s for s in route['sequences'] if s['id']=='forces')['arc'] = ARC
    assert [h for h in route['halls'] if h['sequence']!='forces'] == [h for h in broute['halls'] if h['sequence']!='forces']
    assert [h['id'] for h in route['halls']] == [h['id'] for h in broute['halls']]
    save(p, route)
    p = ROUTE/'index.html'; text = p.read_text(encoding='utf-8'); pat = r'(<script id="route-data" type="application/json">).*?(</script>)'
    assert len(re.findall(pat, text, re.S)) == 1
    p.write_text(re.sub(pat, lambda m:m[1]+json.dumps(route, ensure_ascii=False).replace('</','<\\/')+m[2], text, count=1, flags=re.S), encoding='utf-8')

    full = [HEADING, ARC, '']; short = [HEADING, '']
    for hall in seq['halls']:
        full += [f'### {hall["id"]} — {hall["title"]}',hall['storyboard'],'','**Short AI alternative**',hall['storyboard_short'],'',f'*For correction:* {hall["review_note"]}','']
        short += [f'### {hall["id"]}',hall['storyboard_short'],'']
    for p in [ROOT/'doc/book/course/TUTORIAL_STORYBOARDS.md',ROUTE/'storyboards.md']: replace_section(p,'\n'.join(full))
    for p in [ROOT/'doc/book/course/TUTORIAL_STORYBOARDS_SHORT.md',ROUTE/'storyboards-short.md']: replace_section(p,'\n'.join(short))
    for p in [ROOT/'doc/book/course/storyboards/SEQUENCES.md',ROUTE/'sequences.md']:
        text=p.read_text(encoding='utf-8'); a=text.index(HEADING); b=text.index('## 8.',a)
        lines=text[a:b].splitlines(); lines[1]=ARC; replace_section(p,'\n'.join(lines))

    diff=[]
    for oldhall,hall in zip(before['halls'],seq['halls']):
        for key in ['title','mode','storyboard','storyboard_short','brings','learns','carries','supplied','independent_check','prior_maps','review_note']:
            a=oldhall.get(key, '(not previously declared)'); b=hall.get(key, '(not previously declared)')
            if not isinstance(a,str): a=json.dumps(a,ensure_ascii=False)
            if not isinstance(b,str): b=json.dumps(b,ensure_ascii=False)
            diff.extend(difflib.unified_diff([a+'\n'],[b+'\n'],fromfile=hall['id']+'/'+key+'/before',tofile=hall['id']+'/'+key+'/after'))
    (OUT/'summaries.diff').write_text(''.join(diff),encoding='utf-8')
    changed_elsewhere=[]
    reviewed_external={'commons/maps/VFM_03_Motion/map_data.json':'0928dafc203ef7f18bbbabc049d91e4e4eca1e302e30f2452fada04b0d43d924'}
    for record in load(OUT/'unchanged-evidence-before.json'):
        current=hashlib.sha256((ROOT/record['path']).read_bytes()).hexdigest()
        if current!=record['sha256']:
            assert reviewed_external.get(record['path'])==current, record['path']
            changed_elsewhere.append(dict(**record,current_sha256=current,note='Changed outside this summary pass during work. Preserved; motion_chamber and friction-ramp lesson bindings remain.'))
    save(OUT/'checks.json',dict(sequence='forces',maps=13,other_route_halls_unchanged=len(route['halls'])-13,order_unchanged=True,other_authored_sequences_unchanged=True,other_markdown_sections_unchanged=True,finals_and_tutorials_unchanged=True,protected_files_unchanged=39-len(changed_elsewhere),external_changes_preserved=changed_elsewhere,runtime_checked=False))
    print('Thirteen Forces proposals updated; other sequences, order and full map documents preserved.')

if __name__=='__main__': main()
