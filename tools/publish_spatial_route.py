"""An editable teaching route through installed museum encounters; no runtime edits."""
from pathlib import Path
import html
import json

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-12-spaces-a-route-through-differences'
ITEMS = [
 ('Perspective', '2026-10-12-perspective-the-sphere-keeps-its-size', 'front.png', 'Lobby: left gold doorway.', 'Perspective; scale; measurement', 'Carry the same sphere to the viewpoint, then inspect the tapered corridor from the side. Compare apparent depth with measured construction. The sphere keeps its size; the architecture produces the illusion.', 'Keep object size separate from apparent size.'),
 ('Overlapping rooms', '2026-10-11-overlapping-rooms-the-same-point', None, 'Lobby: Rose and Blue pavilion doors.', 'Portal transform; object identity; visibility', 'Walk around the pavilion before entering Rose and Blue. Carry the same point through a doorway, leave it, and retrieve it. Reconstruct one paired doorway before adding more. Explain the declared source and destination frames and the visibility mask.', 'Keep the object; change its spatial connection.'),
 ('Around the corner', '2026-10-11-around-the-corner', None, 'Lobby: right gold floor line.', 'Generation; stable address; bounded cache', 'Round the hidden corner into another numbered room. Four turns restore heading without returning to the same room. Leave the point, continue, then backtrack. Explain stable room addresses and rebuilding empty rooms while protecting the room holding the point.', 'Familiar appearance does not establish identity.'),
 ('Repeating gallery', '2026-10-12-repeating-gallery-the-same-point', 'across-edge.png', 'Rose: rear-left cyan doorway.', 'Periodic boundary; translation; visual instance', 'Cross a tile edge while holding the same point. Leave it and walk a lap to find it again. Reconstruct one wrap translation; distinguish the physical tile and live point from their visual neighbours. Heading and held offset survive the wrap.', 'A repeated image is not another live object.'),
 ('Labyrinth', '2026-10-12-labyrinth-the-point-remembers', 'marker-returned.png', 'Blue: rear-right gold doorway.', 'Connectivity; persistent state; event', 'Place the point in A and walk A–B–C–D–A. Retrieve that instance, then touch the seal to open A–C. Reconstruct the connection state and both barriers. The lesson changes a graph through a hand event; it does not change room dimensions.', 'A stored object tests a return; an action changes the route.'),
 ('Column forest — side encounter', '2026-10-12-column-forest-a-profile-branches', 'inside.png', 'Blue: rear-left gold doorway.', 'Profile; branching; parameter; guide', 'Bring the point sideways to change the small study’s branch angle; use its trigger to reveal guides. Reuse the earlier profile and transformation work. Follow shaft, branch and vault construction while keeping geometric resemblance separate from structural proof.', 'Earlier geometry becomes architecture; this is not intrinsic curvature.'),
 ('Curved paths and metric spaces', '2026-10-11-seven-spaces-in-the-museum', None, 'Return to the lobby console: chambers 3–7.', 'Parallel transport; geodesic; metric; chart', 'Return to the carried triangle and compare plane and sphere before the exact disk, H² × R and H³ views. Teach these in separate small steps. Measure paths and angles under the declared metric, then use geodesic target practice. Distinguish surface curvature, product geometry and full three-dimensional curvature.', 'Changing connections and changing a metric are different operations.'),
]

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    records=[]
    for title,folder,picture,entry,labels,lesson,carry in ITEMS:
        source=OUT.parent/folder
        assert (source/'index.html').exists(), folder
        if picture:
            assert (source/picture).exists(), picture
        records.append(dict(title=title,report=f'../{folder}/index.html',image=f'../{folder}/{picture}' if picture else None,entry=entry,subjects=labels.split('; '),lesson=lesson,carry=carry))
    (OUT/'route.json').write_text(json.dumps(records,indent=2,ensure_ascii=False),encoding='utf-8')
    md=['# Spaces — proposed teaching route', '', 'Editable teaching order, not a change to the physical room order. Same live PointBody throughout. Existing plane/sphere runnable tutorial remains the baseline. These are briefs for expansion, not tested student reconstructions.', '']
    cards=[]
    for n,r in enumerate(records,1):
        md.extend([f'## {n}. {r["title"]}', '', f'Entrance: {r["entry"]}', '', f'Learning elements: {", ".join(r["subjects"])}.', '', r['lesson'], '', f'Carry: {r["carry"]}', ''])
        image=f'<img src="{r["image"]}" alt="Actual museum capture: {html.escape(r["title"])}" loading="lazy">' if r['image'] else ''
        cards.append(f'<section id="stop-{n}"><small>STOP {n}</small><h2>{html.escape(r["title"])}</h2><p class="labels">{html.escape(" · ".join(r["subjects"]))}</p><p>{html.escape(r["entry"])}</p>{image}<p>{html.escape(r["lesson"])}</p><p><b>Carry:</b> {html.escape(r["carry"])}</p><a href="{r["report"]}">Inside images and test receipts →</a></section>')
    md.extend(['## Acceptance before full lesson expansion', '', 'Print complete new code and explicitly name carried files. Test reconstruction from the text, not hidden artifact code. Predict and test a student variation. Check object identity and reversal. Keep author runtime checks separate from fresh ghost-student evidence. Physical headset review remains open.', ''])
    (OUT/'ROUTE.md').write_text('\n'.join(md),encoding='utf-8')
    (OUT/'index.html').write_text('''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Spaces — a route through differences</title><style>body{margin:auto;max-width:1100px;padding:36px;background:#171d26;color:#ece5d8;font:18px/1.6 system-ui}h1{font-size:clamp(36px,6vw,68px);line-height:1.1}h2{line-height:1.2}a{color:#82d2dc}section{margin:60px 0;padding-top:24px;border-top:1px solid #556}img{width:100%;border-radius:8px}.labels,small{color:#f1bf70}</style><small>ENDLESS MUSEUM · PROPOSED TEACHING ROUTE</small><h1>The same point.<br>Different kinds of space.</h1><p>Apparent depth → connections → repetition → a remembered place → curved paths. The column forest is a side encounter returning to profiles and branching.</p><p>This teaching route uses the installed spaces. It does not change their physical arrangement or the museum code. The linked reports contain actual renderer captures and scoped test receipts. Full tutorial expansion and fresh student reconstruction remain ahead.</p><p><a href="ROUTE.md">Editable paragraph briefs</a> · <a href="route.json">Structured route</a></p>'''+'\n'.join(cards)+'</html>',encoding='utf-8')
    print(f'Published {len(records)} verified report links and {sum(bool(r["image"]) for r in records)} existing captures: {OUT}')

if __name__ == '__main__':
    main()
