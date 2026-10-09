from pathlib import Path
import difflib,hashlib,json,re
import markdown
H=Path(__file__).resolve().parent;R=H.parents[3]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:json.loads(p.read_text(encoding="utf-8-sig"))
base=read(H/"baseline.json");names=["Change_Intro","Flow_Field"]
changed={"tools/export_book_captures.py","commons/data/museum_core_encounters.json","doc/book/iterations/WORKING.md"}|{f"commons/maps/{n}/final.md" for n in names}
preserved={rel:digest for rel,digest in base.items() if rel not in changed}
for rel,digest in preserved.items():assert sha(R/rel)==digest,rel
(H/"preserved.json").write_text(json.dumps(preserved,indent=2)+"\n",encoding="utf-8")
protected={"Change_Intro":["Both reports describe this same curve. They answer questions at different scales.","The heights do not become slopes by changing their label: the calculation changes.","the data retained something true while leaving out a relation.","One height has been asked to represent everything that happens across that width.","An address, a height, a width, an addition. The loop keeps doing the same small thing.","A familiar method has no entitlement to win every coarse comparison.","Zero net change does not mean that nothing happened.","What would a report of zero leave out of your journey?"],"Flow_Field":["That position becomes the address used by its next update. The loop starts making its own route through the field.","The line suggests a crossing the update did not make.","A world can provide a return route and still contain a seam."]}
core=read(R/"commons/data/museum_core_encounters.json");expected=read(H/"before/commons/data/museum_core_encounters.json");roles=read(R/"commons/data/artifact_roles.json")
def render(text,prefix):
 text=re.sub(r"<!--\s*@[^>]*-->","",text)
 out=markdown.markdown(text,extensions=["fenced_code","footnotes","tables"])
 out=re.sub(r'id="([^"]+)"',lambda m:'id="'+prefix+m[1]+'"',out)
 return re.sub(r'href="#([^"]+)"',lambda m:'href="#'+prefix+m[1]+'"',out)
def diff(rel,filename):
 old=(H/"before"/rel).read_text(encoding="utf-8");now=(R/rel).read_text(encoding="utf-8")
 (H/filename).write_text("".join(difflib.unified_diff(old.splitlines(True),now.splitlines(True),fromfile="before/"+rel,tofile="current/"+rel)),encoding="utf-8")
 return old,now
parts=[];counts=[];code_count=0
for name in names:
 rel=f"commons/maps/{name}/final.md";old,now=diff(rel,name+".diff")
 assert sha(H/"before"/rel)==base[rel]
 markers=lambda s:re.findall(r"<!-- @([A-Za-z_0-9]+) -->",s)
 assert markers(old)==markers(now)==core["rooms"][name]["primary_tokens"]==roles["order"][name]["primary"]
 blocks=lambda s:re.findall(chr(96)*3+r"[^\n]*\n(.*?)"+chr(96)*3,s,re.S)
 assert blocks(old)==blocks(now);code_count+=len(blocks(now))
 for quote in protected[name]:assert quote in old and quote in now,quote
 expected["rooms"][name]["text_sha256"]=sha(R/rel)
 counts.append({"map":name,"before_words":len(old.split()),"after_words":len(now.split())})
 note={"Change_Intro":"A worn fabric has a receiver. The slope suggests a possible body. The bridge remembers the line and its missing detour.","Flow_Field":"Delta introduces the clock; the accumulated position chooses the next sample. A short noise handhold keeps the beginner in the room."}[name]
 parts.append('<section id="'+name+'"><h2>'+name.replace('_',' ')+'</h2><p>'+note+'</p><nav><a href="/compose/sources?map='+name+'&amp;doc=final">Read and comment</a><a href="/long-museum/encounters?map='+name+'">Encounter map</a><a href="'+name+'.diff">Exact text diff</a></nav><details><summary>Read the current chapter</summary><div class="reading">'+render(now,name+'-read-')+'</div></details><details><summary>Compare original and current</summary><div class="compare"><article><h3>Original</h3>'+render(old,name+'-old-')+'</article><article><h3>Current</h3>'+render(now,name+'-new-')+'</article></div></details></section>')
