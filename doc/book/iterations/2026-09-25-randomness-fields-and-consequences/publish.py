from pathlib import Path
from collections import Counter
import json,hashlib,difflib,re,html,urllib.request,markdown
r=Path.cwd();o=Path(__file__).parent;base=json.loads((o/'baseline.json').read_text());maps=base['maps'];checks=[]
H=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def check(ok,label):
 checks.append({'check':label,'passed':bool(ok)})
 assert ok,label
figs=json.loads((o/'figure-provenance.json').read_text())
prior=json.loads((o/'core-before-update.json').read_text());core=json.loads((r/'commons/data/museum_core_encounters.json').read_text(encoding='utf-8-sig'))
for m in maps:
 p=r/'commons/maps'/m/'final.md';s=p.read_text(encoding='utf-8');old=(o/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8-sig')
 check(re.findall(r'```[^\n]*\n(.*?)```',old,re.S)==re.findall(r'```[^\n]*\n(.*?)```',s,re.S),m+': code excerpts retained')
 a=Counter(re.findall(r'<!--.*?-->',old));b=Counter(re.findall(r'<!--.*?-->',s));extra=Counter()
 if m=='Random_Space':extra.update(['<!-- @worley_noise -->','<!-- @shannon_entropy_meter -->','<!-- @noise_mixer -->'])
 if m=='Random_Game':extra.update(['<!-- @waiting_profile -->'])
 check(a+extra==b,m+': original anchors retained; only intended anchors added')
 check(core['rooms'][m]['text_sha256']==H(p) and core['rooms'][m]['map_sha256']==H(r/'commons/maps'/m/'map_data.json'),m+': current core references')
 a=dict(prior['rooms'][m]);b=dict(core['rooms'][m])
 for k in ['text_sha256','map_sha256','local_review']:a.pop(k,None);b.pop(k,None)
 check(a==b,m+': roles and review maturity retained')
 with urllib.request.urlopen('http://localhost:3003/api/book-text?map='+m,timeout=20) as response:live=json.load(response)
 check(live['sections']['final'].replace('\r\n','\n').strip()==s.strip(),m+': live reader serves canonical text')
changed_maps=['commons/maps/'+m+'/final.md' for m in maps if m!='Random_Pheromone']+['commons/maps/'+m+'/map_data.json' for m in ['Random_Space_Geometry','Randomness_Examples_of_Randomness','Random_Space']]
for rel,h in base['files'].items():
 if rel.startswith('commons/maps/') and rel not in changed_maps:check(H(r/rel)==h,rel+': unchanged')
for rel in ['commons/data/artifact_roles.json','commons/data/book/randomness.json','ada_run/em_plan.json','commons/data/museum/em_plan.json']:
 if rel in base['files']:check(H(r/rel)==base['files'][rel],rel+': unchanged')
for m in ['Random_Space_Geometry','Randomness_Examples_of_Randomness','Random_Space']:
 a=json.loads((o/'before/commons/maps'/m/'map_data.json').read_text(encoding='utf-8-sig'));b=json.loads((r/'commons/maps'/m/'map_data.json').read_text())
 if m=='Random_Space_Geometry':
  g=[[' ']*12 for _ in range(24)]
  for z,row in enumerate(a['layers']['interactables']):
   for x,v in enumerate(row):
    if str(v).strip():
     check(a['layers']['structure'][z-7][x]=='1','Geometry: floored source cell for '+v)
     g[z-7][x]=v
  a['layers']['interactables']=g;a['map_info']['dimensions'].update(width=12,depth=24)
  a['map_info']['museum']={'sculpture_clear_rects':[[2,17,5,22]]}
 else:
  for row in a['layers']['interactables']:
   for i,v in enumerate(row):
    if m=='Randomness_Examples_of_Randomness' and 'monte_carlo_dartboard' in v:row[i]=v+'#keyboard:off'
    elif m=='Random_Space' and v.startswith('worley_noise'):row[i]=v+'#plinth:0.35'
    elif m=='Random_Space' and v.startswith('shannon_entropy_meter'):row[i]=v+'#plinth:1.05'
 check(a==b,m+': only intended local map edits')
native=0;limitations={}
runs=[('mushrooms-after',8),('geometry-final',6),('examples',6),('pheromone-final',4),('space-final',7),('game',4)]
for sub,count in runs:
 d=json.loads((o/sub/'report.json').read_text());code=json.loads((o/sub/'process.json').read_text())['exit_code'];log=(o/sub/'stdout.log').read_text(errors='replace')
 check(d['passed'] and len(d['checks'])==count and not d['failures'],sub+': native assertions passed');native+=count
 check(code==0,sub+': native process exits successfully')
 check('SCRIPT ERROR' not in log,sub+': no GDScript error')
 limitations[sub]={'exit_code':code,'warnings':list(dict.fromkeys(l for l in log.splitlines() if 'ERROR:' in l or 'WARNING:' in l))}
(o/'engine-limitations.json').write_text(json.dumps(limitations,indent=2)+'\n')
for f in figs:
 check(H(r/f['canonical'])==H(r/f['source'])==f['sha256'],'Original museum PNG copied unchanged: '+f['canonical'])
 with urllib.request.urlopen('http://localhost:3003/book-review/'+f['canonical'],timeout=20) as response:check(hashlib.sha256(response.read()).hexdigest()==f['sha256'],'HTTP serves original figure')
manifest=json.loads((r/'doc/book/captures/randomness/randomness-book.manifest.json').read_text())
check(all(H(r/m['path'])==m['sha256'] for m in manifest['maps']),'All 14 chapters match current capture')
check(H(r/'doc/book/captures/randomness/randomness-book.md')==manifest['output_sha256'],'Capture hash correct')
(o/'verification.json').write_text(json.dumps({'passed':True,'checks':checks,'native_assertions':native,'scope':'Six real museum halls, controlled desktop cameras and supplied events. No tracked-hand, headset, Quest, full route or learner acceptance.'},indent=2)+'\n')
owned=changed_maps+['algorithms/proceduralgeneration/growth_systems/mushrooms/mushrooms.gd','algorithms/randomness/monte_carlo_dartboard/monte_carlo_dartboard.gd','commons/data/museum_core_encounters.json','doc/book/figures/README.md','doc/book/captures/randomness/randomness-book.md','doc/book/captures/randomness/randomness-book.manifest.json']
for rel in owned+['commons/maps/Random_Pheromone/final.md']:
 p=r/rel;dest=o/'after'/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(p.read_bytes());a=(o/'before'/rel).read_text(encoding='utf-8-sig');b=p.read_text(encoding='utf-8-sig')
 if rel=='commons/data/museum_core_encounters.json':a=json.dumps({m:prior['rooms'][m] for m in maps},indent=2)+'\n';b=json.dumps({m:core['rooms'][m] for m in maps},indent=2)+'\n'
 if rel=='doc/book/figures/README.md':a=(o/'figures-before-update.md').read_text()
 dest=o/'diffs'/(rel+'.diff');dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+rel,tofile=rel)),encoding='utf-8')
