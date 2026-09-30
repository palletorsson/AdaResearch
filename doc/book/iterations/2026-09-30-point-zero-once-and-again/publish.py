"""Package the clarified Point Zero lesson, keeping its executable study unchanged."""
from pathlib import Path
import difflib, hashlib, html, json, re, shutil, zipfile
import markdown
from bs4 import BeautifulSoup

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
read = lambda p: p.read_text(encoding="utf-8-sig")
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
source = ROOT / "commons/maps/Point_Zero/tutorial.md"
tutorial = read(source)
old = read(OUT / "before/commons/maps/Point_Zero/tutorial.md")
study = ROOT / "doc/book/studies/point-zero"
study_tutorial = tutorial.replace("../../../doc/book/studies/point-zero/README.md", "README.md")
(study / "TUTORIAL.md").write_text(study_tutorial, encoding="utf-8")
blocks = lambda text: re.findall(r"```gdscript\n(.*?)```", text, re.S)
assert len(blocks(tutorial)) == 3 and blocks(old) == blocks(tutorial)
assert blocks(tutorial)[1].strip() == read(study / "hello_world.gd").strip()
for path, digest in json.loads(read(OUT / "baseline.json")).items():
    assert sha(ROOT / path) == digest, path

diffs = []
for before in (OUT / "before").rglob("*"):
    if not before.is_file():
        continue
    rel = before.relative_to(OUT / "before")
    current = ROOT / rel
    dest = OUT / "after" / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(current, dest)
    diffs.extend(difflib.unified_diff(read(before).splitlines(True), read(current).splitlines(True),
                                   fromfile="before/" + rel.as_posix(), tofile="after/" + rel.as_posix()))
(OUT / "changes.diff").write_text("".join(diffs), encoding="utf-8")

files = ["project.godot", "base.tscn", "hello_world.tscn", "hello_world.gd", "README.md", "TUTORIAL.md"]
with zipfile.ZipFile(OUT / "point-zero-study.zip", "w", compression=zipfile.ZIP_DEFLATED) as archive:
    for filename in files:
        dest = OUT / "point-zero" / filename
        dest.parent.mkdir(exist_ok=True)
        shutil.copy2(study / filename, dest)
        archive.write(study / filename, "point-zero/" + filename)
with zipfile.ZipFile(OUT / "point-zero-study.zip") as archive:
    assert archive.testzip() is None
    assert all(archive.read("point-zero/" + f) == (study / f).read_bytes() for f in files)

def render(text, prefix):
    text = text.replace("../../../doc/book/studies/point-zero/README.md", "point-zero/README.md")
    text = re.sub(r"~~([^~\n]+)~~", r"<del>\1</del>", text)
    soup = BeautifulSoup(markdown.markdown(text, extensions=["extra"]), "html.parser")
    for node in soup.find_all(id=True):
        node["id"] = prefix + "-" + node["id"]
    for link in soup.find_all("a", href=True):
        if link["href"].startswith("#"):
            link["href"] = "#" + prefix + "-" + link["href"][1:]
    return str(soup)

css = re.search(r"<style>(.*?)</style>", read(OUT.parent / "2026-09-30-point-zero-room-to-read/index.html"), re.S).group(1)
nav = '<nav><a href="reading.html#reading">Read the encounter</a><a href="index.html#making">Make the counter</a><a href="point-zero-study.zip" download>Download the study</a><a href="/compose/sources?map=Point_Zero&amp;doc=tutorial">Current tutorial source</a></nav>'

def page(title, content):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>' + html.escape(title) + '</title><style>' + css + '</style></head><body><main>' + content + '</main></body></html>'

decisions = """# Once, or repeatedly?

30 September 2026. Applied the four useful tutorial clarifications from the supplied feedback.

- Name the separate Point Zero study and the actual HelloWorld root, with Greeting and Counter as its children. The Day Zero Welcome label remains hidden in this scene.
- Introduce a node as one part of a scene and explain extends Node3D as adding behaviour to a 3D node. Keep the explanation of function indentation.
- Name count as a variable that stores the changing number; distinguish its initial integer type from its persistence between calls.
- End the comparison with what each number counts and when it started.

Keep all three complete code examples and the experiment that moves the update from _process to _ready. The supplied code, scene and museum are unchanged. Keep the revised encounter manuscript intact: it can attend to late arrival while this companion teaches the operation.

The claimed http://../../../ link and outer backtick wrappers were not present in the actual source. Repository-relative links remain in the canonical tutorial; the downloadable copy uses its local README. The new review resolves that link to the packaged README.

The download contains the updated tutorial and README alongside unchanged executable files. Publication and archive checks are recorded here; no new runtime or learner test was needed for the prose-only changes.
"""
(OUT / "DECISIONS.md").write_text(decisions, encoding="utf-8")
comparison = '<details id="changes"><summary>Original beside revised</summary><div class="pair"><div><p class="eyebrow">Before</p>' + render(old, "before") + '</div><div><p class="eyebrow">Revised</p>' + render(tutorial, "after") + '</div></div><p><a href="changes.diff">Exact changes</a></p></details>'
index = page("Point Zero · once, or repeatedly?", '<header><p class="eyebrow">POINT ZERO · MAKING · 30 SEPTEMBER 2026</p><h1>Once, or repeatedly?</h1><p>The encounter begins with a world already running. Here we change when an instruction runs.</p>' + nav + '</header><article id="making">' + render(tutorial, "making") + '</article><article>' + render(decisions, "decisions") + '</article>' + comparison + '<footer><a href="verification.json">Publication checks</a> · <a href="reading.html#reading">Return to the encounter</a></footer>')
reading = page("Point Zero · you arrive late", '<header><p class="eyebrow">POINT ZERO · ENCOUNTER</p>' + nav + '</header><article id="reading">' + render(read(ROOT / "commons/maps/Point_Zero/final.md"), "reading") + '</article><footer><a href="index.html#making">Make a greeting and a counter</a></footer>')
for name, text in [("index.html", index), ("reading.html", reading)]:
    soup = BeautifulSoup(text, "html.parser")
    ids = [n["id"] for n in soup.find_all(id=True)]
    assert len(ids) == len(set(ids))
    assert all(a["href"][1:] in ids for a in soup.find_all("a", href=True) if a["href"].startswith("#"))
    assert not re.search(r"\[\^[^\]]+\]", soup.get_text())
    (OUT / name).write_text(text, encoding="utf-8")
(OUT / "verification.json").write_text(json.dumps({
    "three_code_examples_unchanged": True,
    "complete_counter_matches_supplied_script": True,
    "main_manuscript_map_and_executable_files_unchanged": True,
    "archive_matches_current_study": True,
    "html_anchors_and_footnotes_resolve": True,
    "archive_sha256": sha(OUT / "point-zero-study.zip"),
    "tutorial_sha256": sha(source),
    "scope": "Prose, packaging and publication. No new runtime, headset or learner test."
}, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"page": str(OUT / "index.html"), "archive": str(OUT / "point-zero-study.zip"), "complete_examples": 3, "main_text_unchanged": True}))
