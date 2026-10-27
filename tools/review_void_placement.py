"""Record a placement-only review from inspected notes and fresh basic receipts.

Usage: python tools/review_void_placement.py 29
Requires a human-readable review-notes.json in the batch folder. Passing receipts
alone do not constitute a review; this packages the author's explicit findings.
"""
from pathlib import Path
import html,importlib.util,json,struct,sys
ROOT=Path(__file__).resolve().parents[1]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,x):p.write_text(json.dumps(x,indent=2)+'\n',encoding='utf8')
def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path)
    obj=importlib.util.module_from_spec(spec);spec.loader.exec_module(obj);return obj
def main():
    batch=sys.argv[1];assert batch.isdigit()
    here=ROOT/'doc/void-transfer'/('2026-10-21-batch-'+batch)
    notes=read(here/'review-notes.json')
    snapshot=module('receipt_snapshot',here.parent/'2026-10-21-batch-25/review.py')
    jobs=read(here/'batch.json')['jobs'];summaries=[]
    for job in jobs:
        trial=job['sequence'];folder=ROOT/job['folder'];e=folder/'evidence'
        findings=notes['trials'][trial];assert findings['review'] and findings['limitations']
        result=snapshot.inspect(job)
        assert not result['source_scale_height_layout_problems'],result
        assert all(x.get('passed') for x in result['receipts'].values()),result
        assert result['export']['failures']==[] and result['export']['stale_sources']==[],result
        load=read(e/'checks.json');assert load['placement_load_only'] and not load['acceptance']
        models=ROOT.parent/'ada_encyclopedia/public/void-trials'/trial
        count=meshes=0
        for p in models.glob('*.glb'):
            b=p.read_bytes();magic,version,length=struct.unpack_from('<III',b)
            assert magic==0x46546c67 and version==2 and length==len(b),p
            size,kind=struct.unpack_from('<II',b,12);assert kind==0x4e4f534a
            gltf=json.loads(b[20:20+size]);assert gltf.get('meshes'),p
            count+=1;meshes+=len(gltf['meshes'])
        evidence=dict(source_checks=len(read(e/'source-checks.json')['checks']),native_load_checks=len(load['checks']),
            editor_checks=len(read(e/'editor-checks.json')['checks']),valid_nonempty_glbs=count,mesh_count=meshes)
        review=dict(trial=trial,reviewer='Codex (transfer author and placement/evidence review)',date='2026-10-21',
            status='accepted_as_uncurated_transfer',scope='Placement, source fidelity, basic load, editor models and saves only; artifact buttons and gameplay untested',
            maps=len(job['maps']),source_occurrences=job['source_placements'],evidence=evidence,**findings)
        write(here/(trial+'-review.json'),review)
        write(here/(trial+'-verification.json'),result)
        write(folder/'transfer-status.json',dict(owner='Codex',stage='placed_load_checked_uncurated',maps=job['maps'],placed=job['source_placements'],omitted=[],native_tested=False,native_load_checked=True,buttons_tested=False,headset_tested=False,curated=False))
        (folder/'HANDOFF.md').write_text('# '+trial+' — placed for curation\n\nOriginal scenes, token config, scale and height preserved. Standard floors; each occurrence independently editable. Desktop and VR share rooms.json. Artifact buttons and gameplay intentionally untested.\n\n'+'\n'.join('- '+x for x in findings['review']+findings['limitations'])+'\n\nEvidence: '+json.dumps(evidence)+'\n',encoding='utf8')
        summaries.append(dict(trial=trial,maps=len(job['maps']),placed=job['source_placements'],evidence=evidence))
    write(here/'STATUS.json',dict(owner='Codex',stage='placement_review_complete',trials=summaries,next=notes['next']))
    (here/'PROGRESS.md').write_text('# Batch '+batch+' complete — placement-first\n\n'+'\n'.join('- '+x['trial']+': '+str(x['maps'])+' maps, '+str(x['placed'])+' original occurrences; '+json.dumps(x['evidence']) for x in summaries)+'\n\nArtifact controls/gameplay deliberately untested. No curation or chapter rewrites. Reviews include source-size/fit/dependency limits.\n\nNext: '+notes['next']+'\nContinue transfers after review; rolling follow-up ACTIVE. Do not reprepare completed trials or overwrite saved user arrangements.\n',encoding='utf8')
    gallery=module('placement_gallery',here.parent/'2026-10-21-batch-25/build_review_page.py')
    gallery.HERE=here;gallery.OUT=ROOT/'doc/book/iterations'/('2026-10-21-void-transfer-batch-'+batch);gallery.main()
    p=gallery.OUT/'index.html';s=p.read_text(encoding='utf8')
    s=s.replace('independent transfer review','placement-first transfer review').replace('Independent review','Placement review')
    s=s.replace('Native checks use desktop and synthetic tracked XR.','Only basic loading is checked in desktop and synthetic tracked XR. Artifact buttons and gameplay are deliberately untested.')
    open_issues=[limit for finding in notes['trials'].values() for limit in finding['limitations'] if limit.startswith('Known unresolved import issue:')]
    if open_issues:
        banner='<aside style="padding:18px;border:1px solid #c793bb;background:#342532"><strong>Open integration issue</strong><p>'+html.escape(' '.join(open_issues))+'</p></aside>'
        s=s.replace('<section id=',banner+'<section id=',1)
    p.write_text(s,encoding='utf8');print(json.dumps(summaries))
if __name__=='__main__':main()
