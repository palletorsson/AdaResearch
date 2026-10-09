"""Verify this dated review's evidence and generated local comparison links."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import hashlib
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
COMPARE = HERE.parent / '2026-09-19-review-comparison'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


class References(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids, self.links, self.images = set(), [], []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            self.ids.add(attrs['id'])
        for key in ('href', 'src'):
            if key in attrs:
                self.links.append(attrs[key])
        if tag == 'img':
            self.images.append(attrs)


def verify():
    before = read(HERE / 'before-manuscripts/sha256.json')
    package = read(ROOT / 'doc/book/review-feedback/2026-09-18/color/package.json')
    finals, frozen = {}, {}
    for hall, sha in before.items():
        live = ROOT / f'commons/maps/{hall}/final.md'
        finals[hall] = digest(live) == sha
        old = ROOT / package['package_directory'] / 'sources/commons/maps' / hall / 'final.md'
        frozen[hall] = live.read_bytes() == old.read_bytes()
    inputs = {key: digest(ROOT / package[key]) == package[key + '_sha256']
              for key in ('zip', 'review_text')}
    review_dir = ROOT / 'doc/book/review-feedback/2026-09-18/color'
    for receipt in read(review_dir / 'received.json'):
        inputs[receipt['file']] = digest(review_dir / receipt['file']) == receipt['sha256']

    reports = {
        'Color_Context_Placed': 'opening/runtime/context/runtime-checks.json',
        'Color_Flashlight': 'opening/runtime/flashlight-after-checks.json',
        'Color_Nails': 'opening/runtime/probe_nail_salon.json',
        'Color_Rainbow': 'fields/evidence/probe_rainbow_celebration.json',
        'Color_Pillar': 'fields/evidence/after/pillar-field-checks.json',
        'Color_Grid_Pallet': 'fields/evidence/probe_grid_address.json',
        'Color_Paint': 'late/verified/probe_paint_encounter.json',
        'Color_Walls': 'late/after/probe_walls_encounter.json',
        'Chamber_Color': 'late/verified/probe_chamber_colour.json',
    }
    runtime = {}
    for hall, path in reports.items():
        data = read(HERE / path)
        checks = data['checks']
        runtime[hall] = {
            'report': path,
            'checks': len(checks) if isinstance(checks, list) else checks,
            'failures': data['failures'],
            'all_passed': not data['failures'] and
                (all(c['passed'] for c in checks) if isinstance(checks, list) else True),
        }

    page = References()
    page.feed((COMPARE / 'index.html').read_text(encoding='utf-8'))
    missing, local = [], 0
    for value in page.links:
        target = urlsplit(value)
        if target.scheme or target.netloc:
            continue
        local += 1
        if target.path:
            if not (COMPARE / unquote(target.path)).exists():
                missing.append(value)
        elif target.fragment and target.fragment not in page.ids:
            missing.append(value)

    data = read(COMPARE / 'color.json')
    images = {}
    for item in data['items']:
        for path in item.get('images', []):
            images[path] = digest(ROOT / path)
    tutorial = next(i for i in data['items'] if i.get('text_kind'))
    excerpts_match = (
        tutorial['before'] in (HERE / 'fields/before/Color_Pillar-tutorial.md').read_text(encoding='utf-8') and
        tutorial['after'] in (ROOT / 'commons/maps/Color_Pillar/tutorial.md').read_text(encoding='utf-8'))

    result = {
        'date': '2026-09-19',
        'final_chapters_match_start_of_pass': finals,
        'final_chapters_match_frozen_package': frozen,
        'original_review_inputs_unchanged': inputs,
        'runtime': runtime,
        'total_final_assertions': sum(r['checks'] for r in runtime.values()),
        'count_note': 'Includes repeated per-object geometry/material assertions; not independent learner tests.',
        'comparison_page': {
            'path': str((COMPARE / 'index.html').relative_to(ROOT)).replace('\\', '/'),
            'has_color_section': 'color' in page.ids,
            'local_links_and_assets_checked': local,
            'missing': missing,
            'image_count': len(page.images),
            'all_images_have_alt': all(i.get('alt') for i in page.images),
            'teaching_excerpts_match_sources': excerpts_match,
            'new_image_sha256': images,
            'inspection': 'All four Color image pairs viewed directly. HTML local references checked. Browser file URL inspection was blocked by Browser Use URL policy; no browser layout QA or workaround claimed.',
        },
        'headset_tested': False,
    }
    (HERE / 'verification.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    assert all(finals.values()) and all(frozen.values()) and all(inputs.values())
    assert all(r['all_passed'] for r in runtime.values())
    assert not missing and 'color' in page.ids and excerpts_match
    assert all(i.get('alt') for i in page.images)
    print(f"Verified {len(finals)} preserved chapters, {len(runtime)} passing hall probes, "
          f"{local} local page references and {len(images)} Color images.")


if __name__ == '__main__':
    verify()
