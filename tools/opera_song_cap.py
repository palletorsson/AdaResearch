#!/usr/bin/env python3
"""AT MOST TEN SONGS A FLOOR.

    python tools/opera_song_cap.py                     which floors sing more than ten, and what would stay
    python tools/opera_song_cap.py --show Map,Map      the same, with every song of those floors (or --show all)
    python tools/opera_song_cap.py --apply             switch the rest off (outline + published world)
    python tools/opera_song_cap.py --cap 8             another limit

Palle, 23 November 2026: "in some of map there is like more then 10 songs that is to many." Measured that day:
50 floors published more than ten songs for works standing on them (Point_Animatedcube 34, Primitives_Ignorance 30);
most of the excess were generated drafts, the same line sung by a row of plinths, tapes and stacks.

WHAT COUNTS. A song is counted on a floor when the published world (commons/data/encounters/trajectory_runtime.json)
binds it to a row that stands on that floor NOW (commons/void/rooms.json). A work moved to another floor does not
sing where it stood and is not counted; its outline entry is left as it is.

WHICH SONGS STAY on a floor, in this order, until the limit:
  1 framed    a view frame is placed for it (the cue a visitor meets; on the six opening floors only these sing)
  2 chosen    an outline entry a person added (origin "user")
  3 authored  a written song, not a generated draft; primary works first, then the outline's order
  4 drafts    never a line already sung on this floor; by the work's role in its hall
              (commons/data/artifact_roles.json: primary or unruled, secondary, decoration and props); works that
              stand on few floors before furniture that stands on many; then the outline's order
A song the world binds without an outline entry (a chamber's own song, written into the world by hand) cannot be
switched off here: it takes one of the ten places first.

WHAT --apply CHANGES. Only the songs it switches off:
  outline   entry.song true -> false (the badge stays); savedAt
  world     entries[id].song live -> off; the bindings of its targets; its coins lose `song`, the default text
            A SONG LIVES HERE becomes AN ENCOUNTER and the note mark leaves the face; counts; source_revision
Nothing is deleted: set an entry's `song` back to true and publish to hear it again.
It does NOT go through the outline editor's save (ada_encyclopedia saveTrajectory). On 23 November that save could
not pass: the outline held five maps the tower no longer has, and validation refuses an unknown map. It takes the
editor's lock file, writes a history snapshot as the editor does, and keeps copies under ada_run/song-cap/.
Check in the game: python tools/run_floor_probe.py <Map> songs_per_floor.gd songs_per_floor.json <folder> --no-opening --opera-quiet
"""
import collections
import datetime
import hashlib
import json
import os
import sys
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTLINE = ROOT / 'commons/data/encounters/trajectory_outline.json'
WORLD = ROOT / 'commons/data/encounters/trajectory_runtime.json'
CAP = 10
POLICIES = {'Point_Zero': 'point_zero', 'Point_One': 'point_one', 'Point_Coordinates': 'point_coordinates', 'Point_Lines': 'point_lines',
            'Point_Trace': 'point_trace', 'Point_Triangle_Context': 'point_triangle_context'}          # commons/void/opening_opera_trail.gd
WHEEL = 'spine_c2b6fc98a64a37b397'
# the note on a coin's face, and the dot a coin without a song carries (ada_encyclopedia/src/lib/trajectory-world.ts)
NOTE = '<circle cx="81" cy="19" r="13" fill="#eb0d85"/><path d="M79 25V12L88 10V22M79 12L88 10" fill="none" stroke="#fffdf8" stroke-width="2.5"/><ellipse cx="76" cy="25" rx="4" ry="3" fill="#fffdf8"/><ellipse cx="85" cy="22" rx="4" ry="3" fill="#fffdf8"/>'
DOT = '<circle cx="50" cy="23" r="5" fill="#1d1d1f"/>'


def load(rel):
    return json.loads((ROOT / rel).read_bytes().decode('utf-8'))


def sha(text):
    return hashlib.sha256(text.encode('utf-8')).hexdigest()


def write(path, text):
    tmp = str(path) + '.' + uuid.uuid4().hex + '.tmp'
    with open(tmp, 'wb') as f:
        f.write(text.encode('utf-8'))
    os.replace(tmp, path)


