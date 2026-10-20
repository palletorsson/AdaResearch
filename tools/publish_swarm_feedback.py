"""Record the external review, bounded editorial response and current evidence."""
from pathlib import Path
import hashlib
import html
import json
import re
import shutil

import markdown

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-10-swarm-feedback'
COLLECTION = '../2026-10-10-swarm-complete-readings/'


def read(path):
    return json.loads(path.read_text(encoding='utf8'))


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(text.encode('utf8'))


checks = read(R / 'doc/book/iterations/2026-10-10-swarm-sequence-review/sequence-checks.json')
assert checks['passed'] and checks['completed'] and checks['same_pointbody_all_seven']
baseline = read(O / 'before-hashes.json')
current = {}
for path, before in baseline.items():
    p = R / path
    text = p.read_text(encoding='utf8')
    digest = hashlib.sha256(p.read_bytes()).hexdigest()
    code = hashlib.sha256('\n'.join(re.findall(r'```gdscript\s*\n(.*?)```', text, re.S)).encode()).hexdigest()
    assert code == before['code_sha256'], path
    if p.name == 'final.md':
        assert digest == before['sha256'], path
    current[path] = {'sha256': digest, 'code_sha256': code}
for hall in checks['halls']:
    for kind in ['tutorial', 'final']:
        key = f"commons/maps/{hall['hall']}/{kind}.md"
        assert current[key]['sha256'] == hall[kind + '_sha256'], key

names = ['Physarum', 'Flow Fields', 'Boids', 'ABM', 'Ant Colony', 'Particle Swarm', 'Population Support']
changes = read(O / 'changes.json')
assert len(changes) == 7
brief = R / 'doc/book/course/storyboards/SWARM-OPEN-STUDY.md'
shutil.copy2(brief, O / 'OPEN-STUDY.md')
shutil.copy2(R / 'doc/book/iterations/2026-10-10-swarm-sequence-review/sequence-checks.json', O / 'sequence-checks.json')
write(O / 'after-hashes.json', json.dumps(current, indent=2) + '\n')
ghost_complete = (R / 'doc/book/iterations/2026-10-10-swarm-ghost-student/publication-checks.json').exists()
ghost_note = '[The subsequent ghost-student rehearsal](../2026-10-10-swarm-ghost-student/index.html) records two instruction corrections and the completed RIDGE comparison.' if ghost_complete else 'The optional investigation has no reported outcome.'

response = f'''# Swarm — what the feedback changes

The assessment supports keeping the seven-hall route. Its useful criticism concerns transfer: recognising a small study's operation in a larger exhibit, and knowing when the next hall changes the model. We have tightened those passages without adding another compulsory algorithm.

## Applied to the lessons

| Hall | Change |
| --- | --- |
| Physarum | A short sequence orientation distinguishes the carried PointBody from the seven models. A return to the colony separates persistent marks from the diffusion and anchors omitted by the study. |
| Flow Fields | Return to a direction mark and compare two passing bodies. Name supplied direction, existing velocity and the exhibit's zero-direction wandering; the study brakes instead. |
| Boids | Transfer the neighbour-radius question back to flocking_controls. Use the observation balcony and aquarium to compare boundaries without claiming the numerical space follows the walls. |
| ABM | Revisit food contact, then ANTS versus RESET. Identify the retained field and state change; finite food and recruitment remain outside the small reconstruction. |
| Ant Colony | Kept. Its state-to-channel handoff already makes the progression explicit. |
| Particle Swarm | Kept. Its scored memories already replace the colony model explicitly. The optional investigation returns here. |
| Population Support | Explain the change from an individual's movement to population persistence. Link the optional investigation after the closing handoff. |

This external-feedback pass made seven short insertions across five canonical tutorials. All seven reflective texts and every printed GDScript block are unchanged. The tests below identify the current texts by hash. No museum geometry, runtime algorithm, sequence order or approval decision was edited in this response. {ghost_note}

## What we retain, qualify and defer

**Retain the reflections.** Their separate work is already clear: inherited traces, supplied direction, neighbourhood boundaries, changing state, shared channels, imposed scores and external support. More code or a general essay on swarm intelligence would weaken that focus.

**Keep the mechanisms distinct.** Environmental memory is important in Physarum, ABM and Ant Colony. It is not the explanation for Flow Fields or Boids. Particle Swarm remembers evaluated positions. Population Support records changes to a supplied model. PointBody supplies continuity of appearance and handling, not evidence that these are one accumulating agent.

**Keep mathematical wording exact.** In the printed Boids lesson, alignment averages velocities, including their magnitudes; “average heading” alone would omit that distinction. The review's broad conceptual comparisons are readings of the sequence, not independent verification of each implementation.

**Make the open investigation optional.** [A good score, a scattered group](OPEN-STUDY.md) asks whether changing shared attraction alters dispersion on RIDGE. It uses the printed Particle Swarm model, declared seed and existing controls. The learner chooses a comparison and predicts an outcome before consulting the separate results. A Boids-plus-trace hybrid remains a proposal requiring another model and tests; it is not silently inserted into the curriculum.

**Do not confuse a reading fix with a spatial fix.** The first four studies are still temporary small reconstructions beside existing exhibits. The last three are permanent full-size installations. The new passages give the reader concrete comparisons. They do not demonstrate that a visitor can find, reach or understand every display.

The separate [artifact image inventory](../2026-10-10-swarm-artifact-gallery/index.html) records three saved placements absent from the captured halls, an unreadable boids_2d_in_3d panel and an obstructed first science_screen. Isolated previews are labelled as such. Those room issues remain open; none was concealed or fixed by editing these lessons.

## Verification after the edits

All seven printed lessons were reconstructed and executed again in Godot: **{checks['total_checks']} checks passed**, including seven independent code variations and 21 deliberately faulty variants. PointBody remains byte-identical across the seven lessons. The before/after records confirm unchanged printed code and unchanged reflections.

This is an author-operated reconstruction. The submitted external assessment is a reading response; it is not an independent execution of these files. Physical headset use, independent learner comprehension and full museum integration remain separate work. The optional investigation is separate from this 265-check count. {ghost_note}

Run receipt: [sequence-checks.json](sequence-checks.json). Editorial record: [changes.json](changes.json). Supplied review: [external-assessment.md](external-assessment.md).

## Short instruction for the next reader

Museum supplied. PointBody reused; models change. Read→predict→run→vary→return to exhibit. Trace ≠ supplied direction ≠ neighbour observations ≠ state ≠ scored memory ≠ account. Name omissions. First4 studies temporary; last3 full-size. Reflection unchanged. {checks['total_checks']} author-run checks; not headset or independent-student proof. Optional RIDGE results: see separate ghost report when available. Keep seven-hall order. Graph Theory next.
'''
write(O / 'RESPONSE.md', response)
css = '''*{box-sizing:border-box}body{margin:0;background:#f5f2ea;color:#173d42;font:18px/1.65 Georgia,serif}nav{padding:18px 24px;background:#173d42;font:14px/1.6 system-ui}nav a{color:#ddf6ee;margin-right:24px}main{max-width:1080px;margin:auto;padding:38px 24px 80px}h1{font-size:48px;line-height:1.15}h2{margin-top:42px}a{color:#126076}table{border-collapse:collapse;font:16px/1.6 system-ui}td,th{padding:14px;border-bottom:1px solid #bec9c4;text-align:left;vertical-align:top}pre{white-space:pre-wrap}code{font:14px Consolas,monospace}details{margin:22px 0;background:white;padding:18px}summary{cursor:pointer;font:16px system-ui}blockquote{margin:15px 0;padding-left:18px;border-left:3px solid #9db9ad}img{max-width:100%;height:auto}figcaption{font:14px/1.6 system-ui}figure{margin:25px 0}.grid{display:grid;grid-template-columns:1fr 1fr;gap:24px}@media(max-width:720px){.grid{display:block}h1{font-size:36px}}'''


