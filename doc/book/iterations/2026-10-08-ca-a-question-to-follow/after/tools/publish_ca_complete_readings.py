"""Collect the current eight CA halls without editing canonical manuscripts or code."""
from pathlib import Path
from urllib.parse import urlsplit,unquote
from html import escape
import ast,hashlib,json,re,shutil,zipfile,posixpath
import markdown
from bs4 import BeautifulSoup

R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-complete-readings'
REVISION=R/'doc/book/iterations/2026-10-08-ca-a-question-to-follow'
SEQ=R/'commons/maps/sequences/cellularautomata.json'
order=json.loads(SEQ.read_text(encoding='utf-8-sig'))['sequences']['cellularautomata']['maps']
assert order==['CA_Introduction','CA_ElementaryRules','CA_GameOfLife','CA_BeyondBinary','CA_ExpandingSpace','CA_SoftRules','CA_AgentsCircuits','CA_EdgeOfChaos']
for name in ['sources','student-files','assets','evidence']:(O/name).mkdir(parents=True,exist_ok=True)
def read(p):return p.read_text(encoding='utf-8-sig')
def write(p,s):p.write_bytes(s.encode('utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(p,x):write(p,json.dumps(x,ensure_ascii=False,indent=2)+'\n')
receipts=dict(zip(order,[
 '2026-10-08-ca-a-row-with-neighbours','2026-10-08-ca-a-state-that-lingers',
 '2026-10-08-ca-history-three-bodies','2026-10-08-ca-a-pattern-visits',
 '2026-10-08-ca-the-surface-includes-you','2026-10-08-ca-what-a-neighbour-offers',
 '2026-10-08-ca-two-ways-to-make','2026-10-08-ca-what-a-difference-keeps']))
operations=[
 'Read three Boolean states, select a rule answer and write a new row. Keep old and next separate.',
 'Give each address empty, active or fading state. Count active neighbours in a finite volume.',
 'Keep independent generations and map one record onto a board and supporting tiles.',
 'Update a two-dimensional present. Follow a moving pattern through fixed addresses and connect one address to a lamp.',
 'Let a position become an input. Compare decay, recovery and simultaneous versus ordered updates.',
 'Store two concentrations and compare local reaction with neighbour exchange.',
 'Compare a local state update with a supplied recursive placement recipe. Change only the seed.',
 'Run matched fields from almost identical beginnings. Distinguish storage, measurement and display gain.']
roles=[
 'Move to inspect an address; trigger advances one generation.',
 'Carry STEP while observing the enlarged neighbourhood.',
 'Move to inspect a recorded generation; trigger appends the next.',
 'Carry STEP; the point does not plant or move the pattern.',
 'Place the held point near the field; its position enters the rule.',
 'Choose a position and trigger a seed in both fields.',
 'Return to address inspection and STEP beside a fixed construction.',
 'Select a Z section; trigger updates both fields. Release returns the installed reader to walking.']
questions=[
 'What does a local rule make, and what has the display or imposed symmetry already arranged?',
 'Can something remain present after it stops contributing to its neighbours?',
 'When does a gap in an image become a missing support for a body?',
 'What moves when the addresses stay, and what does being observed change?',
 'What happens when observing becomes one of the conditions of the surface?',
 'What can a cell receive, and which relations have been withheld?',
 'Does a similar outline establish the same way of making?',
 'Has a difference vanished, or have our storage, counting and viewing choices hidden it?']
sources=[];printed=[];assets=[];halls=[];texts={};evidence=[]
shutil.copy2(SEQ,O/'sources/cellularautomata.json')
plan=json.loads(read(R/'doc/book/course/execution-plan/plan.json'))
selected=[next(x for x in plan['lessons'] if x['id']==hall) for hall in order]
dump(O/'sources/lesson-contracts.json',selected)
def outside_code(text,fn):
 chunks=re.split(r'(```[^\n]*\n.*?```)',text,flags=re.S)
 return ''.join(chunk if i%2 else fn(chunk) for i,chunk in enumerate(chunks))
def add_asset(p,hall,filename=None):
 dest=O/'assets'/hall/(filename or p.name);dest.parent.mkdir(parents=True,exist_ok=True)
 if dest.exists() and any(a['file']==dest.relative_to(O).as_posix() for a in assets):assert sha(dest)==sha(p),(p,dest)
 shutil.copy2(p,dest)
 record={'source':p.relative_to(R).as_posix(),'file':dest.relative_to(O).as_posix(),'sha256':sha(dest)}
 if record not in assets:assets.append(record)
 return dest.relative_to(O).as_posix()
def prepare(text,hall,source):
 def fix(chunk):
  chunk=re.sub(r'\[\^([^\]]+)\]',lambda m:'[^'+hall+'-'+m[1]+']',chunk)
  def local_image(m):
   u=urlsplit(m[2])
   if u.scheme or u.netloc:return m[0]
   p=(source.parent/unquote(u.path)).resolve();assert p.is_file(),(source,m[2])
   return '!['+m[1]+']('+add_asset(p,hall)+')'
  return re.sub(r'!\[([^\]]*)\]\(([^)]+)\)',local_image,chunk)
 return outside_code(text,fix)
for i,hall in enumerate(order):
 row={'id':hall,'number':i+1,'operation':operations[i],'point_role':roles[i],'question':questions[i],'tracks':{}}
 lesson=R/'doc/book/studies/cellular-automata-through-the-hands'/hall
 run=R/'doc/book/iterations'/receipts[hall]
 recorded=json.loads(read(run/'printed-hashes.json'))
 for track in ['tutorial','final']:
  p=R/'commons/maps'/hall/(track+'.md');target=O/'sources'/hall/p.name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,target)
  sources.append({'path':p.relative_to(R).as_posix(),'copy':target.relative_to(O).as_posix(),'sha256':sha(p)})
  raw=read(p);texts[(hall,track)]=prepare(raw,hall,p)
  blocks=re.findall(r'```[^\n]*\n(.*?)\n```',raw,re.S)
  prose=re.sub(r'```.*?```','',raw,flags=re.S);prose=re.sub(r'<!--.*?-->','',prose,flags=re.S)
  row['tracks'][track]={'title':raw.splitlines()[0].lstrip('# '),'prose_words_approx':len(prose.split()),'code_blocks':len(blocks),'code_lines':sum(len(x.splitlines()) for x in blocks)}
  if track=='tutorial':
   for block in blocks:
    candidates=[p for p in lesson.glob('*.gd') if read(p)==block+'\n'];assert len(candidates)==1,(hall,len(candidates))
    original=candidates[0];previous=run/'printed'/original.name
    assert read(previous)==block+'\n' and sha(previous)==recorded[original.name],original
    target=O/'student-files'/hall/original.name;target.parent.mkdir(parents=True,exist_ok=True);write(target,block+'\n')
    printed.append({'hall':hall,'file':original.name,'copy':target.relative_to(O).as_posix(),'sha256':sha(target),'lines':len(block.splitlines()),'source':original.relative_to(R).as_posix(),'source_sha256':sha(original),'matches_previously_tested_printed_code':True,'recorded_printed_sha256':recorded[original.name]})
  else:assert not blocks,hall
 row['label']=row['tracks']['tutorial']['title']
 photo_paths=re.findall(r'!\[[^\]]*\]\(([^)]+)\)',texts[(hall,'final')]);row['image']=photo_paths[0]
 spatial=R/'doc/book/iterations/2026-10-08-ca-rooms-connected/after/museum' if i==0 else run/'museum'
 row['overhead']=add_asset(spatial/'overhead.png',hall,'room-overhead.png')
 ed=O/'evidence'/hall;ed.mkdir(parents=True,exist_ok=True)
 current=[]
 for source,name,scope in [(run/'checks.json','learner-checks.json','Exact printed learner code'),(run/'museum/report.json','museum-checks.json','Museum interaction and capture')]:
  d=json.loads(read(source));assert d['passed'] and not d.get('failures'),source
  shutil.copy2(source,ed/name);current.append({'scope':scope,'checks':len(d['checks']),'receipt':(ed/name).relative_to(O).as_posix(),'passed':True})
 for source,name in [(run/'engine.log','learner-engine.log'),(run/'museum/engine.log','museum-engine.log'),(run/'printed-hashes.json','printed-hashes.json')]:shutil.copy2(source,ed/name)
 if i==0:
  d=json.loads(read(spatial/'report.json'));assert d['passed'];shutil.copy2(spatial/'report.json',ed/'later-layout-checks.json');shutil.copy2(spatial/'engine.log',ed/'later-layout-engine.log')
  current.append({'scope':'Later opening-hall layout pass','checks':len(d['checks']),'receipt':(ed/'later-layout-checks.json').relative_to(O).as_posix(),'passed':True})
 evidence.append({'hall':hall,'original_run':receipts[hall],'runs':current,'rerun_for_compilation':False,'all_printed_files_still_match_recorded_tested_files':True})
 halls.append(row)
assert len(printed)==19
assert len({p['sha256'] for p in printed if p['file']=='point_body.gd'})==1
totals={track:{key:sum(h['tracks'][track][key] for h in halls) for key in ['prose_words_approx','code_blocks','code_lines']} for track in ['tutorial','final']}
# Keep the established reading layout without importing an executable publisher.
tree=ast.parse(read(R/'tools/publish_fractals_complete_readings.py'))
css=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='css' for t in n.targets))
css+='\nfigure{margin:24px 0}figcaption{font:13px/1.5 system-ui;color:#665d62;padding:8px 0}.hall-card{border-top:1px solid #cbbdbd;padding:28px 0}.hall-card img{display:block;max-height:540px;object-fit:contain;background:#e6e1d9;width:100%}details{margin:18px 0}summary{cursor:pointer;font:14px/1.5 system-ui}#evidence{overflow:auto}thead th{font:13px/1.5 system-ui}.review-table td:first-child{min-width:140px}\n'
write(O/'reading.css',css)
def page(title,body):
 return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+escape(title)+'</title><link rel="stylesheet" href="reading.css"></head><body><header><nav><a href="index.html">Sequence review</a><a href="tutorial.html">Full tutorial</a><a href="final.html">Full reflection</a><a href="parallel.html">Side by side</a><a href="review.html">Reviewer brief</a><a href="cellular-automata-review.zip">Download ZIP</a></nav></header>'+body+'<footer>8 October 2026 · Eight current canonical halls in spine order. Full code retained. Historical receipts, no new runtime or headset certification. Original manuscripts preserved in sources/.</footer></body></html>'
