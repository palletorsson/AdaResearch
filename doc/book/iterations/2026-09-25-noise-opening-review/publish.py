from pathlib import Path
import difflib, hashlib, html, json, re, shutil, urllib.request
import markdown

r=Path.cwd(); rel='doc/book/iterations/2026-09-25-noise-opening-review'; o=r/rel
maps=['Random_Noise_Types','Noise_Columns','Noise_One','Noise_Voxel']
H=lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
checks=[]
def check(name, passed):
    checks.append({'name':name,'passed':bool(passed)})
    assert passed, name
def write(p,s):
    p.parent.mkdir(parents=True,exist_ok=True); p.write_bytes(s.encode('utf-8'))
baseline=json.loads((o/'baseline.json').read_text())
changed=[f'commons/maps/{m}/final.md' for m in maps]+['commons/maps/Noise_Voxel/map_data.json','commons/artifacts/perlin_terrain_sculptor/perlin_terrain_sculptor.gd']
for path, sha in baseline.items():
    if path not in changed and path not in ['commons/data/museum_core_encounters.json','doc/tasks/book_noise.json'] and not path.startswith('doc/book/captures/'):
        check('retained: '+path,H(r/path)==sha)
for m in maps:
    before=(o/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8-sig')
    now=(r/'commons/maps'/m/'final.md').read_text(encoding='utf-8')
    check(m+': all code excerpts retained',re.findall(r'```.*?```',before,re.S)==re.findall(r'```.*?```',now,re.S))
    check(m+': artifact anchors retained',re.findall(r'<!--.*?-->',before)==re.findall(r'<!--.*?-->',now))
old=json.loads((o/'before/commons/maps/Noise_Voxel/map_data.json').read_text())
new=json.loads((r/'commons/maps/Noise_Voxel/map_data.json').read_text())
for row in old['layers']['interactables']:
    for i,v in enumerate(row):
        if v.startswith('perlin_terrain_sculptor:'):row[i]=v+'#keyboard:off'
check('only local keyboard configuration changes in map',old==new)
native=0; warnings={}
for sub in ['rings','voxel-final']:
    report=json.loads((o/sub/'report.json').read_text()); process=json.loads((o/sub/'process.json').read_text())
    log=(o/sub/'stdout.log').read_text(errors='replace')
    check(sub+': native assertions pass',report['passed'] and not report['failures'])
    check(sub+': process exits zero',process['exit_code']==0)
    check(sub+': no script errors','SCRIPT ERROR' not in log)
    native+=len(report['checks'])
    warnings[sub]=list(dict.fromkeys(line for line in log.splitlines() if 'ERROR:' in line or 'WARNING:' in line))
write(o/'engine-warnings.json',json.dumps(warnings,indent=2)+'\n')
# The repaired geometry predates this pass. Preserve provenance instead of claiming a new build.
for name,path in [('noise-one-standing','algorithms/randomness/noisetorus/noisetorus.gd'),('voxel-flight','algorithms/randomness/voxelnoise/voxelnoise.gd')]:
    manifest=json.loads((r/'doc/book/iterations'/('2026-09-25-'+name)/'source-manifest.json').read_text())
    previous=next(v for v in manifest if v['path']==path)
    check('earlier repair retained: '+path,H(r/path)==previous['after_sha256'])
source=r/'doc/book/iterations/2026-09-25-voxel-flight/above-volume.png'
shutil.copy2(source,o/'above-volume.png')
check('retained flight image copied unchanged',H(source)==H(o/'above-volume.png'))

shutil.copy2(r/'doc/book/captures/noise/noise-book.md',o/'noise-book.md')
check('review copy matches current capture',H(r/'doc/book/captures/noise/noise-book.md')==H(o/'noise-book.md'))

# Read shared core immediately before patching just these four reference records.
p=r/'commons/data/museum_core_encounters.json'; core=json.loads(p.read_text(encoding='utf-8-sig'))
write(o/'core-before-update.json',json.dumps(core,ensure_ascii=False,indent=2)+'\n')
for m in maps:
    core['rooms'][m].update(text_sha256=H(r/'commons/maps'/m/'final.md'),map_sha256=H(r/'commons/maps'/m/'map_data.json'),local_review=rel+'/DECISIONS.md')
write(p,json.dumps(core,ensure_ascii=False,indent=2)+'\n')
prior=json.loads((o/'core-before-update.json').read_text())
for m,record in core['rooms'].items():
    if m in maps:
        allowed={'text_sha256','map_sha256','local_review'}
        check(m+': primary roles and maturity retained',{k:v for k,v in record.items() if k not in allowed}=={k:v for k,v in prior['rooms'][m].items() if k not in allowed})
check('all other core room records retained',all(v==prior['rooms'][m] for m,v in core['rooms'].items() if m not in maps))
manifest=json.loads((r/'doc/book/captures/noise/noise-book.manifest.json').read_text())
check('current capture contains all nine declared halls',len(manifest['maps'])==9)
check('every captured chapter matches current final.md',all(H(r/m['path'])==m['sha256'] for m in manifest['maps']))
check('capture output hash matches',H(r/'doc/book/captures/noise/noise-book.md')==manifest['output_sha256'])

decisions={
    '004':('fix','The chapter now locates the piece count at the bench. The volume retains its dimensional captions, one-metre cells and glass flight enclosure.'),
    '008':('fix','The 35% now refers to differences between saved images; a footnote states the largest-5%-pixel metric. It does not measure the fraction of the body that changed. The open question of which family member one desires is retained.'),
    '010':('fix','Removed desktop from the computational piece-count footnote. Date, seed, measurements and limits remain.'),
    '012':('fix','The basin now stands at the centre of the room in the prose, rather than at an ambiguous opening.'),
    '016':('comment','Already repaired in the Noise One standing pass. Fresh native checks find both posts from 0.78 m to 0.98 m, reaching the upright tubes. The source is unchanged from that repair; its current manuscript is retained apart from the basin location.'),
    '018':('comment','Already repaired and developed further in the voxel flight pass. The paired bodies share orientation; captions face both approaches; the large body keeps 25 times the model spacing. Fresh native checks confirm these. No placement rollback.'),
    '019':('fix','Only the Noise Voxel bench opts out of global arrow/R/N shortcuts using keyboard:off. All six keys leave its field unchanged; all four real console button signals still work and update the local volume. Standalone defaults and opt-in keyboard behaviour remain available.')}
decisions={'book_noise.'+k:{'status':'done','triage':v[0],'decision':v[1]} for k,v in decisions.items()}
write(o/'decisions.json',json.dumps(decisions,ensure_ascii=False,indent=2)+'\n')
queue=json.loads((r/'doc/tasks/book_noise.json').read_text(encoding='utf-8-sig')); tasks={t['id']:t for t in queue['tasks']}
notes='''# Noise: the value and its receiver

25 September 2026. Opening four halls reviewed against their current final.md, companion manuscripts, placed artifacts, source and recent native work. These are narrow repairs to a mature opening, not a new uniform rewrite. The order remains: a rule that keeps acting; a body changing in time; one field received as relief or colour; a threshold deciding occupancy.

## Decisions

'''
notes+='\n\n'.join('### '+k+' — '+tasks[k]['title']+'\n\n'+d['decision'] for k,d in decisions.items())
notes+='''

The Random Noise Types chapter also gains a paragraph break between Gaussian generation and its visible consequence. Every mathematical excerpt and artifact anchor remains. Secondary orbs stay secondary. Companion texts, scene geometry, sampling functions, collision, artifact roles, sequence order and the new flight enclosure are retained.

## Verification and limits

38 assertions pass in the actual Godot museum: 10 in Noise One and 28 in Noise Voxel. Both final processes exit 0, with no GDScript errors. The voxel test supplies individual key events to the artifact's input handler, then emits the actual four console button signals. It checks occupancy, local receiver updates and survival of the flight enclosure. It does not claim physical headset interaction, pointer targeting, flight traversal, Quest performance or learner acceptance.

The first voxel diagnostic passed 26/27 checks. Its caption check expected “25 times” but the running label says “25.0 times”. The corrected check verifies the scale numerically and both caption positions. That first report remains under voxel/; the final report is voxel-final/. Existing engine/resource warnings are retained in engine-warnings.json and complete logs, including renderer feature limitations and texture leaks on shutdown. No claim that the engine is warning-free.

Two fresh native photographs show the rings and the bench. The larger flight photograph is copied unchanged from the earlier voxel-flight iteration and labelled as such. These are museum views, not grid diagrams or generated illustrations. Current final.md chapters and the nine-hall Noise capture are updated; older review snapshots remain frozen. Shared core references are patched only for these four rooms. No live museum bake/save is intentionally changed and no commit is made.

Thirteen Noise comments remain for the later halls and sequence metadata. Next: Noise 6 Wall, Inside Noise and Space 10, checking current immersive work before acting on older reviews.
'''
write(o/'DECISIONS.md',notes)
owned=changed+['commons/data/museum_core_encounters.json','doc/book/captures/noise/noise-book.md','doc/book/captures/noise/noise-book.manifest.json']
for path in owned:
    p=r/path; dest=o/'after'/path; dest.parent.mkdir(parents=True,exist_ok=True); dest.write_bytes(p.read_bytes())
    bp=o/'before'/path
    if not bp.exists():continue
    a=bp.read_text(encoding='utf-8-sig'); b=p.read_text(encoding='utf-8-sig')
    if path.endswith('museum_core_encounters.json'):
        a=json.dumps({m:prior['rooms'][m] for m in maps},ensure_ascii=False,indent=2)+'\n'
        b=json.dumps({m:core['rooms'][m] for m in maps},ensure_ascii=False,indent=2)+'\n'
    write(o/'diffs'/(path+'.diff'),''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+path,tofile=path)))
