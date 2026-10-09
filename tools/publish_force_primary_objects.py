"""Render the editable hands-first Forces proposal; never mutate museum content."""
from pathlib import Path
import hashlib
import html
import json

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'doc/book/course/forces-primary-objects.json'
OUT = ROOT / 'doc/book/iterations/2026-10-07-forces-through-the-hands'
CURATED = '../2026-10-07-forces-curated-progression'
BODY = '../2026-10-07-forces-teleport-and-body'


def esc(value):
    return html.escape(str(value))


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def source_link(path):
    return f'<a href="sources/{esc(path)}">{esc(Path(path).name)}</a>'


def main():
    data = read(SOURCE)
    current = read(ROOT / 'commons/artifacts/force_halls/curation.json')['halls']
    assert [h['map'] for h in data['halls']] == [h['map'] for h in current]
    sources = {p for h in data['halls'] + data['catalyst_audit'] for p in h['sources']}
    sources.add('commons/artifacts/force_halls/curation.json')
    sources.add('commons/maps/sequences/forces.json')
    for h in current:
        for name in ['tutorial.md', 'FORCES_LESSON.md', 'map_data.json']:
            sources.add(f'commons/maps/{h["map"]}/{name}')
        assert (OUT.parent / Path(CURATED).name / 'after' / h['map'] / 'entry.png').is_file()
    for path in sources:
        assert (ROOT / path).is_file(), path
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'plan.json').write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf8')
    snapshot = {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in sorted(sources)}
    for path in sources:
        captured = OUT / 'sources' / path
        captured.parent.mkdir(parents=True, exist_ok=True)
        captured.write_bytes((ROOT / path).read_bytes())
    (OUT / 'source-audit.json').write_text(json.dumps({
        'date': data['date'], 'scope': 'Static source audit; proposed interaction upgrades were not run or implemented.',
        'halls_in_canonical_order': len(current), 'sources': snapshot,
        'writing_status': 'Existing tutorial.md differs from the recently selected FORCES_LESSON.md in several halls. Neither manuscript nor runtime was changed by this publication.'
    }, indent=2) + '\n', encoding='utf8')

    page = ['''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Forces through the hands — Endless Museum</title><style>
*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:24px}body{margin:0;background:#f4f0e8;color:#24252a;font:17px/1.6 system-ui,sans-serif}a{color:#87334e;text-underline-offset:3px}a:focus-visible,summary:focus-visible{outline:3px solid #87334e;outline-offset:4px}main{max-width:1360px;margin:auto;padding:42px 5vw 90px}h1,h2,h3{font-family:Georgia,serif;font-weight:400;line-height:1.12}h1{font-size:clamp(40px,5.4vw,74px);max-width:800px;margin:16px 0}h2{font-size:clamp(29px,3.5vw,46px);margin:12px 0 22px}h3{font-size:29px;margin:12px 0}.eyebrow,.tag{font:12px/1.5 system-ui;letter-spacing:.1em;text-transform:uppercase;color:#87334e}.lead{font:24px/1.5 Georgia,serif;max-width:920px}.links{display:flex;gap:13px 25px;flex-wrap:wrap;margin:24px 0}.note{background:#e9e1d6;border-left:3px solid #87334e;padding:17px 22px;max-width:980px}.small,figcaption{font-size:13px;color:#625c59}.small{max-width:900px}section{border-top:1px solid #c9c0b3;padding:38px 0;margin-top:30px}table{width:100%;border-collapse:collapse;font-size:15px}th{text-align:left;color:#625c59;font-size:12px;letter-spacing:.06em;text-transform:uppercase}td,th{border-bottom:1px solid #d5cbbd;padding:14px 12px;vertical-align:top}td:first-child{width:48px}td:nth-child(2){width:26%}td:nth-child(3){width:29%}table a{text-decoration:none}table a:hover{text-decoration:underline}.twocol{display:grid;grid-template-columns:1.08fr 1fr;gap:30px;align-items:start}.twocol img{width:100%;display:block}.hero{margin:28px 0}.hero img{width:100%;display:block;max-height:660px;object-fit:contain;background:#292d36}figure{margin:0}figcaption{padding:9px 0}.claim{padding:20px 22px;background:#e6dfd4;margin:18px 0}.wild{border-left:3px solid #bd7492;padding-left:20px}p{max-width:970px}details{border-top:1px solid #c9c0b3;padding:16px 0}summary{cursor:pointer;font-weight:600}details p{font-size:16px}code{font:13px ui-monospace,monospace;overflow-wrap:anywhere}.audit{display:grid;grid-template-columns:1fr 1fr;gap:22px}.audit article{padding:23px;background:#ebe5da}.audit h3{font-size:25px}.audit p{font-size:15px}li{margin-bottom:13px;max-width:970px}.hallnav{display:flex;justify-content:space-between;gap:20px;margin-bottom:22px}.source{overflow-wrap:anywhere;font-size:13px}.sticky-link{position:fixed;right:15px;bottom:15px;background:#25272a;color:#f4f0e8;border-radius:30px;padding:9px 15px;font-size:13px;text-decoration:none;box-shadow:0 2px 12px #0003}@media(max-width:780px){main{padding:25px 18px 80px}.twocol,.audit{grid-template-columns:1fr}.lead{font-size:21px}table{font-size:13px}td,th{padding:10px 6px}td:first-child{width:26px}td:nth-child(4),th:nth-child(4){display:none}}@media print{.sticky-link{display:none}details{display:block}section{break-inside:avoid}a{color:inherit}}
</style></head><body><main><header><div class="eyebrow">Endless Museum / Forces / editable proposal / 7 October 2026</div>
<h1>Put the experiment<br>in the player's hands.</h1>
<p class="lead">A point you can push. A spring you can stretch. A support you can remove. The room starts answering before you know where the experiment will end.</p>
<p>One primary object per hall. More than one possible consequence. The familiar sphere carries the learning; cubes, slopes, hinges and baskets give its actions something to meet.</p>
<nav class="links"><a href="#list">Forces + primary objects</a><a href="#catalyst">What the catalyst actually does</a><a href="#rules">Interaction rules</a><a href="#build">Build order</a><a href="PRIMARY_OBJECTS.md">Text report</a><a href="#editing">Edit the plan</a></nav>
<p class="note"><strong>This is the selection and upgrade plan.</strong> The images show today's real museum. Proposed hand controls, physical breakage and the walk-in vortex have not been built by this report. Current hall order, Keep decisions, museum code and manuscripts are preserved.</p>
</header><section id="list"><div class="eyebrow">Current route / one continuing lineage</div><h2>What we follow.</h2>
<p>Place → combine → decompose → release → push → enter a field → resist → stretch → obstruct → attract → destabilise → strike → fly.</p>
<table><thead><tr><th>#</th><th>Subject</th><th>Primary object</th><th>Player action</th></tr></thead><tbody>''']
    md = [f'# {data["title"]}\n', f'**Status:** {data["status"]}\n', data['brief'] + '\n', '## Force and primary-object list\n', '| Hall | Subject | Primary object | Action |', '| --- | --- | --- | --- |']
    for i, h in enumerate(data['halls'], 1):
        page.append(f'<tr><td>{i:02}</td><td><a href="#{h["map"]}">{esc(h["principle"])}</a></td><td>{esc(h["primary"])}</td><td>{esc(h["gesture"])}</td></tr>')
        md.append(f'| {i:02} — {h["map"]} | {h["principle"]} | {h["primary"]} | {h["gesture"]} |')
    page += [f'</tbody></table><p class="small">{esc(data["order_judgment"])}</p></section>', '<section id="catalyst"><div class="eyebrow">Source audit</div><h2>One lineage. Three implementations.</h2><p>The visual continuity is promising, but it is not yet a single carried tool. These are the integration edges we need to work on.</p><div class="audit">']
    md += ['\n## Order and lineage\n', data['order_judgment'], '\n' + data['object_lineage'], '\n## Catalyst audit\n']
    for a in data['catalyst_audit']:
        page.append(f'<article><h3>{esc(a["object"])}</h3><p>{esc(a["implemented"])}</p><p><b>Still to connect:</b> {esc(a["gap"])}</p><details><summary>Source files</summary><p class="source">' + ' · '.join(source_link(p) for p in a['sources']) + '</p></details></article>')
        md += [f'### {a["object"]}\n', a['implemented'], '\n**Gap:** ' + a['gap'], '\nSources: ' + ', '.join(f'`{p}`' for p in a['sources']) + '\n']
    page.append(f'</div><p class="note">{esc(data["integration_decision"])}</p><figure class="hero"><a href="{BODY}/visor/body-visor-flight.png"><img src="{BODY}/visor/body-visor-flight.png" alt="Actual museum capture of flight with the body visor" loading="lazy"></a><figcaption>Already built: the two black flight points in the final capability court. Aim down/back and hold the triggers. The visor shows the same acceleration used to move the body. <a href="{BODY}/index.html">Existing controls and verification</a>.</figcaption></figure><p>To find the flying spheres directly, run <code>commons/scenes/force_capability_museum.tscn</code>. They are in the court beyond the field crossing. Their current movement effect is local to that court.</p></section>')
    md += ['\n**Integration decision:** ' + data['integration_decision'], '\nFlying points: `Vectors_Act5_ForceAsPlace`, capability court. Direct entry: `commons/scenes/force_capability_museum.tscn`.\n', '## Interaction rules\n']
    page.append('<section id="rules"><div class="eyebrow">Shared interaction language</div><h2>Hands first. Controls within reach.</h2><ol>')
    for rule in data['interaction_rules']:
        page.append(f'<li>{esc(rule)}</li>')
        md.append('- ' + rule)
    page.append('</ol><p class="note"><b>The interface is part of the experiment:</b> holding the gate closed should mean holding the gate. Extra controls should help compare a result, not impersonate the action the player came to perform.</p></section>')
    md += ['\n## Hall-by-hall changes\n']
    for i, (h, old) in enumerate(zip(data['halls'], current)):
        m = h['map']
        before = '#list' if i == 0 else '#' + data['halls'][i-1]['map']
        after = '#build' if i == len(data['halls'])-1 else '#' + data['halls'][i+1]['map']
        page.append(f'<section id="{m}"><div class="hallnav"><a href="{before}">← Previous</a><a href="{after}">Next →</a></div><div class="eyebrow">{i+1:02} / {esc(m)} / proposed upgrade</div><h2>{esc(h["title"])}</h2><div class="twocol"><figure><a href="{CURATED}/after/{m}/entry.png"><img src="{CURATED}/after/{m}/entry.png" alt="Current actual museum entrance view for {esc(m)}" loading="lazy"></a><figcaption>Current hall, before this proposed interaction pass. <a href="{CURATED}/index.html#{m}">Spatial arrangement and elevated view</a>.</figcaption></figure><div><div class="tag">{esc(h["principle"])}</div><h3>{esc(h["primary"])}</h3><p><b>In your hands:</b> {esc(h["gesture"])}</p><p class="small">Current lesson selection: <code>{esc(old["tutorial_artifact"])}</code><br>{esc(h["status"])}</p></div></div>')
        page.append(f'<p><b>Today:</b> {esc(h["current"])}</p><p><b>Upgrade:</b> {esc(h["upgrade"])}</p><p class="wild"><b>Let it get wild:</b> {esc(h["wild"])}</p><details><summary>One-paragraph tutorial direction</summary><p>{esc(h["tutorial"])}</p><p><b>Independent check:</b> {esc(h["check"])}</p><p><b>Supporting encounters:</b> {esc(h["support"])}</p><p class="small">This paragraph is a writing contract. It does not claim that the proposed implementation or its assertions already pass.</p></details><details><summary>Current writing and source evidence</summary><p>The recent <code>FORCES_LESSON.md</code> chooses <code>{esc(old["tutorial_artifact"])}</code>. Full <code>tutorial.md</code> is older and may teach another artifact. Reconcile the manuscript with the actual prototype before treating it as the student route.</p><p class="source">' + ' · '.join(source_link(p) for p in h['sources']) + f' · {source_link("commons/maps/"+m+"/FORCES_LESSON.md")} · {source_link("commons/maps/"+m+"/tutorial.md")}</p></details></section>')
        md += [f'### {i+1:02}. {h["title"]} — {m}\n', f'**Subject:** {h["principle"]}. **Primary:** {h["primary"]}.', '\n**Current lesson selection:** `' + old['tutorial_artifact'] + '`; full tutorial.md still needs alignment after implementation.', '\n**Action:** ' + h['gesture'], '\n**Today:** ' + h['current'], '\n**Upgrade:** ' + h['upgrade'], '\n**Consequence:** ' + h['wild'], '\n**Tutorial direction:** ' + h['tutorial'], '\n**Independent check:** ' + h['check'], '\n**Supporting encounters:** ' + h['support'], '\nSources: ' + ', '.join('`'+p+'`' for p in h['sources']) + '\n']
    page.append('<section id="build"><div class="eyebrow">Order of work, not new hall order</div><h2>Make the target rig work first.</h2><p>It tests the whole promise in a small space: a familiar point, a hand action, motion transferred to another body, a hinge, a basket and a recoverable consequence.</p><ol>')
    md.append('## Build order\n')
    for i, step in enumerate(data['build_order'], 1):
        page.append(f'<li>{esc(step)}</li>')
        md.append(f'{i}. {step}')
    page.append('</ol><details><summary>What an upgrade must pass</summary><ul>')
    md.append('\n## Acceptance\n')
    for check in data['acceptance']:
        page.append(f'<li>{esc(check)}</li>')
        md.append('- ' + check)
    page.append('</ul></details><p class="small">This publication checks thirteen-hall coverage, source paths and capture paths. It does not run new physics tests: runtime code is unchanged. Earlier evidence applies to the earlier builds, not to these proposals.</p><nav class="links"><a href="source-audit.json">Audited source snapshot</a><a href="plan.json">Plan snapshot</a><a href="#editing">Edit the plan</a><a href="http://localhost:3003/research/forces-review/index.html">Existing collection and Keep choices</a></nav></section><section id="editing"><h2>A plan that can change.</h2><p>Edit <code>doc/book/course/forces-primary-objects.json</code> in the repository, then run <code>python tools/publish_force_primary_objects.py</code>. This page is a reading view; its <a href="plan.json">JSON download</a> is a snapshot. Source links open audited copies, not a live editor. Changes to this plan do not alter the museum until implemented and checked.</p></section><footer class="eyebrow">Endless Museum · always another room</footer></main><a class="sticky-link" href="#list">↑ Primary-object list</a></body></html>')
    md += ['\n## Evidence boundary\n', 'Static source audit, not new runtime validation. Real hall images are from the prior curated capture. Runtime code, canonical lesson contracts and full manuscripts were not changed. Edit `doc/book/course/forces-primary-objects.json` and run `python tools/publish_force_primary_objects.py` to regenerate this report.\n']
    (OUT / 'index.html').write_text(''.join(page), encoding='utf8')
    (OUT / 'PRIMARY_OBJECTS.md').write_text('\n'.join(md), encoding='utf8')
    print(f'Published {len(current)} hall proposals; verified {len(sources)} source paths and 13 current hall captures.')


if __name__ == '__main__':
    main()
