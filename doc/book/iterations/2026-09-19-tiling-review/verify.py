"""Check the bounded Tiling review record; does not rerun Godot or edit content."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import difflib
import hashlib
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PAGE = HERE.parent / '2026-09-19-review-comparison'
FEEDBACK = ROOT / 'doc/book/review-feedback/2026-09-18/tiling'


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links, self.ids = [], set()

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            self.ids.add(attrs['id'])
        for key in ('href', 'src'):
            if attrs.get(key):
                self.links.append(attrs[key])
        if tag == 'img':
            assert attrs.get('alt'), 'Image needs its evidence caption'


def verify():
    result = {'scope': 'Eight Tiling halls; preservation and evidence checks, not a new runtime or learner trial'}
    before = read(HERE / 'before/tiling.json')
    current = read(ROOT / 'commons/maps/sequences/tiling.json')
    old, new = before['sequences']['tiling'], current['sequences']['tiling']
    for key in ('maps', 'prerequisites', 'artifact_groups', 'lab_map', 'return_to'):
        assert old[key] == new[key], key
    assert before['artifact_groups'] == current['artifact_groups']
    assert before['world_phase'] == current['world_phase']
    for key in ('notes', 'deferred_reason', 'museum_recovery_note'):
        assert old[key] == new['curation_history'][0][key]
    result['sequence_membership_and_history_preserved'] = True

    hashes = read(HERE / 'before/sha256.json')
    chapters = {}
    for name in new['maps']:
        original = HERE / 'before' / name / 'final.md'
        live = ROOT / 'commons/maps' / name / 'final.md'
        assert sha(original) == hashes[name]
        unchanged = original.read_bytes() == live.read_bytes()
        if name != 'Pattern_Foundry':
            assert unchanged, name
        chapters[name] = {'unchanged': unchanged, 'current_sha256': sha(live)}
    a = (HERE / 'before/Pattern_Foundry/final.md').read_text(encoding='utf-8')
    b = (ROOT / 'commons/maps/Pattern_Foundry/final.md').read_text(encoding='utf-8')
    changes = [op for op in difflib.SequenceMatcher(None, a.strip().split('\n\n'), b.strip().split('\n\n'), autojunk=False).get_opcodes() if op[0] != 'equal']
    assert len(changes) == 2 and all(op[0] == 'insert' and op[4] - op[3] == 1 for op in changes)
    result['chapters'] = chapters
    result['foundry_only_two_paragraph_insertions'] = True

    frozen = {
        ROOT / 'doc/book/review-packages/2026-09-18/tiling/review.md': 'fc901dc259051d5468d865d30b74fc0622e915b12958495331c9c2811b3dde83',
        ROOT / 'doc/book/review-packages/2026-09-18/tiling-review.zip': '8de87f703d01d4566507476f4c9bf397abf0e6c52c148ada3b5c14fbb96fa234',
        FEEDBACK / '01-review.md': read(FEEDBACK / 'received.json')[0]['sha256'],
    }
    for path, expected in frozen.items():
        assert sha(path) == expected, str(path)
    result['frozen_inputs_preserved'] = {str(p.relative_to(ROOT)): h for p, h in frozen.items()}

    chain = read(HERE / 'source-chain.json')
    assert {entry['map'] for entry in chain} == set(new['maps'])
    assert all(not entry[key] for entry in chain for key in ('missing_lookup', 'missing_scene', 'book_anchors_not_placed'))
    result['resolved_placed_instances'] = sum(entry['placed_instances'] for entry in chain)
    assert result['resolved_placed_instances'] == 98
    result['source_chain_scope'] = 'Registry/delegate resolution and book-anchor placement; not execution of every secondary artifact'

    opening = read(HERE / 'opening/verified-summary.json')
    for suite in opening['suites']:
        report = read(HERE / 'opening' / suite['report'])
        count = len(report['checks']) if isinstance(report['checks'], list) else report['checks']
        assert count == suite['checks'] and not report['failures']
        if isinstance(report['checks'], list):
            assert all(check['passed'] for check in report['checks'])
    result['opening'] = {'assertions': opening['assertions_total'], 'includes_replay_assertions': 22, 'failures': 0}
    result['relations'] = {}
    for path in ('after/probe_fixed_motif.json', 'after/probe_tunnel_addresses.json', 'final/probe_symmetry_compare.json', 'ceiling-after/probe_overlay_positions.json'):
        report = read(HERE / 'relations' / path)
        assert not report['failures'], path
        result['relations'][path] = report
    log = (HERE / 'relations/final/symmetry_compare-engine.log').read_text(encoding='utf-8')
    assert not any(term in log for term in ('!is_inside_tree', 'SCRIPT ERROR', 'Parse Error', 'Compile Error'))
    result['final_symmetry_scene_tree_and_compile_errors'] = 0
    bodies = read(HERE / 'bodies/runtime/runtime-summary.json')
    for suite in bodies.values():
        assert not suite['failures'] and suite['exit_code'] == 0 and not suite['script_compile_errors']
        assert not suite['sources_changed_during_run']
    result['bodies_runtime_assertions'] = sum(s['checks'] for s in bodies.values())
    metadata = read(HERE / 'bodies/metadata-validation.json')['checks']
    assert len(metadata) == 20 and all(c['pass'] for c in metadata)
    assert all(read(HERE / 'bodies/preservation-validation.json').values())
    result['ribbon_metadata_checks'] = len(metadata)

    comparison = read(PAGE / 'tiling.json')
    result['selected_image_sha256'] = {}
    for item in comparison['items']:
        if 'report' in item:
            assert (ROOT / item['report']).is_file(), item['report']
        for path in item.get('images', []):
            result['selected_image_sha256'][path] = sha(ROOT / path)
        if item.get('text_kind', '').startswith('final.md'):
            assert item['before'] in a and item['after'] in b
    for stem in ('wallpaper_cage', 'fixed_motif_bay'):
        before_camera = read(HERE / 'relations/clean-before' / (stem + '-camera.json'))
        destination = 'final' if stem == 'wallpaper_cage' else 'after'
        after_camera = read(HERE / 'relations' / destination / (stem + '-camera.json'))
        assert before_camera == after_camera
    html = Links()
    html.feed((PAGE / 'index.html').read_text(encoding='utf-8'))
    local = 0
    for link in html.links:
        parsed = urlsplit(link)
        if parsed.scheme or parsed.netloc:
            continue
        if parsed.path:
            assert (PAGE / unquote(parsed.path)).exists(), link
        elif parsed.fragment:
            assert parsed.fragment in html.ids, link
        local += 1
    assert 'tiling' in html.ids
    result['comparison_local_links_checked'] = local
    result['headset_tested'] = False
    result['learner_verified'] = False
    result['browser_layout_verified'] = False
    result['remaining_diagnostics'] = 'Startup UID/certificate, renderer-feature and cache warnings remain documented in the local audits; no globally clean log claim.'
    (HERE / 'verification.json').write_text(json.dumps(result, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    print('Verified 7 unchanged chapters, 2 Foundry insertions, 98 source references, selected runtime reports and', local, 'local comparison links.')


if __name__ == '__main__':
    verify()
