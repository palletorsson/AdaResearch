from pathlib import Path
import json

H = Path(__file__).resolve().parent
R = H.parents[3]
M = 'SpeculativeComputation_Situated_Computation'
C = H.parent / '2026-09-19-review-comparison'
prefix = H.relative_to(R).as_posix() + '/'
before = (H/'before/commons/maps'/M/'final.md').read_text(encoding='utf-8')
after = (R/'commons/maps'/M/'final.md').read_text(encoding='utf-8')

def passage(text, starts):
    return '\n\n'.join(next(p for p in text.split('\n\n') if p.startswith(s)) for s in starts)

def pair(title, description, images, captions, old_starts, new_starts, note, report='final.diff'):
    return dict(title=title, description=description, images=[prefix+n+'.png' for n in images],
                captions=captions, image_note=note, text_kind='book — following the claim to its source',
                before=passage(before,old_starts), after=passage(after,new_starts),
                report=prefix+report, report_label='Exact manuscript diff' if report=='final.diff' else 'Findings, decisions and verification')

data = json.loads((C/'postfoundationscrisis.json').read_text(encoding='utf-8'))
data['items'] = [i for i in data['items'] if not i.get('report','').startswith(prefix) and i['title'] != 'Next: where did the claim come from?']
data['status'] = 'First four halls reviewed; Collective Knowledge next'
data['summary'] = ('Post-Crisis moves from making distinctions visible, to arranging participation, preserving disagreement and locating a claim. '
                   'The word study, furniture plans, merge sculpture and four situated readouts offer comparisons the visitor can control. '
                   'The manuscripts preserve their strongest questions and keep evidence distinct from the authority a display can suggest.')
data['items'] += [
    pair('One subject, four locations',
         'The four existing panels face into the hall at full scale, with readable text and side controls. Begin with their original four-verdict comparison. Their map tokens assign the descriptions; visitor movement changes which panel can be read.',
         ['situated-nw','situated-ne'], ['NW: ORDERLY, 87%.', 'NE: CREATIVE, 64%.'],
         ['Read the subject'], ['Begin with FOOTNOTE'],
         'Actual revised museum captures from equivalent local camera positions at two different stations. No classifier measures the visitor.'),
    pair('An appealing word also needs evidence',
         'The mature passage stays. DANGEROUS is not made accountable by its high percentage; CREATIVE also needs criteria. All four station assignments and the shared subject remain intact.',
         ['situated-sw','situated-se'], ['SW: DANGEROUS, 92%.', 'SE: IRRELEVANT, 22%.'],
         ['Choose DANGEROUS'], ['Choose DANGEROUS'],
         'This text is deliberately unchanged. These are different stations and authored values, not measured probabilities.'),
    pair('Cover the address. What has the claim lost?',
         'A source-only variant becomes a visitor action. COVER conceals the footer without changing the verdict, its percentage or its assigned subject. FOOTNOTE reverses that gesture.',
         ['situated-sw','situated-covered'], ['FOOTNOTE: the address is visible below the claim.', 'COVER: a strip hides the same address; DANGEROUS remains at 92%.'],
         ['These are four authored'], ['These are four authored','Stay with DANGEROUS.'],
         'Same station and camera. Runtime checks confirm all four underlying text fields are identical; the change is physical occlusion.'),
    pair('Does a body make a claim more believable?',
         'WITNESS exposes the existing marked base, height rule and symbolic eye. The new paragraph asks whether this frame changes trust. The earlier proposal for comparing real criteria and observations remains future work.',
         ['situated-sw','situated-witness'], ['FOOTNOTE: the claim on its simple stand.', 'WITNESS: a marked body and eye frame the unchanged claim.'],
         ['For the room’s next experiment'], ['Now press WITNESS.','For the room’s next experiment'],
         'Same camera. 63 runtime checks, ten selected walking segments and 84 content checks pass. Five authored placements remain. The creature was paused only for this private probe; headset and learner verification remain open.', 'SUMMARY.md'),
    dict(title='Next: what becomes common?',
         description='Collective Knowledge asks how contributions become a shared object while their sources and disagreements remain revisable. Inspect the existing encounter before choosing the next change.',
         report=prefix+'content-checks.json', report_label='Content and preservation checks')
]
(C/'postfoundationscrisis.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Updated Post-Crisis comparison: four reviewed halls.')
