"""Package the local research page from supplied images and native Godot evidence."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib
import json
import shutil
import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
STUDY = ROOT / "doc/book/studies/open-structures"

references = {
    "reference-modules.png": "codex-clipboard-99856be1-fc89-444b-b4df-ffa01d2c2422.png",
    "reference-combinations.png": "codex-clipboard-91ba3efa-2cbb-4c33-a86f-9f02f570963e.png",
    "reference-five-forms.png": "codex-clipboard-02d5edfc-b9eb-4356-a6cd-b66c6d02ccb6.png",
}
for target, source in references.items():
    if not (HERE / target).exists():
        shutil.copy2(Path("C:/Users/palle/AppData/Local/Temp") / source, HERE / target)
for path in (STUDY / "captures").glob("*.png"):
    shutil.copy2(path, HERE / path.name)
for name in ["report.json"]:
    shutil.copy2(STUDY / "captures" / name, HERE / name)
for name in ["README.md", "TUTORIAL.md"]:
    shutil.copy2(STUDY / name, HERE / name)

css = """
:root{color-scheme:light;--paper:#f2f0e9;--ink:#232926;--muted:#59635c;--accent:#9d285c;--line:#d1d2c8}
*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:19px/1.7 Georgia,serif}
a{color:var(--accent);text-underline-offset:4px}a:hover{color:#651639}header{border-bottom:1px solid var(--line);padding:20px 5vw;font:13px/1.5 system-ui,sans-serif;display:flex;justify-content:space-between;gap:18px;flex-wrap:wrap}
header nav{display:flex;gap:22px}.brand{letter-spacing:.12em;font-weight:650}main{max-width:860px;margin:70px auto;padding:0 26px}
h1{font-weight:400;font-size:clamp(48px,7vw,88px);line-height:1.05;letter-spacing:-.035em;margin:0 0 20px}h2{font-weight:400;font-size:31px;line-height:1.25;margin:64px 0 22px}
p{margin:18px 0 24px}main>p:first-of-type{font:13px/1.6 system-ui;color:var(--muted);letter-spacing:.055em}
figure{margin:0}img{display:block;width:100%;height:auto}figcaption,.small{font:14px/1.6 system-ui,sans-serif;color:var(--muted);margin:12px 0 0}
.pair,.wide,.experiment{width:min(1240px,calc(100vw - 52px));position:relative;left:50%;transform:translateX(-50%);margin:38px 0}
.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}.pair img{height:360px;object-fit:contain;background:#e8e8e1}.wide img{max-height:650px;object-fit:contain;background:#e8e8e1}
table{border-collapse:collapse;width:100%;font:15px/1.6 system-ui,sans-serif;margin:28px 0}th,td{border-bottom:1px solid var(--line);text-align:left;padding:14px 12px;vertical-align:top}th{font-size:12px;text-transform:uppercase;letter-spacing:.06em}
code{font: .84em/1.5 Consolas,monospace;background:#e7e7df;padding:2px 5px;border-radius:3px}pre{background:#232926;color:#f5f2e9;padding:24px;overflow:auto}pre code{padding:0;background:none;color:inherit}
.experiment{background:#e5e6dd;padding:24px;max-width:1060px}.experiment img{max-height:650px;object-fit:contain}.eyebrow{font:11px/1.4 system-ui;letter-spacing:.14em;margin:0 0 15px}.switches{display:flex;gap:10px;flex-wrap:wrap}button{font:15px/1.4 system-ui;padding:10px 18px;border:1px solid var(--ink);color:var(--ink);background:transparent;cursor:pointer;border-radius:3px}button[aria-pressed=true]{background:var(--ink);color:var(--paper)}button:focus-visible{outline:3px solid var(--accent);outline-offset:3px}.rule{margin:18px 0;font:20px/1.5 Consolas,monospace}
footer{border-top:1px solid var(--line);padding:25px 5vw;font:13px/1.6 system-ui;color:var(--muted)}li{padding-left:5px;margin:8px 0}
@media(max-width:700px){main{margin-top:42px;padding:0 22px}body{font-size:18px}.pair{grid-template-columns:1fr}.pair img{height:auto;max-height:390px}.pair,.wide,.experiment{width:calc(100vw - 28px)}table{font-size:13px}td,th{padding:10px 6px}h2{font-size:28px}.experiment{padding:15px}}
@media print{header,footer,.switches{display:none}body{background:white;font-size:11pt}main{max-width:none;margin:0}.pair,.wide,.experiment{width:100%;left:0;transform:none;break-inside:avoid}.pair img{height:200px}h2{margin-top:30px}.experiment{max-width:100%}}
"""
js = """
const states={
cyclic:{image:'cyclic-array.png',rule:'(column + row) % 5',note:'Each new row begins one form later. Five forms return in another order.',alt:'Native Godot cyclic array: five forms shift by one place in each successive row.'},
repeat:{image:'repeated-array.png',rule:'column',note:'Every row repeats the same five choices. All twenty-five addresses and their spacing stay fixed.',alt:'Native Godot array: five identical rows, with each form repeated down its column.'},
cross:{image:'five-height-rules.png',rule:'x == 2 or z == 2',note:'Nine ground addresses per structure. Much of the square is left empty.',alt:'Five native Godot stepped lattices on cross-shaped footprints.'},
square:{image:'expanded-footprint.png',rule:'true',note:'Twenty-five ground addresses per structure. The five height functions are unchanged.',alt:'Five native Godot lattices with full square footprints and the same five height functions.'}
};
document.querySelectorAll('[data-comparison]').forEach(group=>{
group.querySelectorAll('[data-choice]').forEach(button=>button.addEventListener('click',()=>{
const state=states[button.dataset.choice];
group.querySelector('[data-result]').src=state.image;group.querySelector('[data-result]').alt=state.alt;
group.querySelector('[data-rule]').textContent=state.rule;group.querySelector('[data-note]').textContent=state.note;
group.querySelectorAll('[data-choice]').forEach(peer=>peer.setAttribute('aria-pressed',String(peer===button)));
}));});
"""

def page(title, source, interactive=False):
    body = markdown.markdown(source, extensions=["tables", "fenced_code"])
    script = f"<script>{js}</script>" if interactive else ""
    return f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{title} — Ada</title><style>{css}</style></head>
<body><header><span class="brand">ADA / IMAGE · RULE · ROOM</span><nav><a href="index.html">Reading the image</a><a href="making.html">Making</a><a href="open-structures.zip">Godot project ↓</a></nav></header><main id="reading">{body}</main><footer>1 October 2026 · Native Godot study after supplied photographs of Sol LeWitt's work. Original arrangement rules are distinguished from our proposals. <a href="report.json">Software evidence</a></footer>{script}</body></html>'''

(HERE / "index.html").write_text(page("Reading a rule", (HERE / "BLOG.md").read_text(encoding="utf-8"), True), encoding="utf-8")
(HERE / "making.html").write_text(page("From one frame to a family", (STUDY / "TUTORIAL.md").read_text(encoding="utf-8")), encoding="utf-8")

files = ["project.godot", "study.tscn", "open_structure.gd", "rules.gd", "stage.gd", "capture.gd", "README.md", "TUTORIAL.md"]
with ZipFile(HERE / "open-structures.zip", "w", ZIP_DEFLATED) as bundle:
    for name in files:
        bundle.write(STUDY / name, "open-structures/" + name)
    bundle.write(STUDY / "captures/report.json", "open-structures/captures/report.json")
manifest = {name: hashlib.sha256((STUDY / name).read_bytes()).hexdigest() for name in files}
(HERE / "source-hashes.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
print("Packaged two pages, supplied images, native captures and independent Godot project.")
