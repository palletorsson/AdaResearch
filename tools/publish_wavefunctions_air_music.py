from pathlib import Path
import hashlib,json,re,zipfile
from publish_wavefunctions_opening import STYLE,render,block
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-air-music-after-contact'
STUDY=ROOT/'doc/book/studies/wavefunctions-lineage'
MAP=ROOT/'commons/maps/WaveFunctions_AirMusic'

def page(title,body):
    return f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{title}</title><style>{STYLE}</style><header><div class="tag">Endless Museum · Wavefunctions · Hall 9</div><h1>{title}</h1><nav><a href="index.html">Room & evidence</a><a href="parallel.html">Tutorial left · reflection right</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="../2026-10-08-cage-a-score-kept/index.html">Previous: Cage</a></nav></header><main>{body}</main></html>'

def main():
    OUT.mkdir(exist_ok=True)
    tutorial=(STUDY/'air-music-tutorial.md').read_text(encoding='utf8')
    for token,name in [('CODE','09_contact_voices.gd'),('VOICE_CODE','ring_voice.gd'),('POINT_CODE','point_body.gd'),('LINE_CODE','line_skin.gd')]:
        tutorial=tutorial.replace('{'+token+'}',block(name,(STUDY/name).read_text(encoding='utf8')))
    final=(STUDY/'air-music-final.md').read_text(encoding='utf8')
    for name,text in [('tutorial',tutorial),('final',final)]:
        for dest in [MAP,OUT]:(dest/(name+'.md')).write_text(text,encoding='utf8')
        (OUT/(name+'.html')).write_text(page(text.splitlines()[0][2:],'<article>'+render(text)+'</article>'),encoding='utf8')
    (OUT/'parallel.html').write_text(page('After contact','<div class="parallel"><article><div class="tag">tutorial.md</div>'+render(tutorial)+'</article><article><div class="tag">final.md</div>'+render(final)+'</article></div>'),encoding='utf8')
    dest=OUT/'extracted';dest.mkdir(exist_ok=True);parity=[]
    for name,code in re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tutorial,re.S):
        assert code==(STUDY/name).read_text(encoding='utf8').rstrip()
        (dest/name).write_text(code+'\n',encoding='utf8')
        parity.append({'file':name,'printed_matches_source':True,'sha256':hashlib.sha256((code+'\n').encode()).hexdigest()})
    production=['ResonatingMetallophone.gd','ResonatingBar.gd','CombinedWaveVisualizer.gd']
    unchanged=all((OUT/'before'/name).read_bytes()==(ROOT/'algorithms/wavefunctions/resonance'/name).read_bytes() for name in production)
    (OUT/'code-check.json').write_text(json.dumps({'files':parity,'production_instrument_unchanged':unchanged},indent=2),encoding='utf8')
    variant=(dest/'09_contact_voices.gd').read_text(encoding='utf8').replace('[261.63, 392.0]','[261.63, 261.63]')
    (dest/'09_same_pitch.gd').write_text(variant,encoding='utf8')
    with zipfile.ZipFile(OUT/'student-code.zip','w',zipfile.ZIP_DEFLATED) as z:
        for row in parity:z.write(dest/row['file'],row['file'])
        z.write(dest/'09_same_pitch.gd','09_same_pitch.gd')
        z.writestr('tutorial.md',tutorial);z.writestr('final.md',final)
        z.writestr('READ-ME.txt','Requires the prepared Endless Museum Godot 4.6 project with XRToolsPickable. Put these files together. Attach 09_contact_voices.gd to an empty unit-scale Node3D, hall-local (13,0,14), yaw180 in WaveFunctions_AirMusic. Touch the bars with the point. Same-pitch exercise: use 09_same_pitch.gd instead. Full setup and limits: tutorial.md.\n')
    evidence=''
    for name,title in [('student-test.json','Exact printed program'),('after/report.json','Actual museum')]:
        if (OUT/name).exists():
            data=json.loads((OUT/name).read_text(encoding='utf8'))
            evidence+=f'<p>{title}: {sum(x["passed"] for x in data["checks"])}/{len(data["checks"])} checks. <a href="{name}">Results</a>.</p>'
    if (OUT/'mutation-tests.json').exists():
        data=json.loads((OUT/'mutation-tests.json').read_text())
        evidence+=f'<p>{sum(x["rejected"] for x in data)}/{len(data)} deliberate faults rejected. <a href="mutation-tests.json">Fault checks</a>.</p>'
    body='''<p>Touch one bar, withdraw, touch another. The first note continues. Return to the same bar and only that voice starts again.</p><p class="status">Ninth lesson revised for review. All ten authored placements retained; production instrument code unchanged.</p>
<div class="pictures"><figure><img src="after/student.png"><figcaption>The exact printed two-bar study inside Endless Museum: the familiar black point supplies contact, two players keep their own ages, and the pink line adds stored samples.</figcaption></figure><figure><img src="after/instrument.png"><figcaption>The existing eight-bar metallophone now faces the entrance, with floor to stand on and room to use its stick.</figcaption></figure></div>
<h2>Before and after</h2><div class="pictures"><figure><img src="before/museum/above.png"><figcaption>Before: an unsupported grid opening cuts the playing floor; the instrument is tucked beside the exit, its readout facing away from the arrival.</figcaption></figure><figure><img src="after/gallery.png"><figcaption>After: an 18 × 22 m playing floor, two foreground encounters, learner bay and later ambient experiments, with a clear passage through the middle.</figcaption></figure></div>
<h2>Two texts, two jobs</h2><p>The tutorial replaces code fragments with a complete reconstruction. It carries PointBody and LineSkin unchanged, makes two contact sensors, creates finite decaying notes and reads each player's playback position. Touching one bar never cancels the other. A same-pitch variation tests whether the learner distinguishes the stored sound from its start time.</p><p>The reflection keeps the original encounter and the distinction between chosen notes and simulated material. Technical fragments move into the tutorial. It asks what continues after an action ends, and why hearing, brightness and a readout can offer different accounts.</p><p>The learner bars sense contact without blocking the point; they use fixed strike strength. The museum instrument retains its physical stick, speed mapping, eight voices and automatic stick return.</p>
<h2>Validation</h2>'''+evidence+'''<p><a href="code-check.json">Printed/source parity and production preservation</a> · <a href="student-code.zip">Complete student code + texts</a> · <a href="tutorial.md">Tutorial manuscript</a> · <a href="final.md">Reflection manuscript</a></p><p class="note">Native assertions move real collision bodies through areas and check independent playback and sample sums. They use the Dummy audio driver; they do not establish perceived sound quality. Museum captures use Compatibility rendering. Headset comfort and independent student understanding remain untested. The engine log retains an unrelated project UID warning.</p><h2>Next: Sky Stairs</h2><p>What does a sampled curve need before it can become a place for a body?</p>'''
    (OUT/'index.html').write_text(page('Air Music: after contact',body),encoding='utf8')
    print('Published Air Music paired readings and exact code.')

if __name__=='__main__':main()
