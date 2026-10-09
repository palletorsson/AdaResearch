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
for name,digest in baseline.items():assert sha(ROOT/name)==digest,name
tutorial=read(ROOT/"commons/maps/Point_Zero/tutorial.md")
blocks=re.findall(r"```gdscript\n(.*?)```",tutorial,re.S)
assert len(blocks)==3
assert blocks[1].strip()==read(ROOT/"doc/book/studies/point-zero/hello_world.gd").strip()
assert sha(ROOT/"doc/book/studies/day-zero/base.tscn")==sha(ROOT/"doc/book/studies/point-zero/base.tscn")
native=json.loads(read(OUT/"native-verification.json"))
assert native["passed"] and all(c["passed"] for c in native["checks"])
packages={}
for name in ["point-zero","point-one"]:
    source=ROOT/"doc/book/studies"/name;dest=OUT/name
    dest.mkdir(exist_ok=True)
    files=sorted(f for f in source.iterdir() if f.is_file())
    for f in files:shutil.copy2(f,dest/f.name)
    archive=OUT/(name+"-study.zip")
    with zipfile.ZipFile(archive,"w",compression=zipfile.ZIP_DEFLATED) as z:
        for f in files:z.write(f,name+"/"+f.name)
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        for f in files:assert z.read(name+"/"+f.name)==f.read_bytes()
    for f in source.glob("*.tscn"):
        for dependency in re.findall(r'path="res://([^"]+)"',read(f)):assert (dest/dependency).is_file(),dependency
    packages[name]={"files":[f.name for f in files],"sha256":sha(archive)}
for hall in ["Point_Zero","Point_One"]:
    for name in ["tutorial","intent"]:
        shutil.copy2(ROOT/f"commons/maps/{hall}/{name}.md",OUT/f"{hall}.{name}.md")
shutil.copy2(ROOT/"commons/maps/Point_Zero/final.md",OUT/"Point_Zero.final.md")
shutil.copy2(ROOT/"commons/maps/Point_Zero/technical.md",OUT/"Point_Zero.technical.md")
diffs=[]
for f in (OUT/"before").rglob("*"):
    if not f.is_file():continue
    rel=f.relative_to(OUT/"before");current=ROOT/rel
    delta="".join(difflib.unified_diff(read(f).splitlines(True),read(current).splitlines(True),fromfile="before/"+rel.as_posix(),tofile=rel.as_posix()))
    if delta:
        dest=OUT/"diffs"/rel.parent/(rel.name+".diff");dest.parent.mkdir(parents=True,exist_ok=True)
        write(dest,delta);diffs.append((rel.as_posix(),dest.relative_to(OUT).as_posix()))
write(OUT/"Point_Zero.tutorial.diff","".join(difflib.unified_diff([],tutorial.splitlines(True),fromfile="/dev/null",tofile="commons/maps/Point_Zero/tutorial.md")))
css=re.search(r"<style>(.*?)</style>",read(ROOT/"doc/book/iterations/2026-09-29-point-one-read-then-make/index.html"),re.S).group(1)
css+=".button{display:inline-block;border:1px solid #c5c5b5;padding:10px 16px;text-decoration:none;margin-top:14px}pre{tab-size:4}"
def render(s,prefix,replacements=None):
    for a,b in (replacements or {}).items():s=s.replace(a,b)
    soup=BeautifulSoup(markdown.markdown(s,extensions=["extra"]),"html.parser")
    for node in soup.find_all(id=True):node["id"]=prefix+"-"+node["id"]
    for a in soup.find_all("a",href=True):
        if a["href"].startswith("#"):a["href"]="#"+prefix+"-"+a["href"][1:]
    return str(soup)
