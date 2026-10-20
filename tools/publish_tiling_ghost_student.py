"""Publish fresh execution evidence, continuity audit and the Tiling blog assets."""
from pathlib import Path
import hashlib
import html
import json
import re
import shutil
import markdown
from publish_tiling_making_and_wearing import STYLE

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-09-tiling-ghost-student'
WEB = ROOT.parent / 'ada_encyclopedia/public/book-images/iterations/2026-10-09-tiling-ghost-student'
BLOG = ROOT.parent / 'ada_encyclopedia/src/content/blog/2026-10-09-what-a-pattern-carries.md'
JOBS = [
    ('Pattern_Disco', 'Change colour assignment while keeping the calculated values separate.', 'Point, palette and fixed cube grid return; equal colours can hide change.'),
    ('Pattern_Foundry', 'Edit a stored source through a repeated occurrence.', 'Same three helpers; calculated parity becomes an editable two-by-three source.'),
    ('Tutorial_Pattern', 'Change a lookup, then compare it with changing the stored rows.', 'Same source structure and helper files; the reflected copy must lead an edit back correctly.'),
    ('Array_Patterns', 'Move and resize a receiver, then recover its address from the held point.', 'The point inspects here; painting is deliberately set aside.'),
    ('Symmetry_Seventeen', 'Compose reflection and half-height shift.', 'The preceding receiver is inherited unchanged. The loom remains optional.'),
    ('Pattern_Temple', 'Select a receiver and copy its recipe without sharing later changes.', 'Two owned records replace the single record; the same grid and point are reused.'),
    ('Ribbon_Patterns_01', 'Add a layer index and separate visibility from stored data.', 'An explicit volume branch; not a prerequisite for the garment shader.'),
    ('Ribbon_Patterns_02', 'Keep target values equal while changing surrounds and comparing carriers.', 'The reconstruction is optional. Observation is not prescribed by an assertion.'),
    ('Ribbon_Patterns_03', 'Write a repeat-and-offset texture sample in the supplied studio.', 'A declared new four-by-four source and host; a saved recipe does not save shader code.'),
]