def plan_for(cap, outline, world, show=()):
    """{map: [entry ids to switch off]} and the lines of the report."""
    rooms = load('commons/void/rooms.json')
    score = load(str(load('commons/data/opera/tower_bindings.json')['score']).replace('res://', ''))
    line = {p['object_id']: ' '.join(str(p.get('text', '')).lower().split()) for p in score.get('phrases', [])}
    placements = load('commons/data/encounters/opera_frame_placements.json')
    roles = load('commons/data/artifact_roles.json').get('roles', {})
    token_of, prop, floors_of, index_of = {}, set(), collections.defaultdict(set), {}
    for i, f in enumerate(rooms['floors']):
        index_of[f['map']] = i
        for kind in ('artifacts', 'copies', 'props'):
            for row in f.get(kind, []):
                token = str(row.get('artifact', row.get('prop', row.get('kind', ''))))
                token_of[(f['map'], row['id'])] = token
                floors_of[token].add(f['map'])          # furniture stands on many floors
                if kind == 'props':
                    prop.add((f['map'], row['id']))

    def stands(name, target):
        return (name, target.split('/')[0]) in token_of

    def role_of(name, target):
        key = (name, target.split('/')[0])
        if key in prop:
            return 2
        ruled = roles.get(name, {}).get(token_of.get(key, ''), 'primary')
        if isinstance(ruled, dict):
            ruled = ruled.get('role', 'primary')
        return {'primary': 0, 'secondary': 1, 'decoration': 2}.get(str(ruled), 0)

    def framed(name):
        chosen = set()
        if name in POLICIES:
            for e in load('commons/data/encounters/%s_progression.json' % POLICIES[name])['encounters']:
                if 'view_frame' in e:
                    chosen.add(e['song'])
        for song, edit in placements.get(name, {}).items():
            if isinstance(edit, dict) and edit.get('kind') not in ('encounter', 'list') and (song == WHEEL or 'position' in edit):
                chosen.add(song)
        return chosen

    plan, rows, away_on = {}, [], {}
    for m in outline['maps']:
        name = m['map']
        if name not in index_of:
            continue                                   # a map the tower no longer holds: nothing of it sings
        songs, away = collections.OrderedDict(), set()  # song id -> its entries, in the outline's order
        for e in m['entries']:
            st = world['entries'].get(e['id'], {})
            if not e.get('song') or st.get('song') != 'live':
                continue
            if not any(stands(name, t) for t in st['targets']):
                away.add(st['songId'])
                continue
            songs.setdefault(st['songId'], []).append(e)
        away -= set(songs)
        if away:
            away_on[name] = len(away)
        loose = {sid for target, sid in world['maps'].get(name, {}).items() if stands(name, target) and sid not in songs and sid not in away}
        room = cap - len(loose)
        if len(songs) <= room:
            continue
        frames = framed(name)
        ranked = []
        for order, (sid, entries) in enumerate(songs.items()):
            targets = [t for e in entries for t in world['entries'][e['id']]['targets'] if stands(name, t)]
            spread = min([len(floors_of[token_of[(name, t.split('/')[0])]]) for t in targets] or [999])
            role = min([role_of(name, t) for t in targets] or [2])
            tier = 1 if sid in frames else 2 if any(e['origin'] == 'user' for e in entries) else 4 if all(e.get('songDraft') for e in entries) else 3
            ranked.append({'song': sid, 'tier': tier, 'order': order, 'spread': spread, 'role': role, 'line': line.get(sid, ''),
                           'title': entries[0]['title'], 'entries': [e['id'] for e in entries]})
        ranked.sort(key=lambda r: (r['tier'], (r['role'], 0 if r['spread'] <= 3 else 1 if r['spread'] <= 8 else 2) if r['tier'] == 4 else (r['role'] if r['tier'] == 3 else 0, 0), r['order']))
        kept, lines = [], set()
        for r in ranked:
            if len(kept) >= room:
                break
            if r['tier'] == 4 and r['line'] and r['line'] in lines:
                continue                               # a draft never repeats a line already sung on this floor
            kept.append(r)
            lines.add(r['line'])
        keep = {r['song'] for r in kept}
        plan[name] = [e for r in ranked if r['song'] not in keep for e in r['entries']]
        had, has = collections.Counter(r['tier'] for r in ranked), collections.Counter(r['tier'] for r in kept)
        text = ['floor %3d %-52s %2d -> %2d   framed %d/%d  authored %d/%d  drafts %d/%d%s' % (
            index_of[name], name, len(songs) + len(loose), len(kept) + len(loose), has[1], had[1], has[2] + has[3], had[2] + had[3], has[4], had[4],
            '   (+%d written into the world by hand)' % len(loose) if loose else '')]
        if name in show or 'all' in show:
            for r in sorted(ranked, key=lambda r: r['order']):
                text.append('      %s %s %s on %3d floors  %-44s | %s' % ('KEEP' if r['song'] in keep else ' off', ' FAad'[r['tier']], 'PSD'[r['role']], r['spread'], r['title'][:44], r['line'][:70]))
        rows.append((index_of[name], text, len(songs) + len(loose), len(kept) + len(loose)))
    rows.sort()
    report = ['limit %d; floors over it: %d; songs on them %d -> %d; entries to switch off: %d' % (
        cap, len(rows), sum(r[2] for r in rows), sum(r[3] for r in rows), sum(len(v) for v in plan.values()))]
    for r in rows:
        report += r[1]
    if away_on:
        report.append('songs of works that no longer stand on their floor (silent, left as they are): %d on %d floors: %s' % (
            sum(away_on.values()), len(away_on), ', '.join('%s %d' % kv for kv in sorted(away_on.items(), key=lambda kv: -kv[1]))))
    return plan, report


