"""Publish actual museum camera pixel captures, code and focused validation."""
from pathlib import Path
import hashlib, html, json, re, shutil, zipfile
import markdown

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-09-cut-the-image-pixels'
N = R / 'ada_run/encounter_pilot/Shader_05_Patterns'
A = R / 'commons/artifacts/camera_glitch_study'
M = O / 'museum'
M.mkdir(exist_ok=True)
run = json.loads((N / 'report.json').read_text())
tests = json.loads((O / 'validation/results.json').read_text())
assert not run['failures'] and len(run['checks']) == 70
assert all(tests[k]['passed'] for k in ['geometry-regression', 'spatial-gpu-regression', 'pixels'])
assert tests['stride-removed']['exit'] == tests['saved-is-live']['exit'] == 1
native_log = (N / 'stdout.log').read_text(encoding='utf-8')
assert not any(s in native_log for s in ['SCRIPT ERROR', 'SHADER ERROR', 'Shader compilation failed'])
for name in [*(f'pixels-{i:02}.png' for i in range(1, 11)), 'pixel-source.png', 'pixel-controls.png',
             'overhead.png', 'gallery-raised.png', 'report.json', 'source_manifest.json', 'stdout.log', 'engine.log']:
    shutil.copy2(N / name, M / name)
assert len({hashlib.sha256((M/f'pixels-{i:02}.png').read_bytes()).hexdigest() for i in range(1,11)}) == 10

names = ['Chop the bands', 'The wrong row width', 'Repeat a scanline', 'Exchange the blocks',
         'Channels lose registration', 'Tear one band', 'Blocks keep the past', 'Fewer colour values',
         'Missing blocks', 'Read every other row backwards']
notes = [
    'Alternate horizontal bands read pixels farther left or right. The image wraps at its edges; the screen remains one rectangle.',
    'The source is treated as a flat list of pixels, but each new row starts too far along it. A width of 640 is read with a stride of 693 here. Successive rows lose alignment.',
    'The first row of each 21-row group fills the whole group. Detail stretches into little vertical curtains; intervening rows are no longer sampled.',
    'An 8 × 6 grid exchanges all 48 blocks through one fixed permutation. At this maximum setting every source block appears once. Intermediate slider positions interpolate the offsets.',
    'Red reads 32 pixels to one side, blue 32 pixels to the other. Green stays at the original address. One object acquires coloured misaligned edges.',
    'Only the middle fifth moves sideways. Above and below, the original room still aligns. A small selection condition produces one large discontinuity.',
    'SNAP retains a frame, then the camera moves. Thirty-six blocks keep the earlier image while twelve read the current view. This capture uses LIVE; the other nine use one shared saved frame.',
    'Each sampled channel is rounded to four available values. Continuous shades become abrupt patches. Pixel addresses stay the same.',
    'Half the blocks are replaced with black. The picture looks incomplete, although the original image is still available beside it.',
    'Every odd source row reads backwards; even rows retain their direction. At a distance the interleaved image can resemble a double exposure. Approach to see its alternating rows.'
]
style = '''*{box-sizing:border-box}body{margin:0;background:#eeebe5;color:#1d2c3b;font:19px/1.65 Georgia,serif}header,main,footer{max-width:1500px;margin:auto;padding:32px}h1{font-size:clamp(40px,5vw,76px);line-height:1.08;max-width:1000px}h2{margin-top:2.2em}p{max-width:85ch}a{color:#345b75}nav{display:flex;flex-wrap:wrap;gap:18px;font:15px/1.6 system-ui}figure{margin:0}img{width:100%;height:auto;display:block}figcaption{font:15px/1.6 system-ui;padding:12px 0}.grid{display:grid;grid-template-columns:1fr 1fr;gap:24px}.card{padding:18px;background:#fffdf9;margin:20px 0}.card h2{font-size:26px;margin:0 0 12px}.card p{font:16px/1.6 system-ui}.note{background:#dae4df;padding:20px;font:16px/1.6 system-ui}pre{background:#1d2c3b;color:#f7f0e7;padding:22px;overflow:auto;font:13px/1.55 Consolas}table{border-collapse:collapse;width:100%;font:15px/1.6 system-ui}td,th{text-align:left;vertical-align:top;padding:12px;border-bottom:1px solid #b8c2c6}summary{cursor:pointer;margin:24px 0}footer{font:14px/1.6 system-ui;border-top:1px solid #bbc4c6}@media(max-width:850px){.grid{display:block}header,main,footer{padding:20px}}'''
nav = '<nav><a href="index.html">Ten pixel views</a><a href="evidence.html">Checks</a><a href="source.html">Source</a><a href="../2026-10-09-camera-image-becomes-body/index.html">Earlier spatial views</a><a href="camera-pixels-review.zip">Review ZIP</a></nav>'