def render(text,prefix):
 soup=BeautifulSoup(markdown.markdown(text,extensions=['fenced_code','tables','footnotes']),'html.parser')
 bodies=re.findall(r'```[^\n]*\n(.*?)\n```',text,re.S);tags=soup.select('pre > code');assert len(tags)==len(bodies)
 for tag,body in zip(tags,bodies):tag.string=body+'\n'
 for tag in soup.find_all(re.compile('^h[1-5]$')):tag.name='h'+str(int(tag.name[1])+1)
 for tag in soup.find_all(id=True):tag['id']=prefix+'-'+tag['id']
 for a in soup.find_all('a',href=True):
  if a['href'].startswith('#'):a['href']='#'+prefix+'-'+a['href'][1:]
 return str(soup)
def toc(page_name):return '<ol class="toc">'+''.join('<li><a href="'+page_name+'#'+h['id']+'">'+escape(h['label'])+'</a></li>' for h in halls)+'</ol>'
def chapter_nav(i):
 return '<div class="chapter-nav">'+('<a href="#'+order[i-1]+'">← Previous hall</a>' if i else '<span></span>')+('<a href="#'+order[i+1]+'">Next hall →</a>' if i<7 else '<a href="review.html">Reviewer brief →</a>')+'</div>'
for track in ['tutorial','final']:
 title='Cellular Automata — complete '+('tutorial' if track=='tutorial' else 'reflective sequence')
 body='<main><p class="eyebrow">Endless Museum · eight halls · '+track+'.md</p><h1>'+escape(title)+'</h1><p>All eight current manuscripts, unabridged and in spine order.</p>'+toc('')+'<p><a href="ca-'+track+'.md">Download the whole reading as Markdown</a></p>'
 combined=['# '+title+'\n\n8 October 2026. All eight current canonical manuscripts, unabridged. Full code retained. Image paths and footnote identifiers are made portable; original sources are included.\n\n']
 combined.append('## Contents\n\n'+''.join('- ['+h['label']+'](#'+h['id']+')\n' for h in halls))
 for i,h in enumerate(halls):
  hall=h['id'];text=texts[(hall,track)]
  body+='<section class="chapter" id="'+hall+'"><p class="chapter-number">'+f'{i+1:02d} / 08 · '+hall+'</p>'+render(text,hall+'-'+track)+chapter_nav(i)+'</section>'
  shifted=outside_code(text,lambda s:re.sub(r'^(#{1,5}) ',r'#\1 ',s,flags=re.M))
  combined.append('\n\n---\n\n<a id="'+hall+'"></a>\n\n**'+f'{i+1:02d} / 08 · '+hall+'**\n\n'+shifted.rstrip()+'\n')
 write(O/(track+'.html'),page(title,body+'</main>'));write(O/('ca-'+track+'.md'),''.join(combined))
