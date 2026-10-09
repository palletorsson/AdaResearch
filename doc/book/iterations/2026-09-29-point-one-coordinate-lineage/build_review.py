from pathlib import Path
import difflib,hashlib,html,json,re,shutil,zipfile
from urllib.parse import urlsplit,unquote
import markdown
from bs4 import BeautifulSoup
ROOT=Path(__file__).resolve().parents[4];OUT=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding="utf-8-sig")
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
write=lambda p,s:p.write_bytes(s.encode("utf-8"))
baseline=json.loads(read(OUT/"baseline.json"))
for f,digest in baseline.items():assert sha(ROOT/f)==digest,f
old=read(OUT/"before/commons/maps/Point_One/final.md")
final=read(ROOT/"commons/maps/Point_One/final.md")
without_note=lambda s:re.sub(r"^\[\^point-one-code\]:.*$","",s,flags=re.M)
assert without_note(old)==without_note(final)
tutorial=read(ROOT/"commons/maps/Point_One/tutorial.md")
blocks=re.findall(r"```gdscript\n(.*?)```",tutorial,re.S)
assert len(blocks)==3
assert blocks[-1].strip()==read(ROOT/"doc/book/studies/point-one/points.gd").strip()
assert all(forbidden not in tutorial for forbidden in ["SphereMesh.new","StaticBody3D","to_local(","catch_radius","GRID_SIZE","%.2f"])
assert "\\n| Point_Zero" not in read(ROOT/"doc/book/STUDENT_TOOLBOX.md")
assert sha(ROOT/"doc/book/studies/point-one/base.tscn")==sha(ROOT/"doc/book/studies/day-zero/base.tscn")
for name in ["final","tutorial","intent","technical"]:
    shutil.copy2(ROOT/f"commons/maps/Point_One/{name}.md",OUT/f"Point_One.{name}.md")
study=ROOT/"doc/book/studies/point-one"
(OUT/"study").mkdir(exist_ok=True)
files=sorted(p for p in study.iterdir() if p.is_file())
for f in files:shutil.copy2(f,OUT/"study"/f.name)
with zipfile.ZipFile(OUT/"point-one-study.zip","w",compression=zipfile.ZIP_DEFLATED) as z:
    for f in files:z.write(f,"point-one/"+f.name)
with zipfile.ZipFile(OUT/"point-one-study.zip") as z:
    assert z.testzip() is None
    for f in files:assert z.read("point-one/"+f.name)==f.read_bytes()
for f in study.glob("*.tscn"):
    for dependency in re.findall(r'path="res://([^"]+)"',read(f)):assert (study/dependency).is_file(),dependency
for name in ["primitives-book.md","primitives-book.manifest.json"]:shutil.copy2(ROOT/"doc/book/captures/primitives"/name,OUT/name)
manifest=json.loads(read(OUT/"primitives-book.manifest.json"))
assert all(sha(ROOT/m["path"])==m["sha256"] for m in manifest["maps"])
assert manifest["output_sha256"]==sha(OUT/"primitives-book.md")
cat=json.loads(read(ROOT/"commons/data/museum_core_encounters.json"))
prior_cat=json.loads(read(OUT/"before/commons/data/museum_core_encounters.json"))
assert cat["rooms"]["Point_One"]["text_sha256"]==sha(ROOT/"commons/maps/Point_One/final.md")
for key in ["text_sha256","local_review"]:prior_cat["rooms"]["Point_One"][key]=cat["rooms"]["Point_One"][key]
assert cat==prior_cat
diffs=[]
for f in sorted((OUT/"before").rglob("*")):
    if not f.is_file():continue
    rel=f.relative_to(OUT/"before");current=ROOT/rel
    if current.is_file():
        delta="".join(difflib.unified_diff(read(f).splitlines(True),read(current).splitlines(True),fromfile="before/"+rel.as_posix(),tofile=rel.as_posix()))
        if delta:
            dest=OUT/"diffs"/rel.parent/(rel.name+".diff");dest.parent.mkdir(parents=True,exist_ok=True)
            write(dest,delta);diffs.append((rel.as_posix(),dest.relative_to(OUT).as_posix()))
prior=ROOT/"doc/book/iterations/2026-09-29-point-one-read-then-make/index.html"
css=re.search(r"<style>(.*?)</style>",read(prior),re.S).group(1)
css+="table{border-collapse:collapse;font:14px/1.5 system-ui,sans-serif}td,th{border-bottom:1px solid #d4d1c7;padding:12px;text-align:left;vertical-align:top}table{display:block;overflow:auto}.button{display:inline-block;border:1px solid #c5c5b5;padding:10px 16px;text-decoration:none;margin-top:12px}"
def render(text,prefix,replacements=None):
    for old,new in (replacements or {}).items():text=text.replace(old,new)
    soup=BeautifulSoup(markdown.markdown(text,extensions=["extra"]),"html.parser")
    for t in soup.find_all(id=True):t["id"]=prefix+"-"+t["id"]
    for a in soup.find_all("a",href=True):
        if a["href"].startswith("#"):a["href"]="#"+prefix+"-"+a["href"][1:]
    return str(soup)
