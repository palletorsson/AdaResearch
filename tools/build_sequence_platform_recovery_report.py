"""Publish a source-data comparison of the three-sequence platform correction."""
from pathlib import Path
import html
import json

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / 'doc/space/sequence-platform-recovery-2026-09-10'
OUT = ROOT / 'doc/research/waves-chance-noise'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def drawing(doc, title, historical=False):
    rows = doc['layers']['structure']
    w, h = max(map(len, rows)), len(rows)
    threshold = int(doc['map_info'].get('museum', {}).get('wall_height', 2))
    parts = [f'<svg role="img" aria-label="{html.escape(title)}" viewBox="0 0 {w*18} {h*18}" xmlns="http://www.w3.org/2000/svg">',
             f'<title>{html.escape(title)}</title>']
    for z,row in enumerate(rows):
        for x,raw in enumerate(row):
            value = str(raw).strip()
            n = int(value) if value.isdigit() else 0
            if historical:
                fill = '#d2ac61' if value == '2' else '#64555d' if n >= 3 or value == 'w' else '#ece7df' if n == 1 else '#ffffff'
            else:
                fill = '#64555d' if value == 'w' or n >= threshold else '#d2ac61' if value == '2' else '#ece7df' if n == 1 else '#ffffff'
            parts.append(f'<rect x="{x*18}" y="{z*18}" width="18" height="18" fill="{fill}" stroke="#c6bdb2" stroke-width=".5"><title>({x},{z}): {html.escape(value)}</title></rect>')
            if value == '2':
                parts.append(f'<text x="{x*18+9}" y="{z*18+12}" text-anchor="middle" font-family="sans-serif" font-size="9" fill="{"#fff" if fill == "#64555d" else "#292326"}">2</text>')
    for z,row in enumerate(doc['layers'].get('utilities', [])):
        for x,raw in enumerate(row):
            token = str(raw).strip().split(':')[0]
            if x < w and z < h and token in ['s','t']:
                parts.append(f'<circle cx="{x*18+9}" cy="{z*18+9}" r="7" fill="{"#26756d" if token == "s" else "#8b2855"}"/><text x="{x*18+9}" y="{z*18+12}" text-anchor="middle" font-family="sans-serif" font-size="10" fill="white">{token.upper()}</text>')
    return ''.join(parts) + '</svg>'


