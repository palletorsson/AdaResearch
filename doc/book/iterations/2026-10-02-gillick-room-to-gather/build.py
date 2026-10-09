"""Publish the separate reading/making registers and a script-free native comparison."""
from pathlib import Path
from html import escape
import json
import markdown

HERE = Path(__file__).resolve().parent
layouts = [('canopy', 'Canopy'), ('screens', 'Screens'), ('gathering', 'Gathering')]
colours = [('alternating', 'Alternating'), ('bands', 'Groups of three'), ('one-colour', 'One colour')]
def rendered(name):
    return markdown.markdown((HERE / name).read_text(encoding='utf-8'), extensions=['fenced_code', 'tables']).replace('<h1>', '<h2>').replace('</h1>', '</h2>')

rules = []
states = []
for i, (layout, label) in enumerate(layouts):
    for j, (colour, colour_label) in enumerate(colours):
        rules.append(f'.comparison:has(#layout-{i}:checked):has(#colour-{j}:checked) .state-{i}-{j}'+'{display:block}')
        states.append(f'<figure class="state state-{i}-{j}"><img src="figures/{layout}-{colour}.png" width="1800" height="1200" alt="{escape(label)} arrangement of the same twelve panels, with {escape(colour_label.lower())} colour assignment"><figcaption>{label} · {colour_label}. Same panels, camera, room and lights.</figcaption></figure>')

def controls(group, values):
    return '<fieldset><legend>'+('Arrangement' if group == 'layout' else 'Colour rule')+'</legend>'+''.join(
        f'<label><input type="radio" id="{group}-{i}" name="{group}" value="{i}" '+('checked' if i == 0 else '')+f'> {escape(label)}</label>' for i, (_, label) in enumerate(values))+'</fieldset>'