pair='<main class="paired"><p class="eyebrow">Two complete tracks</p><h1>What a cell keeps.<br>What a body meets.</h1><p>Tutorial on the left; reflective final.md on the right. Each pair starts at the same hall. Both texts remain complete.</p>'+toc('')
for i,h in enumerate(halls):
 hall=h['id'];pair+='<section class="chapter" id="'+hall+'"><p class="chapter-number">'+f'{i+1:02d} / 08 · '+hall+'</p><div class="pair"><article><p class="eyebrow">Tutorial · reconstruct</p>'+render(texts[(hall,'tutorial')],hall+'-tutorial')+'</article><article><p class="eyebrow">Final · reflect</p>'+render(texts[(hall,'final')],hall+'-final')+'</article></div>'+chapter_nav(i)+'</section>'
write(O/'parallel.html',page('Cellular Automata — parallel readings',pair+'</main>'))
brief='''# Review the complete Cellular Automata sequence

You are the ghost student: an imagined future reader learning to make things inside Endless Museum. Programming can remain a practice of pleasure, attention and judgment even as its professional conditions change. Read the work closely enough to discover where you could act, where you must guess, and where an explanation loses you. You are allowed to remain uncertain; distinguish that uncertainty from a defect you can demonstrate.

## What you are reviewing

Read the eight complete tutorials and eight complete reflections. `tutorial.md` carries the context, full runnable code, explanation, predictions and independent variations. `final.md` carries the reflective encounter. The museum contains more artifacts than either track teaches; an unexamined companion is not automatically an omission.

The setting is the existing Endless Museum. Day Zero already supplies Godot, the player, camera, lighting and XR Tools. Each tutorial reconstructs a small study within that supplied world, following a working installed artifact. These nineteen files are not a standalone Godot project. The student is not expected to rebuild the museum infrastructure. Each hall states the difference between its compact reconstruction and the fuller installed interaction.

The same PointBody class is carried throughout. Its role changes: inspect an address, carry STEP, inspect history, supply a position, place a seed, compare procedures, select a volume section. All eight copies of that class are byte-identical in this package. The changing role must be explained by the lesson around it; familiar appearance alone is not enough.

The stable map IDs are historical. Follow the lesson titles: CA_GameOfLife teaches a Rule 30 history; Conway's two-dimensional Life comes in CA_BeyondBinary. CA_AgentsCircuits compares Rule 90 with recursive placement; it is not a Wireworld lesson. CA_EdgeOfChaos investigates matched fields and display gain; its title is not evidence of chaotic amplification. The sequence JSON is included to establish order, not to endorse every inherited descriptive field as the present lesson contract.

## The progression to inspect

1. **A row with neighbours:** a rule reads old state and produces next state. An address persists while its Boolean value changes.
2. **A state that lingers:** a volume gives each cell empty, active or fading state. Presence and contribution to a neighbour count separate.
3. **Keep a generation:** independent rows become a history. The same record can be an image or physical support.
4. **A pattern visits an address:** both array dimensions now describe space in a present. A pattern moves through fixed addresses; a lamp reads one without feeding back.
5. **The surface includes you:** an external position enters the calculation. Numeric state, thresholds and update order affect what can recover or support a body.
6. **What a neighbour offers:** two concentrations and neighbour differences replace the earlier thresholded neighbour contribution. Matched fields isolate the effect of exchange.
7. **Two ways to make:** local updates and an explicit copying recipe can produce related outlines. A seed edit distinguishes their procedures.
8. **What a difference keeps:** almost identical beginnings follow one procedure. Storage, spatial section, thresholded measurement and image gain can each alter what a difference appears to be.

This is the lineage being proposed, not a verdict that every transition already works.

## Revision after the first complete-sequence assessment

The required eight lessons and nineteen code files remain. The middle reflections now leave more room for the encounter before its explanation. Expanding Space adds a route to attempt while the installed field is running. The final tutorial offers an optional composition: return to an earlier operation, follow a question that emerges, and establish what the resulting construction actually does. Trace provides one starting point, recording each committed input including repeated positions and absence. The student's choice remains open.

Read `review-notes/index.html` for the response and before/after passages. An author-made recorder/replayer passed thirteen fresh native checks, including 6,400 cell values across eighty updates. This tests one possible response to the optional task; it is not a ninth required lesson or an independent ghost-student result. Assess whether the invitation allows a question beyond the prescribed comparisons. The wider comparison of dynamical regimes remains a proposal; the final hall does not establish a transition into chaos.

## Questions for the reviewer

- Can you identify one main new operation in each lesson, what it reuses, and what you can carry onward? Where is a difficulty increase insufficiently prepared?
- Can you reconstruct the current study from the stated host and printed files without inventing a child node, variable, helper or dependency? Separate unfamiliar supplied support from missing essential work.
- Does the explanation make the code's order and data ownership understandable? In particular: old versus next, current versus history, space versus time, periodic versus finite boundaries, input versus display.
- Can you predict an outcome and complete the independent edit for each hall? Report the exact first place where copying succeeds but understanding does not.
- Does the point's changed role remain legible? Is returning to Rule 90 in hall seven useful consolidation, or does it need a clearer reason?
- Where does full-code repetition help reconstruction, and where does it overwhelm the text? Suggest layout or explicit reuse before removing a required dependency.
- Does the reflection add a question that the runnable construction makes tangible? Identify repeated controls, overexplained mechanisms, unsupported historical associations or claims stronger than the experiment.
- Which one transition most needs revision? Prefer a small, specific repair grounded in the existing museum over a new curriculum or an additional collection of artifacts.

## What has and has not been verified

Each hall includes previously recorded native Godot learner and museum checks. The compiler verifies that all nineteen current printed files still match the recorded tested files and their saved hashes. It also checks sixteen source snapshots, exact code in the combined Markdown and rendered HTML, local images, navigation and footnotes.

This compilation does not rerun the simulations. Museum checks include cameras, controls and spatial routes, so their counts are not independent teaching outcomes. The opening has a later layout receipt as well as its original interaction receipt. Do not add these counts into a claim that the whole student journey has been tested end to end.

Physical headset comfort, Quest performance, full inter-hall passage and independent student understanding are not established by these receipts. The dense 50-cubed installed volume in hall two has a recorded update-cost concern; the compact learner reconstruction is a different scale. Some secondary labels and blank frames remain visual follow-ups. The new reviewer should report what they inspected or ran and what remains inferred.

## Return a useful review

Begin with a short judgment of the sequence's progression. Then list the most consequential problems with hall, passage or function, what you expected, what happened or remained unclear, and the smallest proposed repair. Separate executable defects, missing prerequisites, teaching load, reflective claims and editorial preference. Include strengths worth preserving. Do not claim to have run code if you only read it.

Read the two tracks separately once, then use the parallel view for local comparison. The aim is a chapter that builds capacity while leaving room for the museum's larger inquiry.
'''
write(O/'REVIEW_BRIEF.md',brief);write(O/'review.html',page('Cellular Automata — reviewer brief','<main>'+render(brief,'review')+'</main>'))
rows=''.join('<tr><td><a href="parallel.html#'+h['id']+'">'+f'{h["number"]:02d} · '+escape(h['label'])+'</a></td><td>'+escape(h['operation'])+'</td><td>'+escape(h['point_role'])+'</td></tr>' for h in halls)
cards=''
for h in halls:
 cards+='<section class="hall-card"><p class="chapter-number">'+f'{h["number"]:02d} / 08 · '+h['id']+'</p><h2>'+escape(h['label'])+'</h2><p>'+escape(h['question'])+'</p><figure><a href="'+h['image']+'"><img src="'+h['image']+'" loading="lazy" alt="'+escape(h['label'],quote=True)+' — native museum view"></a><figcaption>Existing native museum capture from this hall. <a href="parallel.html#'+h['id']+'">Read both full texts →</a></figcaption></figure><details><summary>See the room from above</summary><figure><a href="'+h['overhead']+'"><img src="'+h['overhead']+'" loading="lazy" alt="'+h['id']+' — overhead room layout"></a><figcaption>Previously captured overhead view; included for spatial review.</figcaption></figure></details></section>'
