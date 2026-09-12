"""The programme's runtime captures, on one page of the guide — the way Astra's review pages
carry images, so Palle can look at what the probes photographed without opening ada_run.

  python tools/build_wcn_captures_page.py

For each hall listed in HALLS: reads ada_run/waves_chance_noise/<Map>/<stem>.json and
<stem>_live.json (checks, failures, the captures' camera poses), copies the PNGs the probe
saved — the live lane's when present, the bare lane's otherwise — into
doc/research/waves-chance-noise/images/ as JPEGs at 960 px (a 1 MB PNG becomes ~120 KB), and
writes doc/research/waves-chance-noise/runtime-captures.html: one section per hall, the
question, the two lanes' counts, a figure per view with its camera's standpoint. Never
edits plan.json or the index; the page is linked from the halls' handbacks and this docstring.
Run the guide copy afterwards (cp -r doc/research/waves-chance-noise/. ../ada_encyclopedia/
public/research/waves-chance-noise/).
"""
import html
import io
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RUNS = ROOT / 'ada_run' / 'waves_chance_noise'
GUIDE = ROOT / 'doc' / 'research' / 'waves-chance-noise'
IMAGES = GUIDE / 'images'
WIDTH = 960

# (map, probe stem, batch, question, the views in the order they are read; a view is the
#  suffix after the stem, '' for the primary)
HALLS = [
    ('WaveFunctions_Synthesis_Lab', 'probe_synthesis_lab', 'W4', 'What shape can several simple returns make together?',
     ['', '_console', '_readout', '_hold', '_overview', '_desktop_front']),
    ('Random_Entropy', 'probe_entropy', 'R1', 'Which differences disappear when a sequence becomes one number?',
     ['', '_approach', '_panel_close', '_buttons', '_origin_contrast', '_desktop_front']),
    ('Random_Remove', 'probe_remove', 'R1b', 'Who was eligible to disappear?',
     ['', '_one', '_emptied', '_row', '_status', '_panel', '_board', '_overview', '_desktop_front']),
    ('Random_Walk', 'probe_walk', 'R2', 'What does a trail remember that the next step does not use?',
     ['', '_running', '_tank', '_logbook', '_keypad', '_north_door', '_arena', '_plan', '_desktop_front']),
    ('Random_Gaussian', 'probe_gaussian', 'R3', 'What can many draws reveal that one draw cannot?',
     ['', '_uniform', '_poisson', '_running', '_display', '_readout', '_keypad', '_north_door', '_south_door', '_arena', '_plan', '_desktop_front']),
    ('Random_Mushrooms', 'probe_mushrooms', 'R4', 'Which parts of this population were allowed to vary?',
     ['', '_readout', '_specimens', '_panel', '_bed', '_rejected', '_edibles', '_eaten', '_north_door', '_south_door', '_west_margin', '_plan', '_desktop_front']),
    ('Random_Game', 'probe_game', 'R5', 'How can you plan when the next state is known but its timing is not?',
     ['', '_approach', '_tablet', '_stele', '_row', '_bed', '_idol', '_desktop_crossing', '_desktop_fallen', '_plan']),
]

VIEW_NAMES = {'': 'the primary, from the visitor\'s spot', '_desktop_front': 'the desktop rig\'s own camera, live lane'}


def load(p: Path):
    if not p.exists():
        return None
    return json.loads(p.read_text(encoding='utf-8-sig'))


def to_jpeg(src: Path, dst: Path) -> bool:
    try:
        from PIL import Image
    except ImportError:
        return False
    im = Image.open(src).convert('RGB')
    if im.width > WIDTH:
        im = im.resize((WIDTH, int(im.height * WIDTH / im.width)), Image.LANCZOS)
    im.save(dst, 'JPEG', quality=84, optimize=True)
    return True


def pose_text(pose) -> str:
    if not isinstance(pose, dict):
        return ''
    at = pose.get('at') or pose.get('eye') or []
    fwd = pose.get('forward') or []
    who = 'the probe\'s camera' if pose.get('is_ours') else pose.get('current_camera', '')
    if 'eye' in pose:
        who = 'the rig\'s camera'
    try:
        return 'standpoint (%.1f, %.1f, %.1f), looking (%.2f, %.2f, %.2f) — %s' % (*at, *fwd, who)
    except Exception:
        return who


