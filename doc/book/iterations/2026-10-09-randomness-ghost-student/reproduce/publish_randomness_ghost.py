"""Publish the author-informed learner run without replacing the reviewed edition."""
from pathlib import Path
import difflib, hashlib, html, json, re, shutil, zipfile
import markdown
from run_randomness_ghost_student import ROOT, OUT, PROBES

OLD=ROOT/'doc/book/iterations/2026-10-09-randomness-review-ready'
NOTES=[
 ('Definition','The cube and material return as a grid of requests. I swapped red and blue and made a five-by-five picture. Green, addresses and generator state stayed; adding a discarded draw still shifted the stream. A seed identifies a beginning, not a complete recipe.'),
 ('Entropy','I supplied four blocks of four symbols. Both that arrangement and a cyclic one measured two bits, but their unlike-neighbour counts were three and fifteen. I can explain the lost order without deriving the formula. Sorting a copy preserved the original.'),
 ('Remove','I replaced the central-square eligibility rule with the diagonal. Eight addresses were removed once each, then the empty guard spent no draw. Equal treatment within a candidate set does not decide who belongs to that set.'),
 ('10 PRINT','I changed the threshold from one half to three eighths. The same samples now selected a different subset of marks. Twenty-four is the expected count in sixty-four cells, not a required outcome. This lesson does not promise the fixed counts of the separate comparison artifact.'),
 ('Cubes','I allowed every even face to continue. The supplied record 2, 4, 3 now totalled nine before closing. Reaching a display limit remained different from drawing a stopping face. I changed what an outcome permits, not the die.'),
 ('Rotate','I supplied turns of +12, −4 and −8 degrees. The accumulated cube returned to zero while the assigned cube ended at −8. Replay read the record without drawing again. Transformation now carries a history rather than only an angle.'),
 ('Walk','I halved the step length and compared the first four moves before a boundary could interfere. Displacements halved. Altering an old trail entry did not steer the next step. The distinction between a current position and its record is doing real work here.'),
 ('Gaussian','I used eight explicit values, including two outside the displayed interval, and changed to six bins. Counts became 3, 0, 1, 1, 0, 3; two values were clipped. Rebinning kept the raw evidence. A changed histogram is not automatically a changed population.'),
 ('Mushrooms','I reduced the population to seven and widened its scale interval. The retained members kept their recipe, position and turn; each scale deviation from one doubled. SIZE changed expression without rerolling identities. This is variation within a repertoire, not generation of new recipes.'),
 ('Space Geometry','I spread the columns farther apart. Their positions changed while sampled records, generator state and neighbour-gap readings stayed. Separate fixtures gave a checkerboard gap of one and a half-plane split of one fourteenth. A display distance and a field-sampling frequency are different controls.'),
 ('Examples of Randomness','I requested seven darts at a time. The final partial batch stopped at 256 and matched single-step sampling, including every intermediate estimate. The test checked the area ratio and retained samples, not whether one finite run happened to land near pi.'),
 ('Pheromone','I disabled guidance while retaining deposition. Even a strongly uneven scent field then left the path unchanged. With guidance enabled, a first eastward choice returned toward its deposited scent. Here history can enter the next decision; Walk did not do that. The first uniform-field test was too weak and was replaced.'),
 ('Space','I kept three layers but set persistence to zero. The two later contributions vanished, and changing their frequency ratio could not change the sum. The raw field matched one layer. Comparing raw values matters because independently stretched displays can disguise changes in magnitude.'),
 ('Game','I shortened advance notice from 1.2 to 0.3 seconds. A sixty-second comparison retained state transitions, support decisions and deadlines. Only the warning interval changed. A future event can already be scheduled while the visitor still lacks useful notice of it.'),
]

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def md(s):return markdown.markdown(s,extensions=['extra'])
def page(title,body):
 return f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>
 body{{margin:0;background:#f5f2ec;color:#252127;font:18px/1.65 Georgia,serif}}main{{max-width:1060px;margin:auto;padding:42px 30px}}h1{{font-size:clamp(36px,5vw,64px);line-height:1.08;max-width:900px}}h2{{margin-top:2em;font-size:29px}}nav,.meta,summary,th{{font:14px/1.6 system-ui}}nav{{display:flex;gap:22px;flex-wrap:wrap;border-bottom:1px solid #cbbfb8;padding-bottom:20px}}a{{color:#7b2850}}p{{max-width:830px}}article{{border-top:1px solid #cbbfb8;padding:18px 0}}table{{border-collapse:collapse;width:100%;font:15px/1.55 system-ui}}td,th{{padding:12px;border-bottom:1px solid #d6cec5;text-align:left;vertical-align:top}}pre{{background:#e9e3dc;padding:20px;overflow:auto;font:13px/1.5 monospace}}code{{font-size:.85em}}img{{max-width:100%;height:auto}}.pair{{display:grid;grid-template-columns:1fr 1fr;gap:24px}}figure{{margin:20px 0}}figcaption{{font:14px/1.5 system-ui;color:#63565b}}details{{padding:12px;border:1px solid #cabbb4;margin:20px 0}}@media(max-width:760px){{.pair{{grid-template-columns:1fr}}main{{padding:22px}}}}@media print{{nav{{display:none}}article{{break-inside:avoid}}}}
 </style><main><nav><a href="index.html">Ghost-student report</a><a href="readings/parallel.html">Facing pages</a><a href="readings/tutorial.html">Tutorial</a><a href="readings/final.html">Reflection</a><a href="randomness-ghost-review.zip">Review ZIP</a></nav>{body}</main></html>'''

def main():
 predictions=json.loads((OUT/'predictions.json').read_text())
 tests=json.loads((OUT/'tests.json').read_text())
 mutants=json.loads((OUT/'mutations.json').read_text())
 assert tests['all_passed'] and tests['checks']==480 and mutants['all_rejected']
 assert len(predictions)==len(NOTES)==14
 sources=[]
 for row in predictions:
  m=row['map'];src=ROOT/'commons/maps'/m/'tutorial.md'
  assert sha(src)==row['source_sha256'],m
  blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',src.read_text(encoding='utf-8-sig'),re.S))
  for name,code in blocks.items():
   p=OUT/'learner'/m/'printed'/name
   assert p.read_text()==code+'\n' and sha(p)==row['files'][name]
  for track in ['tutorial','final']:
   p=src.with_name(track+'.md');assert p.read_bytes()==(OUT/'before'/m/p.name).read_bytes()
   sources.append({'path':p.relative_to(ROOT).as_posix(),'sha256':sha(p)})
 # Retain the reading edition reviewed by the other model, with all local assets.
 dest=OUT/'readings';dest.mkdir(exist_ok=True)
 for p in OLD.iterdir():
  if p.is_file() and p.suffix in ['.html','.md']:shutil.copy2(p,dest/p.name)
 for folder in ['images','learner','tests','changes','before']:
  if (OLD/folder).exists():shutil.copytree(OLD/folder,dest/folder,dirs_exist_ok=True)
 for name in ['tests.json','verification.json','randomness-review.zip']:
  shutil.copy2(OLD/name,dest/name)
 # Historical edition links remain historical; the new report supplies current evidence.
 for p in dest.glob('*.html'):
  s=p.read_text(encoding='utf-8');s=s.replace('<main>','<main><p class="meta"><a href="../index.html">Current ghost-student validation and entrance repairs</a> · This reading edition remains the reviewed snapshot.</p>',1);p.write_text(s,encoding='utf-8')
 shutil.copy2(Path('C:/Users/palle/.codex/attachments/2153f4d8-6993-43ff-9ca4-642a77193755/Pasted text.txt'),OUT/'EXTERNAL-REVIEW.md')
 methods=OUT/'reproduce';methods.mkdir(exist_ok=True)
 scripts=['run_randomness_ghost_student.py','test_randomness_ghost_mutants.py','check_randomness_entries.py','publish_randomness_ghost.py']
 probes=['randomness_ghost_transfer.gd','randomness_entries.gd','transformation_encounters.gd']+[x+'_student.gd' for x in PROBES]
 for name in scripts:shutil.copy2(ROOT/'tools'/name,methods/name)
 for name in probes:shutil.copy2(ROOT/'tools/probes'/name,methods/name)
 evidence=[]
 for m in ['Random_Space','Random_Game']:
  p=OUT/'museum/after'/m/'report.json';data=json.loads(p.read_text());assert data['passed'],m
  evidence.append({'map':m,'checks':len(data['checks']),'observations':data['observations']})
  slim=OUT/'entrances'/m;slim.mkdir(parents=True,exist_ok=True)
  for name in ['report.json','engine.log','entrance.png','overview.png','map_data.json']:shutil.copy2(p.parent/name,slim/name)
  src=ROOT/'commons/maps'/m/'map_data.json';old=OUT/'before'/m/src.name
  assert src.read_bytes()==(slim/'map_data.json').read_bytes()
  delta=''.join(difflib.unified_diff(old.read_text().splitlines(True),src.read_text().splitlines(True),fromfile='before/'+m+'/map_data.json',tofile='after/'+m+'/map_data.json'))
  (slim/'map.diff').write_text(delta)
  sources.append({'path':src.relative_to(ROOT).as_posix(),'sha256':sha(src)})
 (OUT/'sources.json').write_text(json.dumps(sources,indent=2)+'\n')
 table=[];cards=[];notes=['# Randomness — ghost-student notebook\n\nAuthor-informed reconstruction, 9 October 2026. Each changed program is a separate copy; the printed version remains intact.\n']
 for row,(label,note) in zip(predictions,NOTES):
  m=row['map'];baseline=next(r for r in tests['results'] if r['map']==m and r['kind']=='baseline');transfer=next(r for r in tests['results'] if r['map']==m and r['kind']=='transfer')
  table.append(f'<tr><td><a href="#{m}">{row["index"]+1}. {label}</a></td><td>{baseline["checks"]}</td><td>{transfer["checks"]}</td><td>Pass</td></tr>')
  files=' · '.join(f'<a href="learner/{m}/changed/{html.escape(n)}">{html.escape(n)}</a>' for n in row['files'])
  cards.append(f'<article id="{m}"><p class="meta">{row["index"]+1:02d} / {m}</p><h2>{label}</h2><p>{html.escape(note)}</p><details><summary>Prediction made before execution</summary><p>{html.escape(row["prediction"])}</p></details><p class="meta">Changed program: {files}<br><a href="{baseline["receipt"]}">Baseline receipt</a> · <a href="{transfer["receipt"]}">Transfer receipt</a></p></article>')
  notes.append(f'\n## {row["index"]+1}. {label}\n\n{note}\n\nPrediction: {row["prediction"]}\n\nChecks: {baseline["checks"]} baseline + {transfer["checks"]} transfer. Both passed.\n')
 (OUT/'student-notes.md').write_text('\n'.join(notes),encoding='utf-8')
 report=(OUT/'REPORT.md').read_text(encoding='utf-8')
 body=md(report)+'<h2>Fourteen independent changes</h2><table><thead><tr><th>Hall</th><th>Baseline</th><th>Transfer</th><th>Result</th></tr></thead><tbody>'+''.join(table)+'</tbody></table>'
 body+='<h2>Repaired entrances in the museum</h2><div class="pair">'+''.join(f'<figure><img src="entrances/{e["map"]}/entrance.png" alt="Native Godot capture of {e["map"]} entrance"><figcaption>{e["map"]} · {e["checks"]} native checks. <a href="entrances/{e["map"]}/report.json">Receipt</a> · <a href="entrances/{e["map"]}/map.diff">Map change</a></figcaption></figure>' for e in evidence)+'</div>'
 body+=''.join(cards)
 (OUT/'index.html').write_text(page('Randomness — the ghost student changes the rule',body),encoding='utf-8')
 readme='''# Randomness — ghost-student review packet

Open index.html. Read REPORT.md for scope and student-notes.md for the fourteen answers. readings/ contains the complete previously reviewed tutorial and reflection, facing pages, all illustrations and the historical review packet. Its 420-check claims are dated baseline evidence; the new report adds 60 transfer checks and entrance repairs.

This is an author-informed run, not an unfamiliar student trial. Thirty-one exact printed files and thirty-one edited files are in learner/. predictions.json was written before execution. tests.json records 28 successful native Godot processes. mutations.json records six executable faults rejected by assertions. The 60 transfer checks include fourteen initialization checks. Failures of the test harness are retained in attempts/ and described in REPORT.md.

This is not a standalone Godot project. Use the prepared Endless Museum Godot 4.6 project with its existing XR Tools dependencies. All printed dependencies supplied by the lessons are included; the host supplies the player and world. The copied reproduction tools run from the original repository tools/ and tools/probes/ paths, not from this ZIP. Running run_randomness_ghost_student.py reconstructs current canonical text and writes fresh evidence; preserve this dated packet before doing so. That runner does not make the entrance edits: entrances/*/map.diff records them separately.

No human/headset comfort, Quest performance, continuous whole-museum traversal or long-reading endurance claim follows from these checks. Noise is still a separate next sequence.
'''
 (OUT/'README.md').write_text(readme,encoding='utf-8')
 # Exclude heavyweight live museum snapshots and nested archives from the portable packet.
 included=[]
 for p in OUT.rglob('*'):
  if not p.is_file():continue
  rel=p.relative_to(OUT)
  if rel.parts[0]=='museum' or '.zip'==p.suffix or p.suffix in ['.uid','.import','.pyc']:continue
  if '__pycache__' in rel.parts:continue
  if rel.parts[:2]==('attempts','entry-scan-low-origin') or rel.parts[:2]==('attempts','entry-first-reposition'):continue
  if 'museum_snapshot' in p.name or p.name=='plan.json':continue
  included.append(p)
 # The historical edition's archive link points to the old online/local sibling, not a missing nested ZIP.
 for p in dest.glob('*.html'):
  s=p.read_text().replace('href="randomness-review.zip"','href="../randomness-ghost-review.zip"');p.write_text(s,encoding='utf-8')
 from html.parser import HTMLParser
 from urllib.parse import urlsplit,unquote
 class Refs(HTMLParser):
  def __init__(self):super().__init__();self.refs=[]
  def handle_starttag(self,tag,attrs):
   d=dict(attrs)
   for k in ['href','src']:
    if k in d:self.refs.append(d[k])
 failures=[];count=0
 for p in [OUT/'index.html',*dest.glob('*.html')]:
  parser=Refs();parser.feed(p.read_text())
  for ref in parser.refs:
   u=urlsplit(ref)
   if u.scheme or u.netloc or not u.path:continue
   if u.path.endswith('randomness-ghost-review.zip'):continue
   target=(p.parent/unquote(u.path)).resolve();count+=1
   if not target.exists():failures.append((str(p.relative_to(OUT)),ref))
 assert not failures,failures
 validation={'printed_sources_unchanged':True,'printed_files':31,'baseline_checks':420,'transfer_checks':60,'mutation_faults_rejected':6,'entrance_checks':sum(e['checks'] for e in evidence),'local_targets_checked':count,'author_informed':True,'headset_tested':False,'continuous_route_tested':False}
 (OUT/'validation.json').write_text(json.dumps(validation,indent=2)+'\n');included.append(OUT/'validation.json')
 archive=OUT/'randomness-ghost-review.zip'
 with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
  for p in sorted(set(included)):z.write(p,p.relative_to(OUT).as_posix())
 with zipfile.ZipFile(archive) as z:assert z.testzip() is None
 print(json.dumps(validation));print('ZIP',round(archive.stat().st_size/1e6,2),'MB')

if __name__=='__main__':main()
