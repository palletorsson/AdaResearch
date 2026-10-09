from pathlib import Path
import difflib, hashlib, html, json, re
import markdown
H=Path(__file__).resolve().parent
R=H.parents[3]
MAP=R/'commons/maps/Point_One'
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def render(t):
    t=re.sub(r'<!--\s*@[^>]*-->', '', t)
    t=re.sub(r'~~([^~]+)~~', r'<del>\1</del>', t)
    return markdown.markdown(t,extensions=['fenced_code','footnotes','tables'])
checks=[]
def check(name,ok):
    checks.append({'check':name,'passed':bool(ok)})
    assert ok,name
for name,sha in load(H/'preservation.json').items():check('Preserved '+name,digest(R/name)==sha)
core=load(R/'commons/data/museum_core_encounters.json')
old_core=load(H/'before/commons/data/museum_core_encounters.json')
check('Only Point One core entry changed',{k:v for k,v in core['rooms'].items() if k!='Point_One'}=={k:v for k,v in old_core['rooms'].items() if k!='Point_One'} and core['_meta']==old_core['_meta'])
roles=load(R/'commons/data/artifact_roles.json');order=roles['order']['Point_One'];expected=[]
for token in order['primary']:expected.extend(order['primary|'+token[1:]] if token.startswith('@') else [token])
text=(MAP/'final.md').read_text(encoding='utf-8')
check('Primary order matches chapter and ruling',core['rooms']['Point_One']['primary_tokens']==expected==re.findall(r'<!-- @([A-Za-z_0-9]+) -->',text))
for key,name in [('text_sha256','final.md'),('map_sha256','map_data.json')]:check('Current hash '+name,core['rooms']['Point_One'][key]==digest(MAP/name))
d=load(MAP/'map_data.json');placed={t.split('#')[0].split(':')[0].strip() for row in d['layers']['interactables'] for t in row if t.strip()}
check('Primary placements plus configured lobby exist',set(expected)-placed=={'folding_past'} and d['map_info']['museum']['lobby']['enabled'])
registry={}
for path in (R/'commons/artifacts/registry').glob('*.json'):
    try:registry.update(load(path).get('artifacts',{}))
    except (ValueError,UnicodeError):pass
for token in expected:
    entry=registry[token];check('Registered scene '+token,entry.get('map_ready') is True and (R/entry['scene'].removeprefix('res://')).is_file())
prior=load(R/'doc/book/iterations/2026-09-19-primitives-review/after-sha256.json')
for name in ['commons/maps/Point_One/final.md','commons/maps/Point_One/map_data.json','commons/primitives/point/coordinate_readout.gd']:check('Matches earlier observation '+name,digest(R/name)==prior[name])
check('Learner verification stays open',core['rooms']['Point_One']['learner_verified'] is False)
companions=''
for name in ['technical.md','critical.md','artifacts.md']:
    now=(MAP/name).read_text(encoding='utf-8');old=(H/'before/commons/maps/Point_One'/name).read_text(encoding='utf-8')
    for target in re.findall(r'\]\(([^)]+)\)',now):
        if '://' not in target and not target.startswith('#'):check(name+' link '+target,(MAP/target.split('#')[0]).exists())
    (H/(name+'.diff')).write_text(''.join(difflib.unified_diff(old.splitlines(True),now.splitlines(True),fromfile='before/'+name,tofile='current/'+name)),encoding='utf-8')
    companions+='<details><summary>'+name+' — original and current companion</summary><p><a href="'+name+'.diff">Exact diff</a></p><div class="compare"><article><h3>Before this pass</h3>'+render(old)+'</article><article><h3>Current</h3>'+render(now)+'</article></div></details>'
