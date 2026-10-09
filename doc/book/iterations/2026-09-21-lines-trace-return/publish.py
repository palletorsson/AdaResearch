from pathlib import Path
import json,re,hashlib,html
import markdown
H=Path(__file__).resolve().parent;R=H.parents[3]
MAPS=['Point_Lines','Point_Trace']
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def render(s,prefix):
    s=re.sub(r'<!--\s*@[^>]*-->', '', s)
    result=markdown.markdown(s,extensions=['fenced_code','footnotes'])
    result=re.sub(r'id="([^"]+)"',lambda m:'id="'+prefix+m[1]+'"',result)
    return re.sub(r'href="#([^"]+)"',lambda m:'href="#'+prefix+m[1]+'"',result)
checks=[]
def check(n,ok):checks.append({'check':n,'passed':bool(ok)});assert ok,n
for name,sha in read(H/'preserved.json').items():check('Preserved '+name,digest(R/name)==sha)
core=read(R/'commons/data/museum_core_encounters.json');old_core=read(H/'before/commons/data/museum_core_encounters.json')
check('Other core records unchanged',{k:v for k,v in core['rooms'].items() if k not in MAPS}=={k:v for k,v in old_core['rooms'].items() if k not in MAPS} and core['_meta']==old_core['_meta'])
roles=read(R/'commons/data/artifact_roles.json')
chapters=''
for m in MAPS:
    source=R/'commons/maps'/m/'final.md';now=source.read_text(encoding='utf-8');old=(H/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8')
    check(m+' footnotes unchanged',[l for l in now.splitlines() if l.startswith('[^')]==[l for l in old.splitlines() if l.startswith('[^')])
    markers=re.findall(r'<!-- @([A-Za-z_0-9]+) -->',now);expected=[];order=roles['order'][m]
    for t in order['primary']:expected.extend(order['primary|'+t[1:]] if t.startswith('@') else [t])
    check(m+' primary order aligned',markers==expected==core['rooms'][m]['primary_tokens'])
    for key,name in [('text_sha256','final.md'),('map_sha256','map_data.json')]:check(m+' current '+name+' hash',core['rooms'][m][key]==digest(source.parent/name))
    check(m+' learner status preserved',core['rooms'][m]['learner_verified'] is False)
    check(m+' closing unchanged',now.split('<!-- @ -->')[-1]==old.split('<!-- @ -->')[-1])
    label='Point Lines' if m=='Point_Lines' else 'Point Trace'
    chapters+='<section id="'+m+'"><h2>'+label+'</h2><nav><a href="'+m+'.diff">Exact diff</a><a href="/compose/sources?map='+m+'&amp;doc=final">Read and comment</a><a href="/long-museum/encounters?map='+m+'">Encounter map</a></nav><div class="reading">'+render(now,m+'-current-')+'</div><details><summary>Original beside current chapter</summary><div class="compare"><article><h3>Original</h3>'+render(old,m+'-before-')+'</article><article><h3>Current</h3>'+render(now,m+'-comparison-')+'</article></div></details></section>'
trace_map=read(R/'commons/maps/Point_Trace/map_data.json');tokens=[t for row in trace_map['layers']['interactables'] for t in row if t.split(':')[0].split('#')[0] in ['draw_dot','draw_stick']]
check('Capacity statement matches scenes and unoverridden placements',bool(tokens) and all('trail_max_points' not in t for t in tokens) and all('trail_max_points = 4096' in (R/'commons/primitives/point'/scene).read_text(encoding='utf-8') for scene in ['draw_dot.tscn','draw_stick.tscn']))
check('Recorder drops oldest position at capacity','if _trail_points.size() > trail_max_points:\n\t\t_trail_points.pop_front()' in (R/'commons/primitives/point/draw_dot.gd').read_text(encoding='utf-8'))
(H/'content-checks.json').write_text(json.dumps(checks,indent=2)+'\n',encoding='utf-8')
style=(R/'doc/book/iterations/2026-09-21-point-one-return/index.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]
style+=' section{margin:60px 0;border-top:1px solid var(--line);padding-top:24px}.edits{display:grid;grid-template-columns:1fr 1fr;gap:26px}.edits article{min-width:0}.edits blockquote{font-size:21px}.small{font-size:14px;color:var(--muted)}@media(max-width:760px){.edits{grid-template-columns:1fr}}'
page='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Lines into Trace — bring the detour</title><style>'''+style+'''</style></head><body><main><div class="eyebrow">Ada Research · applied editorial pass · 21 September 2026</div><h1>Bring the detour.</h1><p class="intro">A small continuation through Lines and Trace. The rooms keep their works. The writing follows what moves between them.</p><nav><a href="#Point_Lines">Read Lines</a><a href="#Point_Trace">Read Trace</a><a href="#edits">The changes</a><a href="SUMMARY.md">Decisions and verification</a></nav><section id="edits"><h2>Two different ways onward</h2><div class="edits"><article><div class="eyebrow">Lines · the changed transition</div><blockquote>You have changed a line with your hands. Ahead, a line has acquired words.</blockquote><p>One repeated promise of a return visit is removed. The clock, the choice of a thread, the barrier and the detour remain. WALK THIS LINE supplies the next encounter.</p></article><article><div class="eyebrow">Trace · the changed capacity sentence</div><blockquote>A longer drawing can begin to lose its beginning.</blockquote><p>The 4096-position condition stays immediately before this sentence. Capacity becomes a consequence for the drawing. The closing catalogue of side machines is removed; the final invitation still carries your bend into Grid.</p></article></div><p class="small">Main arguments, code examples and all footnotes are preserved. The applied edits total 50 fewer whitespace-counted words across the two chapters. No artifact, placement or role changed. The two derived encounter lists now match the already authored primary order.</p></section>'''+chapters+'''<section><div class="eyebrow">Next hall · Grid</div><h2>What does the address let a hand do?</h2><p>The vitrine currently supplies a time-domain recorder to the right hand. The author wants that operation later. Resolve its hand-tool configuration before adding the missing encounter to the prose. A spatial drawing and a grid-snapped drawing are a candidate comparison, not an implemented change.</p><nav><a href="/compose/sources?map=Point_Line_Grid&amp;doc=final">Read Grid</a><a href="/book-review/doc/book/review-feedback/2026-09-21/primitives/DECISIONS.md">Claude feedback and decisions</a></nav></section><p class="note">Text and source checks only in this unit. No fresh game image or headset test is claimed. The earlier full-book snapshot for Claude remains frozen; Collective Knowledge remains parked.</p></main></body></html>'''
(H/'index.html').write_text(page,encoding='utf-8')
print('Published Lines and Trace: %d preservation/alignment checks passed.'%len(checks))