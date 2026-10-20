"""Publish the B22 review bundle from actual Godot captures and checked runs."""
from pathlib import Path
import difflib
import hashlib
import html
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
RUN = ROOT / 'ada_run/biome_consistency'
OUT = ROOT / 'doc/plans/biome-ladder'
PUBLIC = ROOT.parent / 'ada_encyclopedia/public/biome-plan'
RUNTIME = [f'commons/hazards/biome_ladder/{name}' for name in (
    'ladder_encounter.gd', 'ladder_skull.gd', 'ladder_ball.gd',
    'array_path.gd', 'path_cue.gdshader', 'path_cue.gdshader.uid', 'change_ball.gd')]
PROBES = [f'tools/probes/{name}.gd' for name in (
    'biome_consistency', 'biome_ladder_arrays', 'biome_change', 'biome_colour_floor')]
REPORTS = [
    ('State, warnings, landings and clutter', 'biome_consistency/after-report.json'),
    ('Six-stage behaviour', 'biome_ladder_play/report.json'),
    ('Arrays', 'biome_ladder_arrays/report.json'),
    ('Change', 'biome_change/report.json'),
    ('Colour', 'biome_colour_floor/report.json'),
    ('Desktop input', 'biome_ladder_play/desktop/report.json'),
    ('Controlled XR and skull hits', 'biome_ladder_skull_hits/report.json'),
    ('Tiling access and feedback', 'biome_tiling_feedback/report.json'),
]


