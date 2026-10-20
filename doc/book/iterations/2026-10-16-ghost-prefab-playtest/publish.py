"""Publish actual native captures, without synthesising or retouching the views."""
from pathlib import Path
import json, shutil, html, hashlib, zipfile, re
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
RUN=ROOT/'ada_run/encounter_pilot/Random_Entropy/ghost-prefab-playtest'
USER=Path.home()/'AppData/Roaming/Godot/app_userdata/Ada Research Zero One'
receipt=json.loads((RUN/'report.json').read_text(encoding='utf8'))
ghost=receipt['observations']['ghost']
(HERE/'hall').mkdir(exist_ok=True)
for pair in ghost['observations']:
    source=USER/pair['folder'].removeprefix('user://')
    for file in pair['files'].values():
        assert hashlib.sha256((source/file['name']).read_bytes()).hexdigest()==file['sha256']
        shutil.copy2(source/file['name'],HERE/'hall'/file['name'])
    shutil.copy2(source/(pair['label']+'.json'),HERE/'hall'/(pair['label']+'.json'))
shutil.copy2(RUN/'report.json',HERE/'museum-report.json')
shutil.copy2(RUN/'source_manifest.json',HERE/'museum-source-manifest.json')
files=['commons/ghost_students/hologram.gd','commons/ghost_students/observation_rig.gd','commons/ghost_students/thought_stream.gd','commons/ghost_students/hall_walk.gd','commons/artifacts/prefab_disorder/ghost_student.gd','commons/artifacts/prefab_disorder/part_witness.gd','commons/artifacts/prefab_disorder/prefab_disorder.gd','commons/artifacts/prefab_disorder/preview.gd','commons/maps/Random_Entropy/tutorial.md','commons/maps/Random_Entropy/final.md']
(HERE/'source-manifest.json').write_text(json.dumps({p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in files},indent=2)+'\n')
titles={'01-before-touch':'Before touching the controls','02-original-left':'Find the CRT in the intact left copy','03-separated-left':'Hold stage 0.5: look left','04-separated-right':'Same state: look right','05-follow-early':'Follow the screen: early joining','06-follow-middle':'Follow the screen: midpoint','07-follow-late':'Follow the screen: late joining','08-first-hybrid':'The screen in hybrid B, seed 435','09-another-seed':'Another seed, same stage','10-kept':'Keep an intermediate arrangement','11-replayed':'Replay after changing the conditions','12-next-shannon':'Continue to the Shannon ledger'}
e=html.escape
style='''body{margin:0;background:#101a20;color:#e7efeb;font:18px/1.6 system-ui,sans-serif}main{max-width:1700px;margin:auto;padding:32px}h1{font-size:clamp(32px,4vw,64px);line-height:1.1;max-width:1000px}h2{font-size:28px}p{max-width:950px}a{color:#93ddd6}nav{display:flex;gap:10px;flex-wrap:wrap}nav a,.badge{padding:8px 12px;background:#24383f;border-radius:8px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:16px}.pair figure{margin:0}.pair img{width:100%;height:auto;display:block;border:1px solid #50616b}figcaption{color:#acbdc4;font-size:15px}section{padding:24px 0;border-top:1px solid #3a5058;scroll-margin:16px}.thoughts{display:grid;grid-template-columns:repeat(3,1fr);gap:16px;margin:20px 0}.thoughts div{padding:16px;background:#192c32;border-left:3px solid #98ddd6}.thoughts div:nth-child(2){border-color:#ddc4f5}.thoughts div:nth-child(3){border-color:#ffe09b}.thoughts b{display:block;font-size:13px;text-transform:uppercase;letter-spacing:.08em}.thoughts p{margin:6px 0}details{color:#b8c9d0}code{font-size:14px}small{color:#b8c9d0}table{border-collapse:collapse}td,th{padding:10px;border-bottom:1px solid #456;text-align:left}svg{background:#192c32;max-width:800px;width:100%}@media(max-width:800px){main{padding:16px}.pair,.thoughts{grid-template-columns:1fr}}'''
parts=[f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Following a part — ghost playtest</title><style>{style}</style><main>',
'<small>ADA RESEARCH · RANDOM_ENTROPY · 16 OCTOBER 2026</small><h1>Follow a part. Keep a relation. Carry a question onward.</h1>',
'<p>The ghost compares both tables at one unchanged stage, follows the CRT screen into a hybrid, keeps and replays a form, then walks to the Shannon ledger. These are actual Godot hall renders, paired at the same instant. The words around its head are authored rehearsal cues and source excerpts.</p>',
'<nav><a href="#findings">What changed</a><a href="#03-separated-left">Compare tables</a><a href="#05-follow-early">Follow the screen</a><a href="#10-kept">Keep / replay</a><a href="#12-next-shannon">Next artifact</a><a href="observations-and-source.zip">Download records and source</a><a href="tutorial.html">Updated tutorial</a></nav>',
'<section id="findings"><h2>What the eye view changed</h2><table><tr><th>Observation</th><th>Revision</th></tr><tr><td>The earlier camera watched the right side and did not establish the comparison.</td><td>Hold stage 0.5 and turn between tables before moving the slider.</td></tr><tr><td>The CRT screen is small and easily lost among separated pieces.</td><td>Optional FOLLOW PART frame and label, plus six seconds for joining. Materials remain visible.</td></tr><tr><td>The first outside view cropped the head annotations.</td><td>Reframe the outside camera and keep the eye view free of floating text.</td></tr><tr><td>The standing position was too close to the entrance wall; floor-seam normals also falsely blocked navigation.</td><td>Move the stance inward, check nearby floor support and body clearance, then walk a verified route.</td></tr></table><p>The improved cue makes identity easier to follow in these images. It does not prove that a learner recognises a new use, that the hybrid is mechanically joined, or that headset interaction feels good. The next human trial should turn the marker off and ask where the relation becomes unclear.</p><p><a href="../2026-10-16-ghost-head-camera/index.html">Earlier camera trial</a> · <a href="README.md">Method and limits</a></p></section>']
for pair in ghost['observations']:
    label=pair['label']; state=pair['artifact_state']
    title=titles.get(label,label)
    if label=='08-first-hybrid': title='The screen reaches hybrid '+chr(65+pair['part_witness']['hybrid'])+', seed 435'
    parts.append(f'<section id="{label}"><h2>{e(title)}</h2><p><span class="badge">Seed {state["seed"]} · stage {state["disorder"]:.3f}</span> <small>{e(pair["attention"])} · frame {pair["process_frame"]}</small></p><div class="pair">')
    for channel,caption in [('eyes','Inside the ghost’s head'),('outside','Outside · the same instant')]:
        path='hall/'+pair['files'][channel]['name']
        parts.append(f'<figure><a href="{path}"><img width="960" height="640" style="aspect-ratio:3/2" src="{path}" alt="{e(title)} — {caption}"></a><figcaption>{caption}. Open image for full size.</figcaption></figure>')
    parts.append('</div><div class="thoughts">')
    for item in pair['thought_stream']:
        parts.append(f'<div><b>{e(item["role"])}</b><p>{e(item["text"].replace("**",""))}</p><small>{e(item.get("path","Authored question; not a learner report").removeprefix("res://"))}</small></div>')
    parts.append(f'</div><details><summary>Head pose, part identity and replayable state</summary><p><a href="hall/{label}.json">Full JSON receipt</a> · Same process frame: {pair["same_process_frame"]}. Source checksums and camera settings included. The prefab state on arrival is the restored baseline; the view has moved to the ledger.</p></details></section>')
