"""Publish Point Zero's existing-counter lesson with native museum evidence."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import difflib
import html
import json
import shutil
import markdown

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
MAP = ROOT / 'commons/maps/Point_Zero'
RUN = ROOT / 'ada_run/encounter_pilot/Point_Zero_tutorial'
SOURCE = ROOT / 'commons/visualaid/frame_counter/frame_counter_display.gd'
lesson = (MAP / 'tutorial.md').read_text(encoding='utf-8')
before = (OUT / 'before/tutorial.md').read_text(encoding='utf-8')
report = json.loads((RUN / 'report.json').read_text(encoding='utf-8'))
assert report['passed'] and all(c['passed'] for c in report['checks'])
for name in ('map_data.json', 'final.md'):
    assert (MAP / name).read_bytes() == (OUT / 'before' / name).read_bytes()
assert SOURCE.read_bytes() == (OUT / 'before/frame_counter_display.gd').read_bytes()
assert before.split('## Begin with a running world')[0].split('\n', 1)[1] == lesson.split('## The counter is already here')[0].split('\n', 1)[1]
assert not (ROOT / 'commons/artifacts/registry/tutorial_studies.json').exists()
assert '$' not in lesson and 'get_node(' not in lesson
for name in ('museum-counter.png', 'every-frame.png', 'read-once.png', 'source_manifest.json', 'engine.log'):
    shutil.copy2(RUN / name, OUT / name)
(OUT / 'verification.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
(OUT / 'tutorial.md').write_text(lesson, encoding='utf-8')
(OUT / 'Point_Zero.diff').write_text(''.join(difflib.unified_diff(before.splitlines(True), lesson.splitlines(True), fromfile='Point_Zero/before/tutorial.md', tofile='Point_Zero/tutorial.md')), encoding='utf-8')
contract = {
    'map': 'Point_Zero', 'host': 'existing Endless Museum',
    'artifact': 'frame_counter_display', 'source': str(SOURCE.relative_to(ROOT)),
    'prerequisites': ['working Ada project', 'save, stop and rerun from Day Zero'],
    'introduced': ['node readiness and repeated process callbacks', 'reading an engine total', 'assigning its string representation to a label'],
    'supplied': ['existing code-built console and label reference', 'museum, player, viewing and light', 'other readout modes'],
    'learner_action': 'move the same display assignment between _process and _ready',
    'observable_difference': 'live total versus a single reading; engine continues in both cases',
    'deferred': ['housing geometry', 'frame-rate calculations', 'elapsed-time accumulation', 'camera and light construction'],
    'new_artifacts': [], 'next': 'Point_One after author reading',
    'runtime_checks': len(report['checks']), 'physical_headset_tested': False
}
(OUT / 'lesson-contract.json').write_text(json.dumps(contract, indent=2) + '\n', encoding='utf-8')
decisions = '''# Point Zero — the counter already in the hall

The tutorial begins with the existing `frame_counter_display`. Palle's correction is decisive: the museum already contains the material. The added greeting stand, its source, registry and placement have been removed. No extra artifact is required for this lesson.

The approved opening about tutorial, reflective writing and the wider museum field is retained verbatim. The practical lesson now uses the artifact's actual `_ready()` and a reduced `_process()`. The student keeps the supplied construction and changes when the engine's total reaches its label. This is a close reading and modification of an existing work. It does not claim to build the whole console from scratch.

The repeated update reads `Engine.get_process_frames()`; it does not create a counter beginning at node readiness. The once-only experiment holds a reading while the engine continues. Frame counts and elapsed seconds remain distinct.

Canonical tutorial and implementation notes are updated. The main critical text, artifact source and map are byte-for-byte unchanged from the start of this pass. The handover now explicitly requires beginning with the existing artifact before considering a new teaching object.

The native probe runs the exact printed function edits in memory on the original artifact at its museum placement. All 26 checks pass. The source is then restored in the test process; the saved production script is never edited. Native images show the original counter, its simplified repeated update and the held reading. A still image alone does not prove updating: the runtime checks compare readings across frames.

The engine log also reports the project's unresolved audio-bus UID `uid://rwex60pqapc` and existing material warnings. These did not prevent the checks or images; this is not a claim that the whole project is error-free. Physical headset use and beginner comprehension remain untested. Local HTML links and anchors are checked by the publisher; browser visual inspection was not performed.

Other starter-based tutorials and Day Zero's detailed setup still need their host instructions aligned individually. Continue one tutorial at a time. Point One follows only after Palle reads this correction.
'''
(OUT / 'DECISIONS.md').write_text(decisions, encoding='utf-8')
shutil.copy2(OUT.parent / '2026-10-03-transformation-a-running-body/style.css', OUT / 'style.css')
def figure(name, caption):
    return f'<figure><a href="{name}"><img src="{name}" alt="{html.escape(caption)}" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure>'
page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Point Zero — Already running</title><link rel="stylesheet" href="style.css"></head><body><main>
<header><nav><a href="#reading">Read the tutorial</a><a href="#museum">The existing counter</a><a href="#decisions">Decisions and checks</a></nav><p>ADA / ENDLESS MUSEUM / 3 OCTOBER 2026</p></header>
<article><p class="step">Point Zero · one tutorial</p><h1>The counter is already here.</h1><p class="subtitle">Follow the code inside the work you encounter. Change when the number is read.</p><p>The existing console carries the lesson. The room and its artifacts remain as they were.</p></article>
<section id="museum" class="screen">{figure('museum-counter.png', 'Point Zero’s existing frame counter, inside Endless Museum. Native Godot capture.')}
<div class="pair">{figure('every-frame.png', 'The reduced _process() reads the engine total each frame.')}{figure('read-once.png', 'The same assignment in _ready() holds one reading. The engine keeps running.')}</div></section>
<article id="reading" class="chapter">{markdown.markdown(lesson, extensions=['fenced_code'])}<p class="quiet"><a href="tutorial.md">Tutorial source</a> · <a href="Point_Zero.diff">Exact text diff</a></p></article>
<details id="decisions"><summary>What changed and what was checked</summary><div>{markdown.markdown(decisions)}<p><a href="verification.json">Native checks</a> · <a href="lesson-contract.json">Teaching scope</a> · <a href="before/frame_counter_display.gd">Original artifact source</a> · <a href="verify.gd">Probe</a> · <a href="engine.log">Engine log</a> · <a href="source_manifest.json">Museum source record</a></p></div></details>
</main><script>function reveal(){{const el=document.getElementById(location.hash.slice(1));if(el?.tagName==='DETAILS')el.open=true}}addEventListener('hashchange',reveal);reveal();</script></body></html>'''
(OUT / 'index.html').write_text(page, encoding='utf-8')
class Links(HTMLParser):
    def __init__(self):
        super().__init__(); self.links = []; self.ids = set()
    def handle_starttag(self, tag, attrs):
        self.links.extend(v for k,v in attrs if k in ('href','src'))
        self.ids.update(v for k,v in attrs if k == 'id')
links = Links(); links.feed(page)
for link in links.links:
    url = urlsplit(link)
    if url.scheme: continue
    if url.path: assert (OUT / unquote(url.path)).exists(), link
    elif url.fragment: assert url.fragment in links.ids, link
summary = {'native_checks': len(report['checks']), 'local_links_checked': len(links.links), 'approved_opening_preserved': True, 'original_map_source_and_final_unchanged': True, 'added_display_removed': True, 'lesson_words_including_code': len(lesson.split())}
(OUT / 'review-checks.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
print(json.dumps(summary))
