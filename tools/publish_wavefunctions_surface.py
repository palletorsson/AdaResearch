"""Publish the third hall, keeping its program and both reading tracks together."""
from pathlib import Path
import json, re, shutil, hashlib
from publish_wavefunctions_opening import STYLE, render, block

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-sine-space-a-surface'
STUDY=ROOT/'doc/book/studies/wavefunctions-lineage'
MAP=ROOT/'commons/maps/WaveFunctions_Sine_Space'

def page(title,body):
    return f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{title}</title><style>{STYLE}</style><header><div class="tag">Endless Museum · Wavefunctions · Hall 3</div><h1>{title}</h1><nav><a href="index.html">Evidence</a><a href="parallel.html">Tutorial left · reflection right</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="../2026-10-08-pendulum-a-record-of-return/index.html">Previous: Pendulum</a></nav></header><main>{body}</main></html>'''

def main():
    OUT.mkdir(exist_ok=True,parents=True)
    code=(STUDY/'03_sine_surface.gd').read_text(encoding='utf8')
    point=(STUDY/'point_body.gd').read_text(encoding='utf8')
    assert point==(ROOT/'doc/book/studies/forces-point-lineage/point_body.gd').read_text(encoding='utf8')
    tutorial=(STUDY/'sine-space-tutorial.md').read_text(encoding='utf8').replace('{CODE}',block('03_sine_surface.gd',code)).replace('{POINT_CODE}',block('point_body.gd',point)).rstrip()+'\n'
    final=(STUDY/'sine-space-final.md').read_text(encoding='utf8').rstrip()+'\n'
    for name,text in [('tutorial',tutorial),('final',final)]:
        (MAP/(name+'.md')).write_text(text,encoding='utf8')
        (OUT/(name+'.md')).write_text(text,encoding='utf8')
        (OUT/(name+'.html')).write_text(page(text.splitlines()[0][2:],'<article>'+render(text)+'</article>'),encoding='utf8')
    (OUT/'parallel.html').write_text(page('A surface and what it permits','<div class="parallel"><article><div class="tag">tutorial.md</div>'+render(tutorial)+'</article><article><div class="tag">final.md</div>'+render(final)+'</article></div>'),encoding='utf8')
    dest=OUT/'extracted';dest.mkdir(exist_ok=True)
    checks=[]
    for name,source in re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tutorial,re.S):
        assert source==(STUDY/name).read_text(encoding='utf8').rstrip()
        (dest/name).write_text(source+'\n',encoding='utf8')
        checks.append({'file':name,'printed_matches_source':True,'sha256':hashlib.sha256((source+'\n').encode()).hexdigest()})
    (OUT/'code-check.json').write_text(json.dumps(checks,indent=2),encoding='utf8')
    evidence=''
    for name,title in [('student-test.json','Exact printed program'),('after/report.json','Inside the museum')]:
        path=OUT/name
        if path.exists():
            data=json.loads(path.read_text(encoding='utf8')); tests=data['checks']
            evidence+=f'<p>{title}: {sum(t["passed"] for t in tests)}/{len(tests)} checks. <a href="{name}">Results</a>.</p>'
    p=OUT/'mutation-tests.json'
    if p.exists():
        data=json.loads(p.read_text(encoding='utf8'))
        evidence+=f'<p>{sum(x["rejected"] for x in data)}/{len(data)} deliberate faults rejected. <a href="mutation-tests.json">Fault results</a>.</p>'
    body='''<p>The cube introduced a sine of time. Pendulum distinguished a movement from its record. Here a sine of position becomes a surface: grid addresses return as triangle faces, and the familiar PointBody returns to test their support.</p><p class="status">Third hall rewritten. All five authored exhibits remain. The student reconstruction is temporarily mounted for native verification.</p><div class="pictures"><figure><img src="after/student.png"><figcaption>The complete printed construction, inside the Endless Museum. The PointBody is the unchanged class from Forces.</figcaption></figure><figure><img src="after/coarse.png"><figcaption>Same height rule, only four cells: samples miss every crest. The black sphere now meets an almost flat sheet.</figcaption></figure></div><h2>What changed in the writing</h2><table><tr><th>Before</th><th>After</th></tr><tr><td>Production fragments followed several artifacts without a complete construction.</td><td>One complete two-file study: a static spatial function, shared positions, known triangles and a matching receiver.</td></tr><tr><td>Substantial implementation code interrupted the reflection; the ending described an older moving sphere field.</td><td>The reflection follows contact, the deadline and apparent passage. It now ends on the actual stationary, walkable sine floor.</td></tr><tr><td>The proposed sampling lesson had no executable transfer check.</td><td>Predict heights, distinguish height from spacing, expose missed crests, then independently separate the X and Z frequencies.</td></tr></table><h2 id="museum">A route fitted to the exhibits</h2><p>The 14 × 40-metre hall has an open forecourt, a north–south wave corridor and a silver surface in a basin, with level paths beside it. The old eight-metre partitions are removed. The explanation model stands at reading height, and both entry and exit have supported approaches. An opt-in exact fit closes the narrow basin seam: the complete half-waves are scaled to its eight-by-eighteen-metre footprint, with matching collision. Other placements retain their old fit.</p><div class="pictures"><figure><img src="before/museum/above.png"><figcaption>Before: the inherited enclosure hides the encounters and its exit approach is unsupported.</figcaption></figure><figure><img src="after/gallery.png"><figcaption>After: tray, corridor and terrain remain distinct encounters along one route.</figcaption></figure><figure><img src="after/tray.png"><figcaption>The installed tray keeps its thirty-two-body trial and adjacent controls.</figcaption></figure><figure><img src="after/corridor.png"><figcaption>Visible walls invite a path, but do not collide. The floor does.</figcaption></figure><figure><img src="after/floor.png"><figcaption>A still sine surface changes the player's height through contact.</figcaption></figure></div><h2>Validation</h2>'''+evidence+'''<p><a href="code-check.json">Printed source parity</a> · <a href="tutorial.md">Editable tutorial</a> · <a href="final.md">Editable reflection</a></p><p class="note">Native Godot/Jolt checks and captures. Teacher-authored tests, not an independent ghost-student reconstruction. Headset comfort and learning outcomes remain to be tested with people. The existing unrelated UID warning remains in the logs; the final run contains no script errors or blocked-passage fallback. The study uses the museum's installed XR Tools; it does not set up a replacement world.</p><h2>Next: Unit Circle</h2><p>Where does the returning height come from? A point moves around a circle, and its coordinate becomes a graph. The remaining nine halls still await this writing and validation pass.</p>'''
    (OUT/'index.html').write_text(page('Sine Space: a rule becomes a surface',body),encoding='utf8')
    print('Published Sine Space study, tutorial, reflection and evidence page.')

if __name__=='__main__':main()
