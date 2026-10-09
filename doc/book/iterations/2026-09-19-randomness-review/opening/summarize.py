from pathlib import Path
import difflib,hashlib,json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[4]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
manifest=read(HERE/'before-sha256.json');changes=[]
for rel,oldhash in manifest.items():
    p=ROOT/rel
    if p.is_file() and sha(p)!=oldhash:
        old=(HERE/'before-source'/rel).read_text(encoding='utf-8-sig');new=p.read_text(encoding='utf-8-sig')
        changes.append(dict(path=rel,before_sha256=oldhash,after_sha256=sha(p),diff=''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+rel,tofile=rel))))
(HERE/'source-changes.json').write_text(json.dumps(changes,ensure_ascii=False,indent=2),encoding='utf-8')
(HERE/'source.diff').write_text('\n'.join(c['diff'] for c in changes),encoding='utf-8')
runs={}
for folder in sorted(HERE.iterdir()):
    if (folder/'run.json').is_file():
        d=read(folder/'run.json');r=read(folder/'checks.json') if (folder/'checks.json').is_file() else {}
        runs[folder.name]=dict(returncode=d['returncode'],source_stable=d['source_stable'],checks=len(r.get('checks',[])),failed=r.get('failed'),script_errors='SCRIPT ERROR' in (folder/'process.log').read_text(encoding='utf-8'))
history={}
historical=['ada_run/waves_chance_noise/Random_Definition/probe_random_definition_live.json','ada_run/waves_chance_noise/Random_Entropy/probe_entropy_live.json','ada_run/waves_chance_noise/Random_Remove/probe_remove_live.json']
historical += [f'doc/space/randomness-spatial-2026-09-16/{name}-runtime.json' for name in ['Random_Definition','Random_Entropy','Random_Remove']]
for rel in historical:
    d=read(ROOT/rel)
    history[rel]=dict(checks=d.get('checks'),failures=d.get('failures'),headset_verified=d.get('headset_verified'),has_source_hashes=bool(d.get('source_sha256')))
package=ROOT/'doc/book/review-packages/2026-09-18/randomness/sources'
matches={rel:dict(package_exists=(package/rel).exists(),same_as_prepass=sha(package/rel)==h if (package/rel).is_file() else None) for rel,h in manifest.items()}
dated=read(ROOT/'doc/space/random-definition-review-2026-09-12/verification.json')['run']
old_match={}
for rel,h in dated['source_sha256'].items():
    before=HERE/'before-source'/rel
    if not before.exists(): before=HERE.parent/'before'/rel
    recorded=sha(before) if before.is_file() else None
    old_match[rel]=dict(reported_sha256=h,prepass_sha256=recorded,same_as_prepass=recorded==h if recorded else None)
(HERE/'historical-evidence.json').write_text(json.dumps(dict(reports=history,definition_sept12=old_match,package_source_comparison=matches),indent=2),encoding='utf-8')
records=read(HERE/'source-chain.json')
verification=dict(runs=runs,changed_sources=[c['path'] for c in changes],placements={n:len(v['placements']) for n,v in records.items()},retained_placements=sum(len(v['placements']) for v in records.values()),headset_verified=False,new_museum_capture=False,source_closure_files=len(manifest))
(HERE/'verification.json').write_text(json.dumps(verification,indent=2),encoding='utf-8')
print(json.dumps(verification,indent=2))
