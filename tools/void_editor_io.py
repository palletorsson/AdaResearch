"""Validate a native-editor draft; optionally save with revision check and backup."""
from pathlib import Path
import argparse, hashlib, json, os, tempfile, time
from validate_void_rooms import validate, VOID

def commit(draft, expected, target=VOID / 'rooms.json'):
    raw = Path(draft).read_bytes()
    data = json.loads(raw)
    errors = validate(data)
    if errors:
        return {'ok': False, 'errors': errors}
    if expected is None:
        return {'ok': True, 'message': 'Layout passes placement validation.'}
    old = target.read_bytes()
    if hashlib.sha256(old).hexdigest() != expected:
        return {'ok': False, 'errors': ['Layout changed elsewhere. Reload before saving; your draft is preserved.']}
    backup_dir = VOID.parents[1] / 'ada_run/void-editor-backups' if target.resolve() == (VOID/'rooms.json').resolve() else target.parent / '.editor-backups'
    backup_dir.mkdir(exist_ok=True, parents=True)
    backup = backup_dir / (time.strftime('%Y%m%d-%H%M%S') + '-' + str(time.time_ns()) + '.json')
    backup.write_bytes(old)
    fd, name = tempfile.mkstemp(prefix='.void-save-', suffix='.json', dir=target.parent)
    try:
        with os.fdopen(fd, 'wb') as f:
            f.write(raw); f.flush(); os.fsync(f.fileno())
        if target.read_bytes() != old:
            return {'ok': False, 'errors': ['Layout changed during validation. Reload before saving.']}
        os.replace(name, target)
    finally:
        Path(name).unlink(missing_ok=True)
    return {'ok': True, 'revision': hashlib.sha256(raw).hexdigest(), 'backup': str(backup), 'message': 'Saved. Tower and web editor use this layout.'}

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--draft', required=True)
    parser.add_argument('--expected')
    args = parser.parse_args()
    try:
        result = commit(args.draft, args.expected)
    except Exception as error:
        result = {'ok': False, 'errors': [str(error)]}
    print(json.dumps(result))
    raise SystemExit(0 if result['ok'] else 1)
