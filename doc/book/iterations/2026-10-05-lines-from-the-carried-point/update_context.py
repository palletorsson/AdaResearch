"""Record the tested Lines continuation in the existing teaching memory."""
from pathlib import Path
import hashlib
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
EVIDENCE = HERE.relative_to(ROOT).as_posix()


def main():
    report = json.loads((HERE / 'student/report-runtime.json').read_text(encoding='utf-8'))
    assert report['passed']
    for path, expected in report['inputs'].items():
        assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == expected, path
    lesson = ROOT / 'commons/maps/Point_Lines/tutorial.md'
    sha = hashlib.sha256(lesson.read_bytes()).hexdigest()
    focus = "Continue the current tested Coordinates point.gd on PointStudy. Preserve the point and local/world readout; duplicate the point for B. Read same-frame endpoints, subtract b - a, measure length and redraw the segment each frame. Add a fixed segment from C/D position values; arrange parallel, plus and X, then separate in depth. Carry the complete line.gd and supplied line_skin.gd into the future Trace lesson."
    review = "5 October: Lines now composes exactly from the current tested Coordinates script. Native Godot checks bind both complete printed files and the complete experiment scripts, exercising actual XR Tools with synthetic controllers. Both pickup bodies, live geometry, local/world/distance readings and edge cases are covered. Historical evidence is preserved separately. No headset or learner-comprehension claim."
    path = ROOT / 'doc/book/course/hall-cards/lineage-opening.json'
    data = json.loads(path.read_text(encoding='utf-8-sig'))
    row = next(r for r in data['halls'] if r['map'] == 'Point_Lines')
    row.update(focus=focus, review=review, status='aligned', tutorial_sha256_after=sha,
               revision_report=EVIDENCE + '/index.html',
               carries="The tested continuing point, its copy and a segment that reads both positions; complete line.gd and the supplied renderer. C/D show how an endpoint can remain a stored value.")
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

    path = ROOT / 'doc/book/course/storyboards/opening.json'
    data = json.loads(path.read_text(encoding='utf-8-sig'))
    hall = next(h for seq in data for h in seq['halls'] if h['id'] == 'Point_Lines')
    hall.update(storyboard=focus + " The tutorial names a changed direction with the same length, reversed subtraction and coincident endpoints. The full drawing helper is supplied explicitly; its basis calculation is deferred. Reflective associations remain in final.md.",
                brings=['The tested pickable point from Coordinates', 'Its local/world readout', 'Per-frame updates'],
                review_note=review,
                storyboard_short="Keep tested Coordinates point/readout. Duplicate for B. Same frame: b-a, length, live segment. Print complete line.gd + supplied skin once. Test both pickups, movement/release, vertical/reversed/zero spans. Add C/D as values: parallel,+,X; separate depth. Preserve direction/distance distinction. Carry files to Trace; recording not implemented.",
                carries='Complete tested line.gd and line_skin.gd; join current positions before Trace retains a history.')
    coordinates = next(h for seq in data for h in seq['halls'] if h['id'] == 'Point_Coordinates')
    coordinates['review_note'] = coordinates['review_note'].replace(
        'Current Lines still needs its older predecessor updated.',
        'Lines now continues this exact tested construction and preserves the readout.')
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

    path = ROOT / 'doc/book/course/storyboards/CONTEXT.md'
    text = path.read_text(encoding='utf-8-sig')
    text = text.replace('Lines still carries the older Coordinates construction and is marked for revision; do not treat its historical passing result as proof of this new chain.',
                        'The current Lines continuation now preserves that exact construction and readout; its new native evidence is recorded below. The older Lines report remains historical.')
    entry = "5 October, Lines from the carried point: the complete Lines script preserves current Coordinates, copies its point and adds a live segment plus distance. The same readout retains LOCAL/WORLD. Two-line exercises use stored C/D positions without extra pickup bodies. [Current lesson and native evidence](../../iterations/2026-10-05-lines-from-the-carried-point/index.html). Exact printed files and full variants are tested; synthetic controllers are not a headset test. Trace is the next unassembled continuation. Museum and final.md are unchanged.\n\n"
    if entry not in text:
        text = text.replace('## Keep in memory\n\n', '## Keep in memory\n\n' + entry, 1)
    path.write_text(text, encoding='utf-8')
    print('Recorded the tested Lines continuation; Trace remains the next unassembled state.')


if __name__ == '__main__':
    main()
