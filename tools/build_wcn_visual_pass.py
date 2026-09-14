"""The visual pass of 12 September 2026: Astra's featured "before" images beside the same views
captured after each room's improvement, one page for the guide.

  python tools/build_wcn_visual_pass.py

Reads doc/research/waves-chance-noise/visual-review-evidence.json (Astra's capture manifest: the
featured images per room, from her isolated run) and the live probe outputs under
ada_run/waves_chance_noise/<Map>/ (the same probes, rerun after the edits), pairs them by
filename, copies the after-images as JPEGs into doc/research/waves-chance-noise/images/ and
writes doc/research/waves-chance-noise/visual-pass.html. A room with no fresh capture is shown
with its before-images and a note. The page is one half of the handback; the other is
doc/book/handoffs/fable-wcn-visual-pass-2026-09-12.md.
"""
import json, sys, html
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / 'tools'))
from evidence_root import evidence_dir  # noqa: E402
GUIDE = ROOT / 'doc/research/waves-chance-noise'
IMAGES = GUIDE / 'images'
RUNS = ROOT / 'ada_run/waves_chance_noise'
WIDTH = 960

# (map, probe stem, the change in one line, the views to pair — '' for the primary — and any extra
#  after-only views the improvement added)
ROOMS = [
    ('WaveFunctions_Intro', 'probe_intro', 'A dark slate behind the swing plane and a cased, enlarged state readout beside the pivot (reference:plumb only).',
     ['_desktop_primary', ''], []),
    ('WaveFunctions_Pendulum', 'probe_pendulum', 'The sampler panel turned to the east walkway; a darker trail on a matte runner; the primary frame from a real standing spot; the two holes floored.',
     ['', '_readout', '_desktop_walk'], ['_controls']),
    ('WaveFunctions_Sine_Space', 'probe_sine_space', 'The readout reflowed into four lines inside a taller plate; the passage\'s two thresholds marked on the floor.',
     ['_approach', '_desktop_mid', '_panel'], []),
    ('WaveFunctions_Effect_Sound', 'probe_effect_sound', 'The readout and the AUDITION panel low in front of the desks, below the hand space; the scope lowered to sit with the balls; the sculptor\'s listener check hardened.',
     ['_desktop_front', '_overview', '', '_readout', '_scope'], ['_desktop_operating']),
    ('WaveFunctions_AirMusic', 'probe_air_music', 'The striker\'s cradle at the table\'s left end, front to back, leaving the bars free; a pale rail on the playable edge and a dark kerb at the back; the shutdown crash fixed at its source.',
     ['_desktop_front', '_two_voices', '', '_readout'], []),
    ('WaveFunctions_Synthesis_Lab', 'probe_synthesis_lab', 'The hallway hero fitted to its synthesis stand (a sixty-metre tunnel had filled the hall); the coloredlines ornament that dressed the visitor\'s camera in fog removed; the corridor rect that protected nothing corrected; the shutdown crash fixed at its source.',
     ['_desktop_front', '_console', '', '_overview', '_plan'], []),
    ('Random_Definition', 'probe_random_definition', 'The panel enlarged for its labels; a cased action line at its foot naming the last action, the seed and whether the grids agree.',
     ['_desktop_close', '_desktop_approach', ''], []),
    ('Random_Entropy', 'probe_entropy', 'The first forty draws magnified four times on the desk\'s front, as drawn and staying while the ribbon sorts, labelled as the excerpt it is.',
     ['_approach', '_panel_close', '_desktop_front', ''], []),
    ('Random_Remove', 'probe_remove', 'The control panel off the tray to its right, turned to the visitor; the status and legend cased on a post at the tray\'s left.',
     ['_desktop_front', '_one', '', '_status', '_panel'], []),
    ('Random_Walk', 'probe_walk', 'A dark backboard behind the tank; the followed bead twice the size of the dimmed ones; the bare-instance RESET check hardened.',
     ['_tank', '', '_running', '_desktop_front'], []),
    ('Random_Gaussian', 'probe_gaussian', 'A headline over the six lines (the law, N, bins, the clipped count and the edge bins) at a readable size; the shipped side plate off under the cabinet.',
     ['_desktop_front', '_readout', ''], []),
    ('Random_Mushrooms', 'probe_mushrooms', 'The disc numbers readable; a ring on the shown specimen\'s disc in the highlight\'s colour; saturated highlights and larger pins in the bed.',
     ['', '_specimens', '_bed', '_north_door', '_south_door'], ['_edibles', '_eaten']),
]


