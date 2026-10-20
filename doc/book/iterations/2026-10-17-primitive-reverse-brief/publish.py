from pathlib import Path
import json
import markdown
import re

HERE = Path(__file__).parent
ROOT = HERE.parents[3]
source = (HERE / 'brief.md').read_text(encoding='utf-8')
body = markdown.markdown(source, extensions=['toc'])
summary = markdown.markdown((HERE / 'summary.md').read_text(encoding='utf-8'))
summary = summary.replace('<h1>', '<h2>').replace('</h1>', '</h2>')
# A calculation of the paired front-face test, not a runtime test.
delta = 0.25
receipt = {'scope': 'Geometric calculation only; proposed installation not built',
           'corner_6_forward_displacement_m': delta,
           'centre_depth_diagonal_5_7_m': 0.5,
           'centre_depth_diagonal_4_6_m': 0.5 + delta / 2,
           'centre_depth_difference_m': delta / 2}
assert receipt['centre_depth_difference_m'] == 0.125
(HERE / 'calculation.json').write_text(json.dumps(receipt, indent=2), encoding='utf-8')
page = '''<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Primitive maps · Reverse design brief</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#f5f2eb;color:#282831;font:18px/1.65 system-ui,sans-serif}
main{max-width:1060px;margin:auto;padding:40px 6vw 90px}h1,h2{font-family:Georgia,serif;line-height:1.17}h1{font-size:clamp(36px,5vw,60px);max-width:850px}h2{font-size:30px;margin:65px 0 24px;padding-top:22px;border-top:1px solid #c8c1bc;scroll-margin-top:20px}
p{max-width:850px}a{color:#653d71;text-underline-offset:4px}nav{display:flex;flex-wrap:wrap;gap:10px;margin:24px 0}nav a{border:1px solid #b9acbb;border-radius:5px;padding:7px 12px;text-decoration:none;font-size:15px}
.eyebrow{font-size:13px;letter-spacing:.12em;text-transform:uppercase;color:#6d496f}.trial{background:#e9e2ec;padding:22px;border-radius:8px;margin:26px 0 40px}.trial h2{border:0;margin:0;padding:0;font-size:28px}.trial p{font-size:16px;margin:10px 0}.trial label{display:block;font-size:16px;font-weight:600}input{width:min(100%,460px);min-height:32px;accent-color:#754a81;vertical-align:middle}output{display:block;font-weight:600;color:#513359;font-size:16px}.caption{font-size:14px!important;color:#514b57}
svg{width:100%;height:auto;display:block;margin:10px 0}svg text{font-family:system-ui,sans-serif;fill:#29232d}li{padding:4px 0}code{font-size:.86em;background:#e8e4de;padding:1px 4px;overflow-wrap:anywhere}li code{word-break:break-word}footer{margin-top:40px;font-size:14px;border-top:1px solid #c8c1bc;padding-top:20px}
@media(max-width:650px){main{padding:24px}h2{font-size:26px}svg text{font-size:18px}.trial{padding:16px}}
</style></head><body><main>
<p class="eyebrow">Ada Research · 17 October 2026 · Proposed instructions</p>
<h1>What can one movement expose?</h1>
<p>A reverse trial: Palle supplies three changes; the assistant proposes the Animated Cube encounter. Read the instructions before building. The installed maps remain unchanged.</p>
SUMMARY
<nav><a href="#point_trace-surface-marks-and-spatial-traces">Glass and spatial trace</a><a href="#point_line_grid-find-the-same-point-twice">Selected point</a><a href="#point_animatedcube-the-surface-was-also-a-decision">Cube proposal</a><a href="#primitives_melencolia-a-skull-among-the-instruments">Skull</a><a href="summary.md">Download summary</a><a href="brief.md">Full brief</a></nav>
<div class="trial"><h2>Same corners. Different surface.</h2><p>Move one corner forward on both faces. Only their internal diagonal differs.</p>
<svg viewBox="0 0 800 280" role="img" aria-label="Two front faces with identical corners and opposite diagonals. A slider changes the forward displacement of corner six."><g id="faceA"></g><g id="faceB"></g></svg>
<label for="move">Corner 6: forward displacement</label><input id="move" type="range" min="0" max="0.4" value="0.25" step="0.01"><output id="readout" for="move" aria-live="polite"></output>
<p class="caption">Interactive geometric sketch, not a Godot screenshot. The marked centres share the same front-view coordinates; their depths differ. <a href="calculation.json">Calculation at 25 cm</a>.</p></div>
CONTENT
<footer>Source-grounded proposal. No new engine behaviour or visitor result is claimed. <a href="../2026-10-17-primitive-encounters/index.html">Previous implemented primitive changes</a>.</footer>
</main><script>
const slider=document.getElementById('move');
function face(id,ox,diag,d){
 const p=[[-.5,-.5,.5],[.5,-.5,.5],[.5,.5,.5+d],[-.5,.5,.5]];
 const project=v=>[ox+v[0]*140+(v[2]-.5)*100,135-v[1]*140-(v[2]-.5)*55];
 const pts=p.map(project),list=a=>a.map(i=>pts[i].join(',')).join(' ');
 const tri=diag===0?[[0,1,3],[1,2,3]]:[[0,1,2],[0,2,3]];
 let s=`<text x="${ox}" y="25" text-anchor="middle" font-size="18">${diag===0?'A · diagonal 5–7':'B · diagonal 4–6'}</text>`;
 tri.forEach((a,i)=>s+=`<polygon points="${list(a)}" fill="${i?'#e6bac6':'#d4c3de'}" stroke="#594560" stroke-width="1.5"/>`);
 const edge=diag===0?[1,3]:[0,2];s+=`<line x1="${pts[edge[0]][0]}" y1="${pts[edge[0]][1]}" x2="${pts[edge[1]][0]}" y2="${pts[edge[1]][1]}" stroke="#80501e" stroke-width="3"/>`;
 pts.forEach((a,i)=>s+=`<circle cx="${a[0]}" cy="${a[1]}" r="5" fill="${i===2?'#a42f68':'#444052'}"/><text x="${a[0]+10}" y="${a[1]+(i>1?-9:22)}" font-size="15">${i+4}</text>`);
 const c=project([0,0,.5+(diag?d/2:0)]);s+=`<circle cx="${c[0]}" cy="${c[1]}" r="7" fill="#fff" stroke="#343246" stroke-width="2"/>`;
 s+=`<text x="${ox}" y="257" text-anchor="middle" font-size="16">Centre depth: ${(50+(diag?d*50:0)).toFixed(1)} cm</text>`;
 document.getElementById(id).innerHTML=s;
}
function update(){const d=+slider.value;face('faceA',190,0,d);face('faceB',580,1,d);document.getElementById('readout').textContent=`Corner moves ${(d*100).toFixed(0)} cm · surface depths differ by ${(d*50).toFixed(1)} cm at the centre`;}
slider.addEventListener('input',update);update();
</script></body></html>'''
body = body[body.index('</h1>') + 5:]
page = page.replace('CONTENT', body)
page = page.replace('SUMMARY', '<section id="summary">' + summary + '</section>')
# The review route intentionally disallows scripts. Use three selectable,
# precomputed views so the comparison works without changing that policy.
def face(ox, alternate, displacement):
    points = [(-.5,-.5,.5),(.5,-.5,.5),(.5,.5,.5+displacement),(-.5,.5,.5)]
    def project(v): return (ox+v[0]*140+(v[2]-.5)*100,135-v[1]*140-(v[2]-.5)*55)
    pts = [project(p) for p in points]
    triangles = [[0,1,2],[0,2,3]] if alternate else [[0,1,3],[1,2,3]]
    label = 'B · diagonal 4–6' if alternate else 'A · diagonal 5–7'
    parts = [f'<text x="{ox}" y="25" text-anchor="middle" font-size="18">{label}</text>']
    for i, triangle in enumerate(triangles):
        coords = ' '.join(f'{pts[j][0]},{pts[j][1]}' for j in triangle)
        fill = '#e6bac6' if i else '#d4c3de'
        parts.append(f'<polygon points="{coords}" fill="{fill}" stroke="#594560" stroke-width="1.5"/>')
    a, b = [pts[j] for j in ([0,2] if alternate else [1,3])]
    parts.append(f'<line x1="{a[0]}" y1="{a[1]}" x2="{b[0]}" y2="{b[1]}" stroke="#80501e" stroke-width="3"/>')
    for i, (x,y) in enumerate(pts):
        parts.append(f'<circle cx="{x}" cy="{y}" r="5" fill="{ "#a42f68" if i == 2 else "#444052"}"/><text x="{x+10}" y="{y+(-9 if i>1 else 22)}" font-size="15">{i+4}</text>')
    cx, cy = project((0,0,.5 + (displacement/2 if alternate else 0)))
    parts.append(f'<circle cx="{cx}" cy="{cy}" r="7" fill="white" stroke="#343246" stroke-width="2"/><text x="{ox}" y="257" text-anchor="middle" font-size="16">Centre depth: {50+(displacement*50 if alternate else 0):.1f} cm</text>')
    return ''.join(parts)

