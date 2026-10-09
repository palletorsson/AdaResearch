from pathlib import Path
import difflib,hashlib,html,json,re,shutil
import markdown
r=Path.cwd();o=Path(__file__).resolve().parent;rel=o.relative_to(r).as_posix()
maps=['SoftBodies_Soft_Body_Deformation','SoftBodies_Cloth_Physics'];checks=[]
def H(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf-8'))
def check(name,ok):checks.append({'name':name,'passed':bool(ok)});assert ok,name
base=read(o/'baseline.json');owned=read(o/'changed-files.json')
for path,h in base.items():
 if path not in owned+['commons/data/museum_core_encounters.json','ada_run/em_plan.json']:check('preserved '+path,H(r/path)==h)
for m in maps:
 a=(o/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8');b=(r/'commons/maps'/m/'final.md').read_text(encoding='utf-8')
 check(m+' code excerpts retained',re.findall(r'```.*?```',a,re.S)==re.findall(r'```.*?```',b,re.S))
 check(m+' encounter anchors retained',re.findall(r'<!--.*?-->',a)==re.findall(r'<!--.*?-->',b))
for path in owned:
 p=r/path;dst=o/'after'/path;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dst)
 write(o/'diffs'/(path+'.diff'),''.join(difflib.unified_diff((o/'before'/path).read_text(encoding='utf-8').splitlines(True),p.read_text(encoding='utf-8').splitlines(True),fromfile='before/'+path,tofile='after/'+path)))

plan=read(r/'ada_run/em_plan.json');oldplan=read(o/'before/ada_run/em_plan.json')
for m in maps:
 old=next(p for p in oldplan['plans'] if p.get('map')==m)
 now=next(p for p in plan['plans'] if p.get('map')==m)
 expected=json.loads(json.dumps(old))
 if m=='SoftBodies_Soft_Body_Deformation':
  art=next(a for a in expected['artifacts'] if a['token']=='jelly_cube')
  art.setdefault('config',{})['anchor']='crown'
 check('latest live plan preserves hall apart from cube opt-in '+m,now==expected)

native=[];warnings=[]
for tag in ['cube-native','cloth-native']:
 d=read(o/tag/'report.json');log=(o/tag/'stdout.log').read_text(errors='replace')
 check(tag+' checks pass',d['passed'] and not d['failures']);native+=d['checks']
 check(tag+' process exited zero',read(o/tag/'process.json')['exit_code']==0)
 check(tag+' no script/shader errors','SCRIPT ERROR' not in log and 'SHADER ERROR' not in log)
 warnings += [line for line in log.splitlines() if 'WARNING:' in line or 'ERROR:' in line]
write(o/'engine-warnings.json',json.dumps(list(dict.fromkeys(warnings)),indent=2)+'\n')
capture=r/'doc/book/captures/softbodies/softbodies-book.md';manifest=read(capture.with_suffix('.manifest.json'))
check('all nine captured chapters current',len(manifest['maps'])==9 and all(H(r/x['path'])==x['sha256'] for x in manifest['maps']))
check('capture hash current',H(capture)==manifest['output_sha256']);shutil.copy2(capture,o/capture.name)
cp=r/'commons/data/museum_core_encounters.json';core=read(cp);oldcore=json.loads(json.dumps(core))
write(o/'core-before-update.json',json.dumps(oldcore,ensure_ascii=False,indent=2)+'\n')
for m in maps:core['rooms'][m].update(text_sha256=H(r/'commons/maps'/m/'final.md'),map_sha256=H(r/'commons/maps'/m/'map_data.json'),local_review=rel+'/index.html')
write(cp,json.dumps(core,ensure_ascii=False,indent=2)+'\n')
allowed={'text_sha256','map_sha256','local_review'}
for m in maps:check(m+' acceptance and roles retained',{k:v for k,v in oldcore['rooms'][m].items() if k not in allowed}=={k:v for k,v in core['rooms'][m].items() if k not in allowed})
check('other core records retained',all(v==oldcore['rooms'][m] for m,v in core['rooms'].items() if m not in maps))
check('review queue decisions retained',H(r/'doc/tasks/book_softbodies.json')==base['doc/tasks/book_softbodies.json'])
decisions=(o/'DECISIONS.md').read_text(encoding='utf-8')
write(o/'source-manifest.json',json.dumps({p:{'before':base[p],'after':H(r/p)} for p in base if p!='commons/data/museum_core_encounters.json'},indent=2)+'\n')
def md(s,prefix=''):
 rendered=markdown.markdown(re.sub(r'<!--.*?-->','',s,flags=re.S),extensions=['fenced_code','footnotes','tables'])
 if prefix:
  rendered=re.sub(r'id="([^"]+)"',lambda x:'id="'+prefix+x[1]+'"',rendered)
  rendered=re.sub(r'href="#([^"]+)"',lambda x:'href="#'+prefix+x[1]+'"',rendered)
 return rendered
def figure(path,caption):return f'<figure><a href="{path}"><img src="{path}" alt="{html.escape(caption)}" loading="lazy"></a><figcaption>{caption}</figcaption></figure>'
def pair(a,b):return '<div class="pair">'+figure(*a)+figure(*b)+'</div>'
def diffs(a,b):
 aa=a.split('\n\n');bb=b.split('\n\n');rows=[]
 for tag,i,j,k,l in difflib.SequenceMatcher(None,aa,bb).get_opcodes():
  if tag!='equal':rows.append('<tr><td>'+html.escape('\n\n'.join(aa[i:j]))+'</td><td>'+html.escape('\n\n'.join(bb[k:l]))+'</td></tr>')
 return '<div class="comparison"><table><thead><tr><th>Before this pass</th><th>Current final.md</th></tr></thead><tbody>'+''.join(rows)+'</tbody></table></div>'
template=(r/'doc/book/iterations/2026-09-25-fractals-opening-review/index.html').read_text(encoding='utf-8')
style=re.search(r'<style>(.*?)</style>',template,re.S)[1]
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Soft Bodies â€” what holds?</title><style>'+style+'</style>'
page+='''<header><p class="eyebrow">Endless museum / Soft Bodies / 25 September 2026</p><h1>What holds a body?</h1><p class="lead">The cube yields. The cloth hangs. How much of either belongs to the body, and how much to the arrangement holding it?</p><nav><a href="#SoftBodies_Soft_Body_Deformation">Cube</a><a href="#SoftBodies_Cloth_Physics">Cloth</a><a href="#reading">Read both chapters</a><a href="#decisions">Decisions & evidence</a><a href="softbodies-book.md">Full nine-hall capture</a></nav></header><main><p class="note">A focused return to the two opening halls. The strong cloth pilot stays; its comparisons now unfold one condition at a time. Original native museum images below show the actual encounters. The cube now hangs from one visible held point after the first capture revealed it leaving its small pedestal. The cloth lets the reader change the held set.</p>'''
page+='<section id="SoftBodies_Soft_Body_Deformation"><h2>One point stays. The surface yields.</h2>'
page+=pair(('cube-before-tray/cube-pressure-zero.png','Before the repair: the cube has left its small pedestal during the control sequence. Close camera.'),('cube-native/cube-pressure-zero.png','This hall now holds one upper point. The open stand and brass stem expose the attachment. Wider camera includes the revised support.'))
page+=pair(('cube-native/cube-pressure-one.png','Opening pressure setting: one.'),('cube-native/cube-pressure-two.png','Later in the same control sequence: pressure two. Same camera; this is not a matched fresh-start material experiment.'))
page+='</section><section id="SoftBodies_Cloth_Physics"><h2>The support disappears. The attachment remains.</h2>'
page+=pair(('cloth-native/gantry.png','Gantry present. Eight points hold the top of each strip.'),('cloth-native/no-frame.png','SUPPORT removes the gantry. The same pinned points remain fixed.'))
page+=pair(('cloth-native/corners.png','PINS leaves two held corners per strip. Six formerly held points can sag.'),('cloth-native/released.png','RELEASE removes the last two pins. The strips fall.'))
page+=pair(('cloth-native/rail.png','Soft spheres meet narrow rails; timers subsequently raise damping and stiffness.'),('cloth-native/pan.png','LANDING starts fresh falls into pans. Same camera, different receiving geometry.'))
page+='</section><section id="reading"><h2>The current opening</h2>'
for m in maps:
 a=(o/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8');b=(r/'commons/maps'/m/'final.md').read_text(encoding='utf-8')
 page+=f'<p class="eyebrow">{m.replace("_"," ")}</p><details><summary>Exact changed passages Â· <a href="diffs/commons/maps/{m}/final.md.diff">plain-text diff</a></summary>'+diffs(a,b)+'</details>'
 page+=f'<article class="reading" id="reading-{m}">'+md(b,m+'-')+'</article>'
page+='</section><section id="decisions">'+md(decisions)+'<p><a href="DECISIONS.md">Decision record</a> Â· <a href="verification.json">Checks</a> Â· <a href="source-manifest.json">Source hashes</a> Â· <a href="engine-warnings.json">Engine warnings</a></p><p><a href="cube-native/report.json">Cube native report</a> Â· <a href="cloth-native/report.json">Cloth native report</a></p></section></main><footer>Canonical final.md files and the full Soft Bodies capture are updated. All code excerpts and artifact anchors remain. Headset contact, reach, comfort and learner acceptance remain separate from these desktop experiments.</footer></html>'
write(o/'index.html',page)
write(o/'verification.json',json.dumps({'passed':True,'checks':checks,'native_checks':len(native),'scope':'Two opening halls; no headset acceptance'},indent=2)+'\n')
print('Published',len(checks),'preservation/publication checks and',len(native),'native checks')
