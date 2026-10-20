"""Publish native museum evidence for the seven selectable Jacquard samples, including optical checks."""
from pathlib import Path
import hashlib
import html
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-10-optical-woven-checks'
SAMPLES = [
    ('stripes', 'Stripes', 'Change the width of a band.',
     'Plain weave', 'Unequal dark and pale warp bands; cream weft.',
     'The lift stays one over, one under. Adjacent warp threads of the same colour make a wider stripe.'),
    ('checks', 'Checks', 'Repeat colour in two directions.',
     'Plain weave', 'Three navy, three cream in both warp and weft.',
     'The crossing rule is unchanged from Stripes. Where the two colour sequences meet, a check appears.'),
    ('tartan', 'Tartan', 'A colour sequence meets a diagonal.',
     '2/2 twill', 'The same authored twelve-thread sett in both directions.',
     'Two over, two under, shifted each pass. The matched colour bands cross this twill structure. This is a teaching sett, not a named historical tartan.'),
    ('chevron', 'Chevron', 'Follow the turn.',
     'Pointed, reversing twill', 'Cream warp; navy weft.',
     'The direction of the twill reverses at a point. Follow a diagonal into its returning direction.'),
    ('herringbone', 'Herringbone', 'Find the break in the turn.',
     'Broken, reversing twill', 'Cream warp; navy weft.',
     'The diagonal reverses with an offset. Compare its junction with Chevron while keeping the yarn colours the same.'),
    ('houndstooth', 'Houndstooth', 'Where does the tooth begin?',
     '2/2 twill', 'Four dark, four cream in both warp and weft.',
     'The colour period is eight threads; the lift repeats every four. These continue independently across the twelve-hook sections of the loom.'),
    ('optical', 'Optical checks', 'A flat cloth suggests depth.',
     '2/2 twill', 'Burgundy and cream bands: 8, 5, 3, 2, 1, 1, 2, 3, 5, 8 threads.',
     'The band widths contract, then expand. The same sequence crosses itself in warp and weft. This is an authored colour-and-weave study inspired by the supplied photographs, not a verified reconstruction of their weave draft or catalogue design.'),
]