def main():
    r = read(ARCHIVE / 'recovery.json')
    summaries = []
    for key,label in [('randomness','Randomness'), ('noise','Noise'), ('cellularautomata','Cellular Automata')]:
        entries = [e for e in r['maps'] if e['sequence'] == key]
        summaries.append({'key':key,'label':label,'audited':len(entries),
            'changed':sum(e['changed'] for e in entries),
            'platforms':sum(len(e['newly_platform_cells']) for e in entries),
            'walls':sum(len(e['perimeter_2_to_w']) for e in entries)})
    parts = ['''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Platforms across three sequences · Ada Research</title>
<style>*{box-sizing:border-box}body{margin:0;background:#f4f0e8;color:#24272b;font:17px/1.65 system-ui,sans-serif}main{max-width:1080px;margin:auto;padding:32px 24px 70px}a{color:#8b2855;text-underline-offset:3px}h1{font:clamp(40px,6vw,70px)/1.06 Georgia,serif;max-width:880px}h2{font:30px/1.2 Georgia,serif}h3{font:24px/1.3 Georgia,serif}p{max-width:920px}.small,figcaption{font-size:14px;color:#5e5b62}.status{border-left:5px solid #8b2855;background:#fffaf5;padding:16px 22px}.cards,.comparison{display:grid;grid-template-columns:repeat(3,1fr);gap:18px;margin:24px 0}.card,figure{margin:0;background:#fffcf5;padding:16px;border:1px solid #d8cfc7;border-radius:6px}.card strong{display:block;font:36px Georgia,serif}.comparison{align-items:start}svg{display:block;width:100%;max-height:430px;margin-top:14px}figcaption{min-height:48px}.legend{display:flex;gap:20px;flex-wrap:wrap}.key:before{content:"";display:inline-block;width:14px;height:14px;background:var(--c);margin-right:6px}table{border-collapse:collapse;width:100%;font-size:14px}td,th{padding:9px 5px;text-align:left;border-bottom:1px solid #d8cfc7}td:first-child{overflow-wrap:anywhere}details{margin:22px 0}summary{cursor:pointer;font-weight:600}code{font-size:14px;overflow-wrap:anywhere}li{margin:8px 0}@media(max-width:690px){main{padding:22px 16px 50px}.cards,.comparison{grid-template-columns:1fr}svg{max-height:350px}.comparison figure{max-width:440px;width:100%;margin:auto}}</style></head><body><main>
<nav><a href="index.html">← Waves, Randomness and Noise guide</a> · <a href="recovery.html">Earlier wave recovery</a> · <a href="spine-recovery.html">Whole-spine follow-up</a></nav><p class="small">Ada Research · 10 September 2026 · source structure recovery</p>
<h1>The same number had become two different spaces.</h1>
<p>A grid <code>2</code> builds a stack with a deck one metre above the floor. The default museum conversion read it as a wall. The same fault appeared in Randomness, Noise and one Cellular Automata room.</p>
<div class="status"><strong>17 maps corrected across 31 audited maps.</strong><p>294 existing interior cells now derive as platforms. 255 boundary cells are explicit walls. Ten corrected maps are on the active route; seven remain extensions. Source checks pass; the physical museum probe is prepared and has not run while Godot is occupied.</p></div><div class="cards">''']
    for s in summaries:
        parts.append(f'<div class="card"><strong>{s["changed"]} / {s["audited"]}</strong>{s["label"]} maps corrected<p>{s["platforms"]} interior cells restored<br>{s["walls"]} boundary walls made explicit</p></div>')
    parts.append('''</div><h2>What the correction preserves</h2><p>Current artifacts and their configuration tokens stay at their cells. The main route stays the same. Interior <code>2</code> remains numeric; affected maps use <code>museum.wall_height: 3</code>, and perimeter <code>2</code> becomes <code>w</code>. Gates for the recovered platform rooms sit at the outside doorway. Existing holes and taller structures remain, with one added exit landing described below.</p>
<p>Random_Definition already had the correction. The rebuilt Noise_Perlin_Simplex has no remaining <code>2</code> cells. Seven of the eight Cellular Automata maps have none, so their geometry was left alone.</p>
<h2>Compare the source layouts</h2><p class="small">Top-down diagrams generated from archived JSON and the current maps. These are source interpretations, not runtime captures. The older grids can have different dimensions because the museum conversion expanded or shifted them. Hover a cell for its coordinates and source value.</p>
<div class="legend small"><span class="key" style="--c:#d2ac61">Height-2 stack / restored platform</span><span class="key" style="--c:#64555d">Wall / taller structure</span><span class="key" style="--c:#ece7df">Floor</span><span class="key" style="--c:#fff">Void</span></div>''')
    for name in ['Random_Walk','Noise_Columns','CA_GameOfLife']:
        rel = Path('commons/maps') / name / 'map_data.json'
        parts.append(f'<h3>{name}</h3><div class="comparison">')
        for label,path,historical in [('Before the museum: original grid', ARCHIVE/'pre-museum'/rel,True),
                                      ('Museum interpretation before this correction',ARCHIVE/'before'/rel,False),
                                      ('Museum interpretation after correction',ROOT/rel,False)]:
            parts.append('<figure><figcaption>'+label+'</figcaption>'+drawing(read(path),name+' — '+label,historical)+'</figure>')
        parts.append('</div>')
    parts.append('''<h2>Three access repairs the comparison revealed</h2><ul><li><b>Random_Mushrooms:</b> moved the spawn from corner (0,0) onto existing interior floor at (1,1). The old arrival depended on descending over the border that is now a wall.</li><li><b>Randomness_Examples_of_Randomness:</b> moved the corner spawn to existing floor at (1,1); the spawn's former cell is now an explicit wall.</li><li><b>Noise_Inside_Noise:</b> added one height-2 landing at (7,11), immediately before the unchanged exit at (7,12). The old route approached over a cell on the outer border.</li></ul>
<p>After those repairs, every previously reachable teleporter and interior cell remains reachable in the static checker. Border cells that now represent walls are no longer counted as usable routes.</p>
<h2>Evidence and remaining work</h2><ul><li>The persistent geometry check verifies 550 cells across the 17 changed maps, including the extra landing.</li><li>All 17 maps pass the construction-rule check; all their artifact references resolve. Before/after checks catch losses that the headline “OK” alone does not.</li><li>Nine active plan rows were refreshed for geometry, support height and gate depth. Other plan rows and all artifact curation were preserved.</li><li>The ten-room physical probe is prepared. It checks platform tops, boundaries and gates in the actual museum; no new runtime or headset result is claimed here.</li></ul>
<p>Some maps retain limited static reachability from before this repair. Their full encounters and dynamic routes still need a walk. Existing plan-cache drift in Random_Remove and Noise_Perlin_Simplex was recorded and was not used to overwrite their current layouts.</p>
<h2>Every audited map</h2>''')
    for s in summaries:
        parts.append(f'<details><summary>{s["label"]} · {s["changed"]} corrected / {s["audited"]} inspected</summary><table><thead><tr><th>Map</th><th>Route</th><th>Restored cells</th><th>Boundary cells</th><th>Status</th></tr></thead><tbody>')
        for e in (e for e in r['maps'] if e['sequence']==s['key']):
            status = 'Corrected' if e['changed'] else 'Already correct' if e['interior_platform_cells'] else 'No 2 cells'
            parts.append(f'<tr><td><a href="/museum-progress?sequence={e["sequence"]}&amp;room={e["map"]}">{e["map"]}</a></td><td>{"Active" if e["active"] else "Extension"}</td><td>{len(e["newly_platform_cells"])}</td><td>{len(e["perimeter_2_to_w"])}</td><td>{status}</td></tr>')
        parts.append('</tbody></table></details>')
    parts.append('''<p>Exact before-copies and both historical snapshots: <code>doc/space/sequence-platform-recovery-2026-09-10/</code>. The two historical revisions precede the first museum commit and the later source-map rewrite. No current map was replaced wholesale.</p>
<p>Source check: <code>python tools/recover_sequence_platforms.py --check</code>. Runtime probe: <code>commons/testing/probe_sequence_platform_recovery.gd</code>. <a href="sequence-platform-recovery.json">Detailed recovery manifest</a>.</p><p><a href="NEXT_BATCH.md">Claude's current two-hall development brief →</a></p></main></body></html>''')
    (OUT/'structure-recovery.html').write_text(''.join(parts),encoding='utf-8')
    (OUT/'sequence-platform-recovery.json').write_text(json.dumps(r,indent=2),encoding='utf-8')
    print(json.dumps({'page':'structure-recovery.html','maps':len(r['maps']),'diagram_groups':3}))


if __name__ == '__main__':
    main()
