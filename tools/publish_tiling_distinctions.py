"""Publish a whole-sequence editorial comparison, preserving earlier test receipts."""
from pathlib import Path
import re,json,html,shutil,hashlib,zipfile
import markdown
from tighten_tiling_distinctions import R,O,OLD

def write(p,t):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(t,encoding='utf-8')
def esc(s):return html.escape(str(s))

CSS='''*{box-sizing:border-box}html{background:#ede9e0;color:#252b28}body{margin:0;font:19px/1.65 Georgia,serif}main{max-width:1580px;margin:auto;padding:32px}nav,.eyebrow,summary,figcaption,.label,button{font:14px/1.5 system-ui}nav{display:flex;gap:18px;flex-wrap:wrap;border-bottom:1px solid #aab9ae;padding-bottom:18px}a{color:#2f6458}h1{font-size:clamp(36px,4.6vw,64px);line-height:1.05;max-width:1000px}h2{font-size:30px;line-height:1.18}h3{font-size:23px;line-height:1.2}.lead{max-width:1000px;font-size:23px}.eyebrow{text-transform:uppercase;letter-spacing:.1em;color:#576b5b;margin-top:28px}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:20px}.pair{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:28px}.card,.sheet{min-width:0;background:#faf8f2;padding:24px;border-top:4px solid #3b6758}.sheet h1{font-size:38px}.card img{aspect-ratio:1.44;object-fit:cover}img{max-width:100%;height:auto;display:block}figure{margin:20px 0}figcaption{color:#596a5e;margin-top:8px}.label{display:block;color:#476052;text-transform:uppercase;letter-spacing:.06em;margin:18px 0 5px}p{margin:.8em 0}.card p{font-size:17px}.status{padding:16px 20px;background:#e0e8df;border-left:4px solid #3b6758}.measure{font:14px/1.5 system-ui}.wide-table{overflow:auto}table{border-collapse:collapse;width:100%;font:15px/1.5 system-ui}th,td{text-align:left;vertical-align:top;border-bottom:1px solid #bec8bd;padding:12px}pre{background:#19322d;color:#eef3e8;font:13px/1.5 Consolas,monospace;padding:18px;overflow:auto;tab-size:4}pre code{font-size:inherit}code{font-size:.86em}details{margin:22px 0;padding:14px;background:#e8e8df;border:1px solid #c4c9bf}summary{cursor:pointer;font-weight:650}.diff{max-height:650px}.route{display:flex;gap:8px;flex-wrap:wrap}.route a{display:block;padding:7px 11px;border:1px solid #8ca499;font:14px system-ui;text-decoration:none}.reading{max-width:1000px}.links{font:14px/1.6 system-ui}@media(max-width:1000px){.grid{grid-template-columns:repeat(2,minmax(0,1fr))}}@media(max-width:760px){main{padding:20px}.grid,.pair{grid-template-columns:1fr}.card,.sheet{padding:20px}}@media print{nav,.links{display:none}body{font-size:11pt}.pair,.grid{display:block}.card{break-inside:avoid}.sheet{break-before:page}pre{white-space:pre-wrap;font-size:8pt}details> *{display:block!important}}'''

