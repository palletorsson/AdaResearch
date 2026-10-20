from pathlib import Path
import hashlib
import html
import json
import shutil
import zipfile
import markdown

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
RUN = ROOT / 'ada_run/encounter_pilot/Random_Entropy/ghost-head-camera'
native = json.loads((HERE / 'verification.json').read_text())
hall = json.loads((RUN / 'report.json').read_text())
regression = json.loads((HERE / 'rehearsal-regression/verification.json').read_text())
assert not native['failures'] and hall['passed'] and not regression['failures']
assert json.loads((HERE / 'runner.json').read_text())['exit_code'] == 0
assert json.loads((HERE / 'rehearsal-regression/runner.json').read_text())['exit_code'] == 0
shutil.copy2(RUN / 'report.json', HERE / 'museum-report.json')
shutil.copy2(RUN / 'source_manifest.json', HERE / 'hall-source-manifest.json')
(HERE / 'hall').mkdir(exist_ok=True)
for pair in hall['observations']['ghost']['observations']:
    assert pair['status'] == 'saved' and pair['same_process_frame']
    source = Path(pair['folder'].replace('user://', str(Path.home() / 'AppData/Roaming/Godot/app_userdata/Ada Research Zero One') + '/'))
    for entry in pair['files'].values():
        assert hashlib.sha256((source / entry['name']).read_bytes()).hexdigest() == entry['sha256']
        shutil.copy2(source / entry['name'], HERE / 'hall' / entry['name'])
    shutil.copy2(source / (pair['label'] + '.json'), HERE / 'hall' / (pair['label'] + '.json'))
sources = [
    'commons/ghost_students/hologram.gd', 'commons/ghost_students/observation_rig.gd',
    'commons/artifacts/prefab_disorder/ghost_student.gd', 'commons/artifacts/prefab_disorder/preview.gd',
    'commons/artifacts/prefab_disorder/prefab_disorder.gd', 'commons/artifacts/prefab_disorder/disorder_sample.gd',
    'commons/artifacts/prefab_disorder/seeded_grafts.gd', 'commons/artifacts/prefab_disorder/hybrid_recipe.gd',
    'commons/maps/Random_Entropy/tutorial.md', 'commons/maps/Random_Entropy/final.md',
]
(HERE / 'manifest.json').write_text(json.dumps({p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in sources}, indent=2) + '\n')
STYLE = '''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#101b24;color:#e1ece9;font:17px/1.55 system-ui,sans-serif}main{max-width:1800px;margin:auto;padding:26px 32px}h1{font:clamp(30px,4vw,54px)/1.15 Georgia,serif;margin:8px 0 18px}h2{font:30px/1.2 Georgia,serif;margin:0 0 12px}p{max-width:90ch}small{color:#a1ced1}a{color:#91e1e2;text-underline-offset:4px}nav{display:flex;gap:22px;flex-wrap:wrap;margin:18px 0}.grid{display:grid;grid-template-columns:1fr 1fr;gap:18px}figure{margin:0;background:#1b303b;min-width:0}img{display:block;width:100%;height:auto}figcaption{padding:12px 16px}section{margin:36px 0 52px;scroll-margin-top:20px}.bar{border-top:1px solid #42616b;padding-top:20px}.meta{font:14px/1.6 ui-monospace,monospace;color:#b7d2d5}.intro{color:#c6d9d7;max-width:90ch}.question{border-left:3px solid #e4b66c;padding:8px 16px}.tag{color:#f0c77d}code{font-size:.92em}pre{overflow:auto}footer{border-top:1px solid #42616b;padding-top:16px}li{margin:10px 0}@media(max-width:820px){main{padding:18px}.grid{grid-template-columns:1fr}}'''
LABELS = {
    '01-before-touch': ('Before touch', 'The hand approaches ORIGINAL. The eye view looks down at the control; the outside view locates that reach in the whole apparatus.', 'Can the intended control be distinguished before the hand arrives?'),
    '02-separated': ('Separated parts', 'Both tables are at the midpoint: whole objects scatter on the left; their parts separate on the right. The head has turned toward the right-hand table.', 'Does this gaze make the difference between moving an object and separating it available?'),
    '03-another-seed': ('Another seed, new hybrids', 'Seed 436 replaces 435 at the hybrid endpoint. Memberships and joining targets change; the same fifty parts remain.', 'Is a recognisable part visible long enough to follow it into another form?'),
    '04-replayed': ('The kept form returns', 'REPLAY restores the kept intermediate arrangement at stage 0.82 with seed 436. Its geometry hash matches KEEP, including the stored targets and current part transforms.', 'What can the image establish about return—and what needs the saved state?'),
}

