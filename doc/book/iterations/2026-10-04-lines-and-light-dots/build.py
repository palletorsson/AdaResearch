from pathlib import Path
from html.parser import HTMLParser
import json
import re
import zipfile
import hashlib

HERE = Path(__file__).resolve().parent
STUDY = HERE.parents[1] / 'studies' / 'line-brush-studies'
PREVIOUS = HERE.parent / '2026-10-04-line-brush-deep-studies'
report = json.loads((HERE / 'verification.json').read_text(encoding='utf-8'))
assert report['passed'] and all(c['passed'] for c in report['checks'])
css = re.search(r'<style>(.*?)</style>', (PREVIOUS / 'index.html').read_text(encoding='utf-8'), re.S).group(1)
files = sorted(p for p in STUDY.iterdir() if p.is_file() and p.suffix in {'.gd', '.gdshader', '.godot', '.tscn', '.md', '.ttf', '.txt'})
manifest = {}
with zipfile.ZipFile(HERE / 'lines-and-light-dots.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
    for path in files:
        data = path.read_bytes()
        if path.name == 'project.godot':
            # Same source project, with the focused drawing scene as its entry.
            data = data.replace(b'res://gallery.tscn', b'res://draw_lines.tscn')
        archive.writestr('lines-and-light-dots/' + path.name, data)
        manifest[path.name] = hashlib.sha256(data).hexdigest()
with zipfile.ZipFile(HERE / 'lines-and-light-dots.zip') as archive:
    for name, sha in manifest.items():
        assert hashlib.sha256(archive.read('lines-and-light-dots/' + name)).hexdigest() == sha

body = '''
<nav><a href="#drawing">The drawing</a><a href="#try">Draw your own</a><a href="../2026-10-04-line-brush-deep-studies/index.html">The six brush studies</a></nav>
<header><div class="eyebrow">Ada / A focused drawing study / 4 October 2026</div><h1>Just lines.<br>Just light.</h1><p>Keep the drawing. Change how it appears: a thin coloured line, or separate points of light. There is no filled face beneath the image.</p></header>
<section id="drawing"><div class="controls" data-viewer="drawing-image"><button data-src="lines.png" data-caption="Thin coloured lines. Each stroke has its own colour and finite thickness." aria-pressed="true">Coloured lines</button><button data-src="dots.png" data-caption="Light dots. The same stored strokes become separate emissive spheres with screen glow." aria-pressed="false">Light dots</button><button data-src="dots-side.png" data-caption="From the side, the deliberately different depths of the strokes become visible." aria-pressed="false">Move around it</button></div><img id="drawing-image" src="lines.png" width="1600" height="1000" alt="A face made only from thin coloured lines"><p id="drawing-image-caption" class="small caption" aria-live="polite">Thin coloured lines. Each stroke has its own colour and finite thickness.</p><p>The face is an authored example. It is made from separate paths, not an underlying head model. Switching modes retains those paths; the dots are sampled along them by distance.</p></section>
<section class="section" id="try"><h2>Make a drawing.</h2><p>Open the downloadable Godot project and run. Press <strong>C</strong> to start empty. <strong>Left-drag</strong> draws; a <strong>click</strong> leaves one point. Release to lift the pen. <strong>B</strong> switches between lines and light dots.</p><p><strong>X</strong> changes the next colour. <strong>Right-drag</strong> moves around the drawing; <strong>Shift + wheel</strong> changes drawing depth. <strong>[ / ]</strong> change size, <strong>G</strong> toggles glow, and <strong>Z</strong> undoes. <strong>F5 / F9</strong> save and load locally.</p><div class="download"><a class="button" href="lines-and-light-dots.zip" download>Download the drawing project</a><a href="../../studies/line-brush-studies/DRAWING.md">All controls</a></div><figure><img src="input-dots.png" width="1600" height="1000" loading="lazy" alt="Separate coloured strokes and a single point from the input replay"><figcaption>A separate scripted input test exercises drawing, pen lifts, colour changes and a single click. It uses the real mouse input handler; it is not presented as a person's hand drawing.</figcaption></figure><p>The drawing plane is a desktop way of giving a gesture depth. This scene does not yet read a tracked hand or pressure-sensitive pen. The dots emit colour and bloom on screen; they do not light the surrounding room.</p><details><summary>Test evidence</summary><p>CHECK_COUNT native checks passed, covering the mode switch, stored strokes, separate marks, click-dots, depth, glow, undo and local save/load. <a href="verification.json">Read the test results</a>.</p><p>The complete download starts in <code>draw_lines.tscn</code>. The six-form gallery remains available as <code>gallery.tscn</code>. The original study's main scene is unchanged.</p></details></section>
<footer>Ada / Native Godot 4.6 captures / Desktop replay tested / VR untested.</footer>
'''.replace('CHECK_COUNT', str(len(report['checks'])))
script = '''document.querySelectorAll('[data-viewer]').forEach(group=>{const id=group.dataset.viewer;group.querySelectorAll('button').forEach(b=>b.addEventListener('click',()=>{const im=document.getElementById(id);im.src=b.dataset.src;im.alt=b.dataset.caption;document.getElementById(id+'-caption').textContent=b.dataset.caption;group.querySelectorAll('button').forEach(other=>other.setAttribute('aria-pressed',String(other===b)));}));});'''
page = '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Coloured lines and light dots — Ada</title><style>' + css + '</style></head><body><main>' + body + '</main><script>' + script + '</script></body></html>'
class Links(HTMLParser):
    count = 0
    def handle_starttag(self, tag, attrs):
        for key, value in attrs:
            if key in ('href', 'src', 'data-src') and value and not value.startswith(('http:', 'https:', '#')):
                assert (HERE / value.split('#')[0]).is_file(), value
                self.count += 1
links = Links()
links.feed(page)
(HERE / 'index.html').write_text(page, encoding='utf-8')
(HERE / 'page-script.js').write_text(script, encoding='utf-8')
(HERE / 'source-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
result = {'passed': True, 'native_checks': len(report['checks']), 'local_links': links.count, 'packaged_files': len(files), 'entry_scene': 'draw_lines.tscn'}
(HERE / 'package-checks.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
print(json.dumps(result))
