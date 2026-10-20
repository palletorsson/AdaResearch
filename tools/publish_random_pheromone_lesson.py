"""Publish a tested, reduced feedback study within the existing museum."""
from pathlib import Path
from urllib.parse import unquote, urlparse
import difflib, hashlib, html, json, re, shutil, zipfile
import markdown
from publish_randomness_revision import ROOT, OUT, PLAN, STYLE, page, publish_plan
from publish_ten_print_lesson import Links

MAP = 'Random_Pheromone'
HERE = OUT / MAP
NAMES = ['hall-before', 'installed-attract', 'installed-avoid', 'student-attract',
         'student-scent-erased', 'student-avoid', 'hall-with-study']
REPORT = '''# A visit enters the next choice

**Randomness, hall 12 of 14.** The walker returns. This time its visits alter a field that influences later movement. The tutorial builds one walker and two views: fading scent and retained visit counts.

## The teaching choice

Random Walk retained a trail without reading it. The previous room retained samples without letting their outcomes choose subsequent samples. Pheromone introduces feedback: **fade → deposit → count → choose → move**. The familiar point controls the experiment; arrays, grid addresses and seeded replay carry forward.

The old tutorial left its ant scene and helpers undeclared. Its description of weighted choice did not match the installed artifact. The new complete study follows the actual rule: a random draw sometimes selects the strongest or weakest sensed neighbour; otherwise another draw chooses a direction. Strict comparisons preserve the first valid direction when values tie. On blank ground, list order can supply a preference before scent does.

The old `trail_entropy()` only returned a mean. It has been removed rather than presented as evidence of an information measure or route quality. The reflection keeps its question about paths that become persuasive through repeated use, and distinguishes that reinforcement from finding an optimal route.

## One history, different records

The left grid shows current scent; the right shows accumulated departure visits. Two cyan markers represent the same walker. Erase the scent after 100 steps: the columns and recorded path remain. What remains visible is not necessarily what the next decision reads.

The code preserves separate `field`, `visits` and `path` arrays. Colour and column height saturate for display, while their underlying records remain uncapped. A 256-step budget bounds the experiment. The reduced study uses one walker on 8 × 8 addresses, sensing one address ahead. The museum uses four walkers on 81 × 81 vertices, sensing two addresses ahead, and has an additional border rule. These are declared differences; the small and full runs are not claimed to share a path.

## What was tested

- **31 assertions passed for each of six complete programs:** printed baseline, seed 43, fully guided, unguided, no decay, and an extra fade that erases scent after every step.
- Each program was compared against the production artifact's methods for 100 ATTRACT and 100 AVOID steps under the same reduced configuration. Positions, generator state, scent and departure counts agreed at every step. This checks a reduced rule against its source, not the whole museum against the miniature.
- **Four deliberate faults were rejected:** replacing first-tie selection with last-tie selection, reading visits as scent, erasing visits during decay, and using world coordinates for local trigger zones.
- **28 native museum checks passed:** installed console signals, one-step deposits, batch equivalence, seeded restart, field/height separation, learner actions, floor support and a clear standing approach.

At the installed seed 190919, 500 steps under ATTRACT produced 314 raised vertices; AVOID produced 476. Those are observed outcomes of this run, not guarantees about either policy. The tutorial asks the student to explain a changed rule before judging the resulting shape.

## Space is part of the check

The first table placement passed the floor and standing checks but overlapped a display figure. The second crossed a partition. Both attempts are retained, labelled as rejected visual placements. The first terrain camera was also obstructed; its replacement shows the same installed comparison from above. The final reconstruction sits at hall-local **(10.1, 0, 6.2), yaw -90°**; its pale table improves label contrast. Close views and the overhead view were inspected. The study is a temporary reconstruction used for testing and a documented learner placement, not a newly registered exhibit.

The existing hall, terrain algorithm, sequence and PointBody were not changed. Its bright terrain and surrounding decorative objects still make the installed field harder to read than the small comparison. The native captures show that limitation rather than replacing the museum with an idealized illustration.

## What the evidence does not establish

This is an author-informed reconstruction with supplied button and PointBody action events. It is not an unfamiliar reader, physical headset session or Quest performance test. The final engine log has no script or parse errors; existing resource/renderer and shutdown warnings remain. Browser layout is not verified. The evidence covers the local learner approach, not every passage in the hall.

Next: **Random Space**. Return to combining fields at different scales, and distinguish values generated by a spatial function from values changed by a history of visits.

[Tutorial and reflection](parallel.html) · [Before / after](changes.html) · [Review ZIP](random-pheromone-review.zip)
'''


