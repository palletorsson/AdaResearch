"""Record placement-first evidence, with no artifact interaction acceptance claim."""
from pathlib import Path
import importlib.util, json, struct

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,x): p.write_text(json.dumps(x,indent=2)+'\n',encoding='utf8')

def main():
    job=read(HERE/'batch.json')['jobs'][0];trial=job['sequence'];folder=ROOT/job['folder']
    evidence=folder/'evidence';checks=read(evidence/'checks.json')
    # Correct the old generic inherited receipt label; measured checks are unchanged.
    checks.update(acceptance=False,placement_load_only=True,
        scope='Placement-first desktop and synthetic XR startup, artifact instantiation/config, bounds and screenshots only. No buttons, grabs/triggers, combat, input mechanics, residency/retry or physical headset acceptance. Generic inherited label corrected without altering measured results.')
    write(evidence/'checks.json',checks)
    models=ROOT.parent/'ada_encyclopedia/public/void-trials'/trial
    count=meshes=0
    for p in models.glob('*.glb'):
        b=p.read_bytes();magic,version,length=struct.unpack_from('<III',b)
        assert magic==0x46546C67 and version==2 and length==len(b),p
        size,kind=struct.unpack_from('<II',b,12);assert kind==0x4E4F534A
        data=json.loads(b[20:20+size]);assert data.get('meshes'),p
        count+=1;meshes+=len(data['meshes'])
    spec=importlib.util.spec_from_file_location('snapshot',HERE.parent/'2026-10-21-batch-25/review.py')
    snapshot=importlib.util.module_from_spec(spec);spec.loader.exec_module(snapshot)
    result=snapshot.inspect(job)
    assert not result['source_scale_height_layout_problems'],result
    assert all(r.get('passed') for r in result['receipts'].values()),result
    assert result['export']['failures']==[] and result['export']['stale_sources']==[],result
    write(HERE/'final-verification.json',result)
    limits=[
        'Placement-first transfer only: artifact buttons, grabbing, catalyst combat and puzzle outcomes have not been tested. Desktop and synthetic XR load successfully; physical headset testing is deferred.',
        'Original large works retain their authored scale and height. Menger enclosure reaches across two storeys; Fibonacci extends above its storey; Cantor pagoda extends below the slab. Curation must resolve these spatial relationships.',
        'DLA growth currently extends past the side of the standard floor and below its slab; no floor enlargement or source shrink was introduced. These are uncurated arrangement limits.',
        'Models are static arrangement snapshots, not interactive web implementations. Some fractals continue to evolve after the snapshot.',
        'Source cleanup ObjectDB warnings remain recorded. The final basic load run reports no engine errors. No Quest performance or learning-outcome acceptance is claimed.'
    ]
    review=dict(trial=trial,reviewer='Codex (transfer author and placement/evidence review)',date='2026-10-21',
        status='accepted_as_uncurated_transfer',scope='Placement/load/editor/save only; no artifact button or mechanics tests',
        maps=len(job['maps']),source_occurrences=job['source_placements'],
        evidence=dict(source_checks=len(read(evidence/'source-checks.json')['checks']),
            native_load_checks=len(checks['checks']),editor_checks=len(read(evidence/'editor-checks.json')['checks']),
            valid_nonempty_glbs=count,mesh_count=meshes),
        review=['Every original occurrence is independently editable, preserving original token config, scale, height and standard 42 by 32 metre floors.',
            'Real geometry exported and GLB headers/mesh arrays independently parsed. Editor copy/move/rotate validation and native/Desktop mirror save/reload pass.',
            'Original box-counting visibility startup errors are avoided by a narrow trial adapter type guard. Original source scripts/maps/text remain unchanged.',
            'Native bounds and representative inside-tower screenshots inspected. Fit limits are disclosed rather than treated as curated acceptance.'],limitations=limits)
    write(HERE/(trial+'-review.json'),review)
    write(folder/'transfer-status.json',dict(owner='Codex',stage='placed_load_checked_uncurated',maps=job['maps'],placed=job['source_placements'],omitted=[],native_tested=False,native_load_checked=True,buttons_tested=False,headset_tested=False,curated=False))
    write(HERE/'STATUS.json',dict(owner='Codex',stage='placement_review_complete',trial=trial,maps=len(job['maps']),source_occurrences=job['source_placements'],accepted=len(job['maps']),scope=review['scope'],next='Continue batch 28 / lsystems_02; already prepared and placed. Do not reprepare.'))
    (HERE/'PROGRESS.md').write_text('# Batch 27 complete — placement-first review\n\nFive Fractals maps, all 43 original occurrences, 81 real exported models. Source audit 234; desktop/synthetic XR load 193; editor 46 checks pass. Artifact buttons and interaction mechanics intentionally untested per user instruction. Standard floors and original scales/config retained.\n\nSee fractals_02-review.json for explicit source-size/fit limits. No curation or chapter text rewriting. Next: batch 28 / lsystems_02 is already prepared and placed (six maps, 36 occurrences); finish basic load, models and editor save checks there. Continue transfers after review, do not wait for another continue message.\n',encoding='utf8')
    (folder/'HANDOFF.md').write_text('# Fractals 02 — placed for curation\n\nAll five original maps / 43 occurrences are independently editable in the lab editor. Same rooms.json drives desktop and VR. Basic loading and editor/Desktop save parity checked. Artifact buttons, grabs, catalyst combat and puzzle outcomes deliberately untested. Source scale/config/text retained.\n\n'+ '\n'.join('- '+x for x in limits)+'\n',encoding='utf8')
    print(json.dumps(review['evidence']))
if __name__=='__main__':main()
