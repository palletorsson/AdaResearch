from pathlib import Path
import json, difflib, hashlib, re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
B = HERE / 'before'
ROOM = 'QFEP_Introduction'
checks = []

def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def check(ok, text): checks.append({'ok':bool(ok), 'message':text})
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def families(d): return {c.split('#')[0].split(':')[0] for row in d['layers']['interactables'] for c in row if c.strip()}
def without(d, key): return {k:v for k,v in d.items() if k != key}

seq_path = Path('commons/maps/sequences/qfeplaboratory.json')
oldseq, seq = [read(root / seq_path)['sequences']['qfeplaboratory'] for root in [B, ROOT]]
for key in ['maps', 'prerequisites', 'unlocks', 'deferred_maps', 'completion_rewards']:
    check(seq[key] == oldseq[key], key+' unchanged')
check([g for g in seq['artifact_groups'] if g['map'] != ROOM] == [g for g in oldseq['artifact_groups'] if g['map'] != ROOM], 'Other hall groups unchanged')
for room in seq['maps']:
    rel = Path('commons/maps') / room
    old, now = read(B / rel / 'map_data.json'), read(ROOT / rel / 'map_data.json')
    check(families(old) == families(now), room+': all artifact families retained')
    if room != ROOM:
        for name in ['map_data.json', 'final.md']:
            check((B / rel / name).read_bytes() == (ROOT / rel / name).read_bytes(), room+': '+name+' byte-preserved')
current = read(ROOT / 'commons/maps' / ROOM / 'map_data.json')
check(len(families(current)) == 11, 'All eleven introduction families retained')
check(all(len(rows)==12 and all(len(row)==13 for row in rows) for rows in current['layers'].values()), 'Map layers agree at 13 by 12')
for x,z in [(5,4),(6,10),(7,10)]:
    check(str(current['layers']['structure'][z][x])=='1', 'Clear floor at '+str((x,z)))

role_path = Path('commons/data/artifact_roles.json')
oldroles, roles = read(B/role_path), read(ROOT/role_path)
for k in ['roles', 'order']:
    check(without(oldroles[k],ROOM)==without(roles[k],ROOM), 'Other '+k+' retained')
check(roles['order'][ROOM]['primary']==['qfep_balance_workbench'], 'Primary remains the balance workbench')
check(set(roles['roles'][ROOM])==families(current), 'Every placed family has a role, including existing fruit comparison')

core_path = Path('commons/data/museum_core_encounters.json')
oldcore, core = [read(r/core_path)['rooms'] for r in [B,ROOT]]
check(without(oldcore,ROOM)==without(core,ROOM), 'Other core encounters preserved')
for key,name in [('text_sha256','final.md'),('map_sha256','map_data.json')]:
    check(core[ROOM][key]==sha(ROOT/'commons/maps'/ROOM/name), 'Current '+key)
check(core[ROOM]['learner_verified'] is False, 'Learner verification remains pending')
text = (ROOT/'commons/maps'/ROOM/'final.md').read_text(encoding='utf-8')
check(re.findall(r'<!-- @([\w_]+) -->',text)==['qfep_balance_workbench'], 'Book anchor matches primary')
archive = (ROOT/'commons/maps'/ROOM/'design-proposals.md').read_text(encoding='utf-8')
for name in ['technical.md','critical.md']:
    check((B/'commons/maps'/ROOM/name).read_text(encoding='utf-8-sig') in archive, 'Earlier '+name+' retained verbatim as historical proposal')

book_path = Path('commons/data/book/qfeplaboratory.json')
oldbook, book = [read(r/book_path)['pearls'] for r in [B,ROOT]]
check([p for p in oldbook if p['map']!=ROOM]==[p for p in book if p['map']!=ROOM], 'Other book pearls preserved')
pearl = next(p for p in book if p['map']==ROOM)
check(pearl['hero']=='qfep_balance_workbench', 'Book hero repaired from tutorial table to primary')
for path in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
    old, now = read(B/path),read(ROOT/path)
    check([n for n in old['trunk'] if n['node']!='qfeplaboratory']==[n for n in now['trunk'] if n['node']!='qfeplaboratory'], path+': unrelated chapters unchanged')
    n=next(n for n in now['trunk'] if n['node']=='qfeplaboratory')
    oldn=next(n for n in old['trunk'] if n['node']=='qfeplaboratory')
    check([p for p in n['pearls'] if p['map']!=ROOM]==[p for p in oldn['pearls'] if p['map']!=ROOM], path+': other hall speech retained')
    p=next(p for p in n['pearls'] if p['map']==ROOM)
    check(p['hero']==pearl['hero'] and p['says']=={ln['token']:ln['text'] for ln in pearl['lines']}, path+': introduction speech agrees')

