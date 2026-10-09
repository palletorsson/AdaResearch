"""Publish the second Wavefunctions lesson without changing museum logic."""
from pathlib import Path
import json, re, hashlib
from publish_wavefunctions_opening import STYLE, render, block

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-pendulum-a-record-of-return'
STUDY=ROOT/'doc/book/studies/wavefunctions-lineage'
MAP=ROOT/'commons/maps/WaveFunctions_Pendulum'

def page(title,body):
    return f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{title}</title><style>{STYLE}</style><header><div class="tag">Endless Museum · Wavefunctions · Hall 2</div><h1>{title}</h1><nav><a href="index.html">Evidence</a><a href="parallel.html">Tutorial left · reflection right</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="../2026-10-08-wavefunctions-what-returns/index.html">Cube & route</a></nav></header><main>{body}</main></html>'''

def main():
    OUT.mkdir(exist_ok=True,parents=True)
    code=(STUDY/'02_pendulum_record.gd').read_text(encoding='utf8')
    tutorial=(STUDY/'pendulum-tutorial.md').read_text(encoding='utf8').replace('{CODE}',block('02_pendulum_record.gd',code)).rstrip()+'\n'
    final=(STUDY/'pendulum-final.md').read_text(encoding='utf8').rstrip()+'\n'
    for name,text in [('tutorial',tutorial),('final',final)]:
        (MAP/(name+'.md')).write_text(text,encoding='utf8')
        (OUT/(name+'.md')).write_text(text,encoding='utf8')
        (OUT/(name+'.html')).write_text(page(text.splitlines()[0][2:],'<article>'+render(text)+'</article>'),encoding='utf8')
    (OUT/'parallel.html').write_text(page('A movement and its record','<div class="parallel"><article><div class="tag">tutorial.md</div>'+render(tutorial)+'</article><article><div class="tag">final.md</div>'+render(final)+'</article></div>'),encoding='utf8')
    extracted=OUT/'extracted';extracted.mkdir(exist_ok=True)
    printed=re.search(r'<!-- student-code:02_pendulum_record.gd -->\s*```gdscript\n(.*?)\n```',tutorial,re.S).group(1)
    assert printed==code.rstrip()
    (extracted/'02_pendulum_record.gd').write_text(printed+'\n',encoding='utf8')
    (OUT/'code-check.json').write_text(json.dumps({'printed_matches_source':True,'sha256':hashlib.sha256((printed+'\n').encode()).hexdigest(),'lines':len(printed.splitlines())},indent=2),encoding='utf8')
    evidence=''
    for name,title in [('student-test.json','Exact printed program'),('after/report.json','Inside the museum')]:
        path=OUT/name
        if path.exists():
            data=json.loads(path.read_text(encoding='utf8')); checks=data.get('checks',[])
            evidence+=f'<p>{title}: {sum(c["passed"] for c in checks)}/{len(checks)} checks. <a href="{name}">Results</a>.</p>'
    if (OUT/'mutation-tests.json').exists():
        data=json.loads((OUT/'mutation-tests.json').read_text(encoding='utf8'))
        evidence+=f'<p>{sum(x["rejected"] for x in data)}/{len(data)} deliberate faults rejected. <a href="mutation-tests.json">Fault results</a>.</p>'
    body='''<p>The familiar cube becomes a pendulum bob. Trace returns as a list of named position/time records. We change what the recorder keeps while retaining the movement.</p><p class="status">Second hall rewritten and spatially restaged after the author’s review. All ten authored artifacts are retained. The student study is temporarily mounted for native verification.</p><div class="pictures"><figure><img src="after/student-fine.png"><figcaption>Fine sampling: the complete student program inside the real hall. The count limit shortens its history.</figcaption></figure><figure><img src="after/student-coarse.png"><figcaption>Coarse sampling at the same simulated time: fewer marks, more duration. Their depth is a drawing of age.</figcaption></figure></div><h2>Before and after the writing pass</h2><table><tr><th>Before</th><th>After</th></tr><tr><td>Fragments depended on undisclosed scene children; time occupied a vector's Z field.</td><td>One complete program creates its cube, rod, record and display. Position and time have separate named fields.</td></tr><tr><td>Refresh rate and physics rate were conflated; the drawn spacing was called a wavelength without identifying the encoding.</td><td>The reflection keeps the encounter and distinguishes observations, clocks and the depth assigned to age.</td></tr><tr><td>Sampling described without an independent construction.</td><td>Build two recorders, compare fine/coarse retention, then predict a twenty-entry variation.</td></tr></table><h2 id="museum">The museum has changed too</h2><p>The old raised grid enclosure is gone. The hall now measures 21 × 29 metres, with a 2.8-metre pendulum, its pivot at 3.9 metres, a six-metre floor record and a larger readout facing the side walkway. The painting rigs are three times their former linear scale. The hand recorder starts at a reachable plinth and retains ten seconds along its own clear aisle.</p><div class="pictures"><figure><img src="after/pendulum-floor.png"><figcaption>The larger swing and its two accounts: suspended marks and a projection onto the floor. These are native Godot captures.</figcaption></figure><figure><img src="after/paintings.png"><figcaption>Three double pendulums, three working canvases, and space between them.</figcaption></figure><figure><img src="after/hand-timeline.png"><figcaption>Hand recorder on a plinth. This capture uses a scripted hand movement to expose the time trace; it is not a headset test.</figcaption></figure><figure><img src="after/readout.png"><figcaption>Count, retained duration, requested/actual intervals and measured period, facing the observer.</figcaption></figure></div><h2>Room before and after</h2><div class="pictures"><figure><img src="before/museum/above.png"><figcaption>The inherited grid enclosure restricted sightlines and usable floor.</figcaption></figure><figure><img src="after/gallery-above.png"><figcaption>An open room arranged around the extent of the moving artifacts.</figcaption></figure></div><h2>Existing encounter</h2><div class="pictures"><figure><img src="before/museum/primary.png"><figcaption>Before: the old enclosure blocked this view of the pendulum.</figcaption></figure><figure><img src="after/context.png"><figcaption>The student’s small reconstruction beside the existing exhibit.</figcaption></figure></div><h2>Validation</h2>'''+evidence+'''<p><a href="code-check.json">Printed-source check</a> · <a href="tutorial.md">Editable tutorial</a> · <a href="final.md">Editable reflection</a></p><p class="note">Teacher-authored tests, not an independent ghost-student reconstruction. No headset comfort or student-comprehension claim. The spawn is now on the open central route. Native approach probes include the controls, recorder and passage between the canvases. Source snapshots and engine logs accompany the captures.</p><h2>Next: Sine Space</h2><p>Here depth represents the age of an observation. Next, a repeating rule takes position in space as its input. The remaining ten lessons are still awaiting this writing and validation pass.</p>'''
    (OUT/'index.html').write_text(page('Pendulum: a record of return',body),encoding='utf8')
    print('Published Pendulum tutorial, reflection and review.')

if __name__=='__main__': main()
