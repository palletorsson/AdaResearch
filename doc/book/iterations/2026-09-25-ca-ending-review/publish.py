from pathlib import Path
import difflib,hashlib,html,json,re,shutil
import markdown
r=Path.cwd();o=Path(__file__).resolve().parent;rel=o.relative_to(r).as_posix()
maps=['CA_AgentsCircuits','CA_EdgeOfChaos'];checks=[]
def H(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf-8'))
def check(name,ok):checks.append({'name':name,'passed':bool(ok)});assert ok,name
base=read(o/'baseline.json');owned=read(o/'changed-files.json');concurrent=read(o/'concurrent-immersion.json')
for path,h in base.items():
 if path in concurrent:check('concurrent immersion retained '+path,H(r/path)==concurrent[path])
 elif path not in owned+['commons/data/museum_core_encounters.json','doc/tasks/book_cellularautomata.json']:check('preserved '+path,H(r/path)==h)
for m in maps:
 a=(o/'before/commons/maps'/m/'final.md').read_text();b=(r/'commons/maps'/m/'final.md').read_text()
 check(m+': code excerpts preserved',re.findall(r'```.*?```',a,re.S)==re.findall(r'```.*?```',b,re.S))
 check(m+': anchors preserved',re.findall(r'<!--.*?-->',a)==re.findall(r'<!--.*?-->',b))
 check(m+': footnote identities preserved',re.findall(r'^\[\^([^]]+)\]:',a,re.M)==re.findall(r'^\[\^([^]]+)\]:',b,re.M))
 if m=='CA_AgentsCircuits':
  start='Choose one triangular gap';end='<!-- @sierpinski_pyramid -->'
  check('new floor encounter and figure kept verbatim',a[a.index(start):a.index(end)]==b[b.index(start):b.index(end)])
 else:check('existing handover to Fractals already correct and retained',a[a.index('The next hall,'):a.index('[^ca-edge]:')]==b[b.index('The next hall,'):b.index('[^ca-edge]:')])
oldcritical=(o/'before/commons/maps/CA_AgentsCircuits/critical.md').read_text();archive=(r/'commons/maps/CA_AgentsCircuits/wireworld-proposal.md').read_text()
check('old critical essay retained verbatim',oldcritical in archive)
check('earlier Wireworld proposal retained in full',archive.startswith((o/'before/commons/maps/CA_AgentsCircuits/wireworld-proposal.md').read_text()))
rp='commons/artifacts/registry/commons_artifacts.json';a=read(o/'before'/rp);b=read(r/rp)
for k in ['description','qfep_connection']:a['artifacts']['ca_rule_explorer'][k]=b['artifacts']['ca_rule_explorer'][k]
check('registry changes only the two scoped description fields',a==b)
native=[];warnings=[]
for tag in ['agents-reading','edge-with-walking-slice']:
 d=read(o/tag/'report.json');log=(o/tag/'stdout.log').read_text(errors='replace')
 check(tag+': all native assertions pass',d['passed'] and not d['failures']);native+=d['checks']
 check(tag+': owned process exits zero',read(o/tag/'process.json')['exit_code']==0)
 check(tag+': no script/shader errors','SCRIPT ERROR' not in log and 'SHADER ERROR' not in log)
 warnings += [line for line in log.splitlines() if 'WARNING:' in line or 'ERROR:' in line]
write(o/'engine-warnings.json',json.dumps(list(dict.fromkeys(warnings)),indent=2)+'\n')
check('initial exact-address pier hypothesis failed',read(o/'edge-before/report.json')['observations']['changed_address_colliders']==[])
check('whole-volume pier hypothesis also failed',read(o/'edge-before-volume/report.json')['observations']['volume_region_colliders']==[])
check('no live plan rewrite was made',H(r/'ada_run/em_plan.json')==base['ada_run/em_plan.json'])
prior=read(r/'doc/book/iterations/2026-09-25-ca-pattern-correspondence/source-manifest.json')
scripts=[p for p in prior if p.startswith('commons/artifacts/ca_rule_explorer/')]
check('earlier immersive floor implementation still current',all(H(r/p)==prior[p]['after'] for p in scripts))
walking=read(r/'doc/book/iterations/2026-09-25-ca-walking-slice/source-manifest.json')
walking_sources=[p for p in walking if p.startswith('algorithms/cellularautomata/ca_showcase/')]
check('concurrent walking-slice sources match their completed native evidence',all(H(r/p)==walking[p]['after'] for p in walking_sources))
write(o/'walking-slice-source-hashes.json',json.dumps({p:H(r/p) for p in walking_sources},indent=2)+'\n')
capture=r/'doc/book/captures/cellularautomata/cellularautomata-book.md';manifest=read(capture.with_suffix('.manifest.json'))
check('all eight captured chapters current',len(manifest['maps'])==8 and all(H(r/x['path'])==x['sha256'] for x in manifest['maps']))
check('capture hash matches',H(capture)==manifest['output_sha256']);shutil.copy2(capture,o/capture.name)
cp=r/'commons/data/museum_core_encounters.json';core=read(cp);oldcore=json.loads(json.dumps(core));write(o/'core-before-update.json',json.dumps(oldcore,ensure_ascii=False,indent=2)+'\n')
for m in maps:core['rooms'][m].update(text_sha256=H(r/'commons/maps'/m/'final.md'),map_sha256=H(r/'commons/maps'/m/'map_data.json'),local_review=rel+'/index.html')
write(cp,json.dumps(core,ensure_ascii=False,indent=2)+'\n')
allowed={'text_sha256','map_sha256','local_review'}
for m in maps:check(m+': roles and verification status retained',{k:v for k,v in oldcore['rooms'][m].items() if k not in allowed}=={k:v for k,v in core['rooms'][m].items() if k not in allowed})
check('other core records retained',all(v==oldcore['rooms'][m] for m,v in core['rooms'].items() if m not in maps))
decisions={
 'book_cellularautomata.003':{'status':'done','triage':'comment','decision':'Already corrected in the current chapter: The next hall, the first of Fractals, changes the instruction. Verified against the current opening of Fractal_Recursion and preserved this paragraph verbatim. No duplicate rewrite needed.'},
 'book_cellularautomata.006':{'status':'done','triage':'fix','decision':'The chapter now says the hall was conceived under the name Edge of Chaos, rather than implying the visitor has seen that title in the room. Langton remains a question about retaining, transmitting and changing information. Corrected the lambda footnote: non-quiescent rule-table outputs, not living cells in a field. Removed the overgeneralisation that every image filter is a cellular automaton run once; retained the concrete blur comparison and critical ending.'},
 'book_cellularautomata.019':{'status':'done','triage':'comment','decision':'The old plan row does contain 28 piers, but the current museum replaces an authored row with _derive_map_row at build time (endless_museum.gd around 8048). Native queries at the changed cell and across the full B volume find no collider; interior images agree. The old claim that a plan re-apply is required is stale. Kept both failed obstruction hypotheses as diagnostics. No live plan/bake or map rewrite was needed.'},
 'book_cellularautomata.025':{'status':'done','triage':'fix','decision':'The newer technical/intent/inventory documents already describe the installed comparison. Archived the remaining older critical essay verbatim in wireworld-proposal.md with an explicit speculative status; current critical.md follows the floor image, recursive volume, recognition, failed correspondence and bodily support. It no longer presents code as verification of philosophical theories. Corrected only the explorer registry description and QFEP connection, which had promised unimplemented custom neighbourhood tables and universal computation visible at an edge. Existing Wireworld material and both primary works remain.'}}
write(o/'decisions.json',json.dumps(decisions,ensure_ascii=False,indent=2)+'\n')
notes='''# Cellular Automata — ending review

25 September 2026. Scope: Agents/Circuits and Edge of Chaos, including their remaining source and manuscript comments. Preserve the new floor comparison and both established primary works.

## Decisions

'''+ '\n\n'.join('### '+k+'\n\n'+d['decision'] for k,d in decisions.items())+'''

## What the native run changed

The first Rule 222 assertion expected a completely filled ring. It failed: the actual 32-cell single-seed run settles with 31 occupied addresses and one dark address where the edges meet. The chapter now follows that result. The stored last rows of 190 show travelling stripes; the prose invites observation without assigning a class from a single short beginning. Rule 90 still becomes empty at update 16 for the single seed. The four-class paragraph keeps its historical reference but no longer suggests that the finite panel demonstrates universality or the next hall measures the border of a class.

The pier diagnosis also failed twice, first at the changed address and then across the visible B volume. The stored plan is stale, but runtime map derivation already supplies the open hall. A candidate row was derived for inspection and never installed. No claim that this pass removed a column or changed the space is made.

The integer/fractional experiment retains its exact result: with uniform 4, zero drive, pull .25 and a one-cell increment, one integer step erases the difference; a fractional step leaves 27 changed addresses and maximum difference .75. Z SLICE changes neither time nor state. Zero pull preserves a single difference; matched runs agree under shared forcing. The code excerpts remain unchanged.

## Critical and historical sources

The visitor prose remains an investigation of particular images, values and bodily positions. Langton's name is a research question, not a measured property of these volumes. Wolfram's classes organise behaviour across beginnings, not a ranking certified by this one finite strip. Primary references are linked in the chapter footnotes and SOURCES.md.

The earlier Wireworld essay contains ideas worth developing, but its statements that a neighbour count proves thrownness, performativity or political necessity go beyond its evidence. The complete essay remains in the proposal archive. The current critical companion keeps a queer opening in an imperfect resemblance: works can remain related without one having to reproduce the other's conditions. This is an interpretive way of meeting the works, not an algorithmic certification of queerness.

## Evidence and preservation

23 final native assertions pass (10 explorer, 13 volumes). Controls use the actual slider/button signals with supplied values; cameras are inside the isolated native museum. No tracked-hand, headset, Quest-performance, continuous-route or learner acceptance claim. Both owned final processes exit zero without script/shader errors. Existing UID, environment, registry and material warnings remain; the decorative sculpture time budget also reports that it stopped after one sculpture. These unrelated warnings are retained.

agents-current records the failed full-ring assumption. agents-final records the passing result but an unhelpful camera aimed beyond the floor. agents-reading moves only the capture camera and adds the Rule 222 close view. edge-before and edge-before-volume retain the failed stale-pier hypotheses; edge-with-walking-slice tests the observed clear volume. All images are original native PNGs. Photographs show the current encounters. Gold section markers belong to the concurrent walking-slice pass, not an obstruction repair.

This review makes no map, scene-script or rule edits. A concurrent completed pass added the opt-in walking slice to CA_EdgeOfChaos while preserving our editorial paragraphs. Its six changed existing files are identified separately in concurrent-immersion.json; its new walking reader and native evidence remain in 2026-09-25-ca-walking-slice. The combined Edge chapter diff includes that attributed encounter addition. Numerical models, artifact roles, sequence/book metadata and live plan remain. The final volume run uses the new walking-slice implementation. Both final.md files, one critical companion, its intent reference and two registry description fields change. The earlier critical essay is preserved verbatim. Current eight-hall capture and the two core review links/digests are refreshed; existing acceptance statuses remain. Four comments are closed; the five remaining comments concern headset walking, readability or profiling. No commit.

Next sequence: Fractals. Start from the current manuscripts and newer immersive artifacts, and retain the same distinction between a useful reference and a claim that the room actually demonstrates.
'''
write(o/'DECISIONS.md',notes)
write(o/'SOURCES.md','''# Primary sources checked — 25 September 2026

- [Langton, 1990](https://doi.org/10.1016/0167-2789(90)90064-V), with [paper text](https://shinyverse.org/al4ai/papers/Langton.EdgeOfChaos.pdf): section 2.1 defines the quiescent-state rule-table parameter. The abstract and introduction frame computation near transitions as a research claim.
- [Wolfram, 1984](https://doi.org/10.1016/0167-2789(84)90245-8), and his [later account of four classes](https://www.wolframscience.com/nks/p231--four-classes-of-behavior/): the role of initial conditions limits what the single-seed museum run establishes.
- [Cook, 2004](https://www.complex-systems.com/abstracts/v15_i01_a01/): Rule 110 universality is a proved mathematical result. The visible museum history is not itself that proof.

The finite ring outcomes and paired-volume numbers are checked against the running project, not inferred from these papers.
''')
for path in owned:
 a=(o/'before'/path).read_text();b=(r/path).read_text();name=Path(path).parent.name if path.endswith('final.md') else Path(path).stem
 write(o/(name+'.diff'),''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+path,tofile=path)))
 if path.endswith('final.md'):write(o/(name+'-before.md'),a);write(o/(name+'-after.md'),b)
