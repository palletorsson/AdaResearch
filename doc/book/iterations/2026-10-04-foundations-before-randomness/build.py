"""Render the proposed foundation plan. Does not edit museum or route data."""
from pathlib import Path
from html import escape
import hashlib
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
GUIDE = ROOT / 'doc/book/course/storyboards/FOUNDATIONS_TO_RANDOMNESS.md'
ROUTE = ROOT / 'doc/book/iterations/2026-10-04-museum-tutorial-storyboards/route.json'
ROUTE_URL = '/book-review/doc/book/iterations/2026-10-04-museum-tutorial-storyboards/index.html'

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def main():
    plan, route = read(HERE / 'plan.json'), read(ROUTE)
    halls = {h['id']: h for h in route['halls']}
    plan_ids = [s['id'] for s in plan['sequences']]
    assert plan_ids == [s['id'] for s in route['sequences'][:4]]
    for seq in plan['sequences']:
        assert [h['map'] for h in seq['halls']] == [h['id'] for h in route['halls'] if h['sequence'] == seq['id']]
    for concept in plan['coverage']:
        for stage in ('first', 'practice', 'demonstrate'):
            assert concept[stage]
            for hall in concept[stage]:
                assert hall in halls and halls[hall]['sequence'] in plan_ids, (concept['subject'], hall)
    route_ids = [s['id'] for s in route['sequences']]
    assert [s['id'] for s in plan['consolidation']] == route_ids[4:9]
    assert route_ids[9] == 'randomness'
    count = sum(len(s['halls']) for s in plan['sequences'])

    def hall_link(hall):
        return f'<a href="{ROUTE_URL}#hall={escape(hall, quote=True)}&amp;view=walk&amp;summary=short">{escape(hall.replace("_", " "))}</a>'

    def links(ids):
        return '<br>'.join(hall_link(h) for h in ids)

    md = ['# Foundations before Randomness', '', f'{plan["date"]}. **{plan["status"]}.**', '', plan['purpose'], '', plan['scope'], '', plan['principle'], '',
          '## Target', '', plan['baseline']['text'], '', f'[The Nature of Code prerequisites]({plan["baseline"]["url"]}).', '',
          'Use the existing hall order. First exposure, practice and independent use are different stages. A supplied callback or renderer may be used before its implementation is taught. All checks below are proposed learner actions, not results already observed.', '']
    for i, seq in enumerate(plan['sequences'], 1):
        md += [f'## {i}. {seq["title"]} — {seq["promise"]}', '', '**Leave able to:** ' + seq['exit'], '',
               '| Hall | Role and selected learning | Practice / carry | Independent variation | Supplied |', '| --- | --- | --- | --- | --- |']
        for h in seq['halls']:
            md.append(f'| {h["map"]} | **{h["mode"]}.** {h["introduce"]} | {h["practice"]} | {h["check"]} | {h["supplied"]} |')
        md += ['']
    md += ['## Coverage register', '', '| Subject | First explicit encounter | Practise | Demonstrate | Observable capacity |', '| --- | --- | --- | --- | --- |']
    for c in plan['coverage']:
        md.append('| ' + ' | '.join([c['subject'], ', '.join(c['first']), ', '.join(c['practice']), ', '.join(c['demonstrate']), c['criterion']]) + ' |')
    md += ['', '## Rehearse between Colour and Randomness', '']
    for seq in plan['consolidation']:
        md += [f'### {seq["title"]}', '', seq['reuse'], '', seq['limit'], '']
    md += ['## Readiness, observed through making', '', plan['ready']['task'], '', plan['ready']['meaning'], '', plan['ready']['if_not_ready'], '', 'Deferred until useful:', '']
    md += ['- ' + item for item in plan['ready']['not_required']]
    md += ['', '## One tutorial at a time', '']
    md += [f'{i}. {step}' for i, step in enumerate(plan['workflow'], 1)]
    md += ['', '## Decisions still open', ''] + ['- ' + point for point in plan['open']]
    md += ['', '## Evidence and maintenance', '', 'Current summaries and selected source/companion texts informed this plan. Source reading is not learner testing. The older subject register is a comparison, not the authority when it conflicts with museum summaries.', '',
           'Edit `doc/book/iterations/2026-10-04-foundations-before-randomness/plan.json`, then run its `build.py`. This rebuilds this guide, the review page and a source manifest; it never promotes teaching decisions.', '']
    md += [f'- `{source}`' for source in plan['sources']]
    GUIDE.write_text('\n'.join(md) + '\n', encoding='utf-8')

    cards = []
    detailed = []
    for i, seq in enumerate(plan['sequences'], 1):
        cards.append(f'<a class="stage" href="#{seq["id"]}"><span class="number">0{i} / {len(seq["halls"])} halls</span><h2>{escape(seq["title"])}</h2><p class="promise">{escape(seq["promise"])}</p><p>{escape(seq["exit"])}</p></a>')
        rows = []
        for h in seq['halls']:
            rows.append(f'<article class="hall"><header><p class="role">{escape(h["mode"])}</p><h3>{hall_link(h["map"])}</h3></header><div><p class="teach">{escape(h["introduce"])}</p><p>{escape(h["practice"])}</p><p class="check"><b>Try independently</b> {escape(h["check"])}</p><p class="supply"><b>Supplied</b> {escape(h["supplied"])}</p></div></article>')
        detailed.append(f'<details id="{seq["id"]}" class="sequence"><summary><span>0{i} · {escape(seq["title"])}</span><span>{len(seq["halls"])} hall choices</span></summary><p class="exit"><b>Leave able to</b> {escape(seq["exit"])}</p>{"".join(rows)}</details>')
    matrix = ''.join(f'<tr><th scope="row">{escape(c["subject"])}</th><td>{links(c["first"])}</td><td>{links(c["practice"])}</td><td>{links(c["demonstrate"])}</td><td>{escape(c["criterion"])}</td></tr>' for c in plan['coverage'])
    practice = ''.join(f'<article><h3>{escape(s["title"])}</h3><p>{escape(s["reuse"])}</p><p class="supply">{escape(s["limit"])}</p></article>' for s in plan['consolidation'])
    points = lambda xs: ''.join('<li>' + escape(x) + '</li>' for x in xs)
    css = '''
:root{--paper:#f5f3ed;--ink:#243d35;--muted:#62736b;--line:#d5ddd3;--rose:#985369;--card:#fffefa}*{box-sizing:border-box}html{scroll-padding-top:24px}body{margin:0;background:var(--paper);color:var(--ink);font:15px/1.6 system-ui,sans-serif}main,nav,footer{max-width:1280px;margin:auto;padding:0 32px}nav{display:flex;gap:24px;flex-wrap:wrap;padding-top:18px;padding-bottom:18px;border-bottom:1px solid var(--line);font-size:12px}a{color:inherit;text-underline-offset:3px}a:focus-visible,summary:focus-visible{outline:3px solid var(--rose);outline-offset:4px}.hero{padding:42px 0 26px;max-width:860px}.eyebrow,.number,.role{font-size:10px;letter-spacing:.11em;text-transform:uppercase;font-weight:700;color:var(--muted)}h1,h2,h3{font-family:Georgia,serif;font-weight:400;line-height:1.15}h1{font-size:60px;letter-spacing:-.035em;margin:10px 0 20px}h2{font-size:29px;margin:13px 0}h3{font-size:21px;margin:8px 0 12px}p{margin:10px 0}.lead{font-size:20px}.notice{font-size:12px;color:var(--muted)}.stages{display:grid;grid-template-columns:repeat(4,1fr);gap:16px;margin:8px 0 36px}.stage{background:var(--card);border:1px solid var(--line);padding:21px;text-decoration:none}.stage:hover{border-color:var(--rose)}.stage p{font-size:13px}.stage .promise{font-size:16px;color:var(--rose)}.callout{border-left:3px solid var(--rose);padding:12px 24px;background:#eee8e4;margin-bottom:34px}.callout p{margin:0}.section{margin:34px 0 44px}.sequence{border-top:1px solid var(--line);background:var(--card);scroll-margin:20px}.sequence:last-child{border-bottom:1px solid var(--line)}summary{cursor:pointer;padding:17px 20px;font-weight:650}summary span+span{float:right;font-size:12px;color:var(--muted);font-weight:400}.sequence:target{outline:2px solid var(--rose);outline-offset:3px}.exit{padding:0 22px 20px;color:var(--muted);max-width:1000px}.hall{display:grid;grid-template-columns:240px minmax(0,1fr);gap:26px;padding:20px 24px;border-top:1px solid var(--line)}.hall h3{font-size:21px;overflow-wrap:anywhere}.hall header p{margin-top:0}.teach{font-weight:650;margin-top:0}.check{border-left:2px solid var(--rose);padding-left:12px}.check b,.supply b{display:inline-block;font-size:10px;text-transform:uppercase;letter-spacing:.04em;margin-right:6px}.supply{color:var(--muted);font-size:12px}.scroll{overflow:auto;border:1px solid var(--line)}table{width:100%;border-collapse:collapse;font-size:12px;min-width:860px}th,td{padding:13px 15px;text-align:left;vertical-align:top;border-bottom:1px solid var(--line)}thead{background:#e7ece4}th[scope=row]{font-weight:650;width:18%}td:last-child{width:27%}.practice{display:grid;grid-template-columns:repeat(5,1fr);gap:20px}.practice article{border-top:3px solid var(--line);padding-top:12px}.practice p{font-size:13px}.ready{background:#e7ece4;padding:26px 30px}.ready p{max-width:930px}li{margin:10px 0}footer{border-top:1px solid var(--line);padding-top:20px;padding-bottom:30px;color:var(--muted);font-size:12px}.skip{position:absolute;top:-90px;background:white;padding:10px}.skip:focus{top:0}@media(max-width:1000px){.stages{grid-template-columns:repeat(2,1fr)}.practice{grid-template-columns:repeat(2,1fr)}h1{font-size:48px}}@media(max-width:620px){main,nav,footer{padding-left:18px;padding-right:18px}.stages,.practice{grid-template-columns:1fr}.hall{grid-template-columns:1fr;gap:4px;padding:18px}.hero{padding-top:24px}h1{font-size:40px}.lead{font-size:18px}summary span+span{display:none}.ready{padding:20px}.scroll{max-width:100%}}@media print{@page{size:A3 landscape;margin:14mm}nav,.skip{display:none}main,footer{max-width:none;padding:0}.hero{padding-top:0}h1{font-size:34pt}.stages{grid-template-columns:repeat(4,1fr)}.stage,.ready,.hall{break-inside:avoid}.scroll{overflow:visible}table{min-width:0;font-size:9pt}th,td{padding:8px}.practice{grid-template-columns:repeat(5,1fr)}.section{margin:20px 0}a{text-decoration:none}}
'''
    html = f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Before Randomness · Ada foundations</title><style>{css}</style></head><body>