def publish():
    runs = json.loads((RUN / 'runs.json').read_text())
    assert len(runs) == len(REPORTS), 'Wait for every regression run'
    assert all(r['exit'] == 0 and not r['errors'] for r in runs), runs
    files = []
    checks = []
    for i, (label, source) in enumerate(REPORTS):
        data = json.loads((ROOT / 'ada_run' / source).read_text())
        assert data['passed'] == data['total'], label
        name = f'consistency-checks-{i}.json'
        shutil.copy2(ROOT / 'ada_run' / source, OUT / name); files.append(name)
        checks.append({'name': label, 'passed': data['passed'], 'total': data['total'], 'report': name})
    for image in sorted(RUN.glob('*.png')):
        name = 'consistency-' + image.name
        shutil.copy2(image, OUT / name); files.append(name)
    patch = []
    for source in RUNTIME:
        path = ROOT / source
        old = RUN / ('before-' + path.name)
        patch.extend(difflib.unified_diff(old.read_text().splitlines(True) if old.exists() else [],
                                        path.read_text().splitlines(True), fromfile='before/' + source,
                                        tofile='after/' + source))
    (OUT / 'consistency-runtime.patch').write_text(''.join(patch), encoding='utf-8')
    files.append('consistency-runtime.patch')
    evidence = {
        'iteration': 'B22', 'date': '2026-10-13', 'checks': checks, 'runs': runs,
        'source_sha256': {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in RUNTIME + PROBES},
        'before_sha256': {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in RUN.glob('before-*.gd')},
        'scope': 'Godot desktop, controlled XR input/physics and scripted assertions. No headset comfort or Quest performance validation.',
        'clutter': {'game_seconds': 32, 'shots_sent': 21, 'max_live_balls': 6, 'max_live_paths': 6,
                    'method': 'Real volley loop at 3x engine time; target at arrival, observer safely aside. Claude earlier measured 9 balls and 12 lines in a separate dodging test.'},
    }
    (OUT / 'consistency-evidence.json').write_text(json.dumps(evidence, indent=2), encoding='utf-8')
    files.append('consistency-evidence.json')
    paths = '\n'.join(f'- `{p}`' for p in RUNTIME)
    probes = '\n'.join(f'- `{p}`' for p in PROBES)
    table = '\n'.join(f"| {c['name']} | [{c['passed']}/{c['total']}]({c['report']}) |" for c in checks)
    report = f'''# B22 — Keep the work. Read the next shot.

13 October 2026. Six playable stages, Primitives through Change. Forces waits for independent review.

## State

START/RESUME preserves floor transforms and paint, defeated skulls, damage and consumed pickups. REST stops attacks and removes shots and warnings while retaining those records. The next addressed group receives a fresh warning on resume; an interrupted windup is not resumed halfway through. Landscape motion and the unpainted disco floor continue during REST. RESET restores heads, pickups, health and floor edits. A cleared encounter requires RESET before playing again. The console labels this distinction and shows RESUME after resting.

Exact floor edits still reset when changing stage. This pass preserves within-stage experimentation, not a cross-stage save system.

## Readability and the receiving floor

Upcoming paths are 4 cm wide tubes with bright centres and dark edges. They fade near the viewer, disappearing within 0.7 m, because their target can be the eye itself. Flight guides are thinner and dimmer (1.8 cm); they disappear with their shot. The array's explanation is larger and a short instruction is placed on the refuge. The same cue rendering also serves Change's one-time turn warning.

The original five-position zigzag is preserved. For targets inside the central floor bounds, one additional, previewed position leads to a floor-cell centre after passing the sampled target. Actual collision still decides whether the ball paints a tile, meets cover, hits a player or lands in a gap. A shot cannot paint through cover. Change's centre column keeps its field/warning/straight-commit sequence; its outer columns inherit the landing list.

Stored paths end at their final position. All ladder skull shots are removed after leaving the arena's local bounds (|x| > 6.5, |z| > 12.5 or y < -1), taking their guide with them. The 14-second lifetime remains a fallback. Health, speed, volley interval and stage order are unchanged.

## Verification

| Check | Passed |
|---|---|
{table}

The new probe prepares floors with actual desktop mouse shots, exercises the real control relays, and checks START, REST, RESUME, CLEAR and RESET in all six stages. For state assertions it invokes the existing damage handler and pickup signal; separate regressions exercise real collisions and controlled XR input. Nine real swept skull flights to a missed arrival target each hit a tile and leave colour. The normal 32-second volley loop sends 21 balls, with at most six balls and six guides alive. Claude's earlier, separate dodging experiment reached nine balls and twelve guides; the methods differ and Claude should rerun its own probe.

All listed processes exit 0 without script errors or failed assertions. Existing ObjectDB shutdown warnings remain. Physical headset readability, comfort and performance have not been tested. The known Flow_Field museum cleanup issue is outside this pass. The console and hand glow still occupy part of the entrance view; their layout has not been redesigned.

## Exact runtime changes

{paths}

[Review the runtime diff](consistency-runtime.patch). [Source hashes and run results](consistency-evidence.json).

## Probe changes

{probes}

biome_consistency is new. The existing Arrays probe now explicitly asserts that RESUME keeps a vacancy; Change expects the added landing entry for outer-column shots; Colour expects START to retain paint and checks the new announced landing tile. Claude's review/probe files are untouched. No tutorial.md, final.md, canonical route or user-authored SCAFFOLD changes.

Publishing: new `tools/publish_biome_consistency.py`; report and images under `doc/plans/biome-ladder`, mirrored to `ada_encyclopedia/public/biome-plan`. PLAN.md, HANDOVER.md and ACTIVE-CODEX.md link this result. `tools/publish_biome_change.py` and the existing change.html gain a navigation link to this update; historical B20/B21 evidence is retained. The new shader's Godot resource UID is included in the runtime list and diff.
'''
    (OUT / 'CONSISTENCY.md').write_text(report, encoding='utf-8'); files.append('CONSISTENCY.md')
    handoff = f'''# Claude — independently review B22

Start at http://localhost:3003/biome-plan/consistency.html . Read CONSISTENCY.md and consistency-evidence.json in this folder. Forces is deliberately not built; review the first six stages before expansion.

## Changed runtime files

{paths}

`consistency-runtime.patch` is the exact runtime diff from the pre-B22 snapshots. Verify source hashes before comparing with a later checkout.

## Fresh Godot captures

- consistency-before-row-warning.png / consistency-after-row-warning.png — same standing camera and announced row.
- consistency-before-column-warning.png / consistency-after-column-warning.png — same standing camera and announced column.
- consistency-after-prepared-and-running.png — Tiling floor edits kept when combat starts.
- consistency-after-landing-path.png — the additional floor landing shown in the announced list, elevated view.
- consistency-after-skull-floor-landing.png — actual coloured receiver after missed shots.
- consistency-before-stage-0.png through consistency-before-stage-5.png and matching after-stage files — six-stage arrival comparison.

## Your independent checks

1. Rerun state continuity through START, REST, RESUME, CLEAR and RESET. Floor edits, vacancies, damage and consumed pickups should survive starting/resuming; only RESET restores them. Windups restart safely; the next row/column is selected.
2. Rerun your missed-shot, floor-paint and clutter cases. The runtime now includes an announced sixth landing entry and local-bound retirement. Do not remove a meaningful failing expectation just to get a pass; distinguish stale assumptions from regressions.
3. Inspect bright upcoming paths versus dimmer flight paths from a standing viewpoint. Does the near-eye fade stay comfortable? Does the end-on column warning read? Does the added landing create an unfair second contact while sidestepping?
4. Verify cover still matters and Change still samples one target with no continuous homing. Check both outer zigzags and centre field shots.
5. Report one most useful improvement per stage: what returns, what is new, what the player can perceive and use. Keep code correctness, screenshot evidence and headset questions separate.

Codex's results are in CONSISTENCY.md. Your review and probes remain yours; do not change the runtime, book or stage order. Append your findings to CLAUDE-REVIEW.md. Console placement, hand-glow dominance, physical headset play and the older Flow_Field cleanup errors remain open. This file is the shared handoff, not a claim that Claude has already reviewed or received a forum message.
'''
    (OUT / 'CLAUDE-CONSISTENCY-HANDOFF.md').write_text(handoff, encoding='utf-8'); files.append('CLAUDE-CONSISTENCY-HANDOFF.md')
    rows = ''.join(f"<tr><td>{c['name']}</td><td><a href='{c['report']}'>{c['passed']}/{c['total']}</a></td></tr>" for c in checks)
    stages = ['Primitives', 'Transformation', 'Arrays', 'Colour', 'Tiling', 'Change']
    gallery = ''.join(f"<details><summary>{i+1}. {name}</summary><div class='pair'><figure><img loading='lazy' src='consistency-before-stage-{i}.png' alt='{name}, before'><figcaption>Before</figcaption></figure><figure><img loading='lazy' src='consistency-after-stage-{i}.png' alt='{name}, after'><figcaption>After</figcaption></figure></div></details>" for i, name in enumerate(stages))
    runtime_list = ''.join(f'<li><code>{html.escape(p)}</code></li>' for p in RUNTIME)
    page = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Biome consistency · keep the work</title><style>