def page(title,body):return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+title+'</title><style>'+css+'</style></head><body><main>'+body+'</main></body></html>'
diff_links="".join('<li><a href="'+url+'">'+html.escape(label)+'</a></li>' for label,url in sorted(diffs))
dayzero="/book-review/doc/book/iterations/2026-09-23-book-frame/index.html#day-zero"
pages={}
pages["index.html"]=page("Point Zero | Hello, world",f"""
<header><p class="eyebrow">Point Zero · First tutorial · 29 September 2026</p>
<nav aria-label="Reading"><a href="reading.html#reading">Read the encounter</a><a href="{dayzero}">Day Zero · setup</a><a href="point-one.html#making">Next · Point One</a><a href="#changes">Editorial record</a></nav>
<a class="button" href="point-zero-study.zip" download>Download the working study</a></header>
<article class="reading" id="making">{render(tutorial,"lesson",{"../../../doc/book/studies/point-zero/README.md":"point-zero/README.md"})}</article>
<div class="turn-page"><p><a href="point-one.html#making">Continue to Point One →</a></p><p><a href="point-zero/hello_world.gd">Complete counter script</a> · <a href="point-zero/hello_world.tscn">Supplied scene</a></p></div>
<section class="editorial" id="changes"><details><summary>What this tutorial adds</summary>{render(read(OUT/"DECISIONS.md"),"decisions")}
<p><a href="Point_Zero.tutorial.md">Tutorial source</a> · <a href="Point_Zero.intent.md">Teaching agreement</a> · <a href="native-verification.json">{len(native["checks"])} native checks</a></p>
<ul>{diff_links}</ul><p class="meta">Main manuscripts and museum objects are unchanged. No learner or headset trial.</p></details></section>
""")
pages["reading.html"]=page("Point Zero | You arrive late",f"""
<header><p class="eyebrow">Point Zero · Encounter text</p><nav><a href="index.html#making">Hello-world tutorial</a><a href="{dayzero}">Day Zero</a></nav></header>
<article class="reading" id="reading">{render(read(ROOT/"commons/maps/Point_Zero/final.md"),"reading")}</article>
<div class="turn-page"><a href="index.html#making">Make a greeting and a counter →</a></div>
""")
pages["point-one.html"]=page("Point One | Follow the point",f"""
<header><p class="eyebrow">Point One · Follow the corridor</p><nav><a href="index.html#making">← Point Zero tutorial</a><a href="/book-review/doc/book/iterations/2026-09-29-point-one-coordinate-lineage/index.html#reading">Read Point One</a></nav>
<a class="button" href="point-one-study.zip" download>Download the Point One study</a></header>
<article class="reading" id="making">{render(read(ROOT/"commons/maps/Point_One/tutorial.md"),"point-one",{
"../../../doc/book/studies/point-one/README.md":"point-one/README.md",
"../../../doc/book/studies/point-one/CONSTRUCTION.md":"/book-review/doc/book/iterations/2026-09-29-point-one-coordinate-lineage/construction.html",
"../Point_Zero/tutorial.md":"index.html#making"
})}</article>
<div class="turn-page"><p><a href="corridor-order/DECISIONS.md">How the tutorial follows the corridor</a> · <a href="corridor-order/native-verification.json">Study checks</a></p></div>
""")
pages["lineage.html"]=page("The opening tutorial lineage", '<header><p class="eyebrow">Teaching agreement · 29 September 2026</p><nav><a href="point-one.html#making">Return to Point One</a></nav></header><article class="reading" id="lineage">'+render(read(ROOT/"doc/book/TUTORIAL_LINEAGE.md"),"lineage",{"tutorial-lineage/curriculum.json":"/book-review/doc/book/iterations/2026-09-29-tutorial-lineage/curriculum.json"})+'</article>')
pages["point-one.html"]=pages["point-one.html"].replace('<a href="corridor-order/DECISIONS.md">', '<a href="/tutorial-lineage">Whole-spine lineage tree</a> · <a href="lineage.html#lineage">The opening lineage</a> · <a href="corridor-order/DECISIONS.md">')
for name,body in pages.items():write(OUT/name,body)
for name,body in pages.items():
    soup=BeautifulSoup(body,"html.parser");ids=[e["id"] for e in soup.find_all(id=True)]
    assert len(ids)==len(set(ids)),name
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
manifest=json.loads(read(ROOT/"doc/book/captures/primitives/primitives-book.manifest.json"))
assert all(sha(ROOT/m["path"])==m["sha256"] for m in manifest["maps"])
frame=json.loads(read(ROOT/"doc/book/iterations/2026-09-23-book-frame/manifest.json"))
assert frame["sources_sha256"]["doc/book/STUDENT_TOOLBOX.md"]==sha(ROOT/"doc/book/STUDENT_TOOLBOX.md")
report={"passed":True,"main_manuscripts_museum_sources_and_point_one_code_unchanged":True,"study_uses_unchanged_day_zero_base":True,"actual_lesson_code_matches_complete_download":True,"native_checks":len(native["checks"]),"packages":packages,"html_anchors_and_local_links_valid":True,"primitives_capture_remains_current":True,"framing_toolbox_current":True,"scope":"Native execution and source/publication checks; no learner or headset trial."}
write(OUT/"verification.json",json.dumps(report,indent=2)+"\n")
print(json.dumps({"passed":True,"native_checks":len(native["checks"]),"pages":list(pages),"packages":list(packages)}))