write(o/'source-manifest.json',json.dumps({p:{'before':base[p],'after':H(r/p)} for p in base if p not in ['commons/data/museum_core_encounters.json','doc/tasks/book_cellularautomata.json']},indent=2)+'\n')
write(o/'verification.json',json.dumps({'checks':checks,'native_checks':len(native),'headset_verified':False,'quest_profiled':False},indent=2)+'\n')

def md(s):return markdown.markdown(s,extensions=['fenced_code','footnotes','tables'])
def fig(path,cap):return f'<figure><a href="{path}"><img loading="lazy" src="{path}" alt="{html.escape(cap)}"></a><figcaption>{cap}</figcaption></figure>'
def reading(m):
 s=(r/'commons/maps'/m/'final.md').read_text()
 for path in re.findall(r'!\[[^\]]*\]\(([^)]+)\)',s):
  src=r/'commons/maps'/m/path;dest=o/'chapter-images'/m/path;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dest);s=s.replace('('+path+')','('+dest.relative_to(o).as_posix()+')')
 return re.sub(r'(id|href)="(#?)(fn[^\"]*)"',lambda x:x[1]+'="'+x[2]+m+'-'+x[3]+'"',md(s))
def diff(m):
 a=(o/(m+'-before.md')).read_text().split('\n\n');b=(o/(m+'-after.md')).read_text().split('\n\n');rows=[]
 for op,i,j,k,l in difflib.SequenceMatcher(None,a,b).get_opcodes():
  if op!='equal':rows.append('<tr><td>'+html.escape('\n\n'.join(a[i:j]))+'</td><td>'+html.escape('\n\n'.join(b[k:l]))+'</td></tr>')
 return '<table><thead><tr><th>Before</th><th>Now in final.md</th></tr></thead><tbody>'+''.join(rows)+'</tbody></table>'
