from pathlib import Path
import difflib, hashlib, html, json, re, shutil, zipfile
from urllib.parse import unquote, urlsplit
import markdown
from bs4 import BeautifulSoup

ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding="utf-8-sig")
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
write=lambda p,s:p.write_bytes(s.encode("utf-8"))
base="/book-review/"+OUT.relative_to(ROOT).as_posix()
prior=ROOT/"doc/book/iterations/2026-09-29-point-one-read-then-make"
baseline=json.loads(read(OUT/"baseline.json"))
for f,digest in baseline.items():assert sha(ROOT/f)==digest,f

chapter=read(ROOT/"doc/book/day-zero.md")
tutorial=read(ROOT/"commons/maps/Point_One/tutorial.md")
preface=read(ROOT/"doc/book/preface.md")
assert (ROOT/"doc/book/studies/day-zero/base.tscn").read_bytes()==(ROOT/"doc/book/studies/point-one/base.tscn").read_bytes()
assert "ext_resource" not in read(ROOT/"doc/book/studies/day-zero/base.tscn")
assert read(ROOT/"doc/book/studies/day-zero/DAY_ZERO.md")==chapter
assert read(ROOT/"doc/book/studies/point-one/DAY_ZERO.md")==chapter
assert "F5" not in tutorial and "F6" not in tutorial and "Project Manager" not in tutorial

packages={}
for name,archive in [("day-zero","day-zero.zip"),("point-one","point-one-study.zip")]:
    source=ROOT/"doc/book/studies"/name
    dest=OUT/name
    dest.mkdir(exist_ok=True)
    files=sorted(p for p in source.iterdir() if p.is_file())
    for p in files:shutil.copy2(p,dest/p.name)
    with zipfile.ZipFile(OUT/archive,"w",compression=zipfile.ZIP_DEFLATED) as z:
        for p in files:z.write(p,name+"/"+p.name)
    with zipfile.ZipFile(OUT/archive) as z:
        assert z.testzip() is None
        for p in files:assert z.read(name+"/"+p.name)==p.read_bytes()
    for p in source.glob("*.tscn"):
        for dependency in re.findall(r'path="res://([^"]+)"',read(p)):
            assert (dest/dependency).is_file(),dependency
    packages[archive]={"sha256":sha(OUT/archive),"files":[p.name for p in files]}
shutil.copy2(ROOT/"doc/book/studies/day-zero/base.tscn",OUT/"base.tscn")
write(OUT/"day-zero.md",chapter)
write(OUT/"preface.md",preface)
write(OUT/"Point_One.tutorial.md",tutorial)

diffs=[]
for original in sorted((OUT/"before").rglob("*")):
    if not original.is_file():continue
    rel=original.relative_to(OUT/"before")
    target=ROOT/rel
    if not target.is_file():continue
    diff="".join(difflib.unified_diff(read(original).splitlines(True),read(target).splitlines(True),fromfile="before/"+rel.as_posix(),tofile=rel.as_posix()))
    if diff:
        dest=OUT/"diffs"/rel.parent/(rel.name+".diff")
        dest.parent.mkdir(parents=True,exist_ok=True)
        write(dest,diff)
        diffs.append((rel.as_posix(),dest.relative_to(OUT).as_posix()))

css=re.search(r"<style>(.*?)</style>",read(prior/"index.html"),re.S).group(1)
css+="""
.downloads{display:flex;flex-wrap:wrap;gap:12px;margin:24px 0}
.downloads a{border:1px solid #bfc4b5;border-radius:3px;padding:9px 14px;text-decoration:none;font:14px/1.4 system-ui,sans-serif}
.reading h2{font-size:1.35em;margin:2.3em 0 1em}
nav{flex-wrap:wrap;gap:12px} .editorial li{margin:.6em 0}
@media print{header,.downloads,.editorial,.turn-page{display:none}}
"""
def render(s,prefix,replacements=None):
    for old,new in (replacements or {}).items():s=s.replace(old,new)
    soup=BeautifulSoup(markdown.markdown(s,extensions=["extra"]),"html.parser")
    for t in soup.find_all(id=True):t["id"]=prefix+"-"+t["id"]
    for a in soup.find_all("a",href=True):
        if a["href"].startswith("#"):a["href"]="#"+prefix+"-"+a["href"][1:]
    return str(soup)
