"""Fresh printed-file reconstruction and prediction-led student transfer checks.

This is an author-informed learner simulation, not an independent human trial.
Never imports the production artifact as the transfer-test oracle.
"""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import hashlib, json, re, shutil, subprocess
from student_lesson_sources import lesson_files

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-09-randomness-ghost-student'
ENGINE = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
PROBES = ['random_definition','random_entropy','random_remove','ten_print','random_cubes','random_rotate','random_walk','random_gaussian','random_mushrooms','random_geometry','random_examples','random_pheromone','random_space','random_game']
# Exact changes chosen before executing either version. The printed program
# stays intact; the edited copy is a student's separate experiment.
EDITS = [
 [('01_seed_picture.gd','Color(a, b, c)','Color(c, b, a)')],
 [('02_counts_and_neighbours.gd','record.append(rng.randi_range(0, palette.size() - 1))','record.append(int(i / 4))')],
 [('03_eligible_addresses.gd','return column >= 2 and column <= 5 and row >= 2 and row <= 5','return column == row')],
 [('04_two_diagonals.gd','probability := 0.5','probability := 0.375')],
 [('05_a_continuing_die.gd','return face == 6','return face % 2 == 0')],
 [('06_turns_kept.gd','for i in range(step_count):\n        turns.append(deg_to_rad(rng.randf_range(-limit_degrees, limit_degrees)))','turns.assign([deg_to_rad(12.0), deg_to_rad(-4.0), deg_to_rad(-8.0)])')],
 [('07_a_point_keeps_steps.gd','step_size := 0.12','step_size := 0.06')],
 [('08_values_and_bins.gd','var bin_count := 10','var bin_count := 6')],
 [('09_a_population_kept.gd','var count := 12','var count := 7'),('09_a_population_kept.gd','size_low := 0.7','size_low := 0.4'),('09_a_population_kept.gd','size_high := 1.3','size_high := 1.6')],
 [('10_neighbours_share.gd','cell_gap := 0.16','cell_gap := 0.20')],
 [('11_a_draw_estimates.gd','const BATCH := 16','const BATCH := 7')],
 [('12_a_visit_guides.gd','guidance := 0.4','guidance := 0.0')],
 [('13_fields_add.gd','layer_count := 1','layer_count := 3'),('13_fields_add.gd','persistence := 0.5','persistence := 0.0')],
 [('wait_cycle.gd','notice_ms := 1200','notice_ms := 300')],
]
PREDICTIONS = [
 'Swapping red/blue keeps every green channel, grid address and final RNG state. It changes interpretation, not requests.',
 'Four blocks of four symbols give counts [4,4,4,4], H=2 and three unlike neighbours. The cyclic arrangement has the same counts/H but fifteen unlike neighbours.',
 'Only eight diagonal addresses 0,9,18,27,36,45,54,63 are eligible. All appear exactly once; ninth removal returns -1 without spending a draw.',
 'At threshold .375 the expected count is24, not a promise. Samples and RNG match .5; no old slash can become a backslash when the threshold falls.',
 'With even faces continuing, [2,4,3] totals9 then closes; the original closes after2. A continuing chain reaching the display cap is limited, not closed by an odd face.',
 'The supplied +12,-4,-8 degree record has final latest=-8 and total=0. Replay rewinds the cursor; it does not draw. Assignment differs from accumulation.',
 'From the centre, halving step size halves the first four displacements before any boundary encounter. Editing an old trace entry cannot steer the next move. Held time spends no draw.',
 'Raw [-.2,0,.05,.49,.5,.99,1,1.3] maps to six bins [3,0,1,1,0,3], with two clipped values. Rebinning preserves all eight raw values and RNG state.',
 'Seven members keep the first seven kinds/yaws/positions. Wider .4..1.6 scale doubles each old deviation from1. SIZE changes expression without redrawing the record.',
 'Increasing displayed spacing changes column positions but neither record nor RNG nor neighbour-gap readings. Checkerboard gap=1; a half-plane split gives1/14.',
 'Seven-at-a-time and individual requests produce identical samples and every intermediate estimate after256 values. An over-budget request spends no draw. Numerical closeness to pi is not a pass condition.',
 'With guidance0, corrupting scent cannot change future path or RNG. Visits still accumulate. With guidance1, equal empty neighbours choose east first; the next attraction returns to deposited scent.',
 'Three layers with persistence0 preserve three parts, but parts2/3 contribute zero, so raw equals one layer. Changing lacunarity cannot change that zero-weight sum. No new draws.',
 'Shorter notice preserves every deadline, state, height, collider-support decision and RNG state. At600ms before first sinking, old cue is on and new cue off; at300ms both on.',
]