def page(title,body,prefix=''):
 return f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{esc(title)}</title><style>{CSS}</style></head><body><main><nav><a href="{prefix}index.html">Sequence review</a><a href="{prefix}tutorials.html">Tutorials</a><a href="{prefix}finals.html">Reflective sequence</a><a href="{prefix}changes.html">Changes</a><a href="{prefix}tiling-distinct-halls.zip">Review ZIP</a></nav>{body}</main></body></html>'''

def md(t,dest,optional=False):
 # Resolve canonical book-image and map links into the new portable reading.
 def asset(m):
  path=m.group(1);candidates=[R.parent/'ada_encyclopedia/public/book-images'/path,R/'doc/book'/path]
  source=next((p for p in candidates if p.is_file()),None)
  assert source is not None,path
  name=hashlib.sha256(path.encode()).hexdigest()[:10]+'-'+source.name
  (O/'images').mkdir(exist_ok=True);shutil.copy2(source,O/'images'/name)
  return ('../' if dest.parent!=O else '')+'images/'+name
 t=re.sub(r'/book-images/([^\s)]+)',asset,t)
 t=t.replace('(further-encounters.md)','(further-encounters.html)')
 if optional and '## Optional reconstruction' in t:
  a=t.index('## Optional reconstruction');return md(t[:a],dest)+ '<details class="optional"><summary>Optional complete reconstruction — shared materials</summary>'+md(t[a:],dest,False)+'</details>'
 if optional and '## Complete carried files' in t:
  a=t.index('## Complete carried files');return md(t[:a],dest)+'<details class="carried"><summary>Complete carried files — unchanged, available for reconstruction</summary>'+md(t[a:],dest,False)+'</details>'
 return markdown.markdown(t,extensions=['fenced_code','tables','footnotes'])

def main():
 rows=json.loads((O/'route.json').read_text());audit=json.loads((O/'audit.json').read_text())
 cards=[];all_t=[];all_f=[];diffs=[];measure=[]
 for n,r in enumerate(rows,1):
  h=r['id'];m=R/'commons/maps'/h;d=O/h;d.mkdir(exist_ok=True)
  photo=OLD/h/'museum'/r['image']
  (O/'images').mkdir(exist_ok=True);shutil.copy2(photo,O/'images'/f'{h}.png')
  previous=f'../../2026-10-09-tiling-revision/{h}'
  heading=f'<p class="eyebrow">Tiling {n:02d} / {esc(r["mode"])} / {esc(h)}</p><h1>{esc(r["title"])}</h1><p class="lead">{esc(r["focus"])}</p>'
  nav='<p class="links">'
  if n>1:nav+=f'<a href="../{rows[n-2]["id"]}/parallel.html">Previous</a> · '
  if n<len(rows):nav+=f'<a href="../{rows[n]["id"]}/parallel.html">Next</a> · '
  nav+=f'<a href="http://localhost:3003/tutorial-plan?map={h}&amp;view=summaries">Edit lesson plan</a> · <a href="{previous}/index.html">Earlier runtime evidence</a></p>'
  rendered={}
  for track in ['tutorial','final']:
   t=(m/(track+'.md')).read_text(encoding='utf-8');write(d/(track+'.md'),t)
   rendered[track]=md(t,d/(track+'.html'),optional=track=='tutorial')
   write(d/(track+'.html'),page(r['title']+' / '+track,heading+nav+'<article class="reading">'+rendered[track]+'</article>','../'))
   diff=(O/'changes'/f'{h}-{track}.diff').read_text(encoding='utf-8')
   if diff:diffs.append(f'<h2>{esc(h)} / {track}</h2><details><summary>View text changes</summary><pre class="diff">{esc(diff)}</pre></details>')
  if h=='Pattern_Foundry':
   note=(m/'further-encounters.md').read_text(encoding='utf-8');write(d/'further-encounters.md',note)
   write(d/'further-encounters.html',page('Foundry / further encounters',nav+md(note,d/'further-encounters.html'),'../'))
  write(d/'parallel.html',page(r['title']+' / facing pages',heading+nav+'<div class="pair"><article class="sheet"><p class="label">Tutorial</p>'+rendered['tutorial']+'</article><article class="sheet"><p class="label">Reflection</p>'+rendered['final']+'</article></div>','../'))
  # Aggregate pages use their own asset/link frame.
  t=md((m/'tutorial.md').read_text(encoding='utf-8'),O/'tutorials.html',True)
  f=md((m/'final.md').read_text(encoding='utf-8'),O/'finals.html').replace('href="further-encounters.html"',f'href="{h}/further-encounters.html"')
  all_t.append(f'<section id="{h}" class="reading">{heading}{t}</section>');all_f.append(f'<section id="{h}" class="reading">{heading}{f}</section>')
  card=f'''<article class="card" id="{h}"><p class="eyebrow">{n:02d} / {esc(r['mode'])}</p><h2>{esc(r['title'])}</h2><img src="images/{h}.png" alt="Existing museum capture: {esc(h)}"><p class="label">{esc(r['verb'])}</p><p>{esc(r['focus'])}</p><span class="label">Keep fixed</span><p>{esc(r['keep'])}</p><span class="label">Change</span><p>{esc(r['change'])}</p><span class="label">Show that you understand</span><p>{esc(r['test'])}</p><details><summary>Spatial recommendation — not yet built</summary><p>{esc(r['spatial'])}</p></details><p class="links"><a href="{h}/parallel.html">Read revised pair</a> · <a href="http://localhost:3003/tutorial-plan?map={h}&amp;view=summaries">Edit plan</a></p></article>'''
  cards.append(card)
  data=json.loads((m/'map_data.json').read_text(encoding='utf-8'));ids=[str(c).split('#')[0].split(':')[0].strip() for rr in data['layers']['interactables'] for c in rr if str(c).strip()]
  a=next(a for a in audit['halls'] if a['hall']==h)
  measure.append({'hall':h,'placed_artifact_entries':len(ids),'artifact_ids':ids,'final_words_before':a['final_words_before'],'final_words_after':a['final_words_after'],'complete_code_files':a['code_files_unchanged']})
  # Historical evidence stays intact and points to the current prose.
  for name in ['index.html','parallel.html','tutorial.html','final.html']:
   q=OLD/h/name;s=q.read_text(encoding='utf-8')
   banner=f'<aside class="status" data-tiling-distinction="1">Later sequence edit: <a href="../../2026-10-09-tiling-different-jobs/{h}/parallel.html">read the current pair with a clearer role for this hall</a>. This page retains the earlier tested reading.</aside>'
   if 'data-tiling-distinction="1"' not in s:s=s.replace('</nav>','</nav>'+banner,1);write(q,s)
 nav='<div class="route">'+''.join(f'<a href="#{r["id"]}">{n+1}. {esc(r["title"])}</a>' for n,r in enumerate(rows))+'</div>'
 report='''# Nine rooms need different jobs

