"""Attach the reviewed visual scope and preserve the continuation record."""
from pathlib import Path
import json

here = Path(__file__).resolve().parent
spec = json.loads((here / 'plates.json').read_text(encoding='utf-8'))
assert len(spec['plates']) == 75
draft = (here / 'waves-review-draft.md').read_text(encoding='utf-8')
review = here / 'REVIEW.md'
text = review.read_text(encoding='utf-8')
assert '# Wavefunctions illustration review' not in text
text += '\n' + draft.replace('# Wavefunctions illustration review', '## Wavefunctions illustration review')
text += '\nSelected refinements corrected the bob grip, history age direction and oldest-end deletion, the corridor gap axis, the circle direction labels, modulator depth, hum level, finite note ending, stair centre/gap provisions, beat cancellation and the voice-processing feedback diagram. Original drafts remain separate from selected editions. Waveform boards and event strips are explanatory drawings, not calibrated numeric plots or timing records. All seventy-five source fingerprints still match their reviewed versions. No final.md, tutorial.md, museum code or spine order was changed.\n'
review.write_text(text, encoding='utf-8')
print('Attached twelve-hall source and visual review.')
