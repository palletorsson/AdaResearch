"""Publish measured, same-camera comparisons; never substitute a Quest claim."""
from pathlib import Path
import html,json,shutil
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'doc/ports/2026-10-27-void-visual-profiles'
OUT=ROOT/'doc/book/iterations/2026-10-27-void-visual-profiles'
OUT.mkdir(parents=True,exist_ok=True)
names={16:'Rotation / open sides and gantry',30:'Colour Flashlight / enclosed room',63:'Wave Functions / wheel machines'}
blocks=[];tables=[];results={}
for renderer,label in [('forward_plus','Desktop / Forward+'),('mobile','Mobile renderer / on this PC')]:
    source=SOURCE/renderer
    result=json.loads((source/'results.json').read_text(encoding='utf8'))
    assert result['passed']
    results[renderer]=result
    (OUT/(renderer+'-results.json')).write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
    rows=[]
    def weighted(samples,key):
        return sum(s[key]['mean']*s['frames'] for s in samples)/sum(s['frames'] for s in samples)
    for floor,title in names.items():
        groups={p:[s for s in result['samples'] if s['floor']==floor and s['profile']==p] for p in ['baseline','light','finish']}
        assert all(len(v)==2 for v in groups.values())
        for p,s in groups.items():
            rows.append(f'<tr><td>{floor}</td><td>{p}</td><td>{weighted(s,"frame_ms"):.2f}</td><td>{max(x["frame_ms"]["p95"] for x in s):.2f}</td><td>{weighted(s,"viewport_gpu_ms"):.2f}</td><td>{int(sum(x["draw_calls"] for x in s)/len(s))}</td></tr>')
        views={v['profile']:v['file'] for v in result['views'] if v['floor']==floor}
        for file in views.values():shutil.copy2(source/file,OUT/(renderer+'-'+file))
        def image(p):
            file=renderer+'-'+views[p]
            caption={'baseline':'Before / current appearance','light':'Lighting only / same materials','finish':'After / light + structural finishes'}[p]
            return f'<figure><a href="{file}" target="_blank"><img src="{file}" width="1600" height="1000" style="height:auto" alt="{html.escape(title)} — {caption}" loading="lazy"></a><figcaption>{caption}</figcaption></figure>'
        blocks.append(f'<section id="{renderer}-{floor}"><p class="eyebrow">{label} · floor {floor}</p><h2>{html.escape(title)}</h2><div class="pair">{image("baseline")}{image("finish")}</div><details><summary>See the lighting-only step</summary>{image("light")}</details><a href="http://localhost:3003/lab-editor?mode=void&amp;floor={floor}">Open unchanged floor in the lab editor →</a></section>')
    tables.append(f'<h3>{label}</h3><p>{html.escape(result["device"]["gpu"])} · 1600 × 1000 · MSAA 4× · uncapped, no fixed-fps simulation. Two 3-second samples per stage; order reverses on the second pass.</p><div class="scroll"><table><thead><tr><th>Floor</th><th>Stage</th><th>Mean frame ms</th><th>Worst pass p95 ms</th><th>Mean viewport GPU ms</th><th>End-sample draws</th></tr></thead><tbody>{"".join(rows)}</tbody></table></div>')
