"""Publish the native spatial comparison without re-running or rewriting lessons."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit,unquote
import collections,difflib,hashlib,html,json,re,shutil
import markdown
from PIL import Image

R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-rooms-connected'
M=R/'commons/maps/CA_Introduction'
E=lambda v:html.escape(str(v),quote=True)
load=lambda p:json.loads(p.read_text(encoding='utf-8'))
write=lambda p,s:p.write_bytes(s.encode('utf-8'))
before=load(O/'before/museum/report.json'); after=load(O/'after/museum/report.json')
assert before['passed'] and after['passed']
hashes=load(O/'before/source-hashes.json')
protected={p:hashlib.sha256((R/p).read_bytes()).hexdigest()==sha for p,sha in hashes.items() if p.endswith('.gd') or p.endswith('tutorial.md')}
assert all(protected.values())
source_before=load(O/'before/map_data.json'); source_after=load(M/'map_data.json')
tokens=lambda d:collections.Counter(v.split(':')[0].split('#')[0] for row in d['layers']['interactables'] for v in row if v.strip())
assert tokens(source_before)==tokens(source_after) and sum(tokens(source_after).values())==8
for layer in source_after['layers'].values(): assert len(layer)==19 and all(len(row)==13 for row in layer)
for name in ['map_data.json','tutorial.md','final.md']:
 shutil.copy2(M/name,O/'after'/name)
 diff=''.join(difflib.unified_diff((O/'before'/name).read_text(encoding='utf-8').splitlines(True),(M/name).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+name,tofile='after/'+name))
 write(O/(name+'.diff'),diff)

style='''*{box-sizing:border-box}body{margin:0;background:#f3f0e9;color:#26322e;font:19px/1.65 Georgia,serif}header,main,footer{max-width:1320px;margin:auto;padding:32px}header{padding-top:70px}h1{font-size:clamp(38px,6vw,78px);line-height:1.02;max-width:920px}h2{line-height:1.2;margin-top:2em}p,li{max-width:76ch}.eyebrow,nav,figcaption,label,table,.badge,.legend{font:15px/1.55 system-ui,sans-serif}.eyebrow{letter-spacing:.14em;text-transform:uppercase}nav{display:flex;gap:20px;flex-wrap:wrap}a{color:#256a4e;text-underline-offset:3px}.lead{font-size:26px}.badge{background:#dce9df;padding:9px 15px;display:inline-block;border-radius:4px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:22px}figure{margin:18px 0}img{display:block;width:100%;height:auto}figcaption{padding:10px 0;color:#4f5e56}.viewer{margin:25px 0}.viewer>label{display:inline-block;padding:12px 20px 12px 4px;cursor:pointer}.stage{position:relative}.stage.before{display:none}#before:checked~.after{display:none}#before:checked~.before{display:block}#pins:not(:checked)~.stage .pin{display:none}.pin{position:absolute;transform:translate(-50%,-50%);border:2px solid white;border-radius:50%;width:30px;height:30px;display:grid;place-items:center;background:#9b2852;color:#fff;font:700 15px system-ui;text-decoration:none;box-shadow:0 2px 6px #0008}.legend{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:12px;list-style:none;padding:0}.note{padding:20px;background:#e4e9df;border-left:4px solid #417451}table{border-collapse:collapse;width:100%}th,td{padding:10px;text-align:left;border-bottom:1px solid #bac8bd}pre{background:#192a23;color:#f5f7ec;padding:20px;overflow:auto;font:13px/1.6 Consolas,monospace;tab-size:4}code{font-size:.85em}pre code{font-size:inherit}details{margin:25px 0}footer{border-top:1px solid #c2cabe;font:14px/1.6 system-ui}article{max-width:950px}@media(max-width:800px){.pair{grid-template-columns:1fr}header,main,footer{padding:22px}.lead{font-size:23px}}@media print{nav,.viewer>input,.viewer>label{display:none}.stage{display:block!important}body{font-size:11pt}pre{white-space:pre-wrap;color:#111;background:#fff;font-size:8pt}}'''
nav='<nav><a href="index.html#above">Above the hall</a><a href="index.html#inside">Inside the hall</a><a href="tutorial.html">Full tutorial</a><a href="final.html">Full reflection</a><a href="REPORT.md">Report notes</a></nav>'
def page(name,title,body):
 write(O/name,f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{E(title)}</title><style>{style}</style></head><body><header><div class="eyebrow">Endless Museum · Cellular Automata · 8 October 2026</div><h1>{E(title)}</h1>{nav}</header><main>{body}</main><footer>Native Godot museum captures. Static report controls use CSS. No physical headset or Quest acceptance test.</footer></body></html>')
def photo(state,name,caption):
 return f'<figure><a href="{state}/museum/{name}.png"><img loading="lazy" src="{state}/museum/{name}.png" alt="{E(caption)}"></a><figcaption>{E(caption)}</figcaption></figure>'
labels=[('ca_rule_explorer','Row + history ring'),('persian_rug','Mirrored rug'),('line_network_ca','Growing network'),('ca_showcase','CA showcase'),('dream_bodies','Decorative figure')]
stages=''
for state,data in [('after',after),('before',before)]:
 w,h=Image.open(O/state/'museum/overhead.png').size
 pins=''
 for i,(key,label) in enumerate(labels,1):
  item=next(x for x in data['observations']['inventory'] if x['key']==key)
  x,y=item['top_pixel'];assert 0<=x<w and 0<=y<h
  pins+=f'<span class="pin" title="{E(label)}" style="left:{x/w*100:.3f}%;top:{y/h*100:.3f}%">{i}</span>'
 stages+=f'<figure class="stage {state}"><img src="{state}/museum/overhead.png" alt="{E(state.title())}: full overhead view of the installed CA opening hall.">{pins}<figcaption>{state.title()} · same overhead camera, actual museum geometry.</figcaption></figure>'
legend='<ul class="legend">'+''.join(f'<li><b>{i}.</b> {E(label)}</li>' for i,(_,label) in enumerate(labels,1))+'</ul>'
sample_count=sum(v['samples'] for v in after['observations']['routes'].values())
report=f'''# Two rooms, connected

CA_Introduction now has a direct comparison between the row and rug, a lower gallery instead of narrow wall pockets, and room around the growing network. All eight authored works remain. The decorative figure and its plinth remain too, relocated by the museum's existing placement system into the lower gallery.

## Applied layout

- Open two three-metre connections through the divider: beside the row/rug and beside the network/gallery.
- Open a two-metre passage from the rug room into the lower gallery. Keep enough wall to give the rooms separate identities.
- Convert 40 authored cells to level floor: the derived floor count rises from 134 to 174 within the same 13 × 19 footprint.
- Move the showcase from map cell (1,17) to (3,14). Keep the row, ring, rug, turmites, network, Rule 110 and both sphere placements.
- Reserve the teaching aisle and showcase approaches from automatic sculpture placement. In the captured build the retained figure moves from (9,12) to (3,10), over seven metres from the network instead of approximately one.
- Disable the generic start gate for this hall: its six-metre barrier crossed the rug and the new opening. The hall keeps its museum portals.
- Move sp from (2,1) to (6,0), with no arrival cage. Move t from (2,16) to the centred exit at (6,18), approached from the hall. Both authored frames now validate without fallback in this hall.

## What changes for the learner

The row remains the primary tutorial. The opening lets the visitor turn from its local rule towards the rug's mirrored pattern; the second connection lets the network be seen from another side. The showcase is a deliberate side encounter. The route does not turn every artifact into a lesson.

The tutorial and its runnable code are byte-identical to the baseline. The production CA engine, hand reader and history-ring scripts are also unchanged. Three location sentences in final.md now describe the new arrangement; the reflective argument is retained.

## Evidence

{len(after['checks'])} fresh native checks pass. Six routes have {sample_count} sampled positions, spaced at most 0.15 m apart: a 0.56 m wide, 1.7 m high capsule clears layer-1 collision and finds level floor. Tests also check authored entry/exit validation, retained reader height, shared board/ring updates, showcase placement and figure separation.

Ten native images compare five identical camera viewpoints before/after: full overhead, raised oblique, rug opening, network and lower gallery. No walls are hidden for the pictures. Neighbouring halls and the player are hidden for capture only. Rule 90 is held at the same generation for both layout photographs; other running/random works can differ in state. Before eye-level cameras are diagnostic fixed viewpoints, including the previously obstructed opening, not evidence of a playable before route.

The first layout run failed four clearance checks: the generic gate, an entrance path too close to a corner, and the old exit frame beside the relocated showcase. The next pass identified collision shapes. The gate and portal placements were corrected; the entrance sample path moved 0.3 m off the corner. A probe-only undeclared stream variable caused a parse error and was corrected before the final run. These were not CA program failures. Initial layout diagnostics are retained.

Limit: this checks sampled clearance against museum layer 1, not every dynamic interaction, physical headset comfort, Quest performance or traversal into the next hall. The existing tutorial's 29 construction checks and 16 interaction checks were not re-run for this spatial edit; their code is unchanged. Final engine log contains no SCRIPT ERROR or Parse Error. Existing renderer/UID/Jolt warnings remain.

## Next

Continue with CA_ElementaryRules: inspect the existing three-dimensional empty/active/fading specimen. Keep overhead, elevated and visitor-height views in subsequent hall reviews. Do not infer the lesson from the old map title alone.
'''
write(O/'REPORT.md',report)
body=f'''<p class="lead">The row, rug and network can now be visited as a connected comparison. The lower wall pockets have become a gallery.</p><p class="badge">{len(after['checks'])} native checks passed · 8 authored works retained</p>
<ul><li><strong>Two openings:</strong> row to rug, network to gallery.</li><li><strong>More usable floor:</strong> the showcase has space around it; the decorative figure is away from the network.</li><li><strong>Clear entry and exit:</strong> the gate across the rug is removed and both portal markers are at the room's openings.</li></ul>
<section id="above"><h2>See the arrangement</h2><p>Switch the full overhead view. Pink numbers identify the same works in both arrangements; the upper edge is the entrance.</p><div class="viewer"><input id="after" type="radio" name="state" checked><label for="after">After</label><input id="before" type="radio" name="state"><label for="before">Before</label><input id="pins" type="checkbox" checked><label for="pins">Locations</label>{stages}</div>{legend}<div class="pair">{photo('before','raised-oblique','Before: works concentrated in the right corridor; walls occupy the lower-left area.')}{photo('after','raised-oblique','After: connected spaces around the same teaching encounters.')}</div></section>
<section id="inside"><h2>Check it at body height</h2><p>These pairs use the same eye positions. The before view of the opening is obstructed; its camera is a diagnostic viewpoint. Other works keep running, so their patterns can differ between captures.</p>
<h3>From the row towards the rug</h3><div class="pair">{photo('before','rug-connection','Before: the divider and generic start gate obstruct the comparison.')}{photo('after','rug-connection','After: a three-metre opening; the rug and sphere are visible from beside the row study.')}</div>
<h3>Room around the network</h3><div class="pair">{photo('before','network-room','Before: the decorative figure shares the network’s small area.')}{photo('after','network-room','After: the network and its replay control have their own approach.')}</div>
<h3>A gallery beyond the rug</h3><div class="pair">{photo('before','lower-gallery','Before: a view into the lower wall pockets.')}{photo('after','lower-gallery','After: the showcase stands in the open gallery, with the onward portal at the far opening.')}</div></section>
<section id="reading"><h2>The lesson stays focused</h2><p>The row remains the tutorial’s central reconstruction. The rug and network extend the reflection. All tutorial code and the production CA logic remain unchanged; three sentences in the reflection now describe the room correctly.</p><p><a href="tutorial.html">Read the full tutorial</a> · <a href="final.html">Read the full reflection</a> · <a href="final.md.diff">See the location edits</a></p></section>
<section id="checks"><h2>What was checked</h2><p>{sample_count} positions along six routes have level floor and room for a 0.56 m wide, 1.7 m high capsule. The authored entry and exit validate, and STEP still updates both board and ring.</p><div class="note">These are native geometry and state checks. A tracked visitor and Quest performance have not been tested.</div>
<p><a href="after/museum/report.json">25 checks and route measurements</a> · <a href="after/museum/engine.log">Final engine log</a> · <a href="diagnostics/first-layout/report.json">Initial failed layout checks</a> · <a href="map_data.json.diff">Map changes</a></p><details><summary>Full spatial report and limits</summary>{markdown.markdown(report,extensions=['tables'])}</details></section>'''
page('index.html','Two rooms, connected',body)
for name,title in [('tutorial','A row with neighbours — tutorial'),('final','What will the next row do? — reflection')]:
 raw=(M/(name+'.md')).read_text(encoding='utf-8')
 for img in re.findall(r'!\[[^\]]*\]\((images/[^)]+)\)',raw):
  dst=O/'after'/img;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(M/img,dst)
  raw=raw.replace(']('+img+')','](after/'+img+')')
 page(name+'.html',title,'<article>'+markdown.markdown(raw,extensions=['fenced_code','tables','footnotes'])+'</article>')

class Links(HTMLParser):
 def __init__(self):super().__init__();self.refs=[];self.ids=[]
 def handle_starttag(self,tag,attrs):
  attrs=dict(attrs)
  if 'id' in attrs:self.ids.append(attrs['id'])
  for key in ['href','src']:
   if key in attrs:self.refs.append(attrs[key])
checks=0
for p in [O/'index.html',O/'tutorial.html',O/'final.html']:
 parsed=Links();parsed.feed(p.read_text(encoding='utf-8'));assert len(set(parsed.ids))==len(parsed.ids)
 for ref in parsed.refs:
  url=urlsplit(ref)
  if url.scheme or url.netloc:continue
  dst=p.parent/unquote(url.path) if url.path else p
  assert dst.is_file(),(p,ref)
  if url.fragment and dst.suffix=='.html':
   q=Links();q.feed(dst.read_text(encoding='utf-8'));assert unquote(url.fragment) in q.ids,(p,ref)
  checks+=1
validation={'native_checks':len(after['checks']),'native_passed':after['passed'],'clearance_samples':sample_count,'relative_html_references':checks,'protected_sources_unchanged':protected,'authored_artifacts_retained':dict(tokens(source_after)),'map_shape':[13,19],'images':10}
write(O/'validation.json',json.dumps(validation,indent=2))
write(O/'SUMMARY.md','CA_Introduction spatial return: 40 cells->floor; two 3m cross-openings; 2m rug/gallery passage; showcase(1,17)->(3,14); reserve sculptures away from tutorial approaches; generated figure(9,12)->(3,10). gate:false removes generic barrier across rug. sp(2,1)->(6,0),cage:false; t(2,16)->(6,18),from_hall. All8authoredworks retained. Only target em_plan row replaced+shipped. tutorial+5GD sources hash-unchanged. final3location sentences edited. 25nativechecks/209route samples pass; 10beforeafterimages. Firstclearancefailures preserved. No headset/Quest/next-hall crossing claim. Next: CA_ElementaryRules 3D neighbourhood+fading, not another row lesson.\n')
print(json.dumps({'page':str(O/'index.html'),'native_checks':len(after['checks']),'references':checks,'protected_sources':len(protected)}))
