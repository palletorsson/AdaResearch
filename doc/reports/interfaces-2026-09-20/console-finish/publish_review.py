"""Publish inspected real renders, comparison evidence and shared-profile usage."""
from pathlib import Path
import difflib
import hashlib
import json
import re
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
DEST = ROOT / 'doc/book/iterations/2026-09-20-interface-finish-review'
PREVIOUS = ROOT / 'doc/book/iterations/2026-09-20-interface-console-review/index.html'


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def publish():
    before = read(HERE / 'before/runtime/report.json')
    after = read(HERE / 'after/runtime/report.json')
    checks = [read(HERE / name) for name in ('console-regression.json', 'layout-checks.json', 'instrument-checks.json')]
    assert all(not report['failures'] for report in [before, after] + checks)
    DEST.mkdir(parents=True, exist_ok=True)
    for variant in ('before', 'after'):
        for shot in ('approach', 'controls'):
            shutil.copy2(HERE / variant / 'runtime' / f'{shot}.png', DEST / f'{variant}-{shot}.png')
        shutil.copy2(HERE / variant / 'runtime/report.json', DEST / f'{variant}-runtime.json')
    for name in ('reference-braun.png', 'reference-black_mesa.png', 'console-regression.json', 'layout-checks.json', 'instrument-checks.json'):
        shutil.copy2(HERE / name, DEST / name)

    changed = ['commons/ui/control_panel.gd', 'commons/ui/interface_presets.gd',
               'commons/interactables/slider_smooth.gd', 'commons/interactables/dial_smooth.gd',
               'commons/interactables/InteractableDemo.gd',
               'commons/artifacts/qfep_balance_workbench/qfep_balance_workbench.gd']
    added = ['commons/ui/control_value_surface.gd', 'commons/ui/interface_reference_console.gd',
             'commons/interactables/interactable_console_demo.tscn', 'commons/testing/test_instrument_console.gd']
    changes, hashes = [], {}
    for relative in changed + added:
        current = ROOT / relative
        old = HERE / 'before' / Path(relative).name
        old_text = old.read_text(encoding='utf-8') if relative in changed else ''
        changes.extend(difflib.unified_diff(old_text.splitlines(True), current.read_text(encoding='utf-8').splitlines(True),
                                          fromfile='before/' + relative, tofile=relative))
        hashes[relative] = {'before': hashlib.sha256(old.read_bytes()).hexdigest() if relative in changed else None,
                            'after': hashlib.sha256(current.read_bytes()).hexdigest()}
    for folder in (HERE, DEST):
        (folder / 'changes.diff').write_text(''.join(changes), encoding='utf-8')
        (folder / 'source-hashes.json').write_text(json.dumps(hashes, indent=2), encoding='utf-8')

    css = re.search(r'<style>(.*?)</style>', PREVIOUS.read_text(encoding='utf-8'), re.S).group(1)
    old_h, new_h = before['console']['head_size'][1], after['console']['head_size'][1]
    page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>The console, close up · Ada Research</title><style>{css}