<a class="skip" href="#plan">Skip to the foundation plan</a><nav><a href="/research-outline">Research outline</a><a href="#plan">Hall plan</a><a href="#coverage">Concept coverage</a><a href="#ready">Readiness</a><a href="/book-review/doc/book/course/storyboards/FOUNDATIONS_TO_RANDOMNESS.md">Full text</a></nav>
<main><header class="hero"><p class="eyebrow">Ada / Proposed curriculum · {plan['date']} · {count} halls</p><h1>Before Randomness</h1><p class="lead">{escape(plan['purpose'])}</p><p>{escape(plan['principle'])}</p><p class="notice">{escape(plan['scope'])}</p></header>
<div class="stages">{''.join(cards)}</div><aside class="callout"><p><b>Introduce → practise → use independently.</b> The six foundations are variables, conditions, loops, functions, arrays and objects. <a href="{plan['baseline']['url']}">The Nature of Code assumes these already.</a> Every hall does not need a new language concept.</p></aside>
<section class="section" id="plan"><h2>The teaching choices, hall by hall</h2><p class="notice">Open a sequence for its proposed teaching, independent variation and supplied support. Hall links open the current museum storyboard; those summaries have not been rewritten by this proposal.</p>{''.join(detailed)}</section>
<section class="section" id="coverage"><h2>Where a capability becomes usable</h2><p class="notice">These are planned opportunities, not completed learner assessments. The same hall may contain several short steps. An operation used through a supplied interface does not imply its implementation has been taught.</p><div class="scroll"><table><thead><tr><th>Capability</th><th>First explicit encounter</th><th>Practise</th><th>Demonstrate</th><th>What the learner can do</th></tr></thead><tbody>{matrix}</tbody></table></div></section>
<section class="section"><h2>Then let the foundations work</h2><p>Colour closes the first foundation pass. Five existing sequences give those capacities further work before Randomness.</p><div class="practice">{practice}</div></section>
<section class="section ready" id="ready"><h2>{escape(plan['ready']['title'])}</h2><p>{escape(plan['ready']['task'])}</p><p>{escape(plan['ready']['meaning'])}</p><p>{escape(plan['ready']['if_not_ready'])}</p><details><summary>What can wait</summary><ul>{points(plan['ready']['not_required'])}</ul></details></section>
<section class="section"><h2>Write one tutorial at a time</h2><ol>{points(plan['workflow'])}</ol></section><section class="section"><details><summary>Open teaching contracts and source differences</summary><ul>{points(plan['open'])}</ul></details></section>
</main><footer>Source-informed proposal · no runtime or learner test in this planning pass · <a href="plan.json">Editable plan data</a> · <a href="manifest.json">Source record</a></footer></body></html>'''
    (HERE / 'index.html').write_text(html, encoding='utf-8')
    sources = [ROOT / p for p in plan['sources']] + [HERE / 'plan.json']
    manifest = {'date': plan['date'], 'status': plan['status'], 'hall_count': count, 'sequence_count': len(plan_ids),
                'coverage_count': len(plan['coverage']), 'validated': ['first four sequences match current route', 'all 35 halls in existing order', 'coverage references valid', 'five consolidation sequences precede Randomness'],
                'limitations': ['source review only', 'learner readiness untested', 'planned bindings not implemented'],
                'sources': [{'path': p.relative_to(ROOT).as_posix(), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in sources]}
    (HERE / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'Rendered {len(plan_ids)} sequences / {count} halls / {len(plan["coverage"])} capability chains. Route untouched.')

if __name__ == '__main__':
    main()