def page(name, title, body):
    (O/name).write_text(f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{style}</style></head><body><header><p>ENDLESS MUSEUM · SHADER PATTERNS · 9 OCTOBER 2026</p><h1>{html.escape(title)}</h1>{nav}</header><main>{body}</main><footer>Native Godot 4.6 captures inside Shader_05_Patterns. Desktop and supplied XRTools poses checked; a headset run remains open.</footer></body></html>', encoding='utf-8')

def fig(src, caption):
    return f'<figure><a href="{src}"><img src="{src}" alt="{html.escape(caption)}" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure>'

body = '<p>The same camera station now has a <strong>PIXELS / FORM</strong> switch. Ten new operations work directly on the image’s sampled pixels: their addresses, values and which frame they come from. The reference view stays beside them.</p>'
body += fig('museum/pixels-02.png', 'Wrong row width: the source remains intact on the left; the same pixels lose their row alignment on the right.')
body += '<div class="note">Built in the existing museum. 34 pixel GPU checks, 36 earlier geometry/shader checks and 70 museum checks pass. Two deliberately broken shaders are rejected.</div>'
body += '<h2>Try the new bank</h2><p>Press PIXELS / FORM, then NEXT or PREVIOUS. AMOUNT controls the strength. SNAP saves a frame; HOLD lets you compare operations on exactly that image. For “Blocks keep the past,” take SNAP, return to LIVE, and move the pink camera. RESET returns to the first operation in the chosen bank and keeps the saved frame.</p>'
body += '<nav>' + ''.join(f'<a href="#pixel-{i+1}">{i+1:02} {title}</a>' for i,title in enumerate(names)) + '</nav>'
body += '<div class="grid">' + ''.join(f'<article class="card" id="pixel-{i+1}"><h2>{i+1:02}. {title}</h2>{fig(f"museum/pixels-{i+1:02}.png", notes[i])}</article>' for i,title in enumerate(names)) + '</div>'
body += '<h2>The image has an organisation</h2><p>A picture depends on where a row starts, which samples become neighbours, and which channel values are combined. Change that organisation and the familiar room becomes hard to read. The student can return AMOUNT to zero and locate the decision that produced the break.</p><p>The new bank keeps its display flat. FORM still offers the ten earlier spatial treatments. This extends one optional exhibit; it does not turn every effect into another required tutorial.</p>'
body += '<div class="grid">' + fig('museum/pixel-controls.png', 'The nearby console now switches between two banks of ten.') + fig('museum/overhead.png', 'The same side bay in Shader_05_Patterns. The garden and room route remain in place.') + '</div>'
page('index.html', 'Cut the image’s pixels', body)

evidence = '''<h2>140 focused checks pass</h2><table><tr><th>Run</th><th>Checks</th><th>What it establishes</th></tr><tr><td>Pixel GPU fixture</td><td>34</td><td>All ten zero settings reproduce the unchanged nearest-sampled image. Each maximum setting changes it. Specific pixels verify wrong stride, band offsets, repetition, block permutation, channel separation, saved/live selection, quantisation, replacement and reversed rows. The source bytes and flat receiver stay unchanged.</td></tr><tr><td>Earlier study regression</td><td>28 geometry + 8 GPU</td><td>Earlier spatial geometry and controlled shader behaviour still pass.</td></tr><tr><td>Actual museum</td><td>70</td><td>Real hall placement and source, desktop pointer buttons, XRTools grip/slider driven by supplied controller poses, route to the controls and exit, both banks, flat pixel receivers and snapshot preservation. The total includes capture-camera retention checks.</td></tr></table>
<h2>The tests can reject wrong behaviour</h2><p>Two temporary shader copies are intentionally broken. One silently restores the correct row width; its expected displaced pixel and changed-image checks fail. The other reads LIVE where the retained image is required; its saved-red-block check fails. Both exit with a failing status. Production source is unchanged by these tests.</p>
<h2>What the images establish</h2><p>All ten effects were captured from the same eye-height museum camera. Nine use one saved source; the saved/live-block example moves the source camera after the snapshot. The console and source display stay visible. The image shader never moves the receiver’s vertices.</p>
<h2>Scope</h2><p>These are real shader pixel operations on a camera texture. They do not edit an image file or corrupt GPU memory. Wrong stride explicitly models reading the same logical pixel list under another row-width assumption. Posterisation quantises sampled channel values; it is not a compressed file format. At intermediate block-shuffle amounts, offsets interpolate and may repeat or omit samples; the full setting is a permutation.</p><p>Amount zero matches the unchanged nearest-sampled fixture. The separate reference screen has ordinary filtering, so the two screens can differ in smoothness. Fine alternating rows can alias with viewing distance.</p><p>No new script or shader compilation errors appear in the passing native run. The existing unknown resource UID, Jolt solver-bias warning and authored-entry fallback remain. Headset comfort, Quest frame cost, live portal traversal and an independent student reconstruction remain untested. The wider uncertainty plan still has proposed work; this does not complete P4’s full decoder lesson.</p>
<h2>Receipts</h2><ul><li><a href="validation/results.json">All fixture runs, including the two intentional failures</a></li><li><a href="validation/pixels.json">34 pixel checks</a></li><li><a href="validation/geometry-regression.json">28 geometry checks</a></li><li><a href="validation/spatial-gpu-regression.json">8 earlier shader checks</a></li><li><a href="museum/report.json">70 actual museum checks</a></li><li><a href="museum/stdout.log">Native run output</a></li><li><a href="museum/pixel-source.png">Shared saved camera image</a></li><li><a href="source-manifest.json">Source hashes</a></li></ul>'''
page('evidence.html', 'Pixels, controls and evidence', evidence)

S = O/'source'
S.mkdir(exist_ok=True)
source = markdown.markdown((A/'README.md').read_text(encoding='utf-8'), extensions=['tables','fenced_code'])
source = source.replace('../../../doc/book/iterations/2026-10-09-cut-the-image-pixels/index.html', 'index.html').replace('../../../doc/book/iterations/2026-10-09-camera-image-becomes-body/index.html', '../2026-10-09-camera-image-becomes-body/index.html')
for path in sorted(A.iterdir()):
    if path.suffix not in ['.gd', '.gdshader', '.tscn']: continue
    shutil.copy2(path,S/path.name)
    source += f'<details><summary>{html.escape(path.name)}</summary><p><a href="source/{path.name}">Download source</a></p><pre><code>{html.escape(path.read_text())}</code></pre></details>'
page('source.html', 'One source, different addresses', source)
probes = [R/'tools/probes'/x for x in ['camera_pixels_gpu.gd','camera_pixels_room.gd','camera_glitch_gpu.gd','camera_glitch_room.gd','camera_glitch_test.gd']]
probes += [R/'tools/test_camera_pixels.py', R/'tools/publish_camera_pixels.py']
for path in probes: shutil.copy2(path,S/path.name)
sources = list(A.glob('*')) + probes + [R/'commons/artifacts/registry/shaders.json', R/'commons/maps/Shader_05_Patterns/map_data.json', R/'commons/artifacts/spine_studies/witness_camera.gd', R/'commons/ui/control_console.gd']
(O/'source-manifest.json').write_text(json.dumps({p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sources if p.is_file()},indent=2),encoding='utf-8')
with zipfile.ZipFile(O/'camera-pixels-review.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in O.rglob('*'):
        if p.is_file() and p.suffix!='.zip': z.write(p,p.relative_to(O))
    z.writestr('READ-ME.txt','Open index.html. Native Godot museum captures; no generated images. Source needs the existing Ada museum and its supplied XRTools/console dependencies. The earlier spatial report link needs the repository. Headset and Quest testing remain open.\n')
links=0
for p in O.glob('*.html'):
    for ref in re.findall(r'(?:href|src)="([^"]+)"',p.read_text(encoding='utf-8')):
        if ref.startswith(('http:','https:')): continue
        path,_,anchor=ref.partition('#');dest=p.parent/path if path else p
        assert dest.exists(),(p,ref)
        if anchor and dest.suffix=='.html': assert f'id="{anchor}"' in dest.read_text(encoding='utf-8'),ref
        links+=1
with zipfile.ZipFile(O/'camera-pixels-review.zip') as z: assert z.testzip() is None
(O/'publication.json').write_text(json.dumps({'local_links':links,'native_pixel_captures':10,'checks_passed':140,'deliberate_faults_rejected':2,'zip_crc_valid':True,'browser_render_checked':False},indent=2),encoding='utf-8')
print(json.dumps({'report':str(O/'index.html'),'links':links,'zip_mb':round((O/'camera-pixels-review.zip').stat().st_size/1e6,2)}))
