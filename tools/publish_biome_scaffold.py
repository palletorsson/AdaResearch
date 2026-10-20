"""Publish a source-backed expansion plan. Does not edit or launch museum code.

Edit doc/plans/biome-ladder/SCAFFOLD.json, then run this file. The audit is
structural/source evidence, not a claim that proposed arena stages are playable.
"""
from __future__ import annotations

import hashlib
import html
import json
from pathlib import Path
import re
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/plans/biome-ladder'
PUBLIC = ROOT.parent / 'ada_encyclopedia/public/biome-plan'
BATCHES = {
    'A': ('01–05', 'Make the existing route dependable'),
    'B': ('06–11', 'A ground that directs and carries'),
    'C': ('12–16', 'Surface rules become living structure'),
    'D': ('17–20', 'Bodies change and negotiate'),
    'E': ('21–25', 'Connections, learning and limits'),
}
LABELS = {'playable': 'Playable prototype', 'user-direction': 'Agreed direction · not built', 'proposal': 'Proposal · not built'}


def read(path):
    return json.loads((ROOT / path).read_text(encoding='utf-8-sig'))


def audit(plan):
    spine = read('commons/maps/curriculum_spine.json')['spine']['sequences']
    names = [s['name'] for s in spine]
    rows = plan['stages']
    assert [r['sequence'] for r in rows] == names, 'Plan must follow the current canonical spine exactly.'
    assert len(set(names)) == len(names)
    for row in rows:
        assert row['status'] in LABELS and row['batch'] in BATCHES
        for key in ['operation', 'world', 'catalyst', 'counterpart', 'reuse', 'next_work', 'acceptance']:
            assert row[key].strip(), (row['sequence'], key)
        for source in row['sources']:
            assert (ROOT / source).is_file(), source
    paths = sorted(set(p for r in rows for p in r['sources']))
    route = (ROOT / 'commons/hazards/biome_ladder/route.gd').read_text(encoding='utf-8')
    built = re.findall(r'\{"sequence": "([^"]+)"', route)
    assert [r['sequence'] for r in rows if r['status'] == 'playable'] == built
    vocab = read('commons/data/biome_vocabulary.json')
    authored = read('commons/data/map_authored.json')
    authored_halls = {h for seq in names for h in authored.get(seq, [])}
    soft = read('commons/maps/soft_stages.json')['stages']
    contributions = read('commons/biome_layers/biome_contributions.json')['sequences']
    orders = {s['name']: s['order'] for s in spine}
    order_differences = [dict(sequence=s, spine=orders[s], soft_stages=soft.get(s, {}).get('order'))
                         for s in names if orders[s] != soft.get(s, {}).get('order')]
    boundaries = []
    for name in names:
        spec = read(f'commons/maps/sequences/{name}.json')['sequences'][name]
        halls = spec.get('maps', [])
        boundaries.append({'sequence': name, 'sequence_first': halls[0] if halls else None,
                           'sequence_last': halls[-1] if halls else None,
                           'authored_last': authored.get(name, [None])[-1]})
    return {
        'date': plan['date'],
        'evidence_level': 'Source inspection and structural checks only. No new arena runtime or headset tests in this planning pass.',
        'sequence_count': len(rows), 'playable_sequences': built,
        'referenced_source_count': len(paths),
        'missing_sequence_vocabulary': [s for s in names if s not in vocab['sequences']],
        'vocabulary_halls_outside_current_authored_spine': [h for h in vocab['halls'] if h not in authored_halls],
        'soft_stage_order_differences': order_differences,
        'contribution_orders': [{'sequence': e['seq'], 'kind': e['kind'], 'legacy_order': e['order'],
                                'spine_order': orders.get(e['seq'])} for e in contributions],
        'boundaries_for_review_not_automatic_route_changes': boundaries,
        'source_sha256': {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in paths},
        'checks': ['All 25 canonical sequence keys appear once, in current order.',
                   'Every source reference exists.', 'All required proposal fields are nonempty.',
                   'Only stages present in the actual route are labelled playable.'],
    }