evidence_rows=''
for e,h in zip(evidence,halls):
 evidence_rows+='<tr><td>'+escape(h['label'])+'</td><td>'+'<br>'.join('<a href="'+x['receipt']+'">'+escape(x['scope'])+': '+str(x['checks'])+' passed</a>' for x in e['runs'])+'</td></tr>'
stats=f'<p class="meta">Eight halls · sixteen complete manuscripts · nineteen code files<br>Tutorial: approximately {totals["tutorial"]["prose_words_approx"]:,} prose words + {totals["tutorial"]["code_lines"]:,} code lines · Reflection: approximately {totals["final"]["prose_words_approx"]:,} prose words</p>'
body='<main><p class="eyebrow">Endless Museum · complete Cellular Automata sequence</p><h1>A state, a history,<br>a body in the rule.</h1><p class="lead">Eight halls. Two full readings. From a row with neighbours to a comparison of what one difference can keep.</p><div class="downloads"><a href="tutorial.html">Full tutorial</a><a href="final.html">Full reflection</a><a href="cellular-automata-review.zip">Review ZIP</a></div>'+stats+'<p><a href="parallel.html">Tutorial left · reflection right</a> · <a href="ca-tutorial.md">Tutorial Markdown</a> · <a href="ca-final.md">Reflection Markdown</a></p><p class="note">For your reviewer: start with <a href="review.html">the brief</a>. The texts and code are complete; the environment is the existing Endless Museum. This export preserves the canonical writing.</p><h2>The proposed progression</h2><table class="review-table"><thead><tr><th>Hall</th><th>What is added</th><th>The point returns</th></tr></thead><tbody>'+rows+'</tbody></table><h2>The halls</h2>'+cards+'<section id="evidence"><h2>Included evidence</h2><p>Previously recorded native runs, with current printed-code hashes checked. These are scoped receipts, not a fresh whole-sequence or headset test.</p><table><thead><tr><th>Hall</th><th>Receipts</th></tr></thead><tbody>'+evidence_rows+'</tbody></table></section><p><a href="manifest.json">Sources, code and image hashes</a> · <a href="validation.json">Compilation checks</a> · <a href="REVIEW_BRIEF.md">Reviewer brief Markdown</a></p></main>'
write(O/'index.html',page('Cellular Automata — complete review readings',body))
shutil.copytree(REVISION,O/'review-notes',dirs_exist_ok=True)
revision=json.loads(read(REVISION/'evidence.json'))
assert revision['required_code_files_unchanged']==19 and revision['fresh_optional_checks']==13
index=read(O/'index.html').replace('<h2>The proposed progression</h2>','<p class="note"><a href="review-notes/index.html">Feedback revision: a question to follow</a> — six revised manuscripts, an optional return to Trace, and thirteen fresh checks of one author-made response. <a href="review-notes/changes.html">Before / after</a>.</p><h2>The proposed progression</h2>')
write(O/'index.html',index)
readme='''# Cellular Automata — complete review package

Open index.html after extracting this ZIP. Start the review with REVIEW_BRIEF.md or review.html.

- tutorial.html and ca-tutorial.md: all eight tutorials with all code.
- final.html and ca-final.md: all eight reflective texts.
- parallel.html: tutorial left, reflection right, hall by hall.
- assets/: manuscript images and overhead views, copied from existing native captures.
- sources/: sixteen untouched canonical manuscripts, active sequence JSON and current lesson contracts. Raw image paths in these snapshots remain original; use the compiled readings for portable images.
- student-files/: nineteen exact printed code files in separate hall folders. All eight PointBody copies are identical. Follow each tutorial inside the prepared Endless Museum workspace with Godot XR Tools and the existing player, camera and lighting. This ZIP is a review package, not a standalone Godot project.
- evidence/: previously recorded learner/museum checks and logs, plus the opening's later layout run. No simulations were rerun for this export. Counts include different kinds of assertions and must not be treated as an end-to-end student score.
- review-notes/: response to the supplied assessment, before/after manuscripts, source diffs, and an optional recorder/replayer with thirteen fresh native checks. These new checks concern one author-made composition, not the required lessons or an independent student.
- manifest.json and validation.json: file hashes, source parity, code parity, link checks and ZIP validation.

All eight halls follow the current spine. Use the lesson titles rather than interpreting the historical map IDs as syllabus descriptions. Compiled footnotes are namespaced and image paths local; original prose and code remain unabridged. External source links still require internet access.
'''
write(O/'README.md',readme)
# Validate the assembled and rendered code, not just the snapshots.
expected=[read(O/p['copy']).rstrip('\n') for p in printed]
combined=re.findall(r'```[^\n]*\n(.*?)\n```',read(O/'ca-tutorial.md'),re.S);assert combined==expected
for name in ['tutorial.html','parallel.html']:
 actual=[tag.get_text().rstrip('\n') for tag in BeautifulSoup(read(O/name),'html.parser').select('pre > code')];assert actual==expected,name
