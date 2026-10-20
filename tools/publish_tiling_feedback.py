"""Publish two scope clarifications and an evidence-complete Tiling review revision."""
from pathlib import Path
import difflib
import hashlib
import html
import json
import re
import shutil
import zipfile
import markdown
import publish_tiling_making_and_wearing as publication

ROOT = publication.ROOT
MAPS = publication.MAPS
OUT = ROOT / 'doc/book/iterations/2026-10-09-tiling-feedback'
OLD = ROOT / 'doc/book/iterations/2026-10-09-tiling-making-and-wearing'
TESTS = ROOT / 'doc/book/iterations/2026-10-09-tiling-revision'
CHANGED = {'Symmetry_Seventeen', 'Ribbon_Patterns_03'}

REPORT = '''# Tiling — keep the route, clarify the task

The external review supports retaining the nine halls and the shortened reflective sequence. Its most useful recommendation is to make the student's programming task easier to locate among the museum's supplied systems.

## Applied to tutorial.md

- **Ribbon Patterns 03:** a short “Your part in this lesson” list distinguishes the shader the student writes, the supplied studio and wardrobe, and the independent prediction that demonstrates understanding. It introduces no extra programming requirement.
- **Symmetry Seventeen:** the hand loom is explicitly optional. The student can compare retained crossings with a changed draft without programming the loom or completing it before continuing the reader tutorial.

All nine final.md files remain unchanged. The nine-hall route, room layouts and printed programs are unchanged. The other seven tutorials are unchanged.

## What to keep

The Foundry makes the reach of a local edit visible. Later halls distinguish the source, the rule that reads it, and the surface receiving it. The garment brings those operations into an encounter with a body. Mamma Mönster and the textile references give those encounters desires and histories; they do not turn a rendering demonstration into proof of social change.

The reflective text and installation have different jobs. A room can demonstrate copying, sampling and wearing; a text can ask what people hope those acts will change. Neither needs to stand in for the other.

## A distinction in the review's closing account

The progression from mark to environment to clothing is a useful conceptual reading. It is not a literal data handoff through every artifact. Several halls declare a new starting source. The loom keeps its crossing history; its cloth does not become the garment. The garment studio supplies its own source. The sequence carries classes and operations while making those discontinuities explicit.

## The evidence missing from the first ZIP

The reviewer correctly describes the limits of the archive they received. That ZIP documented the latest editorial pass and the loom checks, but omitted the earlier tutorial test receipts.

This revision includes the existing test reports for all nine halls: **647 passing assertions across the printed examples and their prescribed variations**. It also includes those archived learner files and the reproduction scripts. The current 36 printed file blocks match the archived printed examples after normalizing text line endings and the final newline. This comparison was performed for this feedback pass.

These are earlier Godot runs. No Godot execution, fresh independent ghost-student reconstruction, or physical headset playtest was performed for these two prose clarifications. The receipts establish the assertions they name, not every museum behavior, headset comfort or human understanding. The supplied museum project is still required to run the examples.

The original reviewed ZIP is preserved. The revised ZIP contains complete tutorials and reflections, the two tutorial diffs, native museum images and the previously omitted test evidence.
'''

BRIEF = '''# Start here — Tiling review, revision 2

Read this chapter within Endless Museum after Primitives, Transformation, Arrays and Colour. The learner already uses variables, arrays, loops, conditions, functions, transformations, a palette and a grabbable point. The museum supplies the player, camera, lighting, XR Tools and input setup. This archive is a book review package, not the full Godot project.

Open index.html. Read tutorial.html and final.html, or their Markdown counterparts. Each hall's parallel.html puts tutorial left and reflection right. REPORT.md records the response to the external critique; changes.html shows the two tutorial clarifications.

The tutorial teaches a selected operation with complete printed code and declared dependencies. The reflection develops the critical and poetic encounter. Additional artifacts can remain optional. In particular, the loom is not a compulsory coding assignment and its output is not transferred to the garment.

Please assess the distinct purpose of each hall, the cumulative operations, the smallest useful programming task, and the relationship between making and reflection. Identify exact technical omissions separately from preferences or proposed new features. Preserve strong writing and avoid expanding every supplied service into another lesson.

The evidence folder contains earlier test reports and their printed learner sources. validation.json records this pass's code comparisons and source checks. These are not new Godot runs or a physical headset playtest. The original review archive remains available separately.
'''


def read(path):
    return path.read_text(encoding='utf-8-sig')


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def code_blocks(text):
    return dict(re.findall(r'<!-- student-code:([^>]+?) -->\s*```[^\n]*\n(.*?)\n```', text, re.S))