def page(name, title, body):
    write(O / name, '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>' + html.escape(title) + '</title><style>' + css + '</style></head><body><nav><a href="index.html">Feedback response</a><a href="' + COLLECTION + 'tutorial.html">Complete tutorial</a><a href="' + COLLECTION + 'final.html">Complete reflection</a><a href="' + COLLECTION + 'swarm-review.zip">Review ZIP</a><a href="open-study.html">Optional investigation</a></nav><main>' + body + '</main></body></html>')


def render(text):
    return markdown.markdown(text, extensions=['extra', 'sane_lists'])


gallery = '<h2>Return to the existing encounters</h2><p>Earlier native Godot captures; these rooms were not rerendered for the editorial response.</p><div class="grid">'
for index, (report, image, caption) in enumerate([
    ('2026-10-10-swarm-a-trace-outside', 'live-colony-table', 'Physarum: recognise the trace; name the omitted sources and diffusion.'),
    ('2026-10-10-flow-directions-already-here', 'live-flow-table', 'Flow Fields: read a direction, then watch a body turn.'),
    ('2026-10-10-boids-observation-balcony', 'balcony-eye', 'Boids: observe the open flock from its existing balcony.'),
    ('2026-10-10-abm-what-the-point-carries', 'colony-after', 'ABM: find the transition; compare replacing bodies with clearing their field.'),
]):
    target = O / 'assets' / f'{index + 1}.png'
    target.parent.mkdir(exist_ok=True)
    shutil.copy2(R / 'doc/book/iterations' / report / 'assets' / (image + '.png'), target)
    gallery += f'<figure><img loading="lazy" src="assets/{index + 1}.png" alt="{html.escape(caption)}"><figcaption>{html.escape(caption)}</figcaption></figure>'
gallery += '</div>'
additions = '<h2>Exact additions to the tutorials</h2>'
for change in changes:
    hall = change['path'].split('/')[-2]
    additions += '<details><summary>' + html.escape(hall) + ' — before ' + html.escape(change['insert_before'].removeprefix('## ')) + '</summary>' + render(change['added'].replace('../../../doc/book/course/storyboards/SWARM-OPEN-STUDY.md', 'open-study.html')) + '</details>'
page('index.html', 'Swarm · response to the external review', render(response.replace('](OPEN-STUDY.md)', '](open-study.html)')) + gallery + additions)
page('open-study.html', 'Swarm · optional investigation', render(brief.read_text(encoding='utf8').replace('../../iterations/2026-10-10-swarm-ghost-student/index.html', '../2026-10-10-swarm-ghost-student/index.html')))
print(f'Published bounded feedback response; {checks["total_checks"]} fresh checks; code and reflections unchanged.')