The individual examples work, but the teaching rhythm has been too uniform. A new file, another selector and four complete code listings can make a small return feel as large as a new concept. The hall-to-hall difference needs to be visible in the action and its consequence, not merely in a new title.

## Where the distinction weakens

- **Foundry arrives with too much of the later sequence already on display.** Its reflective text was 2,112 words and toured reflection, curved receivers, holding, saving, architecture and offset. Its first job is smaller and strong: make one source edit and see its reach. The extended encounters are now a separate return-visit reading. Their objects remain in the museum.
- **Tutorial Pattern and Symmetry look like another visit to the same console.** Both use framed fields, a source editor and a carpet. The conceptual difference is mutation versus reflected reading in the first; composition and the limits of classification in the second. The second needs the scale of a short extension, with a visibly different comparison.
- **The learner display does not show its whole period.** Three source columns become a six-column horizontal period under the demonstrated alternating reflection. A five-column preview cuts that return off. Tests can query a distant address, but that is weaker than seeing the relationship. A proposed next build is a 12-column comparison view, showing two full six-column periods, with an explicit physical size. This is not implemented by this prose pass.
- **Temple should be a composition exercise.** It brings source, rule, frame and ownership together. Foundry's occurrences share one live source; Temple's receivers can copy a recipe and then diverge. Its room-scale authority and choice of one dissenting wall earn the hall. It should not become another pattern catalogue.
- **Ribbon 01 is a branch, not a prerequisite for the shader.** Height as an address input is valuable, but the next two lessons can operate on surfaces without its volume. The text now says so.
- **Ribbon 02 is a pause to investigate.** Equal target values, different surrounds and different carriers sharpen observation. Another complete grid construction need not be mandatory here. Its runnable reconstruction remains available as an optional return to material sharing.
- **Code continuity is stronger than saved-state continuity.** The point, palette and renderer return, but replacing entry scripts reinitializes lesson state. The studio later supplies a declared four-by-four source. We must not describe this as one learner-edited motif automatically travelling through every room. A persistent motif would be a separate implementation, with explicit copying and lifetime rules.

## A more varied teaching rhythm

Return in Disco. Build the source in Foundry. Change its reader. Give its addresses a physical place. Add a glide as a short extension. Compose a court with independently owned recipes. Branch into a volume. Pause to compare appearances. Write a sampling shader and carry the recipe onto a garment.

The common question is: **what changes here, what remains fixed, and what becomes possible that the previous room did not provide?** Not every answer requires a new programming construct. The student also chooses, investigates and composes.

## Keep the physical order for this revision

The current order is workable. Array Patterns between reflection and glide gives the student a bodily passage before returning to address operations. The current glide script also inherits Array Patterns' receiver. Moving Symmetry earlier would require changing that code dependency, not just rearranging chapter names.

An alternative is to group reflection and glide in one longer lesson, then enter the tunnel. That may be worth trying after the visual comparison improves. Reordering now would not by itself fix repeated consoles, an incomplete visible period or nine equally heavy reading tasks.

## What changed now

Learning labels and the opening scope of all nine tutorials now name their distinct job. Unchanged companion files move after the new operation and its prediction, and are expandable in these reading pages. All full code remains in the Markdown and review package. Ribbon 02's construction is explicitly optional; its observation task remains part of the route.

Foundry's first reflective reading is shorter; the longer existing encounters remain linked. Temple now explicitly contrasts a copied recipe with Foundry's shared source. Symmetry begins from a reflection already understood. The editable plan uses reuse, build, compose and reflect deliberately rather than treating every hall as a new build.

The native images here were captured during the preceding hall tests. They show existing spaces, not newly built layouts. No artifact was removed, no hall moved, and no production or student code was changed in this pass.

## What the next spatial pass should earn

First make a full reflected/glided return visible. Then distinguish the two encounters: Tutorial Pattern exposes source mutation beside reflected reading; Symmetry exposes the additional displacement and the assumptions of classification. Keep the familiar mark so the changed operation, not a new decorative source, explains the difference.

