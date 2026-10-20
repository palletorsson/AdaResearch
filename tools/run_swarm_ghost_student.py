"""Reconstruct a fresh Swarm learner workspace from the supplied review ZIP.

No study sources or prebuilt lesson scenes are used for reconstruction. This is
an author-operated student rehearsal with prior context, not an independent AI.
"""
from pathlib import Path
from datetime import datetime, timezone
import argparse
import hashlib
import json
import re
import shutil
import subprocess
import zipfile

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-10-swarm-ghost-student'
PACK = R / 'doc/book/iterations/2026-10-10-swarm-complete-readings/swarm-review.zip'
ENGINE = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'


def sha(data): return hashlib.sha256(data).hexdigest()
def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(text.encode('utf8'))
def dump(path, data): write(path, json.dumps(data, indent=2, ensure_ascii=False) + '\n')
def now(): return datetime.now(timezone.utc).isoformat()


def prepare():
    assert not (O / 'input-manifest.json').exists(), 'Preserve the original rehearsal input.'
    O.mkdir(parents=True, exist_ok=True)
    rows = []
    with zipfile.ZipFile(PACK) as bundle:
        assert bundle.testzip() is None
        manifest = json.loads(bundle.read('manifest.json'))
        for entry in manifest:
            hall = entry['hall']
            dest = O / 'halls' / hall
            text = bundle.read(f'halls/{hall}/tutorial.md').decode('utf8')
            for kind in ['tutorial', 'final']:
                write(dest / (kind + '.md'), bundle.read(f'halls/{hall}/{kind}.md').decode('utf8'))
            # Named blocks only; no fallback to the author's implementation.
            blocks = re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```', text, re.S)
            assert len(blocks) == len(dict(blocks)) and len(blocks) in [3, 4]
            files, deps = {}, []
            for name, code in blocks:
                assert Path(name).name == name and '$' not in code
                data = code + '\n'
                write(dest / 'code' / name, data)
                files[name] = sha(data.encode())
                for dep in re.findall(r'(?:preload\(|load\(|extends )"([^"\n]+)"', code):
                    location = R / dep[6:] if dep.startswith('res://') else dest / 'code' / dep
                    deps.append({'name': dep, 'prepared_museum_dependency': dep.startswith('res://'), 'exists': location.exists() or dep in dict(blocks)})
            assert all(d['exists'] for d in deps), deps
            # Exactly the Node3D-and-attached-script instruction in the text.
            scene = '[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="study.gd" id="1"]\n\n[node name="StudentStudy" type="Node3D"]\nscript = ExtResource("1")\n'
            write(dest / 'code/study.tscn', scene)
            rows.append({'hall': hall, 'tutorial_sha256': sha(text.encode()), 'canonical_tutorial_sha256': sha((R/'commons/maps'/hall/'tutorial.md').read_bytes()), 'canonical_final_sha256': sha((R/'commons/maps'/hall/'final.md').read_bytes()), 'printed_files': files, 'dependencies': deps})
        for name in ['README.md', 'OPEN-STUDY.md', 'ROUTE.md']:
            write(O / 'reading' / name, bundle.read(name).decode('utf8'))
    assert len(rows) == 7 and sum(len(r['printed_files']) for r in rows) == 22
    assert len({r['printed_files']['point_body.gd'] for r in rows}) == 1
    pso = O / 'halls/SwarmIntelligence_Particle_Swarm_Optimization/code'
    for seed in [101006, 101007]:
        for pull in [1.5, 0.3]:
            dest = O / 'investigation' / f'seed-{seed}-pull-{pull}'
            for path in pso.glob('*.gd'):
                code = path.read_text(encoding='utf8')
                if path.name == 'swarm.gd':
                    assert code.count('var social_pull := 1.5') == 1 and code.count('random.seed = 101006') == 1
                    code = code.replace('var social_pull := 1.5', f'var social_pull := {pull}').replace('random.seed = 101006', f'random.seed = {seed}')
                write(dest / path.name, code)
    protected = {str(p.relative_to(R).as_posix()):sha(p.read_bytes()) for p in [R/'commons/maps/sequences/swarmintelligence.json', R/'doc/book/course/execution-plan/plan.json']}
    dump(O / 'input-manifest.json', {'prepared_at':now(), 'zip_sha256':sha(PACK.read_bytes()), 'source':'Printed named blocks inside the supplied review ZIP; prepared museum dependencies remain available.', 'scope':'Author-operated ghost student with prior context. No independent-reader or headset claim.', 'halls':rows, 'printed_files':22, 'same_pointbody':True, 'protected':protected})
    write(O / 'PREDICTIONS.md', '''# Ghost student — predictions before running

Read all seven tutorial/final pairs in spine order. Reconstruct the 22 named printed scripts from the reviewer ZIP, not the author's studies or existing tscn files. Use the prepared museum's declared XRTools, buttons and ecosystem. Keep canonical lesson text, world code and plan unchanged during this assessment.

1. Physarum: an abandoned mark of strength 2, with retention changed to 0.8, should be 1.28 after two ticks. The field can retain evidence after its agent is removed.
2. Flow → Boids: from velocity (1,0), an explicit zero direction brakes to (0.9,0) in one tick; no Boids neighbours means coast at (1,0). Shared integration does not make missing information mean the same thing.
3. Boids: two neighbours moving at (0,2) and (0,-2) request braking through their zero average; removing both means no request. Neighbour radius is strict: a point exactly radius units away is excluded.
4. ABM: returning at (8,8), velocity zero, speed 2 yields velocity (-0.2,0) and position (7.99,8). This return ignores a strong side trace. Replacing agents preserves that field, while resetting clears it.
5. ABM → Ant Colony: a returning colony point follows home samples instead of the known home coordinate. Put one stronger home sample to its side and expect a turn toward that sample. Toggling its carrying flag chooses the other channel. A deposit changes only the corresponding outgoing channel.
6. PSO: after changing to RIDGE, old best records must be rescored at current positions. Scores at (-2,-2) and (3,3) tie at zero. A zero shared pull removes one contribution without erasing personal memory.
7. Account: starting at 8 prey, then birth 3, loss 2 and supply 4 gives 13; hiding supply predicts 9 and exposes gap 4. Altering a caller's dictionary later must not rewrite the copied event. Food support cannot count as a creature.

Instantiate each complete host in the prepared project, with a translated and rotated unscaled Node3D. Verify pause/grab/release/coordinate conversion without treating the synthetic pointer as a physical headset test. First four hosts are temporary studies, not existing permanent exhibits.

## Open RIDGE investigation

Hypothesis, not a pass condition: reducing social_pull from 1.5 to 0.3 will leave a wider current population at step100, potentially with worse current scores. Compare steps0/20/100, seeds101006 and101007; restart and repeat both settings. Measure largest pairwise distance, current scores of points0/1/2, mean current score and shared best. Preserve contrary results. Render the four step100 states from the same camera in the existing PSO museum hall if possible. Do not assert that weaker pull must increase spread.

## Reading friction to check

Boids asks for one step but its printed room controls offer continuous RUN, not ONE STEP. Distinguish a model-level step from a button that does not exist. Physarum asks for a sensor value of exactly1 after depositing, but the recipe begins with Pause rather than Reset: an earlier mark would change that value. Both may be instruction gaps even if code checks pass.
''')
    print('Prepared 22 printed scripts, seven minimal scenes and four RIDGE variants from the review ZIP.', flush=True)


def run():
    inputs = json.loads((O/'input-manifest.json').read_text(encoding='utf8'))
    evidence = O / 'transfer-checks.json'
    if evidence.exists():
        shutil.copy2(evidence, O / ('transfer-checks-' + datetime.now().strftime('%H%M%S') + '.json'))
        evidence.unlink()
    args = [ENGINE, '--headless', '--path', str(R), '--xr-mode', 'off', '--script', 'res://tools/probes/swarm_ghost_transfer.gd', '--', '--no-bridges']
    with (O/'engine.log').open('w', encoding='utf8') as log:
        result = subprocess.run(args, cwd=R, stdout=log, stderr=subprocess.STDOUT, timeout=120, creationflags=subprocess.CREATE_NO_WINDOW)
    log = (O/'engine.log').read_text(encoding='utf8', errors='replace')
    print('\n'.join(log.splitlines()[-18:]), flush=True)
    assert result.returncode == 0 and evidence.exists(), 'Ghost probe failed; inspect engine.log'
    assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log
    receipt = json.loads(evidence.read_text(encoding='utf8'))
    assert receipt['completed'] and receipt['passed'] and not receipt['failures']
    assert len(receipt['host_halls']) == 7
    text_revisions=[]
    for row in inputs['halls']:
        for name,digest in row['printed_files'].items():
            assert sha((O/'halls'/row['hall']/'code'/name).read_bytes())==digest
        final=R/'commons/maps'/row['hall']/'final.md'
        assert sha(final.read_bytes())==row['canonical_final_sha256']
        tutorial=R/'commons/maps'/row['hall']/'tutorial.md'
        blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',tutorial.read_text(encoding='utf8'),re.S)
        assert {name:sha((code+'\n').encode()) for name,code in blocks}==row['printed_files']
        if sha(tutorial.read_bytes())!=row['canonical_tutorial_sha256']:
            text_revisions.append({'hall':row['hall'],'before':row['canonical_tutorial_sha256'],'after':sha(tutorial.read_bytes()),'printed_code_unchanged':True})
    for path,digest in inputs['protected'].items(): assert sha((R/path).read_bytes())==digest
    receipt.update(finished_at=now(), printed_files=22, input_manifest_sha256=sha((O/'input-manifest.json').read_bytes()), predictions_sha256=sha((O/'PREDICTIONS.md').read_bytes()), probe_sha256=sha((R/'tools/probes/swarm_ghost_transfer.gd').read_bytes()), canonical_texts_unchanged=not text_revisions, canonical_code_and_reflections_unchanged=True, text_revisions=text_revisions)
    dump(evidence,receipt)
    print(f'{len(receipt["checks"])} new transfer/host/reproducibility assertions passed.', flush=True)


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--prepare',action='store_true')
    args=parser.parse_args()
    prepare() if args.prepare else run()
