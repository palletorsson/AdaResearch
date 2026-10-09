"""Save the selected final-text illustrations and their source evidence."""
from pathlib import Path
from hashlib import sha256
from html import escape
import json
import os
import shutil
from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
spec = json.loads((HERE / 'plates.json').read_text(encoding='utf-8'))
selected = json.loads((HERE / 'selected-images.json').read_text(encoding='utf-8'))
records = {p['slug']: p for p in selected['plates']}
assert len(records) == len(spec['plates']), 'A selected illustration is missing.'
tutorial_records = json.loads((HERE.parent / '2026-10-05-tutorial-comic-plates' / 'generated-files.json').read_text(encoding='utf-8'))['files']
tutorial_maps = {p['map'] for p in tutorial_records}
sections = []
facts = []
prompts = ['# Final-text illustration prompts', '', 'Generated with built-in image_gen. The existing Trace comic is a fictional-character and style reference. These pages interpret selected encounters in final.md; they are not runtime captures.', '']

for i, p in enumerate(spec['plates']):
    r = records[p['slug']]
    source = ROOT / p['source']
    source_hash = sha256(source.read_bytes()).hexdigest()
    snapshot = HERE / 'sources' / (p['map'] + '.md')
    assert sha256(snapshot.read_bytes()).hexdigest() == p['source_sha256'], 'Draft source snapshot changed: ' + p['map']
    assert source_hash == p.get('reviewed_current_source_sha256', p['source_sha256']), 'Unreviewed source change: ' + p['map']
    image_path = HERE / (p['slug'] + '.png')
    generated = Path(r['generated_path'])
    if image_path.exists():
        assert image_path.read_bytes() == generated.read_bytes(), 'Do not overwrite an existing image.'
    else:
        shutil.copy2(generated, image_path)
    with Image.open(image_path) as im:
        size = list(im.size)
    inputs = []
    for ref in p.get('references', []):
        ref_path = Path(ref)
        inputs.append(dict(path=os.path.relpath(ref_path, ROOT).replace('\\', '/'),
                           sha256=sha256(ref_path.read_bytes()).hexdigest()))
    facts.append(dict(map=p['map'], source=p['source'], source_sha256=p['source_sha256'],
                      current_source_sha256=source_hash, source_review=p.get('source_review', ''),
                      source_snapshot='sources/' + p['map'] + '.md', image=image_path.name,
                      image_sha256=sha256(image_path.read_bytes()).hexdigest(), dimensions=size,
                      generation_references=inputs,
                      focus=p['focus'], method='Source-grounded interpretive illustration; imagined staging, schematic overlays, no runtime or learning certification.'))
    relative_source = os.path.relpath(source, HERE).replace('\\', '/')
    if p['map'] in tutorial_maps:
        tutorial = '../2026-10-05-tutorial-comic-plates/index.html#' + p['map']
        tutorial_label = 'Companion tutorial illustration'
    else:
        tutorial_source = source.with_name('tutorial.md')
        if not tutorial_source.is_file():
            tutorial_source = source.with_name('technical.md')
        assert tutorial_source.is_file(), 'Missing tutorial or technical reference: ' + p['map']
        tutorial = os.path.relpath(tutorial_source, HERE).replace('\\', '/')
        tutorial_label = 'Read ' + tutorial_source.name
    prev = spec['plates'][max(0, i - 1)]['map']
    next_map = spec['plates'][min(len(spec['plates']) - 1, i + 1)]['map']
    quote = escape(p['footer'])
    excerpts = ''.join('<li>' + escape(caption) + '</li>' for caption, _ in p['panels'])
    source_note = ('<p class="caption">This plate follows the <a href="sources/' + p['map'] + '.md">saved chapter</a>. ' + escape(p['source_review']) + '</p>') if source_hash != p['source_sha256'] or p.get('source_review') else ''
    sections.append(f'''<section class="plate" id="{p['map']}" {'hidden' if i else ''}>
<a class="image-link" href="{image_path.name}"><img src="{image_path.name}" width="{size[0]}" height="{size[1]}" alt="{escape(p['summary'], quote=True)}"></a>
<aside><p class="eyebrow">{i+1:02} / {len(spec['plates']):02} · {escape(p['map'].replace('_', ' '))}</p>
<h2>{escape(p['title'].title())}</h2><p>{escape(p['summary'])}</p><blockquote>{quote}</blockquote>
<p class="links"><a href="{relative_source}">Read final.md</a> · <a href="{tutorial}">{tutorial_label}</a> · <a href="{image_path.name}" download>Download image</a></p>
{source_note}
<div class="prev-next"><button data-map="{prev}" {'disabled' if i == 0 else ''}>← Previous</button><button data-map="{next_map}" {'disabled' if i == len(spec['plates'])-1 else ''}>Next →</button></div>
<details><summary>Passages pictured</summary><ol>{excerpts}</ol></details>
<p class="caption">Selected encounters from the final text. The figures and staging are imagined; dashed marks and cutaways explain relations. These are companion images, not a replacement for the chapter.</p></aside></section>''')
    prompts += ['## ' + p['title'], '', 'Source: `' + p['source'] + '`', '', p['prompt'], '']
    if inputs:
        prompts += ['### Reference files', ''] + ['- `' + ref['path'] + '`' for ref in inputs] + ['']
    for edit in r.get('refinements', []):
        prompts += ['### Targeted refinement', '', edit, '']