def update_plan():
    status_path = PLAN / 'STATUS.json'
    status = json.loads(status_path.read_text(encoding='utf8'))
    row = next(r for r in status['halls'] if r['map'] == MAP)
    row.update(status='revised; ready for review',
               tutorial_test='31 checks × 6 programs passed; 4 faults rejected; reduced source-rule parity',
               museum_test='28 passed; final native views inspected after two rejected placements; supplied actions',
               report=(HERE / 'index.html').relative_to(ROOT).as_posix())
    status_path.write_text(json.dumps(status, indent=2), encoding='utf8')
    plan_path = PLAN / 'PLAN.md'
    plan = plan_path.read_text(encoding='utf8')
    a, b = plan.index('### 12 ·'), plan.index('### 13 ·')
    section = '''### 12 · Random_Pheromone — a visit enters the next choice

**Primary:** pheromone_terrain. **Bring:** PointBody, walker, grid addresses and retained records. One walker deposits and reads scent on an 8 × 8 field. Compare current scent with accumulated visits; fade only the signal. A random branch selects the strongest/weakest neighbour, otherwise a random direction; this is not a scent-weighted lottery. Declare strict first-tie order and edge policy. Follow/avoid at equal steps; neither proves an optimal route. Keep source border, walker-count and sensor differences explicit. **Status:** revised; six complete programs pass 31 checks each, each agrees with reduced production methods for 100 steps per rule. Four faults rejected; 28 native checks. Two visually obstructed placements rejected; final view inspected. Carry feedback into a comparison with Random Space's history-independent field composition.

'''
    plan_path.write_text(plan[:a] + section + plan[b:], encoding='utf8')
    execution_path = ROOT / 'doc/book/course/execution-plan/plan.json'
    execution = json.loads(execution_path.read_text(encoding='utf8'))
    lesson = next(r for r in execution['lessons'] if r['id'] == MAP)
    before = HERE / 'execution-row-before.json'
    if not before.exists():
        before.write_text(json.dumps(lesson, indent=2), encoding='utf8')
    lesson.update(
        given='Prepared Endless Museum player, floor, camera, light and XR Tools; unchanged PointBody printed beside the complete study.',
        reuses='PointBody actions; walker displacement; addressed arrays; local seed/replay; counts and retained paths.',
        checks=['31 assertions for each of six exact printed programs; 100 source-comparison steps per rule; four semantic faults rejected.',
                '28 native museum checks; console signals, learner actions, floor and approach; final images inspected.'],
        transfer='Set guidance to1 or0; remove decay; erase scent while retaining visits/path. Predict blank-field ties and explain which record guides the next step.',
        next='Random Space: combine spatial contributions without a history of visits; retain the distinction between a signal, a record and its display.',
        notes='Revised/tested 2026-10-09. Report doc/book/iterations/2026-10-09-randomness-revision/Random_Pheromone/index.html. Small study one walker/8x8/sensor1/no border; production four/81x81/sensor2/border10. No production edits, physical-headset or unfamiliar-reader acceptance.',
        summary='Return to the walker and let each departure change a scent field. Reuse PointBody to step, batch, replay or switch between attraction and avoidance. Build two views of the same run: current scent and visits kept. Follow the installed extreme-value-or-random branch, including its tie order and edge policy. Erase the scent while keeping the visit record, then explain why visible history need not guide movement. Carry this distinction into Random Space, where spatial values are composed without prior visits.')
    execution_path.write_text(json.dumps(execution, indent=2, ensure_ascii=False) + '\n', encoding='utf8')
    publish_plan()