(H/'content-checks.json').write_text(json.dumps(checks,indent=2)+'\n',encoding='utf-8')
walk=[('Already running','The number began before you found it.','frame_counter_display'),('What can wait?','The frames keep folding; the rabbit moves ahead.','folding_past'),('Somewhere to count from','Zero names a reference. The visitor is crossed out.','origin'),('Find what is not drawn','Arrows and lines address an empty centre.','the_invisible_point'),('Give it something to wear','A separate code example builds a visible marker.','code_evolution_screen'),('A position with a body','Pick up the changing point. Carry more than an address.','interactive_point_origin_force'),('Two true addresses','One point, WORLD and LOCAL. What makes each reading legible?','coordinate_readout'),('Close enough','Arrive, leave, return. What does the falling rain recognise?','drag_point_target')]
steps=''.join('<a class="step" href="#'+t+'"><span>'+str(i+1).zfill(2)+'</span><h3>'+title+'</h3><p>'+desc+'</p></a>' for i,(title,desc,t) in enumerate(walk))
chapter='<div class="reading">'+render(re.sub(r'<!--\s*@\s*([A-Za-z_0-9]+)\s*-->',lambda m:'\n<span class="anchor" id="'+m[1]+'"></span>\n',text))+'</div>'
style='''
:root{color-scheme:light;--ink:#242822;--muted:#586259;--paper:#f4f1e8;--line:#ccd0c2;--accent:#235f4d}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.65 system-ui,sans-serif}main{max-width:1180px;margin:auto;padding:48px 28px 100px}h1{font:clamp(40px,6vw,76px)/1.04 Georgia,serif;margin:20px 0}h2{font:32px/1.25 Georgia,serif}h3{font-size:19px}.eyebrow{font:12px/1.5 system-ui;text-transform:uppercase;letter-spacing:.16em;color:var(--muted)}.intro{max-width:760px;font:24px/1.5 Georgia,serif}.note{font-size:14px;color:var(--muted);max-width:850px}a{color:var(--accent);text-underline-offset:.2em}nav{display:flex;flex-wrap:wrap;gap:12px 24px;margin:26px 0 36px}.walk{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin:28px 0}.step{display:block;border:1px solid var(--line);padding:18px;color:inherit;text-decoration:none}.step:hover,.step:focus-visible{background:#e4ebe0;outline:2px solid var(--accent)}.step span{font-size:12px;color:var(--muted)}.step h3{margin:8px 0}.step p{font-size:14px;line-height:1.5;margin:0}figure{margin:32px 0}img{display:block;width:100%;height:auto;border:1px solid var(--line)}figcaption{font-size:14px;color:var(--muted);margin:10px 0;max-width:900px}.reading{max-width:750px;margin:46px auto;font:21px/1.8 Georgia,serif}.reading p{margin:1.25em 0}.reading code{font-size:15px}.reading .footnote{font:14px/1.6 system-ui,sans-serif}.anchor{display:block;scroll-margin-top:30px}pre{font:14px/1.55 Consolas,monospace;overflow-x:auto;background:#e7e9df;padding:20px;border-left:3px solid var(--accent)}code{overflow-wrap:anywhere}details{border-top:1px solid var(--line);padding:18px 0}summary{cursor:pointer;font-weight:600}.compare{display:grid;grid-template-columns:1fr 1fr;gap:26px;font-size:15px}.compare article{min-width:0}.compare table{font-size:12px}table{border-collapse:collapse;width:100%;font-size:15px}td,th{padding:10px;border:1px solid var(--line);text-align:left}blockquote{border-left:3px solid var(--accent);margin:28px 0;padding-left:24px;font:25px/1.55 Georgia,serif}.next{border-top:1px solid var(--line);margin-top:50px;padding-top:25px}@media(max-width:760px){main{padding:28px 18px 70px}.walk{grid-template-columns:1fr 1fr}.compare{grid-template-columns:1fr}.reading{font-size:19px}.compare table{display:block;overflow-x:auto}}
'''
page='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Point One — back to the beginning</title><style>'''+style+'''</style></head><body><main><div class="eyebrow">Ada Research · 21 September 2026 · One hall at a time</div><h1>Back to the beginning.</h1><p class="intro">Point One already knows how to begin late. This pass keeps its chapter, and makes the companion notes describe the same encounter.</p><nav><a href="#chapter">Read Point One</a><a href="/compose/sources?map=Point_One&amp;doc=final">Read and comment</a><a href="/long-museum/encounters?map=Point_One">Encounter map</a><a href="#changes">What changed</a><a href="SUMMARY.md">Saved decisions</a></nav><blockquote>The code we leave unread keeps working.</blockquote><p>There is a working thread here: inherited time, a chosen zero, a position without a body, a body in the hand, two addresses and a tolerance for arriving. These are eight encounters, with room for other works to remain beside them.</p><div class="walk">'''+steps+'''</div><figure><a href="../2026-09-19-primitives-review/point-one-after.png"><img src="../2026-09-19-primitives-review/point-one-after.png" alt="Two framed coordinate readouts, LOCAL and WORLD, on the wall inside Point One." loading="lazy"></a><figcaption>Actual Godot museum capture from 19 September, reused here. Both cards follow the same point. The map, chapter and readout script match that saved comparison. This is earlier desktop evidence, not a new walk or headset test.</figcaption></figure><section id="chapter"><div class="eyebrow">The current chapter · preserved word for word</div>'''+chapter+'''</section><section id="changes"><h2>What changed around the chapter</h2><p>The main text and room are preserved. The encounter record now follows the actual primary order. The inventory includes the current works and the lobby view. The technical companion follows the held point and its two addresses; the older critical draft carries a clear status note.</p><p>No new artifact is needed to make the first investigation possible. Next, observe a complete walk: finding the point, picking it up, reading the two cards and returning to the target. Build further when that encounter reveals a specific need.</p>'''+companions+'''</section><section class="next"><div class="eyebrow">Next hall</div><h2>Two points open a passage.</h2><p>Point Lines begins with a connection that blows apart a barrier. Then a length to measure, a black line to walk beside your trace, and combinations that invite further spatial relations. We will start with what that room already lets the body discover.</p><nav><a href="/compose/sources?map=Point_Lines&amp;doc=final">Read Point Lines</a><a href="/long-museum/encounters?map=Point_Lines">See its encounters</a></nav></section><p class="note">Collective Knowledge's unfinished restoration stays parked. The full-book snapshot for Claude remains frozen.</p></main></body></html>'''
for source in [text]+[(MAP/f).read_text(encoding='utf-8') for f in ['technical.md','critical.md','artifacts.md']]:
    for target in re.findall(r'\]\(([^)]+)\)',source):
        if '://' in target or target.startswith(('#','/')):continue
        resolved=(MAP/target.split('#')[0]).resolve()
        if resolved.is_file() and resolved.is_relative_to(R):
            url='/book-review/'+resolved.relative_to(R).as_posix()
            if '#' in target:url+='#'+target.split('#',1)[1]
            page=page.replace('href="'+html.escape(target,quote=True)+'"','href="'+html.escape(url,quote=True)+'"')
(H/'index.html').write_text(page,encoding='utf-8')
print('Published Point One reading page; preservation, alignment and local document links verified.')