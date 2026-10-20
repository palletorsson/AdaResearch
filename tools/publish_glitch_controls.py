"""Publish the museum's new dial interface with its native validation."""
from pathlib import Path
import hashlib, html, json, re, shutil

R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-glitch-dials'
N=R/'ada_run/encounter_pilot/Shader_05_Patterns'
P=R/'doc/book/iterations/2026-10-09-cut-the-image-pixels'
M=O/'museum';M.mkdir(exist_ok=True)
run=json.loads((N/'report.json').read_text())
assert not run['failures'] and len(run['checks'])==82
log=(N/'stdout.log').read_text(encoding='utf-8')
assert not any(word in log for word in ['SCRIPT ERROR','SHADER ERROR','Shader compilation failed'])
prior=json.loads((P/'source-manifest.json').read_text())
unchanged={}
for name in ['pixel_surface.gdshader','pixel_modes.gd','receivers.gd','camera_surface.gdshader','colour_plane.gdshader']:
    path='commons/artifacts/camera_glitch_study/'+name
    actual=hashlib.sha256((R/path).read_bytes()).hexdigest()
    assert actual==prior[path],path
    unchanged[path]=actual
for name in ['new-console.png','new-gallery.png','overhead.png','report.json','stdout.log','source_manifest.json']:
    shutil.copy2(N/name,M/name)
for source,dest in [('pixel-controls.png','before-controls.png'),('pixels-02.png','before-gallery.png')]:
    shutil.copy2(P/'museum'/source,M/dest)
style='''*{box-sizing:border-box}body{margin:0;background:#eee9e1;color:#18282c;font:19px/1.65 Georgia,serif}header,main,footer{max-width:1450px;margin:auto;padding:32px}h1{font-size:clamp(40px,5vw,76px);line-height:1.08;max-width:1000px}h2{margin-top:2em}p{max-width:80ch}a{color:#84495f}nav{display:flex;flex-wrap:wrap;gap:20px;font:15px/1.6 system-ui}img{display:block;width:100%;height:auto}figure{margin:0}figcaption{font:15px/1.6 system-ui;padding:12px 0}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}.callout{background:#dedbd1;padding:22px;margin:28px 0;font:17px/1.7 system-ui}table{border-collapse:collapse;width:100%;font:16px/1.6 system-ui}td,th{border-bottom:1px solid #c2bdb6;padding:12px;text-align:left;vertical-align:top}pre{background:#18282c;color:#eee9e1;padding:22px;overflow:auto;font:13px/1.5 Consolas}summary{cursor:pointer;margin-top:24px}footer{font:14px/1.6 system-ui;border-top:1px solid #c2bdb6}@media(max-width:850px){.pair{display:block}header,main,footer{padding:20px}}'''
def fig(name,caption):
    return f'<figure><a href="museum/{name}"><img src="museum/{name}" alt="{html.escape(caption)}" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure>'
