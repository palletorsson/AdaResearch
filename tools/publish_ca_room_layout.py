"""Add switchable native hall views with optional location pins to the CA report."""
from pathlib import Path
import html,json
from PIL import Image
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-a-row-with-neighbours'
L=O/'layout'
data=json.loads((L/'report.json').read_text(encoding='utf-8'))
assert data['passed']
width,height=Image.open(L/'overhead.png').size
labels=[('ca_rule_explorer','Row explorer + overhead history'),('persian_rug','Mirrored rug'),('langton_swarm','Turmite swarm'),('line_network_ca','Growing line network'),('rule110_computer','Rule 110 comparison'),('ca_showcase','Showcase in the far pocket'),('synthesis_stand','Sphere on its stand')]
pins=''; legend=''
for i,(key,title) in enumerate(labels,1):
 item=next(x for x in data['observations']['inventory'] if x['key']==key)
 x,y=item['top_pixel']; assert 0<=x<width and 0<=y<height
 pins+=f'<a class="layout-pin" style="left:{x/width*100:.3f}%;top:{y/height*100:.3f}%" href="#layout-{key}" aria-label="{html.escape(title)}">{i}</a>'
 legend+=f'<li id="layout-{key}"><b>{i}.</b> {html.escape(title)}</li>'
fragment='''<section id="layout"><h2>The room from above</h2>
<p>Use the overhead view to judge the distribution of works and the spaces between them. Switch to the raised view to see the height of the walls and the history ring. These are captures of the built museum, with its current arrangement.</p>
<style>
.layout-viewer{margin:24px 0}.layout-viewer>label{font:16px system-ui;display:inline-block;padding:12px 15px 12px 4px;cursor:pointer}.layout-stage{position:relative;margin:0}.layout-stage img{width:100%;display:block}.layout-pin{position:absolute;transform:translate(-50%,-50%);width:29px;height:29px;display:grid;place-items:center;border:2px solid #fff;border-radius:50%;background:#17251d;color:white;font:700 15px system-ui;text-decoration:none;box-shadow:0 2px 5px #0008}.layout-pin:focus,.layout-pin:hover{background:#ad345b;outline:3px solid white}.layout-oblique{display:none}#layout-oblique-choice:checked~.layout-top{display:none}#layout-oblique-choice:checked~.layout-oblique{display:block}#layout-pins:not(:checked)~.layout-top .layout-pin{display:none}.layout-legend{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:10px;list-style:none;padding:0;font:15px/1.5 system-ui}.layout-legend li:target{background:#dceada}.layout-note{background:#e7e8de;padding:20px;border-left:4px solid #568c68} @media print{.layout-oblique{display:block!important}.layout-top{display:block!important}}
</style>
<div class="layout-viewer">
<input id="layout-top-choice" type="radio" name="layout-view" checked><label for="layout-top-choice">Overhead</label>
<input id="layout-oblique-choice" type="radio" name="layout-view"><label for="layout-oblique-choice">Raised view</label>
<input id="layout-pins" type="checkbox" checked><label for="layout-pins">Show locations</label>
<figure class="layout-stage layout-top"><img src="layout/overhead.png" alt="Overhead capture of the complete CA opening: rug room on the left, row explorer and later works along the right corridor.">'''+pins+'''</figure>
<figure class="layout-stage layout-oblique"><img src="layout/raised-oblique.png" alt="Raised oblique view showing the CA hall walls, ring and long corridor."></figure>
</div><ul class="layout-legend">'''+legend+'''</ul>
<p><a href="layout/overhead.png">Open full-size overhead image</a> · <a href="layout/raised-oblique.png">Open full-size raised image</a> · <a href="layout/report.json">Capture record and measured locations</a></p>
<div class="layout-note"><strong>What I would improve next</strong>
<ol><li><strong>Make the opening comparison easier to discover.</strong> The rug has its own room; the row explorer is across a long divider. A clearer sightline or connection should let the visitor recognise the two as a comparison.</li>
<li><strong>Give the network breathing room.</strong> Its neighbouring decorative plinth is only about one metre away at the anchors. The overhead image shows both competing in the same small area. Relocate that secondary object before enlarging this exhibit.</li>
<li><strong>Simplify the lower-left pockets.</strong> Much of that part of the footprint is wall or narrow passage, with the showcase tucked into the far corner. Consolidating those pockets could give it a legible destination and a clearer return route.</li></ol>
<p>These are spatial proposals, not applied changes. The current walls, artifact positions and tutorial remain intact. An overhead picture can locate crowding; visitor-height and collision checks must judge a revised route.</p></div>
<p class="eyebrow">Native Godot captures · camera above the actual hall · player and neighbouring halls hidden for the view only · no walls removed</p>
</section>'''
followup=R/'doc/book/iterations/2026-10-08-ca-rooms-connected/index.html'
if followup.exists():
 fragment=fragment.replace('<h2>The room from above</h2>', '<h2>The room from above — before review</h2><p class="layout-note">These proposals have now been applied and checked. <a href="../2026-10-08-ca-rooms-connected/index.html">See the new arrangement and before/after museum pictures.</a></p>')
 fragment=fragment.replace('These are captures of the built museum, with its current arrangement.', 'These captures preserve the arrangement before the spatial return.')
 fragment=fragment.replace('What I would improve next','What this review proposed')
 fragment=fragment.replace('These are spatial proposals, not applied changes. The current walls, artifact positions and tutorial remain intact. An overhead picture can locate crowding; visitor-height and collision checks must judge a revised route.', 'This panel preserves the initial spatial diagnosis. The linked follow-up applies the changes and verifies them from visitor height and against collision geometry.')
(L/'section.html').write_text(fragment,encoding='utf-8')
(L/'NOTES.md').write_text('''# CA opening: spatial review

Added overhead and high-oblique native views to the existing opening report, with optional location pins projected by the Godot camera. Current room retained. No production/map/tutorial change.

Observed: rug has a separate room across the central divider; active works mostly line the right corridor; lower-left pockets devote much of their area to walls and narrow passage; decorative dream-body plinth is beside line network (anchors approximately 1m apart).

Proposed next: clarify first row/rug comparison sightline; move secondary plinth away from network; simplify lower-left pockets and make showcase destination legible. Proposals need visitor-height and collision verification before claiming improved access.

Working convention requested by author: each subsequent hall report should include an overhead view, an elevated oblique view and a visitor-height interaction view. Use actual museum captures, not only the authored grid. Show before/after when arrangement changes.
''',encoding='utf-8')
print(json.dumps({'pins':len(labels),'image_pixels':[width,height],'layout_checks':len(data['checks'])}))
if followup.exists():
 with (L/'NOTES.md').open('a',encoding='utf-8') as f:
  f.write('\nApplied 8 October: see ../../2026-10-08-ca-rooms-connected/index.html for ten native before/after images and 25 fresh layout checks. This folder is the preserved before review.\n')