def page(title,body):return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+title+'</title><style>'+css+'</style></head><body><main>'+body+'</main></body></html>'
diff_links="".join('<li><a href="'+url+'">'+html.escape(label)+'</a></li>' for label,url in diffs)
dayzero="/book-review/doc/book/iterations/2026-09-23-book-frame/index.html#day-zero"
pages={}
pages["index.html"]=page("Point One | Position before connection",f"""
<header><p class="eyebrow">Point One · 29 September 2026</p><h1>A position to carry forward</h1><p>The encounter keeps its bodily and critical differences. The first making passage selects coordinates and leaves us with two positions.</p>
<nav aria-label="Reading"><a href="#reading">Main text</a><a href="making.html">First tutorial</a><a href="#agreement">The hall agreement</a><a href="{dayzero}">Day Zero</a></nav></header>
<article class="reading" id="reading">{render(final,"reading")}</article>
<div class="turn-page"><a href="making.html">Make the first arrangement →</a><p>The supplied scene contains the markers and guides. Your script chooses where the markers appear.</p></div>
<article id="agreement">{render(read(ROOT/"commons/maps/Point_One/intent.md"),"agreement")}
<details><summary>What changed and what stays for later</summary>{render(read(OUT/"DECISIONS.md"),"decisions")}<ul>{diff_links}</ul><p><a href="primitives-book.md">Current Primitives capture</a> · <a href="native-verification.json">Native study checks</a></p></details></article>
""")
pages["making.html"]=page("Point One | Coordinates, then two points",f"""
<header><p class="eyebrow">Point One · First making passage</p>
<nav aria-label="Reading"><a href="index.html#reading">← Read the encounter</a><a href="index.html#agreement">What this hall carries</a><a href="{dayzero}">Day Zero</a></nav>
<a class="button" href="point-one-study.zip" download>Download the working study</a></header>
<article class="reading" id="making">{render(tutorial,"making",{"../../../doc/book/studies/point-one/README.md":"study/README.md","../../../doc/book/studies/point-one/CONSTRUCTION.md":"construction.html"})}</article>
<div class="turn-page"><p><a href="study/points.gd">Complete short script</a> · <a href="study/coordinates.tscn">Supplied coordinate scene</a> · <a href="construction.html">Optional construction study</a></p><p><a href="index.html#reading">Return to the encounter →</a></p>
<p class="meta">Actual lesson snippets and coordinate variations pass 28 native Godot checks. No learner or headset trial is claimed. The next Line tutorial still needs to be rebuilt around the two positions.</p></div>
""")
pages["construction.html"]=page("Point One | Optional construction",f"""
<header><p class="eyebrow">Point One · Retained further study</p><p>Earlier construction material, kept for source inspection. This is separate from the first coordinate lesson; its three-condition scene is study.tscn.</p><nav><a href="making.html">← First tutorial</a><a href="point-one-study.zip" download>Download both studies</a></nav></header>
<article class="reading">{render(read(study/"CONSTRUCTION.md"),"construction",{"[the Point One study](README.md)":"[the Point One study](study/README.md)","[Day Zero](DAY_ZERO.md)":"[Day Zero]("+dayzero+")"})}</article>
""")
for name,body in pages.items():write(OUT/name,body)
for name,body in pages.items():
    soup=BeautifulSoup(body,"html.parser")
    ids=[n["id"] for n in soup.find_all(id=True)];assert len(ids)==len(set(ids)),name
    assert not soup.find("script")
    for a in soup.find_all("a",href=True):
        parts=urlsplit(a["href"])
        if parts.scheme or parts.netloc:continue
        if a["href"].startswith("#"):assert parts.fragment in ids,(name,a["href"]);continue
        if parts.path.startswith("/book-review/"):target=ROOT/unquote(parts.path[len("/book-review/"):])
        elif parts.path.startswith("/"):continue
        else:target=OUT/unquote(parts.path)
        assert target.is_file(),(name,target)
        if parts.fragment and target.suffix==".html":assert BeautifulSoup(read(target),"html.parser").find(id=parts.fragment),(name,a["href"])
native=json.loads(read(OUT/"native-verification.json"))
assert native["passed"] and len(native["checks"])==28
assert all(c["passed"] for c in native["checks"])
report={"passed":True,"main_prose_unchanged_except_making_reference_footnote":True,"map_and_production_hashes_unchanged":True,"previous_optional_study_unchanged":True,"lesson_code_matches_download":True,"lesson_blocks":len(blocks),"native_checks":len(native["checks"]),"zip_sha256":sha(OUT/"point-one-study.zip"),"archive_files":[f.name for f in files],"capture_current":True,"local_links_and_anchors_valid":True,"scope":"Source, native execution and publication. No museum spatial, rendered browser, headset or learner trial."}
write(OUT/"verification.json",json.dumps(report,indent=2)+"\n")
print(json.dumps({"passed":True,"native_checks":28,"pages":list(pages),"archive_files":len(files),"diffs":len(diffs)}))
