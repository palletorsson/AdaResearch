from pathlib import Path
import hashlib
import html
import json
import shutil
import markdown

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
RUN = ROOT / 'ada_run/encounter_pilot/Random_Entropy/ghost-student-pilot'
for name in ['report.json', 'hall-ghost.png', 'source_manifest.json']:
    shutil.copy2(RUN / name, HERE / ('museum-report.json' if name == 'report.json' else 'hall-source-manifest.json' if name == 'source_manifest.json' else name))
native = json.loads((HERE / 'verification.json').read_text())
hall = json.loads((HERE / 'museum-report.json').read_text())
regression = json.loads((HERE / 'gallery-regression/verification.json').read_text())
assert not native['failures'] and hall['passed'] and regression['passed']
sources = [
    'commons/ghost_students/hologram.gd', 'commons/artifacts/prefab_disorder/ghost_student.gd',
    'commons/artifacts/prefab_disorder/prefab_disorder.gd', 'commons/artifacts/prefab_disorder/preview.gd',
    'commons/artifacts/prefab_disorder/gallery_store.gd', 'commons/artifacts/prefab_disorder/kept_gallery.gd',
    'commons/interactables/scalar_pointer.gd', 'commons/maps/Random_Entropy/tutorial.md',
    'commons/maps/Random_Entropy/final.md', 'commons/maps/Random_Entropy/map_data.json',
    'commons/maps/Random_Entropy/writing_wall.json', 'commons/artifacts/registry/prefab_disorder.json',
]
(HERE / 'manifest.json').write_text(json.dumps({p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in sources}, indent=2) + '\n')
style = '''body{margin:0;background:#101b24;color:#e0ede8;font:18px/1.55 system-ui,sans-serif}main{max-width:1320px;margin:auto;padding:28px}h1{font:clamp(32px,4.5vw,54px)/1.1 Georgia,serif;margin:8px 0 20px}h2{font:28px Georgia,serif}p{max-width:80ch}small{color:#84c7c9;letter-spacing:.1em;text-transform:uppercase}a{color:#86e4e4}nav{display:flex;gap:24px;flex-wrap:wrap}video{width:100%;max-height:78vh;background:#0d1318}img{width:100%;display:block}section{margin:30px 0}figure{margin:0}figcaption{padding:16px;background:#1f3540}.grid{display:grid;grid-template-columns:1fr 1fr;gap:22px}.card{background:#1b303b;padding:22px;border-top:2px solid #78cbd5}li{margin:8px 0}code{font-size:.9em}pre{overflow:auto}td,th{padding:10px;border-bottom:1px solid #344956;text-align:left}@media(max-width:800px){.grid{grid-template-columns:1fr}main{padding:16px}}'''
page = f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A student made of light · Ada Research</title><style>{style}</style><main>
<header><small>Random_Entropy / Visible rehearsal pilot / 16 October 2026</small><h1>A student made of light</h1><p>Two hands operate the actual prefab bench: separate, recombine, try a seed, keep a form and replay it. Pauses leave space to see what changed. Touch a control and the bench becomes yours.</p>
<nav><a href="#watch">Watch the native recording</a><a href="#try">Try it in the hall</a><a href="guide.html">Method and implementation</a><a href="rehearsal.json">Action record</a></nav></header>
<section id="watch"><video controls preload="metadata" poster="step-4.png"><source src="rehearsal.mp4" type="video/mp4">Download the <a href="rehearsal.mp4">native recording</a>.</video><p>Recorded in Godot. Scripted control input and real resulting geometry. This is a first rehearsal—not evidence that a learner understands or enjoys the encounter.</p></section>
<section id="try" class="grid"><div class="card"><h2>Watch, interrupt, continue</h2><p>Reload <strong>Random_Entropy</strong>. The prefab bench is the optional encounter near the entrance, grid (13,3). Watching from the front for six seconds starts one rehearsal; <strong>WATCH</strong> starts it manually or stops it.</p><p>Any other control takes over the current arrangement. Completion or WATCH-stop restores the starting state. Your saved collection stays separate.</p><p>Standalone: open <code>commons/artifacts/prefab_disorder/preview.tscn</code> in Godot, run with F6, then WATCH.</p></div><div class="card"><h2>A loop we can inspect</h2><ol><li>Take one claim or question from the text.</li><li>Attempt it through the artifact's controls.</li><li>Compare what actually changed; preserve the record.</li><li>Let a person interrupt, continue, or reject it.</li><li>Revise one behavior, pause, or passage and replay.</li></ol><p>The next question is whether the ghost invites an experiment—or encourages passive watching.</p></div></section>
<section class="grid"><figure><img src="hands-close.png" alt="Holographic arms and fingered hands at the real control board"><figcaption>The left hand drags the slider; the right presses buttons. The rendered fingertip accompanies synthetic pointer events.</figcaption></figure><figure><img src="hall-ghost.png" alt="Ghost student operating the prefab bench in the actual Entropy museum hall"><figcaption>Installed in the Entropy hall. The ghost has no blocking collision or player identity.</figcaption></figure></section>
<section><h2>What the tests establish</h2><p><a href="verification.json">{len(native['checks'])} native checks</a> and <a href="museum-report.json">{len(hall['checks'])} hall checks</a> pass. They cover all nine actions, fresh reconstruction, saved-collection isolation, takeover, stopping, stale text, a deliberately disconnected control and scene exit. The existing <a href="gallery-regression/verification.json">{len(regression['checks'])}-check gallery suite</a> also passes.</p><p>The ghost uses public pointer handlers. Headset tracking, physical finger contact, haptics, comfort, Quest performance and human understanding remain separate trials. It does not read prose autonomously: its adapter links selected passages to explicit actions and observations.</p><p>The existing hall/final sequence stays intact. The 48-value seed bench remains the first research pilot. The reusable body can support further artifact adapters after this encounter is judged.</p></section>
</main></html>'''
(HERE / 'index.html').write_text(page, encoding='utf8')
guide = markdown.markdown((HERE / 'README.md').read_text(encoding='utf8'), extensions=['tables', 'fenced_code'])
(HERE / 'guide.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Ghost-student method</title><style>{style}</style><main><nav><a href="index.html">Native recording and evidence</a></nav>{guide}</main></html>', encoding='utf8')
print(f'Review ready: {len(native["checks"])} native, {len(hall["checks"])} hall checks')
