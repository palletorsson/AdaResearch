#!/usr/bin/env python3
"""Refresh one live-spine sequence without rebuilding unrelated museum halls.

    python tools/em_refresh_sequence.py array_tutorial          # inspect only
    python tools/em_refresh_sequence.py array_tutorial --apply  # backup + install
    python tools/em_refresh_sequence.py randomness --room Random_Remove --align-order --apply

Room membership/order comes from the live sequence and optional museum_interludes.
The interludes name existing spaces after a book chapter without adding chapters.
Geometry and placements use
em_map_halls.derive_row/normalize_row. The museum template must already exist:
reuse the selected maps' current template, or name an existing key explicitly.
Only the selected room rows and their map_authored ownership change. This does
not ship controls, overrides, bakes or cartridges, and does not verify learning.
"""
from __future__ import annotations

import argparse
import copy
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import sys

try:
    from . import em_map_halls
except ImportError:
    import em_map_halls

ROOT = Path(__file__).resolve().parents[1]
PLAN_PATHS = (Path('ada_run/em_plan.json'), Path('commons/data/museum/em_plan.json'))
DECLARATION = Path('commons/data/map_authored.json')


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read(path: Path) -> dict:
    return json.loads((ROOT / path).read_text(encoding='utf-8-sig'))


def expanded_museum_maps(spec: dict) -> list[str]:
    """Keep the book order while inserting explicitly authored museum spaces."""
    chapters = spec['maps']
    if not chapters or any(not isinstance(m, str) or not re.fullmatch(r'[A-Za-z0-9_]+', m) for m in chapters):
        raise ValueError('Expected a nonempty list of map folder names')
    if len(set(chapters)) != len(chapters):
        raise ValueError('Duplicate chapter in the selected sequence')
    interludes = spec.get('museum_interludes', [])
    if not isinstance(interludes, list):
        raise ValueError('museum_interludes must be a list')
    after = {}
    seen = set(chapters)
    for item in interludes:
        if not isinstance(item, dict):
            raise ValueError('Each museum interlude must name a map and an after chapter')
        name, anchor = item.get('map'), item.get('after')
        if not isinstance(name, str) or not re.fullmatch(r'[A-Za-z0-9_]+', name):
            raise ValueError('Invalid museum interlude map')
        if anchor not in chapters:
            raise ValueError(f'Interlude {name} must follow a declared book chapter')
        if name in seen:
            raise ValueError(f'Duplicate museum map: {name}')
        seen.add(name)
        after.setdefault(anchor, []).append(name)
    return [name for chapter in chapters for name in [chapter, *after.get(chapter, [])]]


def sequence_maps(sequence: str) -> tuple[list[str], list[str]]:
    order = em_map_halls.spine_names()
    if sequence not in order:
        raise ValueError(f'{sequence!r} is not in the live curriculum spine')
    maps = expanded_museum_maps(read(Path(f'commons/maps/sequences/{sequence}.json'))['sequences'][sequence])
    for other in order:
        if other == sequence:
            continue
        other_maps = expanded_museum_maps(read(Path(f'commons/maps/sequences/{other}.json'))['sequences'][other])
        overlap = set(maps).intersection(other_maps)
        if overlap:
            raise ValueError(f'Live spine ownership is ambiguous: {other}: {sorted(overlap)}')
    return maps, order


def choose_template(plan: dict, sequence: str, maps: list[str], explicit: str | None) -> tuple[str, str]:
    owners = {r.get('museum') for r in plan['plans']
              if r.get('sequence') == sequence or r.get('map') in maps}
    owners.discard(None)
    if explicit:
        key = explicit
        reason = 'Explicit existing museum key'
    elif len(owners) == 1:
        key = next(iter(owners))
        reason = 'Retained from existing plan rows for the selected rooms or chapter'
    else:
        raise ValueError(f'No unambiguous existing template ({sorted(owners)}); name --museum-template')
    if key not in plan.get('museums', {}):
        raise ValueError(f'Museum template {key!r} is absent from this plan')
    return key, reason


