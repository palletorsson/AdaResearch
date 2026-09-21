"""Render the authored article around retained evidence; publish locally via the manifest."""
from pathlib import Path
import hashlib
import html
import json
import shutil
import zipfile
import markdown

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/research/possible-bodies'
RECORD = ROOT/'doc/space/landscape-size-series-2026-09-12'


def build():
    raw = json.loads((OUT/'landscape-size-results.json').read_text(encoding='utf-8'))
    report = json.loads((OUT/'landscape-size-analysis.json').read_text(encoding='utf-8'))
    assert report['raw_sha256'] == hashlib.sha256((OUT/'landscape-size-results.json').read_bytes()).hexdigest()
    assert raw['status'] == report['status'] == 'complete'
    names = ['SINE', 'RANDOM HEIGHTS', 'PERLIN', 'WORLEY F1']
    table = '| Surface | Radius 45 mm | Radius 75 mm | Radius 105 mm |\n|---|---:|---:|---:|\n'
    for name in names:
        row = []
        for r in [.045,.075,.105]:
            v = report['outlet_ranges'][name][str(r)]
            row.append(str(v['min']) if v['min'] == v['max'] else f"{v['min']}–{v['max']}")
        table += f'| {name} | ' + ' | '.join(row) + ' |\n'
    all_rows = ''.join('<tr>'+''.join(f'<td>{html.escape(str(v))}</td>' for v in [t['trial'],t['seed'],t['repeat'],round(t['radius_m']*1000)]+[t['result']['counts'][n]['outlet'] for n in names])+'</tr>' for t in raw['trials'])
    settings = [
        ('Engine', raw['engine']['string']+'; '+raw['physics_engine']+'; Compatibility renderer'),
        ('Domain and mesh', '2 × 3.2 m; 20 × 32 cells, 693 vertices, 1,280 triangles. Mesh and collision use the same sampled surface.'),
        ('Fields', 'Sine product at 0.9 cycles/m; seeded independent uniform random vertex values; FastNoiseLite Perlin at frequency 0.9 without fractal layers; cellular nearest-feature Euclidean distance (Worley F1). Each field separately min/max normalised to [0, 0.30] m.'),
        ('Body', 'Sphere radii 0.045, 0.075, 0.105 m; mass 0.1 kg; continuous collision detection; zero initial velocity. Linear and angular damping replace defaults with 0.05. All bodies can collide.'),
        ('Contact and gravity', 'World gravity 9.8 m/s²; sphere and terrain friction 0.45, bounce 0. Side/back rims retain ordinary collider material defaults.'),
        ('Release', 'Four columns × eight rows per tray. Local centres x = −0.75 + 0.5 × column, y = 1.1, z = −1.3 + 0.28 × row. Shared across trays, sizes and repeats. Tray tilt 20° about X, downhill along local +Z.'),
        ('Observation', '720 counter ticks at 60 Hz, time scale 1. Counter includes the activation tick. First observed outlet: centre z > 1.6 + radius. Other exit: |x| > 1.06 + radius, z < −1.68 − radius, or y < −0.4. Other-exit test takes precedence. Exited bodies freeze and stop colliding. All remaining bodies freeze at deadline.'),
        ('Order', 'Recorded ordered blocks: seeds 1729, 1730, 1731; two repeats; radius order rotates by seed/repeat index. Not randomised. Sine geometry is seed-independent. All four trays run concurrently.'),
        ('Scope', 'A desktop simulation pilot using selected configurations. Museum placement, a walking player, concealment and headset experience are not tested by this series. No entropy or free-energy estimate. No significance tests.'),
    ]
    method = '<p>The <a href="landscape-size-protocol.md">protocol</a> was written before the series. All 18 trials are retained. '
    method += f"{len(report['checks'])} automated integrity checks verify treatment coverage, matched samples and starts, counters, per-body event accounting and source hashes. They validate the records, not the article's wider interpretation.</p>"
    method += '<dl>'+''.join(f'<dt>{html.escape(k)}</dt><dd>{html.escape(v)}</dd>' for k,v in settings)+'</dl>'
    method += '<p>Individual trials in execution order. Values are outlet counts out of 32. Still-in counts equal 32 minus outlet here; other exits were zero throughout.</p><div class="table-scroll"><table><thead><tr>'+''.join(f'<th>{c}</th>' for c in ['Trial','Seed','Repeat','Radius mm']+names)+'</tr></thead><tbody>'+all_rows+'</tbody></table></div>'
    method += '<p><a href="landscape-size-trials.csv">All 72 tray records (CSV)</a> · <a href="landscape-size-contrasts.csv">Paired size differences (CSV)</a> · <a href="landscape-size-results.json">Raw results, sampled fields and event records (JSON)</a> · <a href="landscape-size-analysis.json">Integrity checks and repeat differences (JSON)</a></p>'
    method += '<p>Final positions of departed bodies belong to the collection display, not their exit locations. Recorded ticks observe state changes; they do not provide continuous collision times. The complete trajectories and contact manifolds were not recorded. These results do not reproduce the earlier Unity setup.</p>'
    method += '<p><a href="landscape-size-source.zip">Source snapshot and protocol (ZIP)</a> contains the recorded source files plus analysis/render scripts. It is a source extract for the AdaResearch project, not a self-contained Godot distribution. Run <code>res://commons/testing/run_landscape_size_series.gd</code> from that project to repeat the series. The interactive workshop is <code>res://commons/testing/landscape_flow_workshop.tscn</code>.</p>'
    method += '<p>All three preselected captures: <a href="landscape-size-radius-45.png">45 mm</a> · <a href="landscape-size-radius-75.png">75 mm</a> · <a href="landscape-size-radius-105.png">105 mm</a>. Export figures: <a href="landscape-size-outcomes.svg">outcomes SVG</a> / <a href="landscape-size-outcomes.png">PNG</a>; <a href="landscape-size-time.svg">time SVG</a> / <a href="landscape-size-time.png">PNG</a>.</p>'
    source = (OUT/'landscape-article.template.md').read_text(encoding='utf-8')
    source = source.replace('<!-- SIZE_RESULTS_TABLE -->',table).replace('<!-- SIZE_METHOD -->',method)
    assert '<!-- SIZE_' not in source
    (OUT/'landscape-article.md').write_text(source, encoding='utf-8')
    body = markdown.markdown(source, extensions=['tables','fenced_code'])
    css = '''
    :root{color-scheme:light;--paper:#f7f4eb;--ink:#243340;--accent:#176a82}
    *{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:20px/1.7 Georgia,serif}
    main{max-width:1090px;margin:0 auto;padding:35px 24px 80px}nav,.status{font:13px/1.5 system-ui,sans-serif;letter-spacing:.035em}
    nav{display:flex;flex-wrap:wrap;gap:22px;border-bottom:1px solid #c9cecb;padding-bottom:20px;margin-bottom:60px}
    a{color:var(--accent);text-underline-offset:.17em}a:hover{color:#9b432e}.status{color:#9b432e;text-transform:uppercase;margin-bottom:20px}
    h1{font-size:clamp(43px,7vw,78px);line-height:1.03;letter-spacing:-.035em;font-weight:normal;margin:0 0 30px;max-width:800px}
    article>p,article>pre,article>table{max-width:760px;margin-left:auto;margin-right:auto}article>p{margin-top:26px;margin-bottom:26px}
    article>p:first-of-type{font:19px/1.5 system-ui,sans-serif;color:#52626d;margin-bottom:55px}
    strong{font-weight:700}figure{margin:48px 0}img{display:block;width:100%;height:auto;border-radius:4px}
    figcaption{font:14px/1.6 system-ui,sans-serif;color:#52626d;max-width:870px;margin:15px auto 0}
    pre{background:#172c39;color:#e0f0ec;padding:25px;overflow:auto;border-radius:3px;font-size:16px}code{font-size:.84em}
    table{border-collapse:collapse;width:100%;font:15px/1.5 system-ui,sans-serif}th,td{text-align:left;padding:12px 14px;border-bottom:1px solid #c9cecb}th{font-weight:650;background:#e8eeeb}
    .table-scroll{overflow-x:auto}.table-scroll table{min-width:700px}.evidence{border-top:2px solid #176a82;margin:60px 0 30px;padding-top:18px;font:16px/1.65 system-ui,sans-serif}
    summary{cursor:pointer;font-size:19px;font-weight:600}dt{font-weight:650;margin-top:22px}dd{margin:5px 0 0}dl{max-width:820px}
    @media(max-width:600px){body{font-size:18px}main{padding:25px 18px 50px}nav{margin-bottom:35px}th,td{padding:8px 6px;font-size:12px}figure{margin:32px 0}pre{font-size:13px;padding:18px}}
    @media print{nav,.status{display:none}body{font-size:12pt;background:white}main{padding:0}figure{break-inside:avoid}summary{display:none}details{display:block}img{max-height:21cm;object-fit:contain}a{color:inherit}}
    '''
    page = '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="description" content="An Ada Research working article on procedural terrain, body size, the clock and the conditions of passage. Includes a recorded Godot experiment."><title>What leaves? What remains? — Ada Research</title><style>'+css+'</style></head><body><main><nav><a href="index.html">Ada Research · possible bodies</a><a href="landscape-thread.html">The landscape workshop</a><a href="landscape-size-protocol.md">Experiment protocol</a></nav><div class="status">Working article · desktop pilot · 12 September 2026</div><article>'+body+'</article></main></body></html>\n'
    (OUT/'landscape-article.html').write_text(page, encoding='utf-8')
    for mm in [45,75,105]:
        shutil.copyfile(ROOT/f'ada_run/landscape-size-series/seed-1729-radius-{mm}.png', OUT/f'landscape-size-radius-{mm}.png')
    files = ['landscape-article.html','landscape-article.md','landscape-size-protocol.md','landscape-size-results.json','landscape-size-analysis.json','landscape-size-trials.csv','landscape-size-contrasts.csv','landscape-size-outcomes.svg','landscape-size-outcomes.png','landscape-size-time.svg','landscape-size-time.png','landscape-size-radius-45.png','landscape-size-radius-75.png','landscape-size-radius-105.png','landscape-size-source.zip','landscape-thread.html','landscape-thread.md']
    with zipfile.ZipFile(OUT/'landscape-size-source.zip','w',zipfile.ZIP_DEFLATED) as z:
        for p, expected in raw['source_sha256'].items():
            content = (ROOT/p).read_bytes()
            assert hashlib.sha256(content).hexdigest() == expected, 'Source changed: '+p
            z.writestr(p,content)
        for p in ['tools/analyze_landscape_size_series.py','tools/build_landscape_article.py','doc/research/possible-bodies/landscape-size-protocol.md']:
            z.write(ROOT/p,p)
        z.writestr('SOURCE-HASHES.json',json.dumps(raw['source_sha256'],indent=2))
    link = '\n\n[Read the working article: What leaves? What remains?](landscape-article.html) — an 18-trial size series, its repeat discrepancy, and the question of what counts as passage.\n'
    p = OUT/'landscape-thread.md'; text = p.read_text(encoding='utf-8')
    if '(landscape-article.html)' not in text:
        title, rest = text.split('\n',1); p.write_text(title+link+rest, encoding='utf-8')
    p = OUT/'landscape-thread.html'; text = p.read_text(encoding='utf-8')
    if 'href="landscape-article.html"' not in text:
        text = text.replace('</h1>','</h1>'+markdown.markdown(link),1); p.write_text(text,encoding='utf-8')
    RECORD.mkdir(parents=True,exist_ok=True)
    (RECORD/'publication-manifest.json').write_text(json.dumps(files,indent=2)+'\n',encoding='utf-8')
    (RECORD/'file-hashes.json').write_text(json.dumps({f:hashlib.sha256((OUT/f).read_bytes()).hexdigest() for f in files},indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'publication_files':len(files),'article':str(OUT/'landscape-article.html')}))


if __name__ == '__main__':
    build()
