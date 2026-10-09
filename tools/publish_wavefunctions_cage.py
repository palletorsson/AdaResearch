from pathlib import Path
import hashlib,json,re,zipfile
from publish_wavefunctions_opening import STYLE,render,block
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-cage-a-score-kept'
STUDY=ROOT/'doc/book/studies/wavefunctions-lineage'
MAP=ROOT/'commons/maps/WaveFunctions_John_Cage'

def page(title,body):
    return f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{title}</title><style>{STYLE}</style><header><div class="tag">Endless Museum · Wavefunctions · Hall 8</div><h1>{title}</h1><nav><a href="index.html">Room & evidence</a><a href="parallel.html">Tutorial left · reflection right</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="../2026-10-08-bernini-a-turn-through-height/index.html">Previous: Bernini</a></nav></header><main>{body}</main></html>'

def main():
    OUT.mkdir(exist_ok=True)
    tutorial=(STUDY/'cage-tutorial.md').read_text(encoding='utf8')
    for token,name in [('CODE','08_chance_score.gd'),('VOICE_CODE','note_voice.gd'),('POINT_CODE','point_body.gd'),('LINE_CODE','line_skin.gd')]:
        tutorial=tutorial.replace('{'+token+'}',block(name,(STUDY/name).read_text(encoding='utf8')))
    final=(STUDY/'cage-final.md').read_text(encoding='utf8')
    for name,text in [('tutorial',tutorial),('final',final)]:
        for dest in [MAP,OUT]:(dest/(name+'.md')).write_text(text,encoding='utf8')
        (OUT/(name+'.html')).write_text(page(text.splitlines()[0][2:],'<article>'+render(text)+'</article>'),encoding='utf8')
    (OUT/'parallel.html').write_text(page('A score kept','<div class="parallel"><article><div class="tag">tutorial.md</div>'+render(tutorial)+'</article><article><div class="tag">final.md</div>'+render(final)+'</article></div>'),encoding='utf8')
    dest=OUT/'extracted';dest.mkdir(exist_ok=True)
    parity=[]
    for name,code in re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tutorial,re.S):
        assert code==(STUDY/name).read_text(encoding='utf8').rstrip()
        (dest/name).write_text(code+'\n',encoding='utf8')
        parity.append({'file':name,'printed_matches_source':True,'sha256':hashlib.sha256((code+'\n').encode()).hexdigest()})
    old=(STUDY/'06_phase_note.gd').read_text(encoding='utf8')
    carried=(STUDY/'note_voice.gd').read_text(encoding='utf8')
    assert old[old.index('func sample_at'):old.index('func _ready')].strip()==carried[carried.index('func sample_at'):].strip()
    (OUT/'code-check.json').write_text(json.dumps({'files':parity,'sound_functions_unchanged':True},indent=2),encoding='utf8')
    variant=(dest/'08_chance_score.gd').read_text(encoding='utf8').replace('var min_interval := 0.8','var min_interval := 1.0').replace('var max_interval := 1.6','var max_interval := 1.0')
    (dest/'08_equal_intervals.gd').write_text(variant,encoding='utf8')
    with zipfile.ZipFile(OUT/'student-code.zip','w',zipfile.ZIP_DEFLATED) as z:
        for row in parity:z.write(dest/row['file'],row['file'])
        z.write(dest/'08_equal_intervals.gd','08_equal_intervals.gd')
        z.writestr('tutorial.md',tutorial);z.writestr('final.md',final)
        z.writestr('READ-ME.txt','Use the prepared Endless Museum working copy with XRToolsPickable. Put all scripts together. Attach 08_chance_score.gd to an empty unit-scale Node3D, hall-local (16,0,10), yaw180. Optional 08_equal_intervals.gd is the complete regular-pulse exercise; attach it instead. Full instructions: tutorial.md. Godot 4.6.\n')
    evidence=''
    for name,title in [('student-test.json','Printed program'),('after/report.json','Actual museum')]:
        if (OUT/name).exists():
            data=json.loads((OUT/name).read_text(encoding='utf8'))
            evidence+=f'<p>{title}: {sum(x["passed"] for x in data["checks"])}/{len(data["checks"])} checks. <a href="{name}">Results</a>.</p>'
    if (OUT/'mutation-tests.json').exists():
        tests=json.loads((OUT/'mutation-tests.json').read_text())
        evidence+=f'<p>{sum(x["rejected"] for x in tests)}/{len(tests)} deliberate faults rejected. <a href="mutation-tests.json">Fault checks</a>.</p>'
    body='''<p>Choose six events, keep their times, then replay the record. The same point controls a new capability; Effect Sound supplies the voices.</p><p class="status">Eighth lesson revised for review. Four authored exhibits retained. Soundscape synthesis and scheduling unchanged.</p>
<div class="pictures"><figure><img src="after/student.png"><figcaption>The exact printed study in the museum. Seconds run across; three sound choices form the rows. The black point selects REPLAY or NEW + PLAY.</figcaption></figure><figure><img src="after/listening.png"><figcaption>The existing soundscape after generation completes. Its luminous forms accompany nonspatial audio; they are not independently located sound sources.</figcaption></figure></div>
<h2>Before and after</h2><div class="pictures"><figure><img src="before/museum/above.png"><figcaption>Before: a large unsupported grid opening, a sculpture partly below floor level, and sound-generation graphics crowded into the passage.</figcaption></figure><figure><img src="after/gallery.png"><figcaption>After: a 22 × 28 m listening floor, suspended wire sculpture with room to expand, mounted displays and a clear central route.</figcaption></figure></div>
<div class="pictures"><figure><img src="after/displays.png"><figcaption>Existing spectrum and spectral-sine renderers mounted at viewing height. The right-hand curve is derived from spectrum data; it is not a recorded microphone waveform.</figcaption></figure><figure><img src="after/entry-after.png"><figcaption>A supported central passage connects the entrance and onward door.</figcaption></figure></div><h2>Two texts, two jobs</h2><p>The tutorial teaches an ordered event record and a clock that reads it. It replaces incomplete microphone and Cage-score claims with a complete six-event program. Replay retains the choices; a new score draws again. The reflection asks what chance can do inside a vocabulary someone has already selected, and how listening changes when an event returns.</p><p>The saved score is the learner study. The larger museum soundscape still selects events live and has no new record/replay command.</p>
<p>Two cleanup errors were repaired: removing a loading display through an invalid Node3D property, and discarding a finished thread without joining it. The display mounting is opt-in for this hall. Sound synthesis and live event selection are preserved.</p><h2>Validation</h2>'''+evidence+'''<p><a href="code-check.json">Printed/source parity</a> · <a href="student-code.zip">Complete student code and texts</a> · <a href="tutorial.md">Tutorial manuscript</a> · <a href="final.md">Reflective manuscript</a></p><p class="note">Teacher-authored native assertions check retained events, playback dispatch, the point trigger and a regular-pulse variation. A late frame starts overdue notes together: this is not sample-accurate scheduling. Museum captures and clearance checks do not establish physical-headset comfort or student comprehension. Captures use the Compatibility renderer. The engine log retains an unrelated project UID warning; it is not evidence of a clean whole-project audit.</p><h2>Next: Air Music</h2><p>The player supplies an onset by striking. A note continues after the contact ends; several voices can overlap.</p>'''
    (OUT/'index.html').write_text(page('John Cage: a score kept',body),encoding='utf8')
    print('Published Cage paired readings and exact code.')

if __name__=='__main__':main()