def main() -> int:
    IMAGES.mkdir(exist_ok=True)
    sections = []
    total = 0
    for name, stem, batch, question, views in HALLS:
        d = RUNS / name
        bare = load(d / f'{stem}.json')
        live = load(d / f'{stem}_live.json')
        if bare is None and live is None:
            continue
        figs = []
        for v in views:
            src_live = d / f'{stem}{v}_live.png'
            src_bare = d / f'{stem}{v}.png'
            src = src_live if src_live.exists() else (src_bare if src_bare.exists() else None)
            if src is None:
                continue
            lane = 'live' if src == src_live else 'bare'
            out = IMAGES / f'{name}{v or "_primary"}.jpg'
            if not to_jpeg(src, out):
                out = IMAGES / f'{name}{v or "_primary"}.png'
                out.write_bytes(src.read_bytes())
            rec = (live if lane == 'live' else bare) or {}
            caps = (rec.get('measurements') or {}).get('captures') or {}
            key = v.lstrip('_') or 'primary'
            pose = caps.get(key)
            if v == '_desktop_front':
                pose = ((rec.get('measurements') or {}).get('desktop_input') or {}).get('front_capture_pose')
            label = VIEW_NAMES.get(v, key.replace('_', ' '))
            figs.append('<figure><img src="images/%s" alt="%s: %s" loading="lazy"><figcaption><b>%s</b> · %s lane · %s</figcaption></figure>'
                        % (out.name, html.escape(name), html.escape(label), html.escape(label), lane, html.escape(pose_text(pose))))
            total += 1
        counts = []
        for lane, rec in (('bare', bare), ('live', live)):
            if rec:
                counts.append('%s %d checks / %d failures' % (lane, rec.get('checks', 0), len(rec.get('failures', []))))
        sections.append('<section id="%s"><h2>%s <span class="badge">%s</span></h2><p class="q">%s</p><p class="muted">%s · %s</p><div class="grid">%s</div></section>'
                        % (name, name, batch, html.escape(question), ' · '.join(counts), html.escape((bare or live or {}).get('control_path', ''))[:400], ''.join(figs)))
    page = ('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
            '<title>Runtime captures · Waves, Randomness and Noise · Ada Research</title><style>'
            'body{font:16px/1.5 system-ui,sans-serif;max-width:1100px;margin:2rem auto;padding:0 1rem;color:#1a1a1a;background:#fafafa}'
            'h1{font-size:1.6rem}h2{font-size:1.2rem;margin-top:2.5rem}.badge{font-size:.75rem;background:#e8e4d8;border-radius:.4rem;padding:.1rem .4rem;vertical-align:middle}'
            '.q{font-style:italic}.muted{color:#666;font-size:.9rem}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(440px,1fr));gap:1rem}'
            'figure{margin:0}img{width:100%;height:auto;border:1px solid #ddd;border-radius:.3rem}figcaption{font-size:.85rem;color:#444;margin-top:.3rem}'
            'a{color:#2a5d8f}</style></head><body><h1>Runtime captures</h1>'
            '<p>What the museum probes photographed, hall by hall, in the order the route meets them. Every picture is a runtime capture by the probe\'s own camera or the desktop rig\'s, taken during a saved run whose JSON sits beside it under <code>ada_run/waves_chance_noise/</code>; none is edited. The live lane runs under project startup with the desktop rig pressing panels through its pointer; the bare lane is the SceneTree probe. <a href="index.html">Back to the plan</a> · <a href="all-maps.html">All maps</a>.</p>'
            + ''.join(sections) + '</body></html>')
    (GUIDE / 'runtime-captures.html').write_text(page, encoding='utf-8')
    print(json.dumps({'halls': len(sections), 'images': total, 'page': 'doc/research/waves-chance-noise/runtime-captures.html'}))
    return 0


if __name__ == '__main__':
    sys.exit(main())
