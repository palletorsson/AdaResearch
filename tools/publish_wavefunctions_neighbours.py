from pathlib import Path
import json, re, hashlib
from publish_wavefunctions_opening import STYLE, render, block

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-wave-propagation-between-points'
STUDY=ROOT/'doc/book/studies/wavefunctions-lineage'
MAP=ROOT/'commons/maps/WaveFunctions_3D_Wave_Propagation'

def page(title,body):
    return f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{title}</title><style>{STYLE}</style><header><div class="tag">Endless Museum · Wavefunctions · Hall 5</div><h1>{title}</h1><nav><a href="index.html">Room & evidence</a><a href="parallel.html">Tutorial left · reflection right</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="../2026-10-08-unit-circle-two-coordinates/index.html">Previous: Unit Circle</a></nav></header><main>{body}</main></html>'

def main():
    tutorial=(STUDY/'propagation-tutorial.md').read_text(encoding='utf8')
    for token,name in [('CODE','05_neighbour_motion.gd'),('POINT_CODE','point_body.gd'),('LINE_CODE','line_skin.gd')]:
        tutorial=tutorial.replace('{'+token+'}',block(name,(STUDY/name).read_text(encoding='utf8')))
    final=(STUDY/'propagation-final.md').read_text(encoding='utf8')
    for name,text in [('tutorial',tutorial),('final',final)]:
        for dest in [MAP,OUT]:(dest/(name+'.md')).write_text(text,encoding='utf8')
        (OUT/(name+'.html')).write_text(page(text.splitlines()[0][2:],'<article>'+render(text)+'</article>'),encoding='utf8')
    (OUT/'parallel.html').write_text(page('A point keeps its place; a disturbance travels','<div class="parallel"><article><div class="tag">tutorial.md</div>'+render(tutorial)+'</article><article><div class="tag">final.md</div>'+render(final)+'</article></div>'),encoding='utf8')
    dest=OUT/'extracted';dest.mkdir(exist_ok=True)
    parity=[]
    for name,source in re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tutorial,re.S):
        assert source==(STUDY/name).read_text(encoding='utf8').rstrip()
        (dest/name).write_text(source+'\n',encoding='utf8')
        parity.append({'file':name,'printed_matches_source':True,'sha256':hashlib.sha256((source+'\n').encode()).hexdigest()})
    (OUT/'code-check.json').write_text(json.dumps(parity,indent=2),encoding='utf8')
    evidence=''
    for name,title in [('student-test.json','Printed program'),('after/report.json','Actual museum')]:
        if (OUT/name).exists():
            data=json.loads((OUT/name).read_text(encoding='utf8'))
            evidence+=f'<p>{title}: {sum(c["passed"] for c in data["checks"])}/{len(data["checks"])} checks. <a href="{name}">Results</a>.</p>'
    if (OUT/'mutation-tests.json').exists():
        data=json.loads((OUT/'mutation-tests.json').read_text(encoding='utf8'))
        evidence+=f'<p>{sum(x["rejected"] for x in data)}/{len(data)} deliberate faults rejected. <a href="mutation-tests.json">Fault checks</a>.</p>'
    body='''<p>One familiar sphere becomes a short row. Each point keeps its own displacement and velocity; a difference between neighbours now contributes force. The tutorial builds this relation. The reflection asks what it means to see movement without yet knowing how it was produced.</p>
    <p class="status">Fifth hall revised for review. All five authored exhibits remain. Room and code evidence below are native Godot captures, not generated illustrations.</p>
    <div class="pictures"><figure><img src="after/student.png"><figcaption>The exact printed program, temporarily mounted in the museum: PointBody, LineSkin, and one shared old state.</figcaption></figure><figure><img src="after/lattice.png"><figcaption>The existing two-dimensional lattice and its comparison controls. The rods now include the diagonal links the force rule actually uses.</figcaption></figure></div>
    <h2>Before and after</h2><div class="pictures"><figure><img src="before/museum/above.png"><figcaption>Before: overlapping fields, narrow unsupported approaches and a blocked-entrance fallback.</figcaption></figure><figure><img src="after/gallery.png"><figcaption>After: separate bays, level approaches, primary comparison near the entrance and a perimeter route around the tiled display.</figcaption></figure></div>
    <table><tr><th>Earlier draft</th><th>Current lesson</th></tr><tr><td>Neighbour-coupling labels followed by analytic field snippets, undeclared arrays and missing scene files.</td><td>Complete working row, printed once with the two unchanged carried classes.</td></tr><tr><td>Two unrelated source bodies introduced without a complete construction.</td><td>The same PointBody sphere becomes a local receiver; Forces' state update and Arrays' indices return.</td></tr><tr><td>A similar wave image implied a shared mechanism.</td><td>The coupled lattice and prescribed distance field are explicitly distinguished.</td></tr></table>
    <h2 id="museum">The hall</h2><p>The 24 × 36-metre room keeps the lattice, tiled field, Kusama sculpture, dark sphere and film. The film and lattice come first. The larger sculpture has its own bay; the tiled field has space at the rear. The student row fits beside the entrance without replacing the installed lattice.</p><p>The lattice's force rule, coefficients and button resets are unchanged. Its bond drawing is corrected to include every unique neighbour relation, including diagonals, and disappears when the visitor disconnects coupling. The secondary tiled field remains a distance-and-time construction.</p>
    <h2>Validation</h2>'''+evidence+'''<p><a href="code-check.json">Printed source parity</a> · <a href="tutorial.md">Editable tutorial</a> · <a href="final.md">Editable reflection</a> · <a href="student-code.zip">Three runnable source files</a></p><p class="note">Teacher-authored native assertions, including first-step predictions, symmetry, uncoupled motion and an independent seven-point variation. Museum checks cover actual controls, floor support, sightlines and the printed lesson in its bay. Headset testing and an independent ghost-student reconstruction remain open.</p><h2>Next: Effect Sound</h2><p>One oscillation changes another's phase. Five Wavefunctions lessons are now revised; seven remain.</p>'''
    (OUT/'index.html').write_text(page('Propagation: between points',body),encoding='utf8')
    import zipfile
    with zipfile.ZipFile(OUT/'student-code.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for row in parity:archive.write(dest/row['file'],row['file'])
    print('Published Propagation, paired readings and extracted code.')

if __name__=='__main__':main()