def patch_plan(plan: dict, sequence: str, maps: list[str], rows: list[dict], order: list[str],
               live_maps: list[str], align_order: bool = False) -> dict:
    """Preserve every non-target row, including its order and all placements."""
    targets = set(maps)
    unexpected = [r for r in plan['plans'] if r.get('sequence') == sequence and r.get('map') not in targets]
    if maps == live_maps and unexpected:
        raise ValueError('Selected chapter has other plan rows; reconcile those explicitly before refreshing')
    original = plan['plans']
    remaining = [r for r in original if r.get('map') not in targets]
    # Insert each selected room at its live-spine boundary. Do not reorder
    # unrelated rows. Optional index alignment updates only the two ordering
    # fields, because the runtime sorts pearl_index rather than array position.
    rank = order.index(sequence)
    merged = copy.deepcopy(remaining)
    for row in rows:
        map_rank = live_maps.index(row['map'])
        at = next((i for i, r in enumerate(merged)
                   if (r.get('sequence') == sequence and r.get('map') in live_maps
                       and live_maps.index(r['map']) > map_rank)
                   or (r.get('sequence') in order and order.index(r['sequence']) > rank)), len(merged))
        merged.insert(at, copy.deepcopy(row))
    result = copy.deepcopy(plan)
    result['plans'] = merged
    if align_order:
        for row in result['plans']:
            if row.get('sequence') == sequence and row.get('map') in live_maps:
                row['pearl_index'] = live_maps.index(row['map'])
                row['pearls_total'] = len(live_maps)
    def without_order(row):
        if align_order and row.get('sequence') == sequence and row.get('map') in live_maps:
            return {k: v for k, v in row.items() if k not in ('pearl_index', 'pearls_total')}
        return row
    assert [without_order(r) for r in result['plans'] if r.get('map') not in targets] == [without_order(r) for r in remaining]
    assert {k: v for k, v in result.items() if k != 'plans'} == {k: v for k, v in plan.items() if k != 'plans'}
    assert [r['map'] for r in result['plans'] if r.get('sequence') == sequence and r.get('map') in targets] == maps
    for name in maps:
        assert sum(r.get('map') == name for r in result['plans']) == 1
    return result


def patch_declaration(declaration: dict, sequence: str, maps: list[str], live_maps: list[str]) -> dict:
    result = copy.deepcopy(declaration)
    for chapter, values in result.items():
        if not chapter.startswith('_') and chapter != sequence and isinstance(values, list):
            result[chapter] = [m for m in values if m not in maps]
    members = [m for m in result.get(sequence, []) if m not in maps]
    for name in maps:
        rank = live_maps.index(name)
        at = next((i for i, other in enumerate(members)
                   if other in live_maps and live_maps.index(other) > rank), len(members))
        members.insert(at, name)
    result[sequence] = members
    return result


