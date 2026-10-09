from pathlib import Path
from datetime import datetime, timezone
import difflib, hashlib, html, json, re, shutil
import markdown
from bs4 import BeautifulSoup
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding="utf-8-sig")
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
add=json.loads(read(HERE/"additions.json"))
checks=[]
def check(name,ok):
    checks.append({"name":name,"passed":bool(ok)})
    if not ok:raise ValueError(name)
def render(text,prefix):
    soup=BeautifulSoup(markdown.markdown(text,extensions=["extra"]),"html.parser")
    for tag in soup.find_all(id=True):tag["id"]=prefix+"-"+tag["id"]
    for tag in soup.find_all("a",href=True):
        if tag["href"].startswith("#"):tag["href"]="#"+prefix+"-"+tag["href"][1:]
    return str(soup)
paths={"trace":"commons/maps/Point_Trace/final.md","preface":"doc/book/preface.md","afterword":"doc/book/afterword-qfep.md"}
old={k:read(HERE/"before"/p) for k,p in paths.items()}
new={k:read(ROOT/p) for k,p in paths.items()}
trace_back=new["trace"].replace(add["trace"]+"\n\n", "").replace(add["trace_note"], "").rstrip()
check("Trace preserves all earlier prose",trace_back==old["trace"].rstrip())
preface_back=new["preface"].replace(add["preface"]+"\n\n", "").replace(add["preface_note"], "").replace("revised 28 September 2026","revised 24 September 2026").rstrip()
check("Preface preserves earlier prose apart from date",preface_back==old["preface"].rstrip())
afterword_back=new["afterword"].replace(add["afterword"]+"\n\n", "").replace(add["afterword_notes"]+"\n\n", "").replace("Working draft, revised 28 September 2026.","Working draft, 23 September 2026.")
check("Afterword preserves earlier prose apart from date",afterword_back==old["afterword"])
for k,p in paths.items():
    defs=re.findall(r"^\[\^([^\]]+)\]:",new[k],re.M)
    refs=re.findall(r"\[\^([^\]]+)\](?!:)",new[k])
    check(k+" footnotes unique and complete",len(defs)==len(set(defs)) and set(refs)==set(defs))
    (HERE/(k+".diff")).write_text("".join(difflib.unified_diff(old[k].splitlines(True),new[k].splitlines(True),fromfile="before/"+p,tofile="current/"+p)),encoding="utf-8")
    (HERE/(k+".current.md")).write_text(new[k],encoding="utf-8")
check("Trace code and encounter anchors preserved",re.findall(r"```.*?```|<!--.*?-->",old["trace"],re.S)==re.findall(r"```.*?```|<!--.*?-->",new["trace"],re.S))
baseline=json.loads(read(HERE/"baseline.json"))
for p in ["commons/maps/Point_Trace/map_data.json","commons/maps/Point_Line_Grid/final.md","commons/maps/sequences/primitives.json"]:
    check("Preserved "+p,sha(ROOT/p)==baseline[p])