body='<p>The camera study now has a compact instrument inspired by <strong>interactable_demo</strong>: two physical dials, grouped rectangular buttons, and a display naming the current effect and image state.</p>'
body+=fig('new-console.png','Actual museum capture: effect selection and strength on the left, seven rectangular controls on the right.')
body+='''<div class="callout"><strong>EFFECT</strong> clicks through ten positions. <strong>STRENGTH</strong> runs continuously from 0 to 100. Turn by hand or drag with a pointer. NEXT / PREVIOUS and RESET update the dials as well as the image.</div>
<table><tr><th>Control</th><th>Action</th></tr><tr><td>PIXELS / FORM</td><td>Choose the flat image operations or spatial receivers. Pink indicates PIXELS; the display names the current bank.</td></tr><tr><td>PREVIOUS · NEXT</td><td>Browse the same ten choices as the EFFECT dial.</td></tr><tr><td>SNAP · LIVE / HOLD</td><td>Save a camera frame and choose live or held input. Pink indicates HOLD.</td></tr><tr><td>HOME · RESET</td><td>Return the released camera; or restore effect 1, strength 80% and LIVE in the chosen bank. The saved frame is retained.</td></tr></table>'''
body+='<h2>One nearby instrument</h2><p>The faceplate is 1.16 metres wide. The long single row has become one bank button above three close pairs. Cream, charcoal and pink match the camera, while light legends identify selected buttons. The dials retain the demo’s physical grip dimensions and shared angular input.</p><div class="pair">'
body+=fig('before-controls.png','Before: a slider and seven buttons spread across a long row.')+fig('new-console.png','After: two dials, readable values, and grouped rectangular caps.')+'</div>'
body+='<h2>Inside the hall</h2>'+fig('new-gallery.png','The same camera station in Shader_05_Patterns; the original view stays beside its transformed image.')
body+='<h2>Checked in Godot</h2><p><strong>82 museum checks pass.</strong> They include both banks, all ten selector positions, desktop pointer button clicks, XRTools camera pickup and dial rotation using supplied controller poses, pointer-dial drag/release, reset synchronisation, retained snapshots and the supported path to the controls and exit. Capture-camera checks are included in the total.</p><p>The five geometry/pixel definition files match the previously validated source hashes. This change replaces the interface; the twenty image operations retain their existing definitions.</p><p>The final run has no script or shader compilation errors. Initial setup errors were corrected and their logs retained. Existing project UID/Jolt warnings and the authored-entry fallback remain. Headset feel, Quest performance and an independent learner test remain open.</p>'
body+='<nav><a href="museum/report.json">82 checks</a><a href="museum/stdout.log">Native output</a><a href="source-manifest.json">Source hashes</a><a href="validation/unchanged-image-definitions.json">Unchanged image definitions</a><a href="../2026-10-09-cut-the-image-pixels/index.html">Ten pixel examples</a><a href="../2026-10-09-camera-image-becomes-body/index.html">Ten spatial examples</a></nav>'
S=O/'source';S.mkdir(exist_ok=True)
paths=[R/'commons/artifacts/camera_glitch_study'/name for name in ['glitch_console.gd','CameraGlitchStudy.gd']]
paths+=[R/'tools/probes/camera_glitch_controls.gd',R/'tools/probes/camera_glitch_room.gd',R/'tools/probes/glitch_console_smoke.gd']
body+='<h2>Source</h2>'
for path in paths:
    shutil.copy2(path,S/path.name)
    body+=f'<details><summary>{html.escape(path.name)}</summary><a href="source/{path.name}">Download source</a><pre><code>{html.escape(path.read_text(encoding="utf-8"))}</code></pre></details>'
(O/'index.html').write_text(f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Turn the image — Endless Museum</title><style>{style}</style></head><body><header><p>ENDLESS MUSEUM · SHADER PATTERNS · 9 OCTOBER 2026</p><h1>Turn the image</h1></header><main>{body}</main><footer>Native Godot museum captures. Interface reference: commons/interactables/InteractableDemo.gd. Existing shaders and museum placement retained.</footer></body></html>',encoding='utf-8')
paths += [R/'commons/interactables'/p for p in ['dial_smooth.gd','dial_smooth.tscn','angular_driver.gd','angular_handle.gd','scalar_pointer.gd','push_button.gd','push_button.tscn','interactable_area_button_pointer.gd']]
(O/'source-manifest.json').write_text(json.dumps({p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},indent=2),encoding='utf-8')
(O/'validation/unchanged-image-definitions.json').write_text(json.dumps(unchanged,indent=2),encoding='utf-8')
links=0
for ref in re.findall(r'(?:href|src)="([^"]+)"',(O/'index.html').read_text(encoding='utf-8')):
    assert (O/ref).exists(),ref
    links+=1
(O/'publication.json').write_text(json.dumps({'native_checks':82,'local_links':links,'unchanged_image_definitions':5,'browser_render_checked':False},indent=2),encoding='utf-8')
print(json.dumps({'report':str(O/'index.html'),'checks':82,'links':links}))
