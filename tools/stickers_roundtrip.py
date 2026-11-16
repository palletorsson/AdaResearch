"""stickers_roundtrip.py - one sticker from the web into a running game, one from the game onto the web (2026-11-13).

The sticker app's two live legs on this machine, through the real routes, with no bridge - and never through the
truth. The run copies commons/data/stickers/ into a TEST SANDBOX, ada_run/stickers/sandbox/rt-<time>/, and both
legs use that copy: the routes read and write it when a request names it (?sandbox=<id>, stickers-store.ts
inSandbox), and the game's StickerData is pointed at it with its outbox beside it and its POSTs naming it.
  web -> game   POST an 'add' to /api/stickers/ops?sandbox=<id> (as the /stickers page does); the game must see it
                by its own one-second file watch on the copy (tools/probes/stickers_roundtrip.gd);
  game -> web   the game sticks one of its own and flushes its outbox to the same route; GET /api/stickers?sandbox=<id>
                must then hold it, stuck 'by' the game.
The truth (commons/data/stickers/*.json) is only READ: its md5 before and after must match, and nothing restores it.
The sandbox is removed afterwards (--keep keeps it). Needs the encyclopedia's dev server on :3003.

  python tools/stickers_roundtrip.py [--keep]     exit 0 when both legs arrive and the truth is untouched
"""
import hashlib
import json
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / 'commons' / 'data' / 'stickers'
OUT = ROOT / 'ada_run' / 'stickers' / 'roundtrip'
SANDBOXES = ROOT / 'ada_run' / 'stickers' / 'sandbox'
GODOT = r'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
URL = 'http://127.0.0.1:3003/api/stickers'


def truth_md5():
    return {p.name: hashlib.md5(p.read_bytes()).hexdigest() for p in sorted(DATA.glob('*.json'))}


def post(sandbox, body):
    req = urllib.request.Request(f'{URL}/ops?sandbox={sandbox}', data=json.dumps(body).encode('utf-8'), headers={'content-type': 'application/json'}, method='POST')
    with urllib.request.urlopen(req, timeout=20) as r:
        return json.loads(r.read().decode('utf-8'))


def get(sandbox):
    with urllib.request.urlopen(f'{URL}?sandbox={sandbox}', timeout=20) as r:
        return json.loads(r.read().decode('utf-8'))


def sandbox_honoured():
    """A server that ignores ?sandbox= would write the TRUTH. Both routes the run uses must refuse a sandbox that does
    not exist - 422 AND the store's own words ('no test sandbox'), since a 422 can also mean a file that does not
    validate - the ops route with a harmless op (a note on no sticker), which a sandbox-blind server would not apply
    to anything either."""
    def refused(req):
        try:
            urllib.request.urlopen(req, timeout=20)
            return False
        except urllib.error.HTTPError as e:
            return e.code == 422 and 'no test sandbox' in e.read().decode('utf-8', 'replace')
        except OSError:
            return False
    get = urllib.request.Request(f'{URL}?sandbox=no-such-sandbox-preflight')
    ops = urllib.request.Request(f'{URL}/ops?sandbox=no-such-sandbox-preflight', method='POST', headers={'content-type': 'application/json'},
                                 data=json.dumps({'by': 'preflight', 'ops': [{'op_id': 'preflight-no-sandbox', 'op': 'note', 'id': 'no-such-sticker', 'note': 'x'}]}).encode('utf-8'))
    return refused(get) and refused(ops)


def main():
    if not sandbox_honoured():
        return {'error': 'the dev server does not honour ?sandbox= (old route code?): refusing to run, the truth would be written'}
    OUT.mkdir(parents=True, exist_ok=True)
    for p in OUT.glob('*.json'):
        p.unlink()
    stamp = time.strftime('%H%M%S')
    sandbox = f'rt-{stamp}'
    box = SANDBOXES / sandbox
    box.mkdir(parents=True, exist_ok=False)
    for name in ('designs.json', 'boards.json', 'placements.json', 'constructions.json'):
        if (DATA / name).exists():   # constructions.json: without it the sandbox has no walls, and a tie between two is refused
            shutil.copyfile(DATA / name, box / name)
    before = truth_md5()
    web_id = f'rt-web-{stamp}'
    report = {'web_id': web_id, 'sandbox': str(box.relative_to(ROOT)).replace('\\', '/'), 'truth_md5_before': before}
    godot = None
    try:
        godot = subprocess.Popen([sys.executable, str(ROOT / 'tools' / 'godot_watchdog.py'), f'--expect={OUT / "roundtrip_gd.json"}', '--grace=120', '--stall=90', '--',
                                  GODOT, '--headless', '--path', str(ROOT), '--xr-mode', 'off', '--script', 'res://tools/probes/stickers_roundtrip.gd', '--',
                                  f'--out={OUT.as_posix()}', f'--web-id={web_id}', f'--data-dir={box.as_posix()}', f'--sandbox={sandbox}', f'--url={URL.rsplit("/api/", 1)[0]}'],
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        t0 = time.time()
        while not (OUT / 'ready.json').exists() and time.time() - t0 < 90:
            time.sleep(0.2)
        if not (OUT / 'ready.json').exists():
            report['error'] = 'the game never became ready'
            return report
        reply = post(sandbox, {'by': 'web:roundtrip', 'ops': [{'op_id': f'op-{web_id}', 'op': 'add', 'sticker': {
            'id': web_id, 'design': 'here_pink_triangle', 'host': {'kind': 'board', 'id': 'visitors'}, 'at': [0.6, 0.3, 0], 'n': [0, 0, 1], 'up': [0, 1, 0], 'size': 0.18, 'by': 'web:roundtrip'}}]})
        report['web_post'] = reply
        t1 = time.time()
        while not (OUT / 'roundtrip_gd.json').exists() and time.time() - t1 < 120:
            time.sleep(0.25)
        gd = json.loads((OUT / 'roundtrip_gd.json').read_text(encoding='utf-8')) if (OUT / 'roundtrip_gd.json').exists() else {}
        report['game'] = gd
        game_id = gd.get('game_id', '')
        on_web = next((s for s in get(sandbox)['placements']['stickers'] if s['id'] == game_id), None) if game_id else None
        report['game_sticker_on_web'] = on_web
        report['ok'] = bool(reply.get('ok')) and int(gd.get('web_to_game_ms', -1)) >= 0 and on_web is not None and on_web.get('by') == 'vr:roundtrip'
        return report
    finally:
        if godot is not None:
            try:
                godot.wait(timeout=180)
            except Exception:
                godot.kill()
        after = truth_md5()
        report['truth_md5_after'] = after
        report['truth_untouched'] = after == before
        if '--keep' not in sys.argv:
            shutil.rmtree(box, ignore_errors=True)
        (OUT / 'report.json').write_text(json.dumps(report, indent=1), encoding='utf-8')


if __name__ == '__main__':
    r = main()
    g = r.get('game', {})
    print('web -> game: %s ms by the file watch; game -> web: reply %s in %s ms, on the web: %s; sandbox %s; truth untouched: %s' % (
        g.get('web_to_game_ms'), (g.get('post_reply') or {}).get('ok'), g.get('game_to_route_ms'), bool(r.get('game_sticker_on_web')), r.get('sandbox'), r.get('truth_untouched')))
    if r.get('error'):
        print('error:', r['error'])
    sys.exit(0 if r.get('ok') and r.get('truth_untouched') else 1)