path=Path('commons/artifacts/registry/qfep.json')
old,now=[read(r/path)['artifacts'] for r in [B,ROOT]]
check(without(old,'qfep_balance_workbench')==without(now,'qfep_balance_workbench'), 'Other registry entries preserved')
authored=read(ROOT/'commons/data/map_authored.json')
check(authored==read(B/'commons/data/map_authored.json'), 'Authored membership unchanged')
check(set(seq['maps'])-set(authored['qfeplaboratory'])=={'QFEP_F_Term','QFEP_Sandbox'}, 'Two missing halls explicitly remain restoration tasks')
for path in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
    old,now=read(B/path),read(ROOT/path)
    def apart_from_declared_numbering(row):
        if row.get('sequence')=='qfeplaboratory':
            return {k:v for k,v in row.items() if k not in ['pearl_index','pearls_total']}
        return row
    check([apart_from_declared_numbering(r) for r in old['plans'] if r.get('map')!=ROOM]==[apart_from_declared_numbering(r) for r in now['plans'] if r.get('map')!=ROOM], path+': other plan geometry/configuration preserved; laboratory numbering follows declared order')
    check(all(r['pearls_total']==8 and r['pearl_index']==seq['maps'].index(r['map']) for r in now['plans'] if r.get('sequence')=='qfeplaboratory'), path+': declared eight-hall numbering retained despite two restoration gaps')
    row=next(r for r in now['plans'] if r.get('map')==ROOM)
    check({a['token'] for a in row['artifacts']}==families(current), path+': all eleven placements retained')
    a=next(a for a in row['artifacts'] if a['token']=='qfep_balance_workbench')
    check(a['cell']==[6,4] and a['rotation']==180 and a['config']=={'comparison':'on'}, path+': workbench location, facing and comparison agree')
check(read(ROOT/'ada_run/em_plan.json')==read(ROOT/'commons/data/museum/em_plan.json'), 'Both museum plans agree')

r=read(HERE/(ROOM+'-runtime.json'))
check(r['passed'] and not r['failures'], 'Museum probe passes')
check(len(r['checks'])==21 and all(c['ok'] for c in r['checks']), '21 runtime control/numerical checks pass')
check(len(r['walks'])==5 and all(w['passed'] for w in r['walks']), 'Five selected collision-body walks pass')
check(len(r['shots'])==5 and all((HERE/Path(p).name).is_file() for p in r['shots']), 'Five actual Godot captures retained')
a,b,c,d=r['captured_states'][:4]
check(a['values']!=b['values'] and abs(a['qfe']-b['qfe'])<1e-5 and abs(a['qfe']-.45)<1e-5 and a['kept']==b['kept'], 'First image pair: distinct arrangements, same 0.450 total and retained outline')
check(c['values'][1]!=d['values'][1] and c['values'][2]==d['values'][2]==0 and abs(c['qfe']-d['qfe'])<1e-5, 'Second image pair: changing E with zero lambda leaves total unchanged')
log=(HERE/(ROOM+'-engine.log')).read_text(encoding='utf-8',errors='replace')
check('No vertices were added' not in log and 'SCRIPT ERROR:' not in log, 'Zero-input geometry error fixed; no script errors in final probe')
for name in ['final.md','technical.md','critical.md']:
    rel=Path('commons/maps')/ROOM/name
    (HERE/(name.replace('.md','')+'.diff')).write_text(''.join(difflib.unified_diff((B/rel).read_text(encoding='utf-8-sig').splitlines(True),(ROOT/rel).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel.as_posix(),tofile=rel.as_posix())),encoding='utf-8')
(HERE/'current-inputs.json').write_text(json.dumps({f.relative_to(B).as_posix():{'before':sha(f),'current':sha(ROOT/f.relative_to(B))} for f in B.rglob('*') if f.is_file() and (ROOT/f.relative_to(B)).is_file()},indent=2)+'\n',encoding='utf-8')
failed=[c['message'] for c in checks if not c['ok']]
(HERE/'content-checks.json').write_text(json.dumps({'checks':checks,'count':len(checks),'failures':failed,'passed':not failed},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks':len(checks),'failures':failed}))
raise SystemExit(bool(failed))
