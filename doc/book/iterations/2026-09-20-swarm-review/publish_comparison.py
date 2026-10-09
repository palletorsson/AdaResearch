"""Publish exact saved/current excerpts on the existing comparison page."""
from pathlib import Path
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PAGE = HERE.parent / '2026-09-19-review-comparison'
PREFIX = HERE.relative_to(ROOT).as_posix()
MAPS = json.loads((ROOT / 'commons/maps/sequences/swarmintelligence.json').read_text(encoding='utf-8'))['sequences']['swarmintelligence']['maps']

def paragraph(room, prefix, old=False):
    path = (HERE / 'before' if old else ROOT) / 'commons/maps' / room / 'final.md'
    return next(p for p in path.read_text(encoding='utf-8').split('\n\n') if p.startswith(prefix))

review = {
    'status': 'seven halls restored to the route; three focused revisions',
    'summary': 'What holds a collective together: traces, neighbours, a reward, or care? The seven-hall order stays. Two missing halls return, two comparisons become repeatable, and the ecosystem reveals its population support. Four final.md chapters are retained unchanged.',
    'items': [
        {
            'title': 'Bring the missing encounters back into the walk',
            'description': 'The Ant Colony and Ecosystem chapters were present, but their halls were absent from the museum plan. Both now have enclosed galleries and tested perimeter passages. The first three halls keep their layouts; all original artifact families remain in the seven maps.',
            'images': [PREFIX + '/SwarmIntelligence_Ant_Colony_Optimization.png', PREFIX + '/SwarmIntelligence_Swarm_Intelligence_Algorithms.png'],
            'captions': ['Restored Ant Colony · home, food and two trail channels occupy a floor-scale field.', 'Restored Ecosystem · local organisms and a separate population-support record.'],
            'image_note': 'Current Godot museum captures, not a matched before/after pair. Required primaries instantiated and the selected perimeter routes passed with the museum collision body. Headset comfort and the full sequence walkthrough remain untested.',
            'report': PREFIX + '/SUMMARY.md', 'report_label': 'Findings, decisions and remaining work'
        },
        {
            'title': 'New travellers, inherited marks',
            'description': 'RESET now repeats food positions, qualities and ant headings. ANTS replaces the agents while preserving their field. The below-floor controls have been raised into reach and the display made smaller.',
            'images': [PREFIX + '/SwarmIntelligence_Agent_Based_Modeling_ABM.png'],
            'captions': ['Current ABM encounter · EVAPORATE and ANTS sit in front of the shared trail diagram.'],
            'image_note': 'Actual museum capture. Button detector centres are approximately 1.03 m above the floor. This verifies placement and a controlled approach; it does not substitute for using the controls with tracked hands.',
            'text_kind': 'book — Agent-Based Modeling',
            'before': paragraph(MAPS[3], 'Next vary ANTS.', True),
            'after': paragraph(MAPS[3], 'Next vary ANTS.'),
            'report': PREFIX + '/model-checks.json', 'report_label': 'Model comparisons and baseline failures'
        },
        {
            'title': 'A remembered place can lose its value',
            'description': 'An impossible initial novelty score froze the old memories. Saved places are now re-evaluated against the current archive. Its count and colour field change together; the field is also lifted above the museum floor.',
            'images': [PREFIX + '/pso-converge.png', PREFIX + '/pso-novelty.png'],
            'captions': ['CONVERGE · the centre stays valuable; particles overlap near it.', 'NOVELTY · distances are measured from the current archive, shown here at 35 / 200 places.'],
            'image_note': 'Two states of the revised artifact in the actual museum: same camera, same initial scatter and velocities, 180 updates of 1/60 second each. These are controlled snapshots, not before/after versions or proof of long-term exploration.',
            'text_kind': 'book — Particle Swarm Optimization',
            'before': paragraph(MAPS[5], 'Spend longer with NOVELTY.', True),
            'after': '\n\n'.join([paragraph(MAPS[5], prefix) for prefix in ['Spend longer with NOVELTY.', 'A remembered position', 'The archive holds']]),
            'report': PREFIX + '/final.diff', 'report_label': 'Complete exact manuscript diff'
        },
        {
            'title': 'Care becomes part of what can be observed',
            'description': 'The ecosystem was skipped because its scene root was Node2D. It now loads as a 3D exhibit, with distinct organism colours and an opt-in record of existing interventions. Support remains active.',
            'text_kind': 'book — Ecosystem',
            'before': paragraph(MAPS[6], 'Watch for a population recovery', True),
            'after': '\n\n'.join([paragraph(MAPS[6], prefix) for prefix in ['Watch for a population recovery', 'Look back at the organisms']]),
            'report': PREFIX + '/content-checks.json', 'report_label': 'Preservation and integration checks'
        }
    ]
}
(PAGE / 'swarmintelligence.json').write_text(json.dumps(review, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
path = PAGE / 'build.py'
text = path.read_text(encoding='utf-8')
text = text.replace("('boolean_surfaces', 'Connected for which body?')]:", "('boolean_surfaces', 'Connected for which body?'), ('swarmintelligence', 'Where coordination lives')]:")
text = text.replace("'isosurfaces', 'boolean_surfaces'] if", "'isosurfaces', 'boolean_surfaces', 'swarmintelligence'] if")
path.write_text(text, encoding='utf-8')
print(PAGE / 'swarmintelligence.json')
