from pathlib import Path
import difflib,hashlib,html,json,re,shutil
import markdown
r=Path.cwd();o=Path(__file__).resolve().parent;rel=o.relative_to(r).as_posix()
maps=['CA_ExpandingSpace','CA_SoftRules'];checks=[]
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf-8'))
def H(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def check(name,passed):checks.append({'name':name,'passed':bool(passed)});assert passed,name
base=read(o/'baseline.json');owned=read(o/'changed-files.json')
for path,sha in base.items():
 if path not in owned+['commons/data/museum_core_encounters.json','doc/tasks/book_cellularautomata.json']:
  check('preserved '+path,H(r/path)==sha)
for m in maps:
 a=(o/'before/commons/maps'/m/'final.md').read_text();b=(r/'commons/maps'/m/'final.md').read_text()
 check(m+': all code excerpts retained',re.findall(r'```.*?```',a,re.S)==re.findall(r'```.*?```',b,re.S))
 check(m+': all encounter anchors retained',re.findall(r'<!--.*?-->',a)==re.findall(r'<!--.*?-->',b))
 check(m+': footnotes retained',re.findall(r'^\[\^.*$',a,re.M)==re.findall(r'^\[\^.*$',b,re.M))
 if m=='CA_ExpandingSpace':start='Look up to find W again.';end="The bridge's variable"
 else:start='Between the displays, a small floor mark';end='<!-- @the_clockmaker_of_rules -->'
 check(m+': new bodily encounter preserved',a[a.index(start):a.index(end)]==b[b.index(start):b.index(end)])
native=[];warnings=[]
for tag in ['bridge-before','bridge-after','exchange-current']:
 d=read(o/tag/'report.json');log=(o/tag/'stdout.log').read_text(errors='replace')
 check(tag+': all native assertions pass',d['passed'] and not d['failures'])
 check(tag+': process exits zero',read(o/tag/'process.json')['exit_code']==0)
 check(tag+': no script or shader errors','SCRIPT ERROR' not in log and 'SHADER ERROR' not in log)
 if tag!='bridge-before':native+=d['checks']
 warnings.extend(line for line in log.splitlines() if 'ERROR:' in line or 'WARNING:' in line)
write(o/'engine-warnings.json',json.dumps(list(dict.fromkeys(warnings)),indent=2)+'\n')
prior=read(r/'doc/book/iterations/2026-09-25-ca-seed-crossing/source-manifest.json')
exchange_paths=[p for p in prior if p.startswith('commons/artifacts/rd_artifact/')]
check('earlier seed-crossing runtime implementation still current',all(H(r/p)==prior[p]['after'] for p in exchange_paths))
prior_bridge=read(r/'doc/book/iterations/2026-09-25-ca-presence/source-manifest.json')
check('earlier bridge solver still current',H(r/'algorithms/cellularautomata/living_architecture/decaying_bridge.gd')==prior_bridge['algorithms/cellularautomata/living_architecture/decaying_bridge.gd']['after'])
capture=r/'doc/book/captures/cellularautomata/cellularautomata-book.md'
manifest=read(capture.with_suffix('.manifest.json'))
check('all eight chapters in capture match current sources',len(manifest['maps'])==8 and all(H(r/item['path'])==item['sha256'] for item in manifest['maps']))
check('capture hash matches',H(capture)==manifest['output_sha256'])
shutil.copy2(capture,o/capture.name)
corepath=r/'commons/data/museum_core_encounters.json';core=read(corepath);prior_core=json.loads(json.dumps(core))
write(o/'core-before-update.json',json.dumps(prior_core,ensure_ascii=False,indent=2)+'\n')
for m in maps:core['rooms'][m].update(text_sha256=H(r/'commons/maps'/m/'final.md'),map_sha256=H(r/'commons/maps'/m/'map_data.json'),local_review=rel+'/index.html')
write(corepath,json.dumps(core,ensure_ascii=False,indent=2)+'\n')
allowed={'text_sha256','map_sha256','local_review'}
for m in maps:check(m+': artifact roles and acceptance status retained',{k:v for k,v in prior_core['rooms'][m].items() if k not in allowed}=={k:v for k,v in core['rooms'][m].items() if k not in allowed})
check('other core records retained',all(v==prior_core['rooms'][m] for m,v in core['rooms'].items() if m not in maps))
decisions={
 'book_cellularautomata.008':{'status':'done','triage':'fix','decision':'The text now sends the reader to the small gold frame on either table and names the side desk as its readout. The native geometry is a square frame, not a cross. W starts outside the seed with V=0 in both fields; one STEP brings V only to the field with exchange. The existing body-seeding encounter and clockmaker remain word for word.'},
 'book_cellularautomata.011':{'status':'done','triage':'fix','decision':'The opening now says to press SOURCE once, read PROBE / NEAR, then press RUN. Native console signals confirm the initial VISITOR state, the single press selecting the near probe, RUN/hold and the witness losing health.'},
 'book_cellularautomata.021':{'status':'done','triage':'fix','decision':'BasinNote now points RIGHT / DESK SIDE, matching the actual recovery ramps when arriving along local +Z. BasinNote and WitnessTag are rotated toward arrival, darkened against the pale floor and enlarged. Matching native before/after photographs verify orientation and contrast; no headset legibility claim.'},
 'book_cellularautomata.022':{'status':'done','triage':'fix','decision':'Made the visible frieze backing consistently solid, like its posts. Its colour panels still share the floor materials and have no individual/state-dependent collision. A native body and body-layer rays stop at the fixed backing, including when all bridge cells are depleted. The manuscript now distinguishes the wall that remains from the tile that loses support. No solver, ramp, map placement or role changes.'},
 'book_cellularautomata.023':{'status':'open','triage':'comment','decision':'Fresh native console signals and photographs confirm that A/B initially withhold the exchange answer, EXCHANGE B reveals the actual visible EXCHANGE ON titles and resets both fields, and REPLAY retains the reveal. Kept open because the requested worn-headset readability check has not been performed. The earlier seed-crossing mouse-ray/body evidence remains linked and its implementation hashes still match.'},
 'book_cellularautomata.024':{'status':'open','triage':'comment','decision':'Kept open. The reported crack_propagation_ca cost still needs headset/Quest profiling. This focused desktop pass neither profiles that rear artifact nor changes its update rate. No performance acceptance is inferred from a passing functional test.'}}
write(o/'decisions.json',json.dumps(decisions,ensure_ascii=False,indent=2)+'\n')
notes='''# Cellular Automata — body and exchange review

25 September 2026. Two mature encounters receive four scoped repairs. The existing bridge/basin and seed crossing remain the centre of the chapters. This is an orientation and material-consistency pass, not another rewrite.

## Decisions

'''+ '\n\n'.join('### '+k+'\n\n'+d['decision'] for k,d in decisions.items())+'''

## Reading

The revised openings give the reader the missing physical reference: which control nominates the probe, and where W can be found. The exchange paragraph no longer says that two fractions replace one bit immediately after a hall whose cells already hold fractions. It instead follows the actual distinction: a neighbour contributes by how much its concentration differs. All code excerpts, references, encounter anchors and newer bodily passages remain.

The wall decision strengthens the comparison already in the text. Colour is shared; support is not. The bridge's threshold still governs its tiles, while the fixed frieze backing now stops a body at every health. The added collider follows the visible 0.08 × 1.95 × 9.6 m backing exactly. It does not span the ends, alter the ramps or change the bridge rule.

## Evidence and limits

36 final native assertions pass (21 bridge, 15 exchange); the baseline bridge run passes 14. The isolated native museum supplies the photographs, control callbacks, physics rays and CharacterBody collision test. The controls are invoked by their real button signals, not a tracked hand or ray in this pass. Native processes exit zero without GDScript or shader errors. Existing environment, UID, registry and material warnings remain in engine-warnings.json.

The earlier ca-presence pass provides the fuller bridge approach/drop/ramp and schedule checks; its solver is unchanged, but its photograph/test run predates this fixed wall collider. The ca-seed-crossing implementation hashes still match its earlier 49 assertions and eight mouse-ray events. That evidence is linked rather than represented as another run here. No new learner acceptance, continuous route test, headset legibility or Quest profiling is claimed.

The bridge before/after views use the same camera. The exchange before/after images show two stages of the existing discovery, not an implementation change. Images are original native PNGs. The table letter A still faces the far side in the close photograph; this pass leaves the exchange staging untouched and keeps headset readability open.

## Preservation

Both map_data.json files, artifact roles, all companion manuscripts, two numerical solvers, reaction parameters, eight controls per study, body receivers, ramps, museum plan, sequence order and book metadata remain. Canonical final.md files and the current eight-hall capture are refreshed. Only these two core records' digests/review links and the six specified queue review fields are updated; original comments and notes are preserved. No commit.

Next: Agents/Circuits and Edge of Chaos, following the active sequence and preserving concurrent immersive work.
'''
write(o/'DECISIONS.md',notes)
for path in owned:
 a=(o/'before'/path).read_text();b=(r/path).read_text()
 name=Path(path).parent.name if path.endswith('final.md') else Path(path).stem
 write(o/(name+'.diff'),''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+path,tofile=path)))
 if path.endswith('final.md'):write(o/(name+'-before.md'),a);write(o/(name+'-after.md'),b)
