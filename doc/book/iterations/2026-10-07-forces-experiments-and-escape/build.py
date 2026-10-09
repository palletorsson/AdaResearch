"""Render the editable scene proposal. This does not modify museum content."""
from pathlib import Path
import html
import json

HERE = Path(__file__).resolve().parent
data = json.loads((HERE / 'proposal.json').read_text(encoding='utf-8'))
e = html.escape

def source_link(path):
    return f'<a href="../../../../{e(path)}">{e(path)}</a>'

def image_block(path, title):
    if not path:
        return ''
    return f'<figure><a href="{e(path)}"><img loading="lazy" src="{e(path)}" alt="Earlier concept-art reference for {e(title)}"></a><figcaption>Earlier concept illustration, reused as a reference. Not a native capture or proof of the proposed interaction.</figcaption></figure>'

theory = ''
for p in data['theory']:
    citation = f' <a href="{e(p["source"])}">{e(p["label"])}</a>' if p['source'] else ''
    theory += f'<p>{e(p["text"])}{citation}</p>'

rows = ''.join(f'<tr><td>{s["id"]}</td><td><a href="#scene-{s["id"]}">{e(s["title"])}</a><small>{e(s["role"])}</small></td><td>{e(s["focus"])}</td></tr>' for s in data['scenes'])
cards = []
for s in data['scenes']:
    fields = [('The instruction', 'task'), ('Learn', 'focus'), ('What else could happen', 'event'), ('What the player can do', 'choice'), ('What travels onward', 'onward')]
    body = ''.join(f'<div class="entry"><h3>{label}</h3><p>{e(s[key])}</p></div>' for label, key in fields)
    sources = ''.join(f'<li>{source_link(p)}</li>' for p in s['sources'])
    visual = image_block(s['image'], s['title'])
    cards.append(f'''<section class="scene" id="scene-{s['id']}" data-role="{e(s['role'])}">
      <header><span class="number">{s['id']}</span><div><p class="eyebrow">{e(s['chapter'])} / {e(s['role'])}</p><h2>{e(s['title'])}</h2></div></header>
      <div class="scene-body {'with-image' if visual else ''}"><div>{body}</div>{visual}</div>
      <p class="placement"><strong>Candidate existing halls:</strong> {e(' · '.join(s['halls']))}</p>
      <details><summary>Implementation boundary and proposed test</summary><p>{e(s['gap'])}</p><p><strong>Test to write:</strong> {e(s['check'])}</p><ul>{sources}</ul></details>
      <a class="back" href="#route">Back to the route ↑</a>
    </section>''')

evidence = ''.join(f'<article><h3>{e(x["title"])}</h3><p>{e(x["text"])}</p><ul>'+''.join(f'<li>{source_link(p)}</li>' for p in x['paths'])+'</ul></article>' for x in data['evidence'])
rules = ''.join(f'<li>{e(x)}</li>' for x in data['design_rules'])
priorities = ''.join(f'<li>{e(x)}</li>' for x in data['priorities'])
sources = ''.join(f'<li><a href="{e(x["url"])}">{e(x["label"])}</a></li>' for x in data['sources'])