css='''*{box-sizing:border-box}body{margin:0;background:#eeeae4;color:#25252b;font:16px/1.6 system-ui,sans-serif}main{max-width:1450px;margin:auto;padding:48px 30px}h1{font-size:clamp(30px,4vw,58px);line-height:1.08;max-width:950px;font-weight:650;margin:12px 0 24px}h2{font-size:25px;font-weight:600}h3{font-size:19px}p{max-width:900px}.eyebrow{color:#8d365a;letter-spacing:.1em;text-transform:uppercase;font-size:12px;font-weight:700}.notice{padding:18px 24px;border-left:4px solid #bd5784;background:#fffaf7}nav{display:flex;flex-wrap:wrap;gap:20px}a{color:#883859;text-underline-offset:4px}section{padding:28px 0 40px;border-top:1px solid #c9c4c0;margin-top:36px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:18px}figure{margin:0}img{width:100%;display:block;background:#1c1c24}figcaption{padding:10px 0;font-size:13px}summary{cursor:pointer;color:#883859;padding:12px 0}details figure{max-width:900px;margin:12px auto 24px}.scroll{overflow:auto}table{border-collapse:collapse;width:100%;font-size:14px}th,td{text-align:left;padding:9px 15px;border-bottom:1px solid #c9c4c0;font-variant-numeric:tabular-nums}th{background:#dfdad4}code{font-size:13px}footer{margin-top:45px;font-size:13px} @media(max-width:850px){.pair{grid-template-columns:1fr}main{padding:25px 18px}}'''
page=f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The Void / three looks, three floors</title><style>{css}</style><main><p class="eyebrow">Ada Research · visual study · 27 October 2026</p><h1>The same places.<br>Different light.</h1><p>Three existing floors, photographed from identical cameras: current appearance, a lighting pass, then lighting with restrained structural material detail. No walls, objects, dimensions or collisions were moved. The rose/violet sky remains.</p><p class="notice"><strong>Quest testing deferred at your request.</strong> The Mobile results below are rendered on the RTX 3070 PC. They check renderer compatibility and relative cost here; they do not measure Quest stereo performance, thermals or sustained frame rate. No test app was installed.</p><nav><a href="#forward_plus-16">Rotation</a><a href="#forward_plus-30">Light room</a><a href="#forward_plus-63">Machines</a><a href="#mobile-16">Mobile renderer</a><a href="#performance">Measurements</a></nav><section><h2>What changes</h2><p><strong>Light:</strong> a warmer directional key, one unshadowed cool fill as an indirect-light approximation, sky-based ambient illumination, AgX highlights and later, lighter distance fog. The fill respects the colour room’s isolated light layer.</p><p><strong>Finish:</strong> small mipmapped textures and restrained normal detail on the tower’s concrete, steel, paint, pipe and timber materials. Teaching artifact hues, shader demonstrations, text and interactions retain their authored materials. The material step is deliberately subtle.</p><p>Photos pause motion and physics at one shared pose. Timings restore the live workload and keep the normal nine-floor visibility window, field of view and antialiasing. These are stationary comparisons, not a full traversal or a worst-case performance guarantee. Shader compilation and loading are warmed before timing; their first-visit cost is not included.</p></section>{''.join(blocks)}<section id="performance"><h2>Measured cost</h2>{''.join(tables)}<p>Frame intervals include CPU work and waiting; GPU values are Godot’s viewport measurements, not total GPU utilization or compositor latency. Live demonstration phases can change draw counts. Short samples can contain background-task noise.</p></section><section><h2>Try without changing a map</h2><p>Launch the existing Void with <code>--void-look=finish</code> after the game-argument separator. F8 cycles baseline → light → finish. Normal launches retain the existing appearance. The profile changes scene-local materials and lighting; it never saves a layout.</p><p>Example: <code>Godot --path &lt;project&gt; --xr-mode off res://commons/void/void.tscn -- --void-start-floor=16 --void-look=finish</code></p></section><footer><a href="forward_plus-results.json">Desktop receipt</a> · <a href="mobile-results.json">Mobile-on-PC receipt</a> · Source layouts are hash-checked by the serial isolated runner. Physical Quest results remain pending.</footer></main></html>'''
(OUT/'index.html').write_text(page,encoding='utf8')
controls=json.loads((SOURCE/'controls.json').read_text(encoding='utf8'))
assert controls['passed']
summary=[]
for renderer,result in results.items():
    for floor in names:
        values=[]
        for profile in ['baseline','light','finish']:
            samples=[s for s in result['samples'] if s['floor']==floor and s['profile']==profile]
            values.append(weighted(samples,'frame_ms'))
        summary.append('| '+renderer+' | '+str(floor)+' | '+' | '.join(f'{v:.2f}' for v in values)+' |')