def page(pairs, directory, title, alternate):
    blocks = []
    for pair in pairs:
        label = pair['label']
        name, note, question = LABELS[label]
        p = pair['head']['bench'][-3:]
        state = pair['artifact_state']
        figures = ''
        for index, channel in enumerate(['eyes', 'outside']):
            image = f"{directory}/{pair['files'][channel]['name']}"
            caption = "GHOST'S EYES · actual head pose" if channel == 'eyes' else 'OUTSIDE · the same rendered frame'
            figures += f'<figure><a href="{image}" aria-label="Open full {channel} image"><img src="{image}" alt="{html.escape(name)} viewed through {channel} camera" loading="lazy"></a><figcaption>{caption} · {pair["cameras"][index]["vertical_fov_degrees"]:g}° vertical field of view</figcaption></figure>'
        blocks.append(f'''<section id="{label}" class="bar"><small class="tag">{pairs.index(pair)+1:02d} / {title}</small><h2>{name}</h2><p>{note}</p><div class="grid">{figures}</div><p class="meta">Seed {state['seed']} · stage {state['disorder']:.2f} · head relative to bench ({p[0]:.3f}, {p[1]:.3f}, {p[2]:.3f}) m · frame {pair['process_frame']} · <a href="{directory}/{label}.json">Full state and camera record</a></p><p class="question">{question}</p></section>''')
    return f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Inside the ghost's head · Ada Research</title><style>{STYLE}</style><main><small>Random_Entropy / Prefab pilot / 16 October 2026</small><h1>Two positions in the same encounter</h1><p class="intro">The left image follows the ghost's head. The right shows the same moment from outside. Every pair keeps the camera poses and complete artifact state, so a visible difference can be traced back to its conditions.</p><nav><a href="#01-before-touch">Before touch</a><a href="#02-separated">Separation</a><a href="#03-another-seed">New seed</a><a href="#04-replayed">Replay</a></nav><nav>{alternate}<a href="guide.html">Method / try it live</a><a href="paired-observations.zip">Download images + state records</a><a href="../2026-10-16-ghost-student-pilot/index.html#watch">Earlier rehearsal film</a></nav>{''.join(blocks)}<section class="bar"><h2>Compare while the ghost acts</h2><p>Run <code>commons/artifacts/prefab_disorder/preview.tscn</code> in Godot with F6. Select <strong>COMPARE CAMERAS</strong>, then <strong>WATCH</strong>. Use <strong>SAVE BOTH VIEWS</strong> for an additional observation and <strong>OPEN CAPTURES</strong> to find its files.</p><details><summary>See the live desktop comparison</summary><a href="live-comparison.png"><img src="live-comparison.png" alt="Desktop preview with both live camera views and artifact controls"></a></details></section><footer><p><a href="verification.json">{len(native['checks'])} camera/capture checks</a>, <a href="rehearsal-regression/verification.json">{len(regression['checks'])} rehearsal checks</a> and <a href="museum-report.json">{len(hall['checks'])} actual-hall checks</a> pass. Images are native Godot renders from one shared world. <a href="manifest.json">Source hashes</a>.</p><p>These are scripted, monoscopic observations. They help inspect visible consequences and sightlines; headset comfort and human understanding still need their own trials.</p></footer></main></html>'''

(HERE / 'index.html').write_text(page(hall['observations']['ghost']['observations'], 'hall', 'Actual Entropy hall', '<a href="preview.html">Isolated preview captures</a>'), encoding='utf8')
(HERE / 'preview.html').write_text(page(native['pairs'], 'captures', 'Isolated preview', '<a href="index.html">Actual hall captures</a>'), encoding='utf8')
guide = markdown.markdown((HERE / 'README.md').read_text(encoding='utf8'), extensions=['fenced_code','tables'])
(HERE / 'guide.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Head camera method</title><style>{STYLE}</style><main><nav><a href="index.html">Paired observations</a></nav>{guide}</main></html>', encoding='utf8')
with zipfile.ZipFile(HERE / 'paired-observations.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
    for dirname in ['hall', 'captures']:
        for path in (HERE / dirname).iterdir():
            if path.suffix in ['.png','.json']: archive.write(path, path.relative_to(HERE))
    for name in ['README.md','manifest.json','verification.json','museum-report.json']:
        archive.write(HERE / name, name)
print('Paired review built: actual hall and isolated preview, four moments each.')
