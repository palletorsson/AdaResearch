from pathlib import Path
import json

H = Path(__file__).resolve().parent
R = H.parents[3]
M = 'SpeculativeComputation_Collective_Knowledge'
C = H.parent / '2026-09-19-review-comparison'
prefix = H.relative_to(R).as_posix() + '/'
before = (H/'before/commons/maps'/M/'final.md').read_text(encoding='utf-8')
after = (R/'commons/maps'/M/'final.md').read_text(encoding='utf-8')

def passage(text, starts):
    return '\n\n'.join(next(p for p in text.split('\n\n') if p.startswith(s)) for s in starts)

def pair(title, description, images, captions, old_starts, new_starts, note, report='final.diff'):
    return dict(title=title, description=description, images=[prefix+n+'.png' for n in images],
                captions=captions, image_note=note, text_kind='book — from arrival to reconsideration',
                before=passage(before,old_starts), after=passage(after,new_starts),
                report=prefix+report, report_label='Exact manuscript diff' if report=='final.diff' else 'Findings, decisions and verification')

data = json.loads((C/'postfoundationscrisis.json').read_text(encoding='utf-8'))
data['items'] = [i for i in data['items'] if not i.get('report','').startswith(prefix) and i['title'] != 'Next: what becomes common?']
data['status'] = 'First five halls reviewed; Rhizome Network next'
data['summary'] = ('Post-Crisis moves from distinctions and participation to disagreement, situated claims and a shared object. '
                   'The visitor can now recover a contribution’s source and revise a piece without making the pile larger. '
                   'The manuscripts keep evidence, authorship and settlement open to inspection.')
data['items'] += [
    pair('The same form, different sources',
         'FLOW holds the arrivals. COLOUR reveals the sources behind the original arrival-order gradient. PIECE identifies a landed contribution and draws a line to its numbered node. The shape has not moved.',
         ['collective-order','collective-sources'],
         ['ORDER: forty pieces assembled by the prescribed helix.', 'SOURCE: the same forty pieces, coloured by their six contributing nodes.'],
         ['The previous room kept'], ['Press COLOUR.','The previous room kept'],
         'Actual revised museum states from the same camera and controlled seeded arrangement. Sources are generated nodes, not people. All four authored families remain declared.'),
    pair('A revision is not a settlement',
         'The earlier proposed experiment is now available. DISPUTE marks an existing piece; REVISE changes its pose while preserving its source. The dispute stays. The counter distinguishes changing a piece from adding one.',
         ['collective-dispute','collective-revision'],
         ['Piece 31, source P5: disputed, no revisions.', 'Same piece: one visitor revision; forty pieces and forty additions remain.'],
         ['For a proposed extension'], ['Choose a piece','Here revision'],
         'Same camera and selected piece. The visible shape change is modest; the frame and readout identify it. This is geometric revision without semantic validation.'),
    pair('What survives the next version?',
         'The historic CONTRIBUTORS discrepancy remains part of the chapter. PARTICIPATIONS names repeated source-version attendance; EVER counts distinct nodes across versions. A previous version is retained in memory, without a full history browser.',
         ['collective-side','collective-version'],
         ['Side view of the revised piece: its source and visitor intervention remain named.', 'Version 2: three arrivals, two current sources, six ever-seen sources and eight participations.'],
         ['Every accepted facet'], ['Every accepted facet','Before pressing VERSION'],
         '39 runtime checks, seven selected walking segments and 79 content checks pass. These images differ in camera and version. Two supporting scene files exist but their museum lookup still rejects them; their restoration is recorded separately. Headset testing remains open.', 'SUMMARY.md'),
    dict(title='Next: no root, but no centre?',
         description='Rhizome Network follows the sources into their pattern of connection. Inspect what the existing grower does and distinguish no designated root from no concentration of links.',
         report=prefix+'content-checks.json',report_label='Content and preservation checks')
]
(C/'postfoundationscrisis.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Updated Post-Crisis comparison: five reviewed halls.')
