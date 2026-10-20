"""Publish reviewed changes, real captures and the unrun human pilot protocol."""
from pathlib import Path
import difflib, html, json, shutil, hashlib
from publish_ml_sequence_review import page, md
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-11-ml-feedback'
PREFIX='../2026-10-11-ml-whole-route/'

def main():
    tests=json.loads((OUT/'artifact-tests.json').read_text())
    assert tests['passed'] and not tests['failures']
    for hall,suffix,pic in [('ML_Neural_Networks','network','input-audit'),('ML_Evolution','evolution','renewal-clock')]:
        run=ROOT/'ada_run/encounter_pilot'/hall/(suffix+'_lesson')
        receipt=json.loads((run/'report.json').read_text())
        assert receipt['passed']
        shutil.copy2(run/(pic+'.png'),OUT/(pic+'.png'))
        shutil.copy2(run/'report.json',OUT/(suffix+'-museum-tests.json'))
    for name in ['ML-HUMAN-PILOT.md','ML-HUMAN-PILOT.csv']:
        shutil.copy2(ROOT/'doc/book/course/storyboards'/name,OUT/name)
    changes=[];register={}
    for old in sorted((OUT/'before').rglob('*')):
        if not old.is_file():continue
        rel=old.relative_to(OUT/'before');current=ROOT/rel
        register[rel.as_posix()]=hashlib.sha256(current.read_bytes()).hexdigest()
        before=old.read_text(encoding='utf-8');after=current.read_text(encoding='utf-8')
        target=OUT/'after'/rel;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(current,target)
        if before==after:continue
        diff=''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='Before',tofile='Now'))
        changes.append('<details><summary>'+html.escape(rel.as_posix())+'</summary><pre>'+html.escape(diff)+'</pre></details>')
    body='<h1>Keep the route.<br>Make the evidence visible.</h1><p><a href="changes.html">Exact changes</a> · <a href="pilot.html">Proposed human pilot</a> · <a href="external-review.html">The external review</a> · <a href="'+PREFIX+'ml-sequence-review.zip">Updated complete review ZIP</a></p>'
    body+='<figure><img src="input-audit.png" alt="Dark lower disclosure panel in the museum network diagram naming the answer-bearing inputs"><figcaption>Actual museum capture: the network names which input channels contain its targets. The legacy diagram remains in place.</figcaption></figure>'
    body+=md((OUT/'RESPONSE.md').read_text(encoding='utf-8'))
    body+='<figure><img src="renewal-clock.png" alt="Evolution population with the simulation-time renewal label in its crowded existing display area"><figcaption>Actual Evolution bay. The clock is corrected and named; competing displays and small text remain spatial work for a visitor-level pass.</figcaption></figure><p><a href="artifact-tests.json">Production checks</a> · <a href="network-museum-tests.json">Networks capture checks</a> · <a href="evolution-museum-tests.json">Evolution capture checks</a> · <a href="source-register.json">Source hashes</a></p>'
    (OUT/'index.html').write_text(page('ML / external feedback',body,PREFIX),encoding='utf-8')
    (OUT/'changes.html').write_text(page('ML / feedback changes','<h1>What changed</h1>'+''.join(changes),PREFIX),encoding='utf-8')
    (OUT/'pilot.html').write_text(page('ML / proposed human pilot',md((OUT/'ML-HUMAN-PILOT.md').read_text(encoding='utf-8'))+'<p><a href="ML-HUMAN-PILOT.csv">Blank observation sheet</a></p>',PREFIX),encoding='utf-8')
    (OUT/'external-review.html').write_text(page('ML / external review',md((OUT/'external-review.md').read_text(encoding='utf-8')),PREFIX),encoding='utf-8')
    (OUT/'source-register.json').write_text(json.dumps(register,indent=2),encoding='utf-8')
    print('Published feedback response,',len(changes),'changed source files,',len(tests['checks']),'artifact checks')

if __name__=='__main__':main()
