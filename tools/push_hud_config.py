"""Send the viewfinder's numbers to a running game. No build, no restart.

    python tools/push_hud_config.py my_hud.json            to the Quest on the cable
    python tools/push_hud_config.py --set vr.frame_width_m=2.6 --set vr.sung_line_at=0.7
    python tools/push_hud_config.py my_hud.json --desktop  to the game running on this PC
    python tools/push_hud_config.py --show                 what the game last used
    python tools/push_hud_config.py --reset                take the sent file away: back to the game's own

The file has the shape of commons/void/hud_config.json and need hold only the keys to change. --set changes
keys of the file last sent (kept beside the game as ada_run/hud_config_sent.json), so values add up from
one try to the next. The game (commons/void/hud_config.gd) looks twice a second, sets the viewfinder at
once and writes back what it used; this tool waits for that and prints it. The game must be a build made
after commons/void/hud_config.gd existed (16 Nov 2026, evening); an older build ignores the file.
"""
import argparse, json, os, subprocess, sys, tempfile, time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADB = r'C:/Users/palle/AppData/Local/Android/Sdk/platform-tools/adb.exe'
PACKAGE = 'com.example.adaresearchzeroone'
KEPT = ROOT / 'ada_run' / 'hud_config_sent.json'
DESKTOP = Path(os.path.expandvars(r'%APPDATA%/Godot/app_userdata/Ada Research Zero One'))


def adb(*args, text=True):
    return subprocess.run([ADB, *args], capture_output=True, text=text, encoding='utf-8' if text else None, errors='replace' if text else None)


def quest_read(name):
    r = adb('shell', 'run-as', PACKAGE, 'cat', 'files/' + name)
    return r.stdout if r.returncode == 0 else ''


def read_applied(desktop):
    if desktop:
        p = DESKTOP / 'hud_config_applied.json'
        return p.read_text(encoding='utf-8') if p.exists() else ''
    return quest_read('hud_config_applied.json')


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('file', nargs='?', type=Path)
    ap.add_argument('--set', action='append', default=[], metavar='section.key=number')
    ap.add_argument('--desktop', action='store_true')
    ap.add_argument('--show', action='store_true')
    ap.add_argument('--reset', action='store_true')
    args = ap.parse_args()
    sys.stdout.reconfigure(encoding='utf-8')
    if not args.desktop:
        devices = [l for l in adb('devices').stdout.splitlines()[1:] if l.strip().endswith('device')]
        if not devices:
            print('No Quest on the cable (adb devices shows none). Use --desktop for the game on this PC.')
            return 2
    if args.show:
        print(read_applied(args.desktop) or 'The game has written nothing yet (is it running, and is it a build with the reader?).')
        return 0
    before = read_applied(args.desktop)
    if args.reset:
        if args.desktop: (DESKTOP / 'hud_config.json').unlink(missing_ok=True)
        else: adb('shell', 'run-as', PACKAGE, 'rm', '-f', 'files/hud_config.json')
        KEPT.unlink(missing_ok=True)
        print('The sent file is taken away.')
    else:
        config = {}
        if args.file is not None:
            config = json.loads(args.file.read_text(encoding='utf-8'))
        elif KEPT.exists():
            config = json.loads(KEPT.read_text(encoding='utf-8'))
        if not isinstance(config, dict):
            print('The file must hold a JSON object like commons/void/hud_config.json.')
            return 2
        for item in args.set:
            path, _, value = item.partition('=')
            section, _, key = path.partition('.')
            if not key or not value:
                print('--set wants section.key=number, e.g. vr.frame_width_m=2.6; got', item)
                return 2
            config.setdefault(section, {})[key] = float(value)
        if args.file is None and not args.set:
            print('Nothing to send: give a file or --set section.key=number.')
            return 2
        config.pop('note', None)
        text = json.dumps(config, indent=2) + '\n'
        KEPT.parent.mkdir(parents=True, exist_ok=True)
        KEPT.write_text(text, encoding='utf-8')
        if args.desktop:
            DESKTOP.mkdir(parents=True, exist_ok=True)
            (DESKTOP / 'hud_config.json').write_text(text, encoding='utf-8')
        else:
            with tempfile.TemporaryDirectory() as d:
                local = Path(d) / 'hud_config.json'
                local.write_text(text, encoding='utf-8')
                r = adb('push', str(local), '/data/local/tmp/hud_config.json')
                if r.returncode != 0:
                    print('adb push failed:', r.stderr.strip())
                    return 1
            r = adb('shell', 'run-as', PACKAGE, 'cp', '/data/local/tmp/hud_config.json', 'files/hud_config.json')
            if r.returncode != 0:
                print('Could not write into the game on the Quest:', (r.stderr or r.stdout).strip())
                return 1
        print('Sent:', json.dumps(config))
    # the game writes back what it used
    for _ in range(16):
        time.sleep(0.25)
        after = read_applied(args.desktop)
        if after and after != before:
            report = json.loads(after)
            if report.get('applied'):
                print('The game took it:', json.dumps(report.get('values')))
                return 0
            print('The game REFUSED it:', report.get('problem'))
            return 1
    print('No answer from the game within 4 s. It takes effect when the game next runs, if that build has the reader; --show reads what it last used.')
    return 3


if __name__ == '__main__':
    sys.exit(main())
