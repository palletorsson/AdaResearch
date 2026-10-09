from pathlib import Path
import hashlib
import html
import json
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
MAPS = ['Array', 'Tutorial_3D', 'Tutorial_Tiling_Floor', 'Tutorial_Tiling_Walls', 'Tutorial_Disco']
IMAGES = ['array', 'array-3d', 'array-floor', 'array-walls', 'array-disco']

def inline(value):
    value = html.escape(value)
    value = re.sub(r'`([^`]+)`', r'<code>\1</code>', value)
    return re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', value)

def markdown(value):
    result = []
    for block in value.strip().split('\n\n'):
        if block.startswith('|'):
            rows = block.splitlines()
            cells = lambda row: ''.join('<td>' + inline(c.strip()) + '</td>' for c in row.strip('|').split('|'))
            result.append('<div class="table"><table><thead><tr>' + cells(rows[0]) + '</tr></thead><tbody>' + ''.join('<tr>' + cells(r) + '</tr>' for r in rows[2:]) + '</tbody></table></div>')
        elif block.startswith('# '):
            result.append('<h1>' + inline(block[2:]) + '</h1>')
        elif block.startswith('## '):
            result.append('<h2>' + inline(block[3:]) + '</h2>')
        else:
            result.append('<p>' + inline(block) + '</p>')
    return '\n'.join(result)

text = (HERE / 'REPORT.md').read_text(encoding='utf-8')
parts = re.split(r'(?=^## )', text, flags=re.M)
body = []
hall_index = 0
for part in parts:
    if any(part.startswith('## ' + name + ' —') for name in MAPS):
        name = MAPS[hall_index]
        image = IMAGES[hall_index]
        body.append(f'<section class="hall" id="{name}"><figure><a href="../2026-10-06-final-comic-plates/{image}.png"><img src="../2026-10-06-final-comic-plates/{image}.png" alt="{name}: selected reflective encounters" loading="lazy"></a><figcaption>Existing illustration · imagined staging, not runtime evidence.</figcaption></figure><div>' + markdown(part) + f'<p class="links"><a href="/book-review/commons/maps/{name}/final.md">Current final.md</a> · <a href="http://localhost:3003/illustrations?sequence=array_tutorial&amp;plate=final-{name}">Illustration viewer</a></p></div></section>')
        hall_index += 1
    else:
        body.append('<section class="reading">' + markdown(part) + '</section>')
assert hall_index == 5
style = '''*{box-sizing:border-box}body{margin:0;background:#eeece6;color:#252525;font:18px/1.65 Georgia,serif}nav{padding:18px 4vw;background:#252525;color:white;display:flex;gap:24px;flex-wrap:wrap;font:14px/1.5 system-ui}nav a{color:white}main{max-width:1500px;margin:auto;padding:35px 4vw}h1{font-size:clamp(36px,4vw,62px);line-height:1.1;max-width:950px}h2{font-size:29px;line-height:1.25}p{margin:0 0 1.1em}a{color:#752249}code{font:0.82em ui-monospace,monospace;background:#dedbd4;padding:2px 4px;overflow-wrap:anywhere}.reading{max-width:1040px;margin:0 auto 50px}.hall{display:grid;grid-template-columns:minmax(270px,.9fr) minmax(350px,1.1fr);gap:42px;margin:65px 0;padding:32px;background:#faf9f5;border-top:3px solid #292929;scroll-margin-top:20px}figure{margin:0}img{width:100%;height:auto;display:block}figcaption,.links{font:13px/1.6 system-ui;margin-top:10px;color:#555}.table{overflow-x:auto}table{border-collapse:collapse;width:100%;font:16px/1.55 system-ui;margin:20px 0}td{padding:12px;vertical-align:top;border-bottom:1px solid #bcb8b0}thead{font-weight:bold;background:#dedbd4}@media(max-width:850px){.hall{display:block;padding:18px}.hall figure{max-width:460px;margin:0 auto 30px}main{padding:25px 5vw}}@media print{nav{display:none}.hall{break-before:page;display:block}figure{max-width:340px;float:left;margin:0 25px 15px 0}.hall:after{content:"";display:block;clear:both}body{background:white;font-size:12pt}}'''
page = '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Arrays after the first two sequences</title><style>' + style + '</style><nav><a href="REPORT.md">One-file report</a>' + ''.join(f'<a href="#{m}">{m.replace("Tutorial_", "").replace("_", " ")}</a>' for m in MAPS) + '</nav><main>' + ''.join(body) + '</main></html>'
(HERE / 'index.html').write_text(page, encoding='utf-8')
sources = ['commons/maps/sequences/array_tutorial.json', 'doc/book/course/execution-plan/plan.json', 'doc/book/course/storyboards/ARRAYS.md', 'doc/book/iterations/2026-10-04-arrays-capacity-return/REPORT.md', 'doc/book/iterations/2026-10-06-transformation-tutorial-drafts/Trans_Pre/tutorial.md', 'doc/book/iterations/2026-10-06-transformation-tutorial-drafts/Trans_Pit/tutorial.md']
sources += [f'commons/maps/{m}/{track}.md' for m in MAPS for track in ['final','tutorial']]
sources += [f'doc/book/iterations/2026-10-06-final-comic-plates/{im}.png' for im in IMAGES]
sources += ['algorithms/arrays/row_3_x.gd', 'algorithms/arrays/grid_2d_4x4.gd', 'commons/artifacts/regularity/array_flight_lab.gd', 'commons/artifacts/regularity/tiling_pattern.gd', 'commons/artifacts/regularity/disco_controls.gd', 'commons/audio/sequencer/step_sequencer.gd', 'commons/audio/sequencer/sequencer_ui.gd']
manifest = {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() if (ROOT / p).exists() else None for p in sources}
(HERE / 'source-manifest.json').write_text(json.dumps({'status':'Read-only source review; lesson proposal; no runtime tests', 'sources':manifest}, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'halls': hall_index, 'source_files': len(manifest), 'missing': [p for p,v in manifest.items() if v is None], 'output':str(HERE / 'index.html')}))
