from pathlib import Path
import hashlib,json,re,zipfile
from publish_wavefunctions_opening import STYLE,render,block
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-bernini-a-turn-through-height'
STUDY=ROOT/'doc/book/studies/wavefunctions-lineage'
MAP=ROOT/'commons/maps/Wavefunctions_Bernini'

def page(title,body):
    return f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{title}</title><style>{STYLE}</style><header><div class="tag">Endless Museum · Wavefunctions · Hall 7</div><h1>{title}</h1><nav><a href="index.html">Room & evidence</a><a href="parallel.html">Tutorial left · reflection right</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="../2026-10-08-effect-sound-a-phase-you-can-hear/index.html">Previous: Effect Sound</a></nav></header><main>{body}</main></html>'

def main():
    OUT.mkdir(exist_ok=True)
    tutorial=(STUDY/'bernini-tutorial.md').read_text(encoding='utf8')
    for token,name in [('CODE','07_twisted_shaft.gd'),('POINT_CODE','point_body.gd'),('LINE_CODE','line_skin.gd')]:
        tutorial=tutorial.replace('{'+token+'}',block(name,(STUDY/name).read_text(encoding='utf8')))
    final=(STUDY/'bernini-final.md').read_text(encoding='utf8')
    for name,text in [('tutorial',tutorial),('final',final)]:
        for dest in [MAP,OUT]:(dest/(name+'.md')).write_text(text,encoding='utf8')
        (OUT/(name+'.html')).write_text(page(text.splitlines()[0][2:],'<article>'+render(text)+'</article>'),encoding='utf8')
    (OUT/'parallel.html').write_text(page('A movement kept in a column','<div class="parallel"><article><div class="tag">tutorial.md</div>'+render(tutorial)+'</article><article><div class="tag">final.md</div>'+render(final)+'</article></div>'),encoding='utf8')
    dest=OUT/'extracted';dest.mkdir(exist_ok=True)
    parity=[]
    for name,code in re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tutorial,re.S):
        assert code==(STUDY/name).read_text(encoding='utf8').rstrip()
        (dest/name).write_text(code+'\n',encoding='utf8')
        parity.append({'file':name,'printed_matches_source':True,'sha256':hashlib.sha256((code+'\n').encode()).hexdigest()})
    (OUT/'code-check.json').write_text(json.dumps(parity,indent=2),encoding='utf8')
    variant=(dest/'07_twisted_shaft.gd').read_text(encoding='utf8').replace('var height := 2.4','var height := 3.6').replace('var sides := 8','var sides := 12')
    (dest/'07_taller_shaft.gd').write_text(variant,encoding='utf8')
    with zipfile.ZipFile(OUT/'student-code.zip','w',zipfile.ZIP_DEFLATED) as z:
        for row in parity:z.write(dest/row['file'],row['file'])
        z.write(dest/'07_taller_shaft.gd','07_taller_shaft.gd')
        z.writestr('tutorial.md',tutorial);z.writestr('final.md',final)
        z.writestr('READ-ME.txt','Use the prepared Endless Museum working copy with XRToolsPickable. Put the scripts together. Attach 07_twisted_shaft.gd to an empty unit-scale Node3D, hall-local (5,0,10), yaw 180. The optional 07_taller_shaft.gd is the complete 3.6m / 12-sided exercise variant; attach it instead to compare. Full instructions: tutorial.md. Godot 4.6.\n')
    evidence=''
    for name,title in [('student-test.json','Printed program'),('after/report.json','Actual museum')]:
        if (OUT/name).exists():
            data=json.loads((OUT/name).read_text(encoding='utf8'))
            evidence+=f'<p>{title}: {sum(x["passed"] for x in data["checks"])}/{len(data["checks"])} checks. <a href="{name}">Results</a>.</p>'
    if (OUT/'mutation-tests.json').exists():
        tests=json.loads((OUT/'mutation-tests.json').read_text())
        evidence+=f'<p>{sum(x["rejected"] for x in tests)}/{len(tests)} deliberate faults rejected. <a href="mutation-tests.json">Fault checks</a>.</p>'
    body='''<p>The turn now has a height. Return to ring sampling and connected faces, then stop the whole-object rotation and inspect what remains.</p><p class="status">Seventh lesson revised for review. Four authored exhibits and all nine columns retained. A clear forecourt and supported route replace the old entry/exit fallbacks.</p>
<div class="pictures"><figure><img src="after/student.png"><figcaption>The exact printed program inside the museum: an oval shaft, the carried black control sphere and a pink guide through one corner.</figcaption></figure><figure><img src="after/aisle.png"><figcaption>Room to look up and move between the original full-size columns.</figcaption></figure></div>
<h2>Before and after</h2><div class="pictures"><figure><img src="before/museum/entry.png"><figcaption>Before: columns at the threshold, dress partly below the floor; authored entry and exit needed fallbacks.</figcaption></figure><figure><img src="after/gallery.png"><figcaption>After: a 22 × 30 m hall, open forecourt, raised column bases and dress plinth; low voice panel beside the onward route.</figcaption></figure></div>
<h2>The same connections, different turns</h2><div class="pictures"><figure><img src="after/straight.png"><figcaption>Zero turns: profiles align. The face list is already complete.</figcaption></figure><figure><img src="after/full-turn.png"><figcaption>One turn through height: new positions, same connectivity. The clock can remain stopped.</figcaption></figure></div>
<h2>The two texts</h2><p>The tutorial replaces incomplete triangle-strip fragments with a complete, capped shaft. The oval profile makes orientation visible; its two controls separate rebuilding geometry from moving the finished body. The reflection keeps the movement, repetition and architectural encounter, with clearer distinctions between the form and its display.</p><p>The large museum generator retains its richer centre offsets, changing radius, nine-column plan and sound. Its geometry and behaviour have not been rewritten to match the small study.</p>
<h2>Validation</h2>'''+evidence+'''<p><a href="code-check.json">Printed/source parity</a> · <a href="student-code.zip">Complete student code and texts</a> · <a href="tutorial.md">Tutorial manuscript</a> · <a href="final.md">Reflective manuscript</a></p><p class="note">Teacher-authored native assertions test closed connectivity, geometry, generated normals, the real PointBody trigger, pause and an independent variation. Museum evidence checks placements and supported approaches. It does not establish physical-headset comfort or learner understanding.</p><h2>Next: John Cage</h2><p>Choose from a prepared vocabulary, retain a timed event list, then replay it.</p>'''
    (OUT/'index.html').write_text(page('Bernini: a turn through height',body),encoding='utf8')
    print('Published Bernini paired readings and exact code.')

if __name__=='__main__':main()