def encode(document: dict) -> bytes:
    return (json.dumps(document, ensure_ascii=False, indent=2) + '\n').encode('utf-8')


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('sequence')
    parser.add_argument('--museum-template', help='An existing key in the plan museums dictionary')
    parser.add_argument('--room', action='append', help='Refresh only this live-sequence room; repeat to select more')
    parser.add_argument('--align-order', action='store_true',
                        help='Also update only pearl_index/pearls_total for other live rooms in this chapter')
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    live_maps, order = sequence_maps(args.sequence)
    if args.room and any(m not in live_maps for m in args.room):
        raise ValueError('--room must belong to the selected live sequence')
    maps = [m for m in live_maps if not args.room or m in args.room]
    inputs = list(PLAN_PATHS) + [DECLARATION, Path('commons/maps/curriculum_spine.json'),
              Path(f'commons/maps/sequences/{args.sequence}.json'), Path('tools/em_map_halls.py'),
              Path('tools/em_refresh_sequence.py')]
    inputs += [Path(f'commons/maps/{m}/map_data.json') for m in maps]
    before = {p: (ROOT / p).read_bytes() for p in inputs}
    plans = {p: json.loads(before[p].decode('utf-8-sig')) for p in PLAN_PATHS}
    key, reason = choose_template(plans[PLAN_PATHS[0]], args.sequence, maps, args.museum_template)
    for plan in plans.values():
        if key not in plan.get('museums', {}):
            raise ValueError(f'The chosen template is not available in both live and shipped plans: {key}')
    rows = []
    post_color = order.index(args.sequence) > order.index('color')
    for name in maps:
        row = em_map_halls.derive_row(name.replace('_', ' ').lower(), name, key,
                                      live_maps.index(name), len(live_maps), args.sequence)
        em_map_halls.normalize_row(row, post_color, any(k in row for k in ('basin', 'passage', 'simulation')),
                                   width_exempt=args.sequence == 'forces')
        rows.append(row)
    documents = {p: patch_plan(plan, args.sequence, maps, rows, order, live_maps, args.align_order)
                 for p, plan in plans.items()}
    original_decl = json.loads(before[DECLARATION].decode('utf-8-sig'))
    documents[DECLARATION] = patch_declaration(original_decl, args.sequence, maps, live_maps)
    changed = {p: encode(doc) for p, doc in documents.items()
               if doc != json.loads(before[p].decode('utf-8-sig'))}
    # A repeat with the same maps is an actual no-op, including file timestamps.
    for p, doc in documents.items():
        again = (patch_declaration(doc, args.sequence, maps, live_maps) if p == DECLARATION
                 else patch_plan(doc, args.sequence, maps, rows, order, live_maps, args.align_order))
        assert again == doc
    report = {'sequence': args.sequence, 'maps': maps, 'live_sequence_maps': live_maps,
              'museum_template': key, 'template_source': reason,
              'mode': 'apply' if args.apply else 'inspect', 'changed_paths': [p.as_posix() for p in changed],
              'source_sha256': {p.as_posix(): sha(data) for p, data in before.items()},
              'proposed_sha256': {p.as_posix(): sha(changed.get(p, before[p])) for p in documents},
              'rows_before': {p.as_posix(): len(plan['plans']) for p, plan in plans.items()},
              'rows_after': {p.as_posix(): len(documents[p]['plans']) for p in PLAN_PATHS},
              'preservation': ('All unrelated geometry, artifacts, content, top-level metadata and relative order retained; '
                               'only named chapter ordering fields may align.' if args.align_order else
                               'All unrelated plan rows, placements, top-level metadata and relative order retained.'),
              'ordering_changes': {}, 'remaining_order_drift': {},
              'unselected_live_rooms_missing_from_plan': {},
              'idempotent': True, 'learner_verified': False,
              'derived': [{'map': r['map'], 'pearl_index': r['pearl_index'], 'room': r['room'],
                           'artifacts': len(r['artifacts']), 'ruling': r['_ruling']} for r in rows]}
    for p, plan in plans.items():
        updated = {r['map']: r for r in documents[p]['plans'] if r.get('sequence') == args.sequence and r.get('map')}
        report['ordering_changes'][p.as_posix()] = [
            {'map': r['map'],
             'before': {k: r.get(k) for k in ('pearl_index', 'pearls_total')},
             'after': {k: updated[r['map']].get(k) for k in ('pearl_index', 'pearls_total')}}
            for r in plan['plans'] if r.get('sequence') == args.sequence and r.get('map') in updated
            and any(r.get(k) != updated[r['map']].get(k) for k in ('pearl_index', 'pearls_total'))]
        report['remaining_order_drift'][p.as_posix()] = [
            {'map': r.get('map'), 'pearl_index': r.get('pearl_index'),
             'reason': 'not in live sequence' if r.get('map') not in live_maps else 'index differs from live sequence'}
            for r in updated.values() if r.get('map') not in live_maps
            or r.get('pearl_index') != live_maps.index(r['map'])]
        report['unselected_live_rooms_missing_from_plan'][p.as_posix()] = [m for m in live_maps if m not in updated]
    if args.apply and changed:
        # Parent agent may be editing a source map. Never install a mixed read.
        for p, data in before.items():
            if (ROOT / p).read_bytes() != data:
                raise ValueError(f'Input changed during derivation; rerun: {p}')
        stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
        backup = ROOT / 'ada_run/encounter_pilot/plan_refresh' / stamp
        for p, data in before.items():
            target = backup / 'before' / p
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
        report['backup'] = backup.relative_to(ROOT).as_posix()
        # Prepare all replacement files before any mutation of the live inputs.
        prepared = {}
        for p, data in changed.items():
            temp = (ROOT / p).with_name((ROOT / p).name + '.sequence-refresh.tmp')
            temp.write_bytes(data)
            prepared[p] = temp
        for p, temp in prepared.items():
            temp.replace(ROOT / p)
        (backup / 'report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    try:
        raise SystemExit(main())
    except (OSError, ValueError, KeyError) as error:
        print(f'Scoped sequence refresh failed: {error}', file=sys.stderr)
        raise SystemExit(1)