def main():
    tests = json.loads((HERE / 'tests.json').read_text(encoding='utf8'))
    positive = [r for r in tests['results'] if r['expected_pass']]
    faults = [r for r in tests['results'] if not r['expected_pass']]
    assert len(positive) == 6 and all(r['passed'] and r['checks'] == 31 for r in positive)
    assert len(faults) == 4 and all(not r['passed'] and r['failures'] for r in faults)
    run = ROOT / 'ada_run/encounter_pilot' / MAP
    receipt = json.loads((run / 'report.json').read_text(encoding='utf8'))
    assert receipt['passed'] and len(receipt['checks']) == 28
    log = (run / 'engine.log').read_text(encoding='utf8')
    assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log
    museum = HERE / 'museum'
    museum.mkdir(exist_ok=True)
    for n in [*(n + '.png' for n in NAMES), 'report.json', 'engine.log', 'source_manifest.json', 'spec.json']:
        shutil.copy2(run / n, museum / n)
    baseline = json.loads((HERE / 'before-manifest.json').read_text(encoding='utf8'))
    unchanged = {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() == sha
                 for p, sha in baseline.items() if not p.endswith(('tutorial.md', 'final.md'))}
    assert all(unchanged.values()), unchanged
    texts = {n: (ROOT / f'commons/maps/{MAP}/{n}.md').read_text(encoding='utf8') for n in ['tutorial', 'final']}
    blocks = dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```', texts['tutorial'], re.S))
    assert set(blocks) == {'12_a_visit_guides.gd', 'point_body.gd'}
    for n, c in blocks.items():
        assert (HERE / 'extracted' / n).read_text(encoding='utf8') == c + '\n'
        assert hashlib.sha256((HERE / 'extracted' / n).read_bytes()).hexdigest() == tests['printed_sha256'][n]
    nav = '<a href="index.html">Report</a><a href="parallel.html">Facing pages</a><a href="changes.html">Before/after</a><a href="sequence-plan.html">Sequence plan</a>'
    diffs = []
    for name, text in texts.items():
        (HERE / f'{name}.md').write_text(text, encoding='utf8')
        (HERE / f'{name}.html').write_text(page(name.title(), text, nav), encoding='utf8')
        old = (HERE / f'before/commons/maps/{MAP}/{name}.md').read_text(encoding='utf8')
        diff = ''.join(difflib.unified_diff(old.splitlines(True), text.splitlines(True), fromfile=f'before/{name}.md', tofile=f'after/{name}.md'))
        (HERE / f'{name}.diff').write_text(diff, encoding='utf8')
        diffs.append(f'<h2>{name}.md</h2><pre>{html.escape(diff)}</pre>')
    shell = f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A visit enters the next choice</title><style>{STYLE}main{{max-width:1200px}}figure{{margin:22px 0}}figcaption{{font:14px/1.5 system-ui;margin:8px 0}}.pair{{display:grid;grid-template-columns:1fr 1fr;gap:24px}}@media(max-width:800px){{.pair{{grid-template-columns:1fr}}}}</style><main><nav>{nav}</nav>'
    def figure(n, caption):
        return f'<figure><img src="museum/{n}.png" alt="{html.escape(caption)}"><figcaption>{html.escape(caption)}</figcaption></figure>'
    pictures = figure('student-attract', 'One walker, two views. The exact printed program at seed 42 after 100 steps: scent on the left, departure counts on the right.')
    pictures += figure('student-scent-erased', 'Erase only the scent. Visit columns and the recorded path remain. No new step or random draw was requested.')
    pictures += '<details><summary>AVOID and the existing museum</summary>'
    pictures += figure('student-avoid', 'AVOID: the same seed and step count, with the signal-guided branch choosing the weakest scent.')
    pictures += '<div class="pair">' + figure('installed-attract', 'Installed ATTRACT after 500 steps: four walkers, 314 raised vertices.') + figure('installed-avoid', 'Installed AVOID after 500 steps: four walkers, 476 raised vertices.') + '</div>'
    pictures += '<div class="pair">' + figure('hall-before', 'The existing hall before temporary learner placement.') + figure('hall-with-study', 'Accepted learner placement beside the existing terrain; museum artifacts remain in place.') + '</div></details>'
    (HERE / 'REPORT.md').write_text(REPORT, encoding='utf8')
    (HERE / 'index.html').write_text(shell + '<h1>A visit enters the next choice</h1>' + pictures + markdown.markdown(REPORT, extensions=['extra']) + '</main></html>', encoding='utf8')
    (HERE / 'changes.html').write_text(shell + '<h1>Before / after</h1>' + ''.join(diffs) + '</main></html>', encoding='utf8')
    spread = ''.join(f'<article><p class="track">{label}</p>{markdown.markdown(texts[name], extensions=["extra"])}</article>' for name, label in [('tutorial', 'Tutorial · left'), ('final', 'Reflection · right')])
    (HERE / 'parallel.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Pheromone — facing pages</title><style>{STYLE}main{{max-width:1650px}}.spread{{display:grid;grid-template-columns:1fr 1fr;gap:50px}}article{{min-width:0}}.spread h1{{font-size:36px}}.track{{font:13px system-ui;text-transform:uppercase;color:#7c365b}}@media(max-width:900px){{.spread{{grid-template-columns:1fr}}}}</style><main><nav>{nav}<a href="tutorial.md">Tutorial source</a><a href="final.md">Reflection source</a></nav><h1>Pheromone</h1><div class="spread">{spread}</div></main></html>', encoding='utf8')
    update_plan()
    plan = (PLAN / 'PLAN.md').read_text(encoding='utf8')
    (HERE / 'sequence-plan.md').write_text(plan, encoding='utf8')
    (HERE / 'sequence-plan.html').write_text(page('Randomness — plan', plan, '<a href="index.html">Pheromone</a>'), encoding='utf8')
    evidence = HERE / 'tools'
    evidence.mkdir(exist_ok=True)
    for p in ['tools/revise_random_pheromone_lesson.py', 'tools/test_random_pheromone_lesson.py', 'tools/publish_random_pheromone_lesson.py', 'tools/probes/random_pheromone_student.gd', 'tools/probes/random_pheromone_museum.gd']:
        shutil.copy2(ROOT / p, evidence / Path(p).name)
    (HERE / 'README.md').write_text('Open parallel.html for tutorial left/reflection right; index.html for native captures and evidence. The learner files are extracted/12_a_visit_guides.gd and point_body.gd. Other extracted files include intentionally faulty programs: do not use those as the starting lesson. Requires the prepared Endless Museum and XR Tools, not a standalone project. first-placement/ and second-placement/ passed runtime assertions but were rejected visually. museum/ is the accepted placement. Tests use supplied actions; no physical headset or unfamiliar-reader acceptance.\n', encoding='utf8')
    for folder, reason in [('first-placement', 'Display figure overlapped the learner grid and readout.'), ('second-placement', 'Partition cut through the visit grid.'), ('first-terrain-camera', 'Terrain capture was obstructed; replaced with an overhead camera.')]:
        (HERE / folder / 'README.md').write_text('Rejected visual placement. ' + reason + ' Runtime checks alone did not detect this. Preserved for review; not the accepted placement.\n', encoding='utf8')
    rendered = [html.unescape(c) for c in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>', (HERE / 'tutorial.html').read_text(encoding='utf8'), re.S)]
    assert all((c + '\n').expandtabs(4) in rendered for c in blocks.values())
    archive = HERE / 'random-pheromone-review.zip'
    count = 0
    for p in HERE.glob('*.html'):
        parser = Links(); parser.feed(p.read_text(encoding='utf8'))
        for link in parser.links:
            if urlparse(link).scheme or link.startswith('#'):
                continue
            target = p.parent / unquote(link.split('#')[0])
            assert target == archive or target.exists(), (p, link)
            count += 1
    verify = {'rendered_code_parity': True, 'positive_program_checks': [31] * 6,
              'faults_rejected': 4, 'museum_checks': 28, 'local_targets_checked': count,
              'native_principal_images_inspected': True, 'unchanged_since_baseline': unchanged,
              'browser_layout': 'Not browser-verified.',
              'scope': 'Author-informed reconstruction and reduced source-rule comparison; supplied actions, not physical headset.'}
    (HERE / 'verification.json').write_text(json.dumps(verify, indent=2), encoding='utf8')
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
        for p in HERE.rglob('*'):
            if not p.is_file() or p == archive or p.suffix == '.uid':
                continue
            if p.suffix in ['.md', '.html']:
                content = p.read_text(encoding='utf8').replace('<a href="random-pheromone-review.zip">Review ZIP</a>', 'Review packet: this folder').replace('[Review ZIP](random-pheromone-review.zip)', 'Review packet: this folder')
                z.writestr(p.relative_to(HERE).as_posix(), content)
            else:
                z.write(p, p.relative_to(HERE).as_posix())
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        names = set(z.namelist())
        for name in names:
            if not name.endswith('.html'):
                continue
            parser = Links(); parser.feed(z.read(name).decode('utf8'))
            for link in parser.links:
                if urlparse(link).scheme or link.startswith('#'):
                    continue
                assert (Path(name).parent / unquote(link.split('#')[0])).as_posix() in names, (name, link)
    print(json.dumps({**verify, 'zip_crc': 'pass', 'zip_links': 'pass'}, indent=2))


if __name__ == '__main__':
    main()