After that, make the primary path through Foundry lead to one source and its repeated result. Keep Temple focused on its whole-room copy-and-diverge action. Let Ribbon 02 be visually quiet enough for comparison, and let the studio, mirror and procession carry the final hall. Extra artifacts can remain part of the wider field without all becoming lesson stations.

## Evidence and limits

All 36 named printed file occurrences across nine lessons match their earlier tested code, comparing text with normalized file line endings. The nine map configurations and sequence definition match their pre-edit hashes. Only the nine selected plan entries were changed. Existing behavior checks still describe that code; they were not rerun as a new student trial for this prose edit.

This review reads the current two text tracks, inspects map inventories and compares existing native captures. It identifies likely teaching and spatial problems; it does not establish that a reader understands the revised sequence. The next useful learner check is a cold prediction across adjacent halls, including explaining why the same-looking controls have a different scope.
'''
 write(O/'REPORT.md',report)
 (O/'images').mkdir(exist_ok=True)
 shutil.copy2(OLD/'Symmetry_Seventeen/museum/installed-p1-pg.png',O/'images/symmetry-comparison.png')
 shutil.copy2(OLD/'Tutorial_Pattern/museum/two-fixed-fields.png',O/'images/reflection-comparison.png')
 comparison='''<h2>The overlap is visible</h2><div class="pair"><figure><img src="images/reflection-comparison.png" alt="Tutorial Pattern: source editor between two framed fields"><figcaption>Tutorial Pattern: did the stored mark change, or did its reader change?</figcaption></figure><figure><img src="images/symmetry-comparison.png" alt="Symmetry: another source editor between two framed fields"><figcaption>Symmetry: what does adding a displacement to reflection change? The setting currently resembles the earlier lesson.</figcaption></figure></div>'''
 intro='<p class="eyebrow">Endless Museum / Tiling / sequence reading / 9 October 2026</p><h1>Nine rooms need different jobs.</h1><p class="lead">The continuity is there. The differences need clearer actions, unequal teaching weight and more distinct encounters.</p><p class="status">Applied: text emphasis and reading layout. Proposed: room curation and a larger comparison preview. Every existing artifact remains.</p>'
 write(O/'index.html',page('Tiling / nine rooms, different jobs',intro+nav+comparison+'<div class="reading">'+markdown.markdown(report[report.index('## Where'):],extensions=['tables'])+'</div><h2>Read the route one hall at a time</h2><div class="grid">'+''.join(cards)+'</div>'))
 write(O/'tutorials.html',page('Tiling / tutorials with distinct roles','<h1>The tutorial route</h1>'+nav+'<p>Complete code remains available. Expand carried files when reconstructing; follow the new operation and its prediction first.</p>'+''.join(all_t)))
 write(O/'finals.html',page('Tiling / reflective sequence','<h1>The reflective route</h1>'+nav+''.join(all_f)))
 write(O/'changes.html',page('Tiling / text changes','<h1>Text and emphasis</h1><p>Executable fences are unchanged. Foundry’s longer encounters are preserved in a separate return-visit reading.</p>'+''.join(diffs)))
 write(O/'inventory.json',json.dumps(measure,indent=2)+'\n')
 write(O/'README.md','Open index.html. This is a prose/role revision of the nine tested Tiling drafts. Full code is printed in each tutorial.md. Inherited code needs the explicitly supplied museum project; this archive is not a standalone Godot project. Earlier runtime receipts are linked, not newly executed here. The native photos precede this text-only pass. All physical redesigns are recommendations.\n')
 # Add a discoverable forward link without replacing the earlier per-hall evidence.
 plan=OLD/'PLAN.md';s=plan.read_text(encoding='utf-8')
 note='\n\n## Sequence distinction review\n\nThe later [nine-room reading](../2026-10-09-tiling-different-jobs/index.html) gives the halls different teaching weights, narrows Foundry’s first visit, and distinguishes copying, a volume branch and a reflective pause. Read those current texts before the earlier snapshots below. Runtime code and the physical order are unchanged.\n'
 if '## Sequence distinction review' not in s:s=s.replace('\n\n9 October',note+'\n9 October',1);write(plan,s)
 q=OLD/'plan.html';s=q.read_text(encoding='utf-8')
 if 'data-distinction-review' not in s:s=s.replace('</nav>','</nav><aside class="status" data-distinction-review="1">Current sequence reading: <a href="../2026-10-09-tiling-different-jobs/index.html">nine rooms with different jobs</a>. Text emphasis revised; previous code evidence retained.</aside>',1);write(q,s)
 with zipfile.ZipFile(O/'tiling-distinct-halls.zip','w',zipfile.ZIP_DEFLATED) as z:
  for p in O.rglob('*'):
   if p.is_file() and p.suffix!='.zip':z.write(p,p.relative_to(O).as_posix())
 print('Published',O/'index.html')

if __name__=='__main__':main()
