from pathlib import Path
import json,hashlib,difflib,re,html
H=Path(__file__).resolve().parent;R=H.parents[3]
def read(p):return p.read_text(encoding='utf-8-sig')
def load(p):return json.loads(read(p))
def save(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
checks=[]
def check(name,ok):
 checks.append({'name':name,'passed':bool(ok)})
 if not ok:raise AssertionError(name)
base='commons/maps/Random_Noise_Types/'
old=read(H/'before'/base/'final.md');new=read(R/base/'final.md')
start=new.index('<!-- @related_weather -->');end=new.index('We can leave this hall with more than one discovery.')
foot=new.index('\n[^weather-filter]:')
check('all previous chapter lines retained',new[:start]+new[end:foot]==old)
passage=new[start:end].replace('<!-- @related_weather -->','').strip()
a=load(H/'before'/base/'map_data.json');b=load(R/base/'map_data.json')
check('hall extended 10 to 28 rows',b['map_info']['dimensions']['depth']==28)
for name,rows in a['layers'].items():
 restored=b['layers'][name][:9]+b['layers'][name][27:]
 if name=='utilities':
  restored=[r.copy() for r in restored];restored[7][6]='t';restored[9][6]=rows[9][6]
 check('old rows preserved: '+name,restored==rows)
 for row in range(9,27):
  expected=['w']+['1']*11+['w'] if name=='structure' else [' ']*13
  if name=='interactables' and row==18:expected[6]='related_weather'
  check('new bay row %s %d'%(name,row),b['layers'][name][row]==expected)
check('exactly one relocated teleporter',b['layers']['utilities'][7][6]==' ' and b['layers']['utilities'][27][6]=='t')
primaries=re.findall(r'<!-- @([^\s>]+) -->',new)
check('five primary encounters in book order',primaries==['randompoint','randompoints','WhiteNoiseGallery','NoiseColors3D','related_weather'])
seq=load(R/'commons/maps/sequences/noise.json');prior=load(H/'before/commons/maps/sequences/noise.json')
check('sequence order retained',seq['sequences']['noise']['maps']==prior['sequences']['noise']['maps'])
groups=seq['sequences']['noise']['artifact_groups'];before_groups=prior['sequences']['noise']['artifact_groups']
check('other sequence groups preserved',[g for g in groups if g['map']!='Random_Noise_Types']==[g for g in before_groups if g['map']!='Random_Noise_Types'])
check('current group matches book',next(g for g in groups if g['map']=='Random_Noise_Types')['artifacts']==primaries)
reg=load(R/'commons/artifacts/registry/noise.json');prev=load(H/'before/commons/artifacts/registry/noise.json');check('existing registry definitions preserved',{k:v for k,v in reg['artifacts'].items() if k!='related_weather'}==prev['artifacts'])
check('registered scene exists',(R/reg['artifacts']['related_weather']['scene'].removeprefix('res://')).exists())
native=load(H/'native-checks.json');museum=load(H/'museum-runtime.json');signal=load(H/'signal-checks.json')
check('native checks pass',not native['failures'] and len(native['checks'])==44 and 'SCRIPT ERROR' not in read(H/'native.log'))
check('signal analysis passes',signal['passed'] and signal['samples']==65536)
check('actual museum run passes',museum['passed'] and not museum['failures'] and 'SCRIPT ERROR' not in read(H/'museum-process.log'))
for key in ['checks','walks','rays']:check('museum '+key+' all pass',bool(museum[key]) and all(c['passed'] for c in museum[key]))
for name in ['room.png','empty.png','eight.png','sight.png','aligned.png','along.png','signal-study.png']:check('image exists '+name,(H/name).stat().st_size>1000)
p=R/'commons/data/museum_core_encounters.json';d=load(p);room=d['rooms']['Random_Noise_Types'];room['primary_tokens']=primaries;room['text_sha256']=sha(R/base/'final.md');room['map_sha256']=sha(R/base/'map_data.json');room['learner_verified']=False;room['verification_scope']='Related-weather addition: 44 native control/state/glass checks, 65,536 raw production samples and independent filter/PSD checks; actual museum controls, sight views, six sampled aisles/exit walks and two floor rays. Existing studies retained. No headset, group-use, learner or Quest acceptance.';save(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
files=[p.relative_to(H/'before') for p in (H/'before').rglob('*') if p.is_file()]+[p.relative_to(R) for p in (R/'commons/artifacts/related_weather').iterdir() if p.is_file()]
manifest=[];diff=[]
for f in sorted(set(files)):
 prior=H/'before'/f;current=R/f
 before=read(prior) if prior.exists() else '';after=read(current);save(H/'after'/f,after)
 manifest.append({'path':f.as_posix(),'before_sha256':sha(prior) if prior.exists() else None,'after_sha256':sha(current)})
 if f.as_posix()=='commons/data/museum_core_encounters.json':before=json.dumps({'Random_Noise_Types':json.loads(before)['rooms']['Random_Noise_Types']},ensure_ascii=False,indent=2)+'\n';after=json.dumps({'Random_Noise_Types':json.loads(after)['rooms']['Random_Noise_Types']},ensure_ascii=False,indent=2)+'\n'
 diff.extend(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='before/'+f.as_posix(),tofile='after/'+f.as_posix()))
save(H/'changes.diff',''.join(diff));save(H/'source-manifest.json',json.dumps(manifest,indent=2)+'\n')
save(H/'before-final.md',old);save(H/'after-final.md',new);save(H/'new-passage.md',passage+'\n')
style=re.search(r'<style>(.*?)</style>',read(H.parent/'2026-09-24-door-timing/index.html'),re.S).group(1)
css='body{font:16px system-ui;background:#f5f1e9;padding:25px;color:#252d2e}table{width:100%;border-collapse:collapse}td{padding:4px;vertical-align:top}.diff_header{background:#deded4}.diff_add{background:#c8ecdb}.diff_sub{background:#f2c9d0}.diff_next{display:none}th{font:24px Georgia;text-align:left;padding:18px}'
table=difflib.HtmlDiff(wrapcolumn=76).make_table(old.splitlines(),new.splitlines(),fromdesc='Before — retained',todesc='After — added encounter and source note',context=True,numlines=3)
save(H/'text-diff.html','<!doctype html><html lang="en"><meta charset="utf-8"><title>Related weather — exact text changes</title><style>'+css+'</style><h1>Related weather</h1><p><a href="index.html">Back to the museum review</a></p>'+table+'</html>')
reading=''
for i,part in enumerate(passage.split('```')):
 if i%2:reading+='<pre><code>'+html.escape(part.removeprefix('gdscript').strip())+'</code></pre>'
 else:
  for paragraph in part.strip().split('\n\n'):
   if paragraph:reading+='<p>'+html.escape(paragraph).replace('[^weather-filter]','<a href="#filter-source"><sup>1</sup></a>')+'</p>'
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Related weather — Ada Research</title><style>STYLE</style><main>
<div class="eyebrow">Ada Research · Noise entrance · 24 September 2026</div><h1>Related weather.</h1><p class="lead">Three walls acquire openings. A line appears on the far side. Walk along their history and find out which relationships let you see through.</p>
<nav><a href="#views">Two positions, one history</a><a href="#reading">New book passage</a><a href="text-diff.html">Exact text differences</a><a href="#evidence">Evidence and limits</a><a href="http://localhost:3003/compose/sources?map=Random_Noise_Types&amp;doc=final">Current chapter</a><a href="http://localhost:3003/necklace/thread?map=Random_Noise_Types&amp;role=primary">Primary encounters</a></nav>
<figure><a href="room.png"><img src="room.png" alt="Full-size pale, brown and pink viewing walls in the museum, with a shared control plinth"></a><figcaption>Fresh draws, accumulated steps and filtered noise. All three use the same new input and travel law. Fixed glass holds the body boundary while the opaque panels change the view. Actual Godot museum render.</figcaption></figure>
<h2 id="views">Two positions, one history</h2><div class="pair"><figure><a href="sight.png"><img src="sight.png" alt="An eye-height view at the oldest sample where the slits do not align across all three walls"></a><figcaption><strong>The first recorded moment.</strong> From this end of the eight-sample history, the three openings do not admit the same eye-height view.</figcaption></figure><figure><a href="aligned.png"><img src="aligned.png" alt="An eye-height view at the newest recorded sample shows the gold line through the three apertures"></a><figcaption><strong>The eighth recorded moment.</strong> Walking to another slot reveals a common opening. These views are from different positions along the same held record; no outcome was forced.</figcaption></figure></div>
<blockquote>Your walk can take the opposite direction from the clock.</blockquote>
<figure><a href="along.png"><img src="along.png" alt="A body-height aisle between the pale and brown viewing walls"></a><figcaption>Walk alongside the last eight moments. The slit in each panel is a target value; the movement between targets is a separate, shared procedure. Apertures are views through glass, not doorways.</figcaption></figure>
<details><summary>From a closed wall to a record</summary><div class="pair"><figure><img src="empty.png" alt="Closed walls before starting"><figcaption>Held and empty on arrival.</figcaption></figure><figure><img src="eight.png" alt="Eight accepted target samples open the slits"><figcaption>Eight NEXT presses, using the production controls.</figcaption></figure></div><p>RUN / HOLD shares one clock. NEXT starts a sample or finishes a paused stroke. REPLAY returns the local seed. NEW SEED clears with another seed. The record stops explicitly at 128; eight moments remain visible.</p></details>
<h2 id="reading">New book passage</h2><div class="reading">PASSAGE</div><p id="filter-source" class="small"><sup>1</sup> The finite pink approximation follows <a href="https://www.dsprelated.com/freebooks/sasp/Example_Synthesis_1_F_Noise.html">Julius O. Smith’s synthesis example</a>. Its measured band and display limits are documented below. The colour alone does not establish its spectrum.</p><p><a href="text-diff.html">Exact differences</a> · <a href="after-final.md">Complete current chapter</a> · <a href="before-final.md">Earlier chapter</a></p>
<h2 id="evidence">Let the names earn their place</h2><figure><a href="signal-study.png"><img src="signal-study.png" alt="Measured raw spectra and the first 128 display-scaled targets, with separate aperture bounds"></a><figcaption>A separate computation from 65,536 actual production-model outputs. The shaded spectral band is 0.01–0.20 cycles per sample. Power slopes are approximately 0, −2 and −1. The right-hand plot shows where display limiting can alter the apparent pattern.</figcaption></figure>
<p>The filtered signal’s slope is −0.992 in that band. Its recurrence agrees with an independent implementation. This evidence concerns the raw signal, before gain, clipping and eased travel. It does not certify a spectrum from eight apertures or measure the older sound-gallery filters.</p>
<table><tr><th>Native controls</th><td>44 checks pass: shared inputs, held motion, one accepted NEXT, replay, explicit record limit, historical targets, marked clipping and fixed glass.</td></tr><tr><th>In the museum</th><td>MUSEUM_COUNT checks pass, plus six sampled walking routes and two floor checks. Uses the registered artifact and actual museum CharacterBody. Native captures include two eye-height views.</td></tr><tr><th>Preserved work</th><td>The existing point, spacing bench, height gallery and sound sculpture remain. Eighteen floor rows extend the hall to 13×28; the exit moves to its new end. Every old structure and artifact row survives. One book encounter and a source note are added; earlier prose is retained.</td></tr></table>
<p class="note">Headset reach, perceived motion, comfort, group use and Quest performance remain to be checked. These are controlled desktop observations. The live bake/save is unchanged; rebuild the hall to load the new source placement.</p>
<details><summary>Sources, decisions and reproducible checks</summary><p><a href="DECISIONS.md">Decisions</a> · <a href="changes.diff">Source differences</a> · <a href="source-manifest.json">Frozen source versions</a> · <a href="publication-checks.json">Preservation checks</a> · <a href="native-checks.json">Native checks</a> · <a href="museum-runtime.json">Museum checks</a> · <a href="signal-checks.json">Signal analysis</a> · <a href="raw-signals.csv">Raw production samples (CSV)</a></p><p class="small">Final passing runs contain no script errors. The project’s unresolved UID and undiagnosed ObjectDB exit warnings remain. No full-book export, live bake replacement or commit.</p></details>
<p><a href="../2026-09-24-door-timing/index.html">Previous: when did the door decide?</a></p></main></html>'''
page=page.replace('STYLE',style).replace('PASSAGE',reading).replace('MUSEUM_COUNT',str(len(museum['checks'])))
save(H/'index.html',page);save(H/'publication-checks.json',json.dumps({'checks':checks,'passed':True},indent=2)+'\n')
for link in re.findall(r'(?:href|src)="([^"]+)"',page):
 if not link.startswith(('http:','https:','#')):check('link exists '+link,(H/link).exists())
save(H/'publication-checks.json',json.dumps({'checks':checks,'passed':True},indent=2)+'\n')
print('Published',len(checks),'preservation/publication checks;',len(museum['checks']),'museum checks.')
