"""Publish the optical-cloth prose revision against preserved sources and evidence."""
from pathlib import Path
import difflib
import hashlib
import html
import json
import re
import shutil
import publish_tiling_cards_and_cloth as base

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-10-tiling-optical-cloth'
HALL = ROOT / 'commons/maps/Symmetry_Seventeen'
EVIDENCE = ROOT / 'doc/book/iterations/2026-10-10-optical-woven-checks'
NAMES = ['tutorial.md', 'final.md', 'textile-note.md', 'intent.md']
base.OUT = OUT


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def render(text):
    return base.render(text.replace('../../../doc/book/iterations/2026-10-10-optical-woven-checks/index.html', '../2026-10-10-optical-woven-checks/index.html'))


def write(name, text):
    (OUT / name).write_text(text, encoding='utf-8')


def main():
    (OUT / 'images').mkdir(parents=True, exist_ok=True)
    before = {n: base.read(OUT / 'before/commons/maps/Symmetry_Seventeen' / n) for n in NAMES}
    current = {n: base.read(HALL / n) for n in NAMES}
    old_code = re.findall(base.BLOCKS, before['tutorial.md'], re.S)
    new_code = re.findall(base.BLOCKS, current['tutorial.md'], re.S)
    assert len(new_code) == 5 and old_code == new_code
    assert '```' not in current['final.md']
    allowed = {f'commons/maps/Symmetry_Seventeen/{n}' for n in NAMES}
    allowed.update(['doc/book/course/execution-plan/plan.json', 'doc/book/course/storyboards/CONTEXT.md'])
    protected = json.loads(base.read(OUT / 'before-hashes.json'))
    assert all(sha(ROOT / p) == h for p, h in protected.items() if p not in allowed)
    # Reuse actual runtime evidence only if the executable artifact still matches it.
    evidence_hashes = json.loads(base.read(EVIDENCE / 'source-hashes.json'))
    artifact_files = [p for p in (ROOT / 'commons/artifacts/jacquard_weaver').iterdir()
                      if p.suffix in ['.gd', '.tscn', '.gdshader']]
    assert all(sha(p) == evidence_hashes[p.relative_to(ROOT).as_posix()] for p in artifact_files)
    receipts = {n: json.loads(base.read(EVIDENCE / (n + '.json')))
                for n in ['tests', 'sample-tests', 'museum-tests']}
    assert all(r['passed'] and all(c['passed'] for c in r['checks']) for r in receipts.values())
    prior_count = sum(len(r['checks']) for r in receipts.values())
    maps = json.loads(base.read(ROOT / 'commons/maps/sequences/tiling.json'))['sequences']['tiling']['maps']
    assert len(maps) == 9 and maps[maps.index('Symmetry_Seventeen') + 1] == 'Pattern_Temple'
    old_plan = json.loads(base.read(OUT / 'before/doc/book/course/execution-plan/plan.json'))
    plan = json.loads(base.read(ROOT / 'doc/book/course/execution-plan/plan.json'))
    for old, new in zip(old_plan['lessons'], plan['lessons']):
        if old['id'] != 'Symmetry_Seventeen':
            assert old == new
        else:
            assert all(old[k] == new[k] for k in old if k not in ['summary', 'notes'])
    checks = {
        'scope': 'Canonical text update; no new runtime execution',
        'five_printed_files_unchanged': [n for n, code in new_code],
        'other_eight_hall_pairs_unchanged': True,
        'map_data_order_and_loom_code_unchanged': True,
        'plan_changed_only_symmetry_summary_and_notes': True,
        'prior_native_checks': prior_count,
        'artifact_matches_tested_source': True,
        'physical_headset_or_perception_test': False,
        'sources': {n: sha(HALL / n) for n in NAMES},
    }
    write('validation.json', json.dumps(checks, indent=2) + '\n')
    for name in NAMES:
        write(name, current[name])
        write(name.replace('.md', '.diff'), ''.join(difflib.unified_diff(
            before[name].splitlines(True), current[name].splitlines(True),
            fromfile='before/' + name, tofile=name)))
    for name in ['optical-cloth.png', 'optical-layers.png', 'optical-museum.png']:
        shutil.copy2(EVIDENCE / name, OUT / 'images' / name)
    intro = '''<p class="eyebrow">Tiling · Symmetry Seventeen · 10 October 2026</p>
    <h1>The cloth stays flat.<br>The eye finds a fold.</h1>
    <p class="lead">Seven woven samples now enter the tutorial and reflection. Compare the crossing rule, the yarn colours and the band widths; then compare what you see with what the geometry does.</p>
    <div class="status">Applied to the canonical hall texts. The loom remains an optional investigation beside the existing glide-reader lesson.</div>
    <figure><img src="images/optical-cloth.png" width="1800" height="1200" alt="Optical checks woven in the installed museum loom"><figcaption>Native museum capture from the tested optical-cloth implementation.</figcaption></figure>
    <div class="reading"><h2>Read the update</h2><p><a href="loom.html">Tutorial and reflective loom passages</a> · <a href="parallel.html">Complete hall, facing pages</a> · <a href="tutorials.html">All nine tutorials</a> · <a href="final.html">All nine reflections</a> · <a href="changes.html">Before / after</a>.</p>
    <p>The tutorial compares three pairs, then follows the optical sample's 38-step colour sequence. The reflection stays with the apparent fold and the act of opening the cloth. The source note keeps the reference textile's unidentified name and draft separate from Ada's own construction.</p>
    <h2>Place in the sequence</h2><p>Array Patterns gives an address a surface. Symmetry composes an operation; the looms let you separate a rule, its recorded result and its appearance. Temple then copies recipes to other receivers. The woven sample stays in this hall.</p>'''
    intro += f'<h2>Checked</h2><p>The five printed files, the other eight hall pairs, map order and museum code match their pre-edit hashes. Current loom code matches its earlier {prior_count} native checks. Those checks were not rerun for this prose edit; perception and headset comfort still require a visitor. <a href="validation.json">Validation record</a>.</p></div>'
    write('index.html', base.page('Optical cloth in Tiling', intro))
    excerpt = current['tutorial.md'].split('### Optional: follow a card into cloth')[1].split('## Complete carried files')[0]
    reflection = current['final.md'].split('<!-- @thread_loom -->')[1]
    loom = '<h1>What changes the pattern?</h1><div class="pair"><article class="sheet"><p class="meta">TUTORIAL · OPTIONAL ENCOUNTER</p>' + render('### Follow a card into cloth\n' + excerpt) + '</article><article class="sheet"><p class="meta">FINAL · REFLECTION</p>' + render(reflection) + '</article></div><figure><img src="images/optical-layers.png" width="1800" height="1200" alt="The same woven sample opened into its thread crossings"><figcaption>Opening deliberately changes the geometry of the same recorded sample.</figcaption></figure>'
    write('loom.html', base.page('The loom passages', loom))
    pair = '<h1>Symmetry Seventeen</h1><div class="pair"><article class="sheet"><p class="meta">LEFT · TUTORIAL</p>' + render(current['tutorial.md']) + '</article><article class="sheet"><p class="meta">RIGHT · FINAL</p>' + render(current['final.md']) + '</article></div>'
    write('parallel.html', base.page('The complete hall', pair))
    comparison = '<h1>Before / after</h1>'
    for name in NAMES:
        comparison += '<section class="chapter"><h2>' + html.escape(name) + '</h2><div class="pair"><article class="sheet"><p class="meta">BEFORE</p>' + render(before[name]) + '</article><article class="sheet"><p class="meta">AFTER</p>' + render(current[name]) + '</article></div></section>'
    write('changes.html', base.page('Before and after', comparison))
    route = '<div class="route">' + ''.join(f'<a href="#{m}">{i+1}. {m.replace("_", " ")}</a>' for i, m in enumerate(maps)) + '</div>'
    for track, output in [('tutorial', 'tutorials'), ('final', 'final')]:
        chapters = []
        combined = []
        for m in maps:
            text = base.read(ROOT / 'commons/maps' / m / (track + '.md'))
            chapters.append(f'<section id="{m}" class="chapter"><p class="eyebrow">{m.replace("_", " ")}</p>' + render(text) + '</section>')
            combined.append(f'<!-- hall: {m} -->\n\n' + text.replace('(../Symmetry_Seventeen/textile-note.md)', '(textile-note.md)').replace('(further-encounters.md)', '(foundry-further.md)').replace('../../../doc/book/iterations/2026-10-10-optical-woven-checks/index.html', '../2026-10-10-optical-woven-checks/index.html'))
        write(output + '.html', base.page('Tiling / ' + output, '<h1>Tiling · ' + output + '</h1>' + route + '<div class="reading">' + ''.join(chapters) + '</div>'))
        write('tiling-' + output + '.md', '# Tiling — ' + output + '\n\n' + '\n\n---\n\n'.join(combined))
    write('textile-note.html', base.page('The thread and the work', '<article class="reading">' + render(current['textile-note.md']) + '</article>'))
    further = base.read(ROOT / 'commons/maps/Pattern_Foundry/further-encounters.md')
    write('foundry-further.md', further)
    write('foundry-further.html', base.page('Further encounters', '<article class="reading">' + render(further) + '</article>'))
    write('REPORT.md', '# Optical cloth in Tiling\n\nCanonical tutorial.md, final.md, textile-note.md and intent.md revised. Execution-plan summary and context aligned. The existing five-file code lesson is unchanged; all seven samples are supplied optional encounters. The reflected depth is an interpretation to investigate, not a test result. Exact source textile name/draft unverified.\n\nPrior native evidence: 185 checks, source hashes matched. No new Godot run. Other eight hall pairs, maps and runtime unchanged. Current full-sequence readers, facing pages, before snapshots and diffs accompany this report.\n')
    print(f'Published {OUT / "loom.html"}; five printed files unchanged; {prior_count} prior checks source-matched.')


if __name__ == '__main__':
    main()
