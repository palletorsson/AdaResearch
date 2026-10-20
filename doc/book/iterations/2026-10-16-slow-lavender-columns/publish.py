from pathlib import Path
import json, shutil, hashlib, html
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
RUN=ROOT/'ada_run/encounter_pilot/Random_Entropy/slow-lavender-columns'
times=[0,15,45,90,180]
for t in times:shutil.copy2(RUN/f'mixing-{t:03d}.png',HERE/f'mixing-{t:03d}.png')
shutil.copy2(RUN/'live-reading.png',HERE/'live-reading.png')
shutil.copy2(RUN/'report.json',HERE/'museum-report.json')
model=json.loads((HERE/'verification.json').read_text(encoding='utf8'))
room=json.loads((HERE/'museum-report.json').read_text(encoding='utf8'))
assert model['passed'] and room['passed']
old=json.loads((HERE.parent/'2026-10-16-column-mixing/verification.json').read_text(encoding='utf8'))
same=all(a['positions']==b['positions'] for a,b in zip(model['samples'][-1]['columns'],old['samples'][2]['columns']))
assert same
style='''*{box-sizing:border-box}body{margin:0;background:#f2eef3;color:#33313d;font:17px/1.55 system-ui,sans-serif}main{max-width:1500px;margin:auto;padding:22px}h1{font:38px/1.2 Georgia,serif;margin:0}p{max-width:88ch}a{color:#63517f}.swatches{display:flex;gap:14px;margin:16px 0}.swatch{padding:9px 20px;border-radius:5px;color:#292333}.lavender{background:#b49af7}.coral{background:#f58b91}fieldset{border:0;padding:0;margin:18px 0}legend{margin:8px 0}input{accent-color:#72548b;margin:0 4px 14px 10px}label{display:inline-block;border:1px solid #b7a7bb;border-radius:5px;padding:7px 14px;cursor:pointer}input:checked+label{background:#695375;color:white}figure{margin:0;display:none}img{width:100%;max-height:70vh;object-fit:contain;display:block;background:#424758}figcaption{padding:12px;background:#e3dce5;font-size:15px}nav{display:flex;flex-wrap:wrap;gap:20px;margin:25px 0}details{margin:24px 0}summary{cursor:pointer}pre{white-space:pre-wrap;font:16px/1.6 system-ui}@media(max-width:750px){main{padding:15px}h1{font-size:30px}label{padding:6px}input{margin-left:3px}}'''
style+=''.join(f'#t{t}:checked~.frames .s{t}{{display:block}}' for t in times)
captions={0:'Starting arrangements in lavender and warm coral.',15:'15 seconds: the layered column still holds a strong division.',45:'45 seconds: the boundary is softening; this is only 11.25 seconds along the earlier trajectory.',90:'90 seconds: continuing to mix, with the same number of beads in both groups.',180:'Three minutes: these exact positions occurred at 45 seconds in the earlier, faster version.'}
controls=''.join(f'<input type="radio" name="time" id="t{t}" {"checked" if t==0 else ""}><label for="t{t}">{"Start" if t==0 else str(t)+" seconds"}</label>' for t in times)
frames=''.join(f'<figure class="s{t}"><img src="mixing-{t:03d}.png" alt="{html.escape(captions[t])}" width="1600" height="1050"><figcaption>{html.escape(captions[t])}</figcaption></figure>' for t in times)
body=f'''<h1>A slower mixing, in lavender and coral</h1><p>The same seeded paths now run at one-quarter speed. The beginnings have longer to remain visible. Forty lavender beads meet forty warm coral beads inside each glass column.</p><div class="swatches"><span class="swatch lavender">Lavender · #b49af7</span><span class="swatch coral">Warm coral · #f58b91</span></div><fieldset><legend>Native Godot captures at the same viewpoint</legend>{controls}<div class="frames">{frames}</div></fieldset><p>The first eight seconds still hold the beginnings. PAUSE/RESUME and RESTART remain on the side panel. Mixing continues without a forced shared endpoint. Reload Entropy Workshop (Random_Entropy) to try the new pace.</p><p>The glass, bases and collars stay neutral and non-emissive. The two bead colours carry the change. Captures use an orthographic comparison camera; headset legibility remains to be tried.</p><p>49 existing apparatus checks and 43 installed-room checks pass. The 180-second positions match the earlier 45-second record exactly: this revision slows the existing motion rather than changing its path.</p>'''
for name in ['final.md','tutorial.md']:
    text=(ROOT/'commons/maps/Random_Entropy'/name).read_text(encoding='utf8')
    (HERE/name).write_text(text,encoding='utf8')
    body+=f'<details><summary>Updated {name}</summary><pre>{html.escape(text)}</pre></details>'
body+='''<nav><a href="verification.json">Apparatus checks and coordinates</a><a href="museum-report.json">Room checks</a><a href="live-reading.png">Updated side panel</a><a href="../2026-10-16-column-mixing/index.html">Earlier pace and palette</a><a href="/long-museum/writing-wall?map=Random_Entropy">Writing wall</a></nav>'''
(HERE/'index.html').write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Slower lavender and coral columns · Ada Research</title><style>'+style+'</style><main>'+body+'</main></html>',encoding='utf8')
files=[ROOT/'commons/artifacts/ordinary_entropies'/n for n in ['column_mixing.gd','jar_column.gd','jar_states.gd']]+[ROOT/'commons/maps/Random_Entropy'/n for n in ['final.md','tutorial.md','plan.md','writing_wall.json']]
(HERE/'manifest.json').write_text(json.dumps({'step_seconds':0.48,'previous_step_seconds':0.12,'speed_ratio':0.25,'palette':{'lavender':'#b49af7','warm_coral':'#f58b91'},'same_positions_at_four_times_elapsed':same,'checks':[49,43],'sha256':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in files}},indent=2),encoding='utf8')
(HERE/'README.md').write_text('''# Slower lavender and coral columns

Palle asks for slower mixing and a queer palette. The fixed proposal interval changes from 0.12 to 0.48 seconds; displacement bounds, seeds and paths remain. 180 seconds now reproduce exactly the previous 45-second coordinates. The columns recolour their two groups as lavender #b49af7 and warm coral #f58b91. Glass and structural materials remain neutral. Labels and current texts follow the change; the original hand-sized jar retains its red/blue palette.

Existing apparatus regression checks run via run.py: 49 pass. The actual museum probe runs with output tag slow-lavender-columns: 43 pass, including approach activation, pointer pause/resume and restart. Native images at the start and three minutes were inspected. Palette legibility under headset conditions remains a human check. Earlier review records remain untouched. No placement or hall-order changes.

Reproduce with run.py, then tools/run_encounter_probe.py Random_Entropy --sequence randomness --render --no-bridges --output-tag slow-lavender-columns --probe doc/book/iterations/2026-10-16-slow-lavender-columns/museum_probe.gd, then publish.py.
''',encoding='utf8')
print('Published slow lavender/coral columns; 49 + 43 checks; exact time-scaled replay.')
