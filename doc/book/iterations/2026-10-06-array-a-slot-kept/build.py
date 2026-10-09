from pathlib import Path
import hashlib
import html
import json
import re
import zipfile
import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]

def put(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value, encoding='utf-8')

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def render(text):
    return markdown.markdown(text, extensions=['fenced_code', 'tables', 'footnotes'])

CSS = '''*{box-sizing:border-box}body{margin:0;background:#f0eee8;color:#242321;font:19px/1.65 Georgia,serif}header,main{max-width:960px;margin:auto;padding:28px}h1{font-size:2.3em;line-height:1.15}h2{font-size:1.45em;line-height:1.3;margin-top:1.8em}a{color:#68435d}nav{display:flex;gap:20px;flex-wrap:wrap;font:15px/1.5 system-ui}pre{background:#24262b;color:#f8f7f1;padding:24px;font:13px/1.65 Consolas,monospace;white-space:pre-wrap;overflow-wrap:anywhere}code{font-size:.88em}pre code{font-size:inherit}.quiet{font:14px/1.6 system-ui;color:#56524f}.spread{display:grid;grid-template-columns:1fr 1fr;max-width:1700px;gap:42px}.spread article{min-width:0}img{max-width:100%;height:auto}.plate{max-width:520px;display:block;margin:28px auto}table{border-collapse:collapse;font:15px/1.5 system-ui;width:100%}td,th{padding:10px;border-bottom:1px solid #ccc;text-align:left;vertical-align:top}details{margin:25px 0}summary{cursor:pointer}@media(max-width:1000px){.spread{display:block}}@media print{body{background:white;font-size:11pt}nav,.quiet{display:none}pre{background:#eee;color:black}.spread{display:block}h2{break-after:avoid}}'''

def shell(title, content, wide=False):
    return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>' + html.escape(title) + '</title><style>' + CSS + '</style><header><p class="quiet">ENDLESS MUSEUM · ARRAY · REVIEW DRAFT</p><nav><a href="index.html">Review</a><a href="tutorial.html">Tutorial</a><a href="parallel.html">Tutorial left / reflection right</a><a href="tutorial.md">Markdown</a><a href="array-review.zip">Code + tests</a></nav></header><main' + (' class="spread"' if wide else '') + '>' + content + '</main></html>'

def main():
    code = (HERE / 'lesson.gd').read_text(encoding='utf-8')
    template = (HERE / 'text.md').read_text(encoding='utf-8')
    assert template.count('{{CODE}}') == 1
    tutorial = template.replace('{{CODE}}', '```gdscript\n' + code + '```')
    put(HERE / 'tutorial.md', tutorial)
    canonical = ROOT / 'commons/maps/Array/final.md'
    if not (HERE / 'final.md').exists():
        put(HERE / 'final.md', canonical.read_text(encoding='utf-8'))
    report = json.loads((HERE / 'verification.json').read_text()) if (HERE / 'verification.json').exists() else None
    current = report and all(sha(ROOT / p) == h for p, h in report['inputs'].items())
    prose_path = HERE / 'feedback-prose-verification.json'
    prose = json.loads(prose_path.read_text()) if prose_path.exists() else None
    prose_current = report and prose and prose['passed'] and prose['native_verification_sha256'] == sha(HERE / 'verification.json') and prose['tutorial_sha256'] == sha(HERE / 'tutorial.md') and all(sha(ROOT / p) == h for p, h in report['inputs'].items() if p != (HERE / 'tutorial.md').relative_to(ROOT).as_posix())
    current = current or prose_current
    status = (f"{report['assertions']} native Godot checks passed; {report['variants']} printed exercise variants tested; {report['faults_rejected']} deliberate faults rejected." if current else 'Native verification pending for this draft.')
    if prose_current:
        status += ' Feedback changed prose only; the printed code still matches that native run.'
    note = '<p class="quiet">' + status + ' Exact printed code; synthetic desktop/XR overlap tests. No headset or learner trial.</p>'
    put(HERE / 'tutorial.html', shell('Array — a slot kept', note + render(tutorial)))
    put(HERE / 'parallel.html', shell('Array — two readings', '<article>' + note + render(tutorial) + '</article><article><p class="quiet">Existing final.md, unchanged. It follows more museum encounters than the selected tutorial.</p>' + render((HERE / 'final.md').read_text(encoding='utf-8')) + '</article>', True))
    overview = '# Array — a slot kept\n\nA complete first lesson for the next sequence. The familiar BoxMesh cube and overlap sensor return from Transformation. Four copies become a plane; collecting one leaves its address intact.\n\n' + status + '\n\n## What is new\n\nStable slots, independent references, occupancy values, a nested traversal and an event bound to its address. The clock rests in this lesson. Each cube stays still until the learner chooses a known transform.\n\nOne complete script starts with `depth = 1`, then the exact same construction opens into a plane with `depth = 4`. Both indices are visible from the beginning; all initial Z indices are zero. This refines the earlier proposal to keep the complete code visible once and avoid two competing script versions.\n\n## Read and run\n\n- [Tutorial](tutorial.html) · [tutorial.md](tutorial.md)\n- [Tutorial beside existing final.md](parallel.html)\n- [Complete program](lesson.gd) · [Code, tests and review ZIP](array-review.zip)\n- [Verification](verification.json) · [Native checks](normal-report.json)\n\n## Review focus\n\nCan the reader explain the difference between a cube, its reference, its address and its occupancy? Is the row → plane step clear with both indices visible from the beginning? Does the complete program give enough context to choose and change another cube independently?\n\n## Scope\n\nThis is an Array tutorial review draft. The canonical tutorial was missing and remains uncreated pending review. Existing final.md, maps, museum runtime, sequence order and plan acceptance are unchanged. The full report records actual checks and limitations; passing code is not evidence of human understanding.\n'
    put(HERE / 'REVIEW.md', overview)
    feedback_link = '<p><a href="feedback.html">Feedback decisions and the three clarifications</a></p>' if (HERE / 'FEEDBACK.md').exists() else ''
    put(HERE / 'index.html', shell('Array tutorial review', feedback_link + render(overview) + '<figure><img class="plate" src="../2026-10-06-final-comic-plates/array.png" alt="Existing Array reflective illustration"><figcaption class="quiet">Existing imagined illustration of the wider hall; not a render of this reduced program.</figcaption></figure>'))
    if (HERE / 'FEEDBACK.md').exists():
        put(HERE / 'feedback.html', shell('Array — feedback decisions', render((HERE / 'FEEDBACK.md').read_text(encoding='utf-8'))))
    with zipfile.ZipFile(HERE / 'array-review.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
        for p in HERE.rglob('*'):
            if p.is_file() and p.suffix in {'.gd', '.md', '.py', '.json', '.godot', '.log', '.diff', '.txt'} and '__pycache__' not in p.parts:
                archive.write(p, p.relative_to(HERE))
    print(status)

if __name__ == '__main__':
    main()
