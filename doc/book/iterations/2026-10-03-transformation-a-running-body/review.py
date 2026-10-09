"""Build the local reading copy from canonical prose and verified runnable code."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import difflib
import html
import json
import re
import markdown

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
STARTER = ROOT / 'doc/book/studies/ada-xr-starter'
MAP = ROOT / 'commons/maps/Trans_Pre'
report = json.loads((OUT / 'verification.json').read_text(encoding='utf-8'))
package = json.loads((OUT / 'package-verification.json').read_text(encoding='utf-8'))
assert report['passed'] and package['passed']
assert all(item['passed'] for item in report['checks'])
lesson = (MAP / 'tutorial.md').read_text(encoding='utf-8')
sine = (MAP / 'tutorial-sine.md').read_text(encoding='utf-8')
code = (STARTER / 'studies/trans_pre/motion.gd').read_text(encoding='utf-8')
blocks = re.findall(r'```gdscript\n(.*?)```', lesson, re.S)
assert all(block.strip() in code for block in blocks)
sine_block = re.findall(r'```gdscript\n(.*?)```', sine, re.S)[0].strip()
assert sine_block in (OUT / 'verify.gd').read_text(encoding='utf-8')
assert (MAP / 'final.md').read_bytes() == (OUT / 'before/final.md').read_bytes()
assert (MAP / 'tutorial-museum.md').read_bytes() == (OUT / 'before/tutorial.md').read_bytes()
(OUT / 'tutorial.md').write_text(lesson, encoding='utf-8')
(OUT / 'tutorial-sine.md').write_text(sine, encoding='utf-8')
before = (OUT / 'before/tutorial.md').read_text(encoding='utf-8')
(OUT / 'Trans_Pre.diff').write_text(''.join(difflib.unified_diff(before.splitlines(True), lesson.splitlines(True), fromfile='Trans_Pre/before/tutorial.md', tofile='Trans_Pre/tutorial.md')), encoding='utf-8')

def render(text):
    text = text.replace('../../../doc/book/studies/ada-xr-starter/README.md', '../../studies/ada-xr-starter/README.md')
    text = text.replace('(tutorial-sine.md)', '(#sine)')
    return markdown.markdown(text, extensions=['fenced_code', 'tables'])

def figure(filename, caption):
    return f'<figure><a href="{filename}"><img loading="lazy" src="{filename}" alt="{html.escape(caption)}"></a><figcaption>{html.escape(caption)}</figcaption></figure>'

def pair(a, ca, b, cb):
    return '<div class="pair">' + figure(a, ca) + figure(b, cb) + '</div>'

sources = []
for filename in ['motion.gd', 'marked_cube.gd', 'motion_readout.gd']:
    text = (STARTER / 'studies/trans_pre' / filename).read_text(encoding='utf-8')
    assert '$' not in text and 'get_node' not in text and 'find_child' not in text
    (OUT / filename).write_text(text, encoding='utf-8')
    sources.append(f'<details><summary>{filename}</summary><div><pre><code>{html.escape(text)}</code></pre><p><a href="{filename}" download>Download script</a></p></div></details>')
css = (OUT.parent / '2026-10-03-primitives-closing-tutorials/style.css').read_text(encoding='utf-8')
css += '\nvideo{width:100%;display:block;background:#18151c}section[id],article[id]{scroll-margin-top:24px}.screen{max-width:960px;margin:36px auto}.screen figure{margin:20px 0}.subtitle{font-size:23px;color:#65515b}.screen .pair{margin:30px 0}@media print{video,.video-caption{display:none}}\n'
(OUT / 'style.css').write_text(css, encoding='utf-8')
page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Trans_Pre — a body that changes</title><link rel="stylesheet" href="style.css"></head><body><main>
<header><nav><a href="#reading">Read the lesson</a><a href="#motion">See the movement</a><a href="#sine">Sine comparison</a><a href="#code">Complete code</a><a href="#decisions">Decisions and checks</a></nav><p>ADA / TRANSFORMATION / 3 OCTOBER 2026</p></header>
<article><p class="step">Trans_Pre · the first Transformation tutorial</p><h1>Keep the cube.<br>Change what it does.</h1><p class="subtitle">A position becomes a journey. Add a turn, then a change in size. Follow each operation in the same body.</p><p><a class="download" href="../2026-10-03-ada-xr-starter/ada-xr-starter.zip" download>Download the updated starter</a></p><p class="quiet">Open <code>trans_pre.tscn</code>. The default is a still cube with a running clock. Change <code>stage</code> as you read. The film below shows stage 3.</p></article>
<section id="motion" class="screen"><figure><video controls playsinline preload="metadata" poster="large.png" aria-label="Eight seconds of the cube rising, turning and changing size in the Godot student room"><source src="three-operations.mp4" type="video/mp4"></video><figcaption class="video-caption">Eight seconds in the prepared student room. Native Godot rendering of the lesson's stage 3, sampled at 30 frames per second. No sound. <a href="three-operations.mp4" download>Download the film</a>.</figcaption></figure>
{pair('rise.png', 'Stage 1, 0.75 s: the centre reaches 1.55 m. Mesh size stays fixed.', 'fall.png', 'Stage 1, 2.25 s: the centre reaches 1.05 m. Its orientation stays fixed.')}
{pair('large.png', 'Stage 3, 0.75 s: scale 1.3 at the upper end, with rotation continuing.', 'small.png', 'Stage 3, 2.25 s: scale 0.7 at the lower end. The same mesh remains.')}</section>
<article id="reading" class="chapter">{render(lesson)}<p class="quiet"><a href="tutorial.md">Tutorial source</a> · <a href="Trans_Pre.diff">Exact text diff</a> · <a href="../2026-10-03-primitives-closing-tutorials/index.html#composition">Previous: placing bodies</a></p></article>
<article id="sine" class="chapter"><p class="step">Optional comparison · one changed expression</p>{render(sine)}{pair('linear.png', 'Linear, 0.375 s: centre height 1.425 m.', 'sine.png', 'Sine, the same 0.375 s: centre height about 1.477 m. It then slows towards the top.')}<p class="quiet"><a href="tutorial-sine.md">Comparison source</a></p></article>
<section id="code"><article><h2>The complete study</h2><p>The first script contains the operations taught here. The other two supply the marked cube and its readout. All are included in the starter. The lesson uses direct references to objects created in code.</p></article>{''.join(sources)}</section>
<details id="decisions"><summary>What changed and what was checked</summary><div><p>Trans_Pre now has an executable tutorial in the shared starter. The original museum implementation notes are preserved. The main lesson follows the museum's linear timing; the optional sine comparison is a separate student experiment.</p><p>{len(report['checks'])} checks passed in Godot 4.6 against a fresh extraction of the download. These cover actual printed edits, elapsed time, endpoint timing, turn periods, uniform scale, frame partition independence, unchanged mesh data and the sine comparison. Images and film come from the running student room, not the map grid.</p><p>The critical manuscript and museum placement are unchanged. Physical headset use and beginner comprehension remain untested. Coordinates' earlier starter revision is still pending. Local-file browser inspection was blocked by policy; review links and anchors were checked programmatically.</p><p><a href="lesson-contract.json">Teaching contract</a> · <a href="DECISIONS.md">Decisions and source references</a> · <a href="verification.json">Runtime checks</a> · <a href="package-verification.json">Download checks</a> · <a href="verify.gd">Test harness</a></p><p>Next: Trans_Introduction — when the animated surface must also carry a body across a gap.</p></div></details>
</main><script>function reveal(){{const el=document.getElementById(location.hash.slice(1));if(el?.tagName==='DETAILS')el.open=true}}addEventListener('hashchange',reveal);reveal();</script></body></html>'''
(OUT / 'index.html').write_text(page, encoding='utf-8')

class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
        self.ids = set()
    def handle_starttag(self, tag, attrs):
        self.links.extend(v for k, v in attrs if k in ('href', 'src', 'poster'))
        self.ids.update(v for k, v in attrs if k == 'id')

links = Links()
links.feed(page)
local = 0
for link in links.links:
    url = urlsplit(link)
    if url.scheme:
        continue
    if url.path:
        assert (OUT / unquote(url.path)).exists(), link
        local += 1
    elif url.fragment:
        assert url.fragment in links.ids, link
summary = {'printed_code_excerpts_match': len(blocks), 'sine_substitution_run': True, 'local_links_resolve': local, 'runtime_checks': len(report['checks']), 'cold_download_checked': True, 'museum_notes_preserved_exactly': True, 'critical_text_unchanged': True, 'learner_scene_lookups': False, 'words_including_code': {'tutorial': len(lesson.split()), 'sine': len(sine.split())}}
(OUT / 'review-checks.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
print(json.dumps(summary))