def apply(plan, outline_text, world_text):
    """The planned entries lose their song in the outline and in the world. Returns the two new texts and a summary."""
    doc, world = json.loads(outline_text), json.loads(world_text)
    assert json.dumps(doc, indent=2, ensure_ascii=False) + '\n' == outline_text, 'the outline would not be written back as it stands'
    forms = {'pretty, escaped': dict(indent=2), 'pretty': dict(indent=2, ensure_ascii=False), 'compact': dict(separators=(',', ':'), ensure_ascii=False)}
    tail = '\n' if world_text.endswith('\n') else ''
    form = next((name for name, kw in forms.items() if json.dumps(world, **kw) + tail == world_text), 'compact')
    legacy = {c['id']: c for c in load('commons/data/badges/path.json').get('coins', [])}
    every = {i for ids in plan.values() for i in ids}
    flipped = unbound = 0
    for m in doc['maps']:
        for e in m['entries']:
            if e['id'] not in plan.get(m['map'], ()):
                continue
            st = world['entries'][e['id']]
            assert e['song'] is True and st['song'] == 'live' and st['map'] == m['map'], e['id']
            e['song'] = False
            st['song'] = 'off'
            flipped += 1
            for target in st['targets'] + st.get('missingTargets', []):
                if world['maps'][m['map']].get(target) == st['songId']:
                    del world['maps'][m['map']][target]
                    unbound += 1
    assert flipped == len(every), (flipped, len(every))
    coins = 0
    for coin in world['coins']:
        if coin.get('trajectory_entry') not in every:
            continue
        coins += 1
        coin.pop('song', None)
        if coin.get('text') == 'A SONG LIVES HERE':
            coin['text'] = 'AN ENCOUNTER'
        if NOTE in coin.get('face', ''):
            old = legacy.get(coin['id'])
            own_face = old is not None and old.get('name') == coin.get('name') and old.get('floor') == coin.get('floor')
            coin['face'] = coin['face'].replace(NOTE, '' if own_face else DOT)
    world['counts']['songs'] = len({sid for m in world['maps'].values() for sid in m.values()})
    world['counts']['links'] = sum(len(m) for m in world['maps'].values())
    now = datetime.datetime.now(datetime.timezone.utc)
    doc['savedAt'] = now.strftime('%Y-%m-%dT%H:%M:%S.') + '%03dZ' % (now.microsecond // 1000)
    new_outline = json.dumps(doc, indent=2, ensure_ascii=False) + '\n'
    world['source_revision'] = sha(new_outline)
    summary = 'entries %d, bindings %d, coins %d; the world now holds %d songs on %d bindings' % (flipped, unbound, coins, world['counts']['songs'], world['counts']['links'])
    return new_outline, json.dumps(world, **forms[form]) + tail, summary


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    args = sys.argv[1:]
    cap = int(args[args.index('--cap') + 1]) if '--cap' in args else CAP
    show = args[args.index('--show') + 1].split(',') if '--show' in args else []
    if '--apply' not in args:
        outline_text = OUTLINE.read_bytes().decode('utf-8')
        world = json.loads(WORLD.read_bytes().decode('utf-8'))
        if world.get('source_revision') != sha(outline_text):
            print('NOTE: the published world was not made from this outline (publish, or expect the two to disagree)')
        plan, report = plan_for(cap, json.loads(outline_text), world, show)
        print('\n'.join(report))
        return 1 if plan else 0
    lock = str(OUTLINE) + '.editor.lock'
    fd = os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY)          # the outline editor's own lock: one save at a time
    try:
        outline_text, world_text = OUTLINE.read_bytes().decode('utf-8'), WORLD.read_bytes().decode('utf-8')
        plan, report = plan_for(cap, json.loads(outline_text), json.loads(world_text), show)
        print('\n'.join(report))
        if not plan:
            print('nothing to switch off')
            return 0
        new_outline, new_world, summary = apply(plan, outline_text, world_text)
        now = datetime.datetime.now(datetime.timezone.utc)
        stamp = now.strftime('%Y-%m-%dT%H-%M-%S-') + '%03dZ' % (now.microsecond // 1000)
        keep = ROOT / 'ada_run/song-cap' / stamp
        keep.mkdir(parents=True, exist_ok=True)
        write(keep / 'trajectory_outline.json', outline_text)
        write(keep / 'trajectory_runtime.json', world_text)
        write(keep / 'switched_off.json', json.dumps(plan, indent=1))
        history = ROOT / 'commons/data/encounters/trajectory_history'
        history.mkdir(parents=True, exist_ok=True)
        write(history / (stamp + '-' + str(uuid.uuid4()) + '.json'), outline_text)
        assert OUTLINE.read_bytes().decode('utf-8') == outline_text and WORLD.read_bytes().decode('utf-8') == world_text, 'a file changed while this ran: nothing written'
        write(WORLD, new_world)
        write(OUTLINE, new_outline)
        print(summary)
        print('copies of both files as they were:', keep.relative_to(ROOT).as_posix())
        return 0
    finally:
        os.close(fd)
        os.remove(lock)


if __name__ == '__main__':
    sys.exit(main())