report='''# Void visual profiles / three-floor trial

27 October 2026. Completed desktop comparison; physical Quest testing explicitly deferred by Palle. No test APK was built or installed.

## Delivered

An opt-in scene-owned controller, `commons/void/visual_profile.gd`, with three stages: baseline, light, finish. Pass `--void-look=finish` after `--` in a normal Void launch; F8 cycles stages. Normal launches keep their original appearance. `game.gd` only creates the controller when that argument is present.

The light stage adjusts the existing sun, ambient illumination, tone mapping and distance fog. One unshadowed cool directional fill approximates indirect illumination. It is an art-directed approximation, not bounced global illumination. The fill follows the existing sun's layer mask, preserving the isolated colour-room light boundary. No SSAO, SSIL, SDFGI, volumetric fog, DOF, TAA or additional shadow map is introduced.

Finish duplicates only the tower's five scene-owned architectural material families: concrete, steel, pink paint, pipe and timber. Two 128-pixel mipmapped textures provide modest grayscale variation and normal detail via triplanar mapping. Authored artifact materials and semantic hues are not edited. Switching to baseline restores the original material references. A first registration scan was made linear with an instance-ID set; later streaming inspects only changed floor content, rather than repeatedly searching the whole tower.

The current floor records identify Rotation at 16, Colour Flashlight at 30 and the wheel machines at 63 (the machines were historically floor 59). No map, placement, dimension, collision, source artifact, catalogue entry or editor arrangement was changed. Both runner receipts hash rooms.json, layout.json and catalog.json and confirm they are unchanged.

## Measurements

Mean frame intervals in milliseconds, two 3-second samples per stage, reversed order on the second pass. RTX 3070, 1600 x 1000, 4x MSAA, uncapped, no fixed-fps simulation. The native game's live artifact workload and normal nine-floor residency window are retained. Startup, shader compilation and screenshot readback are outside the timed samples. Short desktop intervals are sensitive to background tasks; these are exploratory comparisons, not sustained-performance guarantees.

| Renderer / device | Floor | Baseline ms | Light ms | Finish ms |
|---|---:|---:|---:|---:|
'''+ '\n'.join(summary)+'''

The HTML sheet additionally shows per-pass p95, viewport GPU times and end-sample draw counts. Viewport GPU time is not total GPU utilization or compositor time. Live animation and changed directional-shadow culling can change counts without any scene geometry change. Mobile here means the renderer on this PC; those timings are not Quest results and should not be used to predict headset frame rate.

## Evidence and scope

- Forward+ and Mobile each pass 14 checks: the actual authored floors load, geometry/collider poses stay fixed across photo stages, camera and residency remain fixed, baseline disables the fill and restores material references. There are 18 timed segments and nine captures per renderer. Motion/physics are paused only for each matched screenshot triplet, then restored before measurement. Animation phases can differ between the two separate renderer runs.
- Eight additional native checks pass for the actual launch flag, a single controller, unchanged source material, real dispatched F8 events, tone-map/material restoration and cycling back to finish.
- Both native logs have no engine errors. Existing Jolt solver-bias and source painting-viewport anchor warnings remain disclosed in the logs; they were not repaired during this visual pass.
- Source receipts, logs, checks and native captures: `doc/ports/2026-10-27-void-visual-profiles/`.
- Side-by-side reading sheet: `doc/book/iterations/2026-10-27-void-visual-profiles/index.html`. No JavaScript is needed; lighting-only stages use native HTML details controls. The page is verified in the in-app browser.

## Visual judgement

The machine area benefits most: directional shadows and a less uniform structural finish locate objects on the floor and distinguish the supporting cubes and wedges. Rotation's capsule silhouettes and surrounding surfaces read more clearly, while its existing large labels and sharp un-bevelled teaching cubes remain. The colour room's warm wash is less bright; the darker neighbouring exit is a tradeoff to review. Materials are intentionally a small second step. This is a candidate profile, not a declaration that every hall now looks better. It is not enabled as the default.

Quest 3 was detected over USB but asleep. Palle selected “Do desktop now; defer Quest testing.” Stereo frame budget, on-device shader/material cost, thermals and headset readability remain unverified. No headset session or app was changed. The future Quest pass should warm the same views, measure stereo CPU/GPU/compositor timing at the real render resolution and refresh rate, and check sustained behaviour and moving-head readability.
'''
(ROOT/'doc/reports/2026-10-27-void-visual-profiles.md').write_text(report,encoding='utf8')
print(OUT/'index.html')