assert core==expected,"Unexpected core change"
diff("tools/export_book_captures.py","capture-exporter.diff")
diff("commons/data/museum_core_encounters.json","core-records.diff")
manifest=read(H/"capture/change/change-book.manifest.json");capture=(H/"capture/change/change-book.md").read_text(encoding="utf-8")
assert sha(H/"capture/change/change-book.md")==manifest["output_sha256"]
assert re.findall(r"^## (.+)$",capture,re.M)==["Change Intro","Flow Field"]
for source in manifest["maps"]:assert sha(R/source["path"])==source["sha256"]
assert "#### Measure a change" in capture and "#### Add contributions" in capture
report={"scope":"Two manuscripts and the capture exporter; focused source reading, no new Godot or headset run","protected_passages":sum(map(len,protected.values())),"code_blocks_preserved":code_count,"encounter_order_preserved":True,"baseline_inputs_preserved":len(preserved),"core_changes":"Only two text hashes","capture_hall_headings":2,"exporter_regression_tests_passed":4,"chapter_counts":counts}
(H/"verification.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
style=(R/"doc/book/iterations/2026-09-21-point-one-return/index.html").read_text(encoding="utf-8").split("<style>")[1].split("</style>")[0]
style+='section{margin:42px 0;border-top:1px solid var(--line);padding-top:24px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:18px}.pair figure{margin:0}.pair img{width:100%}.compare{align-items:start}@media(max-width:760px){.pair{grid-template-columns:1fr}}'
page="""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Change — the sum has begun to move</title><style>"""+style+"""</style></head><body><main><div class="eyebrow">Ada Research · Change return · 21 September 2026</div><h1>The sum has<br>begun to move.</h1><p class="intro">An endpoint remembers too little. An accumulated position becomes the next question. Two small connections let the earlier rooms return.</p><p>This is a light revision of two developed chapters. The four primary encounters, supporting works and mathematics stay. The changes name the return to the line, let the clock enter Flow, and give the carried fabric a place on the dress.</p><nav><a href="#Change_Intro">Change Intro</a><a href="#Flow_Field">Flow Field</a><a href="capture/change/change-book.md">Fresh text for review</a><a href="SUMMARY.md">Findings and decisions</a><a href="verification.json">Checks</a></nav><section><h2>The connections, made explicit</h2><blockquote>Back at the line, <code>b - a</code> gave the same answer for a direct walk and a detour. Here we ask about height: the final height minus the initial height.</blockquote><blockquote>The sum has begun to move. At the accumulation bench, the loop added a height times a width. Here <code>direction * speed</code> is a velocity: how fast, and which way.</blockquote><p>The retained velocity arrow follows its own puck. It does not yet measure the visitor’s trace. Both that artifact and the two-slope terrain still stand in Change Intro, so the next encounter pass can develop existing work before adding halls.</p></section>"""+''.join(parts)+"""<section><h2>The existing bridge encounter</h2><div class="pair"><figure><a href="../2026-09-19-change-review/bridge/museum/museum-predict.png"><img src="../2026-09-19-change-review/bridge/museum/museum-predict.png" alt="Earlier Godot museum capture before requesting the bridge comparison"></a><figcaption>Predict from the arch and signed strips.</figcaption></figure><figure><a href="../2026-09-19-change-review/bridge/museum/museum-compared.png"><img src="../2026-09-19-change-review/bridge/museum/museum-compared.png" alt="Earlier Godot museum capture after requesting the bridge comparison"></a><figcaption>Then ask for the endpoint comparison.</figcaption></figure></div><p class="note">Actual museum captures from 19 September, showing two states of the same encounter. These are dated context, not new before/after images of today’s prose pass. No new museum or headset run is claimed.</p></section><section><h2>Keep the next step concrete</h2><p>A visitor’s measured velocity would be a worthwhile bodily return. It needs a real connection from timestamped movement to the arrow. A differently shaped bridge can reuse the existing curve family. Neither is claimed as implemented in this revision.</p><p>The earlier Tiling configuration, surround and sightline repairs remain pending. Completing this reading pass does not close those spatial tasks.</p><nav><a href="../../review-feedback/2026-09-21/change/01-supplied-review.txt">Supplied Change review</a><a href="../../review-feedback/2026-09-21/tiling/01-supplied-review.txt">Pending Tiling review</a><a href="capture-exporter.diff">Capture heading repair</a><a href="capture/change/change-book.manifest.json">Captured source versions</a></nav></section></main></body></html>"""
(H/"index.html").write_text(page,encoding="utf-8")
print(json.dumps(report,indent=2))