*{box-sizing:border-box}body{margin:0;background:#f5f3ed;color:#252821;font:17px/1.6 system-ui,sans-serif}main{max-width:1360px;margin:auto;padding:35px 5vw 80px}nav{display:flex;gap:20px;flex-wrap:wrap;font-size:14px}a{color:#315e47;text-underline-offset:4px}h1{font:clamp(40px,5vw,70px)/1.08 Georgia,serif;max-width:850px;margin:35px 0 24px}h2{font:32px/1.2 Georgia,serif;margin-top:44px}.intro{font-size:22px;max-width:870px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}figure{margin:22px 0}img{width:100%;height:auto;display:block}figcaption,small{font-size:14px;color:#596454}figcaption{margin-top:8px}table{border-collapse:collapse;width:100%;max-width:900px}td,th{padding:12px;text-align:left;border-bottom:1px solid #cbd1c3}.play{padding:20px;border-left:3px solid #315e47;background:#e8ecdf}.limits{font-size:14px;max-width:950px}code{font-size:13px;overflow-wrap:anywhere}details{border-top:1px solid #cbd1c3;padding:12px 0}summary{cursor:pointer}section{scroll-margin-top:24px}@media(max-width:760px){.pair{grid-template-columns:1fr}main{padding:25px 18px}}@media print{nav{display:none}figure{break-inside:avoid}}
</style></head><body><main><nav><a href="index.html">Biome ladder</a><a href="change.html">Previous: Change</a><a href="scaffold.html#route">Edit the plan</a><a href="CLAUDE-CONSISTENCY-HANDOFF.md">Claude's handoff</a></nav><p><small>B22 · SIX-STAGE CONSISTENCY · 13 OCTOBER 2026</small></p><h1>Keep the work.<br>Read the next shot.</h1><p class="intro">Prepare the floor, then test it against the skulls. Starting combat now keeps what you made. A missed shot has a visible ending.</p>
<div class="play"><b>Game menu → Biome Ladder.</b> Compare stages 1–6. START/RESUME keeps your work; REST clears shots; RESET restores the encounter. Forces waits for this review.</div>
<section><h2>A warning you can see</h2><div class="pair"><figure><img src="consistency-before-row-warning.png" alt="Before: thin attack guides in the Arrays biome"><figcaption>Before · one-pixel path lines.</figcaption></figure><figure><img src="consistency-after-row-warning.png" alt="After: bright upcoming paths with dark edges in the Arrays biome"><figcaption>After · 4 cm warning paths, larger rule text, near-eye fade.</figcaption></figure></div><details><summary>Compare the column warning</summary><div class="pair"><figure><img src="consistency-before-column-warning.png" alt="Before column warning"><figcaption>Before</figcaption></figure><figure><img src="consistency-after-column-warning.png" alt="After column warning"><figcaption>After</figcaption></figure></div></details><p>The flight guide is thinner and dimmer than the upcoming warning. Both the shot and its guide disappear on impact, at the list's end or after leaving the playable bounds.</p></section>
<section><h2>Starting keeps the experiment</h2><figure><img src="consistency-after-prepared-and-running.png" alt="Tiling in play with the visitor's earlier transformed and painted tiles retained"><figcaption>Tiling · prepared floor edits remain after START/RESUME. The probe also checks vacancies, health and consumed pickups in every stage.</figcaption></figure><table><tr><th>Control</th><th>What happens</th></tr><tr><td>START / RESUME</td><td>Activate surviving heads. Keep floor, damage and pickups. Give the next group a fresh warning.</td></tr><tr><td>REST</td><td>Stop attacks and clear shots. Keep your work. Landscape motion continues.</td></tr><tr><td>RESET</td><td>Restore heads, pickups, health and floor. After CLEAR, reset explicitly to replay.</td></tr></table><p class="limits">Changing stage still starts a fresh floor. This is continuity inside the current encounter, not a cross-stage save system.</p></section>
<section><h2>The missed shot reaches a surface</h2><div class="pair"><figure><img src="consistency-after-landing-path.png" alt="Side view of a warning path with its final descent to a floor tile"><figcaption>The same zigzag gains one announced floor landing.</figcaption></figure><figure><img src="consistency-after-skull-floor-landing.png" alt="Floor tile painted by actual missed skull shots"><figcaption>A real collision leaves colour. All nine tested misses reached a tile.</figcaption></figure></div><p>Cover and gaps still matter. Only an actual tile impact paints it. Change's centre balls retain their field, warning and straight commitment; the outer columns keep the stored path.</p></section>
<section><h2>The six arrivals</h2><p>Matching standing views before and after this pass. These capture the test world's actual Godot rendering.</p>__GALLERY__</section>
<section id="review"><h2>Ready for Claude to check</h2><p><a href="CLAUDE-CONSISTENCY-HANDOFF.md">Exact review brief and captures</a> · <a href="CONSISTENCY.md">Full report</a> · <a href="consistency-runtime.patch">Runtime diff</a> · <a href="consistency-evidence.json">Source hashes</a></p><ul>__FILES__</ul><table><tr><th>Runtime check</th><th>Passed</th></tr>__ROWS__</table><p class="limits">Runs exit 0 with no script errors or failed assertions; existing ObjectDB shutdown warnings remain. A 32-second normal volley loop sent 21 balls, peaking at six balls and six guides. Claude should rerun its independent clutter case. These are desktop and controlled-input checks, not physical headset validation. Console and glow placement, headset feel and the older Flow_Field cleanup issue remain open. No Forces stage or book text was added.</p></section></main></body></html>'''
    page = page.replace('__GALLERY__', gallery).replace('__FILES__', runtime_list).replace('__ROWS__', rows)
    (OUT / 'consistency.html').write_text(page, encoding='utf-8'); files.append('consistency.html')
    for name in files: shutil.copy2(OUT / name, PUBLIC / name)
    print('Published consistency.html and Claude handoff; ' + str(sum(c['passed'] for c in checks)) + ' passing assertions')


if __name__ == '__main__': publish()
