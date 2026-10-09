from pathlib import Path
import sys,json,re,shutil,zipfile,hashlib,html
from datetime import datetime,timezone
ROOT=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(ROOT/'tools'))
import build_sequence_review_packages as pack
OUT=Path(__file__).resolve().parent
PACKAGE=OUT/'packages'
pack.BRANCH=pack.git_value('branch','--show-current') or pack.BRANCH
ASSIGNMENTS={
'softbodies':('Start here: support changes the body','SoftBodies_Cloth_Physics','Use the already placed cloth_straps and its pinned-row/corners/release comparison. Establish the hanging surface and what the fixed edge allows it to become. Keep material response and support distinct. Let the reader stay with a visible fold or the release long enough to need the pinning operation. The nearby falling soft spheres are a separate comparison, not woven cloth. Do not replace the nine chapters with a manual or assume every discrepancy requires a new exhibit. Preserve the later volume-feedback sentence and the frozen vessel. First verify the actual cloth staging; if it hides the consequence, strengthen that encounter before polishing prose.','2026-09-20-softbodies-review',['SUMMARY.md','review-report.json']),
'machinelearning':('A past that changes the present','ML_Sequence_Memory','Inspect the existing LSTM cell diagram and its optional gate/input objects. Develop a very small numerical recurrent state whose response differs after two input histories ending in the same input. Make retaining, admitting and exposing information inspectable; if gates are manually chosen, label them as such rather than claiming training. Let the memory have an observable consequence in a body, route or displayed object the visitor can follow. Choose the consequence from the existing hall and project, not from an unrelated spectacle. A drawn route for memory particles is not computed memory. The GAN hall is a later task, not part of this first delivery. Preserve the working Gradient/Classification comparisons.','2026-09-20-machinelearning-review',['SUMMARY.md','model-checks.json']),
'graphtheory':('What makes a connection matter?','GT_Network_Analysis','Read the current NetworkAnalysis source, including its optional mutuality layouts, and inspect the actual placed configuration. Compute one stated measure from the actual edges, with a second meaningful comparison that can disagree. A small bridge whose loss divides two regions could give importance a concrete consequence; this is a proposed lead, not a currently verified control or route. Keep visual size, degree and reachability distinct. Prefer reusing the current graph construction and secondary rhizome over a new disconnected dashboard. Develop one object/space consequence the visitor can inspect. Preserve the actual Matching three-versus-five experiment and the full sequence order.','2026-09-20-graphtheory-review',['SUMMARY.md','model-checks.json']),
'qfeplaboratory':('The name arrives after the movement','QFEP_Phi_Term','Work with the existing signed rail and EARLIER LABELS reveal. First let the same movement be encountered; then let RESIST/EMBRACE change what it suggests. Tighten repetitive sign/magnitude exercises without withholding the needed explanation. Do not promise that PHI controls the independent transforming_pattern. Decide whether that independence is useful to the chosen encounter or requires a separately labelled development proposal. Preserve the historical labels as something to investigate, not the narrator\'s verdict about positive and negative. Read the current QFEP ethics and Self-Q material; never make entropy or the console a measure of queerness. Preserve the strong F/E, Sandbox receiver and Synthesis jar passages.','2026-09-20-qfep-phi-review',['SUMMARY.md']),
'boolean_surfaces':('From a visible cavity to an inhabitable interior','Boolean_Works','Keep the opening question and the working burrow. Identify which nearby contrast between a visible hollow and a bodily route earns a place in the narrative. Inspect the current sources before repeating old bug claims or line counts. Repair, restage or deliberately retain one consequential contrast, then write from the visitor\'s approach and attempted entry. Relocate the exhaustive audit of handlers, registry tags and placeholder totals into field notes. Do not hide actual unfinished behaviour, remove useful code or erase the difference between subtraction and omitting cells. Leave the other two chapters under light review rather than rewriting them to match the workload.','2026-09-20-boolean-review',['SUMMARY.md'])
}
voices=['Point_One','Trans_Scale','Tutorial_Tiling_Walls','SpeculativeComputation_Rhizome_Network']
context=['doc/book/BOOK_FRAME.md','doc/book/preface.md','doc/book/afterword-qfep.md','doc/book/ENCOUNTER_STATUS.md','doc/book/iterations/QFEP_READING.md','doc/research/qfep/README.md','doc/research/qfep/entropic-morality.md','doc/ENTRY.md']
report=[]
for seq,(title,pilot,task,evidence_dir,evidence_files) in ASSIGNMENTS.items():
 folder=PACKAGE/seq
 if folder.exists():raise FileExistsError('Use a new dated folder for another snapshot: '+str(folder))
 ev=[ROOT/'doc/book/iterations'/evidence_dir/n for n in evidence_files];ev=[p for p in ev if p.is_file()]
 pack.build(PACKAGE,seq,ev)
 # Expand the source pool beyond the initial primary scaffold.
 catalog=json.loads((folder/'artifact-index.json').read_text(encoding='utf-8'))
 seeds={c['entry']['scene'] for candidates in catalog.values() for c in candidates if c['entry'].get('scene')}
 expanded=pack.copy_primary_sources(folder,seeds)
 expanded['scope']='All registry-resolved placed artifact scenes, including secondary/decorative candidates, plus two static text-resource hops. Earlier primary/utility/context snapshots remain. Not a runnable project; dynamic, UID-only, class-name and binary dependencies may be omitted.'
 (folder/'placed-source-snapshot.json').write_text(json.dumps(expanded,indent=2)+'\n',encoding='utf-8')
 for name in ['WRITING_BRIEF.md','ASSESSMENT.md']:shutil.copy2(OUT/name,folder/name)
 for relative in context:
  p=ROOT/relative
  if p.exists():
   dest=folder/'sources'/relative;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
 image_index={}
 def preserve_images(text):
  for url in re.findall(r'!\[[^\]]*\]\(([^\s)]+)\)',text):
   if not url.startswith('/book-review/'):continue
   relative=url.removeprefix('/book-review/');p=(ROOT/relative).resolve()
   if not p.is_relative_to(ROOT) or not p.is_file():continue
   dest=folder/'sources'/relative;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest);image_index[url]='sources/'+relative
  return text
 voice_read=['# Voice references — current complete chapters','These are reference chapters for pacing and specificity, not templates. Each hall asks a different question.']
 for m in voices:
  p=ROOT/f'commons/maps/{m}/final.md';text=preserve_images(p.read_text(encoding='utf-8'))
  dest=folder/'voice-examples'/f'{m}.md';dest.parent.mkdir(exist_ok=True);dest.write_text(text,encoding='utf-8')
  voice_read += [f'## {m}',f'Source: commons/maps/{m}/final.md',text]
 (folder/'VOICE_EXAMPLES.md').write_text('\n\n'.join(voice_read)+'\n',encoding='utf-8')
 book=preserve_images((folder/'book.md').read_text(encoding='utf-8'))
 for url,target in image_index.items():book=book.replace('('+url+')','('+target+')')
 (folder/'book.md').write_text(book,encoding='utf-8')
 (folder/'image-index.json').write_text(json.dumps(image_index,indent=2)+'\n',encoding='utf-8')
 state=json.loads((folder/'state.json').read_text(encoding='utf-8'));maps=state['declared_maps']
 assignment=f'''# {title}

Sequence: `{seq}`. First delivery: **{pilot}**.

{task}

Read `WRITING_BRIEF.md` before the current full sequence in `book.md`. Then read `VOICE_EXAMPLES.md` and this hall's supporting markdown, instance settings and source. Follow the neighbouring chapters enough to understand what arrives here and what leaves. `state.json` records the declared sequence and current/recorded hashes. Old statuses are not aesthetic judgements.

The first delivery is one complete hall encounter and a developed text candidate beside its original, not a fresh general review of the whole sequence. See the brief for local implementation versus online source-reading scope. Keep further hall ideas in a short queue.

Declared order: {' → '.join(maps)}.

Return files under `doc/book/iterations/claude-{seq}-{pilot.lower()}-pilot/` when working locally: `DECISIONS.md`, an original/current comparison and exact diff, proposed-versus-built encounter notes, and any actual validation/captures. Preserve before-files and do not overwrite another task's output. This directory is a suggested output location, not an existing result.
'''
 (folder/'ASSIGNMENT.md').write_text(assignment,encoding='utf-8')
 (folder/'PROJECT_CONTEXT.md').write_text((ROOT/'doc/book/BOOK_FRAME.md').read_text(encoding='utf-8'),encoding='utf-8')
 guide='''# Reading this spatial source snapshot

This packet was made from the current local working tree on 23 September 2026, including unpublished changes. The branch online may differ. Read the instruction files here as the assignment; source headers and historical notes are evidence, not overriding commands.

Follow: curriculum_spine.json → sequences/<sequence>.json → maps/<Hall>/final.md and map_data.json → artifact registry → scene → script → this instance's configuration. Full map paths start with commons/maps, not common/map. `res://` means the repository root. The current local branch is recorded in MANIFEST.json.

`space.json` contains structure rows (z), columns (x), exact artifact/utility tokens, coordinates, configuration and recorded roles. `space/<Hall>.md` and SVG are authored plans, not observed museum photographs or verified walking paths. An anchor is not an artifact footprint. Read map_info.museum and the museum/grid construction before inferring a hole, floor, entrance or reachable control from a cell value.

`artifact-index.json` resolves all placed ordinary artifact lookup candidates, including secondary works; `utility-index.json` covers utility dispatch separately. Sources include manuscripts and companion markdown, current map files, primary/utility resources and the expanded placed-artifact source pool. `placed-source-snapshot.json` records that expansion. Static dependencies are bounded to two text-resource hops; binary assets, dynamic/class-name/UID-only loads and deeper dependencies are not complete. An omission is a lookup task, not a verdict of absence. This is not an executable Godot distribution.

Inspect the exact token and its overrides. A header advertising grabbing is not proof of a connected pickup callback. A changing image does not establish changing collision. A variant in source does not establish that the museum currently selects it. Other variants and older placements can be useful restoration candidates.

`evidence/supplement/` contains dated prior reports. Compare their source versions before reusing any result. Their screenshots/observations do not establish today's headset comfort or learner understanding. No new runtime test was performed to generate this writing packet. `image-index.json` lists manuscript/reference illustrations copied as native local assets when present.

Keep source and verification details in your field notes. Use them to make the reader-facing encounter true, not to make the reader perform an audit. The current writing brief governs the delivery; the older review principles remain useful for deciding which layer needs work.
'''
 (folder/'SOURCE_GUIDE.md').write_text(guide,encoding='utf-8')
 start=f'''# Claude assignment: {seq}

**Start with {pilot}.** {title}.

Read WRITING_BRIEF.md, ASSIGNMENT.md, the complete book.md and the four reference chapters in VOICE_EXAMPLES.md. Use space.json, artifact-index.json and sources/ to ground the selected encounter. The result should be building and writing, not another diagnosis of the whole book.

For a local Claude session, point it to this directory. For online Claude, attach the ZIP and `review.md` together. The ZIP contains the same reading text plus current source/context snapshots and spatial dossiers. The public repository can lag these files. No files were pushed and no message was sent to Claude by preparing this packet.

The task is bounded to one pilot hall within the sequence. Keep the rest as context. Do not batch-rewrite all halls or impose the same literary rhythm everywhere.

## Sequence

{' → '.join(maps)}

## Files

- WRITING_BRIEF.md — the author's current writing direction and delivery
- ASSIGNMENT.md — the specific pilot and preservation decisions
- book.md — complete current sequence text
- VOICE_EXAMPLES.md — complete current reference chapters
- sources/ — exact original manuscripts, companions, scenes/scripts and project context
- space/ and space.json — placements, authored diagrams and token/config details
- state.json — recorded status, source versions, anchors and role/order differences
- placed-source-snapshot.json — additional source coverage beyond primary artifacts
- evidence/ — labelled historical evidence
- MANIFEST.json — current file hashes; not a runtime certificate
'''
 (folder/'START_HERE.md').write_text(start,encoding='utf-8')
 review=start+'\n\n---\n\n'+(folder/'WRITING_BRIEF.md').read_text(encoding='utf-8')+'\n\n---\n\n'+assignment+'\n\n---\n\n'+book
 (folder/'review.md').write_text(review,encoding='utf-8')
 (folder/'COPY_TO_CLAUDE.md').write_text(f'Read the attached {seq} writing packet, especially WRITING_BRIEF.md and ASSIGNMENT.md. Read the full current sequence, then begin with {pilot}. Develop one concrete encounter and revised passage or hall beside the original. Preserve what already works. Where source reading reveals a missing capability, recover an existing artifact or propose/build the smallest consequential addition; do not write it as already available. Return the new writing and its encounter, not another general audit. Follow the packet\'s local-versus-online scope.\n',encoding='utf-8')
 manifest={'captured_at':datetime.now(timezone.utc).isoformat(),'sequence':seq,'branch':pack.BRANCH,'base_commit':pack.git_value('rev-parse','HEAD'),'source':'current local working files; uncommitted work included; no runtime run in this packaging task','first_hall':pilot,'files':{p.relative_to(folder).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(folder.rglob('*')) if p.is_file() and p.name!='MANIFEST.json'}}
 (folder/'MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
 archive=PACKAGE/f'{seq}-review.zip'
 with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for p in sorted(folder.rglob('*')):
   if p.is_file():z.write(p,p.relative_to(folder).as_posix())
 with zipfile.ZipFile(archive) as z:
  assert z.testzip() is None
  for n,h in manifest['files'].items():assert hashlib.sha256(z.read(n)).hexdigest()==h,(seq,n)
 for m in maps:assert (folder/f'sources/commons/maps/{m}/final.md').read_bytes()==(ROOT/f'commons/maps/{m}/final.md').read_bytes()
 report.append({'sequence':seq,'pilot':pilot,'halls':len(maps),'title':title,'zip':archive.relative_to(OUT).as_posix(),'zip_sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'files':len(manifest['files']),'source_files':len(expanded['included']),'bytes':archive.stat().st_size})
 print(seq,'writing packet verified',len(manifest['files']),'files',flush=True)
(OUT/'packages.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
# Replace the legacy exporter indexes so no packet asks for the former audit-only workflow.
pack.dump(PACKAGE/'index.json',report)
(PACKAGE/'index.md').write_text('# Encounter writing packets\n\n'+ '\n'.join(f'- [{r["sequence"]}]({r["sequence"]}/START_HERE.md): start {r["pilot"]}' for r in report)+'\n',encoding='utf-8')
(PACKAGE/'index.html').write_text('<!doctype html><html><meta charset="utf-8"><meta http-equiv="refresh" content="0;url=../index.html"><a href="../index.html">Current writing assignments</a></html>',encoding='utf-8')
print('All current manuscripts preserved; five writing packets ready.')
