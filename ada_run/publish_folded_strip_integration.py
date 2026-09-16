"""Keep the original research gallery as evidence; add the current hall result."""
from pathlib import Path
import json
import html

ROOT = Path(__file__).resolve().parents[1]
STUDY = ROOT / 'doc/book/iterations/2026-09-16-folded-strip-research'
OUT = ROOT / 'doc/book/iterations/2026-09-16-folded-strip-in-museum'

def build():
    report = json.loads((OUT / 'runtime-checks.json').read_text())
    hall = json.loads((OUT / 'museum-report.json').read_text())
    assert report['passed'], report['failures']
    assert not hall['failures'], hall['failures']
    source = (STUDY / 'triangle-strip-research.html').read_text(encoding='utf-8')
    section = '''<aside class="note" style="background:#e3e8da;padding:22px;margin:28px 0"><p class="eyebrow">Now installed · Point_Triangle_Context</p><h2 style="font:30px Georgia,serif;margin:8px 0">The study is in the hall.</h2><p>The existing strip now opens flat, turns around one hinge, unfolds, and builds the paired folds. Grab a visible point to take over. Your edit stays when you release it; the <strong>REPLAY</strong> button starts again once all points are released.</p><p>The strip is slightly smaller and shifted within its alcove. Its shading has been corrected, and the control stands on a plinth with the button about 1.05 m above the floor.</p><div class="images" style="grid-template-columns:repeat(2,minmax(0,1fr))"><figure><a href="triangle-strip-in-museum/museum-flat.png"><img style="width:100%;height:auto" src="triangle-strip-in-museum/museum-flat.png" alt="Flat strip in the actual endless museum alcove"></a><figcaption>Flat · actual museum</figcaption></figure><figure><a href="triangle-strip-in-museum/museum-paired-hinges.png"><img style="width:100%;height:auto" src="triangle-strip-in-museum/museum-paired-hinges.png" alt="Paired folds rising inside the actual museum alcove"></a><figcaption>Paired folds · actual museum</figcaption></figure></div><p><a href="/long-museum/encounters?map=Point_Triangle_Context">Find the triangle hall</a> · <a href="/compose/sources?map=Point_Triangle_Context">Read the room text</a> · <a href="triangle-strip-in-museum/runtime-checks.json">Interaction and geometry checks</a> · <a href="triangle-strip-in-museum/museum-report.json">Hall measurements</a></p><p style="font-size:13px">Verified in Godot with synthetic hand and pointer events; headset testing remains. The 130° overview captures fit the whole alcove and are not a normal headset field of view. The original eight-case research gallery below is a snapshot from before integration and retains the old rendering defects for comparison.</p></aside>'''
    source = source.replace('<section class="intro">', section + '<section class="intro">', 1)
    source = source.replace('These are real Godot renders through the existing artifact code. The hall and the book remain unchanged while we look.', 'These original research renders use the artifact code from before integration. They preserve the comparison that led to the hall revision shown above.')
    source = source.replace('Research proposal, not a hall revision. The shortlist is selected for useful contrasts; the measurements do not rank beauty or decide what belongs in the book.', 'Original research shortlist plus the subsequent hall integration. Measurements support the comparison; they do not rank beauty or decide what belongs in the book.')
    source = source.replace('My next candidate: the paired fold', 'From this candidate to the hall')
    source = source.replace('A useful next pass would repair the winding and normals, then let this existing strip slowly unfold and refold through those two cases.', 'The hall revision now repairs winding and normals, then lets this existing strip slowly unfold and refold through those two cases.')
    source = source.replace('The gallery keeps the current rendering defects visible', 'The original gallery keeps the earlier rendering defects visible')
    target = OUT / 'triangle-strip-research.html'
    target.write_text(source,encoding='utf-8')
    print(f'Built integrated review page; {report["checks"]} checks passed')

if __name__ == '__main__':
    build()
