"""Fresh-file, same-assistant ghost-student reconstruction; no production edits."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import datetime
import hashlib
import json
import re
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-08-wavefunctions-ghost-student'
ENGINE = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
PATTERN = r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```'
PROBES = ['cube', 'pendulum', 'surface', 'circle', 'neighbours', 'sound', 'bernini', 'cage', 'air_music', 'stairs', 'beats', 'synthesis']
NAMES = ['Cube', 'Pendulum', 'Sine Space', 'Unit Circle', 'Propagation', 'Effect Sound', 'Bernini', 'Cage', 'Air Music', 'Sky Stairs', 'Beats', 'Synthesis']
PREDICTIONS = [
    'Amplitude .25, frequency .25, phase PI/2: start at 1.55 m; bottom 1.05 m at 2 s; period 4 s.',
    'Sample every .1 s with 20 slots: after 8 s about 1.9 s retained; swing unchanged. Halving trail speed halves drawn depth, not stored positions.',
    'Separate spatial frequencies: X=.5 and Z=1. At (.5,.25), height=.98; at (0,.25), .8. X repeats over 2 m, Z over 1 m. Still 289 positions and 512 faces.',
    'Radius .6, centre (-.4,1.6,0), angular speed PI: top (-.4,2.2,0) at .5 s. Circle period 2 s; graph axis stays 4 m.',
    'Seven points; initial centre .3 m. At dt=1/60, centre velocity=-.14 and displacement=.2976667; adjacent displacement=.001, next neighbour zero. Reversing traversal with separate next arrays preserves results.',
    'Ratio 1.5: modulator 660 Hz. Zero-depth sample bytes unchanged from ratio 2; positive-depth bytes differ. Length and amplitude limits unchanged.',
    'Height 3.6, twelve corners: 206 positions and 408 faces. Half-height corner (0,2.05,-.4), top (-.4,3.85,0). Rotating the parent leaves stored positions intact.',
    'Both intervals .75: six times .75,1.5,2.25,3,3.75,4.5. Replay leaves voice choices and RNG state unchanged; late dispatch retains order.',
    'Both bars 392 Hz: same sample bytes, but separate starts. Touching bar 1 after bar 0 must not restart bar 0. Equal pitch is not shared age.',
    'Constant radius 2.5 and rise .15: eleven centres on the same circle, tops 0,.75,1.5 at indices 0,5,10; collider tops match. No claim that this proves player ascent.',
    'A=6 Hz; initial point Y=.95 selects B=5.75. Envelope period 4 s, cancellation after 2 s. Raw source sum and display gain stay distinct.',
    'Recipe [1,0,.5,0,0]: at PI/2 signed sum=.5. Half-cycle sign reverses. Removing H3 raises the sum to 1. Baseline restores recipe without restoring phase.'
]

def digest(data):
    return hashlib.sha256(data).hexdigest()

def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf8')

def edited(code, changes):
    for old, new in changes:
        assert old in code, old
        code = code.replace(old, new, 1)
    return code

def prepare():
    assert not (OUT/'manifest.json').exists(), 'Preserve the first packet and predictions; do not prepare twice.'
    maps = json.loads((ROOT/'commons/maps/sequences/wavefunctions.json').read_text())['sequences']['wavefunctions']['maps']
    archive = ROOT/'doc/book/iterations/2026-10-08-wavefunctions-reading-pass/wavefunctions-readings.zip'
    zip_contents = zipfile.ZipFile(archive)
    rows, protected = [], {}
    for i, map_id in enumerate(maps):
        source = ROOT/'commons/maps'/map_id/'tutorial.md'
        text = source.read_text(encoding='utf8')
        blocks = re.findall(PATTERN, text, re.S)
        assert blocks
        dest = OUT/'attempt'/map_id
        for name, code in blocks:
            write(dest/name, code+'\n')
        for kind in ['tutorial', 'final']:
            path = ROOT/'commons/maps'/map_id/(kind+'.md')
            raw = path.read_bytes()
            protected[path.relative_to(ROOT).as_posix()] = digest(raw)
            target = OUT/'packet'/map_id/(kind+'.md')
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(raw)
        archive_matches = []
        for name in zip_contents.namelist():
            if name.endswith('/'+map_id+'/tutorial.md'):
                archive_matches.append(zip_contents.read(name).decode('utf8').replace('\r\n','\n') == text)
        main = blocks[0][0]
        row = dict(map=map_id, title=NAMES[i], probe=PROBES[i], main=main,
                   files=[n for n,c in blocks], code_lines=sum(len(c.splitlines()) for n,c in blocks),
                   main_lines=len(blocks[0][1].splitlines()),
                   archive_matches=archive_matches, prediction=PREDICTIONS[i],
                   hashes={n:digest((c+'\n').encode()) for n,c in blocks})
        rows.append(row)
    # Companion versions demanded by existing teacher probes, reconstructed from the exercise edits.
    variants = {
        6: ('07_taller_shaft.gd', [('height := 2.4','height := 3.6'),('sides := 8','sides := 12')]),
        7: ('08_equal_intervals.gd', [('min_interval := 0.8','min_interval := 1.0'),('max_interval := 1.6','max_interval := 1.0')]),
        8: ('09_same_pitch.gd', [('[261.63, 392.0]','[261.63, 261.63]')]),
        9: ('10_constant_radius.gd', [('amplitude := 0.45','amplitude := 0.0')]),
        10: ('11_faster_pair.gd', [('frequency_a := 4.0','frequency_a := 5.0'),('Vector3(-2.1, 1.7, 0.5)','Vector3(-2.1, 1.45, 0.5)')]),
        11: ('12_odd_recipe.gd', [('[1.0, 0.5, 1.0 / 3.0, 0.25, 0.2]','[1.0, 0.0, 1.0 / 3.0, 0.0, 0.2]')]),
    }
    changes = [
        [('amplitude := 0.4','amplitude := 0.25'),('frequency := 0.5','frequency := 0.25'),('phase := 0.0','phase := PI / 2.0')],
        [('sample_interval := 0.025','sample_interval := 0.1'),('max_samples := 120','max_samples := 20'),('trail_speed := 0.6','trail_speed := 0.3')],
        [('sin(TAU * frequency * x)','sin(TAU * 0.5 * x)')],
        [('Vector3(0, 1.5, 0)','Vector3(-0.4, 1.6, 0)'),('radius := 1.0','radius := 0.6'),('angular_speed := PI / 2.0','angular_speed := PI')],
        [('count := 9','count := 7'),('displacement[count / 2] = 0.6','displacement[count / 2] = 0.3')],
        [('ratio := 2.0','ratio := 1.5')],
        variants[6][1],
        [('min_interval := 0.8','min_interval := 0.75'),('max_interval := 1.6','max_interval := 0.75')],
        [('[261.63, 392.0]','[392.0, 392.0]')],
        [('amplitude := 0.45','amplitude := 0.0'),('rise := 0.11','rise := 0.15')],
        [('frequency_a := 4.0','frequency_a := 6.0'),('Vector3(-2.1, 1.7, 0.5)','Vector3(-2.1, 0.95, 0.5)')],
        [('[1.0, 0.5, 1.0 / 3.0, 0.25, 0.2]','[1.0, 0.0, 0.5, 0.0, 0.0]')],
    ]
    for i,row in enumerate(rows):
        folder = OUT/'attempt'/row['map']
        code = (folder/row['main']).read_text()
        if i in variants:
            name, edits = variants[i]
            write(folder/name, edited(code, edits))
        write(folder/'transfer.gd', edited(code, changes[i]))
        row['edits'] = changes[i]
        row['transfer_hash'] = digest((folder/'transfer.gd').read_bytes())
    row = rows[4]
    folder = OUT/'attempt'/row['map']
    code = (folder/'transfer.gd').read_text()
    write(folder/'reverse.gd', code.replace('    for i in range(count):\n        var force', '    for i in range(count - 1, -1, -1):\n        var force'))
    instructions = '# Before execution\n\nSame-assistant reconstruction, not a blind reader or headset test. Only complete printed listings are extracted; no production lesson scripts are copied to fill gaps. Prepared museum, XR Tools, player/camera/light remain supplied prerequisites. Existing teacher probes are regressions, separately labelled. Predictions below precede this fresh run, but many mechanisms were already familiar to the author.\n\n'
    instructions += '\n\n'.join(f'## {i+1}. {r["title"]}\n\n{r["prediction"]}' for i,r in enumerate(rows))+'\n'
    write(OUT/'predictions-before.md', instructions)
    manifest = dict(created=datetime.datetime.now(datetime.timezone.utc).isoformat(), scope='same-assistant fresh-file reconstruction', archive_sha256=digest(archive.read_bytes()), predictions_sha256=digest(instructions.encode()), rows=rows, protected=protected)
    write(OUT/'manifest.json', json.dumps(manifest, indent=2))
    print('Prepared',len(rows),'halls;',sum(len(r['files']) for r in rows),'printed files; predictions recorded.')

def run_one(row):
    evidence = OUT/'evidence'/row['map']
    evidence.mkdir(parents=True, exist_ok=True)
    receipt=evidence/'teacher-checks.json'; log_path=evidence/'engine.log'
    assert not log_path.exists(), 'Keep first run; use a new run path for repairs.'
    lesson=OUT/'attempt'/row['map']/row['main']
    cmd=[ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script',f'res://tools/probes/wavefunctions_{row["probe"]}_student.gd','--','--lesson=res://'+lesson.relative_to(ROOT).as_posix(),'--report=res://'+receipt.relative_to(ROOT).as_posix()]
    with log_path.open('w',encoding='utf8') as log:
        try:
            proc=subprocess.run(cmd,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=70,creationflags=subprocess.CREATE_NO_WINDOW)
            status=proc.returncode
        except subprocess.TimeoutExpired:
            status='timeout'
    output=log_path.read_text(encoding='utf8',errors='replace')
    data=json.loads(receipt.read_text()) if receipt.exists() else {}
    result=dict(map=row['map'], exit_code=status, passed=status==0 and data.get('passed',False) and 'SCRIPT ERROR' not in output, checks=len(data.get('checks',[])), failures=data.get('failures',[]))
    print(json.dumps(result),flush=True)
    return result

def run():
    manifest=json.loads((OUT/'manifest.json').read_text())
    assert digest((OUT/'predictions-before.md').read_text(encoding='utf8').encode())==manifest['predictions_sha256']
    with ThreadPoolExecutor(max_workers=2) as pool:
        results=list(pool.map(run_one,manifest['rows']))
    write(OUT/'regression-results.json',json.dumps(results,indent=2))
    assert all(r['passed'] for r in results), 'See first-run logs; no silent repair.'

if __name__=='__main__':
    {'prepare':prepare,'run':run}[sys.argv[1]]()