core=json.loads(read(ROOT/"commons/data/museum_core_encounters.json"))
before=json.loads(read(HERE/"before/commons/data/museum_core_encounters.json"))
entry=core["rooms"]["Point_Trace"]
check("Catalogue hash matches final.md",entry["text_sha256"]==sha(ROOT/paths["trace"]))
for k in ["text_sha256","local_review"]:before["rooms"]["Point_Trace"][k]=entry[k]
check("Only Trace hash and review changed in catalogue",core==before)
manifest=json.loads(read(ROOT/"doc/book/captures/primitives/primitives-book.manifest.json"))
check("All current Primitives sources match capture",all(sha(ROOT/r["path"])==r["sha256"] for r in manifest["maps"]))
check("Capture hash matches",sha(ROOT/"doc/book/captures/primitives/primitives-book.md")==manifest["output_sha256"])
for name in ["primitives-book.md","primitives-book.manifest.json"]:shutil.copy2(ROOT/"doc/book/captures/primitives"/name,HERE/name)
css=re.search(r"<style>(.*?)</style>",read(ROOT/"doc/book/iterations/2026-09-28-nails-the-next-choice/index.html"),re.S).group(1)
css+="\n.footnote{font-size:.85em;overflow-wrap:anywhere}.footnote p{margin-bottom:10px}.addition{border-left:3px solid #a06a65;padding-left:24px}.reading{scroll-margin-top:30px}nav{flex-wrap:wrap}"
intro="A tool carries earlier purposes into connections its original task did not anticipate. A brief passage in Trace opens the question; the project framing gives it more room."
trace_addition_html=render(add['trace']+'\n\n'+add['trace_note'],'addition')
preface_addition_html=render(add['preface']+'\n\n'+add['preface_note'],'preface-excerpt')
afterword_addition_html=render(add['afterword']+'\n\n'+add['afterword_notes'],'afterword-excerpt')
page=f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Trace — A tool has other futures</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">POINT TRACE · PROJECT FRAMING · 28 SEPTEMBER 2026</p><h1>A tool has other futures.</h1><p>{intro}</p><nav><a href="#addition">The Trace addition</a><a href="#project">The wider argument</a><a href="#reading">Full Trace chapter</a><a href="#changes">What changed</a><a href="#sources">Sources</a></nav></header>
<section class="reading" id="addition"><p class="eyebrow">ADDED NEAR THE EXIT OF TRACE</p><div class="addition">{trace_addition_html}</div><p><a href="#reading">Read in the chapter ↓</a></p></section>
<section class="reading" id="project"><p class="eyebrow">PROJECT PREFACE · NEW PASSAGE</p>{preface_addition_html}<p class="eyebrow">PROJECT AFTERWORD · NEW SECTION</p>{afterword_addition_html}<p><a href="/book-review/doc/book/iterations/2026-09-23-book-frame/index.html#preface">Read the full preface and afterword</a></p></section>
<article class="reading" id="reading"><p class="eyebrow">CURRENT POINT_TRACE FINAL.MD · <a href="/compose/sources?map=Point_Trace&amp;doc=final">READ AND COMMENT</a></p>{render(new['trace'],'trace')}</article>
<section id="changes">{render(read(HERE/'DECISIONS.md'),'decisions')}<p><a href="trace.diff">Exact Trace difference</a> · <a href="preface.diff">Exact preface difference</a> · <a href="afterword.diff">Exact afterword difference</a></p><p><a href="trace.current.md">Trace Markdown</a> · <a href="primitives-book.md">Current Primitives capture</a> · <a href="primitives-book.manifest.json">Capture source record</a> · <a href="checks.json">Publication checks</a></p></section>
<section id="sources">{render(read(HERE/'SOURCES.md'),'sources')}</section><footer><p>Next in the continuing Colour pass: <a href="/compose/sources?map=Color_Rainbow&amp;doc=final">Color_Rainbow</a>.</p></footer></main></body></html>"""
soup=BeautifulSoup(page,"html.parser")
ids=[t["id"] for t in soup.find_all(id=True)]
check("Reading edition IDs unique",len(ids)==len(set(ids)))
check("Reading edition internal links resolve",all(a["href"][1:] in ids for a in soup.find_all("a",href=True) if a["href"].startswith("#")))
check("No raw footnote notation in reading page",not re.search(r"\[\^[^\]]+\]",soup.get_text()))
(HERE/"index.html").write_text(page,encoding="utf-8")
(HERE/"checks.json").write_text(json.dumps({"passed":True,"generated_at":datetime.now(timezone.utc).isoformat(),"checks":checks,"words_added":{k:len(new[k].split())-len(old[k].split()) for k in paths},"scope":"Manuscript additions, preservation, footnotes and current capture. No runtime or headset replay."},ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(str(len(checks))+" publication checks passed; "+str(len(manifest['maps']))+" captured halls.")
