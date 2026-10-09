from pathlib import Path
import hashlib,json,re,zipfile
from publish_wavefunctions_opening import STYLE,render,block
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-synthesis-five-amounts'
STUDY=ROOT/'doc/book/studies/wavefunctions-lineage'
MAP=ROOT/'commons/maps/WaveFunctions_Synthesis_Lab'

def page(title,body):
    return f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{title}</title><style>{STYLE}</style><header><div class="tag">Endless Museum · Wavefunctions · Hall 12</div><h1>{title}</h1><nav><a href="index.html">Room & evidence</a><a href="parallel.html">Tutorial left · reflection right</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="../2026-10-08-beats-a-difference-in-time/index.html">Previous: Beats</a></nav></header><main>{body}</main></html>'

def main():
    OUT.mkdir(exist_ok=True)
    tutorial=(STUDY/'synthesis-tutorial.md').read_text(encoding='utf8')
    for token,name in [('CODE','12_five_amounts.gd'),('POINT_CODE','point_body.gd'),('LINE_CODE','line_skin.gd')]:
        tutorial=tutorial.replace('{'+token+'}',block(name,(STUDY/name).read_text(encoding='utf8')))
    final=(STUDY/'synthesis-final.md').read_text(encoding='utf8')
    for name,text in [('tutorial',tutorial),('final',final)]:
        for dest in [MAP,OUT]:(dest/(name+'.md')).write_text(text,encoding='utf8')
        (OUT/(name+'.html')).write_text(page(text.splitlines()[0][2:],'<article>'+render(text)+'</article>'),encoding='utf8')
    (OUT/'parallel.html').write_text(page('Five amounts, one shape','<div class="parallel"><article><div class="tag">tutorial.md</div>'+render(tutorial)+'</article><article><div class="tag">final.md</div>'+render(final)+'</article></div>'),encoding='utf8')
    dest=OUT/'extracted';dest.mkdir(exist_ok=True);parity=[]
    for name,code in re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tutorial,re.S):
        assert code==(STUDY/name).read_text(encoding='utf8').rstrip()
        (dest/name).write_text(code+'\n',encoding='utf8')
        parity.append({'file':name,'printed_matches_source':True,'sha256':hashlib.sha256((code+'\n').encode()).hexdigest()})
    before=(OUT/'before/additive_wave_demo.gd').read_text(encoding='utf8')
    current=(ROOT/'commons/artifacts/additive_wave_demo/additive_wave_demo.gd').read_text(encoding='utf8')
    executable=lambda text:'\n'.join(line.strip() for line in text.splitlines() if line.strip() and not line.lstrip().startswith('#'))
    unchanged=executable(before)==executable(current.replace('const LIFT: float = 2.15','const LIFT: float = 1.75'))
    assert unchanged
    scene_unchanged=(OUT/'before/additive_wave_demo.tscn').read_bytes()==(ROOT/'commons/artifacts/additive_wave_demo/additive_wave_demo.tscn').read_bytes()
    production_files=['commons/artifacts/additive_wave_demo/additive_wave_demo.gd','algorithms/wavefunctions/oscillation_driver/DoubleHelix.gd','algorithms/wavefunctions/oscillation_driver/double_helix_scene.gd','commons/maps/WaveFunctions_Synthesis_Lab/map_data.json']
    sources={name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest() for name in production_files}
    (OUT/'code-check.json').write_text(json.dumps({'files':parity,'additive_logic_unchanged_except_display_lift':unchanged,'additive_scene_unchanged':scene_unchanged,'production_sources':sources,'repairs':['Bench display raised 0.40m; controls, coefficient calculation, gains and state unchanged.','This helix placement opts into a 4.8m local trail drop limit. Other placements retain their original behaviour.']},indent=2),encoding='utf8')
    variant=(dest/'12_five_amounts.gd').read_text(encoding='utf8').replace('[1.0, 0.5, 1.0 / 3.0, 0.25, 0.2]','[1.0, 0.0, 1.0 / 3.0, 0.0, 0.2]')
    (dest/'12_odd_recipe.gd').write_text(variant,encoding='utf8')
    with zipfile.ZipFile(OUT/'student-code.zip','w',zipfile.ZIP_DEFLATED) as z:
        for row in parity:z.write(dest/row['file'],row['file'])
        z.write(dest/'12_odd_recipe.gd','12_odd_recipe.gd')
        z.writestr('tutorial.md',tutorial);z.writestr('final.md',final)
        z.writestr('READ-ME.txt','Prepared Endless Museum, Godot 4.6. Put scripts together. Attach 12_five_amounts.gd to empty unit-scale Node3D at hall-local (16,0,11), yaw180, inside WaveFunctions_Synthesis_Lab. The odd-harmonic variation replaces that script. See tutorial.md for full context and validation limits.\n')
    evidence=''
    for name,title in [('student-test.json','Exact printed program'),('after/report.json','Actual museum')]:
        if (OUT/name).exists():
            data=json.loads((OUT/name).read_text(encoding='utf8'))
            evidence+=f'<p>{title}: {sum(x["passed"] for x in data["checks"])}/{len(data["checks"])} checks. <a href="{name}">Results</a>.</p>'
    if (OUT/'mutation-tests.json').exists():
        data=json.loads((OUT/'mutation-tests.json').read_text())
        evidence+=f'<p>{sum(x["rejected"] for x in data)}/{len(data)} deliberate faults rejected. <a href="mutation-tests.json">Fault checks</a>.</p>'
    body="""<p>Five amounts change one shape. Keep the black point, the line renderer and signed addition; give the sum a finite list of harmonics.</p><p class="status">Final Wavefunctions hall revised for review. All 26 authored placements retained. The existing additive calculation and controls are preserved; its display is raised to reveal the fifth row.</p>
<div class="pictures"><figure><img src="after/student.png"><figcaption>The exact printed program, temporarily installed inside the museum: five carried points control amounts, six rows show contributions and sum.</figcaption></figure><figure><img src="after/bench.png"><figcaption>The original additive bench faces arrival, with its five sliders, held comparison and baseline controls.</figcaption></figure></div>
<h2>Before and after</h2><div class="pictures"><figure><img src="before/museum/above.png"><figcaption>Before: partitions, floating or buried specimens, an oversized model slab and an obstructed exit.</figcaption></figure><figure><img src="after/gallery.png"><figcaption>After: supported specimen benches, a clear central passage, a separate listening-room approach and scaled spatial studies.</figcaption></figure></div>
<h2>Two texts, two jobs</h2><p>The tutorial prints a complete three-file study. Height selects each nonnegative amount; H1's action holds time, H5 restores the saved baseline without resetting phase. An odd-harmonic variation tests half-cycle reversal. The reflection retains the question of what leaves the picture before leaving the calculation, then compares the changing sum with the separately filtered voice. Its implementation blocks move out of the main reading.</p>
<p>The helix now limits its trail above its footing in this placement, including at slow frame rates. The reference sphere sits beside the exit, leaving its frame aligned with the central route. The bench display is raised 40 cm so the baseline’s fifth component clears its readout.</p><h2>Validation</h2>"""+evidence+"""<p><a href="code-check.json">Printed/source parity and preserved calculations</a> · <a href="student-code.zip">Complete code and texts</a> · <a href="tutorial.md">Tutorial manuscript</a> · <a href="final.md">Reflection manuscript</a></p><p class="note">Teacher-authored native checks validate code, museum placement, actual control callbacks and stated calculations. They do not establish independent student understanding or physical-headset comfort. The learner display is visual only; Room Memory remains a separate encounter. Native captures use Compatibility rendering.</p><h2>Wavefunctions → Randomness</h2><p>The sequence has moved from a returning cube through records, surfaces, phase, coupling, sound and composition. This final study separates restoring a recipe from restoring an instant. Random Definition can now ask what must be retained when a result is chosen.</p>"""
    (OUT/'index.html').write_text(page('Synthesis: five amounts',body),encoding='utf8')
    print('Published Synthesis paired readings and exact code.')

if __name__=='__main__':main()
