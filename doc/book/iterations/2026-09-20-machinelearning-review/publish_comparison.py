"""Add exact manuscript excerpts and current museum evidence to the shared review."""
from pathlib import Path
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PAGE = HERE.parent / '2026-09-19-review-comparison'
PREFIX = HERE.relative_to(ROOT).as_posix()


def paragraph(room, prefix, old=False):
    path = (HERE / 'before' if old else ROOT) / 'commons/maps' / room / 'final.md'
    return next(p for p in path.read_text(encoding='utf-8').split('\n\n') if p.startswith(prefix))


review = {
    'status': 'eight halls in the route; six chapters preserved',
    'summary': 'What actually changes when a machine appears to learn? Keep the eight-hall progression and strengthen two comparisons: repeat a loss experiment, then ask the same four centres to divide different populations. Memory and Generative return to the museum as clearly identified diagrams. Only Gradient Landscape and Classification receive manuscript edits.',
    'items': [
        {
            'title': 'Let the reader try the alternative',
            'description': 'The Classification chapter proposed rings as a future experiment. DATASET now cycles BLOBS, RINGS and BLOCK while keeping four centres. STEP, PAUSE / RUN and RESET make the updates and repeated beginnings available. An entrance bay gives this primary encounter space; the older rooms and supporting works continue behind it.',
            'images': [PREFIX + '/kmeans-blobs.png', PREFIX + '/kmeans-rings.png', PREFIX + '/kmeans-block.png'],
            'captions': ['BLOBS · three planted groups meet a demand for four centres.', 'RINGS · the colour boundaries cut across the form we follow with our eyes.', 'BLOCK · a sample without planted clusters is still divided into four groups.'],
            'image_note': 'Three states of the revised artifact in the actual Godot museum, using the same raised overview camera. Each dataset is reset and given eight step attempts; convergence can halt it sooner. These are not before/after software versions, and tracked-hand interaction has not been tested.',
            'text_kind': 'book — Classification',
            'before': paragraph('ML_Classification', 'Imagine replacing', True),
            'after': '\n\n'.join(paragraph('ML_Classification', p) for p in ['Press DATASET to', 'Press DATASET again']),
            'report': PREFIX + '/final.diff', 'report_label': 'Full exact manuscript diff, including the new opening'
        },
        {
            'title': 'Something must hold still',
            'description': 'The loss comparator previously redrew observations on RESET. It now repeats the selected data, starts and timer. Raising OUTLIERS introduces nested substitutions from a fixed set; unchanged observations stay put. The comparison has been raised and enlarged so the reset control is above the floor.',
            'images': [PREFIX + '/ML_Gradient_Landscape.png'],
            'captions': ['Current loss comparison · three scoring surfaces on a raised plinth.'],
            'image_note': 'Actual museum capture and a tested approach, not a before/after pair. The surrounding legacy displays still make this a busy room; clearer separation is recorded for a later staging pass.',
            'text_kind': 'book — Gradient Landscape',
            'before': paragraph('ML_Gradient_Landscape', 'The squared-error surface', True),
            'after': paragraph('ML_Gradient_Landscape', 'The squared-error surface'),
            'report': PREFIX + '/model-checks.json', 'report_label': 'Controlled comparisons and reproduced baseline failures'
        },
        {
            'title': 'Restore the diagrams and name their limits',
            'description': 'Memory and Generative were present in the manuscript but missing from the authored museum route. Both return. Their chapters already distinguish a diagram from trained behaviour, so they stay unchanged. Generative now shows its missing reference/candidate particles and updates its explicitly scripted score display.',
            'images': [PREFIX + '/ML_Sequence_Memory.png', PREFIX + '/ML_Generative.png'],
            'captions': ['Memory · walk around the gate and cell-state diagram; its entrance sign identifies the absent learning process.', 'Generative · reference and candidate particles make the illustrated exchange visible. The panel identifies scripted losses.'],
            'image_note': 'Current Godot museum captures, not matched before/after images. Selected perimeter passages pass with the collision body. Neither exhibit trains the network it illustrates; the restoration does not claim that it does.',
            'report': PREFIX + '/SUMMARY.md', 'report_label': 'Decisions for all eight halls and the next encounter tasks'
        },
        {
            'title': 'Preserve the chapters that already do the work',
            'description': 'Evolution, Neural Networks, Perception, Memory, Generative and Synthesis remain byte-for-byte unchanged. Book heroes now match the current primary encounters, all original artifact families and roles remain, and both museum plans contain the eight halls in order. The next sequence is Graph Theory.',
            'report': PREFIX + '/content-checks.json', 'report_label': '83 preservation and integration checks'
        }
    ]
}
(PAGE / 'machinelearning.json').write_text(json.dumps(review, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
path = PAGE / 'build.py'
source = path.read_text(encoding='utf-8')
source = source.replace("('swarmintelligence', 'Where coordination lives')]:", "('swarmintelligence', 'Where coordination lives'), ('machinelearning', 'What actually changes?')]:")
source = source.replace("'boolean_surfaces', 'swarmintelligence'] if", "'boolean_surfaces', 'swarmintelligence', 'machinelearning'] if")
path.write_text(source, encoding='utf-8')
print(PAGE / 'machinelearning.json')
