"""Build the comparison from native museum photographs and recorded checks."""
from pathlib import Path
import difflib
import hashlib
import html
import json

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-06-colour-rooms-from-the-plates'
ROOMS = [
    ('Color_Context_Placed', 'The same parts', 'context',
     'Twenty-three existing stacks now sit on low pale plinths. Their plaques use a quiet stone background. The long room gains wall columns and a neutral floor, so the different arrangements carry the colour.'),
    ('Color_Flashlight', 'Light reaches a surface', 'flashlight',
     'The beam experiment gains pale walls and a quieter floor. The four lamps, coarse sphere, white-light room and aperture studies remain. No extra gallery lights were added here: the coloured sources need to remain legible.'),
    ('Color_Nails', 'Colour reaches a hand', 'nails',
     'A simple pale plinth supports the manicure display. The two selector stands and their labels are quieter. The small and giant hands still receive the same nail-colour changes.'),
    ('Color_Rainbow', 'A room for celebration', 'rainbow',
     'White wall columns frame the existing arch, low steps, mushrooms, banners and pickup path. The celebratory colour now sits against a calm architectural background.'),
    ('Color_Pillar', 'A colour between floor and ceiling', 'pillar',
     'The pillar bases are pale and their address labels are smaller. The dark floor, thirty-five samples and matching colour ceiling remain. No fill light was added over the fog-like field.'),
    ('Color_Grid_Pallet', 'A colour kept in place', 'grid',
     'The editable floor keeps its real per-cell colours, with fine joints in place of the triangular wire overlay. The console gains a pale base. The huge spectrum forest becomes a smaller side study, opening the view across the floor.'),
    ('Color_Paint', 'A mark left on a surface', 'paint',
     'A plain white frame and solid pale cabinet gather the canvas and thirty spray cans. The existing wet surface and automatic painter remain active. The photograph catches a real aerosol mark forming on the canvas.'),
    ('Color_Walls', 'Colour becomes a room', 'walls',
     'Neutral walls and floor let the twelve translucent partitions read more clearly against their surroundings. The furniture, gaps, pane positions and collision remain. The opacity control still changes the panes together.'),
]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    reports = {m: json.loads((OUT / 'after' / m / 'report.json').read_text(encoding='utf-8')) for m, *_ in ROOMS}
    checks = [c for r in reports.values() for c in r['checks']]
    assert all(c['passed'] for c in checks), 'Do not publish a passing report with failed checks'
    total = len(checks)
    sections = []
    notes = ['# Colour rooms from the drawings', '', '6 October 2026. Actual Endless Museum changes and native visitor-height captures.', '']
    for i, (room, title, plate, prose) in enumerate(ROOMS, 1):
        for phase in ['before', 'after']:
            assert (OUT / phase / room / 'room.png').is_file()
        source = f'../2026-10-06-final-comic-plates/colour-{plate}.png'
        assert (OUT / source).is_file()
        before_caption = 'Before · earlier approach view' if room in ['Color_Paint','Color_Walls'] else 'Before · same visitor viewpoint'
        sections.append(f'''<section id="{room}">
<div class="room-head"><span class="number">{i:02}</span><div><h2>{html.escape(title)}</h2><p class="map">{room}</p></div></div>
<p class="description">{html.escape(prose)}</p>
<div class="comparison"><figure class="before"><a href="before/{room}/room.png"><img loading="lazy" src="before/{room}/room.png" alt="{title}: before, inside the museum"></a><figcaption>{before_caption}</figcaption></figure>
<figure class="after"><a href="after/{room}/room.png"><img loading="lazy" src="after/{room}/room.png" alt="{title}: updated hall, inside the museum"></a><figcaption>After · native Godot capture</figcaption></figure></div>
<p class="links"><a href="{source}">Comic reference ↗</a><a href="after/{room}/report.json">{len(reports[room]['checks'])} checks passed ↗</a><a href="after/{room}/room.png">Open full photograph ↗</a></p></section>''')
        notes += [f'## {i}. {room}', '', prose, '', f'Checks: {len(reports[room]["checks"])} passed. [After](after/{room}/room.png) · [Before](before/{room}/room.png).', '']

    evidence = f'''{total} native checks passed across eight installed halls: retained grid instances, one-time installation, perimeter placement of architectural collision, supported and unobstructed photograph positions, plus focused checks of the existing colour receivers. These are desktop runtime checks; headset comfort and controller use still need a VR walk.'''
    limits = 'The images use Godot 4.6 Compatibility on the RTX 3070, at 1.7 m above the floor. They load the actual museum and installed artifacts through an isolated runner. Moon phase is fixed for comparison; the after photographs hide the desktop HUD. Paint’s after camera moves 0.7 m nearer the canvas to clear a wall collider; Walls moves 1 m back from its console. The other viewpoints match. Dynamic marks and animations can differ between photographs. Existing shadow banding remains visible on some surfaces. The renderer does not reproduce the comics’ illustrated lighting exactly.'
    notes += ['## Verification', '', evidence, '', limits, '', 'Existing boot UID, Rainbow viewport-texture and cleanup messages are retained in stdout.log; they also occur before this pass. No new script or shader compilation errors were observed. Tutorial manuscripts and final.md were not edited in this architectural pass.', '', '## Reproduce', '', '`python -X utf8 tools/colour_gallery_review.py after`', '', '`python -X utf8 tools/build_colour_gallery_review.py`', '', 'Reload a Colour hall in the museum to see its new finish. The gallery_finish map flag opts in only these eight halls.', '']
    (OUT / 'REPORT.md').write_text('\n'.join(notes), encoding='utf-8')
    nav = ''.join(f'<a href="#{m}">{i:02} {html.escape(t)}</a>' for i, (m,t,*_) in enumerate(ROOMS,1))
    page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Colour — rooms from the drawings</title>
