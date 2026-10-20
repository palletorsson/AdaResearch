"""Collect canonical texts; include a current sequence receipt when available."""
from pathlib import Path
import json,shutil,hashlib,html,zipfile,re
import markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-10-swarm-complete-readings';O.mkdir(parents=True,exist_ok=True)
REVIEW=R/'doc/book/iterations/2026-10-10-swarm-sequence-review'
FEEDBACK=R/'doc/book/iterations/2026-10-10-swarm-feedback'
GHOST=R/'doc/book/iterations/2026-10-10-swarm-ghost-student'
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf8'))
def read(p):return json.loads(p.read_text(encoding='utf8'))
seq=read(R/'commons/maps/sequences/swarmintelligence.json')['sequences']['swarmintelligence']['maps']
fresh=None
if (REVIEW/'sequence-checks.json').exists():
 fresh=read(REVIEW/'sequence-checks.json')
 assert fresh['passed'] and fresh['completed'] and [h['hall'] for h in fresh['halls']]==seq
 for h in fresh['halls']:
  for kind in ['tutorial','final']:
   assert hashlib.sha256((R/'commons/maps'/h['hall']/(kind+'.md')).read_bytes()).hexdigest()==h[kind+'_sha256'], 'Stale sequence receipt: rerun tools/test_swarm_sequence.py'
reports=['2026-10-10-swarm-a-trace-outside','2026-10-10-flow-directions-already-here','2026-10-10-boids-who-is-near','2026-10-10-abm-what-the-point-carries','2026-10-10-colony-two-trails-underfoot','2026-10-10-pso-a-place-remembered','2026-10-10-swarm-who-keeps-the-count']
names=['Physarum','Flow Fields','Boids','Agent-Based Modeling','Ant Colony','Particle Swarm','Population Support']
focus=['A body leaves a trace that another can read.','A supplied direction differs from a trace made by agents.','Nearby bodies contribute different steering requests.','The same point carries a state that changes what it does.','Outward and returning travellers use different trail channels.','A score selects a remembered position.','A population account makes supplied support visible.']
images=['live-colony-table','live-flow-table','aquarium','colony-after','eye-level','memory','support']
css='''*{box-sizing:border-box}body{margin:0;background:#f4f2eb;color:#203139;font:18px/1.7 Georgia,serif}main{max-width:1150px;margin:40px auto;padding:0 24px 60px}nav{background:#163440;padding:14px;color:white;font:14px/1.5 system-ui}nav a{color:#c8ede6;margin-right:25px}a{color:#145b70}h1{font-size:48px;line-height:1.15}h2{font-size:28px}article{margin:50px 0 90px;border-top:1px solid #9eb6b7;padding-top:24px}.cards{display:grid;grid-template-columns:1fr 1fr;gap:25px}.card{background:white;padding:20px}.card img{width:100%}.card h2{margin:15px 0 5px}.meta{font:14px/1.6 system-ui}pre{background:#142c34;color:#e1edeb;padding:20px;overflow:auto;font:13px/1.6 Consolas,monospace}code{font-family:Consolas,monospace;font-size:.85em}details{border:1px solid #bdcccc;margin:20px 0;padding:15px}summary{cursor:pointer}table{border-collapse:collapse;width:100%}td,th{border-bottom:1px solid #bdcccc;padding:12px;text-align:left}.notice{background:#fffbef;border-left:4px solid #cdaa50;padding:20px}@media(max-width:760px){.cards{grid-template-columns:1fr}}'''
def render(s):return markdown.markdown(s,extensions=['extra','sane_lists'])
def page(name,title,body):write(O/name,'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><nav><a href="index.html">Seven halls</a><a href="tutorial.html">Complete tutorial</a><a href="final.html">Complete reflection</a><a href="swarm-review.zip">Download ZIP</a></nav><main>'+body+'</main></body></html>')
texts={'tutorial':[],'final':[]};manifest=[];cards='';table='| Hall | What changes |\n| --- | --- |\n'
for i,(id,report,name,description,img) in enumerate(zip(seq,reports,names,focus,images),1):
 m=R/'commons/maps'/id;source=R/'doc/book/iterations'/report
 (O/'halls'/id).mkdir(parents=True,exist_ok=True);(O/'assets').mkdir(exist_ok=True)
 shutil.copy2(source/'assets'/(img+'.png'),O/'assets'/(str(i)+'.png'))
 entry={'hall':id,'order':i,'report':report,'sha256':{}}
 for kind in texts:
  text=(m/(kind+'.md')).read_text(encoding='utf8')
  entry['sha256'][kind]=hashlib.sha256((m/(kind+'.md')).read_bytes()).hexdigest()
  text=text.replace('/book-images/figures/swarmintelligence/tank-two-runs-part.png','assets/tank-two-runs-part.png').replace('../../artifacts/navigator_noise/tutorial.md','supplied/navigator_noise/tutorial.md').replace('../../../doc/book/course/storyboards/SWARM-OPEN-STUDY.md','OPEN-STUDY.md')
  texts[kind].append((id,name,text))
  portable=text.replace('](assets/','](../../assets/').replace('](supplied/','](../../supplied/').replace('](OPEN-STUDY.md)','](../../OPEN-STUDY.md)')
  write(O/'halls'/id/(kind+'.md'),portable)
 for receipt in ['checks.json','source-check.json','SUMMARY.md']:
  if (source/receipt).exists():shutil.copy2(source/receipt,O/'halls'/id/receipt)
 study=R/'doc/book/studies/swarm-through-the-hands'/id
 if study.exists():
  for f in study.iterdir():
   if f.suffix in ['.gd','.tscn']:shutil.copy2(f,O/'halls'/id/f.name)
 entry['has_recorded_code_check']=(source/'checks.json').exists();manifest.append(entry)
 cards+='<section class="card"><img loading="lazy" src="assets/'+str(i)+'.png" alt="'+html.escape(name)+' museum encounter"><div class="meta">'+str(i)+' / 7</div><h2>'+name+'</h2><p>'+description+'</p><a href="tutorial.html#'+id+'">Tutorial</a> · <a href="final.html#'+id+'">Reflection</a> · <a href="http://localhost:3003/book-review/doc/book/iterations/'+report+'/index.html">Project report</a></section>'
 table+='| '+str(i)+'. '+name+' | '+description+' |\n'
