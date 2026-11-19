"""One door for commons/void/rooms.json, the floor file of the Void tower.

Several sessions and the web editors write this file on the same day. On 2026-11-19 a save that was cut short
by a file lock left the file unparseable for a minute, with weeks of rows in it that exist nowhere else.
Palle gave the file's ownership to this session that day; this is what the owner asks of every writer:

    python tools/rooms_door.py check             parse it, count the floors, find rows that share an id
    python tools/rooms_door.py snapshot [note]   keep the file as it stands, recoverable, without a commit
    python tools/rooms_door.py list              the snapshots kept

    from rooms_door import edit, stage_from_head
    edit(change)             change(text) -> text. Snapshot, validate, write whole, read back, or leave it untouched.
    stage_from_head(change)  the same change applied to HEAD's copy and put in the index: your rows only.

A snapshot is the file stored as a git blob under refs/rooms/<utc time>: no commit, nothing staged, and
`git show refs/rooms/<name> > commons/void/rooms.json` brings it back. edit() takes one before every write.
A change is refused, and the file left as it was, when the result does not parse or the floors are not the
same floors in the same order (pass floors_may_change=True for a floor insert).
"""
import json
import os
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ROOMS = ROOT / 'commons/void/rooms.json'
REL = 'commons/void/rooms.json'


def git(*args, data=None):
    return subprocess.run(['git', *args], input=data, capture_output=True, cwd=ROOT).stdout


def findings(text):
    """What is wrong with this text as a floor file. An empty list means it may be written."""
    try:
        doc = json.loads(text)
    except json.JSONDecodeError as error:
        return ['does not parse: %s' % error]
    found = []
    floors = doc.get('floors')
    if not isinstance(floors, list) or not floors:
        return ['no floors']
    for index, floor in enumerate(floors):
        if not isinstance(floor.get('map'), str) or not isinstance(floor.get('artifacts'), list):
            found.append('floor %d has no map or no artifacts list' % index)
            continue
        seen = set()
        for row in floor['artifacts']:
            if row.get('id') in seen:
                found.append('%s: two rows share the id %s' % (floor['map'], row.get('id')))
            seen.add(row.get('id'))
    return found


def maps(text):
    return [floor['map'] for floor in json.loads(text)['floors']]


def snapshot(note=''):
    """Store the file as it stands under refs/rooms/<utc>. Returns the ref name, or '' when it is already kept."""
    blob = git('hash-object', '-w', '--no-filters', str(ROOMS)).decode().strip()
    kept = git('for-each-ref', '--format=%(objectname)', 'refs/rooms/').decode().split()
    if blob in kept:
        return ''
    name = 'refs/rooms/' + time.strftime('%Y%m%d-%H%M%S', time.gmtime()) + ('-' + ''.join(c if c.isalnum() else '-' for c in note)[:40] if note else '')
    git('update-ref', name, blob)
    return name


def write_whole(path, text):
    """Replace the file in one step; if another process holds it, write in place and never leave a tail."""
    data = text.encode('utf-8')
    temporary = path.with_name(path.name + '.door')
    temporary.write_bytes(data)
    for attempt in range(8):
        try:
            os.replace(temporary, path)
            return 'replaced'
        except PermissionError:
            time.sleep(0.75)
    temporary.unlink(missing_ok=True)
    old = path.stat().st_size
    with open(path, 'r+b') as handle:
        handle.write(data)
        if len(data) < old:
            try:
                handle.truncate(len(data))
            except PermissionError:
                # a shorter text under a lock: blank the old ending, which JSON allows, and say so
                handle.seek(len(data))
                handle.write(b'\n' + b' ' * (old - len(data) - 1))
                return 'written in place, old ending blanked (file was held open)'
    return 'written in place'


def edit(change, floors_may_change=False, path=ROOMS):
    """Apply change(text) -> text to the floor file, safely. Returns how it was written; raises ValueError if refused."""
    before = path.read_bytes().decode('utf-8')
    after = change(before)
    if after == before:
        return 'unchanged'
    found = [f for f in findings(after) if f.startswith(('does not parse', 'no floors', 'floor '))]
    if found:
        raise ValueError('refused, the file is untouched: ' + '; '.join(found[:3]))
    if not floors_may_change and maps(after) != maps(before):
        raise ValueError('refused, the file is untouched: the floors are not the same floors in the same order')
    if path == ROOMS:
        snapshot('before-edit')
    how = write_whole(path, after)
    back = path.read_bytes().decode('utf-8')
    if json.loads(back) != json.loads(after):
        raise RuntimeError('the file on disk is not what was written; restore the last snapshot (python tools/rooms_door.py list)')
    return how


def stage_from_head(change):
    """Put HEAD's copy with this change applied into the index, so a commit carries these rows and nobody else's."""
    head = git('show', 'HEAD:' + REL).decode('utf-8')
    staged = change(head)
    json.loads(staged)
    blob = git('hash-object', '-w', '--stdin', '--path', REL, data=staged.encode('utf-8')).decode().strip()
    subprocess.run(['git', 'update-index', '--cacheinfo', '100644,%s,%s' % (blob, REL)], check=True, cwd=ROOT)
    return blob


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    command = sys.argv[1] if len(sys.argv) > 1 else 'check'
    if command == 'check':
        text = ROOMS.read_bytes().decode('utf-8')
        found = findings(text)
        for line in found[:40]:
            print('FINDING', line)
        if not found or not found[0].startswith('does not parse'):
            doc = json.loads(text)
            print('%d floors, %d rows, %d findings' % (len(doc['floors']), sum(len(f['artifacts']) for f in doc['floors']), len(found)))
        return len(found)
    if command == 'snapshot':
        name = snapshot(' '.join(sys.argv[2:]))
        print(name or 'already kept: the file has not changed since a snapshot')
        return 0
    if command == 'list':
        print(git('for-each-ref', '--sort=-refname', '--format=%(refname)  %(objectname:short)', 'refs/rooms/').decode().strip() or 'no snapshots yet')
        return 0
    print(__doc__)
    return 2


if __name__ == '__main__':
    sys.exit(main())