<style>*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:110px}.mode{position:absolute;width:1px;height:1px;overflow:hidden;clip-path:inset(50%)}body{margin:0;background:#f4f1e9;color:#242426;font:16px/1.6 system-ui,sans-serif}header,main,footer{max-width:1440px;margin:auto;padding:40px 4vw}header{padding-bottom:20px}.eyebrow,.map{font-size:12px;letter-spacing:.13em;text-transform:uppercase}h1{font:clamp(38px,6vw,80px)/1.05 Georgia,serif;max-width:950px;margin:24px 0}header>p{max-width:800px;font-size:19px}a{color:inherit;text-underline-offset:4px}nav{display:flex;gap:8px;flex-wrap:wrap;margin-top:28px}nav a{font-size:12px;text-decoration:none;border:1px solid #c9c3b8;padding:7px 10px}.toolbar{position:sticky;top:0;z-index:3;display:flex;align-items:center;gap:10px;padding:12px 4vw;background:#f4f1e9f5;border-block:1px solid #c9c3b8;flex-wrap:wrap}.toolbar span{font-size:13px;margin-right:auto}.toolbar label{border:1px solid #9e9991;background:transparent;padding:9px 17px;cursor:pointer;color:inherit;font:inherit;font-size:14px}#mode-after:checked~.toolbar label[for=mode-after],#mode-before:checked~.toolbar label[for=mode-before],#mode-beside:checked~.toolbar label[for=mode-beside]{background:#242426;color:#fff}section{margin-bottom:70px;padding-top:14px}.room-head{display:flex;gap:22px;align-items:baseline}.number{font-size:14px;color:#936575}h2{font:clamp(27px,4vw,43px)/1.2 Georgia,serif;margin:0}.map{margin:8px 0;color:#6c6862}.description{max-width:880px;margin:14px 0 25px}.comparison{display:grid;gap:18px}figure{margin:0}img{width:100%;height:auto;display:block;background:#ddd;aspect-ratio:1.6}figcaption{font-size:12px;padding:8px 0;color:#6c6862}.before{display:none}#mode-before:checked~main .before{display:block}#mode-before:checked~main .after{display:none}#mode-beside:checked~main .comparison{grid-template-columns:1fr 1fr}#mode-beside:checked~main .before{display:block}.links{display:flex;gap:24px;flex-wrap:wrap;font-size:13px;margin:10px 0}.evidence{border-top:1px solid #c9c3b8;padding-top:28px;max-width:850px}footer{padding-top:0;color:#6c6862;font-size:13px}.mode:focus-visible~.toolbar,a:focus-visible{outline:3px solid #b95a85;outline-offset:3px}@media(max-width:700px){#mode-beside:checked~main .comparison{grid-template-columns:1fr}header,main,footer{padding-inline:20px}.toolbar{padding-inline:20px}.toolbar span{width:100%}.links{gap:12px}section{margin-bottom:45px}}@media print{.toolbar,nav{display:none}section{break-inside:avoid}body{background:white}}</style>
<body><input class="mode" type="radio" name="view" id="mode-after" checked><input class="mode" type="radio" name="view" id="mode-before"><input class="mode" type="radio" name="view" id="mode-beside"><header><div class="eyebrow">Endless Museum · Colour · 6 October 2026</div><h1>Rooms from the drawings</h1><p>Pale walls, simple plinths and clearer displays across the eight existing Colour halls. The colour experiments now have more room to be seen.</p><p>These photographs are taken inside the running museum, at standing eye height.</p><nav>''' + nav + '''</nav></header>
<div class="toolbar" role="group" aria-label="Comparison view"><span>Compare the rooms · click any photograph to enlarge</span><label for="mode-after">After</label><label for="mode-before">Before</label><label for="mode-beside">Side by side</label></div><main>''' + ''.join(sections) + f'''<div class="evidence"><h2>What was checked</h2><p>{evidence}</p><p>{limits}</p><p>The tutorial and reflective manuscripts remain separate from this architectural pass. <a href="REPORT.md">Read the change report</a> · <a href="evidence.json">Evidence and source hashes</a>.</p></div></main><footer>Reload a Colour hall to see the new finish. Always another room.</footer>
</body></html>'''
    (OUT / 'index.html').write_text(page, encoding='utf-8')

    sources = ['commons/scenes/endless_museum.gd', 'commons/scenes/em/em_colour_gallery.gd', 'commons/scenes/em/colour_gallery.gdshader', 'commons/scenes/em/em_identity.gd', 'tools/run_encounter_probe.py', 'tools/probes/colour_gallery.gd', 'tools/colour_gallery_review.py', 'tools/build_colour_gallery_review.py']
    sources += [f'commons/maps/{m}/map_data.json' for m,*_ in ROOMS]
    diff = []
    for relative in sources:
        current = ROOT / relative
        previous = OUT / 'before-source' / relative
        if relative.endswith('/em_identity.gd'):
            previous = OUT / 'before-source/em_identity.gd'
        if previous.exists():
            diff += difflib.unified_diff(previous.read_text(encoding='utf-8').splitlines(True), current.read_text(encoding='utf-8').splitlines(True), fromfile='before/'+relative, tofile='after/'+relative)
    (OUT / 'changes.diff').write_text(''.join(diff), encoding='utf-8')
    manifest = {'checks_passed': total, 'halls': len(ROOMS), 'capture': 'Actual isolated Endless Museum runtime; Godot 4.6 Compatibility; 1.7 m visitor eye; fixed moon phase; no headset claim', 'sources': {p:digest(ROOT/p) for p in sources}, 'reports': {m:digest(OUT/'after'/m/'report.json') for m,*_ in ROOMS}, 'images': {f'{phase}/{m}/room.png':digest(OUT/phase/m/'room.png') for m,*_ in ROOMS for phase in ['before','after']}}
    (OUT / 'evidence.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
    print(f'Published {len(ROOMS)} comparisons; {total} passing checks')


if __name__ == '__main__':
    main()
