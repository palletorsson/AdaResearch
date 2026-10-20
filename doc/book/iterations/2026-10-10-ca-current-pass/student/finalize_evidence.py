from pathlib import Path
import json, re, hashlib, difflib
ROOT=Path(__file__).resolve().parent
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
data=json.loads((ROOT/'results.json').read_text())
order=json.loads((ROOT.parent/'packet/order.json').read_text())
integrity=[]
for hall in order:
    text=(ROOT.parent/'packet'/hall/'tutorial.md').read_text()
    blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\r?\n(.*?)```',text,re.S)
    diffs=[]
    for filename,code in blocks:
        original=ROOT/hall/'original'/filename
        variation=ROOT/hall/'variation'/filename
        equal=original.read_text()==code
        integrity.append({'hall':hall,'file':filename,'matches_printed_block':equal,'original_sha256':sha(original),'variation_sha256':sha(variation)})
        diffs.extend(difflib.unified_diff(original.read_text().splitlines(keepends=True),variation.read_text().splitlines(keepends=True),fromfile='original/'+filename,tofile='variation/'+filename))
    (ROOT/hall/'source_variation.diff').write_text(''.join(diffs),encoding='utf-8')
summary=[]
for key,run in data['runs'].items():
    for attempt in run['attempts']:
        folder=Path(attempt['latest_log']).parent
        attempt['artifact_hashes']={p.name:sha(p) for p in folder.iterdir() if p.is_file() and p.name!='run.json'}
        (folder/'run.json').write_text(json.dumps(attempt,indent=2))
    run['latest']=run['attempts'][-1]
    latest=run['latest']
    checks=latest['checks']['checks']
    run['exit_code']=latest['effective_exit_code']
    run['errors']=latest['errors']
    run['checks_passed']=sum(c['passed'] for c in checks)
    run['checks_total']=len(checks)
    run['latest_log']=latest['latest_log']
    run['latest_screenshot']=str(Path(latest['latest_log']).parent/'screenshot.png')
    summary.append({'hall':run['hall'],'variant':run['variant'],'exit':run['exit_code'],'checks':len(checks),'errors':len(run['errors']),'latest_log':run['latest_log'],'screenshot':run['latest_screenshot']})
data['summary']={'original_programs':8,'source_variations':8,'latest_passed':sum(r['exit']==0 for r in summary),'latest_failed':sum(r['exit']!=0 for r in summary),'checks_total':sum(r['checks'] for r in summary),'checks_include_repeated_per_cell_or_instance_assertions':True,'originals_match_printed_blocks':all(r['matches_printed_block'] for r in integrity),'book_repairs':[],'failure_account':'FAILURES.md','prediction_sha256':sha(ROOT/'PREDICTIONS.md')}
data['compact_runs']=summary
(ROOT/'results.json').write_text(json.dumps(data,indent=2))
(ROOT/'integrity.json').write_text(json.dumps(integrity,indent=2))
(ROOT/'SUMMARY.json').write_text(json.dumps({'summary':data['summary'],'runs':summary},indent=2))
print(json.dumps(data['summary'],indent=2))
for r in summary: print(r['hall'],r['variant'],r['exit'],r['checks'])
