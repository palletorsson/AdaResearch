"""Make the local review from actual receipts and current canonical texts."""
from pathlib import Path
import hashlib, html, json, re, shutil
import markdown
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
MAP=ROOT/'commons/maps/Random_Entropy'
RUN=ROOT/'ada_run/encounter_pilot/Random_Entropy/entropy-compartments'
for name in ['report.json','bench-separated.png','bench-balanced.png','jar-labels.png','jar-readout-detail.png','entrance-comparison.png','source_manifest.json']:
    shutil.copy2(RUN/name,HERE/('museum-report.json' if name=='report.json' else name))
for name in ['tutorial.md','final.md']:
    shutil.copy2(MAP/name,HERE/name)
native=json.loads((HERE/'verification.json').read_text())
fresh=json.loads((HERE/'reconstruction/verification.json').read_text())
room=json.loads((HERE/'museum-report.json').read_text())
assert native['passed'] and fresh['passed'] and room['passed']
before=json.loads((HERE/'before/commons/data/museum/em_plan.json').read_text())
now=json.loads((ROOT/'commons/data/museum/em_plan.json').read_text())
assert [r for r in before['plans'] if r.get('map')!='Random_Entropy']==[r for r in now['plans'] if r.get('map')!='Random_Entropy']
row=next(r for r in now['plans'] if r.get('map')=='Random_Entropy')
assert next(a for a in row['artifacts'] if a['token']=='entropy_compartments')['tile_cell']==[8,9]
paths=[*MAP.glob('*.md'),MAP/'map_data.json',MAP/'writing_wall.json',
       * (ROOT/'commons/artifacts/entropy_compartments').glob('*.gd'),
       * (ROOT/'commons/artifacts/entropy_compartments').glob('*.tscn'),
       ROOT/'algorithms/randomness/entropy_jar/entropy_jar.gd',ROOT/'commons/artifacts/registry/randomness.json',
       ROOT/'commons/data/museum/em_plan.json',ROOT/'commons/data/museum/em_bake.json',ROOT/'commons/data/long_museum.json']
(HERE/'after.json').write_text(json.dumps({'sha256':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths if p.is_file()},'unrelated_plan_rows_preserved':True},indent=2),encoding='utf8')
def render(name):
    s=(HERE/name).read_text(encoding='utf8')
    # The review lives one level deeper than the source; give local links absolute browser routes.
    s=s.replace('](counts-and-neighbours.md)','](/book-review/commons/maps/Random_Entropy/counts-and-neighbours.md)')
    s=s.replace('](../../../doc/','](/book-review/doc/')
    return markdown.markdown(s,extensions=['tables','fenced_code','footnotes'])
prose=(HERE/'final.md').read_text(encoding='utf8')
words=len(re.sub(r'<!--.*?-->','',prose,flags=re.S).split())
style='''*{box-sizing:border-box}body{margin:0;background:#f4f1e8;color:#1e3035;font:18px/1.65 Georgia,serif}main{max-width:1640px;margin:auto;padding:36px}header{max-width:1080px}h1{font-size:42px;line-height:1.16}h2{font-size:25px;margin-top:1.8em}a{color:#1b6470}nav,.label,button{font:15px/1.4 system-ui}nav{display:flex;gap:24px;flex-wrap:wrap}button{padding:12px 20px;border:1px solid #779293;background:#fff;cursor:pointer}.photos{margin:30px 0;display:grid;grid-template-columns:3fr 1fr;gap:24px}.photos img{width:100%;height:auto}.caption{font:15px/1.5 system-ui}.spread{display:grid;grid-template-columns:1fr 1fr;gap:60px}.spread article{min-width:0}.spread h1{font-size:32px}pre{overflow:auto;background:#192e35;color:#e9eee5;padding:20px;font:13px/1.6 monospace}code{font-size:.86em}td,th{text-align:left;border-bottom:1px solid #c3cdca;padding:8px}table{border-collapse:collapse;width:100%;font-size:16px}.label{letter-spacing:.06em;text-transform:uppercase;color:#687e7a;border-top:2px solid;padding-top:14px}details{margin:18px 0}@media(max-width:1000px){.spread,.photos{grid-template-columns:1fr}main{padding:22px}}'''
page=f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Two accounts of one arrangement — Ada Research</title><style>{style}</style><main><nav><a href="/long-museum/writing-wall?map=Random_Entropy">Writing wall</a><a href="README.md">Trial and limits</a><a href="verification.json">Native checks</a><a href="reconstruction/verification.json">Reconstruction</a><a href="museum-report.json">Museum checks</a></nav><header><p class="label">Random Entropy · 15 October 2026</p><h1>Two accounts of one arrangement</h1><p>Eight A, eight B. The colour reading stays at one bit while the number of compatible arrangements changes. SAME k moves the colours while both readings stay fixed. The revised texts begin from that difference.</p><p class="caption">{len(native['checks'])} apparatus checks · {len(fresh['checks'])} fresh reconstruction checks · {len(room['checks'])} museum checks passed. Physical headset and independent learner trials remain open. The 48-value seed bench remains the first research pilot.</p></header><div class="photos"><figure style="margin:0"><img id="bench" src="bench-balanced.png" alt="Two-compartment bench inside Random Entropy, four A and four B in each tray"><div><button onclick="document.getElementById('bench').src='bench-separated.png'">Separated: Ω = 1</button> <button onclick="document.getElementById('bench').src='bench-balanced.png'">Four and four: Ω = 4,900</button></div><figcaption class="caption">Actual hall captures. The left reading is unchanged. These buttons compare saved images.</figcaption></figure><figure style="margin:0"><img src="jar-readout-detail.png" alt="Corrected jar readout names colour within six height bands"><figcaption class="caption">The jar measures H(C|Y), colour given a height band. Its 0–1 bit range is explicit.</figcaption></figure></div><div class="spread"><article><p class="label">Tutorial · small mechanism and experiment cycle</p>{render('tutorial.md')}</article><article><p class="label">Final · {words} words · same adopted room order</p>{render('final.md')}</article></div></main></html>'''
(HERE/'index.html').write_text(page,encoding='utf8')
print('Review published:',HERE/'index.html','final words:',words)
