"""Retain supplied form studies exactly; build a portable reading collection."""
from pathlib import Path
import hashlib
import html
import json
import re
import zipfile
import markdown

HERE = Path(__file__).resolve().parent
OLD = HERE.parent / "2026-10-15-five-randomness-readings"
SOURCE = Path(r"C:\Users\palle\.codex\attachments\cc514e71-65fb-445d-956f-85d11cb744b6\Pasted text.txt")
RECORD = HERE / "supplied-experiments.txt"
if not RECORD.exists():
    RECORD.write_bytes(SOURCE.read_bytes())
raw = RECORD.read_text(encoding="utf-8-sig")
sections = re.split(r"(?m)^## ([1-5])\. (.+)\n", raw)
studies = []
for i in range(1, len(sections), 3):
    number, title, section = sections[i:i + 3]
    section = section.split("## What I would send to Astra")[0].strip()
    attribution, rest = section.split("\n\n", 1)
    body, question = rest.split("What it tests:", 1)
    notes = ""
    if number == "1":
        body, notes = body.split("This is almost a theatrical score.", 1)
        notes = "This is almost a theatrical score. " + notes.strip()
    question, *remaining = question.strip().split("\n\n", 1)
    if remaining:
        notes += "\n\n" + remaining[0]
    body = body.strip()
    (HERE / f"study-{number}.md").write_text(f"# {title}\n\n{body}\n", encoding="utf-8")
    studies.append({"id": int(number), "title": title, "method_label_as_supplied": attribution,
                    "body": body, "question": question, "notes": notes.strip(),
                    "words": len(re.findall(r"\b\w+(?:['’-]\w+)*\b", body))})

css = (OLD / "style.css").read_text(encoding="utf-8")
css += ".study-title{text-transform:none}.comparison .scroll-text{height:70vh} .source-note{font:14px/1.6 system-ui;max-width:85ch}"
nav = '<nav><a href="index.html">Returned studies</a><a href="contrast.html">Office / ink</a><a href="assessment.html">Editorial reading</a><a href="literary-forms.zip">Download packet</a><a href="../2026-10-15-five-randomness-readings/index.html">Earlier five chapters</a></nav>'
def render(text):
    return markdown.markdown(text, extensions=["tables"])
def page(title, body):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>'+html.escape(title)+' · Ada Research</title><style>'+css+'</style></head><body>'+nav+body+'</body></html>'
for s in studies:
    body = '<main class="reading"><p class="eyebrow">Supplied form study '+str(s['id'])+' · '+str(s['words'])+' words</p><article><h1>'+html.escape(s['title'])+'</h1>'+render(s['body'])+'</article><details><summary>Supplied method and question · after reading</summary>'+render(s['method_label_as_supplied']+'\n\nWhat it tests: '+s['question']+'\n\n'+s['notes'])+'</details><p class="source-note">Preserved from the supplied return. A literary study, not an adopted chapter or a report of a visit. The office in study 3 is fictional. <a href="assessment.html">Separate editorial and technical reading</a>.</p></main>'
    (HERE/f"study-{s['id']}.html").write_text(page(s['title'],body),encoding="utf-8")
cards = ''.join('<a class="card" href="study-'+str(s['id'])+'.html"><span class="eyebrow">Study '+str(s['id'])+' · '+str(s['words'])+' words</span><h2>'+html.escape(s['title'])+'</h2><span>Read the supplied text →</span></a>' for s in studies)
index = '<main class="wide"><h1>Five different kinds of work</h1><p class="intro">One simulation can supply a performance, a case, a dialogue, a close observation, or a montage. These short studies ask what can organize the writing when a walkthrough no longer has to.</p>'+cards+'<p><a href="contrast.html">Read the office and ink studies side by side</a> · <a href="assessment.html">Read the comparison with our earlier chapters</a></p><p class="source-note">Returned by Palle on 15 October 2026. Original wording preserved; method notes follow each study. No study is adopted. The room and final chapter’s existing order decision remains in force.</p></main>'
(HERE/"index.html").write_text(page("Five different kinds of work",index),encoding="utf-8")
columns = ''.join('<section><p class="eyebrow">Study '+str(s['id'])+'</p><article class="scroll-text" tabindex="0" aria-label="'+html.escape(s['title'])+'"><h1>'+html.escape(s['title'])+'</h1>'+render(s['body'])+'</article></section>' for s in studies if s['id'] in (3,4))
(HERE/"contrast.html").write_text(page("Office and ink",'<main class="comparison"><h1>Conflict / observation</h1><p class="intro">What does each piece make worth investigating? Read the works before their method notes.</p><div class="columns">'+columns+'</div><p class="source-note">The office and clerk are fictional; the sphere constraints are grounded in the apparatus. <a href="assessment.html">Technical limits and editorial reading</a>.</p></main>'),encoding="utf-8")
(HERE/"assessment.html").write_text(page("Editorial reading",'<main class="reading">'+render((HERE/"assessment.md").read_text(encoding="utf-8"))+'</main>'),encoding="utf-8")
(HERE/"supplied-experiments.html").write_text(page("Complete supplied return",'<main class="reading">'+render(raw)+'</main>'),encoding="utf-8")
(HERE/"studies.json").write_text(json.dumps(studies,ensure_ascii=False,indent=2)+'\n',encoding="utf-8")
files = ["README.md","index.html","contrast.html","assessment.html","assessment.md","supplied-experiments.txt","supplied-experiments.html","studies.json"] + [f"study-{s['id']}.{ext}" for s in studies for ext in ["md","html"]]
with zipfile.ZipFile(HERE/"literary-forms.zip","w",zipfile.ZIP_DEFLATED) as archive:
    for name in files: archive.write(HERE/name,name)
manifest = {"date":"2026-10-15","status":"received_form_studies_not_adopted","source_sha256":hashlib.sha256(RECORD.read_bytes()).hexdigest(),"source_preserved_byte_for_byte":RECORD.read_bytes()==SOURCE.read_bytes(),"source_identity":"Supplied by Palle; writer identity not independently established.","reported_preference":[3,4],"palle_selection":None,"reader_responses":[],"canonical_adoption":False,"files":[{"path":n,"sha256":hashlib.sha256((HERE/n).read_bytes()).hexdigest()} for n in files+["literary-forms.zip"]]}
(HERE/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding="utf-8")
assert len(studies)==5 and manifest['source_preserved_byte_for_byte']
print(json.dumps({"studies":len(studies),"words":{s['id']:s['words'] for s in studies},"verbatim_source":True}))