assert not BeautifulSoup(read(O/'final.html'),'html.parser').select('pre > code')
for source in sources:assert sha(R/source['path'])==source['sha256']==sha(O/source['copy'])
assert sha(SEQ)==sha(O/'sources/cellularautomata.json')
manifest={'date':'2026-10-08','sequence':'cellularautomata','order':order,'sequence_sha256':sha(SEQ),'halls':halls,'sources':sources,'student_files':printed,'assets':assets,'totals':totals,'previously_recorded_evidence':evidence,'all_point_body_copies_identical':True,'canonical_sources_modified':False,'runtime_tests_rerun_for_compilation':False}
manifest['editorial_revision']=revision
dump(O/'manifest.json',manifest)
# Placeholder allows link validation to include the receipt itself.
dump(O/'validation.json',{'status':'checking'})
archive=O/'cellular-automata-review.zip'
def pack():
 with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
  for p in sorted(O.rglob('*')):
   if p.is_file() and p!=archive:
    name=p.relative_to(O).as_posix()
    if p.suffix=='.html':z.writestr(name,read(p).replace('href="cellular-automata-review.zip"','href="README.md"').replace('>Download ZIP</a>','>Package README</a>').replace('>Review ZIP</a>','>Package README</a>'))
    else:z.write(p,name)