controls=[]; views=[]
for i, (name, delta) in enumerate([('Flat',0),('Corner forward 25 cm',.25),('Corner forward 40 cm',.4)]):
    controls.append(f'<input class="choice" id="choice{i}" name="view" type="radio" {"checked" if i == 1 else ""}><label class="choice-label" for="choice{i}">{name}</label>')
    views.append(f'<div class="state" id="state{i}"><svg viewBox="0 0 800 280" role="img" aria-label="{name}: paired front faces with opposite diagonals">{face(190,False,delta)}{face(580,True,delta)}</svg><p><strong>Surface depths differ by {delta*50:.1f} cm at the centre.</strong></p></div>')
replacement = ''.join(controls) + '<div class="states">' + ''.join(views) + '</div>'
page = re.sub(r'<svg viewBox="0 0 800 280".*?</output>', replacement, page, count=1, flags=re.S)
page = re.sub(r'<script>.*?</script>', '', page, flags=re.S)
page = page.replace('Interactive geometric sketch, not a Godot screenshot.', 'Selectable geometric sketches, not Godot screenshots.')
page = page.replace('</style>', '.choice{width:auto;min-height:0;accent-color:#754a81}.trial label.choice-label{display:inline-block;margin:8px 16px 8px 5px;font-size:14px}.state{display:none}#choice0:checked~.states #state0,#choice1:checked~.states #state1,#choice2:checked~.states #state2{display:block}</style>')
(HERE / 'index.html').write_text(page, encoding='utf-8')
print('Published instruction brief and geometric sketch; maps unchanged.')