write(o/'changed-files.json',json.dumps(owned,indent=2)+'\n')
write(o/'source-manifest.json',json.dumps([{'path':p,'before_sha256':baseline.get(p),'after_sha256':H(r/p)} for p in owned],indent=2)+'\n')

sections=[]
for m in maps:
    a=(o/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8-sig'); b=(r/'commons/maps'/m/'final.md').read_text(encoding='utf-8')
    reading=markdown.markdown(b,extensions=['fenced_code','footnotes'])
    reading=re.sub(r'id="([^"]+)"',lambda v:'id="'+m+'-'+v[1]+'"',reading)
    reading=re.sub(r'href="#([^"]+)"',lambda v:'href="#'+m+'-'+v[1]+'"',reading)
    table=difflib.HtmlDiff(wrapcolumn=70).make_table(a.splitlines(),b.splitlines(),fromdesc='Before this pass',todesc='Current final.md',context=True,numlines=2)
    sections.append(f'<section id="{m}"><h2>{m.replace("_"," ")}</h2><p><a href="/compose/sources?map={m}&amp;doc=final">Current chapter and comments</a></p><details><summary>Exact changes beside the original</summary><div class="diffwrap">{table}</div><a href="diffs/commons/maps/{m}/final.md.diff">Plain diff</a></details><div class="reading">{reading}</div></section>')
css='body{margin:0;background:#f3eee5;color:#302b31;font:18px/1.65 Georgia,serif}main{max-width:1160px;margin:auto;padding:40px 26px}h1{font-size:48px;line-height:1.12}h2{line-height:1.3}a{color:#72526c}p{max-width:78ch}nav{display:flex;gap:18px;flex-wrap:wrap}img{width:100%;height:auto}figure{margin:28px 0}figcaption{font-size:15px;max-width:90ch}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}.reading{max-width:760px;margin:40px auto}.reading h1{font-size:34px}section{margin-top:48px;padding-top:24px;border-top:1px solid #cfc6bb}details{padding:18px;border:1px solid #cfc6bb}summary{cursor:pointer}.diffwrap{overflow:auto}.diff{font:12px/1.4 monospace}.diff_header{background:#e2d9cd}.diff_add{background:#d9ead8}.diff_sub{background:#efd9d5}.diff_chg{background:#f0e5b8}table{border-collapse:collapse;width:100%}td,th{vertical-align:top;padding:9px;border-bottom:1px solid #ccc}pre{overflow:auto;background:#e8e1d7;padding:15px;font-size:13px}@media(max-width:750px){.pair{display:block}h1{font-size:35px}}'
def figure(path,caption):return '<figure><a href="'+path+'"><img loading="lazy" src="'+path+'" alt="'+html.escape(caption,quote=True)+'"></a><figcaption>'+caption+'</figcaption></figure>'
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Noise — the value and its receiver</title><style>'+css+'</style><main><p>Ada Research · 25 September 2026</p><h1>The value and its receiver</h1><p>A field can alter a surface, colour it, or decide where a block belongs. These opening halls let the same word, noise, divide into different encounters. The revisions give the reader a clearer place to look while keeping the question of what a body may become.</p><nav><a href="#museum">Inside the museum</a><a href="#reading">Read the four halls</a><a href="DECISIONS.md">Decisions and limits</a><a href="/book-tasks/review?seq=noise">Review comments</a><a href="noise-book.md">Current Noise capture</a></nav><p>Four small chapter revisions. Seven comments resolved, including two already repaired by recent artifact work. The museum bench now reserves walking keys for movement.</p><h2 id="museum">Two ways to receive a field</h2>'
page+=figure('rings/upright-pair.png','Fresh museum view. One upright ring receives the field as relief, the other as colour. Both supports already reached the tubes; this pass verifies and retains that repair. The violet basin lies behind them.')
page+='<h2>A count has a location</h2><div class="pair">'+figure('voxel-final/bench-controls.png','Fresh museum view. The plate at this bench counts occupied cells and connected pieces. Its four buttons still change the encounter; arrow keys, R and N no longer change it while moving through the museum.')+figure('above-volume.png','Retained native photograph from the earlier voxel-flight pass. The same decisions gain one-metre cells inside a glass enclosure. The caption here gives dimensions, not the bench’s piece count.')+'</div>'
page+='<p>A connected piece does not promise headroom or a usable route. That distinction stays in the chapter. The large body and its flight enclosure remain intact.</p><h2 id="reading">The opening four halls</h2><nav>'+''.join(f'<a href="#{m}">{m.replace("_"," ")}</a>' for m in maps)+'</nav>'+''.join(sections)
page+='<section><h2>What was checked</h2><p>38 native assertions pass across two halls. This includes the retained supports and orientation, individual key events and all four console button signals. Headset use, pointer targeting, flight routes and learner understanding remain untested in this pass. Existing engine warnings and the initial diagnostic correction are recorded.</p><p><a href="verification.json">Publication checks</a> · <a href="rings/report.json">Ring report</a> · <a href="voxel-final/report.json">Voxel report</a> · <a href="engine-warnings.json">Engine warnings</a></p></section></main></html>'
write(o/'index.html',page)
write(o/'verification.json',json.dumps({'passed':True,'checks':checks,'native_assertions':native,'scope':'Four chapter clarifications, two real museum halls. No headset, Quest, full route or learner acceptance.'},indent=2)+'\n')
print(f'Published {len(checks)} checks, {native} native assertions, {len(decisions)} decisions.')