write(o/'source-manifest.json',json.dumps({p:{'before':base[p],'after':H(r/p)} for p in base if p not in ['commons/data/museum_core_encounters.json','doc/tasks/book_cellularautomata.json']},indent=2)+'\n')
write(o/'verification.json',json.dumps({'checks':checks,'native_checks':len(native),'native_failures':[],'headset_verified':False,'quest_profiled':False},indent=2)+'\n')

def fig(path,caption):return f'<figure><a href="{path}"><img loading="lazy" src="{path}" alt="{html.escape(caption)}"></a><figcaption>{caption}</figcaption></figure>'
def md(s):return markdown.markdown(s,extensions=['fenced_code','footnotes','tables'])
def reading(m):
 s=(r/'commons/maps'/m/'final.md').read_text()
 for imagepath in re.findall(r'!\[[^\]]*\]\(([^)]+)\)',s):
  source=r/'commons/maps'/m/imagepath;dest=o/'chapter-images'/m/imagepath
  dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,dest);s=s.replace('('+imagepath+')','('+dest.relative_to(o).as_posix()+')')
 body=md(s)
 body=re.sub(r'(id|href)="(#?)(fn[^\"]*)"',lambda x:x[1]+'="'+x[2]+m+'-'+x[3]+'"',body)
 return body
