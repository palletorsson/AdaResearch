"""Update collection counts after all twelve selected Wavefunctions pages are saved."""
from pathlib import Path
import json

here = Path(__file__).resolve().parent
assert len(json.loads((here / 'plates.json').read_text(encoding='utf-8'))['plates']) == 75
p = here / 'README.md'
t = p.read_text(encoding='utf-8').replace('Sixty-three six-panel', 'Seventy-five six-panel').replace('thirteen Forces halls and six Form Finding halls.', 'thirteen Forces halls, six Form Finding halls and twelve Wavefunctions halls.').replace('all sixty-three texts read at drafting', 'all seventy-five texts read at drafting')
t += '\nWavefunctions follows at http://localhost:3003/illustrations?sequence=wavefunctions. Twelve pages trace returns through state, sampled history, colliding terrain, visible passages, coordinate projections, neighbour coupling, phase modulation, columns, chance, struck voices, stair support, beats and a finite harmonic sum. The separate voice room compares iterative filtering with a freshly evaluated sum. waves-plates.json and waves-selected-images.json keep the drafting prompts, material references and selected versions.\n'
p.write_text(t, encoding='utf-8')
p = here / 'REVIEW.md'
t = p.read_text(encoding='utf-8').replace('thirteen Forces halls and six Form Finding halls, in canonical order.', 'thirteen Forces halls, six Form Finding halls and twelve Wavefunctions halls, in canonical order.')
p.write_text(t, encoding='utf-8')
p = here.parent / '2026-10-06-illustrations-collection' / 'README.md'
t = p.read_text(encoding='utf-8').replace('seventy-two selected comic editions', 'eighty-four selected comic editions').replace('sixty-three final-text pages', 'seventy-five final-text pages').replace('thirteen Forces halls and six Form Finding halls.', 'thirteen Forces halls, six Form Finding halls and twelve Wavefunctions halls.')
t += '\nWavefunctions-only collection: http://localhost:3003/illustrations?sequence=wavefunctions. All twelve canonical halls have selected final-text pages, with quoted captions, saved chapters and source records.\n'
p.write_text(t, encoding='utf-8')
p = here / 'NEXT.md'
t = p.read_text(encoding='utf-8').replace('63 final-text plates through all six Form Finding halls; Encyclopedia contains 72 selected pages', '75 final-text plates through all twelve Wavefunctions halls; Encyclopedia contains 84 selected pages').replace('Next sequence: wavefunctions, from commons/maps/sequences/wavefunctions.json.', 'Next sequence: randomness, from commons/maps/sequences/randomness.json.')
p.write_text(t, encoding='utf-8')
print('Updated counts and continuation: 75 final / 84 total; next sequence Randomness.')