toc='<ol>'+''.join('<li><a href="#'+id+'">'+name+'</a></li>' for id,name,_ in texts['final'])+'</ol>'
for kind,title in [('tutorial','Swarm Intelligence — complete tutorial'),('final','Swarm Intelligence — complete reflective sequence')]:
 scope=(str(fresh['total_checks'])+' checks passed in a fresh author-operated Godot reconstruction of all seven printed lessons. See REVIEW.md for limits; independent reader and headset assessment remain open.') if fresh else 'This collection does not itself constitute a fresh whole-sequence test.'
 raw='# '+title+'\n\nCollected from the seven canonical hall files on 10 October 2026. Read inside the prepared Endless Museum. '+scope+'\n\n'
 body='<h1>'+title+'</h1><p>Seven halls, in the current spine order. Complete canonical texts; inherited host dependencies remain part of each lesson.</p>'+toc
 for id,name,text in texts[kind]:
  raw+='\n---\n\n## '+name+'\n\n'+text+'\n'
  body+='<article id="'+id+'"><div class="meta">'+name+'</div>'+render(text)+'</article>'
 write(O/(kind+'.md'),raw);page(kind+'.html',title,body)
write(O/'ROUTE.md','# Swarm — what the next room keeps\n\n'+table+'\nThe point remains recognisable while its useful relations change. These are different models, not seven behaviors silently added to one universal agent. The closing account leads into Graph Theory, then Machine Learning.\n')
intro='''# Review this sequence

Read tutorial.md and final.md separately, then compare them hall by hall. The tutorial should let a reader reconstruct its focused operation using the declared prepared museum and inherited dependencies. The reflection should stay close to the encounter while making a distinct claim.

Follow the PointBody lineage. Identify what is reused, replaced, supplied or newly taught. Require a prediction and independent change in each lesson. Check where a physical intervention differs from neutral observation. Do not treat an analogy as mathematical proof, or a numerical test as a headset evaluation.

This is a collection of the current seven canonical texts, with lesson scripts and prior check receipts. Two inherited image/companion links are rebased for this portable bundle; the manifest hashes identify the original canonical texts. Project report links require the local museum server. It does not run a new independent ghost student or retest all earlier halls. See each hall report for native images, runtime placement and exact test scope. The final hall was freshly tested for this collection. Earlier learner hosts were sometimes temporary comparison studies beside existing museum artifacts; the later Ant Colony, Particle Swarm and Population Support hosts are permanent full-size installations.

These files require the prepared AdaResearch museum, XRTools and declared project dependencies. They are not a standalone Godot project. Population Support's supplied ecosystem sources are included under supplied/ecosystemsimulation. Keep those sources at their declared res:// path when reconstructing inside the project. A physical headset test remains distinct from the synthetic pickup checks.
'''
if fresh:
 intro=intro.replace('This is a collection of the current seven canonical texts, with lesson scripts and prior check receipts.', 'This is a collection of the current seven canonical texts, with lesson scripts and fresh printed-code check receipts for all seven halls.')
 intro=intro.replace('It does not run a new independent ghost student or retest all earlier halls. See each hall report for native images, runtime placement and exact test scope. The final hall was freshly tested for this collection.', 'All seven printed lessons were freshly reconstructed and executed in Godot: 265 checks passed, including 7 independent code variations and 21 deliberately faulty versions detected by the checks. This was author-operated, not an independent ghost student. See REVIEW.md and review/sequence-checks.json for the assessment and exact hashes. Hall reports retain their earlier native images and spatial evidence; rooms were not rerendered in this pass.')
 intro+='\nOpen review.html for the complete sequence assessment, or REVIEW.md for its text. The three updated plan handoffs preserve their existing draft decisions.\n'
 review_text=(REVIEW/'REVIEW.md').read_text(encoding='utf8').replace('](assets/','](review/assets/').replace('](../2026-10-10-swarm-feedback/index.html)','](feedback.html)')
 write(O/'REVIEW.md',review_text)
 page('review.html','Swarm · sequence assessment',render(review_text))
 for name in ['sequence-checks.json','changes.json','lesson-plan.json','review-data.json']:
  target=O/'review'/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(REVIEW/name,target)
 for folder in ['receipts','assets']:
  shutil.copytree(REVIEW/folder,O/'review'/folder,dirs_exist_ok=True)
 for h in fresh['halls']:shutil.copy2(REVIEW/h['log'],O/'review'/h['log'])
