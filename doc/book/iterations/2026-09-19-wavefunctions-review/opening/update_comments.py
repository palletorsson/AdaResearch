from pathlib import Path
import hashlib, json, difflib

ROOT = Path(__file__).resolve().parents[5]
OUT = Path(__file__).resolve().parent
changes = {
    'commons/artifacts/control_pendulum/control_pendulum.gd': [
        ('# Swing harder = faster oscillation. Higher amplitude = bigger movements.',
         '# The release supplies angle and tangent speed; wider swings need not have a shorter period.'),
        ('# critical_parameter: pendulum_length — determines the natural frequency via sqrt(g/L)',
         '# critical_parameter: pendulum_length — with gravity fixed, sqrt(g/L) gives the small-angle natural frequency'),
        ('# emerges: harmonic motion from the simplest possible setup — mass, string, gravity',
         '# emerges: a returning swing from an integrated nonlinear restoring rule, with damping and optional drive'),
        ("# truth: A pendulum is gravity's metronome — length alone determines the tempo.",
         '# truth: In the small-angle undamped approximation, length and gravity set the period; this simulated swing also has amplitude, damping and optional drive.'),
    ],
    'algorithms/wavefunctions/unit_circle/UnitCircle.gd': [
        ('# desire: Watch a point trace the unit circle while sine and cosine waves build incrementally',
         '# desire: Follow both coordinate projections of a turning point while the selected graph builds incrementally'),
        ('# emerges: visual proof that sine and cosine are born from circular motion',
         '# emerges: sine and cosine as coordinate projections of uniform angular progression'),
        ('#   drawn and walked. "both" is the shipped figure — the vertical sine rod, the',
         '#   drawn. Collision boxes accompany the sampled bridge, but do not establish a traversable route.\n#   "both" is the shipped figure — the vertical sine rod, the'),
    ],
    'algorithms/wavefunctions/sine_wall/SineWallCorridor.gd': [
        ('# desire: feel the body inside the wave — left and right walls phasing against each other across 24m',
         '# desire: compare moving and frozen folds in a passage; the shipped scene is 7 m long with wall collision off'),
        ('# triggers: _ready() rebuilds wall meshes on parameter change; animate_at_runtime tweens the phase across animation_speed',
         '# triggers: controls rebuild wall meshes; animate_at_runtime advances phase by animation_speed * delta and rebuilds the walls'),
    ],
}

def sha(data): return hashlib.sha256(data).hexdigest()
def code(text): return '\n'.join(line for line in text.splitlines() if line.strip() and not line.lstrip().startswith('#'))

records = []
for rel, replacements in changes.items():
    path = ROOT / rel
    saved = OUT / 'before-source' / rel
    if saved.exists():
        old = saved.read_bytes()
    else:
        old = path.read_bytes()
        saved.parent.mkdir(parents=True, exist_ok=True)
        saved.write_bytes(old)
    before = old.decode('utf-8')
    after = before
    for search, replace in replacements:
        assert after.count(search) == 1, (rel, search)
        after = after.replace(search, replace.replace('\n', '\r\n') if '\r\n' in before else replace)
    assert code(before) == code(after), rel
    assert path.read_bytes() in (old, after.encode('utf-8')), f'Concurrent source edit: {rel}'
    path.write_bytes(after.encode('utf-8'))
    records.append({'path': rel, 'before_sha256': sha(old), 'after_sha256': sha(path.read_bytes()),
                    'executable_lines_unchanged': True,
                    'diff': ''.join(difflib.unified_diff(before.splitlines(True), after.splitlines(True),
                                                       fromfile='before/'+rel, tofile=rel))})
(OUT / 'source-changes.json').write_text(json.dumps(records, indent=2), encoding='utf-8')
(OUT / 'before-sha256.json').write_text(json.dumps({r['path']: r['before_sha256'] for r in records}, indent=2), encoding='utf-8')
(OUT / 'source-changes.diff').write_text(''.join(r['diff'] for r in records), encoding='utf-8')
print(json.dumps({'files': len(records), 'executable_lines_unchanged': all(r['executable_lines_unchanged'] for r in records)}))