.hero-image img{{width:100%;height:auto;display:block}}.hero-image{{margin:0}}.zoom-note{{font-size:.9rem;color:#496c63}}
.pair img{{object-fit:contain}}pre{{overflow-x:auto}}.comparison>input{{accent-color:#234e42;margin:1rem .4rem 1rem 1rem}}.comparison>label{{display:inline-block;border:1px solid #315d50;border-radius:30px;padding:.65rem 1.2rem;cursor:pointer}}
.comparison>input:checked+label{{background:#234e42;color:white}}.comparison .before-view{{display:none}}#view-before:checked~.before-view{{display:block}}#view-before:checked~.after-view{{display:none}}.comparison figcaption{{padding:1rem 0}}
</style></head><body><header><div class="eyebrow">Ada Research · interface refinement · 20 September 2026</div>
<h1>The console,<br>close up.</h1><p class="lead">Larger values. A tighter casing. Every control has a place on the face. The same construction now works for a second instrument.</p>
<p><a href="../2026-09-20-interface-console-review/index.html">Previous console pass</a> · <a href="/book?map=QFEP_Introduction&amp;section=final">QFEP Introduction</a> · <a href="#reference">Working reference</a></p>
<div class="metrics"><div class="metric"><strong>{old_h*100:.1f} → {new_h*100:.1f} cm</strong><span>Casing length along the sloping face</span></div><div class="metric"><strong>52 → 78 mm</strong><span>Individual value-window width</span></div><div class="metric"><strong>14 cm</strong><span>Physical slider travel retained</span></div></div></header><main>
<section><h2>Inspect the face</h2><p>Same museum placement, camera position and comparison values. The lens is now closer: 42° field of view. Select before or after, or open the image at full size.</p>
<div class="comparison" role="group" aria-label="Console comparison">
<input type="radio" name="view" id="view-after" checked><label for="view-after">After refinement</label>
<input type="radio" name="view" id="view-before"><label for="view-before">Before refinement</label>
<figure class="hero-image after-view"><a href="after-controls.png"><img src="after-controls.png" alt="Refined QFEP console with larger values, grouped wells and a slim casing" width="1800" height="1200"></a><figcaption>After: four full-size rails and KEEP. Values, labels and controls occupy clearly grouped areas.</figcaption></figure>
<figure class="hero-image before-view"><a href="before-controls.png"><img src="before-controls.png" alt="Original console with a broad top border and smaller numeric windows" width="1800" height="1200"></a><figcaption>Before: a broad top border, smaller numeric windows and widely separated labels.</figcaption></figure></div>
<p class="zoom-note">Actual Godot museum renders. These images show the built console, not a design mock-up.</p></section>
<section><h2>What improved</h2><p>The empty top border is removed. A slim frame and four flush fasteners attach the face to its housing. Printed labels sit closer to their controls, within subtle shaded wells. The value windows use larger type, and their backing clears the slider handle at every position.</p><p>F, E(S), λ, φ and KEEP still perform the same experiment. The retained total and comparison remain visible. The design makes their relationship easier to follow.</p>
<figure><a href="after-approach.png"><img src="after-approach.png" alt="Refined console seen with the QFEP apparatus from the approach" width="1800" height="1200"></a><figcaption>The console remains part of its room. Neighbouring screens and the object it changes must also be considered from the operating position.</figcaption></figure></section>
<section id="reference"><h2>One principle, different instruments</h2><p>The focused reference console combines a slider, dial, joystick and RESET. Size, rotation and position change the orange body. The two joystick axes appear in the same flat summary screen. Every visible caption and value on the console is 2D text carried by a surface in 3D.</p>
<div class="pair"><figure><a href="reference-braun.png"><img src="reference-braun.png" alt="Working reference console in the light Braun finish" width="1500" height="1300"></a><figcaption>Light finish. Two columns, full-size controls, a specimen above the readout.</figcaption></figure><figure><a href="reference-black_mesa.png"><img src="reference-black_mesa.png" alt="The same working reference in a dark finish" width="1500" height="1300"></a><figcaption>Dark finish. The same construction and actions with different housing and label colours.</figcaption></figure></div>
<p>The first reference capture revealed a mistake: the specimen platform hid the readout. Moving the platform back and up restored both views. An interaction test can pass while the spatial arrangement still needs work.</p></section>
<section><h2>Reuse it in the project</h2><pre><code>var console = InterfacePresets.build(
    "workbench", "Your instrument", plate_height,
    "braun", "instrument"
)
# Set the grouping before adding controls.
console.panel().layout_columns = 2
add_child(console)
var size = console.add_slider("SIZE")
var turn = console.add_dial("TURN")
var position = console.add_joystick("POSITION")
var reset = console.add_button("RESET")</code></pre>
<p>The <code>instrument</code> layout fits the casing to unscaled controls. It defaults to three columns; this reference uses two. The existing full sampler remains available. Enable <code>reference_console</code> on InteractableDemo, or use <code>commons/interactables/interactable_console_demo.tscn</code>, for the focused example.</p><p>This profile applies to console housings. Other housing forms and bespoke controls still need their own inspection. Adopt it per encounter, preserving the actions and comparisons that matter.</p></section>
<section><h2>Checked, and still to check</h2><ul><li><a href="console-regression.json">{checks[0]['checks']} console regression checks</a>: existing layouts, three mounting forms, scale, travel, pointer input and values.</li>
<li><a href="layout-checks.json">{checks[1]['checks']} shared panel checks</a>: row layout, input and backing.</li><li><a href="instrument-checks.json">{checks[2]['checks']} working-reference checks</a>: two finishes, mixed controls, their actual effects, RESET and value-window clearance.</li><li><a href="after-runtime.json">{len(after['checks'])} QFEP encounter checks and {len(after['walks'])} selected walks</a>: KEEP, equal totals with different tuples, dependencies, rebuilds and access.</li></ul>
<p>Headset legibility, seated reach, tracked-hand operation and Quest performance remain to be tested. Other QFEP workbench placements inherit the style, but only this hall received the museum capture and walk pass.</p>
<p><a href="before-runtime.json">Before measurements</a> · <a href="changes.diff">Exact source changes</a> · <a href="source-hashes.json">Source hashes</a></p></section>
</main><footer>Shared profile and working reference implemented · Desktop verification complete · Headset checks pending</footer>
</body></html>'''
    (DEST / 'index.html').write_text(page, encoding='utf-8')
    old_page = PREVIOUS.read_text(encoding='utf-8')
    link = '<p><a href="../2026-09-20-interface-finish-review/index.html">Continue: zoom into the refined console and its working reference.</a></p>'
    if link not in old_page:
        PREVIOUS.write_text(old_page.replace('<footer>', '<footer>' + link), encoding='utf-8')
    print(DEST / 'index.html')


if __name__ == '__main__':
    publish()
