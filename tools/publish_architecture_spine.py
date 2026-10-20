"""Publish native architecture study and a sourced research report."""
from pathlib import Path
import hashlib
import json
import shutil
import markdown
import re

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-the-corridor-has-a-spine'
RUN=ROOT/'ada_run/architecture_spine'
BODY=ROOT/'commons/artifacts/architecture_spine'
for name in ('museum','validation','source'):(OUT/name).mkdir(exist_ok=True,parents=True)
receipt=json.loads((RUN/'report.json').read_text())
assert len(receipt['checks'])==27 and not receipt['failed']
assert all(c['passed'] for c in receipt['checks'])
for f in RUN.glob('*.png'):shutil.copy2(f,OUT/'museum'/f.name)
for name in ('report.json','native.log'):shutil.copy2(RUN/name,OUT/'validation'/name)
for f in BODY.iterdir():
    if f.suffix in ('.gd','.tscn','.md'):shutil.copy2(f,OUT/'source'/f.name)
shutil.copy2(ROOT/'tools/probes/architecture_spine.gd',OUT/'source/verification.gd')
shutil.copy2(ROOT/'commons/artifacts/registry/architecture_spine.json',OUT/'source/registry.json')
text=(OUT/'REPORT.md').read_text(encoding='utf-8')
text=re.sub(r'<!-- museum-placement:start -->.*?<!-- museum-placement:end -->\n*','',text,flags=re.S)
body=markdown.markdown(text,extensions=['tables','fenced_code'])
style='''*{box-sizing:border-box}body{margin:0;background:#f3efe7;color:#213035;font:19px/1.7 Georgia,serif}header,main,footer{max-width:1320px;margin:auto;padding:30px}header{padding-top:48px}h1{font-size:clamp(43px,6vw,80px);line-height:1.05;max-width:1000px}h2{line-height:1.2;margin-top:2.3em}p,li{max-width:79ch}nav,figcaption,.eyebrow,table{font:14px/1.55 system-ui}nav{display:flex;gap:22px;flex-wrap:wrap}.eyebrow{letter-spacing:.1em;text-transform:uppercase}a{color:#923754;text-underline-offset:4px}figure{margin:28px 0}img{width:100%;height:auto;display:block}figcaption{color:#536268;padding-top:9px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:22px}details{padding:17px 0;border-top:1px solid #c5c8c0}summary{cursor:pointer}blockquote{border-left:3px solid #d75e93;padding:5px 25px;margin:30px 0;font-size:1.2em}table{border-collapse:collapse;width:100%;display:block;overflow:auto}td,th{text-align:left;vertical-align:top;padding:16px;border-bottom:1px solid #c5c8c0}code{font:.8em Consolas,monospace;overflow-wrap:anywhere}footer{border-top:1px solid #c5c8c0}@media(max-width:750px){header,main,footer{padding:20px}.pair{display:block}}'''
page=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The corridor has a spine — Endless Museum</title><style>{style}</style></head><body><header><div class="eyebrow">Endless Museum / architecture study / 9 October 2026</div><nav><a href="../2026-10-09-move-the-centre/index.html">Previous: the creature</a><a href="REPORT.md">Research note</a><a href="source/README.md">Run in Godot</a><a href="validation/report.json">27 checks</a></nav></header><main>{body}</main><footer>Endless Museum · always another room</footer></body></html>'''
(OUT/'index.html').write_text(page,encoding='utf-8')
manifest={f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in sorted((OUT/'source').iterdir()) if f.is_file() and f.name!='manifest.json'}
(OUT/'source/manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
print(f'Published {OUT}; {len(manifest)} source snapshots; 27 passing checks.')
from museum_placement_status import decorate
decorate(OUT,'architecture_spine','architecture_spine.json')
