from pathlib import Path
import json, re, hashlib
from publish_wavefunctions_opening import STYLE, render, block

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-unit-circle-two-coordinates'
STUDY=ROOT/'doc/book/studies/wavefunctions-lineage'
MAP=ROOT/'commons/maps/WaveFunctions_Unit_Circle'

def page(title,body):
    return f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{title}</title><style>{STYLE}</style><header><div class="tag">Endless Museum · Wavefunctions · Hall 4</div><h1>{title}</h1><nav><a href="index.html">Evidence</a><a href="parallel.html">Tutorial left · reflection right</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="../2026-10-08-sine-space-a-surface/index.html">Previous: Sine Space</a></nav></header><main>{body}</main></html>'''

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    tutorial=(STUDY/'unit-circle-tutorial.md').read_text(encoding='utf8')
    for token,name in [('CODE','04_circle_coordinates.gd'),('POINT_CODE','point_body.gd'),('LINE_CODE','line_skin.gd')]:
        tutorial=tutorial.replace('{'+token+'}',block(name,(STUDY/name).read_text(encoding='utf8')))
    final=(STUDY/'unit-circle-final.md').read_text(encoding='utf8')
    for name,text in [('tutorial',tutorial),('final',final)]:
        for dest in [MAP,OUT]:(dest/(name+'.md')).write_text(text,encoding='utf8')
        (OUT/(name+'.html')).write_text(page(text.splitlines()[0][2:],'<article>'+render(text)+'</article>'),encoding='utf8')
    (OUT/'parallel.html').write_text(page('One point, two coordinates','<div class="parallel"><article><div class="tag">tutorial.md</div>'+render(tutorial)+'</article><article><div class="tag">final.md</div>'+render(final)+'</article></div>'),encoding='utf8')
    dest=OUT/'extracted';dest.mkdir(exist_ok=True)
    parity=[]
    for name,source in re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tutorial,re.S):
        assert source==(STUDY/name).read_text(encoding='utf8').rstrip()
        (dest/name).write_text(source+'\n',encoding='utf8')
        parity.append({'file':name,'printed_matches_source':True,'sha256':hashlib.sha256((source+'\n').encode()).hexdigest()})
    (OUT/'code-check.json').write_text(json.dumps(parity,indent=2),encoding='utf8')
    evidence=''
    for name,title in [('student-test.json','Printed program'),('after/report.json','Real museum')]:
        if (OUT/name).exists():
            data=json.loads((OUT/name).read_text(encoding='utf8'))
            evidence+=f'<p>{title}: {sum(c["passed"] for c in data["checks"])}/{len(data["checks"])} checks. <a href="{name}">Results</a>.</p>'
    if (OUT/'mutation-tests.json').exists():
        data=json.loads((OUT/'mutation-tests.json').read_text(encoding='utf8'))
        evidence+=f'<p>{sum(x["rejected"] for x in data)}/{len(data)} deliberate faults rejected. <a href="mutation-tests.json">Results</a>.</p>'
    body='''<p>Sine Space made height from position. Here the familiar point and cylinder return: one angle produces a circle position, and its vertical coordinate becomes a graph.</p><p class="status">Fourth hall revised. All seven authored artifact placements remain. The printed construction is temporarily mounted inside the museum for verification.</p><div class="pictures"><figure><img src="after/student.png"><figcaption>The actual printed program, in the existing museum. The black sphere carries PointBody's shape; its position is prescribed by angle.</figcaption></figure><figure><img src="after/projection.png"><figcaption>The existing two-turn exhibit, fitted to its room. A nearby slider stops and sets its angle.</figcaption></figure></div><h2>Writing: before and after</h2><table><tr><th>Before</th><th>After</th></tr><tr><td>Fragments with undeclared runners and a missing scene dependency.</td><td>A complete program, with both unchanged helper files printed.</td></tr><tr><td>Independent clocks and an incorrect quarter-turn chord claim.</td><td>One shared angle; quarter-turn predictions; centre, radius, radians and graph units declared.</td></tr><tr><td>The reflective graph scale described a different display.</td><td>The reflection follows this room: six metres per turn, a finite drawing and a continuing point.</td></tr></table><h2 id="museum">Room to read the relationship</h2><p>The 24 × 29-metre hall has a level forecourt, an unobstructed view of the circle and twelve-metre graph, and a separate area for the bridge, scrolling curve and film. The graph has no collision; the museum floor provides support. The compact display is an opt-in configuration. Other placements retain their original dimensions and behaviour.</p><div class="pictures"><figure><img src="before/museum/above.png"><figcaption>Before: the grid-era enclosure is too small for the expanding graph and bridge.</figcaption></figure><figure><img src="after/gallery.png"><figcaption>After: the primary relationship has its own viewing area, followed by the supporting exhibits.</figcaption></figure><figure><img src="after/control.png"><figcaption>Angle control beside the circle, with run/pause and replay.</figcaption></figure></div><h2>Validation</h2>'''+evidence+'''<p><a href="code-check.json">Printed source parity</a> · <a href="tutorial.md">Editable tutorial</a> · <a href="final.md">Editable reflection</a></p><p class="note">Native Godot checks and captures. These are teacher-authored assertions, not an independent ghost-student reconstruction or headset test. Changes to radius and centre are made before running, so the sampled outlines and moving markers agree.</p><h2>Next: 3D Wave Propagation</h2><p>The next lesson must make the difference between prescribed oscillation and interaction between neighbours visible. Eight halls remain in this pass.</p>'''
    (OUT/'index.html').write_text(page('Unit Circle: two coordinates from one angle',body),encoding='utf8')
    print('Published Unit Circle reading and evidence pages.')

if __name__=='__main__':main()