def read(path):
    return path.read_text(encoding='utf-8-sig')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    manifest = json.loads(read(OUT / 'manifest.json'))
    regression = json.loads(read(OUT / 'regression-results.json'))
    transfer = json.loads(read(OUT / 'transfer.json'))
    assert regression['all_passed'] and transfer['passed']
    assert all(sha(ROOT / p) == digest for p, digest in manifest['protected'].items())
    native = {}
    for hall in ['Symmetry_Seventeen', 'Ribbon_Patterns_03']:
        source = ROOT / 'ada_run/encounter_pilot' / hall / 'tiling-ghost-student'
        target = OUT / 'museum' / hall
        target.mkdir(parents=True, exist_ok=True)
        for p in source.iterdir():
            if p.suffix == '.png' or p.name in ['report.json', 'source_manifest.json', 'engine.log', 'stdout.log', 'spec.json']:
                shutil.copy2(p, target / p.name)
        receipt = json.loads(read(target / 'report.json'))
        assert receipt['passed']
        assert 'SCRIPT ERROR:' not in read(target / 'engine.log')
        native[hall] = {'passed': True, 'checks': len(receipt['checks']), 'report': f'museum/{hall}/report.json'}
    files = ['palette.gd', 'grid_surface.gd', 'point_body.gd']
    helpers = {name: len({read(OUT / r['hall'] / 'learner/printed' / name) for r in manifest['rows'][:8]}) == 1 for name in files}
    inherited = read(OUT / 'Array_Patterns/learner/printed/04_surface_frame.gd') == read(OUT / 'Symmetry_Seventeen/learner/printed/04_surface_frame.gd')
    assert all(helpers.values()) and inherited
    diagnostics = {}
    for p in list(OUT.glob('*/tests/*.log')) + [OUT / 'transfer.log'] + list(OUT.glob('museum/*/engine.log')):
        for line in set(read(p).splitlines()):
            if line.startswith(('ERROR:', 'SCRIPT ERROR:', 'WARNING:')):
                diagnostics.setdefault(line, []).append(p.relative_to(OUT).as_posix())
    (OUT / 'diagnostics.json').write_text(json.dumps(diagnostics, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    summary = {'scope': 'Fresh same-assistant reconstruction, not a blind or headset test',
               'regression_runs': regression['runs'], 'regression_assertions': regression['checks'],
               'new_transfer_assertions': len(transfer['checks']), 'museum': native,
               'helper_continuity': helpers, 'inherited_receiver_unchanged': inherited,
               'source_files_unchanged': True, 'all_named_checks_passed': True,
               'diagnostics': 'diagnostics.json'}
    (OUT / 'results.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
    rows = '\n'.join(f'| {hall} | {job} | {carry} |' for hall, job, carry in JOBS)
    checks = '\n'.join(f'| {r["hall"]} | ' + ' | '.join(str(c['checks']) for c in r['results']) + ' | Pass |' for r in regression['results'])
    report = f'''# Tiling — the ghost student carries a changed source

Fresh reconstruction from all nine current tutorial.md files: **36 printed file blocks, 18 executions and {regression['checks']} passing assertions**. A new six-row transfer passed **{len(transfer['checks'])} checks**. Two actual museum halls passed **{sum(r['checks'] for r in native.values())} checks**, including camera checks, installed interactions and temporary learner placement.

This was performed by the same assistant that knows the work. It is a fresh-file rehearsal, not a blind student, independent reviewer, human learning study or physical headset test.

## Method

The packet preserves tutorial.md and final.md for each hall. Printed listings alone supplied the lesson files; no production lesson implementation was copied to fill a gap. Named museum and XR Tools dependencies remain prerequisites. Predictions were recorded before execution. Existing teacher probes checked the originals and prescribed edits; their new logs are kept separately from earlier runs.

The new transfer changes the source to six rows and four columns, predicts a three-row glide and two visible copies of an edited cell, then explicitly transfers that source into Temple's two owned records. It tests copying back from wall to table and retaining independent later edits. This deliberate transfer does not add automatic saving between halls.

## What the student can carry

| Hall | Task | Continuity and scope |
| --- | --- | --- |
{rows}

Palette, GridSurface and PointBody match across the first eight tutorials. Symmetry's inherited receiver matches the preceding lesson. All declared file dependencies were found. Each hall names its supplied setting and the role of its small reconstruction.

## Reading judgment

The sequence holds as a progression through source, reader, receiver and ownership. The new challenge gives evidence that a learner construction can accept another source without being rewritten for that particular motif. The strongest transition is from editing all occurrences through one shared source to deliberately copying a record that may later change independently.

The remaining reading demand is switching between the large installed artifact and the smaller learner study. The tutorials declare those differences, including different source dimensions. A first-time human reader may still need help keeping them distinct; the code checks cannot settle that. The volume and equal-target reconstruction remain optional branches. The final shader lesson's new scope list makes its small required operation clear.

No tutorial or reflective-text repair was required by this run. The two clarifications from the feedback pass remain. Tests did not require changing artifact behavior or the route.

## Fresh program results

| Hall | Printed example | Prescribed variation | Result |
| --- | ---: | ---: | --- |
{checks}

The garment test reads actual rendered pixels for independently predicted texture samples. The six-row challenge is a new test, separate from those regression fixtures. Predictions, reconstructed files, probes and raw logs are retained here.

## Inside the museum

Symmetry Seventeen: **{native['Symmetry_Seventeen']['checks']} checks** for installed comparison controls, clear standing approaches, a single reconstructed receiver, simulated XR Tools pickup/action/release, painting through the glide, and the four-row variation.

Ribbon Patterns 03: **{native['Ribbon_Patterns_03']['checks']} checks** for source edits, shader controls, saved fabric, wear/runway/undo, supported approaches and replacement of only the studio instance with the printed scene. Its three-repeat preview and the original saved-recipe shader remain distinct.

These isolated museum runs redirect output and appearance saves to test folders. Their captures use the Compatibility renderer and omit effects requiring Forward+ or Mobile. They do not represent headset performance or the final lighting quality.

## Diagnostics and limits

No GDScript parse or runtime script error appeared in the successful runs. Logs are not globally clean: the project reports an unresolved default-audio-bus UID (project.godot line 24), Jolt's unsupported custom solver-bias setting, renderer feature warnings and some unrelated registry/bridge warnings. Focused runs without a museum environment also report NatureRenderer's missing environment. The complete messages are in diagnostics.json. They did not fail the named Tiling assertions; audio-system readiness is not established by these tests.

The loom was not retested in this pass, and its cloth does not become the garment. Headset comfort, perception and human understanding remain outside these assertions.

## Reproduce

tools/test_tiling_ghost_student.py prepare extracts the printed packet into a new run folder and records predictions. Its run command executes the nine existing teacher probes against those new files. The preserved manifest and first-run logs are not overwritten by a second invocation; choose a new output folder for a later rehearsal.

tools/probes/tiling_ghost_transfer.gd runs the new transfer with --base set to this report folder and --report to a fresh receipt. The two *-museum-spec.json files identify the reconstructed lessons used by tools/run_encounter_probe.py, with sequence tiling, render enabled, no-bridges and output tag tiling-ghost-student. All execution requires the supplied museum project.
'''
    (OUT / 'REPORT.md').write_text(report, encoding='utf-8')
    WEB.mkdir(parents=True, exist_ok=True)
    for hall, name in [('Symmetry_Seventeen', 'student-wall.png'), ('Ribbon_Patterns_03', 'student-three-vertical.png')]:
        shutil.copy2(OUT / 'museum' / hall / name, WEB / name)
    for name in ['test_tiling_ghost_student.py', 'probes/tiling_ghost_transfer.gd', 'publish_tiling_ghost_student.py', 'run_encounter_probe.py', 'probes/tiling_symmetry_room.gd', 'probes/tiling_ribbon03_room.gd', 'probes/transformation_encounters.gd']:
        shutil.copy2(ROOT / 'tools' / name, OUT / 'reproduce' / Path(name).name)
    shutil.copy2(BLOG, OUT / 'blog.md')
    nav = '<nav><a href="/blog/2026-10-09-what-a-pattern-carries">Read the blog</a><a href="../2026-10-09-tiling-feedback/index.html">Complete readings</a><a href="REPORT.md">Report Markdown</a><a href="results.json">Fresh results</a><a href="regression-results.json">18 runs</a><a href="transfer.json">New transfer</a><a href="predictions-before.md">Predictions</a><a href="diagnostics.json">Diagnostics</a></nav>'
    photos = '<div class="pair">' + ''.join(f'<figure><img src="museum/{hall}/{name}" alt="Fresh museum capture of the reconstructed study"><figcaption>{caption}</figcaption></figure>' for hall, name, caption in [('Symmetry_Seventeen','student-wall.png','The learner wall and held point in Symmetry Seventeen.'),('Ribbon_Patterns_03','student-three-vertical.png','Three vertical repeats in the existing studio.')]) + '</div>'
    receipts = '<div class="route">' + ''.join(f'<a href="{row["hall"]}/tests/printed.json">{i+1}. {row["hall"]}</a>' for i, row in enumerate(manifest['rows'])) + '</div>'
    body = nav + photos + '<article class="reading">' + markdown.markdown(report, extensions=['tables','fenced_code']) + '</article>' + receipts
    (OUT / 'index.html').write_text('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Tiling / fresh ghost student</title><style>' + STYLE + '</style></head><body><main>' + body + '</main></body></html>', encoding='utf-8')
    print(json.dumps(summary, indent=2))


if __name__ == '__main__':
    main()
