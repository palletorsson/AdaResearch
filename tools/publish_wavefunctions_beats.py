from pathlib import Path
import hashlib,json,re,zipfile
from publish_wavefunctions_opening import STYLE,render,block
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-beats-a-difference-in-time'
STUDY=ROOT/'doc/book/studies/wavefunctions-lineage'
MAP=ROOT/'commons/maps/WaveFunctions_TrigWalkingPath'

def page(title,body):
    return f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{title}</title><style>{STYLE}</style><header><div class="tag">Endless Museum · Wavefunctions · Hall 11</div><h1>{title}</h1><nav><a href="index.html">Room & evidence</a><a href="parallel.html">Tutorial left · reflection right</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="../2026-10-08-sky-stairs-a-place-for-a-foot/index.html">Previous: Sky Stairs</a></nav></header><main>{body}</main></html>'

def main():
    OUT.mkdir(exist_ok=True)
    tutorial=(STUDY/'beats-tutorial.md').read_text(encoding='utf8')
    for token,name in [('CODE','11_two_cycles.gd'),('POINT_CODE','point_body.gd'),('LINE_CODE','line_skin.gd')]:
        tutorial=tutorial.replace('{'+token+'}',block(name,(STUDY/name).read_text(encoding='utf8')))
    final=(STUDY/'beats-final.md').read_text(encoding='utf8')
    for name,text in [('tutorial',tutorial),('final',final)]:
        for dest in [MAP,OUT]:(dest/(name+'.md')).write_text(text,encoding='utf8')
        (OUT/(name+'.html')).write_text(page(text.splitlines()[0][2:],'<article>'+render(text)+'</article>'),encoding='utf8')
    (OUT/'parallel.html').write_text(page('A difference in time','<div class="parallel"><article><div class="tag">tutorial.md</div>'+render(tutorial)+'</article><article><div class="tag">final.md</div>'+render(final)+'</article></div>'),encoding='utf8')
    dest=OUT/'extracted';dest.mkdir(exist_ok=True);parity=[]
    for name,code in re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tutorial,re.S):
        assert code==(STUDY/name).read_text(encoding='utf8').rstrip()
        (dest/name).write_text(code+'\n',encoding='utf8')
        parity.append({'file':name,'printed_matches_source':True,'sha256':hashlib.sha256((code+'\n').encode()).hexdigest()})
    def function_text(text,name):
        return re.search(r'^func '+re.escape(name)+r'\(.*?(?=^func |\Z)',text,re.M|re.S).group().strip()
    beat=ROOT/'algorithms/wavefunctions/beat_frequency'
    before=(OUT/'before/beat_frequency_demo.gd').read_text(encoding='utf8')
    current=(beat/'beat_frequency_demo.gd').read_text(encoding='utf8')
    preservation={
        'beat_wave_calculation_unchanged':function_text(before,'_animate_spheres')==function_text(current,'_animate_spheres'),
        'beat_scene_unchanged':(OUT/'before/beat_frequency_demo.tscn').read_bytes()==(beat/'beat_frequency_demo.tscn').read_bytes(),
        'circulating_path_generator_unchanged':(OUT/'before/TrigWalkingPath.gd').read_bytes()==(ROOT/'algorithms/wavefunctions/oscillation_driver/TrigWalkingPath.gd').read_bytes(),
    }
    assert all(preservation.values())
    (OUT/'code-check.json').write_text(json.dumps({'files':parity,'preserved':preservation,'production_repairs':['Beat slider callbacks and initial positions; bottom label states half gain.','Interference uses a fixed local sampling plane and local sources.']},indent=2),encoding='utf8')
    variant=(dest/'11_two_cycles.gd').read_text(encoding='utf8').replace('var frequency_a := 4.0','var frequency_a := 5.0').replace('Vector3(-2.1, 1.7, 0.5)','Vector3(-2.1, 1.45, 0.5)')
    (dest/'11_faster_pair.gd').write_text(variant,encoding='utf8')
    with zipfile.ZipFile(OUT/'student-code.zip','w',zipfile.ZIP_DEFLATED) as z:
        for row in parity:z.write(dest/row['file'],row['file'])
        z.write(dest/'11_faster_pair.gd','11_faster_pair.gd')
        z.writestr('tutorial.md',tutorial);z.writestr('final.md',final)
        z.writestr('READ-ME.txt','Prepared Endless Museum, Godot 4.6. Put scripts together. Attach 11_two_cycles.gd to empty unit-scale Node3D at hall-local (23,0,12), yaw180, inside WaveFunctions_TrigWalkingPath. The faster-pair variation replaces that script. See tutorial.md for full context and validation limits.\n')
    evidence=''
    for name,title in [('student-test.json','Exact printed program'),('after/report.json','Actual museum')]:
        if (OUT/name).exists():
            data=json.loads((OUT/name).read_text(encoding='utf8'))
            evidence+=f'<p>{title}: {sum(x["passed"] for x in data["checks"])}/{len(data["checks"])} checks. <a href="{name}">Results</a>.</p>'
    if (OUT/'mutation-tests.json').exists():
        data=json.loads((OUT/'mutation-tests.json').read_text())
        evidence+=f'<p>{sum(x["rejected"] for x in data)}/{len(data)} deliberate faults rejected. <a href="mutation-tests.json">Fault checks</a>.</p>'
    body='''<p>Two fast motions produce a slow pulse. Keep both signed inputs, add them, then make the drawing scale explicit.</p><p class="status">Eleventh lesson revised for review. All six authored exhibits retained. Beat calculations and the circulating path generator are preserved; controls and interference coordinates are repaired.</p>
<div class="pictures"><figure><img src="after/student.png"><figcaption>The exact printed study, installed for validation: the carried black point selects B, its trigger starts both sources together, and three rows retain the distinction between source, sum and display gain.</figcaption></figure><figure><img src="after/paths.png"><figcaption>The complete finite red-and-blue paths now have their own open basin, a near bridge, far ramp and a separate descent to the catch floor.</figcaption></figure></div>
<h2>Before and after</h2><div class="pictures"><figure><img src="before/museum/above.png"><figcaption>Before: a 24-metre artifact crosses a 14-metre hall, intersecting the arrival; much of the oscillation lies below the floor.</figcaption></figure><figure><img src="after/gallery.png"><figcaption>After: a 34 × 48 m hall. Compare beats near the entrance, follow the paths beside the central passage, then encounter coordinate curves and the interference field.</figcaption></figure></div>
<h2>The two texts</h2><p>The tutorial replaces the archived endless-path proposal with a complete three-file program. It carries PointBody and LineSkin, uses a shared start, retains the raw signed sum and shows half gain only at the drawing step. A faster pair tests whether beat period belongs to the frequency difference.</p><p>The reflection retains the slow pulse and the question of what a quiet sum conceals. It also qualifies the claim about a curve that never repeats: a finite drawing cannot establish infinity.</p><p>The beat sliders now start at their actual frequencies and respond through the correct one-argument signal. The lower row is labelled (A+B)/2 so its gain is visible.</p><p>The interference field had mixed world positions with local sources. Its placement now leaves the arithmetic unchanged, and the fixed sampling plane no longer feeds yesterday's drawn height into today's distance. The actual field and its explanatory apparatus use the same local source terms.</p>
<h2>Validation</h2>'''+evidence+'''<p><a href="code-check.json">Printed/source parity and preserved beat generator</a> · <a href="student-code.zip">Complete code + texts</a> · <a href="tutorial.md">Tutorial manuscript</a> · <a href="final.md">Reflection manuscript</a></p><p class="note">Teacher-authored native checks cover the exact printed files, pickup action, known signal values, display gain, an independent frequency variation, real exhibit controls and museum access. The tests do not establish independent student understanding or headset comfort. Full traversal of the circulating paths remains a playtest; this lesson verifies their placement and access. The beat displays are visual only. Captures use Compatibility rendering; unrelated project UID and renderer warnings remain in the logs.</p><h2>Next: Synthesis Lab</h2><p>Keep the signed sum; change what several harmonic components contribute.</p>'''
    (OUT/'index.html').write_text(page('Beats: a difference in time',body),encoding='utf8')
    print('Published Beats paired readings and exact code.')

if __name__=='__main__':main()