INTRO = """# Building out of the existing biome ladder

13 October 2026. Source-backed expansion plan for the current 25-sequence spine.
Six arena stages exist, through Change. B20/B21 runtime evidence is in CHANGE.md; this publisher audits the plan structure only.
The later rows below are scaffolds, not newly playable maps or revised book lessons.

## What the older work gives us

1. **Cumulative vocabulary.** `commons/biome_layers/biome_grammar.gd` reads the canonical spine and `map_authored.json`; `commons/data/biome_vocabulary.json` supplies made-of / does / knows. The old Biome_Ladder_Primitives, Transformation, Color and Randomness halls display these additions through `biome_vitrine.gd`. They are display encounters, not the new combat route.
2. **One seed, several states of a world.** Generation 17 of `commons/artifacts/biome_object/biome_object.gd` has stage and phase gates, a sampled ground, water, rocks, vegetation and resident placement. It can reveal layers gradually. Its `full` state is the mature habitat, not the proper default for every early arena. The old phase knob mixes the words arriving at a stage; it does not automatically make every curriculum operation into gameplay.
3. **Actual continuity of objects.** `biome_inheritance.gd` and `rising_banners.gd` retain panel IDs, bodies and their record while translating, rotating, scaling and colouring them. The later habitat reads their footprints to keep vegetation clear. That is a stronger reuse seam than replacing the whole scene after each sequence. This bridge currently expects its own panel encounter, not arbitrary arena cover; an adapter is still needed.
4. **Walkable surfaces.** `TopologySpace.gd` builds geometry and collision from heights. SineSpace, RandomSpace and NoiseSpace already implement the three floor ideas Palle requested. `biome_ground_substrate.gd` adds a paint texture over a sampled field. They need arena-sized sampling, retained surface addresses and safe placements; a scene instance alone is not the integration.
5. **A shared play shell.** The new ladder already owns the XR/desktop player, catalyst, hit/death/reset paths, cover, tile records, six stage choices and museum handoffs. Keep that shell and adapt these older components into it.

## Where the sources need care

- **Three sources describe different things.** Canonical spine order names the curriculum. BiomeGrammar names cumulative vocabulary. soft_stages and biome_contributions still contain older numeric orders and some different gates. An old number is not a current stage index. Tiling and Form-finding lack soft_stages entries; Shaders lacks a biome_vocabulary sequence entry. Preserve other consumers while introducing an explicit translation or migration.
- **Vocabulary is not implementation.** The mature BiomeObject consumes a subset of the grammar words. Merely setting its stage to Change, Waves or Shaders does not construct those arena behaviours. `connect` and `absent`, for example, are recorded without a dedicated world layer in that object.
- **Some old layer names overstate behaviour.** force_field draws arrows; swarm_creatures follows predetermined orbits; adaptive_behavior pulses halos; tunable_field builds static dial indicators; critical_overlay draws a tinted dome. ca_surface computes real CA generations at build time, then displays a static field. These are useful visual parts, but cannot certify force integration, neighbour-driven swarming, learning, live tuning, measured bias or ongoing CA respectively. Reuse the actual corresponding algorithm where the stage requires it.
- **The earlier Tiling obstruction is fixed in B20.** The new probe reproduces it, then reaches all 14 controls with the fix. B19 exposes the nine-head array; B20 signals matching tiles together. Independent review of the updated full route and physical headset acceptance remain open. See CHANGE.md.
- **Hall boundaries need explicit decisions.** Authored lists include some Biome_Ladder display rooms after the teaching halls. The current playable route deliberately uses Trans_Pit and Color_Walls, not the final item of those authored lists. Noise's sequence file ends at Lab_Path while its authored list ends at Noise_Perlin_Simplex; that discrepancy needs resolving before its arena handoff is built. Do not generate new exits blindly from `map_authored[-1]`. Check actual sequence routes, current runtime boundaries and intended placement together.

## The scaffold to implement

Use **one record for each stage**, keyed by sequence name, with inherited capabilities, one featured operation, source adapters, surface policy, counterpart response, museum entry/return and acceptance evidence. SCAFFOLD.json is a review record for this purpose; the runtime does not read it yet. Do not make a second authoritative copy of spine order.

Keep the same catalyst, landmark IDs and floor addresses. Add an arena-owned state record for seed, tile hit count, colour, motif, field values and entity IDs. Separate the record from its rendering so a flat tile address still refers to the same place on a sine or noise surface. Existing run state currently resets on stage exit: continuity of available abilities is implemented, but transporting the player's exact floor edits into another stage is a new decision and implementation task. Proposed default: carry edits on NEXT STAGE; RESET restores the current stage's explicit baseline; standalone selection begins with its documented fixture. This default is not applied by this report.

Give the surface adapter world-to-address and height sampling, one render/collision revision, and the impact receiver. Reuse a single terrain builder per stage; avoid layering the old full accrual stack under the new floor. Retained cover needs both ground placement and verified collision: mature plants or stones are not automatically cover because they look solid. The white outlined primitive floor and its fixed refuge remain the starting contract.

Capabilities accumulate; workload need not. Keep earlier actions available but cap active heads, branches, terrain updates and particles, and activate expensive modules only where needed. This preserves a readable new operation and a playable frame budget. Later stages can turn a counterpart into a source, guide or companion; progression need not mean an endlessly stronger enemy.

## First implementation group

**A0 — repair and clarify the five-stage route.** Make all 13 controls reachable after transformed floor hits; keep projectile contact accurate. Expose the Arrays row, put the stage rule where it can be read, and signal all motif copies together. Rerun Claude's route test and the existing hit/cover/tiling checks after the relevant changes.

**B0 — connect the existing systems through a small adapter.** Reuse BiomeGrammar as the cumulative vocabulary source, and current spine keys as order. Preserve existing route behavior first. Add a surface/receiver interface at the current flat-floor seam, with stable addresses. Keep old consumers intact and document any gate translation. This makes later additions smaller instead of accumulating more `stage >= n` branches.

**B1 — Change, then Forces.** Start with the floor-steers proposal, corrected to prescribed velocity: `position += direction(position) * speed * delta`. Its integral is a trajectory; it has no retained inertial velocity yet. Forces then introduces `velocity += acceleration * delta`, mass and impulse. Claude's proposed velocity-gains-a-push version belongs at that second step. Both versions must keep arrows and motion tied to the same declared sampler. The existing noisy hall sampler is supplied machinery at Change; it is not an early Noise terrain unlock.

**B2 — Form-finding, then the terrain trio.** Add one explicit optimisation problem, then adapt SineSpace → seeded static RandomSpace → correlated NoiseSpace. Compare the last two using fixed footprint, controlled range and recorded neighbour-difference measurements. Preserve earlier paint, transform and tiling operations. Start with static terrain; moving collision under the player's feet is a separate feature.

This gives us a bounded next group ending at Noise, with later work organised into C (Shaders–Procedural Generation), D (Soft Bodies–Swarm) and E (Graphs–Post-foundations). A scaffold for all 25 sequences is useful now; marking all 25 playable would not be true.

## Per-stage acceptance

For every implemented addition, check: the new subject makes an observable difference; earlier selected actions still work; shots, cover and feet agree with collision; the seed/reset policy is reproducible; NEXT STAGE and MUSEUM go to the intended place; an actual standing-height capture shows the relation. Add an appropriate numerical or behavioural assertion for the new rule. Record hardware/backend and frame cost; desktop checks do not certify Quest comfort.

The audit accompanying this document validates order, source links and planning completeness only. It does not execute these proposed interactions. Claude's latest route findings and the previous B16 runtime evidence remain separate records.

## Sequence cards

Edit `doc/plans/biome-ladder/SCAFFOLD.json`, then run `python -X utf8 tools/publish_biome_scaffold.py`. The generated Markdown and page follow that file. Share `http://localhost:3003/biome-plan/scaffold.html` and SCAFFOLD.json with Claude; claim a small task and its files before editing. No forum message was sent in this pass.
"""


