from pathlib import Path
import hashlib
import html
import json
import shutil
import zipfile
import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]


def put(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def render(text):
    return markdown.markdown(text, extensions=['fenced_code', 'tables', 'footnotes'])


CSS = '''*{box-sizing:border-box}body{margin:0;background:#f1efe9;color:#242321;font:19px/1.65 Georgia,serif}header,main{max-width:960px;margin:auto;padding:28px}h1{font-size:2.25em;line-height:1.15}h2{font-size:1.4em;line-height:1.3;margin-top:1.8em}a{color:#714154}nav{display:flex;gap:18px;flex-wrap:wrap;font:15px/1.5 system-ui}pre{background:#25282e;color:#faf8f2;padding:22px;font:13px/1.6 Consolas,monospace;white-space:pre-wrap;overflow-wrap:anywhere}code{font-size:.88em}pre code{font-size:inherit}.quiet,figcaption{font:14px/1.6 system-ui;color:#56524f}.spread{display:grid;grid-template-columns:1fr 1fr;max-width:1720px;gap:44px}.spread article{min-width:0}img{max-width:100%;height:auto}.plate{max-width:540px;display:block;margin:auto}figure{margin:28px 0}table{border-collapse:collapse;font:15px/1.5 system-ui;width:100%}td,th{padding:10px;border-bottom:1px solid #ccc;text-align:left;vertical-align:top}.swatches{display:flex;height:10px;margin-bottom:22px}.swatches span{flex:1}@media(max-width:1000px){.spread{display:block}.spread article+article{border-top:1px solid #aaa;margin-top:40px;padding-top:25px}}@media print{body{background:white;font-size:11pt}nav{display:none}pre{background:#eee;color:black}.spread{display:block}h2{break-after:avoid}}'''


def shell(title, content, wide=False):
    return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>' + html.escape(title) + '</title><style>' + CSS + '</style><header><p class="quiet">ENDLESS MUSEUM · COLOUR 2 / 8 · FLASHLIGHT · REVIEW DRAFT</p><div class="swatches"><span style="background:#c7994d"></span><span style="background:#cc2929"></span><span style="background:#295ccc"></span></div><nav><a href="index.html">Review</a><a href="tutorial.html">Tutorial</a><a href="parallel.html">Tutorial left / reflection right</a><a href="tutorial.md">Markdown</a><a href="flashlight-review.zip">Code + tests</a></nav></header><main' + (' class="spread"' if wide else '') + '>' + content + '</main></html>'



def main():
    template = (HERE / 'text.md').read_text(encoding='utf-8')
    assert template.count('{{CODE}}') == 1
    code = (HERE / 'lesson.gd').read_text(encoding='utf-8')
    fence = chr(96) * 3
    tutorial = template.replace('{{CODE}}', fence + 'gdscript\n' + code + fence)
    put(HERE / 'tutorial.md', tutorial)
    if not (HERE / 'final.md').exists():
        shutil.copyfile(ROOT / 'commons/maps/Color_Flashlight/final.md', HERE / 'final.md')
    record = HERE / 'verification.json'
    report = json.loads(record.read_text()) if record.exists() else None
    current = report and report['passed'] and all(sha(ROOT / p) == h for p, h in report['inputs'].items())
    status = (f"{report['native_assertions']} native checks and {report['render_assertions']} GPU image checks passed; three printed edits and one independent choice tested; {report['faults_rejected']} deliberate faults rejected." if current else 'Verification pending for this draft.')
    note = '<p class="quiet">' + status + ' Supplied test hosts. No headset or learner trial.</p>'
    put(HERE / 'tutorial.html', shell('Flashlight — keep the surface', note + render(tutorial)))
    reflection = render((HERE / 'final.md').read_text(encoding='utf-8'))
    put(HERE / 'parallel.html', shell('Flashlight — two readings', '<article id="tutorial">' + note + render(tutorial) + '</article><article id="reflection"><p class="quiet">Existing final.md, unchanged. The reflective route includes more encounters than the selected tutorial.</p>' + reflection + '</article>', True))
    put(HERE / 'final.html', shell('What reaches the surface', reflection))
    figures = '<h2>The exact program, rendered</h2><p class="quiet">Fixed camera and supplied ambient light in an isolated GPU fixture. These are renders of the printed code, not screenshots inside the museum.</p>'
    for name, caption in [('separate', 'Red and green, separate aims'), ('blue', 'Only the first light changes colour'), ('overlap', 'Red aims at the green pool'), ('away', 'Red aims away; green stays')]:
        if (HERE / (name + '.png')).exists():
            figures += '<figure><img src="' + name + '.png" alt="' + caption + '"><figcaption>' + caption + '</figcaption></figure>'
    figures += '<h2>The encounter in the museum</h2><figure><img src="../2026-09-23-flashlight-faceted-sphere/same-sphere-moving-light.png" alt="Earlier native museum comparison of a pale sphere with red light on either side"><figcaption>Earlier museum capture, 23 September. This wider encounter informs the reflection; the tutorial selects a smaller planar receiver.</figcaption></figure>'
    put(HERE / 'index.html', shell('Colour 2 of 8 — Flashlight', note + render((HERE / 'REVIEW.md').read_text(encoding='utf-8')) + figures))
    with zipfile.ZipFile(HERE / 'flashlight-review.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
        for p in HERE.rglob('*'):
            if p.is_file() and p.suffix in {'.gd', '.md', '.py', '.json', '.godot', '.log', '.png'} and '__pycache__' not in p.parts:
                archive.write(p, p.relative_to(HERE))
    print(status)


if __name__ == '__main__':
    main()
