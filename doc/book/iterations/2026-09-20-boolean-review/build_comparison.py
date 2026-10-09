"""Refresh the review's selected quotations from the preserved and live texts."""
from pathlib import Path
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
COMPARISON = HERE.parent / '2026-09-19-review-comparison'
PREFIX = HERE.relative_to(ROOT).as_posix()


def passage(map_name, start, old=False, count=1):
    base = HERE / 'before' if old else ROOT
    paragraphs = (base / f'commons/maps/{map_name}/final.md').read_text(encoding='utf-8').split('\n\n')
    at = next(i for i, paragraph in enumerate(paragraphs) if paragraph.startswith(start))
    return '\n\n'.join(paragraphs[at:at + count])


review = {
    'status': 'existing encounter developed; three chapters revised',
    'summary': 'The burrow was already in the hall, but absent from the book. Its connected hollows stopped the museum body at a raised join. A level cutting profile now makes a tested route into the same wandering plan. The sequence can ask which body an opening accommodates, and let the visitor try an answer.',
    'items': [
        {
            'title': 'Give the objects room to disagree',
            'description': 'All nine artifact families remain in Works. The visual wall, roofed burrow and raised cavern model now have separate places, with an aisle beside them. The hall is eight cells longer.',
            'images': [f'{PREFIX}/before-overview.png', f'{PREFIX}/after-overview.png'],
            'captions': ['Before · the large models overlap the surrounding architecture.', 'Current · the visual wall leads toward the roofed burrow.'],
            'image_note': 'Same overview camera in the actual museum, captured in Godot with Vulkan/mobile rendering. These images show the spatial change; the body tests provide separate evidence about passage.',
            'text_kind': 'book — Boolean_Works opening',
            'before': passage('Boolean_Works', 'You cannot.', old=True),
            'after': passage('Boolean_Works', 'Do not answer'),
        },
        {
            'title': 'Connected for which body?',
            'description': 'Burrow becomes a primary encounter beside the workbench and cavern model. Eleven seeded centres and their overlap graph stay the same. Cylindrical cutters give the hollow a level floor. The original spherical profile remains available.',
            'images': [f'{PREFIX}/after-burrow.png', f'{PREFIX}/after-inside.png'],
            'captions': ['Current entrance · the invitation sits above the opening.', 'Inside · rounded walls, a roof and a floor that continues through the joins.'],
            'image_note': 'Two views of the revised museum encounter. The actual 1.5 m high, 0.32 m radius desktop collision capsule reached six inward and six return waypoints; intact rock blocked it. Headset comfort and other body sizes remain untested.',
            'text_kind': 'book — new Boolean_Works encounter',
            'before': '',
            'after': passage('Boolean_Works', 'This burrow was already') + '\n\n' + passage('Boolean_Works', 'The spherical version remains'),
        },
        {
            'title': 'Estimate before reading the number',
            'description': 'The existing intersection-volume display is enabled, turned toward the approach and given enough panel height for its three lines. The text distinguishes a shared radius parameter from the different representations built with it.',
            'images': [f'{PREFIX}/verbs-readout.png'],
            'captions': ['Current Verbs hall · operand volumes and their shared region.'],
            'image_note': 'Actual Godot hall in compatibility rendering. The revised text asks the reader to look for a facet and compare what the gauge measures with what is visible.',
            'text_kind': 'book — Boolean_Verbs',
            'before': passage('Boolean_Verbs', 'So there are three spheres', old=True),
            'after': passage('Boolean_Verbs', 'A number with three'),
        },
        {
            'title': 'Change the route through the comparison',
            'description': 'All 24 Gallery placements remain unchanged. Its default-first catalogue order differs from the gradual order a tutorial might choose. The prose now makes that difference available for exploration.',
            'text_kind': 'book — Boolean_Gallery',
            'before': passage('Boolean_Gallery', 'Walk this band left', old=True),
            'after': passage('Boolean_Gallery', 'Walk this band left'),
        },
        {
            'title': 'Evidence and remaining work',
            'description': '32 integration checks pass. Controlled museum tests compare the original obstruction, revised inward and return route, intact wall, gallery aisle and visual wall. The workbench selection affordance and a less forensic Gallery reading remain named next tasks.',
            'report': f'{PREFIX}/SUMMARY.md',
            'report_label': 'Findings, decisions, tests and limits',
        },
        {
            'title': 'Read the complete text change',
            'description': 'Verbs receives the largest clarification. Gallery keeps its comparisons. Works gains the burrow encounter and an ending that leaves room for an implemented answer. The saved originals remain available beside the current manuscripts.',
            'report': f'{PREFIX}/final.diff',
            'report_label': 'Complete three-chapter diff',
        },
    ],
}
(COMPARISON / 'boolean_surfaces.json').write_text(json.dumps(review, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('Boolean Surfaces comparison refreshed from source passages.')
