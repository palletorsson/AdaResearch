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
    return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>' + html.escape(title) + '</title><style>' + CSS + '</style><header><p class="quiet">ENDLESS MUSEUM · COLOUR · REVIEW DRAFT</p><div class="swatches"><span style="background:#c7994d"></span><span style="background:#cc2929"></span><span style="background:#295ccc"></span></div><nav><a href="index.html">Review</a><a href="tutorial.html">Tutorial</a><a href="parallel.html">Tutorial left / reflection right</a><a href="tutorial.md">Markdown</a><a href="colour-review.zip">Code + tests</a></nav></header><main' + (' class="spread"' if wide else '') + '>' + content + '</main></html>'


def main():
    template = (HERE / 'text.md').read_text(encoding='utf-8')
    assert template.count('{{CODE}}') == 1
    code = (HERE / 'lesson.gd').read_text(encoding='utf-8')
    fence = chr(96) * 3
    tutorial = template.replace('{{CODE}}', fence + 'gdscript\n' + code + fence)
    put(HERE / 'tutorial.md', tutorial)
    if not (HERE / 'final.md').exists():
        shutil.copyfile(ROOT / 'commons/maps/Color_Context_Placed/final.md', HERE / 'final.md')
    record = HERE / 'verification.json'
    report = json.loads(record.read_text()) if record.exists() else None
    current = report and report['passed'] and all(sha(ROOT / p) == h for p, h in report['inputs'].items())
    status = (f"{report['assertions']} native Godot checks passed; three printed exercise variants and one independent-choice example tested; {report['faults_rejected']} deliberate faults rejected." if current else 'Native verification pending for this draft.')
    note = '<p class="quiet">' + status + ' Exact printed program in a supplied test host. No new museum render, headset or learner trial.</p>'
    put(HERE / 'tutorial.html', shell('Colour — the same parts', note + render(tutorial)))
    reflection = render((HERE / 'final.md').read_text(encoding='utf-8'))
    put(HERE / 'parallel.html', shell('Colour — two readings', '<article id="tutorial">' + note + render(tutorial) + '</article><article id="reflection"><p class="quiet">Existing final.md, unchanged. The reflective route includes more encounters than this selected tutorial.</p>' + reflection + '</article>', True))
    put(HERE / 'final.html', shell('Before we ask what colour is', reflection))
    review = '# Colour — the same parts\n\nThe first Colour tutorial returns to five familiar parts. Keep geometry fixed; use a palette and five indices to change their grouping. One complete program creates its own meshes and independent materials in the existing museum host.\n\n' + status + '\n\n## The small progression\n\n1. One ochre: every part selects palette entry 0.\n2. Group the blocks in red and the round forms in blue.\n3. Change the red palette entry: the assigned group changes together.\n4. Alternate the assignments, then compose another grouping.\n\nThe student changes values and assignments separately. No new mesh factory, animation, automatic shape classifier or input system is required. The supplied fixed construction reproduces the opening column’s five forms and dimensions. The rest of the gallery remains available to the reflective text.\n\n## Read and review\n\n- [Tutorial beside final.md](parallel.html)\n- [Tutorial alone](tutorial.html) · [tutorial.md](tutorial.md)\n- [Reflection alone](final.html) · [final.md](final.md)\n- [Complete program](lesson.gd) · [Code and tests](colour-review.zip)\n- [Verification](verification.json) · [Native checks](normal-report.json)\n\n## What was inherited and what changes\n\n| Bring | Change | Keep | Carry |\n|---|---|---|---|\n| BoxMesh, SphereMesh, transforms, arrays and instance references | RGB values and palette indices assigned to independent materials | Five parts, their order, geometry, pose and material roughness | A palette and a function that writes chosen values into known surfaces |\n\nThe existing companion was a tour of many exhibits, with a later landscape source edit. This draft chooses the opening colour assignment as the executable lesson. The historical shape association and broader compositions remain in the unchanged reflection.\n\n## Evidence and limits\n\nChecks extract the exact printed program, instantiate it in Godot, test the three specified edits and an independent composition, then reassign colours on the same live objects. They check reference/material independence, copied values, unchanged geometry/transforms, a translated/rotated host, and repeated application. Deliberate broken versions test whether the assertions detect shared materials, wrong assignments, movement during repainting and rebuilding meshes. Test results establish these program behaviours; they do not establish a student’s understanding or perceptual equivalence between differently lit surfaces.\n\nThe photographs below are earlier real museum captures from 23 September. The comic is an imagined illustration of the wider reflective route. Neither is a new render of this learner program.\n\n## Status\n\nReview draft. Canonical tutorial.md, final.md, museum logic, placement, sequence order and plan acceptance are preserved. The four later Array tutorials still need their own executable pass. Next Colour lesson: keep the material and change the light.\n'
    put(HERE / 'REVIEW.md', review)
    images = '<figure><img src="../2026-09-23-colour-gathering/four-colour-rules.png" alt="Earlier native museum views: five identical forms under four colour assignments"><figcaption>Existing museum comparison, 23 September. This tutorial selects the one-colour and shape-grouping comparison.</figcaption></figure><figure><img class="plate" src="../2026-10-06-final-comic-plates/colour-context.png" alt="Illustrated reflective route through colour and composition"><figcaption>Existing imagined illustration for final.md. The lesson reconstructs the smaller assignment, not every pictured exhibit.</figcaption></figure>'
    put(HERE / 'index.html', shell('Colour tutorial review', render(review) + images))
    with zipfile.ZipFile(HERE / 'colour-review.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
        for p in HERE.rglob('*'):
            if p.is_file() and p.suffix in {'.gd', '.md', '.py', '.json', '.godot', '.log'} and '__pycache__' not in p.parts:
                archive.write(p, p.relative_to(HERE))
    print(status)


if __name__ == '__main__':
    main()