groups = {}
for p in spec['plates']:
    groups.setdefault(p.get('sequence', 'primitives'), []).append(p)
sequence_labels = {'array_tutorial': 'Arrays and Regularity', 'color': 'Colour', 'tiling': 'Tiling', 'formfinding': 'Form Finding', 'wavefunctions': 'Wavefunctions', 'randomness': 'Randomness'}
nav = ''.join('<div class="nav-group"><p class="eyebrow">' + escape(sequence_labels.get(name, name.title())) + '</p>' +
              ''.join('<button data-map="' + p['map'] + '">' + escape(p['map'].replace('_', ' ')) + '</button>' for p in group) +
              '</div>' for name, group in groups.items())
description = escape(spec.get('description', 'From Point One through Melencolia, following the poetic and critical thread of final.md. Short passages accompany the pictured encounters; the full chapters remain available beside them.'))
html = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Final-text illustrations · Endless Museum</title><style>
:root{--paper:#f6f3ed;--ink:#292826;--accent:#8c5165;--line:#d7d0c5;color-scheme:light}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:16px/1.65 system-ui,sans-serif}header,main,footer{max-width:1400px;margin:auto;padding:2rem}header{padding-top:3rem}h1{font:normal clamp(2rem,4vw,3rem)/1.1 Georgia,serif;letter-spacing:-.03em;margin:.6rem 0}header>p{max-width:75ch}.eyebrow{font-size:11px;letter-spacing:.14em;text-transform:uppercase;color:var(--accent)}nav{display:flex;gap:.5rem;flex-wrap:wrap;margin-top:1.4rem}button{font:inherit;font-size:.88rem;cursor:pointer;border:1px solid var(--line);background:#fffdf8;border-radius:3px;padding:.55rem .85rem;color:var(--ink)}button[aria-current="true"]{background:var(--ink);color:var(--paper);border-color:var(--ink)}button:disabled{opacity:.4;cursor:default}a{color:var(--accent);text-underline-offset:3px}.plate{display:grid;grid-template-columns:minmax(0,2fr) minmax(280px,1fr);gap:2.5rem;align-items:start}.plate[hidden]{display:none}.image-link img{display:block;width:100%;height:auto;box-shadow:0 5px 28px #28242020}aside{position:sticky;top:2rem}aside h2{font:normal 1.8rem/1.2 Georgia,serif}blockquote{font:italic 1.25rem/1.5 Georgia,serif;margin:2rem 0;padding-left:1rem;border-left:2px solid var(--accent)}.links{font-size:.9rem}.caption{font-size:.82rem;color:#6e675f;margin-top:2rem}.prev-next{display:flex;gap:.6rem;margin-top:1.5rem}details{font-size:.9rem;margin-top:2rem}summary{cursor:pointer}ol{padding-left:1.3rem}li{margin:.6rem 0}footer{font-size:.8rem;color:#6e675f;border-top:1px solid var(--line);margin-top:2rem}@media(max-width:780px){header,main,footer{padding:1.2rem}.plate{grid-template-columns:1fr;gap:1rem}aside{position:static}}@media print{header,aside,footer{display:none}.plate[hidden],.plate{display:block;break-after:page}.image-link img{max-height:270mm;width:auto;max-width:100%;box-shadow:none}main{padding:0}}
.nav-group{width:100%;display:flex;gap:.5rem;flex-wrap:wrap}.nav-group>p{width:100%;margin:.8rem 0 0}
</style></head><body><header><p class="eyebrow">Ada · ''' + str(len(spec['plates'])) + ''' final-text illustrations · 6 October 2026</p><h1>What has the encounter made possible?</h1><p>''' + description + '''</p><nav aria-label="Hall illustrations">''' + nav + '''</nav></header><main>''' + ''.join(sections) + '''</main><footer>Built-in image_gen · <a href="PROMPTS.md">Prompts and refinements</a> · <a href="provenance.json">Source records</a> · <a href="../2026-10-05-tutorial-comic-plates/index.html">Tutorial plates</a></footer><script>
const pages=[...document.querySelectorAll('.plate')];
function show(id){const chosen=pages.find(p=>p.id===id)||pages[0];pages.forEach(p=>p.hidden=p!==chosen);document.querySelectorAll('nav [data-map]').forEach(b=>b.setAttribute('aria-current',String(b.dataset.map===chosen.id)));}
document.querySelectorAll('[data-map]').forEach(b=>b.addEventListener('click',()=>{history.replaceState(null,'','#'+b.dataset.map);show(b.dataset.map);window.scrollTo({top:0,behavior:'smooth'});}));
window.addEventListener('hashchange',()=>show(decodeURIComponent(location.hash.slice(1))));show(decodeURIComponent(location.hash.slice(1)));
</script></body></html>'''
(HERE / 'index.html').write_text(html, encoding='utf-8')
(HERE / 'PROMPTS.md').write_text('\n'.join(prompts) + '\n', encoding='utf-8')
(HERE / 'provenance.json').write_text(json.dumps(dict(date='2026-10-06', tool='Built-in image_gen', plates=facts), ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'gallery': str(HERE / 'index.html'), 'images': len(facts)}, indent=2))