prior_page=(r/'doc/book/iterations/2026-09-25-ca-body-and-exchange-review/index.html').read_text();style=re.search(r'<style>(.*?)</style>',prior_page,re.S)[1]+'td{white-space:pre-wrap;overflow-wrap:anywhere}'
page='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>CA — resemblance and one difference</title><style>'+style+'</style></head><body>'
page+='''<header><div class="eyebrow">Cellular automata · ending review · 25 September 2026</div><h1>What the resemblance leaves open</h1><p>A dark address remains where the pattern meets itself. Two volumes differ by one value. The names invite us closer; the encounter gives us something to check.</p><nav><a href="#agents">The same pattern</a><a href="#edge">One difference</a><a href="#reading">Read the chapters</a><a href="#evidence">Decisions &amp; evidence</a></nav></header><main><section><p class="note">Four comments resolved. The five remaining CA comments require headset walking, readability or profiling. These edits preserve the immersive floor comparison and existing volume experiment. This review changes no artifact or museum geometry. The parallel <a href="../2026-09-25-ca-walking-slice/index.html">walking-slice pass</a> adds the new bodily encounter shown in the combined chapter.</p></section><section id="agents"><h2>The same pattern, different work</h2><p>The native test leaves one dark cell in Rule 222. The text now notices it and keeps classification open to other beginnings. The older Wireworld research survives in a clearly labelled proposal; the current critical companion follows the installed works.</p>'''
page+='<div class="pair">'+fig('agents-reading/remembered-gap.png','The existing Rule 90 history lies underfoot, between the desk and recursive construction.')+fig('agents-reading/one-dark-address.png','Rule 222 at update 35: one dark address remains in every settled row.')+'</div>'+diff('CA_AgentsCircuits')+'<p><a href="CA_AgentsCircuits.diff">Exact chapter diff</a> · <a href="critical.diff">Critical companion diff</a> · <a href="wireworld-proposal.diff">Retained research</a></p></section>'
page+='<section id="edge"><h2>How far does one difference go?</h2><p>The current museum already builds this hall without the old piers. The review’s obstruction claim was stale. The chapter keeps its measured comparison and treats “Edge of Chaos” as a question.</p>'+fig('edge-with-walking-slice/inside-comparison.png','Inside the current hall: gold frames follow the selected depth, with the difference underfoot and spatial slices ahead.')+diff('CA_EdgeOfChaos')+'<p><a href="CA_EdgeOfChaos.diff">Exact chapter diff</a> · <a href="SOURCES.md">Primary references</a></p></section>'
page+='<section id="reading"><div class="reading"><div class="eyebrow">Current final.md · both chapters</div>'+''.join('<article id="'+m+'">'+reading(m)+'</article>' for m in maps)+'</div></section>'
page+='<section id="evidence"><h2>What was checked</h2><p>23 final native checks pass. The earlier failures are kept: an expected fully occupied ring retained a dark cell; the expected pier was absent. These changed the account, not the algorithms.</p><p><a href="DECISIONS.md">Decisions and limits</a> · <a href="verification.json">Preservation checks</a> · <a href="source-manifest.json">Source hashes</a> · <a href="engine-warnings.json">Engine warnings</a> · <a href="cellularautomata-book.md">Current eight-hall capture</a></p><p><a href="agents-reading/report.json">Explorer runtime</a> · <a href="edge-with-walking-slice/report.json">Volume runtime</a> · <a href="/book-tasks/review?seq=cellularautomata">CA review queue</a> · <a href="../2026-09-25-ca-pattern-correspondence/index.html">Earlier immersive floor evidence</a> · <a href="../2026-09-25-ca-walking-slice/index.html">Concurrent walking-slice evidence</a></p><details><summary>Read the full decisions</summary>'+md(notes)+'</details></section></main></body></html>'
write(o/'index.html',page)
print(json.dumps({'preservation_checks':len(checks),'native_checks':len(native),'review':rel+'/index.html'}))
