from pathlib import Path
from html import escape
from html.parser import HTMLParser
import json
import zipfile

OUT = Path(__file__).resolve().parent
STUDY = OUT.parents[1] / 'studies/glyph-form-atlas'
report = json.loads((OUT / 'verification.json').read_text(encoding='utf-8'))
assert report['passed'] and all(c['passed'] for c in report['checks'])
assert not (OUT / 'native-errors.log').read_text().strip()
files = ['project.godot', 'atlas.tscn', 'atlas.gd', 'profile_sweep.gd',
         'README.md', 'JetBrainsMono-Medium.ttf', 'JetBrainsMono-OFL.txt']
with zipfile.ZipFile(OUT / 'borrowed-outlines.zip', 'w', zipfile.ZIP_DEFLATED) as z:
    for name in files:
        z.write(STUDY / name, 'borrowed-outlines/' + name)
with zipfile.ZipFile(OUT / 'borrowed-outlines.zip') as z:
    assert z.testzip() is None
    for name in files:
        assert z.read('borrowed-outlines/' + name) == (STUDY / name).read_bytes()

specimens = [
    ('O', 'passage', 'An opening becomes large', 'Straight depth',
     'The counter—the empty part of the letter—becomes a space at bodily scale. Its bottom stroke also becomes a sill. A 1.7 m body fits in the raised opening, but meets the rim when placed at floor level.',
     'A hole is not yet a doorway.'),
    ('O', 'vessel', 'The same opening, rising', 'Changing width + a slight turn',
     'Narrow the section, then flare it. The letter becomes a vessel-like body with a throat and a broad rim. Its opening continues through the bottom: this is still an open tube, not a cup.',
     'What would we have to close for it to hold something?'),
    ('B', 'wells', 'Two wells in one body', 'Rise + twist',
     'B gives us two separate channels inside one continuous body. The section turns as it rises. From the side it reads as a twisting wall; from above, the letter returns.',
     'Recognition depends on where we stand.'),
    ('C', 'channel', 'An open channel curls back', 'Follow a curved path',
     'C travels around an arc. Its gap becomes an opening along the side of a curved channel. It begins to suggest a shelter or a seat, though neither use has been tested.',
     'Enclosing space visually does not always make a topological hole.'),
    ('I', 'loop', 'A hole that was not in the letter', 'Close the path',
     'I has no hole. Carry its section around a full circle and join the ends: now the body has one. The top and bottom strokes become circular flanges, with a thinner wall between them.',
     'The path contributes form as well as the profile.'),
    (':', 'two-bodies', 'One character, two bodies', 'Carry both pieces together',
     'The colon supplies two disconnected regions. They bend and turn together, but remain separate. One character, one generator and one mesh resource can still contain two bodies.',
     'Being named together does not mean being joined.'),
]
cards = []
for i, (glyph, name, title, operation, copy, question) in enumerate(specimens):
    cards.append(f'''<article class="card" id="{name}">
    <a href="{name}.png"><img src="{name}.png" loading="lazy" alt="Native Godot study: {escape(title)} from the glyph {escape(glyph)}."></a>
    <div class="card-copy"><div class="operation"><span class="glyph">{escape(glyph)}</span><span>0{i+1} / {operation}</span></div>
    <h3>{title}</h3><p>{copy}</p><p class="question">{question}</p></div></article>''')

page = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Borrowed outlines — Ada form atlas</title><style>
@font-face{font-family:Glyph;src:url('../../studies/glyph-form-atlas/JetBrainsMono-Medium.ttf')}
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#211f29;color:#eee5d9;font:20px/1.65 Georgia,serif}main{max-width:1450px;padding:35px 35px 90px;margin:auto}nav,.meta,figcaption,.operation,.small,summary,footer{font:14px/1.6 system-ui,sans-serif}nav{display:flex;gap:24px;flex-wrap:wrap;border-bottom:1px solid #5b4d5c;padding-bottom:18px}a{color:#f0b8ce;text-underline-offset:5px}header{max-width:850px;margin:65px auto 50px}h1{font-size:clamp(52px,8vw,102px);font-weight:400;line-height:1;letter-spacing:-3px;margin:18px 0 30px}h2{font-size:36px;font-weight:400;line-height:1.15}h3{font-size:29px;font-weight:400;line-height:1.15;margin:20px 0}p{margin:16px 0}.meta,.small,figcaption{color:#c9b8c7}figure{margin:30px 0 55px}img{display:block;width:100%;height:auto}figcaption{padding:12px 0;max-width:950px}.copy{max-width:800px;margin:65px auto}.route{font-size:28px;border-left:2px solid #e1adbf;padding:12px 24px}.cards{display:grid;grid-template-columns:1fr 1fr;gap:32px}.card{background:#302b37;border:1px solid #564652;scroll-margin-top:25px}.card-copy{padding:28px 32px}.operation{display:flex;gap:25px;align-items:center;color:#d4b6c8}.glyph{font:54px/1 Glyph,monospace;min-width:55px;color:#f3d3df}.question{color:#e8bdce;font-style:italic}.button{display:inline-block;padding:13px 23px;background:#efcad6;color:#28232d;font:16px/1.4 system-ui,sans-serif;text-decoration:none}details{border-top:1px solid #645462;padding-top:16px}summary{cursor:pointer;color:#ebc4d6}table{border-collapse:collapse;width:100%;font:15px/1.5 system-ui,sans-serif}td,th{text-align:left;padding:12px 10px;border-bottom:1px solid #594a56}code{font:.85em Consolas,monospace}footer{margin:50px 0;border-top:1px solid #514552;padding-top:25px}a:focus-visible,summary:focus-visible{outline:2px solid #f0b8ce;outline-offset:5px}@media(max-width:850px){.cards{grid-template-columns:1fr}main{padding:22px 18px}.card-copy{padding:24px}h1{letter-spacing:-1px}body{font-size:18px}}@media(prefers-reduced-motion:reduce){html{scroll-behavior:auto}}
</style></head><body><main>
<nav><a href="#forms">Six bodies</a><a href="blog.html">The blog</a><a href="#possibilities">What becomes possible</a><a href="#limits">Where the shortcut ends</a><a href="#open">Open in Godot</a><a href="../2026-10-04-glyphs-as-profiles/index.html">First study</a></nav>
<header><div class="meta">ADA / FORM STUDY / 4 OCTOBER 2026</div><h1>Borrowed<br>outlines</h1><p>A font gives us more than a silhouette. It gives us decisions about the inside, the outside and what remains separate. Here, six bodies put those decisions to another use.</p></header>
<figure><a href="overview.png"><img src="overview.png" alt="Six sculptures in the native Godot gallery, with their source letters beside them: O, O, B, C, I and a colon."></a><figcaption>Six working geometry studies, each with its source profile beside it. Native Godot captures. These remain a separate research gallery.</figcaption></figure>
<section class="copy"><h2>Two things to change</h2><p class="route">The shape we carry.<br>The path along which we carry it.</p><p>A straight path makes depth. Turn the section as it travels and the body twists. Change its width and it narrows or opens. Bend the path and the same section becomes a channel. Join the ends and the path itself can make a new hole.</p><p>The method lets us keep something constant while another decision changes. O returns twice here, first as an upright opening, then as a flared hollow body.</p></section>
<section class="cards" id="forms">CARDS</section>
<section class="copy" id="possibilities"><h2>A small vocabulary, many possible uses</h2><p>The working forms suggest columns and chimneys, open vessels, handles, channels, frames, screens and passages. A symbol font can supply a different starting vocabulary. A hand-drawn contour or a vector drawing could enter the same construction once its region has been triangulated correctly.</p><p><strong>Lines also make form.</strong> Contours can imply a surface; repeated ribs can describe a shell; woven lines can make a screen; a profile carried along a line can become a tube or ribbon. A trace gives movement a shape that remains. The <a href="../2026-10-04-painting-space-second-pass/index.html#line-forms">line-form possibilities</a> connect the working luminous rings and traces to further studies in lattices, straight-line surfaces and branching.</p><p>Three further encounters seem especially useful: cut the sill of O until the opening actually admits a walking body; let B’s two wells meet in one room; carry one profile through the scales of a handle, a column and a shelter. These are proposed next experiments, not completed interactions.</p><p>There is a critical question inside the convenience. The type designer made these proportions for reading. We borrow that work when we make a room. Which of those decisions becomes visible only when someone tries to enter?</p></section>
<section class="copy" id="limits"><h2>Where the shortcut ends</h2><p>Here “compound 2D profile” means a region that may contain holes or separate pieces. Simply making it wider, taller or twisted does not change those connections, provided it does not fold through itself.</p><p>A branch, a merged channel or a closed bottom is a different operation. We need to construct the new connection deliberately. B cannot smoothly become O just by pairing arbitrary points: one of its holes must disappear. Nor does borrowing a font guarantee that every glyph will triangulate successfully.</p>
<details><summary>The measured topology and construction</summary><p>The source is a flat <a href="https://docs.godotengine.org/en/4.6/classes/class_textmesh.html">TextMesh</a>. Godot supplies the face triangulation; our code builds the sweep from its boundary edges. Vector glyphs are required. For direct access to the original outlines, Godot also exposes <a href="https://docs.godotengine.org/en/4.6/classes/class_textserver.html#class-textserver-method-font-get-glyph-contours">glyph contours</a>.</p><table><tr><th>Body</th><th>Components</th><th>Handles in its boundary</th></tr><tr><td>O, straight / flared</td><td>1 each</td><td>1 each</td></tr><tr><td>B, twisted</td><td>1</td><td>2</td></tr><tr><td>C, curved</td><td>1</td><td>0</td></tr><tr><td>I, closed sweep</td><td>1</td><td>1</td></tr><tr><td>Colon, bent</td><td>2</td><td>0</td></tr></table><p class="small">B’s closed boundary is a genus-two surface. This is different from merely having a two-dimensional input. The figures above are checked on the generated geometry. A circular sweep can also be understood as revolving a profile around an axis.</p><p class="small">The generator does not solve arbitrary path framing, self-intersections, remeshing between different topologies or engineering feasibility.</p></details></section>
<section class="copy" id="open"><h2>Move around the forms</h2><a class="button" href="borrowed-outlines.zip" download>Download the Godot study</a><p>Open <code>project.godot</code> in Godot 4.6 and run. Press 1–6 to approach a body, 0 for the gallery. Drag to orbit; scroll to move closer. Hold right mouse and use WASD/QE to fly through the forms.</p><p class="small">Free camera exploration; no collision-based walking or VR placement yet. CHECK_COUNT native checks passed, including the O’s opening and sill. They do not certify general self-intersection freedom or fabrication.</p><p><a href="../../studies/glyph-form-atlas/README.md">Method, limits and next experiments</a> · <a href="../../studies/glyph-form-atlas/profile_sweep.gd">Profile and sweep code</a> · <a href="../../studies/glyph-form-atlas/atlas.gd">The six recipes</a> · <a href="verification.json">Verification</a></p></section>
<footer>Ada research study · JetBrains Mono, license included · Six generated bodies, eight native captures · The book and live museum remain as they were.</footer>
</main></body></html>'''
page = page.replace('CARDS', '\n'.join(cards)).replace('CHECK_COUNT',str(len(report['checks'])))
(OUT / 'index.html').write_text(page,encoding='utf-8')

class Links(HTMLParser):
    def handle_starttag(self, tag, attrs):
        for name, value in attrs:
            if name in ('src', 'href') and value and not value.startswith(('http:', 'https:', '#')):
                assert (OUT / value.split('#')[0]).exists(), value

Links().feed(page)
print(json.dumps({'native_checks':len(report['checks']),'project_files':len(files),'local_links':'verified','zip':'source-equal'}))