walk=receipt['observations']['walk']; path=walk.get('path_world',[])
if path:
    xs=[p[0] for p in path];zs=[p[2] for p in path];xmin=min(xs)-.5;zmin=min(zs)-.5
    points=' '.join(f'{(p[0]-xmin)*90+20:.1f},{(p[2]-zmin)*90+20:.1f}' for p in path)
    parts.append(f'<section><h2>The continuation</h2><p>{walk["travelled_metres"]:.2f} metres at {walk["speed_metres_per_second"]:.2f} m/s. The route checks floor support and clearance and stops on obstruction. The ledger is the first encounter of the main room/final sequence. Its own control rehearsal is still to build.</p><svg viewBox="0 0 620 330" role="img" aria-label="Recorded walking path in world X Z coordinates"><polyline points="{points}" fill="none" stroke="#9edfd5" stroke-width="4"/><text x="25" y="315" fill="#eee" font-size="15">Recorded floor path · world X / Z · no teleport</text></svg></section>')
checks=receipt['checks'];passed=sum(c['passed'] for c in checks)
parts.append(f'<section><h2>Verification</h2><p>{passed}/{len(checks)} actual-hall checks pass. <a href="museum-report.json">Hall receipt</a> · <a href="verification.json">Isolated apparatus and fresh reconstruction</a> · <a href="rehearsal-regression/verification.json">Existing rehearsal regression</a> · <a href="source-manifest.json">Source hashes</a>.</p><p>Native rendered rehearsal and synthetic pointer input establish apparatus behaviour and a recorded viewpoint. They do not establish comprehension, independent human reconstruction, physical VR hand contact, haptics, comfort or Quest performance. The 48-value seed bench remains the first research pilot.</p></section></main></html>')
(HERE/'index.html').write_text(''.join(parts),encoding='utf8')
import markdown
tutorial=markdown.markdown((ROOT/'commons/maps/Random_Entropy/tutorial.md').read_text(encoding='utf8'),extensions=['tables','fenced_code'])
def tutorial_link(match):
    href=match.group(1)
    if href.startswith(('http:','https:','#','/')): return match.group(0)
    target=(ROOT/'commons/maps/Random_Entropy'/href).resolve()
    if not target.relative_to(ROOT).as_posix().startswith('doc/book/iterations/'):
        (HERE/'references').mkdir(exist_ok=True)
        shutil.copy2(target,HERE/'references'/target.name)
        return 'href="references/'+target.name+'"'
    return 'href="/book-review/'+target.relative_to(ROOT).as_posix()+'"'
tutorial=re.sub(r'href="([^"]+)"',tutorial_link,tutorial)
(HERE/'tutorial.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Entropy tutorial</title><style>{style}pre{{overflow:auto;background:#192c32;padding:20px}}main{{max-width:1000px}}</style><main><a href="index.html">Back to ghost playtest</a>'+tutorial+'</main></html>',encoding='utf8')
with zipfile.ZipFile(HERE/'observations-and-source.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for file in (HERE/'hall').glob('*'): archive.write(file,'hall/'+file.name)
    for file in ['museum-report.json','source-manifest.json','README.md','index.html','tutorial.html']:
        if (HERE/file).exists(): archive.write(HERE/file,file)
    for file in files: archive.write(ROOT/file,'source/'+file)
    for file in (HERE/'references').glob('*'): archive.write(file,'references/'+file.name)
print(f'Published {len(ghost["observations"])} paired hall observations; {passed}/{len(checks)} checks.')