(o/'changed-files.json').write_text(json.dumps(owned+[f['canonical'] for f in figs],indent=2)+'\n')
D=json.loads((o/'decisions.json').read_text());q=json.loads((r/'doc/tasks/book_randomness.json').read_text(encoding='utf-8-sig'));tasks={t['id']:t for t in q['tasks']}
rows=''.join('<tr><td>'+html.escape(k+' · '+tasks[k]['title'])+'</td><td><strong>'+v['status']+'</strong> — '+html.escape(v['decision'])+'</td></tr>' for k,v in D.items())
decisions='# Randomness: fields and consequences\n\n25 September 2026. Six remaining Randomness halls reviewed against current chapters, companion manuscripts, placed scenes and native museum views. Five chapters receive narrow changes; Random Pheromone is retained byte for byte.\n\n'
decisions+='## Decisions\n\n'+''.join('### '+k+' — '+tasks[k]['title']+'\n\n**'+v['status']+'**. '+v['decision']+'\n\n' for k,v in D.items())
decisions+='''## What the source could not tell us alone

The noise-bench report correctly identified a malformed source grid, but its description of the loaded museum was wrong. The native hall uses its existing stamped necklace. Three standing-position floor rays succeeded before any change. Repairing the source grid and removing an unrelated generated sculpture are distinct actions; neither is evidence of having rescued a previously unsupported museum visitor. The existing necklace remains authoritative.

The pheromone review confused script defaults with scene overrides. Its initial diagnostic failed because this pass repeated that assumption. The original manuscript was restored; the diagnostic remains in `pheromone/report.json`, and the corrected check is in `pheromone-final/report.json`.

The native photographs showed two real obstructions not visible in manuscript review: random ground partly buried the cellular plane and the entropy display. Their local supports now expose both. No change to the random ground's generation, mesh or collision was made.

## Verification and remaining limits

35 native assertions across six halls pass, with all six final processes exiting 0 and no GDScript errors. These include specimen population preservation under SIZE, the scene's actual four walkers/40% guidance, unchanged independent heights when coherent frequency changes, museum keyboard isolation with legacy shortcuts preserved, two local exhibit lifts, and five retained profiles. The source-grid pathfinder reports 213/288 reachable cells and all six artifacts; its two-teleporter warning is retained.

Existing engine warnings remain, including UID, unavailable renderer features, invalid resource state warnings and shutdown resource leaks. See `engine-limitations.json` and the full logs. Native assertions are bounded; they are not a claim that every room is visually or spatially finished. In particular, the noise bench remains overlit; the pheromone photograph shows its terrain close to the end wall/gate and does not establish a fully exposed, approachable footprint. Investigate those together with the still-open headset tasks.

The random ground's walker classification is still open. No tracked-hand eating, headset approach, pointer comfort, Quest performance, complete museum traversal or reader-learning test was performed. The older removal-floor shutdown failure remains outside this pass.

All photographs are original PNGs from the running Godot museum, not grid illustrations. Mushroom populations differ between runs; those images show staging, not a controlled seed comparison. The geometry room's random shapes also differ. The raised-gauge pair uses the same eye-height standing position with the view tilted toward its new height. Two native photographs enter canonical final.md and the current 14-hall capture.

Companion manuscripts, source excerpts, artifact roles, sequence order, other artifact placements and live plan/bake/save files are retained. Shared core references are updated only for these six halls. No new commit is made by this pass.
'''
(o/'DECISIONS.md').write_text(decisions,encoding='utf-8')
sections=[]
for m in maps:
 a=(o/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8-sig');b=(r/'commons/maps'/m/'final.md').read_text(encoding='utf-8')
 reading=markdown.markdown(b,extensions=['fenced_code','footnotes'])
 reading=re.sub(r'id="([^"]+)"',lambda v:'id="'+m+'-'+v[1]+'"',reading);reading=re.sub(r'href="#([^"]+)"',lambda v:'href="#'+m+'-'+v[1]+'"',reading)
 table=difflib.HtmlDiff(wrapcolumn=70).make_table(a.splitlines(),b.splitlines(),fromdesc='Before',todesc='Current final.md',context=True,numlines=2) if a!=b else '<p>Retained unchanged. The placed scene confirms the original count and percentage.</p>'
 sections.append(f'<section id="{m}"><h2>{m.replace("_"," ")}</h2><p><a href="/compose/sources?map={m}&amp;doc=final">Current chapter and comments</a></p><details><summary>Text beside the original</summary><div class="diffwrap">{table}</div><a href="diffs/commons/maps/{m}/final.md.diff">Exact diff</a></details><div class="reading">{reading}</div></section>')
def pair(a,ac,b,bc):
 return '<div class="pair">'+''.join('<figure><a href="'+p+'"><img loading="lazy" src="'+p+'" alt="'+html.escape(c,quote=True)+'"></a><figcaption>'+c+'</figcaption></figure>' for p,c in [(a,ac),(b,bc)])+'</div>'
css='body{margin:0;background:#f3eee5;color:#302b31;font:18px/1.65 Georgia,serif}main{max-width:1180px;margin:auto;padding:40px 26px}h1{font-size:48px;line-height:1.13}h2{line-height:1.25}a{color:#72526c}p{max-width:78ch}nav{display:flex;gap:20px;flex-wrap:wrap}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}figure{margin:20px 0}img{width:100%;height:auto}figcaption{font-size:15px}.reading{max-width:760px;margin:40px auto}.reading h1{font-size:35px}section{margin-top:45px;border-top:1px solid #cfc6bb;padding-top:24px}details{padding:18px;border:1px solid #cfc6bb}summary{cursor:pointer}.diffwrap{overflow:auto}.diff{font:12px/1.4 monospace}.diff_header{background:#e2d9cd}.diff_add{background:#d9ead8}.diff_sub{background:#efd9d5}.diff_chg{background:#f0e5b8}table{border-collapse:collapse;width:100%}td,th{vertical-align:top;padding:9px;border-bottom:1px solid #ccc}pre{overflow:auto;background:#e8e1d7;padding:15px;font-size:13px}@media(max-width:750px){.pair{grid-template-columns:1fr}h1{font-size:35px}}'
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Randomness — fields and consequences</title><style>'+css+'</style><main><p>Ada Research · 25 September 2026</p><h1>Fields and consequences</h1><p>A draw can choose which body appears, how neighbours differ, or how long a surface will support you. These last six halls follow the consequences of those choices, and the signs that make them available to a visitor.</p><nav><a href="#museum">Inside the museum</a><a href="#reading">Read the six halls</a><a href="DECISIONS.md">Decisions and limits</a><a href="/book-tasks/review?seq=randomness">Review comments</a></nav><p>Ten review comments resolved. Five chapters lightly revised; the pheromone chapter retained. Two local display supports, a clearer approach, specimen cleanup, and walking keys separated from the dartboard controls.</p><h2 id="museum">A comparison uncovered</h2>'
page+=pair('space/cellular-field.png','Before: the random ground crosses the small cellular image.','space-final/cellular-field.png','Now: a low support exposes the whole image, while the surrounding ground remains.')
page+=pair('space/returning-gauge.png','Before: the ground hides much of the returning entropy gauge.','space-final/returning-gauge.png','Now: the gauge stands at reading height. Same standing position; the view turns upward with it.')
page+='<p>The chapter now brings these works into the comparison. Neighbouring distances produce a seam; symbol counts alone cannot tell us whether similar values make a seam or have been scattered apart. The gauge measures its own symbols. It does not measure the room.</p><h2>The noise bench already had floor</h2>'
page+=pair('geometry-before/comparison-approach.png','Before: native placement already supports the bench, but an unrelated generated sculpture stands in the approach.','geometry-final/comparison-approach.png','Now: a local exclusion clears that sculpture. The six authored works remain. Random shapes differ between runs.')
page+='<p>The malformed source grid is repaired too, with all six tokens inside its floor. The running museum retains its existing stamped arrangement. Contrast at the small bench still needs work; the source report and the native view describe different problems.</p><h2>Only the specimen bed changes</h2>'
page+=pair('mushrooms-before/mushroom-bed.png','Before: the specimen setup inherits a standalone prism, camera and fill light.','mushrooms-after/mushroom-bed.png','Now: those demo leftovers are absent from this staging. Different generated populations; this is not a fixed-seed image comparison.')
page+='<h2>Waiting has a shape</h2>'
page+=pair('game/waiting-and-seeing.png','The waiting podium and profiles now have their own chapter anchor. The text distinguishes expected attempt rates from the podium’s drawn waits.','examples/dartboard-in-gallery.png','Walking keys no longer toggle this dartboard. Its console remains; the standalone demo keeps its shortcuts.')
page+='<details><summary>What was checked, and what remains</summary><p>35 bounded native assertions passed across six halls; all six final processes exited successfully. No GDScript errors were logged. Existing engine warnings remain. These are controlled desktop camera and supplied-event checks, not headset acceptance.</p><p>The pheromone scene overrides the script defaults: four walkers, 40% guidance. Its existing chapter was correct and remains unchanged. Its terrain’s relationship to the end wall/gate still needs a full spatial check. Random-ground navigation, headset work and the bench’s lighting contrast remain follow-ups.</p><p><a href="verification.json">Publication checks</a> · <a href="engine-limitations.json">Engine warnings</a> · <a href="figure-provenance.json">Original image provenance</a> · <a href="pheromone-final/pheromone-visits.png">Pheromone diagnostic view</a></p></details><section><h2>Each review comment</h2><table>'+rows+'</table></section><section id="reading"><h2>The six halls</h2><nav>'+''.join(f'<a href="#{m}">{m.replace("_"," ")}</a>' for m in maps)+'</nav></section>'+''.join(sections)+'</main></html>'
(o/'index.html').write_text(page,encoding='utf-8')
print(f'{len(checks)} publication/preservation checks passed; {native} native assertions. Reading and exact diffs published.')
