"""Render the preface with its new passage; preserve a before/after record."""
from pathlib import Path
from html import escape
import difflib
import hashlib
import json
import re
import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
SOURCE = ROOT/'doc/book/preface.md'
before = (HERE/'preface.before.md').read_text(encoding='utf-8')
current = SOURCE.read_text(encoding='utf-8')
opening = 'I began from the programming courses I had taught at university.'
start = current.index(opening)
end = current.index('Whenever possible, an encounter comes before its explanation.', start)
passage = current[start:end].strip()
note = re.search(r'^\[\^preface-folding-future\]:.*$', current, re.M).group(0)
(HERE/'preface.current.md').write_text(current, encoding='utf-8')
(HERE/'addition.md').write_text('# The folding future\n\n'+passage+'\n\n'+note+'\n', encoding='utf-8')
(HERE/'preface.diff').write_text(''.join(difflib.unified_diff(before.splitlines(True),current.splitlines(True),fromfile='preface.before.md',tofile='doc/book/preface.md')),encoding='utf-8')
why_before = HERE/'preface.before-why.md'
if why_before.exists():
    (HERE/'why.diff').write_text(''.join(difflib.unified_diff(why_before.read_text(encoding='utf-8').splitlines(True),current.splitlines(True),fromfile='preface.before-why.md',tofile='doc/book/preface.md')),encoding='utf-8')
report = '''# The folding future in the preface

5 October 2026. Added to the canonical `doc/book/preface.md`.

The new passage follows the invitation to readers and precedes the account of learning through encounters. It keeps the two ghosts distinct: the student whose imagined needs change the lesson now, and the author anticipating a changed relation to their own knowledge and teaching labour.

The follow-up revision makes the cause explicit, using the [author's account](AUTHOR-CONTEXT.md). The course grew from teaching programming to artists. During its construction the author increasingly worked through instructions to AI: an object could arrive before they understood its construction. If a student begins through that route too, the original teaching encounter becomes uncertain. This is an account of changed practice and expectation, not a prediction that understanding will become unnecessary. [Compare this clarification](why.diff).

The point continuation gives the argument a concrete event. We stopped rebuilding the sphere, kept an assumed student program and tested the changes needed to make it pickable. Compact instructions for later AI readers provide another present decision. These are records of practice; the connection to anticipated displacement is the author's interpretation.

The encounter is left uncertain. The writing does not predict the disappearance of students or teachers. It also asks whether the imagined student is too convenient, and leaves room for someone to question the route. The existing QFEP paragraph now asks which capacities to preserve when the intended relationship changes.

Derrida's “Exordium” was checked in the publisher preview, especially pp. xxiii–xxiv. It supports the connection to responsibility towards absent and future others. “Anticipatory hauntology” is identified as a description of Ada's emphasis, not Derrida's own term. The supplied NLR excerpt was also inspected. Jo Albin-Clark's institutional record was verified as a 2024 conference abstract; it offers a related research-creation approach, not evidence that Ada's teaching works.

The full reasoning and source limits are retained in [discursive memory](../../memory/FOLDING-FUTURE.md). The tutorial continuation remains a separate test artifact.

[Read the current preface](../../preface.md) · [Read only the addition](addition.md) · [Compare before/after](preface.diff)
'''
(HERE/'REPORT.md').write_text(report,encoding='utf-8')
rendered = markdown.markdown(current, extensions=['footnotes','fenced_code','tables'])
rendered = rendered.replace('<p>'+opening, '<p id="folding-future">'+opening)
rendered = rendered.replace('href="day-zero.md"','href="../../day-zero.md"')
html = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The folding future · Ada preface</title><style>
:root{color-scheme:light;--paper:#f5f1e9;--ink:#292824;--muted:#706b64;--accent:#84495f}*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:var(--paper);color:var(--ink);font:19px/1.85 Georgia,serif}header,article,footer{max-width:810px;margin:auto;padding:2rem}header{padding-top:3rem;font:14px/1.6 system-ui,sans-serif}header .label{color:var(--accent);font-size:11px;letter-spacing:.17em;text-transform:uppercase}header h2{font-size:2rem;letter-spacing:-.04em;margin:.5rem 0}.meta{color:var(--muted)}nav{display:flex;flex-wrap:wrap;gap:1.2rem;margin-top:1.2rem}a{color:var(--accent);text-underline-offset:3px}article{padding-top:1rem}h1{font-size:2.8rem;line-height:1.2;font-weight:400;letter-spacing:-.04em}p{margin:1.25em 0}#folding-future{scroll-margin-top:2rem;border-left:2px solid var(--accent);padding-left:1.2rem}.footnote{font-size:14px;line-height:1.7}.footnote li{margin-bottom:1.5rem}.footnote-ref{font-size:.7em}hr{border:0;border-top:1px solid #d8cfc2;margin:2.5rem 0}footer{font:13px/1.7 system-ui,sans-serif;border-top:1px solid #d8cfc2}details{margin-top:1rem}summary{cursor:pointer}pre{white-space:pre-wrap;font-size:12px;line-height:1.6}table{border-collapse:collapse}td,th{padding:.5rem;border-bottom:1px solid #ccc}@media(max-width:600px){header,article,footer{padding:1.3rem}h1{font-size:2.2rem}body{font-size:18px}}@media print{header,footer{display:none}body{background:white}article{max-width:none;padding:0}a{color:inherit}#folding-future{border:0;padding:0}}
</style></head><body><header><div class="label">Ada · Preface revision · 5 October 2026</div><h2>The folding future</h2><p class="meta">A course began with learning to code in order to make. Its author increasingly made through AI instructions, then investigated the result. That change unsettled the teaching encounter being prepared. This page shows the full revised preface.</p><nav><a href="#folding-future">New passage</a><a href="#preface">From the beginning</a><a href="addition.md">Addition only</a><a href="preface.diff">Before / after</a><a href="../../memory/FOLDING-FUTURE.md">Discursive memory</a></nav></header><article id="preface">'''+rendered+'''</article><footer><a href="../../preface.md">Canonical manuscript</a> · <a href="REPORT.md">Editorial note and source checks</a><details><summary>What changed</summary>'''+markdown.markdown(report)+'''</details></footer></body></html>'''
(HERE/'index.html').write_text(html,encoding='utf-8')
refs=set(re.findall(r'\[\^([^\]]+)\](?!:)',current))
definitions=set(re.findall(r'^\[\^([^\]]+)\]:',current,re.M))
assert refs == definitions, (refs,definitions)
record={'preface_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
        'before_sha256':hashlib.sha256((HERE/'preface.before.md').read_bytes()).hexdigest(),
        'addition_words':len(passage.split()),'footnote_references_resolve':True,
        'source_scope':'Derrida publisher preview Exordium and public NLR excerpt; Albin-Clark conference abstract.',
        'future_outcome':'Not established; author interpretation of anticipation in current practice.'}
(HERE/'checks.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
print(json.dumps(record,indent=2))