pack()
links=0;chapters=0;pages={p:BeautifulSoup(read(p),'html.parser') for p in O.rglob('*.html')}
for p,soup in pages.items():
 ids=[t['id'] for t in soup.find_all(id=True)];assert len(ids)==len(set(ids)),p
 for tag in soup.find_all(['a','img','link']):
  url=tag.get('href') or tag.get('src')
  if not url:continue
  u=urlsplit(url)
  if u.scheme or u.netloc:continue
  dest=(p.parent/unquote(u.path)).resolve() if u.path else p
  assert dest.is_relative_to(O) and dest.is_file(),(p,url)
  if u.fragment and dest.suffix=='.html':assert pages[dest].find(id=unquote(u.fragment)),(p,url)
  links+=1
 if p.parent==O and p.name in ['tutorial.html','final.html','parallel.html']:
  assert [t['id'] for t in soup.select('section.chapter')]==order;chapters+=8
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None
 for source in sources:assert hashlib.sha256(z.read(source['copy'])).hexdigest()==source['sha256']
 for name in [n for n in z.namelist() if n.endswith('.html')]:
  soup=BeautifulSoup(z.read(name).decode('utf-8'),'html.parser')
  for tag in soup.find_all(['a','img','link']):
   url=tag.get('href') or tag.get('src')
   if not url:continue
   u=urlsplit(url)
   if u.scheme or u.netloc or not u.path:continue
   assert posixpath.normpath(posixpath.join(posixpath.dirname(name),unquote(u.path))) in z.namelist(),(name,url)
dump(O/'validation.json',{'canonical_manuscripts_match_snapshots':16,'printed_files_match_studies_and_prior_tested_files':19,'point_body_copies_identical':8,'combined_code_blocks_exact':19,'rendered_code_blocks_exact_in_each_reading':19,'chapter_sections_in_spine_order':chapters,'local_links_and_anchors_checked':links,'assets':len(assets),'duplicate_html_ids':0,'zip_integrity':'passed','zip_internal_links':'passed','canonical_sources_modified':False,'runtime_tests_rerun':False,'browser_render_checked':False})
pack()
print(json.dumps({'output':str(O),'manuscripts':len(sources),'code_files':len(printed),'assets':len(assets),'links':links,'totals':totals,'zip_mb':round(archive.stat().st_size/1024**2,2)},indent=2))