def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def res(path): return 'res://' + path.relative_to(ROOT).as_posix()

def prepare():
    maps=json.loads((ROOT/'commons/maps/sequences/randomness.json').read_text(encoding='utf-8-sig'))['sequences']['randomness']['maps']
    assert len(maps)==len(EDITS)==14
    OUT.mkdir(parents=True,exist_ok=True)
    manifest=[]
    for i,m in enumerate(maps):
        source=ROOT/'commons/maps'/m/'tutorial.md'
        text=source.read_text(encoding='utf-8-sig')
        matches=re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',text,re.S)
        assert matches and len(matches)==len(dict(matches)),m
        blocks=lesson_files(source)
        for track in ['tutorial','final']:
            src=source.with_name(track+'.md');dest=OUT/'before'/m/src.name
            dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dest)
        for version in ['printed','changed']:
            dest=OUT/'learner'/m/version;dest.mkdir(parents=True,exist_ok=True)
            for name,code in blocks.items():
                if version=='changed':
                    for file,old,new in EDITS[i]:
                        if file==name:
                            assert code.count(old)==1,(m,name,old)
                            code=code.replace(old,new)
                (dest/name).write_text(code+'\n',encoding='utf-8')
        entry=next(n for n in blocks if re.match(r'\d\d_',n))
        manifest.append({'map':m,'index':i,'entry':entry,'source_sha256':sha(source),'files':{n:sha(OUT/'learner'/m/'printed'/n) for n in blocks},'edits':EDITS[i],'prediction':PREDICTIONS[i]})
    (OUT/'predictions.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    return manifest

def run_one(row,kind):
    folder=OUT/'tests';folder.mkdir(exist_ok=True)
    receipt=folder/(row['map']+'-'+row.get('tag',kind)+'.json')
    if receipt.exists(): receipt.unlink()
    printed=OUT/'learner'/row['map']/'printed'/row['entry']
    changed=Path(row.get('changed',OUT/'learner'/row['map']/'changed'/row['entry']))
    probe='tools/probes/'+PROBES[row['index']]+'_student.gd' if kind=='baseline' else 'tools/probes/randomness_ghost_transfer.gd'
    args=[ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://'+probe,'--','--lesson='+res(printed),'--report='+res(receipt)]
    if kind=='transfer':args+=['--changed='+res(changed),'--hall='+str(row['index'])]
    with receipt.with_suffix('.log').open('w',encoding='utf-8') as log:
        r=subprocess.run(args,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
    log=receipt.with_suffix('.log').read_text(encoding='utf-8')
    data=json.loads(receipt.read_text(encoding='utf-8')) if receipt.exists() else {}
    passed=r.returncode==0 and data.get('passed') is True and 'SCRIPT ERROR' not in log and 'Parse Error' not in log
    return {'map':row['map'],'kind':kind,'passed':passed,'exit':r.returncode,'checks':len(data.get('checks',[])),'failures':data.get('failures',[]),'log':receipt.with_suffix('.log').relative_to(OUT).as_posix(),'receipt':receipt.relative_to(OUT).as_posix(),'diagnostics':[line for line in log.splitlines() if line.startswith(('ERROR:','WARNING:','SCRIPT ERROR:'))]}

def main():
    rows=prepare();results=[]
    with ThreadPoolExecutor(max_workers=2) as pool:
        futures=[pool.submit(run_one,r,k) for r in rows for k in ['baseline','transfer']]
        for future in as_completed(futures):
            r=future.result();results.append(r);print(r['map'],r['kind'],r['checks'],'PASS' if r['passed'] else 'FAIL',flush=True)
    results.sort(key=lambda r:([m['map'] for m in rows].index(r['map']),r['kind']))
    (OUT/'tests.json').write_text(json.dumps({'author_informed':True,'results':results,'all_passed':all(r['passed'] for r in results),'checks':sum(r['checks'] for r in results)},indent=2)+'\n',encoding='utf-8')
    assert all(r['passed'] for r in results),'Read retained logs and receipts.'

if __name__=='__main__':main()
