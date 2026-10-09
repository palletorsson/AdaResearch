"""Publish the Shannon adoption and independently verified shared fixes."""
from pathlib import Path
import difflib
import hashlib
import json
import re
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
DEST = ROOT / 'doc/book/iterations/2026-09-20-interface-shannon-review'
PREVIOUS = ROOT / 'doc/book/iterations/2026-09-20-interface-finish-review/index.html'


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def publish():
    before = read(HERE / 'before/runtime/report.json')
    after = read(HERE / 'after/runtime/report.json')
    for name in ('control-checks.json', 'console-checks.json', 'layout-checks.json', 'instrument-checks.json'):
        assert not read(HERE / name)['failures'], name
    assert not before['failures'] and not after['failures']
    assert (HERE / 'before/runtime/plan.json').read_bytes() == (HERE / 'after/runtime/plan.json').read_bytes()
    DEST.mkdir(parents=True, exist_ok=True)
    for variant in ('before', 'after'):
        for shot in ('approach', 'controls'):
            shutil.copy2(HERE / variant / 'runtime' / f'{shot}.png', DEST / f'{variant}-{shot}.png')
        for name in ('report.json', 'source_manifest.json'):
            shutil.copy2(HERE / variant / 'runtime' / name, DEST / f'{variant}-{name}')
    for name in ('control-checks.json', 'console-checks.json', 'layout-checks.json', 'instrument-checks.json'):
        shutil.copy2(HERE / name, DEST / name)
    paths = ['commons/ui/control_panel.gd', 'commons/ui/control_console.gd',
             'commons/interactables/push_button.gd', 'commons/interactables/slider_smooth.gd',
             'commons/artifacts/shannon_workbench/shannon_workbench.gd']
    changes, hashes = [], {}
    for relative in paths:
        old = HERE / 'before' / Path(relative).name
        new = ROOT / relative
        changes.extend(difflib.unified_diff(old.read_text(encoding='utf-8').splitlines(True), new.read_text(encoding='utf-8').splitlines(True), fromfile='before/' + relative, tofile=relative))
        hashes[relative] = {'before': hashlib.sha256(old.read_bytes()).hexdigest(), 'after': hashlib.sha256(new.read_bytes()).hexdigest()}
    for folder in (HERE, DEST):
        (folder / 'changes.diff').write_text(''.join(changes), encoding='utf-8')
        (folder / 'source-hashes.json').write_text(json.dumps(hashes, indent=2), encoding='utf-8')
    css = re.search(r'<style>(.*?)</style>', PREVIOUS.read_text(encoding='utf-8'), re.S).group(1)
    scale = before['console']['panel_scale'][0]
    page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The choice stays visible · Ada Research</title><style>{css}</style></head>
