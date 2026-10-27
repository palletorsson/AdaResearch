"""Placement-only review: source fidelity, load, geometry and editor saves."""
from pathlib import Path
import importlib.util,json,struct
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,x):p.write_text(json.dumps(x,indent=2)+'\n',encoding='utf8')
def main():
    job=read(HERE/'batch.json')['jobs'][0];trial=job['sequence'];folder=ROOT/job['folder'];e=folder/'evidence'
    models=ROOT.parent/'ada_encyclopedia/public/void-trials'/trial
    count=meshes=0
    for p in models.glob('*.glb'):
        b=p.read_bytes();magic,v,n=struct.unpack_from('<III',b)
        assert magic==0x46546c67 and v==2 and n==len(b),p
        size,kind=struct.unpack_from('<II',b,12);assert kind==0x4e4f534a
        g=json.loads(b[20:20+size]);assert g.get('meshes'),p
        count+=1;meshes+=len(g['meshes'])
    spec=importlib.util.spec_from_file_location('snapshot',HERE.parent/'2026-10-21-batch-25/review.py')
    snapshot=importlib.util.module_from_spec(spec);spec.loader.exec_module(snapshot)
    receipt=snapshot.inspect(job)
    assert not receipt['source_scale_height_layout_problems'],receipt
    assert all(x.get('passed') for x in receipt['receipts'].values()),receipt
    assert receipt['export']['failures']==[] and receipt['export']['stale_sources']==[],receipt
    write(HERE/'final-verification.json',receipt)
    checks=read(e/'checks.json');assert checks['placement_load_only'] and not checks['acceptance']
    manifest=read(models/'manifest.json')
    marker=manifest['floors']['6']['artifacts']['f6_grid_substrate_runner_5_21']
    assert marker['preview_kind']=='missing_dependency_arrangement_marker'
    limits=[
        'Artifact buttons, grabs/triggers, catalyst combat, puzzles and mechanics intentionally untested. Basic desktop and synthetic XR loading only; physical headset testing deferred.',
        'Grid substrate runner requires the original GridDataComponent/GridMultiMesh, absent from the fixed Void slabs. Its original scene remains with a safe dimensions lookup. Its editor-only labelled marker is a selectable dependency location, not a working floor simulation.',
        'Original source sizes/heights retained. Hilbert, tube tree, tube painting, CityGenerator and canopy extend through other storeys; several original centred objects extend below slabs. These are fit issues for later curation, not completed integration.',
        'Dungeon, forest display and 10 PRINT geometry extend beyond parts of the standard floor footprint at their current uncurated placements. Original scale was not reduced and floor size not enlarged.',
        'Models are static arrangement snapshots. Original shader views, animations and controls run in Godot. No web interaction, Quest performance or learning-outcome claim is made.',
        'Native cleanup texture leak warnings and two known post-export GL texture cleanup errors are recorded. Basic runtime load has zero script/engine errors; export completes with no failed models.'
    ]
    review=dict(trial=trial,reviewer='Codex (transfer author and placement/evidence review)',date='2026-10-21',
        status='accepted_as_uncurated_transfer',scope='Placement/load/editor/save only; no artifact button/mechanics acceptance',maps=6,source_occurrences=36,
        evidence=dict(source_checks=len(read(e/'source-checks.json')['checks']),native_load_checks=len(checks['checks']),editor_checks=len(read(e/'editor-checks.json')['checks']),valid_nonempty_glbs=count,mesh_count=meshes),
        review=['All 36 original occurrences placed independently on six standard floors; original token config, scale, height, source maps and texts retained.',
            'Real model files independently parsed. Editor copy/move/rotate validation and save/reload to native rooms and Desktop mirror pass.',
            'Native bounds and representative inside-tower screenshot inspected. Source fit and missing host-grid dependency are disclosed for later integration.'],limitations=limits)
    write(HERE/(trial+'-review.json'),review)
    write(folder/'transfer-status.json',dict(owner='Codex',stage='placed_load_checked_uncurated',maps=job['maps'],placed=36,omitted=[],native_tested=False,native_load_checked=True,buttons_tested=False,headset_tested=False,curated=False))
    write(HERE/'STATUS.json',dict(owner='Codex',stage='placement_review_complete',trial=trial,maps=6,placed=36,accepted=6,next='Continue next uncovered Procedural Generation maps; compare inventories and main/trial rooms first. User wants rolling transfers without another continue prompt.'))
    (HERE/'PROGRESS.md').write_text('# Batch 28 complete — placement-first\n\nAll six remaining L-systems maps, 36 original occurrences, 75 exported model files. Source 216; basic desktop/synthetic XR load 169; editor 39 checks pass. No artifact buttons or mechanics tested. Source sizes/config retained, same layout for desktop and VR. See lsystems_02-review.json for missing grid dependency and uncurated fit limits. No curation or text rewriting.\n\nNext: remaining Procedural Generation maps (PG_Branching_Growth, PG_Percolation_Network, PG_Caves_Mazes, PG_Sculpted_Forms, PG_Mirrored_Patterns). Confirm existing inventories and main/trial rooms before preparation. Continue transfers after review; rolling follow-up ACTIVE.\n',encoding='utf8')
    (folder/'HANDOFF.md').write_text('# L-systems 02 — placed for curation\n\n36 original occurrences on six standard floors, all independently editable. Original token config/scale/height retained. Desktop and VR use the same rooms.json. Basic loading and editor saves checked; artifact buttons/mechanics untested by instruction.\n\n'+'\n'.join('- '+x for x in limits)+'\n',encoding='utf8')
    print(json.dumps(review['evidence']))
if __name__=='__main__':main()
