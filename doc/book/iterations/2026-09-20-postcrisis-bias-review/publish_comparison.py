from pathlib import Path
import json

H = Path(__file__).resolve().parent
R = H.parents[3]
M = 'CriticalAlgorithms_Algorithmic_Bias_Visualization'
C = H.parent / '2026-09-19-review-comparison'
prefix = H.relative_to(R).as_posix() + '/'
before = (H/'before/commons/maps'/M/'final.md').read_text(encoding='utf-8')
after = (R/'commons/maps'/M/'final.md').read_text(encoding='utf-8')

def passage(text, starts):
    return '\n\n'.join(next(p for p in text.split('\n\n') if p.startswith(start)) for start in starts)

def pair(title, description, images, captions, old_starts, new_starts, note, report):
    return dict(title=title, description=description,
                images=[prefix+name+'.png' for name in images], captions=captions,
                image_note=note, text_kind='book — a preserved question gains a working encounter',
                before=passage(before,old_starts), after=passage(after,new_starts),
                report=prefix+report, report_label='Exact manuscript diff' if report=='final.diff' else 'Findings, decisions and verification')

data = {
    'status': 'Post-Crisis opening revised; Applied Ethics next',
    'summary': 'After QFEP asks who may revise the conditions, Post-Crisis begins with a representation: the words stay, but some distinctions become harder to see. The existing word-position study now reaches both authored arrangements. Material brightness stays fixed, and the maker’s interpretation can be opened after looking. All four artifact families remain; the mature manuscript receives a few precise changes.',
    'items': [
        pair('The words remain; their room changes',
             'The old physical handle reached only 0.14 of the intended 0–1 blend at full travel. The corrected callback uses its normalized value. COMPRESSION now reaches both arrangements, with no simultaneous brightening or fading of the groups.',
             ['bias-arrangement-a','bias-arrangement-b'],
             ['Arrangement A: the two authored groups occupy the central region.',
              'Arrangement B: warm positions contract while grey positions spread. Colours, emission and alpha are held fixed.'],
             ['Choose two warm-coloured'], ['Choose two warm-coloured'],
             'Same camera, two states of the revised Godot museum. These are not before/after software screenshots. The frozen old callback was executed separately to reproduce the 0.14 endpoint. Tracked hand use remains to be checked.',
             'final.diff'),
        pair('Move the handle. Then move yourself.',
             'The text keeps its distinction between an authored analogy and evidence about a trained model. The visitor can now hold the handle still and change viewpoint, separating movement of the representation from movement of the observer.',
             ['bias-close-a','bias-close-b'],
             ['A, from the controls: the chosen warm labels can be followed individually.',
              'B, from the same position: the warm labels crowd together. The grey labels move farther away.'],
             ['The warm group'], ['The warm group'],
             'Actual close views. Fixed materials do not imply identical perceived visibility: distance, overlap and viewing angle are part of this encounter. The 24 terms and their two groupings remain authored choices.',
             'final.diff'),
        pair('The grouping is also something to question',
             'READ opens the maker’s interpretation without changing the geometry. Its wording asks which distinction matters to the visitor. The study stands on a narrow support with controls around 1.1 m, and the lower divider opening gives the expanded arrangement room. The three secondary works keep their exact placements.',
             ['bias-reading','bias-gallery'],
             ['Halfway between A and B, with READ open: “Both groups were chosen.”',
              'The study in the divided gallery, with room to circulate around its expanded state.'],
             ['Now scrutinise'], ['Press READ'],
             '28 interaction/state checks and seven selected walking segments pass in the actual museum copy. The test triggers the real arrival-gate signal before walking; it does not test palm recognition or continuous headset play. All four authored artifact families instantiate.',
             'SUMMARY.md'),
        {
            'title': 'The next question becomes furniture',
            'description': 'Applied Ethics is next: which arrangement lets a body participate? The existing furniture-plan comparison should carry that question. The seven later halls and their manuscripts were preserved during this opening pass.',
            'report': prefix+'content-checks.json',
            'report_label': 'Content and preservation checks'
        }
    ]
}
(C/'postfoundationscrisis.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
build=C/'build.py'
s=build.read_text(encoding='utf-8')
if "('postfoundationscrisis'," not in s:
    s=s.replace("('qfeplaboratory', 'What does one number leave out?')]", "('qfeplaboratory', 'What does one number leave out?'), ('postfoundationscrisis', 'Which decisions can we return to?')]")
    s=s.replace("'foundationscrisis', 'qfeplaboratory']", "'foundationscrisis', 'qfeplaboratory', 'postfoundationscrisis']")
    s=s.replace('else key.replace("_", " ").title()', 'else "Post-Crisis" if key == "postfoundationscrisis" else key.replace("_", " ").title()')
build.write_text(s,encoding='utf-8')
q=C/'qfeplaboratory.json'
d=json.loads(q.read_text(encoding='utf-8'))
d['status']='All eight QFEP Laboratory halls reviewed; Post-Crisis opening follows below'
q.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Published Post-Crisis opening comparison data')
