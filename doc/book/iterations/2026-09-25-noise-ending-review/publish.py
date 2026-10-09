from pathlib import Path
import difflib, hashlib, html, json, re, shutil
import markdown
r=Path.cwd();rel='doc/book/iterations/2026-09-25-noise-ending-review';o=r/rel
maps=['Noise_Perlin_Simplex','Lab_Path']
H=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf-8'))
checks=[]
def check(name,passed):checks.append({'name':name,'passed':bool(passed)});assert passed,name
baseline=json.loads((o/'baseline.json').read_text())
changed=['algorithms/randomness/simplexnoise/SimplexNoise.gd','commons/maps/Noise_Perlin_Simplex/final.md','commons/maps/Lab_Path/final.md','commons/maps/Lab_Path/intent.md','commons/maps/Lab_Path/summary.md','commons/maps/Lab_Path/blurb.md','commons/maps/Lab_Path/map_data.json','commons/maps/sequences/noise.json']
later=['commons/data/museum_core_encounters.json','doc/tasks/book_noise.json','doc/book/captures/noise/noise-book.md','doc/book/captures/noise/noise-book.manifest.json']
for path,sha in baseline.items():
    if path not in changed+later:check('retained: '+path,H(r/path)==sha)
for m in maps:
    a=(o/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8-sig');b=(r/'commons/maps'/m/'final.md').read_text(encoding='utf-8')
    check(m+': code excerpts retained',re.findall(r'```.*?```',a,re.S)==re.findall(r'```.*?```',b,re.S))
    check(m+': encounter anchors retained',re.findall(r'<!--.*?-->',a)==re.findall(r'<!--.*?-->',b))
before=(o/'before/commons/maps/Noise_Perlin_Simplex/final.md').read_text()
after=(r/'commons/maps/Noise_Perlin_Simplex/final.md').read_text()
start='The small sheet keeps changing. A little noise'
check('blob-culture ending retained word for word',after[after.index(start):after.index('\n\n[^engine-noise]:')].strip()==before[before.index(start):].strip())
check('four main code excerpts remain',len(re.findall(r'```.*?```',after,re.S))==4)
check('arch encounter retained',before[before.index('Turn back towards the entrance.'):before.index('Matching conditions costs')]==after[after.index('Turn back towards the entrance.'):after.index('Matching conditions costs')])

# Compare the audited chapter with the live chapter frozen before this pass.
older=r/'doc/book/iterations/2026-09-24-claude-randomness-onwards/Noise_Perlin_Simplex/after.md'
shutil.copy2(older,o/'claude-audited-chapter.md')
old=older.read_text(encoding='utf-8-sig')
write(o/'claude-to-current-before-pass.diff',''.join(difflib.unified_diff(old.splitlines(True),before.splitlines(True),fromfile='Claude audited chapter',tofile='Current chapter before this pass')))
check('audited code excerpts preserved',re.findall(r'```.*?```',old,re.S)==re.findall(r'```.*?```',after,re.S))
check('audited blob-culture ending preserved',old[old.index(start):].strip()==before[before.index(start):].strip())

seqpath='commons/maps/sequences/noise.json'
seq=json.loads((r/seqpath).read_text())['sequences']['noise'];seqbefore=json.loads((o/'before'/seqpath).read_text())['sequences']['noise']
allowed={'name','truth','qfep_term','qfep_connection','formula','description','learning_objectives','content','artifact_groups','local_review_history'}
check('sequence order, unlocks, deferred maps and routing retained',{k:v for k,v in seq.items() if k not in allowed}=={k:v for k,v in seqbefore.items() if k not in allowed})
check('artifact groups change rationales only',[{k:v for k,v in g.items() if k!='rationale'} for g in seq['artifact_groups']]==[{k:v for k,v in g.items() if k!='rationale'} for g in seqbefore['artifact_groups']])
check('content lists all nine current titles',len(seq['content'])==9 and all(m in c for m,c in zip(seq['maps'],seq['content'])))
check('deferred chamber absent from active content',not any('Chamber_Noise' in c for c in seq['content']))
check('encoding repaired in revised sequence text',all(bad not in json.dumps({k:seq[k] for k in allowed if k!='local_review_history'},ensure_ascii=False) for bad in ['Î»','â€','Ã—']))
mp='commons/maps/Lab_Path/map_data.json';a=json.loads((o/'before'/mp).read_text());b=json.loads((r/mp).read_text());a['map_info']['description']=b['map_info']['description']
check('Lab Path geometry and placements unchanged',a==b)
book=json.loads((r/'commons/data/book/noise.json').read_text())
check('Lab Path stays dropped from museum/book route',next(p for p in book['pearls'] if p['map']=='Lab_Path')['drop'] is True)
check('optional coda clearly labelled',(r/'commons/maps/Lab_Path/final.md').read_text().startswith('# What has followed you out of the room?\n\n*An optional return'))
check('second CA handover removed','In the cellular-automata rooms' not in (r/'commons/maps/Lab_Path/final.md').read_text())

report=json.loads((o/'native-final/report.json').read_text());process=json.loads((o/'native-final/process.json').read_text());log=(o/'native-final/stdout.log').read_text(errors='replace')
check('all native regression assertions pass',report['passed'] and not report['failures'] and all(c['passed'] for c in report['checks']))
check('native process exits zero',process['exit_code']==0)
check('no GDScript or shader errors','SCRIPT ERROR' not in log and 'SHADER ERROR' not in log)
write(o/'engine-warnings.json',json.dumps(list(dict.fromkeys(s for s in log.splitlines() if 'ERROR:' in s or 'WARNING:' in s)),indent=2)+'\n')
native_sources={p:H(r/p) for p in baseline if p.startswith('algorithms/') or p=='commons/maps/Noise_Perlin_Simplex/map_data.json'}
write(o/'native-implementation.json',json.dumps(native_sources,indent=2)+'\n')

manifest=json.loads((r/'doc/book/captures/noise/noise-book.manifest.json').read_text())
check('all nine captured chapters current',len(manifest['maps'])==9 and all(H(r/m['path'])==m['sha256'] for m in manifest['maps']))
check('capture hash correct',H(r/'doc/book/captures/noise/noise-book.md')==manifest['output_sha256'])
shutil.copy2(r/'doc/book/captures/noise/noise-book.md',o/'noise-book.md')
check('review copy equals canonical capture',H(o/'noise-book.md')==H(r/'doc/book/captures/noise/noise-book.md'))
(o/'images').mkdir(exist_ok=True)
shutil.copy2(r/'commons/maps/Noise_Perlin_Simplex/images/noise-archways.png',o/'images/noise-archways.png')
check('chapter photograph copied unchanged',H(o/'images/noise-archways.png')==H(r/'commons/maps/Noise_Perlin_Simplex/images/noise-archways.png'))

p=r/'commons/data/museum_core_encounters.json';core=json.loads(p.read_text(encoding='utf-8-sig'))
write(o/'core-before-update.json',json.dumps(core,ensure_ascii=False,indent=2)+'\n');prior=json.loads((o/'core-before-update.json').read_text())
for m in maps:core['rooms'][m].update(text_sha256=H(r/'commons/maps'/m/'final.md'),map_sha256=H(r/'commons/maps'/m/'map_data.json'),local_review=rel+'/DECISIONS.md')
write(p,json.dumps(core,ensure_ascii=False,indent=2)+'\n')
for m in maps:
    allowed_core={'text_sha256','map_sha256','local_review'}
    check(m+': roles and verification limits retained',{k:v for k,v in core['rooms'][m].items() if k not in allowed_core}=={k:v for k,v in prior['rooms'][m].items() if k not in allowed_core})
check('other core references retained',all(v==prior['rooms'][m] for m,v in core['rooms'].items() if m not in maps))

decisions={
 'book_noise.002':{'status':'done','triage':'fix','decision':'Lab_Path now has a real H1. Its reflective question and encounter remain; the subtitle explicitly marks it as an optional return.'},
 'book_noise.003':{'status':'done','triage':'fix','decision':'VIEW leaves the seed alone. If you used REGEN, you keep that new field. The sentence now distinguishes choosing a new field from changing how its values occupy space. Native sample and generator checks support it.'},
 'book_noise.005':{'status':'done','triage':'fix','decision':'The dangling engine-docs fragment becomes a sourced footnote. The main sentence and four code excerpts remain. The linked Godot 4.6 reference distinguishes Perlin, OpenSimplex2 and OpenSimplex2S.'},
 'book_noise.006':{'status':'done','triage':'fix','decision':'Repaired encoding and updated the sequence title, purposes, descriptions and current chapter titles, with Chamber_Noise kept deferred and Lab_Path explicitly optional. The description distinguishes spatial coherence from stored state. Map order, route, unlocks, roles and artifact lists are retained.'},
 'book_noise.007':{'status':'done','triage':'fix','decision':'Keep Lab_Path outside the main museum/book route. Fold the two tellings and hold-a-seed invitation into the Perlin/Simplex ending, before the preserved blob-culture passage. The main chapter retains the one handover to Cellular Automata; the optional coda no longer repeats it.'},
 'book_noise.013':{'status':'done','triage':'comment','decision':'Compared the frozen Claude audited chapter with the live chapter before this pass. Keep the live chapter: its newer arch encounter is supported by native work, and VIEW already bypassed the obsolete seed-reset caveat. All four audited code excerpts and the blob-culture ending remain. This pass also fixes the underlying readout-only config API.'},
 'book_noise.014':{'status':'done','triage':'fix','decision':'The absence of Lab_Path from the museum is now an explicit curatorial choice. Its existing drop flag, grid, teleporter and orb stay; final.md and companion descriptions call it an optional return. Its strongest invitation also appears in the main ending, so the spine does not need an unbuilt corridor to carry it.'},
 'book_noise.017':{'status':'done','triage':'fix','decision':'Simplex apply_grid_config now separates readout updates from contract application. Native REGEN followed by plate and relief preserves the regenerated seed, 49 sampled values, generator properties and colours; heights change and return. Explicit seed changes, pre-ready config, shared VIEW and MATCH remain effective. 29 native assertions pass, exit 0, no script/shader errors. No headset claim.'}}
write(o/'decisions.json',json.dumps(decisions,ensure_ascii=False,indent=2)+'\n')
q=json.loads((r/'doc/tasks/book_noise.json').read_text(encoding='utf-8-sig'));tasks={t['id']:t for t in q['tasks']}
notes='''# Noise ending — a field, a form, a return

25 September 2026. Perlin/Simplex, Lab Path and the sequence description reviewed against current source, the earlier Claude audit, companion texts and native museum behaviour.

The main chapter is mature. Keep its shared comparison, arches, four code excerpts, scope-of-return passage and full blob-culture ending. The supplied arch makes the critique bodily: removing noise relief does not remove the room we already decided to give the surface. No new artifact is needed for this passage.

## Decisions

'''+ '\n\n'.join('### '+k+' — '+tasks[k]['title']+'\n\n'+v['decision'] for k,v in decisions.items())+'''

## Native evidence

29 assertions pass in the real isolated museum, exit 0, no GDScript or shader errors. The actual REGEN, VIEW and MATCH button signals are supplied by the probe. This is signal-path verification, not a new mouse-ray or hand interaction test. The readout-only regression checks 49 samples, generator properties, cube heights and colours; explicit seed changes and before-ready configuration also pass. Both arches remain and their flat readout retains the supplied curve and colour. Three new original museum photographs show relief, colour-only and a view from inside the Simplex arch. Relief/colour use the same camera.

The earlier archway pass established supplied body crossings, collision, occupied-shape protection and GPU/CPU agreement. Those source files are unchanged here apart from the root configuration function addressed above. This pass does not rerun those earlier acceptance cases and does not claim headset comfort, hand reach, Quest performance or learner response. Existing engine environment, UID and resource warnings are recorded separately.

## Editorial scope

Lab Path remains an optional grid-lane coda and stays in the complete nine-hall text capture, clearly marked as optional. The main museum/book route is unchanged. Its map changes only a stale description. Three companion summaries are aligned with that choice; older technical/critical/tutorial drafts are retained as sources, not recast wholesale. The existing orb is not newly promoted.

The sequence metadata repairs the broken encoding and describes the current encounters. QFEP is an invitation to ask what variation and representation permit; these halls do not compute political freedom or turn correlation into memory. Local grounding: doc/research/qfep/README.md. Descriptive artifact rationales change; artifact lists and navigation do not. Legacy algorithm_paths references were outside this descriptive pass and remain for a separate registry cleanup.

Current final.md files and the nine-hall capture are updated. Frozen captures and older reviews stay intact. Eight remaining comments are resolved, leaving the requested Space 10 walk from another approach in a headset open and unchanged. No commit. Next sequence: Cellular Automata; begin from what its existing encounters let a body notice, and use the comments to locate missing work without turning the prose into instructions.
'''
write(o/'DECISIONS.md',notes)
owned=changed+['commons/data/museum_core_encounters.json','doc/book/captures/noise/noise-book.md','doc/book/captures/noise/noise-book.manifest.json']
for path in owned:
    p=r/path;dest=o/'after'/path;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(p.read_bytes())
    a=(o/'before'/path).read_text(encoding='utf-8-sig');b=p.read_text(encoding='utf-8-sig')
    if path.endswith('museum_core_encounters.json'):
        a=json.dumps({m:prior['rooms'][m] for m in maps},ensure_ascii=False,indent=2)+'\n';b=json.dumps({m:core['rooms'][m] for m in maps},ensure_ascii=False,indent=2)+'\n'
    write(o/'diffs'/(path+'.diff'),''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+path,tofile=path)))
