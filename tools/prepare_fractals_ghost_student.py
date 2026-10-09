"""Freeze the readings supplied to a fresh ghost student; exclude teacher results."""
from pathlib import Path
import hashlib
import json
import shutil

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-08-fractals-ghost-student'
P = O / 'packet'
assert not P.exists(), 'Keep the original packet; use a new directory for another trial.'
P.mkdir(parents=True)
(O / 'attempt').mkdir()
full = R / 'doc/book/iterations/2026-10-08-fractals-complete-readings'
for source, name in [('fractals-tutorial.md', 'tutorial.md'), ('fractals-final.md', 'final.md')]:
    shutil.copy2(full / source, P / name)
shutil.copytree(full / 'assets', P / 'assets')
prerequisites = ['Point_Zero', 'Point_One', 'Point_Coordinates', 'Point_Lines', 'Point_Trace', 'Noise_Columns', 'WaveFunctions_Intro']
(P / 'prerequisites').mkdir()
canonical = {}
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
order = json.loads((R / 'commons/maps/sequences/fractals.json').read_text(encoding='utf-8'))['sequences']['fractals']['maps']
for hall in order:
    for track in ['tutorial', 'final']:
        p = R / 'commons/maps' / hall / (track + '.md')
        canonical[p.relative_to(R).as_posix()] = sha(p)
for hall in prerequisites:
    source = R / 'commons/maps' / hall / 'tutorial.md'
    shutil.copy2(source, P / 'prerequisites' / (hall + '.md'))
    canonical[source.relative_to(R).as_posix()] = sha(source)
(O / 'canonical-before.json').write_text(json.dumps(canonical, indent=2) + '\n', encoding='utf-8')
(P / 'README.md').write_text('''# Fractals: ghost-student reading packet

Read tutorial.md and final.md in the seven-hall order printed there. They are the current complete readings, including the complete required learner scripts. assets/ contains their figures. prerequisites/ contains frozen earlier tutorial readings you may consult: the point/line/trace lineage, Noise Columns and the Waves opening. Those are source lessons, not teacher solutions for this task.

Assumed environment: the existing Endless Museum Godot 4.6 project, with camera, lights, player and XRTools already installed. The student studies run as described in each tutorial. You may assume prior programming subjects in the earlier curriculum, but name any knowledge you use that the packet does not explain. These pages have not been supplemented with missing explanations for this trial.

You are the imagined future student reading for the pleasure and difficulty of making. Assess the writing honestly. Distinguish the tutorial's construction from the reflective text's wider museum encounter. Do not role-play that you physically visited a room or wore a headset.

First submission: read both tracks; extract all sixteen marked student-code files into per-hall folders in ../attempt/reconstructed/. Reproduce them verbatim. Record pre-execution predictions for the required Synthesis variation, then implement it as a separate file. Choose and implement one response to Synthesis's optional composition task using the declared earlier material. Keep your original. Record its input, receiver, expected invariants, predicted change and reason for choosing it before seeing runtime results. Include a README naming the entry scripts and their adjustable properties so the evaluator can run them. You may author a small native assertion probe for your predictions, but do not run Godot yet.

Write ../attempt/review-before.md: one short assessment per hall, what accumulates, what must be guessed, the relationship between the two texts, where you felt agency and where instructions constrain you. Point to specific passages. Distinguish absent teaching from useful prior knowledge and optional depth. Give a few ranked improvements, not a rewrite. Write ../attempt/reading-log.md listing the packet files you actually read and the outside knowledge used.

Read only this packet and your own output files during the first submission. Do not read other repository files, teacher probes, existing study files, reports, reviews, solutions or conversation history. Do not browse. Do not edit the packet, canonical manuscripts or museum code. Work only in ../attempt/. Tell the parent when the first submission is ready. Runtime results will be returned later for a separate after-run account.
''', encoding='utf-8')
manifest = {p.relative_to(P).as_posix(): sha(p) for p in P.rglob('*') if p.is_file()}
(O / 'packet-sha256.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'packet': str(P), 'files': len(manifest), 'canonical_readings_frozen': len(canonical)}))
