"""Append selected Randomness pages once; preserve all preceding editions."""
from pathlib import Path
import json

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
APP=ROOT.parent/'ada_encyclopedia'
def read(n):return json.loads((HERE/n).read_text(encoding='utf-8'))
def save(n,d):(HERE/n).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
spec,selected,new,choices=[read(n) for n in ['plates.json','selected-images.json','randomness-plates.json','randomness-selected-images.json']]
assert len(spec['plates'])==len(selected['plates'])==75
assert len(new['plates'])==len(choices['plates'])==14
assert [p['map'] for p in new['plates']]==[p['map'] for p in choices['plates']]
spec['plates'].extend(new['plates']);selected['plates'].extend(choices['plates'])
spec['scope']+=' Fourteen Randomness halls follow in canonical order.'
spec['description']+=' Randomness asks where a draw enters the construction, what its record omits and what happens when its consequence reaches a body.'
save('plates.json',spec);save('selected-images.json',selected)
p=APP/'src/app/illustrations/IllustrationGallery.tsx'
t=p.read_text(encoding='utf-8').replace('wavefunctions: "Wavefunctions",','wavefunctions: "Wavefunctions", randomness: "Randomness",')
p.write_text(t,encoding='utf-8')
p=HERE/'build_gallery.py'
t=p.read_text(encoding='utf-8').replace("'wavefunctions': 'Wavefunctions'", "'wavefunctions': 'Wavefunctions', 'randomness': 'Randomness'")
p.write_text(t,encoding='utf-8')
p=APP/'src/content/blog/2026-10-06-what-a-picture-has-to-carry.md'
t=p.read_text(encoding='utf-8').replace('seventy-five plates drawn','eighty-nine plates drawn')
paragraph='''The fourteen [Randomness pages](/illustrations?sequence=randomness) ask where a draw enters the work. One discarded number shifts a palette without moving a cube. Sorting retains symbol shares while changing neighbours. A removed cell becomes a fall only when support goes with its surface. A trail can record visits without guiding the next one; another terrain lets a changing signal recruit a later visit. Near the end, three passages separate drawing, disclosure and choice. A question mark can conceal a decision or stand before one.

![The same seed supplies different palettes when one draw is discarded before assigning colour.](/book-review/doc/book/iterations/2026-10-06-final-comic-plates/random-seed.png)

*A seed names a beginning. The generator, order of requests and use of their results belong to the picture's construction too.*

'''
t=t.replace('The most promising connection runs both ways.',paragraph+'The most promising connection runs both ways.')
p.write_text(t,encoding='utf-8')
p=HERE/'README.md';t=p.read_text(encoding='utf-8').replace('Seventy-five six-panel','Eighty-nine six-panel').replace('all seventy-five texts','all eighty-nine texts').replace('and twelve Wavefunctions halls.', 'twelve Wavefunctions halls and fourteen Randomness halls.')
t+='\nRandomness-only collection: http://localhost:3003/illustrations?sequence=randomness. Fourteen pages distinguish sampling, assignments, eligibility, retained records, local relationships, authored repertoires, feedback and decision timing. randomness-plates.json and randomness-selected-images.json retain the prompts and chosen editions.\n';p.write_text(t,encoding='utf-8')
p=HERE/'REVIEW.md';t=p.read_text(encoding='utf-8').replace('and twelve Wavefunctions halls, in canonical order.', 'twelve Wavefunctions halls and fourteen Randomness halls, in canonical order.')
t+='\n## Randomness selected editions\n\nAll fourteen complete chapters were read. Eighty-four panel excerpts and fourteen footer excerpts were checked against their saved chapter bytes. Figures, temporal views and overlays are companion interpretations; they do not certify collision, measured samples, learning, fairness or historical reconstructions.\n\n| Hall | Material distinction and limit |\n| --- | --- |\n'
for pnew in new['plates']:t+='| '+pnew['map']+' | '+pnew['source_review']+' |\n'
p.write_text(t,encoding='utf-8')
p=HERE.parent/'2026-10-06-illustrations-collection/README.md';t=p.read_text(encoding='utf-8').replace('eighty-four selected comic editions','ninety-eight selected comic editions').replace('seventy-five final-text pages','eighty-nine final-text pages')
t+='\nRandomness-only collection: http://localhost:3003/illustrations?sequence=randomness. All fourteen canonical halls have selected final-text pages.\n';p.write_text(t,encoding='utf-8')
p=HERE/'NEXT.md';t=p.read_text(encoding='utf-8').replace('75 final-text plates through all twelve Wavefunctions halls; Encyclopedia contains 84 selected pages', '89 final-text plates through all fourteen Randomness halls; Encyclopedia contains 98 selected pages').replace('Next sequence: randomness, from commons/maps/sequences/randomness.json.', 'Next sequence: noise, from commons/maps/sequences/noise.json.')
p.write_text(t,encoding='utf-8')
print('Preserved 75 editions; appended 14 Randomness plates. Total 89 final / 98 selected pages.')