def diffrows(m):
 before=(o/(m+'-before.md')).read_text().split('\n\n');after=(o/(m+'-after.md')).read_text().split('\n\n');rows=[]
 for op,a,b,c,d in difflib.SequenceMatcher(None,before,after).get_opcodes():
  if op!='equal':rows.append('<tr><td>'+md('\n\n'.join(before[a:b]))+'</td><td>'+md('\n\n'.join(after[c:d]))+'</td></tr>')
 return '<table><thead><tr><th>Before</th><th>Now in final.md</th></tr></thead><tbody>'+''.join(rows)+'</tbody></table>'
page='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Body and exchange — CA review</title><style>
:root{color-scheme:light;--paper:#f5f1e9;--ink:#243938;--accent:#85653b}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:18px/1.6 Georgia,serif}header{background:#153137;color:#faf5e8;padding:54px max(5vw,24px)}header p{max-width:760px}h1{font-size:clamp(2rem,4vw,3.5rem);line-height:1.1;font-weight:normal}h2{font-weight:normal;font-size:2rem}h3{font-weight:normal}a{color:inherit;text-underline-offset:4px}nav{display:flex;flex-wrap:wrap;gap:20px;font:15px/1.5 system-ui;margin-top:24px}.eyebrow{font:12px/1.5 system-ui;letter-spacing:.13em;text-transform:uppercase}main{max-width:1260px;margin:auto;padding:24px}section{padding:35px 0;border-bottom:1px solid #cfc7b7}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}figure{margin:18px 0}img{display:block;width:100%;height:auto;background:#153137}figcaption{font:14px/1.55 system-ui;padding:10px 0;color:#52615e}table{border-collapse:collapse;width:100%;font-size:17px}td,th{width:50%;vertical-align:top;text-align:left;border:1px solid #ccc3b4;padding:18px}th{font:13px system-ui;text-transform:uppercase}td:first-child{background:#eae4da}td:last-child{background:#e6eee7}.reading{max-width:760px;margin:auto}.reading p{margin:1.3em 0}.reading img{max-width:100%}pre{overflow:auto;font:13px/1.6 monospace;padding:18px;background:#e5e8e2}code{font-size:.85em}details{margin:24px 0}summary{cursor:pointer;font:16px system-ui}.note{max-width:800px;font:16px/1.65 system-ui}.footnote{font-size:15px}@media(max-width:720px){.pair{grid-template-columns:1fr}td,th{padding:9px}table{font-size:15px}}
</style></head><body><header><div class="eyebrow">Cellular automata · 25 September 2026 · Review comments</div><h1>The body and the exchange</h1><p>The wall keeps its answer. The floor can stop carrying you. In the next room, a little concentration arrives where there was none.</p><nav><a href="#space">The surface includes you</a><a href="#exchange">What can a cell receive?</a><a href="#reading">Read both chapters</a><a href="#evidence">Decisions &amp; checks</a></nav></header><main>
<section><p class="note">Four comments resolved. Two remain open for headset readability and performance. The existing bridge and seed-crossing encounters stay intact; these are small repairs to orientation, wording and the wall’s physical presence.</p></section>
<section id="space"><h2>The surface includes you</h2><p>The ramp directions now face the arriving visitor and agree with the actual right-hand route. SOURCE takes one press. The wall has a fixed backing, while the tiles can lose support.</p><div class="pair">'''
page+=fig('bridge-before/arrival-directions.png','Before: a pale, inverted instruction says LEFT.')+fig('bridge-after/arrival-directions.png','After: upright directions point RIGHT / DESK SIDE. Same native camera.')+'</div>'
page+=diffrows('CA_ExpandingSpace')+'<p><a href="CA_ExpandingSpace.diff">Exact chapter diff</a> · <a href="proximity_study.diff">Scene code diff</a></p></section>'
page+='<section id="exchange"><h2>What can a cell receive?</h2><p>W is the small gold frame on a table. Its values are read at the desk. The seed crossing remains an event the body can introduce into the field.</p>'
page+=fig('exchange-current/table-witness.png','The gold frame sits just outside the seed. This is W; the desk reports its U and V.')+diffrows('CA_SoftRules')
page+='<div class="pair">'+fig('exchange-current/exchange-before-naming.png','Before intervention: A and B leave the difference unnamed.')+fig('exchange-current/exchange-after-naming.png','After EXCHANGE B: both visible titles disclose exchange. These are stages of the existing encounter, not a new label system.')+'</div><p><a href="CA_SoftRules.diff">Exact chapter diff</a></p></section>'
page+='<section id="reading"><div class="reading"><div class="eyebrow">Current final.md · both chapters</div>'+''.join('<article id="'+m+'">'+reading(m)+'</article>' for m in maps)+'</div></section>'
page+='<section id="evidence"><h2>Decisions and evidence</h2><p class="note">36 final native assertions pass. The new fixed wall stops the actual museum CharacterBody. Console signals confirm source selection and the exchange reveal. These checks do not certify headset reach, readability or Quest performance.</p><p><a href="DECISIONS.md">Decisions and limits</a> · <a href="verification.json">Preservation checks</a> · <a href="source-manifest.json">Source hashes</a> · <a href="engine-warnings.json">Engine warnings</a> · <a href="cellularautomata-book.md">Current eight-hall capture</a></p><p><a href="bridge-after/report.json">Bridge runtime report</a> · <a href="exchange-current/report.json">Exchange runtime report</a> · <a href="/book-tasks/review?seq=cellularautomata">Review queue</a></p><p>Earlier immersive evidence: <a href="../2026-09-25-ca-presence/index.html">bridge, drop and recovery</a> · <a href="../2026-09-25-ca-seed-crossing/index.html">body entry and seed dispersal</a>.</p><details><summary>Read the full decisions here</summary>'+md(notes)+'</details></section></main></body></html>'
write(o/'index.html',page)
print(json.dumps({'preservation_checks':len(checks),'native_checks':len(native),'review':rel+'/index.html'}))
