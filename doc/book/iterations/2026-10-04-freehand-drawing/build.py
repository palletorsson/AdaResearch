from pathlib import Path
from html.parser import HTMLParser
import json
import re
import difflib

HERE = Path(__file__).resolve().parent
PREVIOUS = HERE.parent / '2026-10-04-painting-space-second-pass'
STUDY = HERE.parents[1] / 'studies/painting-space'
report = json.loads((HERE / 'verification.json').read_text(encoding='utf-8'))
assert report['passed'] and all(c['passed'] for c in report['checks'])
assert not (HERE / 'verify-errors.log').read_text(encoding='utf-8').strip()
css = re.search(r'<style>(.*?)</style>', (PREVIOUS / 'index.html').read_text(encoding='utf-8'), re.S).group(1)
body = '''<nav><a href="../2026-10-04-line-brush-deep-studies/index.html">New: line as brushstroke</a><a href="#drawing">The drawing</a><a href="#manual">Mouse test</a><a href="#try">Try it</a><a href="../2026-10-04-painting-space-second-pass/blog.html">Read the blog</a></nav>
<header><div class="eyebrow">Ada / Freehand drawing test / 4 October 2026</div><h1>A drawing<br>leaves the plane.</h1><p>A face made from separate strokes. Its eyes and nose sit in front of its outline. The same marks can become soft colour, transparent spheres or a thin line of light.</p></header>
<section class="copy" id="drawing"><h2>One drawing, three appearances</h2><p>This irregular portrait was replayed through the ordinary mouse input handler: eight pen-down strokes, with pen lifts between them. Its 584 marks occupy four depth layers spanning 0.9 metres. It is a repeatable drawing test; the Mona Lisa remains a future experiment.</p>
<div class="controls" role="group" aria-label="Compare drawing representations"><button data-src="portrait-soft.png" aria-pressed="false">Soft colour</button><button data-src="portrait-spheres.png" aria-pressed="true">Transparent spheres</button><button data-src="portrait-lines.png" aria-pressed="false">Light points</button><button data-src="portrait-side.png" aria-pressed="false">From the side</button></div>
<img id="portrait" src="portrait-spheres.png" alt="A face drawn with overlapping transparent spherical shells" width="1600" height="1000"><p id="caption" class="small" aria-live="polite">Transparent spheres — native Godot capture.</p>
<p>The light points retain the clearest outline. Spheres give each stroke a thicker body; their overlaps brighten. Soft colour blurs the edges. Moving around the drawing reveals the depth we deliberately gave it.</p></section>
<section class="copy" id="manual"><h2>Actual mouse strokes</h2><img src="manual-light.png" alt="Desktop mouse test: a pink triangle and a separate cyan stroke, displayed as light points" width="1600" height="1000" loading="lazy"><p class="small">Three pink drags, then one cyan drag closer to the viewer. This was entered through the desktop window, independently of the portrait replay.</p><p>Pen lifts keep strokes separate. Changing materials retains their positions. The wheel moves the next stroke closer or farther away; it can also change depth while drawing.</p></section>
<section class="copy"><h2>One problem fixed</h2><p>Switching away from the window during a stroke could leave the brush drawing. It now ends the stroke when the window loses focus. All CHECK_COUNT targeted checks pass, including separate strokes, depth, material changes, undo, save/load and the focus fix.</p><p>Depth still asks for a deliberate gesture with the wheel or a change of viewpoint. This is a working desktop brush. Tracked-hand use in VR remains to be tested.</p><details><summary>Test evidence and limits</summary><p><a href="RESULTS.md">Findings and controls</a> · <a href="verification.json">32 passing checks</a> · <a href="before-fix.json">The two failures before repair</a> · <a href="manual-session.json">Desktop input session</a> · <a href="study.diff">Code change</a></p><p>Holding still deposits extra marks. At 900 marks the oldest are recycled. These tests support small drawings, not an unlimited painting system. Test saves are separate from the user's F5 save.</p></details></section>
<section class="copy" id="try"><h2>Try a drawing</h2><p>Open the project in Godot 4.6 and run. Press <strong>5</strong>, then <strong>C</strong> for an empty canvas. Press <strong>[</strong> two or three times for a narrower brush.</p><p><strong>Left-drag</strong> draws; releasing lifts the pen. <strong>Wheel</strong> changes depth, <strong>X</strong> colour and <strong>B</strong> material. <strong>Shift + left-drag</strong> lets you orbit. <strong>Z</strong> undoes. <strong>F5 / F9</strong> save and load locally.</p><a class="button primary" href="../2026-10-04-painting-space-second-pass/painting-space.zip" download>Download the updated Godot study</a></section>
<footer>Ada / Native Godot captures / Desktop input tested / No headset test.</footer>'''.replace('CHECK_COUNT', str(len(report['checks'])))
script = '''document.querySelectorAll('button[data-src]').forEach(b=>b.addEventListener('click',()=>{const im=document.getElementById('portrait');im.src=b.dataset.src;im.alt=b.textContent+' — the same portrait drawing in Godot';document.getElementById('caption').textContent=b.textContent+' — native Godot capture.';document.querySelectorAll('button[data-src]').forEach(other=>other.setAttribute('aria-pressed',String(other===b)));}));'''
page = '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Freehand drawing — Ada</title><style>' + css + '</style></head><body><main>' + body + '</main><script>' + script + '</script></body></html>'
(HERE / 'study.diff').write_text(''.join(difflib.unified_diff((HERE/'study-before.gd.txt').read_text(encoding='utf-8').splitlines(True), (STUDY/'study.gd').read_text(encoding='utf-8').splitlines(True), fromfile='study.gd before', tofile='study.gd after')),encoding='utf-8')
(HERE / 'index.html').write_text(page,encoding='utf-8')

class Links(HTMLParser):
    count = 0
    def handle_starttag(self, tag, attrs):
        for name, value in attrs:
            if name in ('href', 'src', 'data-src') and value and not value.startswith(('http:', 'https:', '#')):
                assert (HERE / value.split('#')[0]).exists(), value
                self.count += 1

links = Links()
links.feed(page)
result = {'native_checks':len(report['checks']), 'passed':report['passed'], 'local_links':links.count, 'portrait_marks':report['portrait_marks'], 'desktop_mouse_marks':269}
(HERE/'package-checks.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result))