def load(p: Path):
    return json.loads(p.read_text(encoding='utf-8-sig')) if p.exists() else None


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


def main() -> int:
    evidence = load(GUIDE / 'visual-review-evidence.json') or []
    before_by_map = {}
    for r in evidence:
        before_by_map[r['map']] = {Path(i['source']).name: i['file'] for i in r.get('images', [])}
    parts = []
    summary = []
    for name, stem, change, views, extra in ROOMS:
        rep = load(RUNS / name / f'{stem}_live.json')
        status = 'no fresh run'
        if rep is not None:
            status = f"{rep.get('checks')} checks · {len(rep.get('failures', []))} failures"
        befores = before_by_map.get(name, {})
        rows = []
        for v in views + extra:
            # PNGs are in the evidence root since 2026-09-14; older runs left them beside the JSON
            after_png = evidence_dir('waves_chance_noise', name, create=False) / f'{stem}{v}_live.png'
            if not after_png.exists():
                after_png = RUNS / name / f'{stem}{v}_live.png'
            before_rel = befores.get(f'{stem}{v}_live.png')
            after_rel = None
            if after_png.exists():
                out = IMAGES / f'after-{name}-{stem}{v}_live.jpg'
                if to_jpeg(after_png, out):
                    after_rel = f'images/{out.name}'
            if before_rel is None and after_rel is None:
                continue
            label = 'the primary, from the visitor\'s spot' if v == '' else v.strip('_').replace('_', ' ')
            rows.append((label, before_rel, after_rel, v in extra))
        summary.append((name, status, len([r for r in rows if r[1] and r[2]])))
        cells = []
        for label, b, a, is_extra in rows:
            bimg = f'<figure><img loading="lazy" src="{b}" alt="before: {html.escape(label)}"><figcaption>before — Astra\'s capture</figcaption></figure>' if b else '<figure class="empty"><div>no before image (a view the improvement added)</div></figure>'
            aimg = f'<figure><img loading="lazy" src="{a}" alt="after: {html.escape(label)}"><figcaption>after — this pass</figcaption></figure>' if a else '<figure class="empty"><div>no fresh capture</div></figure>'
            cells.append(f'<div class="pair"><h4>{html.escape(label)}</h4>{bimg}{aimg}</div>')
        parts.append(f'<section class="room" id="{name}"><h2>{name} <span class="status">{html.escape(status)}</span></h2><p class="change">{html.escape(change)}</p>{"".join(cells)}</section>')
    head = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Waves / Randomness / Noise — the visual pass of 12 September 2026</title>
<style>body{font:15px/1.45 system-ui,sans-serif;margin:0;background:#f4f3ef;color:#222}main{max-width:1180px;margin:0 auto;padding:24px}
h1{font-size:22px}h2{font-size:18px;margin:36px 0 6px;border-top:1px solid #ccc;padding-top:18px}.status{font-weight:normal;color:#666;font-size:14px;margin-left:8px}
.change{margin:0 0 12px;max-width:900px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin:8px 0 18px}.pair h4{grid-column:1/3;margin:6px 0 0;font-size:14px;color:#444}
figure{margin:0}img{width:100%;height:auto;border:1px solid #ccc;background:#fff}figcaption{font-size:12px;color:#666;margin-top:3px}
.empty{border:1px dashed #bbb;min-height:120px;display:flex;align-items:center;justify-content:center;color:#888;font-size:13px}
table{border-collapse:collapse;font-size:14px}td,th{border:1px solid #ccc;padding:4px 8px;text-align:left}</style></head><body><main>
<h1>The visual pass of 12 September 2026 — before and after, room by room</h1>
<p>Left: Astra's featured captures from the isolated serial pass (visual-review.html). Right: the same probe views after each room's improvement, from the live lane (the desktop rig pressing the controls). Each room's line says what changed; the handback in <code>doc/book/handoffs/fable-wcn-visual-pass-2026-09-12.md</code> says what was checked and what remains.</p>'''
    tbl = '<table><tr><th>room</th><th>fresh run</th><th>pairs</th></tr>' + ''.join(f'<tr><td><a href="#{n}">{n}</a></td><td>{html.escape(s)}</td><td>{c}</td></tr>' for n, s, c in summary) + '</table>'
    (GUIDE / 'visual-pass.html').write_text(head + tbl + ''.join(parts) + '</main></body></html>', encoding='utf-8')
    print(json.dumps({'rooms': len(ROOMS), 'paired': sum(c for _, _, c in summary), 'page': 'doc/research/waves-chance-noise/visual-pass.html'}))
    return 0


if __name__ == '__main__':
    sys.exit(main())