report = json.loads((HERE / 'figures/verification.json').read_text(encoding='utf-8'))
behaviours = sum(not c['check'].startswith('saved ') for c in report['checks'])
captures = len(report['checks']) - behaviours
assert all(c['pass'] for c in report['checks'])
html = '''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Room to gather · Ada / Gillick</title><style>
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#efede7;color:#24292f;font:18px/1.65 system-ui,sans-serif}
header,main,footer{max-width:1250px;margin:auto;padding:30px}header{padding-top:70px}.eyebrow{font:12px/1.4 system-ui;letter-spacing:.17em;text-transform:uppercase;color:#825169}
h1,h2,h3{font-family:Georgia,serif;font-weight:400;line-height:1.15}h1{font-size:clamp(48px,8vw,96px);margin:20px 0 24px}h2{font-size:40px;margin-top:0}h3{font-size:28px}
.lead{font:28px/1.5 Georgia,serif;max-width:850px}.small,figcaption{font:14px/1.55 system-ui;color:#575d61}a{color:#86355c;text-underline-offset:4px}nav{display:flex;flex-wrap:wrap;gap:24px}
section{padding:48px 0;border-top:1px solid #c9c5bf;scroll-margin-top:20px}figure{margin:0 0 24px}img{display:block;width:100%;height:auto}figcaption{padding-top:10px}.state{display:none}
fieldset{border:0;padding:10px 0 20px;margin:0;display:flex;flex-wrap:wrap;gap:10px}legend{font-size:13px;text-transform:uppercase;letter-spacing:.10em}label{cursor:pointer;padding:8px 16px;background:#e2ded8;border:1px solid transparent;border-radius:3px}label:has(input:checked){border-color:#87375d;background:#f2dae5}input{accent-color:#87375d}label:has(input:focus-visible){outline:2px solid #224c9a;outline-offset:2px}
article{max-width:750px;margin:auto;font:24px/1.75 Georgia,serif}article h2{font-size:44px}article hr{border:0;border-top:1px solid #c9c5bf;margin:38px 0}article hr+p{font:15px/1.6 system-ui}
.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}.making{max-width:860px;margin:auto}.making p{max-width:760px}pre{padding:24px;background:#252b32;color:#f2e9ee;overflow-x:auto;font:15px/1.6 Consolas,monospace}code{font-size:.9em}table{width:100%;border-collapse:collapse}td,th{padding:12px;text-align:left;border-bottom:1px solid #c9c5bf;vertical-align:top}details{border:1px solid #c9c5bf;padding:22px}summary{cursor:pointer}footer{font-size:14px;border-top:1px solid #c9c5bf}.pill{display:inline-block;background:#252b32;color:#f9eff4;padding:11px 20px;border-radius:3px;text-decoration:none}
@media(max-width:700px){header,main,footer{padding:22px}header{padding-top:40px}.pair{grid-template-columns:1fr}article{font-size:21px}label{padding:8px 10px;font-size:15px}h2{font-size:33px}.lead{font-size:24px}}
''' + '\n'.join(rules) + '''</style></head><body>
<header><div class="eyebrow">Ada · Colour / companion study · 2 October 2026</div><h1>Room to gather.</h1>
<p class="lead">Twelve panels. Three arrangements. An array gives every sheet a place; what place does it leave for someone?</p>
<nav><a href="#room">Compare the room</a><a href="#reading">Read</a><a href="#making">Make a change</a><a href="#lineage">In the spine</a></nav>
<p class="small">An original Godot study informed by Liam Gillick. Proposed companion for Color_Walls.</p></header>
<main><section id="room"><h2>Keep one decision. Change the other.</h2><p>Choose an arrangement, then keep it still while you change the colour rule. These controls compare nine native Godot captures; the downloadable scene lets you walk between the panels.</p>
<div class="comparison">''' + controls('layout', layouts) + controls('colour', colours) + ''.join(states) + '''</div>
<p class="small">The same gallery and twelve persistent panel identities in every state. This companion is not yet installed in the museum.</p>
<div class="pair"><figure><img src="figures/screens-eye.png" alt="Transparent coloured screens interrupt the route ahead at standing eye height" loading="lazy"><figcaption>At 1.65 m: the view crosses several sheets. The walking body has to find a gap.</figcaption></figure><figure><img src="figures/gathering-eye.png" alt="The same standing viewpoint shows an open centre with six panels overhead" loading="lazy"><figcaption>Same eye position: six sheets above, six around the centre. The benches remain at the sides.</figcaption></figure></div>
<p><a class="pill" href="colour-assembly-study.zip" download>Download the Godot study</a></p><p class="small">Godot 4.6 · desktop WASD + mouse · Escape releases the pointer · Reset returns to the first arrangement.</p></section>
<section id="reading"><article>''' + rendered('READING.md') + '''</article></section>
<section id="making"><div class="making">''' + rendered('MAKING.md') + '''</div></section>
<section id="lineage"><h2>Where this fits</h2><p><strong>Colour → Color_Walls.</strong> A return to things the reader can already carry, with space left for the encounter to ask more than the code implements.</p>
<table><thead><tr><th>Earlier capability</th><th>What it carries here</th></tr></thead><tbody>
<tr><td>Coordinates and Transformation</td><td>A panel keeps its identity while its position and orientation change.</td></tr>
<tr><td>Array</td><td>Twelve indexed objects, repeatable layouts, one chosen exception.</td></tr>
<tr><td>Color_Context_Placed</td><td>Colour assignment makes groups within a spatial arrangement.</td></tr>
<tr><td>Color_Pillar → Color_Walls</td><td>What takes up space; what the eye can cross; what the body can pass.</td></tr></tbody></table>
<p>This is an application of the existing capability ladder. Its proposed placement is recorded without adding a new hall or rewriting the current chapter.</p></section>
<section id="reference"><h2>A structure prepared for use</h2><p>Gillick's screens and platforms let us ask what an interior has organised before anyone occupies it. His <a href="https://liamgillick.info/Somewhere-Specific-in-Mind-Liam-Gillick-and-Suzanne-Cotter">conversation with Suzanne Cotter</a> is the principal reference; <a href="https://www.kerlingallery.com/artists/liam-gillick">Kerlin Gallery's account</a> grounds the material vocabulary of modular Plexiglas and aluminium.</p>
<p>The palette and arrangements here are ours. The relation to array indexing is a computational interpretation. We borrow a question about context and occupation, while keeping the work's institutional and social questions available beyond this small mechanism.</p>
<details><summary>Sources, code and verification</summary><p>''' + str(behaviours) + ' native behaviour checks and ' + str(captures) + ''' successful image saves. The tests cover independent controls, persistent identities, collision, scripted standing-body traversal, the occupied-area guard and reset. No physical headset or learner trial has been run.</p>
<p><a href="figures/verification.json">Native checks</a> · <a href="figures/provenance.json">Source hashes</a> · <a href="README.md">Decisions and limits</a> · <a href="READING.md">Reading source</a> · <a href="MAKING.md">Making source</a></p>
<p class="small">Two-sided alpha compositing; solid panel colliders; ordinary frame shadows. No spectral glass transmission or coloured shadow simulation. Images are unedited Godot viewport output.</p></details></section></main>
<footer>Ada Research · Room to gather · Independent native study. <a href="../2026-10-02-gillick-wall-relations/index.html">Continue to the wall studies</a> · <a href="../2026-10-01-artist-capacity/index.html">Artist / capacity atlas</a> · <a href="/tutorial-lineage">Tutorial lineage</a></footer></body></html>
'''
(HERE / 'index.html').write_text(html, encoding='utf-8')
print(f'Built {HERE / "index.html"}')
