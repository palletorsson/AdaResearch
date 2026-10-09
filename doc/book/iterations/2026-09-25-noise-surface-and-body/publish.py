from pathlib import Path
import difflib, hashlib, html, json, re, shutil
import markdown
r=Path.cwd();rel='doc/book/iterations/2026-09-25-noise-surface-and-body';o=r/rel
maps=['Noise_6_Wall','Noise_Inside_Noise','Noise_Space_10']
H=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf-8'))
checks=[]
def check(name,passed):checks.append({'name':name,'passed':bool(passed)});assert passed,name
baseline=json.loads((o/'baseline.json').read_text())
changed=['commons/maps/Noise_6_Wall/final.md','commons/maps/Noise_Space_10/final.md']
for path,sha in baseline.items():
    if path not in changed and path not in ['commons/data/museum_core_encounters.json','doc/tasks/book_noise.json'] and not path.startswith('doc/book/captures/'):
        check('retained: '+path,H(r/path)==sha)
for m in maps:
    a=(o/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8-sig');b=(r/'commons/maps'/m/'final.md').read_text(encoding='utf-8')
    check(m+': mathematical excerpts retained',re.findall(r'```.*?```',a,re.S)==re.findall(r'```.*?```',b,re.S))
    check(m+': encounter anchors retained',re.findall(r'<!--.*?-->',a)==re.findall(r'<!--.*?-->',b))
check('Inside Noise manuscript retained byte for byte',H(r/'commons/maps/Noise_Inside_Noise/final.md')==baseline['commons/maps/Noise_Inside_Noise/final.md'])
report=json.loads((o/'enclosure-final/report.json').read_text());process=json.loads((o/'enclosure-final/process.json').read_text());log=(o/'enclosure-final/stdout.log').read_text(errors='replace')
check('all fresh native checks pass',report['passed'] and not report['failures'])
check('native process exits zero',process['exit_code']==0)
check('no GDScript errors','SCRIPT ERROR' not in log)
check('full size enclosure',report['observations']['world_base_radius_m']==5.0 and report['observations']['enclosure_scale']==[1,1,1])
write(o/'engine-warnings.json',json.dumps(list(dict.fromkeys(s for s in log.splitlines() if 'ERROR:' in s or 'WARNING:' in s)),indent=2)+'\n')

# Reuse already-verified native work when the implementation is unchanged.
reused=[]
for tag,pictures in [('noise-wall-inside',[('inside.png','wall-pink.png'),('inside-grey.png','wall-grey.png')]),('noise-small-world',[('small-surface.png','small-surface.png')])]:
    p=r/'doc/book/iterations'/('2026-09-25-'+tag)
    source_manifest=json.loads((p/'source-manifest.json').read_text());runtime=json.loads((p/'museum-runtime.json').read_text())
    check(tag+': earlier native report passed',runtime['passed'] and not runtime['failures'])
    for item in source_manifest:
        if item['path'].endswith(('.gd','.gdshader','.tscn')):check(tag+': current implementation '+item['path'],H(r/item['path'])==item['after_sha256'])
    write(o/(tag+'-runtime.json'),json.dumps(runtime,indent=2)+'\n')
    shutil.copy2(p/'source-manifest.json',o/(tag+'-source-manifest.json'))
    for src,dest in pictures:
        shutil.copy2(p/src,o/dest);check('native photograph unchanged: '+dest,H(p/src)==H(o/dest))
        reused.append({'source':(p/src).relative_to(r).as_posix(),'review_image':dest,'sha256':H(o/dest),'status':'retained from earlier native museum run, not a new change'})
write(o/'image-provenance.json',json.dumps(reused,indent=2)+'\n')
manifest=json.loads((r/'doc/book/captures/noise/noise-book.manifest.json').read_text())
check('all nine captured chapters current',len(manifest['maps'])==9 and all(H(r/m['path'])==m['sha256'] for m in manifest['maps']))
check('capture hash correct',H(r/'doc/book/captures/noise/noise-book.md')==manifest['output_sha256'])
shutil.copy2(r/'doc/book/captures/noise/noise-book.md',o/'noise-book.md')
check('review copy equals current capture',H(o/'noise-book.md')==H(r/'doc/book/captures/noise/noise-book.md'))

p=r/'commons/data/museum_core_encounters.json';core=json.loads(p.read_text(encoding='utf-8-sig'))
write(o/'core-before-update.json',json.dumps(core,ensure_ascii=False,indent=2)+'\n');prior=json.loads((o/'core-before-update.json').read_text())
for m in maps:core['rooms'][m].update(text_sha256=H(r/'commons/maps'/m/'final.md'),map_sha256=H(r/'commons/maps'/m/'map_data.json'),local_review=rel+'/DECISIONS.md')
write(p,json.dumps(core,ensure_ascii=False,indent=2)+'\n')
for m in maps:
    allowed={'text_sha256','map_sha256','local_review'}
    check(m+': roles, reason and maturity retained',{k:v for k,v in core['rooms'][m].items() if k not in allowed}=={k:v for k,v in prior['rooms'][m].items() if k not in allowed})
check('all other core references preserved',all(v==prior['rooms'][m] for m,v in core['rooms'].items() if m not in maps))

decisions={
 'book_noise.001':{'status':'done','triage':'fix','decision':'The main prose now says one recorded walk and the controller in that walk. Desktop provenance, date, forty-five-degree limit and the limits of that observation stay in the existing footnote. The two height settings, body-dependent argument, pink trail and miniature return are preserved.'},
 'book_noise.009':{'status':'done','triage':'fix','decision':'Removed only the untraceable half-white measurement. The exact gain/clamp equation and the conditional claim that sums of 0.5 or greater map to white remain, along with the argument that grey is already an interpretation. No new measurement is invented.'},
 'book_noise.011':{'status':'done','triage':'fix','decision':'The chapter now asks what your body can cross and what you imagine crossing. It keeps its address to the visitor instead of switching to the player.'},
 'book_noise.015':{'status':'done','triage':'comment','decision':'Fresh native museum check: host, study and shell all have global scale (1,1,1); base radius is five metres. The old 80% shrink is absent. Both shell openings pass bounded rays at three heights; floor support and RELIEF/SKIN return pass. Existing scene and chapter retained; headset comfort is not certified.'},
 'book_noise.020':{'status':'open','triage':'comment','decision':'Keep open for the requested walk from the other approach in a headset. Newer native work adds a pink trail, a recorded sidestep and reversible miniature scale, but none constitutes a tracked-headset crossing. Keep the chapter bounded to one body, one approach and two settings; do not loosen its claims on that basis.'}}
write(o/'decisions.json',json.dumps(decisions,ensure_ascii=False,indent=2)+'\n')
q=json.loads((r/'doc/tasks/book_noise.json').read_text(encoding='utf-8-sig'));tasks={t['id']:t for t in q['tasks']}
notes='''# Noise: surface and body

25 September 2026. Noise 6 Wall, Inside Noise and Space 10 reviewed against current manuscripts, companion texts, source and the newer immersive encounters. The sequence has a clear progression: appearance can change an approach before geometry changes; a field can displace the enclosing surface; a sampled landscape can resist a particular moving body. No new artifact is needed to support these passages.

Five sentence edits across two final.md files. Inside Noise is retained byte for byte. Every mathematical excerpt and artifact anchor remains. The room's coloured finish, vertex relief, pink walk trace and one-eighth-size return remain intact. The half-white measurement was an untraceable incidental number; removing it does not cut the chapter's argument about display interpretation.

## Review decisions

'''+ '\n\n'.join('### '+k+' — '+tasks[k]['title']+'\n\n**'+v['status']+'**. '+v['decision'] for k,v in decisions.items())+'''

## Native evidence

20 fresh assertions pass in the real enclosing-sphere hall, with exit 0 and no GDScript errors. The host, study and shell retain unit global scale; the base radius measures five metres in world space. Six short rays cross the two shell doorways at three heights, a floor ray finds support, and the actual RELIEF button signal returns from relief to skin and back. Two fresh fixed-camera photographs show the surrounding surface. These are geometry, signal and camera checks, not a new body traversal or headset test.

The first enclosure run had three failed rays. The diagnostic run identifies the hit as the outer hall Collision at local x = -5.5 m, exactly at the ray's endpoint, rather than the enclosing shell. The final rays end at 5.35 m, beyond the shell opening and before that wall. All three reports remain. The outside approach is bounded; a clear short ray does not certify a comfortable turning space. No collision was removed and no geometry was changed to make the check pass.

The existing wall run (37 checks) and miniature run (38 checks) already passed. Their implementation hashes still match current source, so this pass preserves and references that evidence instead of repeating the work. Their original museum photographs are copied unchanged and labelled as retained views. The older walked-noise diagnostic is context only: its study and trace scripts were subsequently extended by the miniature work, so it is not presented as verification of today's complete implementation.

Existing engine/environment/resource warnings are recorded separately. Headset reach, another approach through the terrain, actual flying/walking comfort, Quest performance and learner response remain unverified. The four resolved comments leave Noise at eleven done and nine open. Original reviewer fields and notes are retained. The current nine-hall capture is refreshed, older snapshots remain frozen, and only these three shared core references are updated. No artifact code, map placement, sequence, role or companion text is changed; no commit.

Next review: Perlin/Simplex and the sequence/coda metadata. Preserve the new arch encounter and the critique of noise as an easy answer to organic form.
'''
write(o/'DECISIONS.md',notes)
owned=changed+['commons/data/museum_core_encounters.json','doc/book/captures/noise/noise-book.md','doc/book/captures/noise/noise-book.manifest.json']
for path in owned+['commons/maps/Noise_Inside_Noise/final.md']:
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
    diff=difflib.HtmlDiff(wrapcolumn=70).make_table(a.splitlines(),b.splitlines(),fromdesc='Before this pass',todesc='Current final.md',context=True,numlines=2) if a!=b else '<p>Retained byte for byte. The new enclosing relief already supports this chapter.</p>'
    sections.append(f'<section id="{m}"><h2>{m.replace("_"," ")}</h2><p><a href="/compose/sources?map={m}&amp;doc=final">Current chapter and comments</a></p><details><summary>Text beside the original</summary><div class="diffwrap">{diff}</div></details><div class="reading">{reading}</div></section>')
css=re.search(r'<style>(.*?)</style>',(r/'doc/book/iterations/2026-09-25-noise-opening-review/index.html').read_text(),re.S)[1]
def figure(path,caption):return '<figure><a href="'+path+'"><img loading="lazy" src="'+path+'" alt="'+html.escape(caption,quote=True)+'"></a><figcaption>'+caption+'</figcaption></figure>'
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Noise — surface and body</title><style>'+css+'</style><main><p>Ada Research · 25 September 2026</p><h1>What the surface lets a body do</h1><p>A painted fold can make you hesitate before it can hold your foot. Then the field reaches the wall’s shape, and finally the ground beneath you. These three halls let that difference become an encounter.</p><nav><a href="#museum">Inside the museum</a><a href="#reading">Read the three halls</a><a href="DECISIONS.md">Decisions and limits</a><a href="/book-tasks/review?seq=noise">Review comments</a><a href="noise-book.md">Current Noise capture</a></nav><p>Five sentence edits in two chapters; Inside Noise retained unchanged. Four comments resolved. The request for another terrain approach in a headset remains open.</p><h2 id="museum">The room changes its appearance</h2><div class="pair">'+figure('wall-pink.png','Retained museum photograph from the earlier wall pass: the pink finish surrounds the visitor.')+figure('wall-grey.png','Retained paired view: DRESS changes the finish while the opening and supporting floor remain.')+'</div><h2>The enclosing surface gains depth</h2><div class="pair">'+figure('enclosure-final/enclosing-relief.png','Fresh museum photograph: relief shapes the enclosing wall. The base sphere keeps its full five-metre radius.')+figure('enclosure-final/enclosing-skin.png','Fresh photograph from the same camera: SKIN restores the round surface while the field’s colours remain.')+'</div><p>The earlier shrink is absent. Both openings remain in the shell; the outer hall still bounds the approach. No geometry needed changing in this pass.</p><h2>The same ground, another body</h2>'+figure('small-surface.png','Retained native view from the miniature encounter. Becoming one-eighth size brings the existing sampled terrain close enough for its triangles to become part of the experience.')+'<p>The chapter keeps its distinctions: a proposed route, a recorded walk, and the body whose dimensions and controller decide what happens. Desktop provenance stays in the footnote. The pink trail and reversible return remain part of the encounter.</p><h2 id="reading">Read the three halls</h2><nav>'+''.join(f'<a href="#{m}">{m.replace("_"," ")}</a>' for m in maps)+'</nav>'+''.join(sections)+'<section><h2>Evidence and the next step</h2><p>20 fresh native assertions pass in the enclosing sphere. Earlier wall and miniature evidence is retained with matching source hashes. These checks do not replace a headset walk.</p><p><a href="verification.json">Preservation checks</a> · <a href="enclosure-final/report.json">Fresh native report</a> · <a href="engine-warnings.json">Engine warnings</a> · <a href="image-provenance.json">Photograph provenance</a></p><p>Next: Perlin/Simplex, its new walk-through arches, and the sequence’s closing route.</p></section></main></html>'
write(o/'index.html',page)
write(o/'verification.json',json.dumps({'passed':True,'checks':checks,'native_assertions':len(report['checks']),'scope':'Two manuscript revisions, one unchanged chapter; fresh enclosure scale/clearance checks. No headset acceptance.'},indent=2)+'\n')
print(f'Published {len(checks)} preservation checks and {len(report["checks"])} fresh native assertions.')
