from pathlib import Path
import hashlib, json, re, zipfile
from publish_wavefunctions_opening import STYLE, render, block

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations/2026-10-08-effect-sound-a-phase-you-can-hear'
STUDY = ROOT/'doc/book/studies/wavefunctions-lineage'
MAP = ROOT/'commons/maps/WaveFunctions_Effect_Sound'

def page(title, body):
    return f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{title}</title><style>{STYLE}</style><header><div class="tag">Endless Museum · Wavefunctions · Hall 6</div><h1>{title}</h1><nav><a href="index.html">Room & evidence</a><a href="parallel.html">Tutorial left · reflection right</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="../2026-10-08-wave-pools-walk-down/index.html">Previous: wave pools</a></nav></header><main>{body}</main></html>'

def main():
    OUT.mkdir(exist_ok=True)
    tutorial = (STUDY/'effect-sound-tutorial.md').read_text(encoding='utf8')
    for token, name in [('CODE','06_phase_note.gd'),('POINT_CODE','point_body.gd'),('LINE_CODE','line_skin.gd')]:
        tutorial = tutorial.replace('{'+token+'}', block(name,(STUDY/name).read_text(encoding='utf8')))
    final = (STUDY/'effect-sound-final.md').read_text(encoding='utf8')
    for name, text in [('tutorial',tutorial),('final',final)]:
        for dest in [MAP,OUT]: (dest/(name+'.md')).write_text(text,encoding='utf8')
        (OUT/(name+'.html')).write_text(page(text.splitlines()[0][2:],'<article>'+render(text)+'</article>'),encoding='utf8')
    (OUT/'parallel.html').write_text(page('One wave inside another','<div class="parallel"><article><div class="tag">tutorial.md</div>'+render(tutorial)+'</article><article><div class="tag">final.md</div>'+render(final)+'</article></div>'),encoding='utf8')
    dest = OUT/'extracted'; dest.mkdir(exist_ok=True)
    parity = []
    for name, source in re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tutorial,re.S):
        assert source == (STUDY/name).read_text(encoding='utf8').rstrip()
        (dest/name).write_text(source+'\n',encoding='utf8')
        parity.append({'file':name,'printed_matches_source':True,'sha256':hashlib.sha256((source+'\n').encode()).hexdigest()})
    (OUT/'code-check.json').write_text(json.dumps(parity,indent=2),encoding='utf8')
    with zipfile.ZipFile(OUT/'student-code.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for row in parity: archive.write(dest/row['file'],row['file'])
        archive.writestr('tutorial.md',tutorial)
        archive.writestr('final.md',final)
        archive.writestr('READ-ME.txt','Use your prepared Endless Museum working copy and its XR player. Place the three scripts together. Attach 06_phase_note.gd to an empty unit-scale Node3D in Effect Sound, hall-local (7,0,10), yaw 180 degrees. Grab the sphere, raise it, press the trigger. A then B. Tutorial and explanation: tutorial.md. No external sound samples. Godot 4.6 / supplied XRToolsPickable required.\n')
    evidence = ''
    for name,title in [('student-test.json','Printed program'),('after/report.json','Actual museum')]:
        if (OUT/name).exists():
            data=json.loads((OUT/name).read_text(encoding='utf8'))
            evidence += f'<p>{title}: {sum(c["passed"] for c in data["checks"])}/{len(data["checks"])} checks. <a href="{name}">Results</a>.</p>'
    if (OUT/'mutation-tests.json').exists():
        faults=json.loads((OUT/'mutation-tests.json').read_text())
        evidence += f'<p>{sum(f["rejected"] for f in faults)}/{len(faults)} deliberate faults rejected. <a href="mutation-tests.json">Fault checks</a>.</p>'
    body='''<p>The familiar pickable point returns as a control. Raise it to change one oscillator’s contribution to another’s phase; trigger a comparison with a retained zero-depth note.</p><p class="status">Sixth lesson revised for review. This is a construction inside the existing museum. All 33 authored artifact placements remain; the primary instrument has a clear approach and the secondary instruments have separate bays.</p>
<div class="pictures"><figure><img src="after/student.png"><figcaption>The exact printed program in its museum study bay. The carried point selects phase depth; the carried lines draw a selected signal window.</figcaption></figure><figure><img src="after/instrument.png"><figcaption>The existing two-ball instrument. BASELINE, HOLD, PLAY and COMPARE stay at the desks.</figcaption></figure></div>
<h2>Before and after</h2><div class="pictures"><figure><img src="before/museum/above.png"><figcaption>Before: crowded 14 × 16 m grid-derived staging, high rack controls and an unsupported exit approach.</figcaption></figure><figure><img src="after/gallery.png"><figcaption>After: level approach, two-ball instrument first, wider bays for the surrounding sound collection.</figcaption></figure></div>
<h2>The two texts</h2><p>The tutorial replaces undeclared fragments with one complete program and the two unchanged carried classes. Only phase depth is hand-controlled. Sample timing, envelope and playback are explained at their point of use. The reflection keeps the listening, comparison and naming of sounds; code blocks and buffer details move to the tutorial.</p>
<h2>Hear the generated samples</h2><div class="pictures"><figure><audio controls src="baseline.wav"></audio><figcaption>A: retained zero-depth reference.</figcaption></figure><figure><audio controls src="modulated.wav"></audio><figcaption>B: depth two, same carrier and envelopes.</figcaption></figure></div>
<h2>Validation</h2>'''+evidence+'''<p><a href="code-check.json">Printed/source parity</a> · <a href="student-code.zip">Complete student code</a> · <a href="tutorial.md">Tutorial manuscript</a> · <a href="final.md">Reflective manuscript</a></p><p class="note">Teacher-authored native tests cover signed PCM data, formula predictions, parameter mapping, retained reference, triggered playback and an independent ratio change. Museum checks cover the real instrument, supports, controls and temporary student installation. They do not establish listening quality, learner comprehension or physical-headset comfort.</p><h2><a href="../2026-10-08-bernini-a-turn-through-height/index.html">Next: Bernini</a></h2><p>Use the circle to generate a shaft through height, then distinguish that twist from rotation of the whole object.</p>'''
    (OUT/'index.html').write_text(page('Effect Sound: a phase you can hear',body),encoding='utf8')
    print('Published Effect Sound paired readings and exact code.')

if __name__=='__main__': main()
