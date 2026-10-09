"""Publish focused prose changes beside real museum captures."""
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
    'status': 'eight halls restored to the route; six chapters preserved',
    'summary': 'A valid local choice can still close off a better arrangement. Matching now lets a visitor test that on the same ten points: three pairs or five, depending on which edges are considered first. Spanning Trees and Matching return to the authored museum. The existing eight-hall progression holds; only Matching and Flow receive manuscript edits.',
    'items': [
        {
            'title': 'Keep your eye on one point left waiting',
            'description': 'The graph already contained the counterexample. ORDER now chooses cycle edges first or spokes first without moving a point or changing a connection. STEP, RUN / PAUSE and RESET make its decisions available to prediction and repetition. Both outcomes follow the free-endpoint rule; the earlier choices change who remains unpaired.',
            'images': [PREFIX + '/matching-cycle-first.png', PREFIX + '/matching-spokes-first.png'],
            'captions': ['CYCLE FIRST · three pairs, four outer points still waiting.', 'SPOKES FIRST · five pairs; the same graph can pair everyone.'],
            'image_note': 'Two completed scans of the revised artifact in the actual Godot museum, from the same raised camera. These are alternative states, not before/after software versions. Button signals and selected walking paths pass; headset use remains untested.',
            'text_kind': 'book — Matching',
            'before': paragraph('GT_Matching', 'The exhibit’s name', True),
            'after': '\n\n'.join(paragraph('GT_Matching', p) for p in ['When the cycle-first', 'Press ORDER', 'RESET repeats']),
            'report': PREFIX + '/final.diff', 'report_label': 'Exact manuscript diff, including the new opening'
        },
        {
            'title': 'The price of one more route',
            'description': 'Spanning Trees was in the manuscript but absent from the authored route. Its existing graph returns in a bounded gallery, raised above the floor and facing the approach. A startup reset was switching computation off; it now advances edge by edge. The chapter remains unchanged.',
            'images': [PREFIX + '/GT_Spanning_Trees.png'],
            'captions': ['Current Spanning Trees hall · accepted connections remain visible within the weighted graph.'],
            'image_note': 'Actual Godot museum capture. All vertex spheres clear the floor and the selected perimeter walk passes. The graph still has dense labels; readability in the headset and new hand controls are later work.',
            'report': PREFIX + '/model-checks.json', 'report_label': 'Model checks and controlled comparisons'
        },
        {
            'title': 'Could an earlier allocation be taken back?',
            'description': 'Flow now keeps a blocked junction and its excess visible. Its readout reports what reached the sink, without calling the partial allocation a maximum. The graph is raised to reading height, the old placement refreshed, and its wall text synchronized. The existing funnel and supporting artifacts remain.',
            'images': [PREFIX + '/GT_Flow.png'],
            'captions': ['Current Flow hall · the forward-only study during a run, with revised wall speech.'],
            'image_note': 'Current museum capture, not a before/after pair or a picture of the controlled blocked-state test. The selected approach passes. Residual reverse adjustments are not implemented; the manuscript invites that next comparison.',
            'text_kind': 'book — Flow',
            'before': paragraph('GT_Flow', 'A complete maximum-flow', True),
            'after': '\n\n'.join(paragraph('GT_Flow', p) for p in ['A junction can', 'A complete maximum-flow']),
            'report': PREFIX + '/GT_Flow-runtime.json', 'report_label': 'Placement and approach evidence'
        },
        {
            'title': 'Preserve the sequence; make the missing comparison possible',
            'description': 'Foundations, Layout, Pathfinding, Network Analysis, Connectivity and Spanning Trees retain their manuscripts byte for byte. No artifact family or role is removed. All eight halls occur in order in the authored route and derived views. The next sequence is Foundations Crisis.',
            'report': PREFIX + '/SUMMARY.md', 'report_label': 'Decisions by hall, verification limits and later tasks'
        }
    ]
}
(PAGE / 'graphtheory.json').write_text(json.dumps(review, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
path = PAGE / 'build.py'
source = path.read_text(encoding='utf-8')
source = source.replace("('machinelearning', 'What actually changes?')]:", "('machinelearning', 'What actually changes?'), ('graphtheory', 'What an early choice makes possible')]:")
source = source.replace("'swarmintelligence', 'machinelearning'] if", "'swarmintelligence', 'machinelearning', 'graphtheory'] if")
path.write_text(source, encoding='utf-8')
print(PAGE / 'graphtheory.json')