feedback_link=''
if (FEEDBACK/'RESPONSE.md').exists():
 feedback_checks=read(FEEDBACK/'sequence-checks.json')
 assert fresh and feedback_checks==fresh, 'Stale feedback receipt: publish_swarm_feedback.py first'
 response=(FEEDBACK/'RESPONSE.md').read_text(encoding='utf8')
 for name in ['sequence-checks.json','changes.json','external-assessment.md']:
  response=response.replace(']('+name+')','](feedback/'+name+')')
 response=response.replace('](../2026-10-10-swarm-artifact-gallery/index.html)','](http://localhost:3003/book-review/doc/book/iterations/2026-10-10-swarm-artifact-gallery/index.html)')
 response=response.replace('](../2026-10-10-swarm-ghost-student/index.html)','](ghost/index.html)')
 write(O/'FEEDBACK.md',response)
 page('feedback.html','Swarm · response to external feedback',render(response.replace('](OPEN-STUDY.md)','](open-study.html)')))
 for name in ['OPEN-STUDY.md','external-assessment.md','sequence-checks.json','changes.json','before-hashes.json','after-hashes.json']:
  target=O/'feedback'/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(FEEDBACK/name,target)
 shutil.copytree(FEEDBACK/'before',O/'feedback/before',dirs_exist_ok=True)
 brief=(FEEDBACK/'OPEN-STUDY.md').read_text(encoding='utf8').replace('../../iterations/2026-10-10-swarm-ghost-student/index.html','ghost/index.html')
 write(O/'OPEN-STUDY.md',brief)
 write(O/'feedback/OPEN-STUDY.md',brief.replace('](ghost/index.html)','](../ghost/index.html)'))
 page('open-study.html','Swarm · optional investigation',render((O/'OPEN-STUDY.md').read_text(encoding='utf8')))
 intro+='\nExternal feedback response: FEEDBACK.md / feedback.html. Seven short additions across five tutorials clarify model changes and transfer to the existing exhibits. All seven reflections and all printed code are unchanged. OPEN-STUDY.md is an optional investigation using the Particle Swarm lesson; its current status and separate results are linked there. The original assessment, before/after hashes and editorial changes are in feedback/.\n'
 feedback_link='<p class="notice"><a href="feedback.html">What changed after external feedback</a> · Clearer study-to-exhibit comparisons and an <a href="open-study.html">optional open investigation</a>. Reflections and printed code unchanged.</p>'
