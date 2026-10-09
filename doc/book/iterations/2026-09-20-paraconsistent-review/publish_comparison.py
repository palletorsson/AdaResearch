from pathlib import Path
import json

H = Path(__file__).resolve().parent
R = H.parents[3]
M = 'SpeculativeComputation_Paraconsistent_Engineering'
C = H.parent / '2026-09-19-review-comparison'
prefix = H.relative_to(R).as_posix() + '/'
before = (H/'before/commons/maps'/M/'final.md').read_text(encoding='utf-8')
after = (R/'commons/maps'/M/'final.md').read_text(encoding='utf-8')

def passage(text, starts):
    return '\n\n'.join(next(p for p in text.split('\n\n') if p.startswith(start)) for start in starts)

def pair(title, description, images, captions, old_starts, new_starts, note, report='final.diff'):
    return dict(title=title, description=description,
                images=[prefix+name+'.png' for name in images], captions=captions,
                image_note=note, text_kind='book — an available comparison becomes an encounter',
                before=passage(before,old_starts), after=passage(after,new_starts),
                report=prefix+report, report_label='Exact manuscript diff' if report=='final.diff' else 'Findings, decisions and verification')

data = json.loads((C/'postfoundationscrisis.json').read_text(encoding='utf-8'))
data['items'] = [i for i in data['items'] if not i.get('report','').startswith(prefix) and i['title'] != 'Next: keep the conflict']
data['status'] = 'First three halls reviewed; Situated Computation next'
data['summary'] = ('Post-Crisis moves from making distinctions visible, to arranging participation, to preserving a disagreement. '
                   'The existing word study, furniture plans and merge sculpture now offer comparisons the visitor can control. '
                   'The manuscripts keep their strongest questions and distinguish what these models show from what they cannot establish.')
data['items'] += [
    pair('Do the branches actually meet?',
         'JUNCTION leaves a gap. OVERLAP rotates both branches inward while their feet retain their positions. The visitor can remove the glowing marker to inspect what is there. The artifact moves nearer arrival; every supporting family stays.',
         ['merge-junction','merge-overlap'],
         ['JUNCTION: separate uprights and a marker between them.', 'OVERLAP, marker hidden: two oriented boxes share a volume.'],
         ['Trace branch'], ['Trace branch','Press OVERLAP.'],
         'Actual states of the revised Godot museum from the same 1.7 m camera. The runtime check verifies a point inside both boxes in OVERLAP. This is geometry, not a logical inference test.'),
    pair('Choose what you would keep. Then press RESOLVED.',
         'The earlier source-only comparison is now selectable. A always keeps its height and takes the centre; B remains as a named stump. FORK restores both branches and separates their tops. The reader can disagree with the decision encoded in the sculpture.',
         ['merge-resolved','merge-fork'],
         ['RESOLVED: A stands at full height; B is 0.2 m tall. No marker remains.', 'FORK: both heights return and the branches lean outward. The visible marker drops to their feet.'],
         ['There is a second'], ['Before pressing','Press FORK.'],
         'The source code example is unchanged. The artifact chooses these outcomes; it neither merges files nor derives consequences from contradictory propositions.'),
    pair('A name survives. What did it fail to record?',
         'The closing return asks what must remain for a decision to be reconsidered. Marker visibility and viewpoint offer different ways to inspect the crossing; neither supplies the missing history of the accounts.',
         ['merge-overlap-lit','merge-side'],
         ['OVERLAP with its authored highlight.', 'The same crossing from the side, with the highlight hidden.'],
         ['Return to the pillars'], ['Return to RESOLVED'],
         '38 runtime checks, 24 selected walking segments and 73 content checks pass. The second image changes both camera and marker state. All eight families remain declared; seven instantiate. The vault floor is flush, but its broad footprint remains a placement follow-up. Headset verification remains open.',
         'SUMMARY.md'),
    {'title':'Next: where did the claim come from?',
     'description':'Situated Computation follows the surviving accounts to their sources. Inspect what the existing readout changes across its four positions, and what remains an authored judgement.',
     'report':prefix+'content-checks.json','report_label':'Content and preservation checks'}
]
(C/'postfoundationscrisis.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Published Paraconsistent Engineering; earlier comparisons preserved')
