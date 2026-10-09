"""Publish console captures and their measured evidence through the book-review route."""
from pathlib import Path
import difflib, hashlib, json, re, shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
DEST = ROOT/'doc/book/iterations/2026-09-20-interface-console-review'
previous = ROOT/'doc/book/iterations/2026-09-20-interface-compact-review/index.html'


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def publish():
    before = read(HERE/'before/runtime/report.json')
    after = read(HERE/'after/runtime/report.json')
    checks = read(HERE/'console-checks.json')
    assert not before['failures'] and not after['failures'] and not checks['failures']
    DEST.mkdir(parents=True, exist_ok=True)
    for variant in ('before','after'):
        for shot in ('approach','controls'):
            shutil.copy2(HERE/variant/'runtime'/f'{shot}.png', DEST/f'{variant}-{shot}.png')
        shutil.copy2(HERE/variant/'runtime/report.json', DEST/f'{variant}-runtime.json')
    for name in ('console-checks.json','placements.json'):
        shutil.copy2(HERE/name, DEST/name)
    changes=[]
    hashes={}
    for relative in ('commons/ui/control_console.gd','commons/ui/interface_presets.gd',
                     'commons/ui/control_panel.gd','commons/interactables/slider_smooth.gd',
                     'commons/artifacts/qfep_balance_workbench/qfep_balance_workbench.gd'):
        old=HERE/'before'/Path(relative).name
        new=ROOT/relative
        changes.extend(difflib.unified_diff(old.read_text(encoding='utf-8').splitlines(True),new.read_text(encoding='utf-8').splitlines(True),fromfile='before/'+relative,tofile=relative))
        hashes[relative]={'before':hashlib.sha256(old.read_bytes()).hexdigest(),'after':hashlib.sha256(new.read_bytes()).hexdigest()}
    for folder in (HERE,DEST):
        (folder/'changes.diff').write_text(''.join(changes),encoding='utf-8')
        (folder/'source-hashes.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')
    css=re.search(r'<style>(.*?)</style>',previous.read_text(encoding='utf-8'),re.S).group(1)
    old_scale=before['console']['panel_scale'][0]
    casing=after['console']['head_size'][0]
    pair=lambda shot,a,b: f'''<div class="pair"><figure><a href="before-{shot}.png"><img src="before-{shot}.png" alt="{a}" width="1800" height="1200"></a><figcaption><strong>Before.</strong> {a}</figcaption></figure><figure><a href="after-{shot}.png"><img src="after-{shot}.png" alt="{b}" width="1800" height="1200"></a><figcaption><strong>After.</strong> {b}</figcaption></figure></div>'''
    page=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A casing for the controls · Ada Research</title><style>{css}</style></head>
<body><header><div class="eyebrow">Ada Research · second interface pilot · 20 September 2026</div>
<h1>A casing for<br>the controls.</h1>
<p class="lead">QFEP Introduction keeps its four quantities and KEEP comparison. Its console now gives the controls room to retain their authored size.</p>
<p><a href="../2026-09-20-interface-compact-review/index.html">First pilot: Pattern Foundry</a> · <a href="../2026-09-19-review-comparison/index.html#qfeplaboratory">The encounter review</a> · <a href="/book?map=QFEP_Introduction&amp;section=final">The chapter</a></p>
<div class="metrics"><div class="metric"><strong>{old_scale*100:.0f}% → 100%</strong><span>Control scale in this placement</span></div><div class="metric"><strong>{old_scale*14:.1f} → 14 cm</strong><span>Slider travel in world space</span></div><div class="metric"><strong>5 → 5</strong><span>Four rails and KEEP retained</span></div></div></header><main>
{pair('approach','A 0.70 m casing compresses the whole panel, including its handles and labels.',f'Three controls above two. A {casing:.2f} m casing fits the unscaled controls and their backing.')}
<p class="note">Real Godot museum renders, matched camera poses and input tuples. The before and after preparation recorded matching hall and plan input hashes. Headset comfort is not established by these images.</p>
<section><h2>Keep the distinction the room teaches</h2><p>Two arrangements can produce the same total. The first capture keeps F=0.4, E=0.2, lambda=0.5, phi=0.5. The closer capture changes F to 0.6 and E to 0.6. Both give 0.450. The pale outline retains the first arrangement, while the live shape changes.</p><p>The four rails, their zero-to-one ranges, the fixed change term and KEEP remain. The manuscript and map configuration were not edited.</p>
{pair('controls','The original controls in the closer operating view.','Full-size rails with live 2D value screens seated on their frames. The same kept reading remains.')}
<p>The wider housing is a deliberate tradeoff. Wrapping limits its width while preserving the controls. The lower row and the neighbouring detail screen still need checking from seated and standing headset positions.</p></section>
<section><h2>A reusable console option</h2><pre><code>InterfacePresets.build(
    "workbench", "QFEP Balance", plate_height,
    "braun", "compact"
)</code></pre><p>The optional compact preset uses three columns with closer spacing. The shared console sizes its casing around the panel instead of rescaling the input geometry. Default callers retain their existing layout. Explicit scale applied by an artifact or map still affects world dimensions and must be checked at that placement.</p><p>Compact faders replace their old value label with a small 128×48 2D screen. It redraws when its formatted value changes. The existing value, range, formatting and signal path are preserved. Other slider placements and dial/joystick values remain migration work.</p></section>
<section><h2>Evidence and scope</h2><ul>
<li><a href="console-checks.json">{checks['checks']} console checks pass</a>: legacy and compact layouts, kiosk/lectern/wall mounting, casing coverage, unscaled controls, 14 cm travel, forward/backward pointer motion, button events and live 2D values.</li>
<li><a href="after-runtime.json">{len(after['checks'])} encounter checks and {len(after['walks'])} selected collision-body walks pass</a>: KEEP, different tuples with equal totals, zero-lambda dependency, configuration rebuilds, approach, passage and exit.</li>
<li><a href="before-runtime.json">Original runtime measurements</a>, <a href="changes.diff">exact source changes</a> and <a href="source-hashes.json">source hashes</a> are retained.</li>
<li><a href="placements.json">Ten map files place this workbench</a>, including trial layouts. This pass verified its assembly in QFEP Introduction; the others still need a spatial review.</li></ul>
<p class="note">Direct pointer-handler calls and selected desktop walks do not establish tracked-hand operation, seated reach, headset legibility or Quest performance. Existing UID/certificate, shader-cache and unrelated scene warnings remain. The live museum was not restarted and its bake was not replaced.</p></section>
<section><h2>What comes next</h2><p>Bring this compact console into the interface reference demo, then migrate dial and joystick values onto their supporting surfaces. The next spatial pass should also examine large neighbouring displays: the control and the thing it changes need to remain visible together.</p></section>
</main><footer>Shared console option implemented · QFEP Introduction captured and checked · Headset verification pending</footer></body></html>'''
    (DEST/'index.html').write_text(page,encoding='utf-8')
    # Add a forward link without regenerating the earlier pilot's evidence.
    old=previous.read_text(encoding='utf-8')
    link='<p><a href="../2026-09-20-interface-console-review/index.html">Continue to the second pilot: a casing for the controls.</a></p>'
    if link not in old:
        previous.write_text(old.replace('<footer>','<footer>'+link),encoding='utf-8')
    print(DEST/'index.html')


if __name__=='__main__': publish()
