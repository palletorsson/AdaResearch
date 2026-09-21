"""Build the source-backed spine platform audit, without regenerating W1's guide."""
from pathlib import Path
from collections import Counter
import html
import json
from urllib.parse import quote

from build_sequence_platform_recovery_report import drawing
from recover_spine_platforms import ROOT, OUT as ARCHIVE, read, save_json, write

OUT = ROOT / 'doc/research/waves-chance-noise'
LABELS = {'recover':'Corrected', 'already-platforms':'Already platforms',
          'embedded-grid':'Real grid arena', 'no-interior-2':'No interior 2',
          'preserved-gallery':'Preserved gallery'}


def main():
    report = read(ARCHIVE/'recovery.json')
    s = report['summary']
    parts = ['''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Platforms through the spine · Ada Research</title><style>
*{box-sizing:border-box}body{margin:0;background:#f4f0e8;color:#24272b;font:17px/1.65 system-ui,sans-serif}main{max-width:1120px;margin:auto;padding:32px 24px 80px}a{color:#8b2855;text-underline-offset:3px}h1{font:clamp(40px,6vw,68px)/1.08 Georgia,serif;max-width:900px}h2{font:30px/1.25 Georgia,serif;margin-top:40px}h3{font:24px/1.3 Georgia,serif}.small,figcaption{font-size:14px;color:#625b60}p{max-width:940px}.status{padding:18px 24px;border-left:5px solid #26756d;background:#fffcf5}.review{border-color:#bc833f}.cards,.comparison{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:18px;margin:24px 0}.card,figure{margin:0;border:1px solid #d8cfc7;border-radius:5px;padding:16px;background:#fffcf5}.card strong{display:block;font:38px Georgia,serif}.comparison{align-items:start}svg{display:block;width:100%;max-height:360px;margin-top:12px}figcaption{min-height:46px}table{border-collapse:collapse;width:100%;font-size:14px}td,th{padding:10px 6px;text-align:left;border-bottom:1px solid #d8cfc7}td:first-child{overflow-wrap:anywhere}details{margin:18px 0;border:1px solid #d8cfc7;padding:12px 16px}summary{cursor:pointer;font-weight:600}code{font-size:14px;overflow-wrap:anywhere}.key{display:inline-block;margin:3px 18px 3px 0}.key:before{content:"";display:inline-block;width:14px;height:14px;margin-right:6px;background:var(--c)}input{width:100%;max-width:520px;padding:12px;border:1px solid #8d7c82;border-radius:3px;font:inherit;background:#fffaf5}li{margin:7px 0}[hidden]{display:none!important}.tablewrap{overflow-x:auto}@media(max-width:680px){main{padding:22px 16px 55px}.cards,.comparison{grid-template-columns:1fr}.comparison figure{max-width:440px;width:100%;margin:auto}td,th{padding:8px 4px}svg{max-height:320px}}
</style></head><body><main><nav><a href="index.html">Research guide</a> · <a href="structure-recovery.html">Randomness, Noise and CA recovery</a> · <a href="NEXT_BATCH.md">Current development brief</a></nav>
<p class="small">Ada Research · 10 September 2026 · geometry audit</p><h1>Give the grid its platforms back.</h1>
<p>The museum can turn a one-metre deck into a full-height wall when both are written as <code>2</code>. Following the wave, randomness, noise and cellular automata repairs, this pass checks that distinction across every sequence in the current spine.</p>''',
    f'<div class="status"><strong>{s["changed_maps"]} additional maps corrected; source checks pass.</strong><p>{s["new_platform_cells"]:,} interior cells now derive as platforms. {s["boundary_cells_made_explicit"]} boundary cells are explicit walls. {s["changed_active"]} corrected rooms are active; 15 remain extensions. Physical museum and headset verification are pending.</p></div>',
    f'<div class="cards"><div class="card"><strong>{s["sequences"]}</strong>spine sequences audited</div><div class="card"><strong>{s["audited_maps"]}</strong>authored maps, including extensions</div><div class="card"><strong>{s["active_maps"]}</strong>active museum halls</div></div>',
    '''<h2>One number, three construction cases</h2><p><b>Converted grid:</b> keep interior <code>2</code> and give the map <code>museum.wall_height: 3</code>. The deck is one metre above the floor; an outside wall is written <code>w</code>. Existing holes, taller structures and artifact positions stay in place.</p>
<p><b>Real grid inside a museum:</b> twenty maps already build their arena with GridSystem, which reads numeric heights directly. The staged Transformation rooms belong here. Their simulation and the surrounding museum shell are separate; the bulk wall-threshold correction does not apply.</p>
<p><b>Rebuilt gallery:</b> Palle chose to preserve the newer partitions. A room’s old grid cannot tell us the purpose of every wall added since. Nine such rooms keep their current layout, as recorded below.</p>
<h2>See what changes</h2><p class="small">Source diagrams generated from archived map JSON and corrected sources. These are not screenshots or collision measurements. Historical grids can be smaller than their museum rooms. Hover a cell for its source value and coordinates.</p>
<div class="small"><span class="key" style="--c:#d2ac61">Height-2 deck</span><span class="key" style="--c:#64555d">Wall / taller structure</span><span class="key" style="--c:#ece7df">Floor</span><span class="key" style="--c:#fff">Void</span></div>''']
    for name in ['Fractal_RecursiveTrees','ISO_Caves','QFEP_Synthesis','Boolean_Verbs']:
        rel = Path('commons/maps')/name/'map_data.json'
        parts.append(f'<h3>{name}</h3>')
        if name == 'Boolean_Verbs':
            parts.append('<p>The existing intent calls the sills steps, not walls, so the previous verb should remain visible from the next. This is a direct repair of the agreement between the room and its text.</p>')
        variants = [('Museum before correction',ARCHIVE/'before'/rel,False),('Museum after correction',ROOT/rel,False)]
        if (ARCHIVE/'pre-museum'/rel).exists():
            variants.insert(0,('Original grid before the museum',ARCHIVE/'pre-museum'/rel,True))
        parts.append('<div class="comparison">')
        for title,path,historical in variants:
            parts.append('<figure><figcaption>'+title+'</figcaption>'+drawing(read(path),name+' — '+title,historical)+'</figure>')
        parts.append('</div>')
    parts.append('''<h2 id="preserved">Nine rebuilt galleries, preserved</h2><div class="status review"><strong>Author’s decision: preserve the newer partitions.</strong><p>Confirmed by Palle during this audit. These rooms have substantially rebuilt layouts, and retain their current geometry. Preserving them does not claim that their full encounters or physical access have been tested.</p></div><ul>''')
    for e in report['maps']:
        if e['status'] == 'preserved-gallery':
            parts.append(f'<li><a href="/necklace/thread?map={quote(e["map"])}&amp;role=primary">{e["map"]}</a> — {len(e["interior_platform_cells"])} interior <code>2</code> cells retained in the current layout.</li>')
    parts.append('''</ul><h2>What the checks establish</h2><p>The 62 corrected maps retain all their artifacts, configuration tokens, utilities and dimensions. The route, primary roles, book order and text are unchanged. Four focused regression tests pass, and 1,606 cells are checked through the museum’s source deriver.</p>
<p>Before-and-after grid pathfinding finds no loss of previously reachable interior cells or exits, and no new construction-rule issue. This is an access non-regression check. It does not establish full access to every existing artifact or validate live museum gates, packing and physics.</p>
<p>The two cached plan copies receive narrow cell and support-height patches. Existing unrelated cache differences remain documented; two source-only artifact placements were not used to rewrite the cached arrangements.</p>
<p class="small">Runtime probe: <code>commons/testing/probe_sequence_platform_recovery.gd --spine</code>, after the occupied Godot instance closes. Start with Boolean_Verbs, then inspect the restored larger platforms and the active rooms. Source check: <code>python tools/recover_spine_platforms.py --check</code>.</p>
<h2 id="all-maps">Every sequence, every map</h2><label for="filter">Find a map, sequence or status</label><br><input id="filter" type="search" placeholder="For example: fractals or preserved" aria-describedby="filter-note"><p class="small" id="filter-note">202 maps. Open a sequence or type to reveal matching rows. “Already platforms” records existing source settings; it does not claim a runtime test.</p>''')
    for seq in report['spine_sequences']:
        rows = [e for e in report['maps'] if e['sequence'] == seq]
        counts = Counter(e['status'] for e in rows)
        parts.append(f'<details class="sequence"><summary>{seq} · {len(rows)} maps · {counts["recover"]} corrected</summary><div class="tablewrap"><table><thead><tr><th>Map</th><th>Route</th><th>Status</th><th>Interior 2</th></tr></thead><tbody>')
        for e in rows:
            status = LABELS[e['status']]
            search = html.escape(' '.join([seq,e['map'],status]).lower(), quote=True)
            parts.append(f'<tr data-search="{search}"><td><a href="/necklace/thread?map={quote(e["map"])}&amp;role=primary">{e["map"]}</a></td><td>{"Active" if e["active"] else "Extension"}</td><td>{status}</td><td>{len(e["interior_platform_cells"])}</td></tr>')
        parts.append('</tbody></table></div></details>')
    parts.append('''<p><a href="spine-platform-recovery.json">Detailed audit manifest</a> · Archive: <code>doc/space/spine-platform-recovery-2026-09-10/</code></p><p>The wave development brief remains W1: Pendulum and Sine Space. This audit supplies corrected geometry for later work without expanding that assignment.</p></main>
<script>document.querySelector('#filter').addEventListener('input',function(){const q=this.value.trim().toLowerCase();document.querySelectorAll('.sequence').forEach(section=>{let found=0;section.querySelectorAll('tbody tr').forEach(row=>{row.hidden=!row.dataset.search.includes(q);if(!row.hidden)found++;});section.hidden=found===0;if(q)section.open=true;else section.open=false;});});</script></body></html>''')
    write(OUT/'spine-recovery.html', ''.join(parts).encode('utf-8'))
    save_json(OUT/'spine-platform-recovery.json', report)
    print(json.dumps({'page':'spine-recovery.html','maps':len(report['maps']),'comparisons':4}))


if __name__ == '__main__':
    main()