page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{e(data['title'])} · Endless Museum</title>
<style>
:root{{color-scheme:light;--paper:#f1eee7;--ink:#25251f;--muted:#68665f;--line:#d5d0c3;--accent:#8b3d2c}}
*{{box-sizing:border-box}}html{{scroll-behavior:smooth}}body{{margin:0;background:var(--paper);color:var(--ink);font:18px/1.55 Georgia,serif}}a{{color:var(--accent);text-underline-offset:3px}}nav{{display:flex;gap:20px;flex-wrap:wrap;padding:18px 4vw;border-bottom:1px solid var(--line);font:14px/1.5 system-ui}}main{{max-width:1160px;margin:auto;padding:36px 28px}}h1{{font-size:clamp(40px,6vw,78px);line-height:1.02;letter-spacing:-.035em;margin:18px 0}}h2{{font-size:31px;line-height:1.15;margin:8px 0 20px}}h3{{font-size:20px;margin:20px 0 6px}}p{{margin:0 0 16px}}.eyebrow,small,figcaption,.status,.placement,details,.back{{font-family:system-ui,sans-serif}}.eyebrow{{font-size:12px;letter-spacing:.09em;text-transform:uppercase;color:var(--muted)}}.lede{{font-size:24px;max-width:840px}}.status{{font-size:13px;padding:16px;border-left:3px solid var(--accent);background:#e9e4d9}}.reading{{max-width:820px;margin:44px auto}}.reading li{{margin-bottom:12px}}.hero{{display:grid;grid-template-columns:1.3fr 1fr;gap:32px;align-items:start}}figure{{margin:0}}img{{display:block;width:100%;height:auto;border:1px solid var(--line)}}figcaption{{font-size:11px;line-height:1.4;color:var(--muted);margin-top:8px}}table{{width:100%;border-collapse:collapse;margin:25px 0 40px;font-size:17px}}td,th{{padding:13px 10px;border-bottom:1px solid var(--line);text-align:left;vertical-align:top}}th{{font:12px system-ui;letter-spacing:.08em;text-transform:uppercase}}td:first-child{{width:40px;color:var(--muted)}}td:nth-child(2){{width:36%}}small{{display:block;font-size:11px;color:var(--muted);margin-top:6px}}.scene{{margin:34px 0;padding:28px;background:#fffdf8;border:1px solid var(--line);scroll-margin-top:20px}}.scene header{{display:flex;gap:22px;border-bottom:1px solid var(--line);margin-bottom:24px}}.number{{font:48px/.95 Georgia;color:#9c9788}}.scene h2{{margin-bottom:20px}}.scene-body.with-image{{display:grid;grid-template-columns:1.25fr .8fr;gap:36px}}.entry h3{{font:12px system-ui;text-transform:uppercase;letter-spacing:.06em;color:var(--accent);margin:4px 0 6px}}.entry p{{margin-bottom:20px}}.placement{{font-size:13px;border-top:1px solid var(--line);padding-top:16px;overflow-wrap:anywhere}}details{{font-size:14px}}summary{{cursor:pointer;margin-bottom:12px}}details li{{overflow-wrap:anywhere}}.back{{font-size:12px;display:inline-block;margin-top:14px}}.evidence{{border-top:1px solid var(--line);padding-top:22px}}.evidence ul{{font:12px/1.6 system-ui;overflow-wrap:anywhere}}footer{{padding:30px 4vw;border-top:1px solid var(--line);font:13px system-ui}}@media(max-width:750px){{.hero,.scene-body.with-image{{grid-template-columns:1fr}}main{{padding:24px 16px}}.scene{{padding:20px}}td{{font-size:14px}}}}@media print{{nav,.back,details{{display:none}}body{{background:white;font-size:11pt}}main{{max-width:none;padding:0}}h1{{font-size:40pt}}.scene{{break-before:page;border:0;margin:0;padding:20px 0}}a{{color:inherit}}.scene-body.with-image{{grid-template-columns:1.2fr 1fr}}}}
</style></head><body><nav><strong>ENDLESS MUSEUM / FORCES</strong><a href="#route">14 encounters</a><a href="#cybernetics">Cybernetics</a><a href="#evidence">What exists</a><a href="#next">First builds</a><a href="REPORT.md">Full text</a><a href="proposal.json">Editable plan</a></nav>
<main><div class="hero"><div><p class="eyebrow">7 October 2026 · scene proposal</p><h1>{e(data['title'])}</h1><p class="lede">{e(data['premise'])}</p><p>One instruction: carry the point across the room. A growing capacity to act. A growing awareness of what else acts with you.</p><p class="status">{e(data['status'])}</p></div>{image_block('../2026-10-07-everything-worked/everything-worked.png','the delivery experiment')}</div>
<article class="reading" id="cybernetics"><h2>What cannot this apparatus contain?</h2>{theory}<p>The dramatic turn need not be a secret monster. It may be a door that opens too far, a successful delivery that moves its receiver, or a factory whose correct output occupies its exit.</p></article>
<section id="route"><p class="eyebrow">From capacity to consequence</p><h2>{e(data['subtitle'])}</h2><p>{e(data['route_note'])}</p><table><thead><tr><th>#</th><th>Encounter</th><th>Learning focus</th></tr></thead><tbody>{rows}</tbody></table></section>
{''.join(cards)}
<article class="reading"><h2>How to keep the lesson clear</h2><ol>{rules}</ol><p>For every apparatus, record four things: the intended outcome, the variables it observes, the actions available to it, and the disturbance under which its promise fails. Make that limit something the student can investigate and change.</p><p>The critical opening is specific: which bodies were counted as cargo, which variations were treated as error, and which arrangements must be restored? An unexpected arrangement can sometimes be kept. That offers a place for queer reflection without assigning a moral identity to a force law.</p></article>
<section class="evidence" id="evidence"><p class="eyebrow">Source inspection, not a new engine run</p><h2>What we can already build from</h2>{evidence}</section>
<article class="reading" id="next"><h2>The first builds</h2><ol>{priorities}</ol><p><strong>Test the rules, not the joke.</strong> A spectacular collapse should not be a passing assertion. A successful baseline, causal response, retained aftermath and deliberate reset should be.</p><h3>References</h3><ul>{sources}</ul><p><a href="../2026-10-07-forces-artifacts-through-consequence/index.html">Earlier eight artifact families</a> · <a href="../2026-10-06-forces-the-point-gains-power/index.html">Accepted flight input and earlier ability proposal</a></p></article></main><footer>Always another room. Always another consequence. · Edit proposal.json, then run build.py to refresh this reading and REPORT.md.</footer></body></html>'''
(HERE / 'index.html').write_text(page, encoding='utf-8')

md = [f'# {data["title"]}', data['subtitle'], data['status'], data['premise'], '## Cybernetics and the experiment']
for p in data['theory']:
    md.append(p['text'] + (f' [{p["label"]}]({p["source"]})' if p['source'] else ''))
md.extend(['## Fourteen encounters', data['route_note']])
for s in data['scenes']:
    md.extend([f'### {s["id"]}. {s["title"]}', f'{s["chapter"]} · {s["role"]}', f'Candidate halls: {", ".join(s["halls"])}'])
    for label,key in [('Task','task'),('Learn','focus'),('Possible consequence','event'),('Player choices','choice'),('Carry forward','onward'),('Implementation boundary','gap'),('Proposed test','check')]:
        md.append(f'**{label}:** {s[key]}')
    if s['sources']:
        md.append('Source references:\n\n'+'\n'.join(f'- [{p}](../../../../{p})' for p in s['sources']))
md.extend(['## Writing and implementation rules','\n'.join(f'{i}. {x}' for i,x in enumerate(data['design_rules'],1)), '## Existing evidence'])
for item in data['evidence']:
    md.extend([f'### {item["title"]}',item['text'],'\n'.join(f'- [{p}](../../../../{p})' for p in item['paths'])])
md.extend(['## First builds','\n'.join(f'{i}. {x}' for i,x in enumerate(data['priorities'],1)), '## References','\n'.join(f'- [{x["label"]}]({x["url"]})' for x in data['sources'])])
(HERE / 'REPORT.md').write_text('\n\n'.join(md)+'\n', encoding='utf-8')
print(f'Rendered {len(data["scenes"])} scene briefs to index.html and REPORT.md')