write(o/'changed-files.json',json.dumps(owned,indent=2)+'\n')
write(o/'source-manifest.json',json.dumps([{'path':p,'before_sha256':baseline.get(p),'after_sha256':H(r/p)} for p in owned],indent=2)+'\n')

sections=[]
for m in maps:
    a=(o/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8-sig');b=(r/'commons/maps'/m/'final.md').read_text(encoding='utf-8')
    reading=markdown.markdown(b,extensions=['fenced_code','footnotes'])
    reading=re.sub(r'id="([^"]+)"',lambda v:'id="'+m+'-'+v[1]+'"',reading);reading=re.sub(r'href="#([^"]+)"',lambda v:'href="#'+m+'-'+v[1]+'"',reading)
    diff=difflib.HtmlDiff(wrapcolumn=70).make_table(a.splitlines(),b.splitlines(),fromdesc='Before this pass',todesc='Current final.md',context=True,numlines=2)
    sections.append(f'<section id="{m}"><h2>{m.replace("_"," ")}</h2><p><a href="/compose/sources?map={m}&amp;doc=final">Current chapter and comments</a></p><details><summary>Text beside the original</summary><div class="diffwrap">{diff}</div></details><div class="reading">{reading}</div></section>')
css=re.search(r'<style>(.*?)</style>',(r/'doc/book/iterations/2026-09-25-noise-opening-review/index.html').read_text(),re.S)[1]
def figure(path,caption):return '<figure><a href="'+path+'"><img loading="lazy" src="'+path+'" alt="'+html.escape(caption,quote=True)+'"></a><figcaption>'+caption+'</figcaption></figure>'
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Noise — a field, a form, a return</title><style>'+css+'</style><main><p>Ada Research · 25 September 2026</p><h1>The curve was already there</h1><p>The field gives the arch its relief. Remove that contribution and a curve still makes room for you. What looked grown has inherited a shape; the pleasure of that surface can lead us to ask what else a body might become.</p><nav><a href="#museum">Inside the museum</a><a href="#reading">Read the ending</a><a href="DECISIONS.md">Decisions and limits</a><a href="/book-tasks/review?seq=noise">Review comments</a><a href="noise-book.md">Current Noise capture</a></nav><p>Eight comments resolved. The main chapter keeps its arches and blob-culture argument. Lab Path remains an optional return, with its strongest invitation also carried by the main ending.</p><h2 id="museum">One curve, two fields</h2><div class="pair">'+figure('native-final/arches-relief.png','Fresh native museum view: Perlin and OpenSimplex2 give the matching arches different relief.')+figure('native-final/arches-colour.png','The same camera after VIEW. The noise relief is removed; the supplied arches and sampled colours remain.')+'</div>'+figure('native-final/inside-simplex.png','Fresh view from inside the Simplex arch, at 1.65 metres above its floor. This camera capture is not a headset walk.')+'<p>Changing the display through the Simplex configuration API now keeps the field chosen by REGEN. The regression checks the samples and colours, then restores the relief. No arch geometry or placement was changed in this pass.</p><h2 id="reading">Read the ending</h2><nav>'+''.join(f'<a href="#{m}">{m.replace("_"," ")}</a>' for m in maps)+'</nav>'+''.join(sections)+'<section><h2>What stands, and what remains</h2><p>The current chapter retains the earlier audited argument and adds the supported arch encounter. The obsolete seed-reset caveat is resolved in code. Lab Path’s optional status removes the second required send-off to Cellular Automata.</p><p><a href="claude-to-current-before-pass.diff">Audited chapter compared with the newer chapter</a> · <a href="diffs/commons/maps/sequences/noise.json.diff">Sequence description changes</a> · <a href="diffs/algorithms/randomness/simplexnoise/SimplexNoise.gd.diff">Display fix</a></p><p>29 native assertions pass. One Noise review item remains open: a terrain walk from another approach in a headset. The other chapters retain their earlier checks and limits.</p><p><a href="verification.json">Preservation checks</a> · <a href="native-final/report.json">Native report</a> · <a href="engine-warnings.json">Engine warnings</a></p><p>Next: Cellular Automata, where a previous state can begin to matter.</p></section></main></html>'
write(o/'index.html',page)
write(o/'verification.json',json.dumps({'passed':True,'checks':checks,'native_assertions':len(report['checks']),'scope':'Noise ending, optional coda and descriptive sequence metadata; native readout regression and museum photographs. No headset acceptance.'},indent=2)+'\n')
print(f'Published {len(checks)} preservation checks and {len(report["checks"])} native assertions.')
