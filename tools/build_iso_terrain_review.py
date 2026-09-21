from pathlib import Path
import json, hashlib, shutil, re, markdown

R = Path.cwd()
O = R / 'doc/research/possible-bodies'
E = R / 'doc/space/iso-flat-terrain-2026-09-15'
run = R / 'ada_run/iso-flat-terrain-review-2026-09-15'
M = 'ISO_FlatTerrain'
r = json.loads((run / 'run.json').read_text())
assert r['exit'] == 0 and r['sources_unchanged']
assert all(hashlib.sha256((R / p).read_bytes()).hexdigest() == h for p, h in r['source_sha256'].items())

css = re.search(r'<style>(.*?)</style>', (O / 'iso-introduction.html').read_text(), re.S)[1]
assets = ['iso-learning-arc.md', 'iso-learning-arc.html', 'spine-iteration.md', 'spine-iteration.html']
figures = ''
for name in ['entrance', 'encounter', 'specimen', 'overview']:
    out = f'iso-flat-terrain-{name}.png'
    shutil.copyfile(run / M / f'{name}.png', O / out)
    assets.append(out)
    figures += f'<figure><img src="{out}" alt="Actual Godot Flat Terrain hall: {name}" loading="lazy"><figcaption>Actual Godot museum capture · {name}. Desktop review; headset review remains pending.</figcaption></figure>'

links = []
for kind in ['final', 'technical', 'critical']:
    for before in [False, True]:
        p = (E / 'before' if before else R) / f'commons/maps/{M}/{kind}.md'
        if p.exists():
            out = 'iso-flat-terrain-' + ('previous-' if before else '') + kind + '.md'
            shutil.copyfile(p, O / out)
            assets.append(out)
            links.append(f'<a href="{out}">{"Previous" if before else "Current"} {kind}</a>')

for src, name in [(run / 'run.json', 'receipt.json'), (run / M / 'probe_ca_edge_live.json', 'runtime-report.json'), (run / M / 'engine.log', 'engine.log')]:
    shutil.copyfile(src, E / name)
shutil.copyfile(run / 'run.json', O / 'iso-flat-terrain-verification.json')
assets.append('iso-flat-terrain-verification.json')

book_text = (R / f'commons/maps/{M}/final.md').read_text(encoding='utf-8')
body = '<p class="date">Isosurfaces · Hall 6 · 15 September 2026</p><h1>Look beneath the height</h1><p class="lead">One height per place is a rule. A volume can fold that rule into an interior.</p><p>The hall keeps the two original GPU landscapes visible as a pair. INTERIOR adds a three-dimensional contribution to the turquoise height field; TERMS accumulates the amber field’s overhang, cave, arch and outcrop terms. HOLD keeps the first surface behind the live one, while COLUMN marks crossings on a fixed 25 × 25 sample lattice.</p><p><a href="/necklace/thread?map=ISO_FlatTerrain&role=primary">Primary artifacts and book</a> · <a href="iso-learning-arc.html">Learning arc</a></p><details><summary>Read the book passage</summary>' + markdown.markdown(book_text, extensions=['fenced_code']) + '</details>' + figures + '<h2>The boundary is a choice</h2><p>A height field can vary without changing its contract: each horizontal position gets one height. The volumetric term changes that contract. A marked column can leave solid, enter air, and meet solid again. The counter makes the difference inspectable, while its finite sample keeps the claim honest.</p><p>The retained CPU terrain and rhizome specimen stay in the rear aisle as earlier and later ways to ask the same question. The two primary landscapes carry the book argument; the preserved collection gives the comparison a history.</p><p>' + str(r['checks']) + ' rendered desktop checks passed, including real pointer presses, field rebuilds, held-surface preservation, mesh-crossing changes and onward walking. The receipt records a renderer shutdown diagnostic for one generated mesh; it did not affect the checks. These checks do not certify a human headset session or Quest performance.</p><p><a href="iso-flat-terrain-verification.json">Runtime receipt</a></p><p>' + ' · '.join(links) + '</p><p>Next: <strong>ISO_Caves</strong> — when a volume has an opening, what makes it a route?</p>'

(O / 'iso-flat-terrain.html').write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Look beneath the height · Ada Research</title><style>' + css + '</style><main><nav><a href="iso-introduction.html">Introduction</a><a href="iso-learning-arc.html">Learning arc</a><a href="/museum-progress?sequence=isosurfaces">Museum progress</a></nav>' + body + '</main></html>', encoding='utf-8')
assets.append('iso-flat-terrain.html')
manifest = ['possible-bodies/' + a for a in assets]
(E / 'publish-targets.json').write_text(json.dumps(manifest, indent=2))
(E / 'publish-hashes.json').write_text(json.dumps({a: hashlib.sha256((R / 'doc/research' / a).read_bytes()).hexdigest() for a in manifest}, indent=2))
print('Built', len(assets), 'verified FlatTerrain review assets.')
