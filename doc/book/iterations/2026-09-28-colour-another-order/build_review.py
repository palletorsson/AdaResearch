from pathlib import Path
import difflib,hashlib,json,re,shutil,html
import markdown
from PIL import Image
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding="utf-8-sig")
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
render=lambda s:markdown.markdown(s,extensions=["fenced_code","footnotes","tables"])
checks=[]
def check(name,ok):
 checks.append({"name":name,"passed":bool(ok)})
 assert ok,name
changed={"commons/maps/Color_Context_Placed/final.md","commons/maps/Color_Context_Placed/tutorial.md","commons/maps/Color_Context_Placed/field_notes.md","commons/data/museum_core_encounters.json"}
for name,digest in json.loads(read(HERE/"baseline.json")).items():
 if name not in changed:check("Preserved "+name,sha(ROOT/name)==digest)
rel=Path("commons/maps/Color_Context_Placed/final.md");old=read(HERE/"before"/rel);new=read(ROOT/rel)
changes=json.loads(read(HERE/"changes.json"));expected=old
for change in changes:expected=expected.replace(change["before"],change["after"])
check("Only the four recorded passage changes",expected==new and len(changes)==4)
check("All three code excerpts preserved",re.findall(r"```gdscript.*?```",old,re.S)==re.findall(r"```gdscript.*?```",new,re.S) and new.count("```gdscript")==3)
check("Both primary encounters preserved",re.findall(r"<!--.*?-->",old)==re.findall(r"<!--.*?-->",new))
check("Gallery encounter and ending preserved verbatim",old.split("<!-- @color_dna_stack -->")[1]==new.split("<!-- @color_dna_stack -->")[1])
for para in old.split("\n\n"):
 if para.startswith("Colour is deeply scientific"):check("Scientific and associative passage preserved",para in new)
images=lambda s:re.findall(r"!\[[^\]]*\]\(([^)]+)\)",s)
check("Book figures unchanged",images(old)==images(new))
for path in images(new):
 with Image.open(ROOT/path.removeprefix("/book-review/")) as im:im.verify()
 check("Native figure readable "+path,True)
check("Historical source note preserved",old.split("[^bauhaus]:")[1]==new.split("[^bauhaus]:")[1])
core=json.loads(read(ROOT/"commons/data/museum_core_encounters.json"));before=json.loads(read(HERE/"before/commons/data/museum_core_encounters.json"));entry=core["rooms"]["Color_Context_Placed"]
check("Current text hash",entry["text_sha256"]==sha(ROOT/rel))
for key in ["text_sha256","local_review"]:before["rooms"]["Color_Context_Placed"][key]=entry[key]
check("Rest of catalogue preserved",before==core)
manifest=json.loads(read(ROOT/"doc/book/captures/color/color-book.manifest.json"))
check("Eight current chapter sources",len(manifest["maps"])==8 and all(sha(ROOT/r["path"])==r["sha256"] for r in manifest["maps"]))
check("Current capture output",sha(ROOT/"doc/book/captures/color/color-book.md")==manifest["output_sha256"])
for name in ["color-book.md","color-book.manifest.json"]:shutil.copy2(ROOT/"doc/book/captures/color"/name,HERE/name)
(HERE/"Color_Context_Placed.current.md").write_text(new,encoding="utf-8")
(HERE/"Color_Context_Placed.diff").write_text("".join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile="before/Color_Context_Placed/final.md",tofile="current/Color_Context_Placed/final.md")),encoding="utf-8")
rows="".join("<tr><td>"+render(c["before"])+"</td><td>"+render(c["after"])+"</td></tr>" for c in changes)
css=re.search(r"<style>(.*?)</style>",read(ROOT/"doc/book/iterations/2026-09-27-rotation-follow-a-turn/index.html"),re.S).group(1)
css+=".passages{width:100%;border-collapse:collapse;table-layout:fixed}.passages td,.passages th{width:50%;padding:20px;vertical-align:top;text-align:left;border-bottom:1px solid #d6cfc3}.passages th{font-family:system-ui;font-size:15px}.passages td:first-child{color:#6f665b}.passages td:last-child{background:#ecefe6}.source-note{font-size:16px;color:#62594e}@media(max-width:700px){.passages,.passages tbody,.passages tr,.passages td{display:block;width:100%}.passages thead{display:none}}"
page=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Another order among the parts</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">COLOR_CONTEXT_PLACED · 28 SEPTEMBER 2026 · COLOUR AND COMPOSITION</p><h1>Another order among the parts.</h1><p>The parts touch in one order; colour lets you gather them in another. A small writing pass follows that difference through the existing columns.</p><nav><a href="#reading">Read the chapter</a><a href="#changes">The four changes</a><a href="#decisions">Decisions and evidence</a><a href="color-book.md">Full Colour capture</a></nav></header>
<article class="reading" id="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map=Color_Context_Placed&amp;doc=final">READ AND COMMENT</a></p>{render(new)}</article>
<section id="changes"><h2>Four passages, beside their originals</h2><p>{len(old.split())} → {len(new.split())} words, including code, captions and source note. <a href="Color_Context_Placed.diff">Exact text diff</a> · <a href="Color_Context_Placed.current.md">Current Markdown</a></p><table class="passages"><thead><tr><th>Before this pass</th><th>Current final.md</th></tr></thead><tbody>{rows}</tbody></table></section>
<section class="decisions" id="decisions">{render(read(HERE/"DECISIONS.md"))}<p><a href="source-comparison.json">Current source comparison</a> · <a href="/book-review/doc/book/iterations/2026-09-23-colour-gathering/report.json">Earlier native evidence, 23 September</a> · <a href="checks.json">Publication checks</a> · <a href="http-checks.json">Served-file checks</a> · <a href="color-book.manifest.json">Capture manifest</a></p></section>
<footer><p class="source-note">The museum images are the existing native views. Their source date remains 23 September; this page does not present them as fresh captures.</p><p>Previous: <a href="/book-review/doc/book/iterations/2026-09-28-disco-a-rule-in-time/index.html">A rule in time</a>. Next: <a href="/compose/sources?map=Color_Flashlight&amp;doc=final">What reaches the surface</a>.</p></footer>
</main></body></html>'''
(HERE/"index.html").write_text(page,encoding="utf-8")
(HERE/"checks.json").write_text(json.dumps({"passed":True,"checks":checks,"words":{"before":len(old.split()),"after":len(new.split())},"scope":"Four manuscript passages; source and figure preservation; current eight-hall capture. Existing native evidence retained with its original date; no runtime replay."},indent=2)+"\n",encoding="utf-8")
print(len(checks),"publication checks passed; words",len(old.split()),"->",len(new.split()))
