"""Publish Trace's verified focus without promoting unbuilt Grid work."""
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
    subjects = ['Arrays of positions', 'Appending and reading an index', 'A distance condition with if', 'Neighbour loops with for']
    focus = "Continue the tested Lines point and readout; remove B and the single live span. Seed a typed array with the point's local position. Compare each frame with the last retained value; append only when the distance reaches the threshold. Loop through neighbouring entries to draw the trace with the unchanged LineSkin. Explain array lifetime, indices, if and for. Keep the record separate from its drawings."
    carry = "Complete trace.gd, the unchanged drawing helper, and an ordered station-local position array that lasts while the station exists. No file or automatic Grid handoff yet."
    review = "5 October author correction: teach arrays, loops and the distance condition through the existing student dot. Production pen excerpts and grip alignment no longer define this lesson. Exact printed code, the current Lines predecessor, threshold and traversal variants are checked in native Godot using real XR Tools with synthetic controllers. No headset or learner-understanding claim."
    p = ROOT / 'doc/book/course/hall-cards/lineage-opening.json'
    data = json.loads(p.read_text(encoding='utf-8-sig'))
    row = next(r for r in data['halls'] if r['map'] == 'Point_Trace')
    row.update(subjects=subjects, focus=focus, carries=carry, review=review, status='aligned',
               adds='An ordered typed array, append/index access, a threshold condition and neighbouring-index traversal.',
               tutorial_sha256_after=hashlib.sha256((ROOT / 'commons/maps/Point_Trace/tutorial.md').read_bytes()).hexdigest(),
               revision_report=EVIDENCE + '/index.html')
    grid = next(r for r in data['halls'] if r['map'] == 'Point_Line_Grid')
    grid['status'] = 'needs_revision'
    grid['review'] = '5 October: the current Trace lesson produces a station-local learner array. This older Grid text reads the production pen’s world-coordinate session store. Preserve its real museum behaviour, but write and test the explicit learner continuation before claiming a current Trace-to-Grid handoff. Source fitting and snapping remain distinct operations.'
    p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

    p = ROOT / 'doc/book/course/storyboards/opening.json'
    data = json.loads(p.read_text(encoding='utf-8-sig'))
    hall = next(h for seq in data for h in seq['halls'] if h['id'] == 'Point_Trace')
    hall.update(storyboard=focus + ' Change the threshold; separately omit the final drawing pair while keeping the record. Track the dot centre, not a new pen tip. Supplied room/hands and complete printed renderer remain explicit.',
                brings=['The tested Lines point and local/world readout', 'Displacement and length', 'The supplied line_skin.gd'],
                learns=subjects, carries=carry, supplied=['Prepared museum room, camera, light and XR hands/library', 'Complete unchanged line_skin.gd'],
                review_note=review,
                storyboard_short='Keep tested dot/readout/skin; remove B/live span. Seed Array[Vector3] with local position. If distance from last retained >= threshold: append, loop neighbours and redraw. Explain zero-based indices, size, append, if, for/range and array lifetime. Test threshold/traversal changes, pause, return and pickup. Carry scene-local record; Grid transfer next. Defer pen grip.')
    for seq in data:
        for h in seq['halls']:
            if h['id'] == 'Point_Line_Grid':
                h['review_note'] = grid['review']
    p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

    p = ROOT / 'doc/book/course/storyboards/CONTEXT.md'
    text = p.read_text(encoding='utf-8-sig')
    text = text.replace('Trace is the next unassembled continuation.', 'Trace now has a tested continuation; Grid is the next unassembled handoff.')
    entry = "5 October, trace the carried point: the author selects arrays, loops and the movement condition. Trace now continues the tested dot from Lines, removes the second endpoint, retains local positions in Array[Vector3] and draws neighbouring pairs. The threshold compares with the last retained value, not last frame. Full script/helper and small edited variants have native tests. [Lesson and evidence](../../iterations/2026-10-05-trace-the-carried-point/index.html). Pen grip is deferred; final.md/museum are unchanged. The learner record lasts with its station and has no timestamps/file. Grid’s older production-session tutorial needs an explicit learner continuation; do not claim it consumes this new local array yet.\n\n"
    if entry not in text:
        text = text.replace('## Keep in memory\n\n', '## Keep in memory\n\n' + entry, 1)
    p.write_text(text, encoding='utf-8')
    print('Trace focus and current chain updated; Grid handoff explicitly needs revision.')


if __name__ == '__main__':
    main()
