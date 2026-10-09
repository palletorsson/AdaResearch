from pathlib import Path
import hashlib,json,re,zipfile
from publish_wavefunctions_opening import STYLE,render,block
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-sky-stairs-a-place-for-a-foot'
STUDY=ROOT/'doc/book/studies/wavefunctions-lineage'
MAP=ROOT/'commons/maps/Wavefunctions_Sky_Stairs'

def page(title,body):
    return f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{title}</title><style>{STYLE}</style><header><div class="tag">Endless Museum · Wavefunctions · Hall 10</div><h1>{title}</h1><nav><a href="index.html">Room & evidence</a><a href="parallel.html">Tutorial left · reflection right</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="../2026-10-08-air-music-after-contact/index.html">Previous: Air Music</a></nav></header><main>{body}</main></html>'

def main():
    OUT.mkdir(exist_ok=True)
    tutorial=(STUDY/'sky-stairs-tutorial.md').read_text(encoding='utf8')
    for token,name in [('CODE','10_sampled_treads.gd'),('LINE_CODE','line_skin.gd')]:
        tutorial=tutorial.replace('{'+token+'}',block(name,(STUDY/name).read_text(encoding='utf8')))
    final=(STUDY/'sky-stairs-final.md').read_text(encoding='utf8')
    for name,text in [('tutorial',tutorial),('final',final)]:
        for dest in [MAP,OUT]:(dest/(name+'.md')).write_text(text,encoding='utf8')
        (OUT/(name+'.html')).write_text(page(text.splitlines()[0][2:],'<article>'+render(text)+'</article>'),encoding='utf8')
    (OUT/'parallel.html').write_text(page('A place for a foot','<div class="parallel"><article><div class="tag">tutorial.md</div>'+render(tutorial)+'</article><article><div class="tag">final.md</div>'+render(final)+'</article></div>'),encoding='utf8')
    dest=OUT/'extracted';dest.mkdir(exist_ok=True);parity=[]
    for name,code in re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tutorial,re.S):
        assert code==(STUDY/name).read_text(encoding='utf8').rstrip()
        (dest/name).write_text(code+'\n',encoding='utf8')
        parity.append({'file':name,'printed_matches_source':True,'sha256':hashlib.sha256((code+'\n').encode()).hexdigest()})
    production=['sine_cylinder_staircase.gd','sine_cylinder_staircase.tscn']
    unchanged=all((OUT/'before'/name).read_bytes()==(ROOT/'algorithms/wavefunctions/sine_cylinder_staircase'/name).read_bytes() for name in production)
    (OUT/'code-check.json').write_text(json.dumps({'files':parity,'production_stair_unchanged':unchanged},indent=2),encoding='utf8')
    variant=(dest/'10_sampled_treads.gd').read_text(encoding='utf8').replace('var amplitude := 0.45','var amplitude := 0.0')
    (dest/'10_constant_radius.gd').write_text(variant,encoding='utf8')
    with zipfile.ZipFile(OUT/'student-code.zip','w',zipfile.ZIP_DEFLATED) as z:
        for row in parity:z.write(dest/row['file'],row['file'])
        z.write(dest/'10_constant_radius.gd','10_constant_radius.gd')
        z.writestr('tutorial.md',tutorial);z.writestr('final.md',final)
        z.writestr('READ-ME.txt','Prepared Endless Museum, Godot 4.6. Put scripts together. Attach 10_sampled_treads.gd to empty unit-scale Node3D at hall-local (16,0,10), yaw0, inside Wavefunctions_Sky_Stairs. The constant-radius variation replaces that script. See tutorial.md for full context and validation limits.\n')
    evidence=''
    for name,title in [('student-test.json','Exact printed program'),('after/report.json','Actual museum')]:
        if (OUT/name).exists():
            data=json.loads((OUT/name).read_text(encoding='utf8'))
            evidence+=f'<p>{title}: {sum(x["passed"] for x in data["checks"])}/{len(data["checks"])} checks. <a href="{name}">Results</a>.</p>'
    if (OUT/'mutation-tests.json').exists():
        data=json.loads((OUT/'mutation-tests.json').read_text())
        evidence+=f'<p>{sum(x["rejected"] for x in data)}/{len(data)} deliberate faults rejected. <a href="mutation-tests.json">Fault checks</a>.</p>'
    body='''<p>The cube returns as a tread. A sampled curve gives positions; width, orientation and collision determine what can support a body.</p><p class="status">Tenth lesson revised for review. All four authored artifact placements retained; full stair generator preserved.</p>
<div class="pictures"><figure><img src="after/student.png"><figcaption>The exact printed eleven-tread study inside Endless Museum. The pink line joins top centres; only the boxes supply collision.</figcaption></figure><figure><img src="after/stair.png"><figcaption>The existing two-turn stair, now grounded and given room around its full extent.</figcaption></figure></div>
<h2>Before and after</h2><div class="pictures"><figure><img src="before/museum/above.png"><figcaption>Before: remnants of the grid layout crowded the helix, with a blocked authored arrival and exhibits below the floor.</figcaption></figure><figure><img src="after/gallery.png"><figcaption>After: a 24 × 26 m viewing floor, a clear route through the middle and a continuous support for the mathematical specimens.</figcaption></figure></div>
<h2>What the lesson adds</h2><p>Unit Circle supplies coordinates; Transformation supplies placement and turning; the cube and line return as recognizable pieces. Sine modulates radius, while height rises uniformly. A complete, short construction replaces the obsolete three-stair proposal and missing scene dependencies. The constant-radius exercise holds count, height and turning fixed.</p><p>The reflection retains its question: when does a curve become a usable route? It distinguishes centres from edges, apparent continuity from support, and a regular equation from provision for different bodies.</p>
<p>A native check caught off-origin mathematical specimens falling through their support. The gallery fallback now aligns collision to each generated mesh bounds; formulas and existing supplied shapes are preserved. <a href="CHANGES.md">Detailed changes and reproduction steps</a>.</p><h2>Validation</h2>'''+evidence+'''<p><a href="code-check.json">Printed/source parity and preserved generator</a> · <a href="student-code.zip">Complete code + texts</a> · <a href="tutorial.md">Tutorial manuscript</a> · <a href="final.md">Reflection manuscript</a></p><p class="note">Native assertions verify construction, contact, a dropped sphere, a changed-radius example and floor-level viewing access. They do not establish full staircase ascent, headset comfort or independent student understanding. The tall stair retains its existing 0.30 m membrane offset; an upper landing and a continuous climbing route are not claimed. Captures use Compatibility rendering. Logs retain unrelated project UID and renderer-feature warnings.</p><h2>Next: Trig Walking Path</h2><p>Two nearby cycles: what becomes visible and audible as they come together and move apart?</p>'''
    (OUT/'index.html').write_text(page('Sky Stairs: a place for a foot',body),encoding='utf8')
    print('Published Sky Stairs paired readings and exact code.')

if __name__=='__main__':main()
