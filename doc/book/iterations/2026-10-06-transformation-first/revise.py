from pathlib import Path
import copy
import hashlib
import html
import json
import re

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
COURSE = ROOT / 'doc/book/course/execution-plan'
DATA = json.loads((OUT / 'revision.json').read_text(encoding='utf-8'))
PLATES = ROOT / 'doc/book/iterations/2026-10-06-final-comic-plates'
rows = DATA['halls']
ids = [r['id'] for r in rows]
spine = json.loads((ROOT / 'commons/maps/sequences/transformation.json').read_text(encoding='utf-8'))['sequences']['transformation']['maps']
assert ids == spine
protected = [ROOT / f'commons/maps/{m}/{f}.md' for m in ids for f in ['tutorial', 'final']]
protected += [PLATES / r['plate'] for r in rows]
hashes = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in protected}

plan = json.loads((COURSE / 'plan.json').read_text(encoding='utf-8'))
before = copy.deepcopy(plan)
fields = ['summary','object','change','given','later','checks','transfer','carry']
for row in rows:
    lesson = next(l for l in plan['lessons'] if l['id'] == row['id'])
    lesson.update({k:row[k] for k in fields})
    lesson['notes'] = '6 October author-approved focus correction: transformation leads; programming supports the selected spatial experiment. All seven final-text plates inspected. Current tutorial still needs a complete tested reconstruction; no runtime or learning result is claimed. See TRANSFORMATION_SUMMARIES.md.'
    lesson['next'] = 'Pin inherited CubeBody/PointBody files and a named museum host; write the core spatial comparison before optional extensions. Test the exact printed code and a relevant fault.'
    if 'Point_Animatedcube' not in lesson['dependsOn']:
        lesson['dependsOn'].append('Point_Animatedcube')
    lesson['reuses'] = 'Familiar CubeBody/PointBody constructions and independent instances; named coordinate frames; earlier functions and value assignments. ' + {
        'Trans_Pre':'Point Zero supplies the distinction between initialization and repeated updates.',
        'Trans_Introduction':'The three operations from Trans_Pre now change the relation between a surface and its banks.',
        'Trans_Translation':'Lines supplies displacement and distance; Trace supplies an ordered record for the optional route.',
        'Trans_Rotation':'Coordinates supplies frames; Ignorance supplies a small returning function.',
        'Trans_Scale':'Earlier local positions and parent-child attachments return through a concrete size comparison.',
        'Trans_Body':'Known scale/rotation and distance calculations return with bodily input.',
        'Trans_Pit':'Known transforms, interpolation, functions and branches compose a new spatial result.'
    }[row['id']]