def page(title,body):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><main>'+body+'</main></body></html>'
frame="/book-review/doc/book/iterations/2026-09-23-book-frame/index.html"
reading_link="/book-review/doc/book/iterations/2026-09-29-point-one-read-then-make/index.html#reading"
diff_links="".join('<li><a href="'+html.escape(url)+'">'+html.escape(label)+'</a></li>' for label,url in diffs)
index=page("Day Zero | Hello, world",f"""
<header><p class="eyebrow">Ada Research · 29 September 2026 · Preface</p>
<p>Prepare the place in which the first point can happen.</p>
<nav aria-label="Reading routes"><a href="#reading">Day Zero</a><a href="{frame}#preface">Preface in context</a><a href="point-one-making.html">Point One · making</a><a href="#changes">Changes</a></nav>
<div class="downloads"><a href="day-zero.zip" download>Download the Day Zero project</a><a href="base.tscn" download="base.tscn">Download base.tscn</a></div></header>
<article class="reading" id="reading">{render(chapter,"chapter")}</article>
<div class="turn-page"><p><a href="/compose/sources?map=Point_Zero&amp;doc=final">Enter Point Zero →</a></p><p><a href="{reading_link}">Read Point One</a> · <a href="point-one-making.html">Then make the point</a></p></div>
<section class="editorial" id="changes"><details><summary>The change to the book</summary>
{render(read(OUT/"DECISIONS.md"),"decisions")}
<p><a href="{frame}#day-zero">Day Zero inside the book framing edition</a> · <a href="day-zero.md">Chapter source</a></p>
<ul>{diff_links}</ul>
<p><a href="day-zero-native.json">Six starter checks</a> · <a href="point-study-native.json">Fourteen Point One checks</a> · <a href="sources.json">Sources</a></p>
</details></section>
""")
making=page("Point One | Making after Day Zero",f"""
<header><p class="eyebrow">Point One · Making passage · Prepared in Day Zero</p>
<nav aria-label="Reading routes"><a href="{reading_link}">← Read the encounter</a><a href="index.html#reading">Day Zero</a></nav>
<div class="downloads"><a href="point-one-study.zip" download>Download the Point One study</a></div></header>
<article class="reading" id="making">{render(tutorial,"making",{
"../../../doc/book/studies/point-one/README.md":"point-one/README.md",
"../../../doc/book/day-zero.md":"index.html#reading"
})}</article>
<div class="turn-page"><p><a href="point-one/position.gd">Position script</a> · <a href="point-one/visible.gd">Visible script</a> · <a href="point-one/solid.gd">Solid script</a></p>
<p><a href="{reading_link}">Return to the encounter →</a></p>
<p class="meta">The study inherits the supplied base. Native construction and collision checks pass; this has not been trialled with a beginner or on a headset.</p></div>
""")
pages={"index.html":index,"point-one-making.html":making}
for name,s in pages.items():write(OUT/name,s)
for name,s in pages.items():
    soup=BeautifulSoup(s,"html.parser");ids=[x["id"] for x in soup.find_all(id=True)]
    assert len(ids)==len(set(ids)),name
    for a in soup.find_all("a",href=True):
        parts=urlsplit(a["href"])
        if parts.scheme or parts.netloc:continue
        if a["href"].startswith("#"):assert parts.fragment in ids,(name,a["href"]);continue
        if parts.path.startswith("/"):
            if parts.path.startswith("/book-review/"):
                path=ROOT/unquote(parts.path[len("/book-review/"):]);assert path.is_file(),path
            continue
        path=OUT/unquote(parts.path)
        assert path.is_file(),(name,path)
        if parts.fragment and path.suffix==".html":
            assert BeautifulSoup(read(path),"html.parser").find(id=parts.fragment),(name,a["href"])
    assert not soup.find("script"),name
native=[json.loads(read(OUT/f)) for f in ["day-zero-native.json","point-study-native.json"]]
assert all(r["passed"] and all(c["passed"] for c in r["checks"]) for r in native)
frame_manifest=json.loads(read(ROOT/"doc/book/iterations/2026-09-23-book-frame/manifest.json"))
assert "Day Zero" in frame_manifest["order"]
for f in ["doc/book/preface.md","doc/book/day-zero.md"]:
    assert frame_manifest["sources_sha256"][f]==sha(ROOT/f),f
verification={
"passed":True,
"native_checks":sum(len(r["checks"]) for r in native),
"native_evidence":"Existing runs from this Day Zero pass, not repeated during packaging.",
"preserved_sources_sha256":baseline,
"base_self_contained_and_identical_in_both_studies":True,
"archives_checked":packages,
"point_one_setup_instructions_moved_to_day_zero":True,
"framing_edition_current":True,
"html_anchors_and_local_links_valid":True,
"scope":"Native engine and publication verification. No browser visual, headset or learner trial.",
"url":"http://localhost:3003"+base+"/index.html#reading"
}
write(OUT/"verification.json",json.dumps(verification,indent=2,ensure_ascii=False)+"\n")
print(json.dumps({"passed":True,"native_checks":verification["native_checks"],"archives":list(packages),"diffs":len(diffs),"url":verification["url"]}))
