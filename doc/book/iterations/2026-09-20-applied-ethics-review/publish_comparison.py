from pathlib import Path
import json

H = Path(__file__).resolve().parent
R = H.parents[3]
M = 'CriticalAlgorithms_Applied_Ethics'
C = H.parent / '2026-09-19-review-comparison'
prefix = H.relative_to(R).as_posix() + '/'
before = (H/'before/commons/maps'/M/'final.md').read_text(encoding='utf-8')
after = (R/'commons/maps'/M/'final.md').read_text(encoding='utf-8')

def passage(text, starts):
    return '\n\n'.join(next(p for p in text.split('\n\n') if p.startswith(start)) for start in starts)

def pair(title, description, images, captions, old_starts, new_starts, note, report='final.diff'):
    return dict(title=title, description=description,
                images=[prefix+name+'.png' for name in images], captions=captions,
                image_note=note, text_kind='book — existing questions become selectable encounters',
                before=passage(before,old_starts), after=passage(after,new_starts),
                report=prefix+report, report_label='Exact manuscript diff' if report=='final.diff' else 'Findings, decisions and verification')

data = json.loads((C/'postfoundationscrisis.json').read_text(encoding='utf-8'))
# Idempotent: preserve the completed Bias cards and replace our own later cards.
data['items'] = [item for item in data['items'] if '2026-09-20-postcrisis-bias-review/' in item.get('report','') and item['title'] != 'The next question becomes furniture']
data['status'] = 'Opening and Applied Ethics reviewed; Paraconsistent Engineering next'
data['summary'] = ('After QFEP asks who may revise the conditions, Post-Crisis begins with representation and participation. '
                   'The word study lets us vary the room given to a distinction. Applied Ethics now lets us choose a furniture plan, '
                   'then test what its colours persuade us to think. Both passes preserve the mature manuscripts and the existing artifact families.')
data['items'] += [
    pair('Before the first person speaks',
         'Applied Ethics begins with one neutral model. The existing HEAD and CIRCLE configurations are now available at the controls; PAIR brings them together. Chair count and relative scale differ, so the text does not pretend this changes arrangement alone.',
         ['ethics-head','ethics-circle'],
         ['HEAD: seven chair blocks, including a larger head position.', 'CIRCLE: six equal chair blocks. These solo models are larger than their paired versions.'],
         ['Walk around'], ['Begin with HEAD.', 'Press CIRCLE.'],
         'Actual states of the revised Godot museum, from the same elevated inspection camera. These are miniature models, not rooms the player can occupy; headset visibility remains to be checked.'),
    pair('Does the room seem to have made up its mind?',
         'The existing critique of red authority and green distribution can now be tried. COLOUR and NEUTRAL change furniture materials while every chair keeps its position, orientation and scale.',
         ['ethics-pair-neutral','ethics-pair-colour'],
         ['PAIR, NEUTRAL: both plans in the same furniture colour.', 'PAIR, COLOUR: the earlier red, tan and green judgements return. No chair moves.'],
         ['Notice how'], ['Leave PAIR'],
         'Same camera and geometry. The runtime probe checks every chair transform across this colour change. The passage about equal spacing versus equal opportunity remains unchanged.'),
    pair('What remains when the furniture goes?',
         'WATCH exposes an outward-facing ring beside the long table. Returning to PAIR before VACANT lets the reader remove the furniture while keeping its rectangular rooms. These new comparisons precede the preserved proposal for future observations with people.',
         ['ethics-watch','ethics-vacant'],
         ['WATCH: the seven-chair table beside eight backed seats and a raised centre; sixteen blocks in total.', 'VACANT: two unfurnished rectangular rooms. Walls, openings and scale remain authored.'],
         ['A future version'], ['WATCH puts', 'Return to PAIR', 'A future version'],
         '36 runtime checks, eight selected walking segments and 72 content checks pass. All six artifact families remain declared; five instantiate. The legacy tt and synthesis stand issues are recorded in the report. These two images show different plan states, not a controlled furniture-only pair.',
         'SUMMARY.md'),
    {'title': 'Next: keep the conflict',
     'description': 'Paraconsistent Engineering follows. Inspect the existing merge-conflict encounter and make its comparison usable while preserving the distinction between retaining disagreement and changing inference rules.',
     'report': prefix+'content-checks.json', 'report_label': 'Content and preservation checks'}
]
(C/'postfoundationscrisis.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Published Applied Ethics comparison data; Bias cards preserved')