sequence = next(s for s in plan['sequences'] if s['id'] == 'transformation')
sequence.update(
    aim='Choose translation, rotation and scale; explain what each preserves and what it changes in the space available to a body.',
    carry='The familiar grayscale cube and sphere support deliberate displacements, turns, size changes and compositions. Programming control develops where the spatial operation needs it.',
    check='Predict and make a changed pose or opening; identify the operation, frame and preserved properties. Test its timing or input only where used.',
    note='Transformation is not necessarily animation. Start from poses, then vary them through time or proximity. Core comparison before optional routes, event detail, memory or sine. See TRANSFORMATION_SUMMARIES.md.'
)
assert [l for l in plan['lessons'] if l['id'] not in ids] == [l for l in before['lessons'] if l['id'] not in ids]
assert [s for s in plan['sequences'] if s['id'] != 'transformation'] == [s for s in before['sequences'] if s['id'] != 'transformation']
assert plan['topics'] == before['topics']
history = COURSE / 'history/2026-10-06-transformation-first.json'
if not history.exists():
    history.write_text(json.dumps(before, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
(COURSE / 'plan.json').write_text(json.dumps(plan, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
# Preserve every other saved export paragraph; only replace the seven selected rows.
summaries = (COURSE / 'lesson-summaries.txt').read_text(encoding='utf-8')
for row in rows:
    summaries, n = re.subn(r'^'+re.escape(row['id'])+r'\|[^\n]*',lambda _: row['id']+'|'+row['summary'], summaries, flags=re.M)
    assert n == 1, row['id']
(COURSE / 'lesson-summaries.txt').write_text(summaries, encoding='utf-8')

intro = '''# Transformation — move, turn, change size

6 October 2026 · Revised after the author's focus correction and review of all seven Transformation comic plates. Lesson plans, ready for one-at-a-time expansion.

## The sequence in one paragraph

'''+DATA['sequence']+'''

## What leads the teaching

**Spatial operation → what changes and what remains → small working code → a deliberate variation.**

A transformation need not be animated. Start with a changed pose; add animation when following intermediate poses helps explain the operation. Use a clock, list, event or flag when the chosen experiment needs it. Do not add a second programming syllabus to every hall. Several comparisons can use the same object without becoming simultaneous requirements.

| Hall | Core comparison | Further step, after the core works |
| --- | --- | --- |
'''
intro += ''.join(f"| {r['id']} | {r['focus']} | {r['extension']} |\n" for r in rows)
chapters = ''.join(f"\n## {i}. {r['id']} — {r['title'].lower()}\n\n{r['summary']}\n" for i,r in enumerate(rows,1))
ending = '''
## Programming foundations: present, then developed through use

Primitives already explains initialization, values and references, PointBody/CubeBody classes, arrays and indices, loops, conditions, parameters and returning functions. It offers practice and tested programs, not proof of human mastery. Transformation can reuse these foundations rather than finish every programming subject before beginning its own work.

Elapsed seconds help animate a transform. Events connect a control to a chosen value. A route needs an index that survives updates. A proximity response needs a calculation and possibly a condition. Parent-child relationships explain which bodies a scale reaches. Explain these where needed; keep general state-machine theory, exhaustive input design and matrix algebra outside this sequence. Sine may remain a short optional timing comparison once linear movement is understood; its derivation waits for Waves. Arrays and Colour provide further work with collections, functions and independent instances.

The older foundation plan's first-class-in-Colour claim is superseded: PointBody now begins in Lines. Likewise, seeing the supplied timer in Godot Primitives does not establish an ability to author a timing rule. Keep the concept's role explicit: supplied, introduced or practised.

## Writing and testing contract

- Select a spatial capability first: what can the student transform, predict and explain? Begin from the existing museum encounter and declare where the reduced study runs.
- Print the smallest complete resulting program once in tutorial.md, identifying inherited classes and supplied support. Initialize lesson objects. A source link or unexplained scene lookup cannot replace the needed code.
- Test the printed code, exact exercise variation and a relevant deliberate fault. Lead with the transformation claim: a displacement preserves orientation and size, a turn preserves internal distances, or a chosen scale changes the expected dimensions. Check timing, bounds and reset where the program uses them; the test harness need not become a second lesson.
- Keep final.md's reflection distinct. Illustrations can connect both readings without turning every depicted artifact into a coding requirement.
- Offer one small closing transfer to PointBody using a learned operation. If animation and grabbing coexist, declare which controls the transform; do not introduce an entire ownership framework merely to complete the chapter.

## Illustration review and next step

All seven [Transformation plates](http://localhost:3003/illustrations?plate=final-Trans_Pre) were inspected. Their strongest comparisons are the separate operations in Pre; the three crossings; level orientation on a diagonal journey; the marked face and swept space; a larger doorway beside an unchanged body; transformation versus removal; and the fixed frame around a changing opening. These illustrate final.md with imagined staging, not captures proving runtime behaviour. Several retain earlier coloured surfaces and overlays; future tutorial depictions should follow the current grayscale choice. The art remains intact in this pass.

These summaries and the seven editable execution-plan entries now share this focus. The existing tutorial.md files still need complete tested reconstructions. The seven-hall order remains; it can change if writing or testing gives a reason. Begin with Trans_Pre's three operations, then add a clock. No tutorial manuscript, reflective text, illustration or museum code changed in this planning revision.

[Illustrations beside these summaries](../../iterations/2026-10-06-transformation-first/index.html) · [Edit the live plan](http://localhost:3003/tutorial-plan?view=summaries&seq=transformation&map=Trans_Pre) · [Current spine order](../../../../commons/maps/sequences/transformation.json) · [Primitives takeaways](PRIMITIVES_TAKEAWAYS.md) · [Reconstruction rules](../functional_text/RECONSTRUCTION.md)
'''
(COURSE / 'TRANSFORMATION_SUMMARIES.md').write_text(intro+chapters+ending, encoding='utf-8')

def esc(s): return html.escape(s,quote=True)
page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Transformation comes first</title><style>
*{box-sizing:border-box}body{margin:0;background:#f1eee6;color:#262521;font:19px/1.65 Georgia,serif}header,main,footer{max-width:1350px;margin:auto;padding:40px 5vw}h1{font-weight:400;font-size:clamp(42px,6vw,80px);line-height:1.05;max-width:950px}h2{font-weight:400;font-size:35px;line-height:1.15}header p{max-width:850px}a{color:inherit}.meta,nav,.focus,figcaption,details,footer{font:14px/1.65 system-ui,sans-serif}.meta{letter-spacing:.1em;text-transform:uppercase}nav{display:flex;gap:20px;flex-wrap:wrap;margin-top:25px}.rule{font-size:24px;border-block:1px solid #bab3a4;padding:20px 0}.hall{display:grid;grid-template-columns:minmax(260px,.9fr) minmax(330px,1.1fr);gap:45px;padding:45px 0;border-top:1px solid #c5beb0;align-items:start;scroll-margin-top:20px}figure{margin:0}img{width:100%;display:block}figcaption{color:#646054;margin-top:10px}.focus{border-left:2px solid #9b9281;padding:10px 16px;margin:24px 0}.focus p{margin:7px 0}details{margin:25px 0}summary{cursor:pointer}footer{border-top:1px solid #c5beb0}@media(max-width:780px){.hall{grid-template-columns:1fr;gap:10px}.hall figure{max-width:520px}header,main,footer{padding:25px}h2{font-size:29px}}
</style><header><div class="meta">Endless Museum · Tutorial plan · 6 October 2026</div><h1>Transformation comes first.</h1><p>Move, turn, change size. Each lesson follows what happens to the object and the space around it. Programming gives the student the means to choose that change.</p><p class="rule">An operation → a spatial consequence → the code needed to make it.</p><p class="meta">Seven revised summaries · Existing final-text comic plates · Full tutorial rewrite still ahead</p><nav><a href="/book-review/doc/book/course/execution-plan/TRANSFORMATION_SUMMARIES.md">One-file summaries</a><a href="/tutorial-plan?view=summaries&seq=transformation&map=Trans_Pre">Edit the plan</a><a href="/illustrations?plate=final-Trans_Pre">Illustration gallery</a></nav></header><main>'''
for i,r in enumerate(rows,1):
    image_path='../2026-10-06-final-comic-plates/'+r['plate']
    assert (PLATES/r['plate']).exists()
    page += f'<section class="hall" id="{r["id"]}"><figure><a href="{image_path}"><img loading="lazy" src="{image_path}" alt="{esc(r["id"]+": "+r["title"])}"></a><figcaption>Existing final.md illustration · imagined staging, not a runtime capture.</figcaption></figure><div><div class="meta">{i:02d} / {esc(r["id"])}</div><h2>{esc(r["title"])}</h2><p>{esc(r["summary"])}</p><div class="focus"><p><b>Core:</b> {esc(r["focus"])}</p><p><b>Further step:</b> {esc(r["extension"])}</p></div><details><summary>What the complete example should check</summary><ul>'
    page += ''.join('<li>'+esc(c)+'</li>' for c in r['checks'])
    page += f'</ul><p>Proposed checks, not results from an unwritten lesson.</p></details><p class="meta"><a href="/tutorial-plan?map={r["id"]}&view=summaries&seq=transformation">Edit this summary</a></p></div></section>'
page += '<section><h2>What changed in the plan?</h2><p>Spatial operations lead. A clock follows the first changed pose. Routes, event detail and retained flags become further steps where needed. The tests still require complete runnable examples, but their first claim concerns the transformation.</p><p>The seven plates were reviewed beside the current reflective texts. Several images retain an earlier coloured palette; the tutorials will use the agreed grayscale forms. No illustration, manuscript or museum code changed.</p></section></main><footer>Revised summaries are synchronized with the editable execution plan. Source snapshots and the earlier plan remain in this review’s before directory. This is an editorial and source review, not new Godot or learner evidence.</footer></html>'
(OUT / 'index.html').write_text(page,encoding='utf-8')
for p in protected:
    assert hashlib.sha256(p.read_bytes()).hexdigest() == hashes[str(p.relative_to(ROOT))]
report={'scope':'Editorial plan synchronization and source preservation; no runtime or learner claims.', 'halls':ids,'illustrations_inspected':7,'preserved_source_sha256':hashes,'only_selected_plan_rows_changed':True,'passed':True}
(OUT / 'verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('Revised seven summaries, their execution contracts and sequence aim; published all seven inspected plates beside the summaries. Manuscripts and images unchanged.')