def publish():
    plan = read('doc/plans/biome-ladder/SCAFFOLD.json')
    evidence = audit(plan)
    (OUT / 'scaffold-audit.json').write_text(json.dumps(evidence, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    markdown = [INTRO]
    cards = []
    esc = html.escape
    for i, row in enumerate(plan['stages'], 1):
        markdown.append(f"\n### {i:02d}. {row['title']} — {LABELS[row['status']]}\n\n**{row['operation']}**\n")
        if 'changes' in row:
            markdown.append('\n**Current change list:**\n' + '\n'.join('- ' + c for c in row['changes']) + '\n')
        for key, label in [('world', 'World'), ('catalyst', 'Catalyst'), ('counterpart', 'Counterpart'),
                           ('reuse', 'Reuse'), ('next_work', 'Work remaining'), ('acceptance', 'Acceptance')]:
            markdown.append(f"\n- **{label}:** {row[key]}")
        markdown.append('\n- **Sources:** ' + '; '.join('`' + p + '`' for p in row['sources']) + '\n')
        details = ''.join(f'<div><h4>{label}</h4><p>{esc(row[key])}</p></div>' for key, label in
                          [('world', 'World'), ('catalyst', 'Catalyst'), ('counterpart', 'Counterpart')])
        source_list = ''.join(f'<li><code>{esc(s)}</code></li>' for s in row['sources'])
        cards.append(f'''<article class="card" id="{row['sequence']}" data-status="{row['status']}" data-batch="{row['batch']}">
<div class="top"><span class="number">{i:02d}</span><span class="status {row['status']}">{LABELS[row['status']]}</span></div>
<h3>{esc(row['title'])}</h3><p class="operation">{esc(row['operation'])}</p>{details}
<div class="reuse"><h4>What we can reuse</h4><p>{esc(row['reuse'])}</p></div>
<details><summary>Implementation seam + acceptance</summary><h4>Work remaining</h4><p>{esc(row['next_work'])}</p><h4>What must pass</h4><p>{esc(row['acceptance'])}</p><h4>Source files inspected or identified</h4><ul class="sources">{source_list}</ul></details>
</article>''')
    (OUT / 'SCAFFOLD.md').write_text('\n'.join(markdown), encoding='utf-8')
    batch_links = ''.join(f'<button data-batch="{k}"><small>{v[0]}</small>{esc(v[1])}</button>' for k, v in BATCHES.items())
    template = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Biome ladder · the larger scaffold</title><style>
:root{font-family:system-ui,sans-serif;color:#202723;background:#f4f1e9;font-size:16px;line-height:1.55}*{box-sizing:border-box}body{margin:0}main,header,footer{max-width:1440px;margin:auto;padding:32px 5vw}header{padding-top:58px}h1{font:clamp(38px,5vw,70px)/1.04 Georgia,serif;max-width:900px;margin:20px 0}h2{font:32px/1.15 Georgia,serif}h3{font:28px/1.15 Georgia,serif;margin:12px 0}p{margin:.6em 0 1em}a{color:#245d55;text-underline-offset:4px}nav{display:flex;flex-wrap:wrap;gap:12px 24px}.eyebrow,h4{font-size:12px;letter-spacing:.07em;text-transform:uppercase}h4{margin:14px 0 3px;color:#54625b}.lead{font-size:21px;max-width:850px}.notice{border-left:3px solid #bc8053;padding:14px 20px;background:#eae3d8;margin:25px 0}.evidence{display:grid;grid-template-columns:1fr 1fr;gap:24px}figure{margin:0}figure img{width:100%;height:310px;object-fit:contain;background:#181b20}figcaption{font-size:13px;color:#52615b;margin-top:7px}.systems{display:grid;grid-template-columns:repeat(3,1fr);gap:24px;margin:32px 0}.systems div{border-top:1px solid #abb4aa;padding-top:14px}.systems b{display:block;margin-bottom:8px}.bands{display:grid;grid-template-columns:repeat(5,1fr);gap:10px;margin:22px 0}button,input{font:inherit;border:1px solid #9eaaa0;border-radius:3px;padding:10px 15px;background:#fffdf7;color:inherit}button{cursor:pointer;text-align:left}button:hover,button[aria-pressed=true]{background:#294f45;color:white}button small{display:block;opacity:.75}label{display:flex;gap:8px;align-items:center}.filters{display:flex;align-items:center;flex-wrap:wrap;gap:12px;margin-bottom:24px}input{max-width:100%;width:270px}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:20px;align-items:start}.card{background:#fffdf7;border:1px solid #c5cbbf;padding:22px;scroll-margin-top:24px}.top{display:flex;justify-content:space-between;gap:12px;align-items:center}.number{font:30px Georgia;color:#94a19a}.status{font-size:11px;padding:5px 8px;background:#eae5dc}.playable{background:#d8e9d7}.user-direction{background:#e8e1bb}.operation{font-size:18px;font-weight:600}.reuse{border-top:1px solid #ddd;padding-top:4px}details{margin-top:16px}summary{cursor:pointer;color:#2c6556}code{font-size:11px;overflow-wrap:anywhere}.sources{padding-left:14px}li{margin-bottom:8px}.actions{max-width:1000px}.actions li{margin-bottom:14px}footer{color:#647369;border-top:1px solid #bbb;font-size:13px}[hidden]{display:none!important}@media(max-width:1050px){.grid{grid-template-columns:repeat(2,minmax(0,1fr))}.bands{grid-template-columns:repeat(3,1fr)}}@media(max-width:680px){main,header,footer{padding:24px}.grid,.evidence,.systems{grid-template-columns:1fr}.bands{grid-template-columns:1fr 1fr}figure img{height:250px}}@media print{.filters,.bands,nav{display:none}.grid{display:block}.card{break-inside:avoid;margin-bottom:15px}details{display:block}figure img{height:200px}}
</style></head><body><header><div class="eyebrow">Endless Museum · source review · 13 October 2026</div><h1>One world.<br>A longer memory.</h1><p class="lead">The earlier biome already knows how to accumulate forms, preserve a seed and carry objects into a growing landscape. The arena can build on that work.</p><nav><a href="index.html">Six playable stages</a><a href="SCAFFOLD.md">Full report</a><a href="SCAFFOLD.json" download>Editable plan · JSON</a><a href="scaffold-audit.json">Source audit</a><a href="CLAUDE-REVIEW.md">Claude’s route review</a></nav><div class="notice"><b>25 sequences mapped. Six arena stages built.</b> Later cards distinguish agreed directions from proposals. These are implementation scaffolds, not new screenshots or playable stages. No museum, tutorial or final.md logic changed in this review.</div></header><main>
<section class="evidence"><figure><img src="cover-after.png" alt="Existing native Godot capture of the primitive arena and its geometric cover"><figcaption>Existing arena · white floor, thin outlines, cover and a route. The starting contract remains.</figcaption></figure><figure><img src="scaffold-existing-gen17.png" alt="Existing generation-17 Godot capture of the seeded biome with terrain, a pool, vegetation and rocks"><figcaption>Existing generation 17 · seed 7, moisture .5, relief .5, wildness .6. A reusable mature habitat; not a capture of the proposed expansion.</figcaption></figure></section>
<section class="systems"><div><b>Vocabulary</b>BiomeGrammar follows the actual spine and accumulates what a world may be made of, do and know.</div><div><b>Identity</b>The inheritance study retains the same panels, bodies and record as their transforms and habitat change.</div><div><b>Physical ground</b>Walkgrids already build sine, random and noise meshes with collision. The task is to connect them to the existing play shell.</div></section>
<section class="actions"><h2>What to do first</h2><ol><li><b>Make the five-stage route dependable.</b> B20 fixes the turned Tiling slab obstruction and tests all 14 controls; <a href="change.html#tiling">see the result</a>. B19 now exposes all nine Arrays places and builds row/column volleys: <a href="arrays.html">see the implementation</a>. Motif feedback remains a separate refinement.</li><li><b>Join the records, not the entire generators.</b> Use current sequence keys and cumulative capabilities. Add stable surface addresses, a shared sampler and an impact receiver. Keep one floor builder active per stage.</li><li><b>Continue from Change toward Noise.</b> Change now has field-guided position updates and one announced turn. Next: mass and impulse → a bounded search for form → walkable sine → seeded rough ground → correlated terrain.</li></ol><p><b>One important correction:</b> Change’s current hall prescribes motion through a sampled direction field. A push that accumulates into velocity belongs in Forces. The difference should be visible in play.</p><details><summary>Known gaps in the old scaffold</summary><p>Older numeric unlock tables differ from the current spine; Tiling and Form-finding have no soft_stages entries; Shaders has no biome-vocabulary entry. A declared vocabulary word does not prove a corresponding world behaviour exists.</p><p>Some legacy layers are visual stand-ins: orbiting “swarm” shapes, a pulsing “learning” halo, static QFEP indicators and a tinted “bias” dome. The plan points to real algorithm candidates or marks the missing implementation.</p><p>Exact floor edits currently reset when changing stage. Carrying that personal state into the next biome is proposed here, separate from the already inherited abilities. The mature habitat’s attractive objects also need verified colliders before they count as cover.</p></details></section>
<section id="route"><h2>The route, one addition at a time</h2><p>Every card keeps earlier capacities available. Each stage foregrounds one operation; it does not run every accumulated system at full density.</p><div class="bands">__BATCHES__</div><div class="filters"><button id="all" aria-pressed="true">All 25</button><button data-status="playable">Playable</button><button data-status="user-direction">Agreed direction</button><button data-status="proposal">Proposed</button><label>Find <input id="search" type="search" placeholder="e.g. ground, catalyst, noise"></label><span id="count" role="status"></span></div><div class="grid">__CARDS__</div></section>
</main><footer>Scope: source inspection and planning. Existing captures reused and labelled. __COUNT__ source files exist and are hashed in the audit; no new runtime or headset test is claimed. Edit SCAFFOLD.json, then run tools/publish_biome_scaffold.py to regenerate this report.</footer>
<script>let batch='',status='';const cards=[...document.querySelectorAll('.card')];function filter(){const q=document.getElementById('search').value.toLowerCase();let n=0;for(const c of cards){c.hidden=!!((batch&&c.dataset.batch!==batch)||(status&&c.dataset.status!==status)||!c.textContent.toLowerCase().includes(q));if(!c.hidden)n++}document.getElementById('count').textContent=n+' sequences shown';for(const b of document.querySelectorAll('button[data-batch]'))b.setAttribute('aria-pressed',String(b.dataset.batch===batch));for(const b of document.querySelectorAll('button[data-status]'))b.setAttribute('aria-pressed',String(b.dataset.status===status));document.getElementById('all').setAttribute('aria-pressed',String(!batch&&!status&&!q))}for(const b of document.querySelectorAll('button[data-batch]'))b.onclick=()=>{batch=b.dataset.batch;status='';filter()};for(const b of document.querySelectorAll('button[data-status]'))b.onclick=()=>{status=b.dataset.status;batch='';filter()};document.getElementById('all').onclick=()=>{batch=status='';document.getElementById('search').value='';filter()};document.getElementById('search').oninput=filter;filter();</script></body></html>'''
    page = template.replace('__BATCHES__', batch_links).replace('__CARDS__', '\n'.join(cards)).replace('__COUNT__', str(evidence['referenced_source_count']))
    (OUT / 'scaffold-detail.html').write_text(page, encoding='utf-8')
    editor = (ROOT / 'tools/biome_changes.html').read_text(encoding='utf-8')
    minimal = {'stages': [{k: row[k] for k in ['sequence', 'title', 'status', 'changes']} for row in plan['stages']]}
    initial = json.dumps(minimal, ensure_ascii=False).replace('<', '\\u003c')
    (OUT / 'scaffold.html').write_text(editor.replace('__INITIAL__', initial), encoding='utf-8')
    shutil.copy2(ROOT / 'ada_run/biome_rsi/gen_17/s7_m50_r50_w60.png', OUT / 'scaffold-existing-gen17.png')
    PUBLIC.mkdir(parents=True, exist_ok=True)
    for name in ['SCAFFOLD.json', 'SCAFFOLD.md', 'scaffold-audit.json', 'scaffold.html', 'scaffold-detail.html', 'scaffold-existing-gen17.png', 'cover-after.png']:
        shutil.copy2(OUT / name, PUBLIC / name)
    print(json.dumps({'sequences': evidence['sequence_count'], 'source_files': evidence['referenced_source_count'],
                      'playable': len(evidence['playable_sequences']), 'missing_vocab': evidence['missing_sequence_vocabulary'],
                      'page': str(OUT / 'scaffold.html')}, indent=2))


if __name__ == '__main__':
    publish()