def main():
    receipts = {}
    for name in ['tests', 'sample-tests', 'museum-tests']:
        receipts[name] = json.loads((OUT / (name + '.json')).read_text(encoding='utf-8'))
        assert receipts[name]['passed'] and all(c['passed'] for c in receipts[name]['checks']), name
    count = sum(len(r['checks']) for r in receipts.values())
    for key, *_ in SAMPLES:
        for view in ['cloth', 'layers']:
            assert (OUT / f'{key}-{view}.png').is_file()
    files = [p for p in (ROOT / 'commons/artifacts/jacquard_weaver').iterdir()
             if p.suffix in ['.gd', '.tscn', '.gdshader', '.md']]
    files += [ROOT / p for p in [
        'commons/artifacts/registry/jacquard_weaver.json',
        'tools/probes/jacquard_weaver_test.gd', 'tools/probes/jacquard_samples_test.gd',
        'tools/probes/jacquard_museum_test.gd', 'tools/run_jacquard_review.py',
        'tools/publish_jacquard_optical.py']]
    hashes = {}
    for p in files:
        rel = p.relative_to(ROOT)
        dest = OUT / 'source' / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(p, dest)
        hashes[rel.as_posix()] = hashlib.sha256(p.read_bytes()).hexdigest()
    (OUT / 'source-hashes.json').write_text(json.dumps(hashes, indent=2) + '\n', encoding='utf-8')
    cards = []
    for i, (key, title, question, structure, colours, explanation) in enumerate(SAMPLES):
        cards.append(f'''<article id="{key}" class="sample">
          <div class="sample-title"><span class="number">0{i+1}</span><div><h2>{title}</h2><p>{question}</p></div></div>
          <div class="image-switch"><input class="display-mode choice-flat" type="radio" name="view-{key}" id="cloth-{key}" checked aria-label="Cloth for {title}"><input class="display-mode choice-open" type="radio" name="view-{key}" id="layers-{key}" aria-label="Open layers for {title}"><a class="view cloth" href="{key}-cloth.png"><img src="{key}-cloth.png" loading="lazy" alt="{title}: dense woven cloth in the actual museum"></a>
          <a class="view layers" href="{key}-layers.png"><img src="{key}-layers.png" loading="lazy" alt="{title}: the same recorded threads opened into three dimensions"></a>
          <div class="tabs" role="group" aria-label="View {title}"><label class="flat-label" for="cloth-{key}">Cloth</label><label class="open-label" for="layers-{key}">Open layers</label></div></div>
          <div class="sample-copy"><p>{explanation}</p><dl><dt>Crossings</dt><dd>{structure}</dd><dt>Yarns</dt><dd>{colours}</dd></dl></div></article>''')
    nav = ''.join(f'<a href="#{s[0]}">{s[1]}</a>' for s in SAMPLES)
    report = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
      <title>Optical checks · Endless Museum</title><style>
      :root{--paper:#f3efe5;--ink:#272932;--soft:#68685e;--line:#d0cabc;--accent:#8b493b}*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:2rem}body{margin:0;background:var(--paper);color:var(--ink);font-family:system-ui,sans-serif;line-height:1.55}a{color:inherit;text-underline-offset:4px}header,main,footer{max-width:1420px;margin:auto;padding:32px 5vw}header{padding-top:64px}.eyebrow{font-size:12px;letter-spacing:.16em;text-transform:uppercase;color:var(--soft)}h1,h2{font-family:Georgia,serif;font-weight:400;line-height:1.07}h1{font-size:clamp(42px,6vw,86px);max-width:850px;margin:24px 0}h2{font-size:34px;margin:0}.intro{font-size:20px;max-width:760px;margin:0}.location{font-size:14px;margin-top:24px;color:var(--soft)}nav{display:flex;flex-wrap:wrap;gap:9px;margin:28px 0 0}nav a{border:1px solid var(--line);padding:7px 15px;text-decoration:none;border-radius:24px}nav a:hover{background:#e2dccd}figure{margin:0}img{display:block;width:100%;height:auto}figcaption{font-size:13px;color:var(--soft);padding:12px 0}.hero{border-top:1px solid var(--line);padding-top:26px}.instructions{display:grid;grid-template-columns:repeat(3,1fr);gap:30px;padding:28px 0 45px}.instructions strong{display:block;margin-bottom:8px}.instructions p{margin:0;color:var(--soft)}.gallery{display:grid;grid-template-columns:1fr 1fr;gap:32px 26px}.sample#optical{grid-column:1 / -1;display:grid;grid-template-columns:1fr 1fr}.sample#optical .sample-title{grid-column:1 / -1}.sample#optical .sample-copy{padding-top:15px}.sample{border:1px solid var(--line);background:#fbf8f0;scroll-margin-top:30px}.sample-title{display:flex;gap:18px;padding:23px}.sample-title p{margin:8px 0 0;color:var(--soft)}.number{font-size:13px;color:var(--accent);margin-top:6px}.image-switch{position:relative}.display-mode{position:absolute;opacity:0;width:1px;height:1px}.view.layers{display:none}.choice-open:checked~.view.cloth{display:none}.choice-open:checked~.view.layers{display:block}.view img{aspect-ratio:3/2;object-fit:cover}.tabs{position:absolute;bottom:14px;left:14px;display:flex;border:1px solid #d9d5cb;background:var(--paper);border-radius:5px;overflow:hidden}.tabs label{font:inherit;font-size:13px;border:0;padding:10px 14px;cursor:pointer;color:var(--ink);background:var(--paper)}.choice-flat:checked~.tabs .flat-label,.choice-open:checked~.tabs .open-label{background:var(--ink);color:white}.choice-flat:focus-visible~.tabs .flat-label,.choice-open:focus-visible~.tabs .open-label{outline:3px solid #ef91a5;outline-offset:-3px}.sample-copy{padding:4px 23px 23px}.sample-copy p{min-height:75px}dl{display:grid;grid-template-columns:78px 1fr;gap:8px;font-size:14px;border-top:1px solid var(--line);padding-top:15px}dt{color:var(--soft)}dd{margin:0}.evidence{margin-top:48px;padding:32px;background:#e8e3d6}.evidence h2{font-size:30px}.evidence p{max-width:900px}.evidence a{display:inline-block;margin-right:20px}footer{font-size:13px;color:var(--soft);border-top:1px solid var(--line)}[hidden]{display:none!important}@media(max-width:800px){header{padding-top:34px}.instructions,.gallery,.sample#optical{grid-template-columns:1fr}.sample-copy p{min-height:0}.instructions{gap:20px}}@media print{nav,.tabs{display:none}.view.layers,.view.cloth{display:block!important}.gallery{grid-template-columns:1fr 1fr}.sample{break-inside:avoid}.hero{max-width:700px}}
      </style></head><body><header><div class="eyebrow">Endless Museum · Tiling · 10 October 2026</div>
      <h1>A flat cloth.<br>An apparent fold.</h1><p class="intro">Wide bands narrow to a thread, then widen again. Try the new OPTICAL CHECKS button beside the six existing patterns. Open the cloth to inspect the actual yarns. These are captures from the running museum.</p>
      <p class="location">Find it in <strong>Tiling → Symmetry Seventeen → Cards become cloth</strong>.</p><nav>''' + nav + '''</nav></header><main>
      <figure class="hero"><a href="optical-top.png"><img src="optical-top.png" alt="Top view of graduated burgundy and cream woven checks"></a><figcaption>Optical checks: actual yarn geometry, flat except for the over/under crossings. The perceived depth is a visual reading of changing band widths.</figcaption></figure>
      <p style="max-width:850px">Naming: <strong>Optical checks</strong> is a descriptive working title. The exact manufacturer's name and weave draft of the photographed fabric have not been established. The original shows stronger alternating face blocks; this version studies the effect through graduated yarn colours in 2/2 twill. It is therefore a related construction, not a facsimile.</p>
      <figure class="hero"><a href="optical-museum.png"><img src="optical-museum.png" alt="The Jacquard loom and its linked layer table inside Symmetry Seventeen"></a><figcaption>Native Godot capture: the hanging card chain, loom, seven sample buttons and opened optical checks.</figcaption></figure>
      <div class="instructions"><div><strong>1 / Choose</strong><p>The seven buttons on the front of the inspection table load a fresh 96-pick sample. Each sets the card lifts and yarn colours.</p></div><div><strong>2 / Open</strong><p>Press LAYERS or pull the pink slider. FLAT closes the same cloth. The diagram below keeps its top-thread pattern visible.</p></div><div><strong>3 / Watch it grow</strong><p>On the loom, press CLEAR CLOTH, then ONE PICK or RUN. The selected cards and colours stay in place; the chain makes the sample one pass at a time.</p></div></div>
      <div class="gallery">''' + '\n'.join(cards) + f'''</div>
      <section class="evidence"><h2>Checked in the running museum</h2><p><strong>{count} automated checks passed</strong>: loom, seven samples and the installed museum pair. For every sample, the tests inspect all 9,216 over/under crossings and diagram colours; they also compare sixteen animated picks with the same batch-generated record.</p>
      <p>Opening and closing keeps the same mesh and history. Card and colour edits retain previous picks; choosing a named sample explicitly replaces the cloth. Houndstooth's eight-thread colour sequence continues correctly across each twelve-hook section.</p>
      <p>The tests include simulated XR interaction and clear standing approaches. A physical headset playthrough is still needed to judge reach and comfort. The opening is an inspection transform; yarn tension and cloth physics are not simulated.</p>
      <p><a href="optical-player.png">Player view</a><a href="tests.json">Loom checks</a><a href="sample-tests.json">Sample checks</a><a href="museum-tests.json">Museum checks</a><a href="source/commons/artifacts/jacquard_weaver/README.md">Artifact guide</a><a href="source-hashes.json">Source snapshot</a></p></section>
      </main><footer>Native captures, no generated replacement images. Pattern context: <a href="https://www.designpoolpatterns.com/plaids-and-checks-do-you-know-the-difference/">Design Pool · Checks and optical distortion</a>. Weave references: <a href="https://cottonworks.com/wp-content/uploads/2023/03/Weaving-101.pdf">CottonWorks · Weaving 101</a>; <a href="https://www.datocms-assets.com/75077/1687814092-hwnd13.pdf">Handwoven · November/December 2013</a>. The tartan is an authored teaching sett.</footer>
</body></html>'''
    (OUT / 'index.html').write_text(report, encoding='utf-8')
    print(f'Published {OUT / "index.html"}; {count} checks passed')


if __name__ == '__main__':
    main()
