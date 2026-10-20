"""Publish the bounded loom text revision; preserve the existing coding lesson."""
from pathlib import Path
import difflib
import hashlib
import html
import json
import re
import shutil
import markdown
from publish_tiling_making_and_wearing import STYLE

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-10-tiling-cards-and-cloth'
HALL = ROOT / 'commons/maps/Symmetry_Seventeen'
BEFORE = OUT / 'before/commons/maps/Symmetry_Seventeen'
EVIDENCE = ROOT / 'doc/book/iterations/2026-10-10-jacquard-hanging-chain'
WEB = ROOT.parent / 'ada_encyclopedia/public'
BLOCKS = r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```'


def read(path):
    return path.read_text(encoding='utf-8-sig')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def render(text):
    def image(match):
        path = WEB / match[1].lstrip('/')
        assert path.is_file(), path
        name = hashlib.sha256(match[1].encode()).hexdigest()[:8] + '-' + path.name
        shutil.copy2(path, OUT / 'images' / name)
        return '](images/' + name + ')'
    text = re.sub(r'\]\((/book-images/[^)]+)\)', image, text)
    text = text.replace('(../Symmetry_Seventeen/textile-note.md)', '(textile-note.html)')
    text = text.replace('(textile-note.md)', '(textile-note.html)')
    text = text.replace('(further-encounters.md)', '(foundry-further.html)')
    return markdown.markdown(text, extensions=['tables', 'fenced_code', 'footnotes'])


def page(title, body):
    nav = '<nav><a href="index.html">The edit</a><a href="loom.html">Loom passages together</a><a href="parallel.html">Full hall / facing pages</a><a href="final.html">All nine reflections</a><a href="changes.html">Before / after</a><a href="textile-note.html">Sources</a></nav>'
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>' + html.escape(title) + ' · Endless Museum</title><style>' + STYLE + '</style></head><body><main>' + nav + body + '</main></body></html>'


def write(name, value):
    (OUT / name).write_text(value, encoding='utf-8')


def main():
    (OUT / 'images').mkdir(exist_ok=True)
    source = {n: read(HALL / n) for n in ['tutorial.md', 'final.md', 'textile-note.md', 'intent.md']}
    old = {n: read(BEFORE / n) for n in source}
    before_blocks = dict(re.findall(BLOCKS, old['tutorial.md'], re.S))
    after_blocks = dict(re.findall(BLOCKS, source['tutorial.md'], re.S))
    assert len(after_blocks) == 5 and before_blocks == after_blocks
    hashes = json.loads(read(OUT / 'before-hashes.json'))
    allowed = {f'commons/maps/Symmetry_Seventeen/{n}' for n in ['tutorial.md', 'final.md']}
    assert all(sha(ROOT / p) == h for p, h in hashes.items() if p not in allowed)
    assert '```' not in source['final.md']
    assert '<!-- @jacquard_studio -->' in source['final.md']
    maps = json.loads(read(ROOT / 'commons/maps/sequences/tiling.json'))['sequences']['tiling']['maps']
    assert maps.index('Pattern_Temple') == maps.index('Symmetry_Seventeen') + 1
    receipt = json.loads(read(EVIDENCE / 'tests.json'))
    museum = json.loads(read(EVIDENCE / 'museum-tests.json'))
    assert receipt['passed'] and museum['passed']
    # Cite prior runtime evidence only when its captured artifact source is still exact.
    runtime_sources = json.loads(read(EVIDENCE / 'source-hashes.json'))
    for p in (ROOT / 'commons/artifacts/jacquard_weaver').iterdir():
        if p.suffix in ['.gd', '.gdshader', '.tscn']:
            assert sha(p) == runtime_sources[p.name], p
    checks = {'scope': 'Prose revision; Godot was not rerun in this text pass',
              'five_printed_files_unchanged': list(after_blocks),
              'other_eight_hall_pairs_unchanged': True,
              'runtime_and_map_order_unchanged': True,
              'prior_loom_runtime_assertions': len(receipt['checks']),
              'prior_loom_museum_checks': len(museum['checks']),
              'artifact_matches_prior_tested_source': True,
              'physical_headset_tested': False,
              'sources': {n: sha(HALL / n) for n in source}}
    write('validation.json', json.dumps(checks, indent=2) + '\n')
    for name, text in source.items():
        write(name, text)
        write(name.replace('.md', '.diff'), ''.join(difflib.unified_diff(old[name].splitlines(True), text.splitlines(True), fromfile='before/' + name, tofile=name)))
    for name in ['one-hole-cloth.png', 'one-hole-layers.png', 'hanging-chain.png']:
        shutil.copy2(EVIDENCE / name, OUT / 'images' / name)
    intro = '<p class="eyebrow">Tiling · hall 5 of 9 · 10 October 2026</p><h1>The card returns.<br>The cloth grows.</h1><p class="lead">A stored instruction can repeat while its result keeps accumulating. The new loom gives that distinction a place in the existing text.</p>'
    intro += '<div class="status"><b>Applied to Symmetry Seventeen.</b> The tutorial adds an optional one-hole investigation, including the separate jobs of lift choices and yarn colours. The reflection follows repeated instructions, retained work and what the mechanism leaves outside its account. The five complete learner scripts remain unchanged.</div>'
    intro += '<figure><img src="images/hanging-chain.png" width="1800" height="1200" alt="The installed Jacquard teaching artifact"><figcaption>Native Godot capture of the existing loom. This pass changes its writing.</figcaption></figure>'
    intro += '<div class="reading"><h2>Its place in the route</h2><p>Array Patterns gives an address a surface. Symmetry composes reflection and glide; the optional looms let a repeated instruction leave successive records. Temple then copies a receiver recipe and lets later edits stay local. At the garment, a saved pattern dresses another surface; the woven sample has not travelled there.</p><h2>Read the two jobs together</h2><p><a href="loom.html">The revised loom passages</a> · <a href="parallel.html">The complete tutorial on the left and reflection on the right</a> · <a href="final.html">The whole reflective sequence</a></p><p>The source note distinguishes the historical card mechanism, Ada’s simplified construction and our interpretation. It retains the links to Plant and Mamma Mönster.</p><h2>Checked</h2><p>All five printed files match the pre-edit lesson. The other eight hall pairs, maps and runtime match their pre-edit hashes. The loom source still matches its earlier 90 runtime assertions and 11 museum checks; those tests were not rerun for prose changes. <a href="validation.json">Validation record</a>.</p></div>'
    write('index.html', page('Cards and cloth in Tiling', intro))
    tutor_excerpt = source['tutorial.md'].split('### Optional: follow a card into cloth')[1].split('## Complete carried files')[0]
    final_excerpt = source['final.md'].split('<!-- @thread_loom -->')[1]
    pair = '<p class="eyebrow">Symmetry Seventeen · complete texts</p><div class="pair"><article class="sheet"><p class="meta">LEFT · TUTORIAL</p>' + render(source['tutorial.md']) + '</article><article class="sheet"><p class="meta">RIGHT · REFLECTION</p>' + render(source['final.md']) + '</article></div>'
    loom = '<section id="loom" class="chapter"><h1>The loom passages</h1><div class="pair"><article class="sheet"><p class="meta">TUTORIAL · OPTIONAL INVESTIGATION</p>' + render('### Follow a card into cloth\n' + tutor_excerpt) + '</article><article class="sheet"><p class="meta">REFLECTION · WORK THAT REMAINS</p>' + render(final_excerpt) + '</article></div><figure><img src="images/one-hole-cloth.png" width="1800" height="1200" alt="24 rows with a patched hook repeating on rows 9 and 17"><figcaption>The tested change appears on picks 9 and 17; the first eight rows stay intact.</figcaption></figure></section>'
    write('loom.html', page('The loom passages', loom))
    write('parallel.html', page('Tutorial and reflection', pair + loom))
    comparisons = '<h1>The changes</h1>'
    for name in source:
        comparisons += '<section class="chapter"><h2>' + name + '</h2><div class="pair"><article class="sheet"><p class="meta">BEFORE</p>' + render(old[name]) + '</article><article class="sheet"><p class="meta">AFTER</p>' + render(source[name]) + '</article></div></section>'
    write('changes.html', page('Before and after', comparisons))
    route = '<div class="route">' + ''.join(f'<a href="#{m}">{i + 1}. {m.replace("_", " ")}</a>' for i, m in enumerate(maps)) + '</div>'
    chapters = []; combined = []
    for m in maps:
        text = read(ROOT / 'commons/maps' / m / 'final.md')
        chapters.append(f'<section class="chapter" id="{m}"><p class="eyebrow">{m.replace("_", " ")}</p>' + render(text) + '</section>')
        combined.append(f'<!-- hall: {m} -->\n\n' + text.replace('(../Symmetry_Seventeen/textile-note.md)', '(textile-note.md)').replace('(further-encounters.md)', '(foundry-further.md)'))
    write('final.html', page('Tiling / nine reflections', '<h1>Making, repetition, wearing.</h1>' + route + '<div class="reading">' + ''.join(chapters) + '</div>'))
    write('tiling-final.md', '# Tiling — making, repetition, wearing\n\n' + '\n\n---\n\n'.join(combined))
    write('textile-note.html', page('The thread and the work', '<article class="reading">' + render(source['textile-note.md']) + '</article>'))
    further = read(ROOT / 'commons/maps/Pattern_Foundry/further-encounters.md')
    write('foundry-further.md', further)
    write('foundry-further.html', page('Further encounters', '<article class="reading">' + render(further) + '</article>'))
    write('REPORT.md', '# Cards and cloth in Tiling\n\nApplied to canonical Symmetry_Seventeen tutorial.md, final.md, textile-note.md and intent.md. Core glide-reader code unchanged. Loom remains an optional investigation. Intent now names Pattern_Temple as the actual next hall. The execution-plan summary records the same distinction. Before versions and diffs are retained.\n\nNo museum code, map order or other hall texts changed. Five code blocks match their pre-edit versions. Prior loom evidence: 90 runtime assertions and 11 museum checks, with current artifact-source hashes verified. No new runtime execution or physical headset test in this prose pass.\n')
    print('Published cards-and-cloth reading: five printed files unchanged; eight other hall pairs and runtime unchanged.')


if __name__ == '__main__':
    main()