<body><header><div class="eyebrow">Ada Research · Shannon workbench · 20 September 2026</div>
<h1>The choice<br>stays visible.</h1><p class="lead">The slider changes the source. The buttons change what we expect of it. The console now makes both actions easier to see and operate.</p>
<p><a href="../2026-09-20-interface-finish-review/index.html">Previous console refinement</a> · <a href="/book?map=QFEP_F_Term&amp;section=final">The chapter</a> · <a href="../2026-09-19-review-comparison/index.html#qfeplaboratory">Encounter review</a></p>
<div class="metrics"><div class="metric"><strong>{scale*100:.0f}% → 100%</strong><span>Physical control scale in this placement</span></div><div class="metric"><strong>{scale*14:.1f} → 14 cm</strong><span>Slider travel</span></div><div class="metric"><strong>70 → 85.2 cm</strong><span>Cabinet width: room for the controls</span></div></div></header><main>
<section><h2>Inspect the operating surface</h2><p>Both captures have p(1)=0.90 and EXPECT 1. Select a view to compare the handle, value window, captions and button state.</p>
<div class="comparison" role="group" aria-label="Console comparison"><input type="radio" name="view" id="view-after" checked><label for="view-after">After refinement</label><input type="radio" name="view" id="view-before"><label for="view-before">Before refinement</label>
<figure class="hero-image after-view"><a href="after-controls.png"><img src="after-controls.png" alt="Full-size Shannon controls with the slider at 0.9 on the right and EXPECT 1 lit cyan" width="1800" height="1200"></a><figcaption>After: the value, handle position and selected predictor agree. Every visible console caption and value is 2D on its supporting surface.</figcaption></figure>
<figure class="hero-image before-view"><a href="before-controls.png"><img src="before-controls.png" alt="Original smaller Shannon controls with identical-looking prediction buttons and a high value at the left end" width="1800" height="1200"></a><figcaption>Before: smaller controls, no persistent choice indication, and a high value at the left end of the rail.</figcaption></figure></div></section>
<section><h2>A visual review found a directional bug</h2><p>The earlier code said that dragging right increased a panel slider. A new check against the actual panel axes showed that the opposite was true. The shared panel now rotates the slider correctly. Its value screen counter-rotates to stay upright and clear of the handle.</p><p>Earlier tests checked range changes and travel distance. They now also check the direction. This repair applies to horizontal sliders created by the shared panel, including the previous pilots. Standalone vertical sliders keep their orientation.</p></section>
<section><h2>Keep the source; change the prediction</h2><p>EXPECT 0 and EXPECT 1 retain the same stored draws and bit colours. They change which cells count as prediction errors. A selected button now stays cyan after release, and the existing monitor also names the active predictor. Pressing the same choice again leaves it selected.</p><p>The shared button exposes <code>set_selected(bool)</code>; its owner decides the selection. Ordinary buttons keep their momentary behaviour. Selection adds feedback without changing the experiment or making every button a toggle.</p>
<figure><a href="after-approach.png"><img src="after-approach.png" alt="Shannon workbench, entropy curve, complete bit grid and prediction error display in the museum" width="1800" height="1200"></a><figcaption>The approach view uses EXPECT 0 at p(1)=0.90. Amber marks show many misses. The source remains the same as in the close-up with EXPECT 1.</figcaption></figure>
<p>The primary monitor's support column previously hid bottom-centre grid cells. Moving the support behind the screen restores those cells. This correction lives in the shared monitor builder.</p></section>
<section><h2>Fit the housing when the lesson expands</h2><p>A single-control Shannon bench can later enable its prediction comparison. Its cabinet now refits around the added buttons while preserving the sample, controls, grid and live readout. This is an explicit structural update; changing a value does not rebuild the cabinet.</p><pre><code># The artifact chooses its profile.
InterfacePresets.build(
    "workbench", "Shannon Entropy", plate_height,
    "braun", "instrument"
)

# Its existing logic determines which choice is active.
expect_zero.set_selected(prediction == 0)
expect_one.set_selected(prediction == 1)

# After adding controls to an assembled console:
console.refit_housing()</code></pre></section>
<section><h2>Evidence and limits</h2><ul><li><a href="control-checks.json">23 Shannon control checks</a>: real pointer handlers, settled travel, direction, selection, source independence, screen clearance and runtime housing expansion.</li>
<li><a href="after-report.json">26 encounter checks and five selected museum walks</a>: source entropy, expected/observed errors, no-sample mode, evidence changes, seeds, passage and exit.</li>
<li><a href="console-checks.json">156 shared console checks</a>, <a href="layout-checks.json">70 panel checks</a> and <a href="instrument-checks.json">46 mixed-reference checks</a> pass after the directional correction.</li></ul>
<p>These are desktop and direct-input-handler checks. Headset readability, seated reach, tracked-hand operation and Quest performance remain open. Only this Shannon museum placement received the full capture and walk pass.</p>
<p>Comparison cameras, input values and the private museum plan match. The global plan changed during other review work, so the final after capture uses the first capture's plan. The live museum was not replaced.</p>
<p><a href="before-report.json">Before measurements</a> · <a href="before-source_manifest.json">Before source manifest</a> · <a href="after-source_manifest.json">After source manifest</a> · <a href="changes.diff">Exact source changes</a> · <a href="source-hashes.json">Source hashes</a></p></section>
<section><h2>Next principle</h2><p>Discrete and spring-return controls. The inventory found stepped and bipolar rack sliders that draw a useful interface but lack working pointer handlers. Their behaviour needs to be made as explicit as their appearance before they become reference examples.</p></section>
</main><footer>Shannon console adopted · Shared direction, choice and support fixes verified · Headset checks pending</footer></body></html>'''
    (DEST / 'index.html').write_text(page, encoding='utf-8')
    prior = PREVIOUS.read_text(encoding='utf-8')
    link = '<p><a href="../2026-09-20-interface-shannon-review/index.html">Continue: Shannon, persistent choices and the slider direction fix.</a></p>'
    if link not in prior:
        PREVIOUS.write_text(prior.replace('<footer>', '<footer>' + link), encoding='utf-8')
    print(DEST / 'index.html')


if __name__ == '__main__':
    publish()