ghost_link=''
if (GHOST/'publication-checks.json').exists():
 ghost_checks=read(GHOST/'publication-checks.json')
 assert ghost_checks['passed'] and ghost_checks['sequence_receipt_sha256']==hashlib.sha256((REVIEW/'sequence-checks.json').read_bytes()).hexdigest()
 shutil.copytree(GHOST,O/'ghost',dirs_exist_ok=True,ignore=shutil.ignore_patterns('*.zip','*.import','*.uid'))
 intro+='\nGhost-student rehearsal: ghost/index.html / ghost/REPORT.md. Seven complete hosts reconstructed from the original review ZIP; 78 new checks, plus 31 native PSO checks and images. Two instruction gaps corrected in Physarum and Boids. Printed code and reflections unchanged. This was author-operated with prior context, not a blind learner or physical headset run. The original lesson inputs remain under ghost/halls/; the corrected current texts are under halls/ and in tutorial.md. The optional RIDGE comparison is completed and retains its contrary result: weaker shared attraction did not sustain a scattered population.\n'
 ghost_link='<p class="notice"><a href="ghost/index.html">Ghost student: seven lessons tested</a> · Two instruction gaps corrected. Read the predictions, new checks and museum investigation.</p>'
write(O/'README.md',intro)
shutil.copy2(R/'doc/book/iterations/2026-10-10-boids-who-is-near/assets/tank-two-runs-part.png',O/'assets/tank-two-runs-part.png')
for source in (R/'commons/artifacts/navigator_noise').iterdir():
 if source.is_file() and source.suffix in ['.md','.gd','.tscn']:
  target=O/'supplied/navigator_noise'/source.name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
for name in ['ecosystem.gd','Creature.gd','food.gd']:
 p=O/'supplied/ecosystemsimulation'/name;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(R/'algorithms/emergentsystems/ecosystemsimulation'/name,p)
write(O/'manifest.json',json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
review_link='<p class="notice"><a href="review.html">Read the seven-hall assessment</a> · '+str(fresh['total_checks'])+' fresh code checks passed; museum code unchanged.</p>' if fresh else ''
page('index.html','Swarm Intelligence · seven halls','<div class="meta">Endless Museum / Complete sequence / 10 October 2026</div><h1>Where coordination lives</h1><p>Trace → direction → neighbours → state → two trails → remembered score → support.</p><p class="notice">The seven tutorial and reflective texts are collected here for review. The point stays recognisable; what it reads, carries and leaves changes from hall to hall.</p>'+ghost_link+feedback_link+review_link+'<p><a href="tutorial.html">Read the complete tutorial</a> · <a href="final.html">Read the complete reflection</a> · <a href="swarm-review.zip">Download both with code and receipts</a></p><div class="cards">'+cards+'</div><h2>Review boundary</h2>'+render(intro))
with zipfile.ZipFile(O/'swarm-review.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in O.rglob('*'):
  if p.is_file() and p.suffix!='.zip':z.write(p,p.relative_to(O))
print('Collected seven canonical tutorial/final pairs with images, scripts and '+('fresh sequence evidence.' if fresh else 'prior receipts.'))
