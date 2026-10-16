"""Preserve the supplied sixth chapter and give it a standalone reading page."""
from pathlib import Path
import hashlib
import html
import json
import re
import markdown

HERE = Path(__file__).resolve().parent
SOURCE = Path(r"C:\Users\palle\.codex\attachments\ba1f9cf8-c842-4d8b-9f98-b9f7c71ed2a4\Pasted text.txt")
RECORD = HERE / "supplied-trial.txt"
if not RECORD.exists():
    RECORD.write_bytes(SOURCE.read_bytes())
raw = RECORD.read_text(encoding="utf-8-sig")
lines = raw.splitlines()
title, subtitle = lines[:2]
paragraphs = [line for line in lines[2:] if line.strip()]
receipt_start = paragraphs.index("13 October 2026, 14:29:02 UTC")
receipt = paragraphs[receipt_start:receipt_start+4]
paragraphs[receipt_start:receipt_start+4] = ["> " + "  \n> ".join(receipt)]
prose = "\n\n".join(paragraphs)
trial = f"# {title}\n\n*{subtitle}*\n\n{prose}\n"
(HERE / "trial.md").write_text(trial, encoding="utf-8")
route = re.findall(r"<!-- @([^ >]+) -->", raw)
assert route == ["random_touch", "random_number_book_page_1955", "geiger_counter", "seed_replay_demo/movement_sampler", "random_return"]
plain = re.sub(r"<!--.*?-->", "", "\n".join(lines[2:]), flags=re.S)
words = len(re.findall(r"\b\w+(?:['’-]\w+)*\b", plain))
css = (HERE.parent / "2026-10-15-five-randomness-readings/style.css").read_text(encoding="utf-8")
nav = '<nav><a href="compare.html">Compare texts</a><a href="index.html">Original</a><a href="revised.html">Revised (r1)</a><a href="revised-r2.html">Sequence revision (r2)</a><a href="revision-notes.html">r1 changes</a><a href="revision2-notes.html">r2 changes</a><a href="assessment.html">Initial assessment</a><a href="supplied-trial.txt">Exact supplied source</a></nav>'
css += '''
body.compare-page{height:100dvh;display:flex;flex-direction:column;overflow:hidden}
.compare-page nav{flex-shrink:0}
.compare-page main{width:100%;max-width:none;flex:1;min-height:0;display:flex;flex-direction:column;padding:14px 24px 16px}
.compare-page main>h1{font-size:1.55rem;margin:0 0 6px}
.compare-page .context{font:14px/1.45 system-ui;margin:0 0 12px;max-width:110ch}
.compare-page .columns{flex:1;min-height:0;gap:20px}
.compare-page section{display:flex;flex-direction:column;min-height:0}
.compare-page .column-label{font:15px/1.4 system-ui;font-weight:600;margin:0 0 8px}
.compare-page .scroll-text{flex:1;min-height:0;height:auto;padding:20px 26px}
.compare-page .scroll-text:focus{outline:2px solid var(--accent);outline-offset:2px}
.compare-page .scroll-text h1{font-size:1.55rem}
@media(max-width:850px){body.compare-page{height:auto;overflow:auto}.compare-page .scroll-text{flex:none;height:68vh}.compare-page .columns{gap:22px}}
@media print{body.compare-page{height:auto;overflow:visible}.compare-page .columns{display:block}.compare-page .scroll-text{height:auto;overflow:visible}.compare-page section{break-before:page}}
'''
def page(label, body, comparison=False):
    body_class = ' class="compare-page"' if comparison else ''
    main_class = 'comparison' if comparison else 'reading'
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>'+html.escape(label)+' · Ada Research</title><style>'+css+'</style></head><body'+body_class+'>'+nav+'<main class="'+main_class+'">'+body+'</main></body></html>'
note = '<p class="status">Supplied complete candidate · '+str(words)+' prose words · not adopted. Composed encounter, not a field report. MOVE / KEEP is removed from the saved room; this intended route depends on resolving that placement.</p>'
(HERE / "index.html").write_text(page(title, note + markdown.markdown(trial)), encoding="utf-8")
(HERE / "assessment.html").write_text(page("Reading the sixth trial", markdown.markdown((HERE / "assessment.md").read_text(encoding="utf-8"))), encoding="utf-8")
files = ["supplied-trial.txt", "trial.md", "index.html", "assessment.md", "assessment.html"]
revised_path = HERE / "revised.md"
revision = None
if revised_path.exists():
    revised = revised_path.read_text(encoding="utf-8")
    revised_body = revised[revised.index("<!-- @random_touch -->"):]
    revised_plain = re.sub(r"<!--.*?-->", "", revised_body, flags=re.S)
    revised_words = len(re.findall(r"\b\w+(?:['’-]\w+)*\b", revised_plain))
    assert re.findall(r"<!-- @([^ >]+) -->", revised) == route
    original_body = trial[trial.index("<!-- @random_touch -->"):]
    original_paragraphs = [p for p in original_body.split("\n\n") if p and not p.startswith("<!--")]
    revised_paragraphs = [p for p in revised_body.split("\n\n") if p and not p.startswith("<!--")]
    assert original_paragraphs[0] == revised_paragraphs[0]
    assert original_paragraphs[-3:] == revised_paragraphs[-3:]
    revised_note = '<p class="status">Small revision · '+str(revised_words)+' prose words · not adopted. Composed encounter, not a field report. MOVE / KEEP remains removed from the saved room; placement is unresolved.</p>'
    (HERE / "revised.html").write_text(page(title+' · revised', revised_note + markdown.markdown(revised)), encoding="utf-8")
    texts = {"original": (words, original_body), "revised": (revised_words, revised_body)}
    r2_path = HERE / "revised-r2.md"
    revision2 = None
    if r2_path.exists():
        r2 = r2_path.read_text(encoding="utf-8")
        r2_body = r2[r2.index("<!-- @random_touch -->"):]
        r2_plain = re.sub(r"<!--.*?-->", "", r2_body, flags=re.S)
        r2_words = len(re.findall(r"\b\w+(?:['\u2019-]\w+)*\b", r2_plain))
        assert re.findall(r"<!-- @([^ >]+) -->", r2) == route
        r2_paragraphs = [q for q in r2_body.split("\n\n") if q and not q.startswith("<!--")]
        # r2's contract: true bookends — first and FINAL paragraph unchanged
        # (the door enters before the final line, so r1's last-three rule
        # deliberately does not carry to r2)
        assert original_paragraphs[0] == r2_paragraphs[0]
        assert original_paragraphs[-1] == r2_paragraphs[-1]
        r2_note = '<p class="status">Sequence-context revision (r2) · '+str(r2_words)+' prose words · not adopted. Applied on top of the small revision; first and final paragraphs unchanged. MOVE / KEEP remains removed from the saved room; placement is unresolved.</p>'
        (HERE / "revised-r2.html").write_text(page(title+' · r2', r2_note + markdown.markdown(r2)), encoding="utf-8")
        (HERE / "revision2-notes.html").write_text(page("Sequence-context revision · changes", markdown.markdown((HERE/'revision2-notes.md').read_text(encoding='utf-8'), extensions=['tables'])), encoding="utf-8")
        texts["r2"] = (r2_words, r2_body)
        revision2 = {"words": r2_words, "first_paragraph_unchanged": True, "final_paragraph_unchanged": True, "route_unchanged": True, "base": "revised.md", "changes": "revision2-changes.json", "reader_responses": [], "canonical_adoption": False}
    labels = {"original": "Original", "revised": "Revised (r1)", "r2": "Sequence revision (r2)"}
    options = ''.join('<option value="'+k+'">'+labels[k]+' · '+str(v[0])+' words</option>' for k, v in texts.items())
    columns = ''
    for side in ["left", "right"]:
        columns += '<section aria-label="'+side+' column"><label class="column-label" for="'+side+'">'+("Left reading" if side=="left" else "Right reading")+'</label><select id="'+side+'">'+options+'</select><article class="scroll-text" id="'+side+'-text" tabindex="0" aria-label="'+side+' full text"></article></section>'
    comparison = '<h1>The sixth text · original and revisions</h1><p class="context">Pick any two of the texts. Scroll each column independently. The final return to centre is unchanged in every version. MOVE / KEEP remains conditional on room placement.</p><div class="columns">'+columns+'</div>'
    data = json.dumps({k: markdown.markdown('# '+title+'\n\n'+v[1]) for k, v in texts.items()}, ensure_ascii=False).replace("<", "\u003c")
    js = '<script>const texts='+data+';function show(side,val){document.getElementById(side+"-text").innerHTML=texts[val];document.getElementById(side+"-text").scrollTop=0;}document.getElementById("right").value='+json.dumps("r2" if "r2" in texts else "revised")+';["left","right"].forEach(function(side){var sel=document.getElementById(side);sel.addEventListener("change",function(){show(side,sel.value);});show(side,sel.value);});</script>'
    (HERE / "compare.html").write_text(page("Sixth trial · texts compared", comparison + js, comparison=True), encoding="utf-8")
    (HERE / "revision-notes.html").write_text(page("Small revision · changes",markdown.markdown((HERE/'revision-notes.md').read_text(encoding='utf-8'),extensions=['tables'])),encoding="utf-8")
    files += ["revised.md", "revised.html", "compare.html", "revision-notes.md", "revision-notes.html", "revision-changes.json", "revise.py"]
    if revision2 is not None:
        files += ["revised-r2.md", "revised-r2.html", "revision2-notes.md", "revision2-notes.html", "revision2-changes.json", "revise2.py"]
    revision = {"words":revised_words,"opening_paragraph_unchanged":True,"last_three_paragraphs_unchanged":True,"route_unchanged":True,"comparison":"compare.html","changes":"revision-changes.json","reader_responses":[],"canonical_adoption":False}
manifest = {"date":"2026-10-15", "id":"supplied-sixth-trial", "title":title, "reported_exposure":"Composed after reading A-E, as stated in supplied subtitle.", "provenance":"Supplied by Palle; writer identity and setting not independently established.", "distinct_from":"Existing local F, How long a result remains, and the five returned short form studies.", "status":"complete_candidate_received_not_adopted", "words":words, "route":route, "source_preserved_byte_for_byte": RECORD.read_bytes()==SOURCE.read_bytes(), "reader_responses":[], "canonical_adoption":False, "files":[{"path":n,"sha256":hashlib.sha256((HERE/n).read_bytes()).hexdigest()} for n in files]}
assert manifest["source_preserved_byte_for_byte"]
if revision is not None:
    manifest["status"] = "small_revision_prepared_comparison_pending"
    manifest["revision"] = revision
    if revision2 is not None:
        manifest["status"] = "two_revisions_prepared_reading_pending"
        manifest["revision2"] = revision2
(HERE / "manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding="utf-8")
print(json.dumps({"original_words":words,"revised_words":revision["words"] if revision else None,"route":"PASS","exact_source":True,"bookends":"PASS" if revision else None,"r2_words":revision2["words"] if (revision and revision2) else None}))