def portable(text, prefix=''):
    def image(match):
        url = match.group(1)
        name = hashlib.sha256(url.encode()).hexdigest()[:8] + '-' + Path(url).name
        assert (OUT / 'images' / name).exists()
        return '](' + prefix + 'images/' + name + ')'
    text = re.sub(r'\]\((/book-images/[^)]+)\)', image, text)
    return (text.replace('(../Symmetry_Seventeen/textile-note.md)', '(' + prefix + 'textile-note.md)')
            .replace('](textile-note.md)', '](' + prefix + 'textile-note.md)')
            .replace('(further-encounters.md)', '(' + prefix + 'foundry-further.md)'))


def page(title, body, prefix=''):
    nav = ''.join(f'<a href="{prefix}{url}">{label}</a>' for url, label in [
        ('index.html', 'Review response'), ('tutorial.html', 'Complete tutorials'),
        ('final.html', 'Complete reflections'), ('changes.html', 'Two clarifications'),
        ('evidence.html', 'Earlier test evidence'), ('tiling-review-v2.zip', 'Review ZIP')])
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{publication.STYLE}</style></head><body><main><nav>{nav}</nav>{body}</main></body></html>'


def main():
    OUT.mkdir(exist_ok=True)
    publication.OUT = OUT
    shutil.copytree(OLD / 'images', OUT / 'images', dirs_exist_ok=True)
    for name in ['textile-note.md', 'foundry-further.md']:
        text = read(OLD / name)
        content = publication.rendered(text, 'Pattern_Foundry')
        (OUT / name).write_text(portable(text), encoding='utf-8')
        (OUT / name.replace('.md', '.html')).write_text(page(name, '<article class="reading">' + content + '</article>'), encoding='utf-8')
    baseline = json.loads(read(OUT / 'before-hashes.json'))
    protected = {path: digest(ROOT / path) == sha for path, sha in baseline.items()
                 if path not in {f'commons/maps/{m}/tutorial.md' for m in CHANGED}}
    assert all(protected.values()), 'An unrelated source or reviewed archive changed.'
    validation = {'kind': 'Prose clarification and comparison with earlier evidence; no new Godot run', 'protected': protected, 'halls': []}
    combined = {'tutorial': [], 'final': []}
    rendered = {'tutorial': [], 'final': []}
    comparisons, evidence_rows, route = [], [], []
    for i, m in enumerate(MAPS):
        destination = OUT / m
        destination.mkdir(exist_ok=True)
        texts = {kind: read(ROOT / 'commons/maps' / m / (kind + '.md')) for kind in combined}
        for kind, text in texts.items():
            content = publication.rendered(text, m)
            combined[kind].append(f'<!-- hall: {m} -->\n\n' + portable(text))
            rendered[kind].append(f'<section class="chapter" id="{m}"><p class="eyebrow">{i+1}. {m}</p>' + content + '</section>')
            (destination / (kind + '.md')).write_text(portable(text, '../'), encoding='utf-8')
        neighbors = ' · '.join(f'<a href="../{MAPS[j]}/parallel.html">{label}</a>' for j, label in [(i-1, 'Previous hall'), (i+1, 'Next hall')] if 0 <= j < len(MAPS))
        pair = '<p class="meta">' + neighbors + '</p><div class="pair">' + ''.join('<section class="sheet"><p class="eyebrow">' + kind + '</p>' + publication.rendered(texts[kind], m, '../') + '</section>' for kind in ['tutorial', 'final']) + '</div>'
        (destination / 'parallel.html').write_text(page(m, pair, '../'), encoding='utf-8')
        route.append(f'<a href="{m}/parallel.html">{i+1}. {m}</a>')
        if m in CHANGED:
            before = read(OUT / 'before' / m / 'tutorial.md')
            assert code_blocks(before) == code_blocks(texts['tutorial'])
            diff = ''.join(difflib.unified_diff(before.splitlines(True), texts['tutorial'].splitlines(True), fromfile='before/tutorial.md', tofile='tutorial.md'))
            (destination / 'changes.diff').write_text(diff, encoding='utf-8')
            comparisons.append(f'<section class="chapter"><h2>{m}</h2><pre>{html.escape(diff)}</pre><a href="{m}/parallel.html">Read the complete pair</a></section>')
        evidence = OUT / 'evidence' / m
        evidence.mkdir(parents=True, exist_ok=True)
        report = json.loads(read(TESTS / m / 'tests.json'))
        assert report['all_passed'] and all(r['passed'] for r in report['results'])
        shutil.copy2(TESTS / m / 'tests.json', evidence / 'tests.json')
        shutil.copytree(TESTS / m / 'learner' / 'printed', evidence / 'learner' / 'printed', dirs_exist_ok=True)
        shutil.copytree(TESTS / m / 'reproduce', evidence / 'reproduce', dirs_exist_ok=True,
                        ignore=shutil.ignore_patterns('__pycache__', '*.pyc'))
        for case in report['results']:
            for field in ['receipt', 'log']:
                p = Path(case[field])
                (evidence / p).parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(TESTS / m / p, evidence / p)
        blocks = code_blocks(texts['tutorial'])
        assert blocks
        matches = {name: code.rstrip('\n') == read(evidence / 'learner/printed' / name).rstrip('\n') for name, code in blocks.items()}
        assert all(matches.values()), (m, matches)
        validation['halls'].append({'map': m, 'code_matches_archived_printed_files': matches, 'earlier_report_all_passed': True, 'earlier_assertions': report['checks']})
        evidence_rows.append(f'<tr><td>{m}</td><td>{len(blocks)}</td><td>{report["checks"]}</td><td><a href="evidence/{m}/tests.json">Earlier report</a></td></tr>')
    for kind in combined:
        (OUT / (kind + '.md')).write_text('# Tiling — complete ' + kind + ' sequence\n\n' + '\n\n---\n\n'.join(combined[kind]), encoding='utf-8')
        (OUT / (kind + '.html')).write_text(page('Tiling / ' + kind, '<div class="route">' + ''.join(route) + '</div><div class="reading">' + ''.join(rendered[kind]) + '</div>'), encoding='utf-8')
    (OUT / 'REPORT.md').write_text(REPORT, encoding='utf-8')
    (OUT / 'START_HERE.md').write_text(BRIEF, encoding='utf-8')
    intro = '<article class="reading">' + markdown.markdown(REPORT) + '<p><a href="START_HERE.md">Reviewer instructions</a></p><figure><img src="images/Symmetry_Seventeen.png" alt="Existing native museum capture of the hand loom"><figcaption>The loom remains an optional encounter. Existing Godot capture, not a new render.</figcaption></figure></article>'
    (OUT / 'index.html').write_text(page('Tiling / feedback applied', intro + '<div class="route">' + ''.join(route) + '</div>'), encoding='utf-8')
    (OUT / 'changes.html').write_text(page('Tiling / two clarifications', '<h1>Two small changes to tutorial scope.</h1>' + ''.join(comparisons)), encoding='utf-8')
    (OUT / 'evidence.html').write_text(page('Tiling / earlier test evidence', '<h1>The evidence behind the examples.</h1><p>Earlier runs, newly included. Printed code matches all 36 archived files. The 647 assertions span the printed programs and prescribed variations. This is not a new Godot execution or physical headset test.</p><table><thead><tr><th>Hall</th><th>Printed files matched</th><th>Earlier assertions</th><th>Receipt</th></tr></thead><tbody>' + ''.join(evidence_rows) + '</tbody></table><p>See each evidence folder for the archived learner sources and reproduction scripts. Running them requires the supplied museum project.</p><p><a href="validation.json">Checks performed for this publication</a></p>'), encoding='utf-8')
    validation['earlier_assertions_total'] = sum(h['earlier_assertions'] for h in validation['halls'])
    validation['printed_file_blocks_matched'] = sum(len(h['code_matches_archived_printed_files']) for h in validation['halls'])
    (OUT / 'validation.json').write_text(json.dumps(validation, indent=2) + '\n', encoding='utf-8')
    files = sorted(p for p in OUT.rglob('*') if p.is_file() and p.suffix != '.zip' and p.name != 'manifest.json')
    manifest = {p.relative_to(OUT).as_posix(): digest(p) for p in files}
    (OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    archive = OUT / 'tiling-review-v2.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for p in files + [OUT / 'manifest.json']:
            if p.suffix == '.html':
                text = read(p)
                text = re.sub(r'<a href="(?:\.\./)?tiling-review-v2.zip">Review ZIP</a>', '', text)
                z.writestr('tiling-review-v2/' + p.relative_to(OUT).as_posix(), text)
            else:
                z.write(p, 'tiling-review-v2/' + p.relative_to(OUT).as_posix())
    # The portable archive removes its own download link; hash the actual archived bytes.
    with zipfile.ZipFile(archive) as z:
        archived_hashes = {n.removeprefix('tiling-review-v2/'): hashlib.sha256(z.read(n)).hexdigest() for n in z.namelist() if not n.endswith('/manifest.json')}
    # Rewrite once to replace the manifest, avoiding duplicate ZIP entries.
    temporary = OUT / 'tiling-review-v2.build.zip'
    with zipfile.ZipFile(archive) as src, zipfile.ZipFile(temporary, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as dst:
        for n in src.namelist():
            dst.writestr(n, json.dumps(archived_hashes, indent=2) + '\n' if n.endswith('/manifest.json') else src.read(n))
    temporary.replace(archive)
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
    print(json.dumps({'archive': str(archive), 'bytes': archive.stat().st_size, 'matched_files': validation['printed_file_blocks_matched'], 'earlier_assertions': validation['earlier_assertions_total'], 'protected_unchanged': all(protected.values())}))


if __name__ == '__main__':
    main()
