from pathlib import Path
import json, shutil, html, hashlib, re
import markdown

ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
for hall,names in {
    'Random_Entropies':['chair-reference','paired-chairs','guess-1','guess-2','guess-3','aerial'],
    'Random_Entropy':['four-jars','jar-1','jar-2','jar-3','jar-4'],
}.items():
    run=ROOT/'ada_run/encounter_pilot'/hall/'entropy-reading'
    for name in names:shutil.copy2(run/(name+'.png'),HERE/(name+'.png'))
    shutil.copy2(run/'report.json',HERE/(hall+'-report.json'))
reports=[json.loads((HERE/name).read_text(encoding='utf8')) for name in ['verification.json','Random_Entropies-report.json','Random_Entropy-report.json']]
assert all(r['passed'] and not r['failures'] for r in reports)
counts=[len(r['checks']) for r in reports]
STYLE='''*{box-sizing:border-box}body{margin:0;background:#eeeade;color:#283b3a;font:18px/1.6 system-ui,sans-serif}main{max-width:1420px;margin:auto;padding:32px}h1{font:clamp(36px,5vw,68px)/1.1 Georgia,serif}h2{font:32px/1.2 Georgia,serif}h3{font-size:22px}p{max-width:85ch}a{color:#17685d}nav{display:flex;gap:10px 24px;flex-wrap:wrap}section{margin:36px 0}figure{margin:0}img{display:block;width:100%;height:auto}figcaption{padding:12px;background:#dce2d4;font-size:16px}.grid{display:grid;grid-template-columns:1fr 1fr;gap:22px}.three{grid-template-columns:repeat(3,1fr)}.four{grid-template-columns:repeat(4,1fr)}.card{padding:22px;background:#dce2d4}.reading{max-width:1000px}table{width:100%;border-collapse:collapse;font-size:16px}td,th{padding:12px;text-align:left;border-bottom:1px solid #b1c0b4}pre{overflow:auto;background:#dce2d4;padding:18px}code{font-size:.9em}@media(max-width:900px){.grid,.three{grid-template-columns:1fr}.four{grid-template-columns:repeat(2,1fr)}main{padding:18px}}'''
NAV='<nav><a href="index.html">Two halls</a><a href="relationship.html">Curation decision</a><a href="types-final.html">Types final</a><a href="workshop-final.html">Workshop final</a><a href="types-tutorial.html">Types tutorial</a><a href="workshop-tutorial.html">Workshop tutorial</a></nav>'
def page(title,body,reading=False):
    return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+' · Ada Research</title><style>'+STYLE+'</style><main'+(' class="reading"' if reading else '')+'>'+NAV+body+'</main></html>'
def figure(name,caption):
    return f'<figure><img src="{name}.png" width="1600" height="1050" loading="lazy" alt="{html.escape(caption)}"><figcaption>{html.escape(caption)}</figcaption></figure>'
sources=[]
for hall,prefix in [('Random_Entropies','types'),('Random_Entropy','workshop')]:
    for name in ['final','tutorial','plan']:
        p=ROOT/'commons/maps'/hall/(name+'.md');sources.append(p)
        text=p.read_text(encoding='utf8');(HERE/(prefix+'-'+name+'.md')).write_text(text,encoding='utf8')
        text=text.replace('(relationship.md)','(relationship.html)').replace('(../Random_Entropy/relationship.md)','(relationship.html)')
        text=text.replace('](tutorial.md)',f']({prefix}-tutorial.html)').replace('](plan.md)',f']({prefix}-plan.html)')
        text=text.replace('](counts-and-neighbours.md)','](workshop-counts.html)')
        text=text.replace('](../../../doc/','](/book-review/doc/')
        (HERE/(prefix+'-'+name+'.html')).write_text(page(prefix.title()+' '+name,markdown.markdown(text,extensions=['tables','fenced_code','footnotes']),True),encoding='utf8')
p=ROOT/'commons/maps/Random_Entropy/counts-and-neighbours.md';sources.append(p)
(HERE/'workshop-counts.html').write_text(page('Counts and neighbours',markdown.markdown(p.read_text(encoding='utf8'),extensions=['tables','fenced_code']),True),encoding='utf8')
p=ROOT/'commons/maps/Random_Entropy/relationship.md';sources.append(p)
(HERE/'relationship.html').write_text(page('Two halls, two kinds of work',markdown.markdown(p.read_text(encoding='utf8'),extensions=['tables']),True),encoding='utf8')
body='''<h1>Two halls, two kinds of work</h1><p>Keep both maps. Condense the repeated explanation. Prepared comparisons establish which question an entropy answers; the workshop tests what its answer can miss.</p>
<section class="grid"><article class="card"><h2>Entropy Types</h2><p><b>Which question are we asking?</b></p><p>Chairs, recipes, doors, cups, glass and the safest colour guess. Versions stay visible together, with minimal interface.</p><p>Stable map: <code>Random_Entropies</code></p><a href="types-plan.html">Comparison plan</a></article><article class="card"><h2>Entropy Workshop</h2><p><b>What does the measure miss?</b></p><p>Keep a record while changing its arrangement. Compare jar observations, shake the live jar, reconstruct a compartment experiment, or preserve a new prefab hybrid.</p><p>Stable map: <code>Random_Entropy</code></p><a href="workshop-plan.html">Research plan</a></article></section>
<p><b>The handoff:</b> “We can now name the measurement. What can happen that it fails to register?”</p>
<section><h2>One chair before two questions</h2>'''+figure('chair-reference','A full-size specimen of the same chair model, mounted on a wall near the entrance to Entropy Types.')+'''</section>
<section><h2>Min-entropy: keep the question still</h2><p>Every tray asks for a colour. Imagine choosing one of sixteen balls with equal chance, then returning it. Only the colour counts change.</p><div class="grid three">'''+''.join(figure('guess-'+str(i+1),c) for i,c in enumerate(['8 pink / 8 teal: either guess wins half the chances. H-min = 1 bit.','12 pink / 4 teal: pink wins three quarters. H-min ≈ 0.415 bits.','16 pink: pink always wins. H-min = 0 bits.']))+'''</div><p>The lower reading belongs to the safer prediction. This follows the <a href="https://csrc.nist.gov/glossary/term/min_entropy">min-entropy definition</a>. Earlier number/colour/weighted-ticket records retain their original meaning, but that more complicated comparison is no longer installed.</p></section>
<section><h2>The jar becomes a research bridge</h2><p>These four prepared specimens are in the Workshop beside the original shakeable jar. They keep forty red and forty blue beads. Height reveals layers; core/rim reveals the shell arrangement. Changing the account can reveal order without moving anything.</p>'''+figure('four-jars','Four still configurations, seed 435. These are prepared comparisons, not frames from a physical mixing simulation.')+'<div class="grid four">'+''.join(figure('jar-'+str(i+1),c) for i,c in enumerate(['Layers','Overlapping interface','Mixed','Red core / blue shell']))+'''</div><p>The readings compare six height bands with two radial regions. They test two specified observations; this is not an isolated test of orientation or a heat measurement.</p></section>
<section><h2>Where the other artifacts belong</h2><p>The prefab investigation stays in the Workshop with KEEP, its seed gallery and replay. Compartments extend the chair comparison through interventions and reconstruction. Displaced points, the ruin and signal room offer questions about visual order, boundaries and neighbours. Butterflies and hardware decay remain optional: looking disordered alone does not earn another entropy definition. Point placements are unchanged.</p></section>
<section class="card"><h2>What would justify keeping two maps?</h2><p>After the first hall, can a visitor name the outcome and condition behind a reading? In the second, can they make a difference that the reading misses and use it to propose a change?</p><p>If the second visit only repeats a definition, shorten that passage or demote the encounter. If it produces a new experiment, the separation is doing useful work. Understanding remains an open visitor trial.</p></section>
<section><h2>Verified, and still open</h2><p>'''+f'{counts[0]} native apparatus checks; {counts[1]} Types room checks; {counts[2]} Workshop placement checks. Both pathfinder checks pass. These cover calculations, retained positions, reconstruction, supported approaches and native rendering. Headset comfort and learning are not inferred from them.'+'''</p><nav><a href="verification.json">Apparatus report</a><a href="Random_Entropies-report.json">Types room report</a><a href="Random_Entropy-report.json">Workshop room report</a><a href="manifest.json">Source fingerprints</a></nav><p>Restart the museum to load the revised scenes. Order remains Random Definition → Entropy Types → Entropy Workshop → Random Remove. The 48-value seed bench remains the first research pilot.</p></section>'''
(HERE/'index.html').write_text(page('Two entropy halls',body),encoding='utf8')
sources+=list((ROOT/'commons/artifacts/ordinary_entropies').glob('*.gd'))
sources += [ROOT/'commons/maps'/n/f for n in ['Random_Entropies','Random_Entropy'] for f in ['map_data.json','writing_wall.json']]
(HERE/'manifest.json').write_text(json.dumps({'checks':counts,'source_sha256':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}},indent=2),encoding='utf8')
(HERE/'README.md').write_text('''# Two related entropy halls

User-directed curation: retain Entropy Types as prepared comparisons and Entropy Workshop as investigations of what the readings omit. Add a full-size chair reference, simplify the installed min-entropy scene to one colour question, and add four prepared jar states beside the live jar in the workshop. Prefab investigation, gallery and replay remain; Point is unchanged. Historical coffee/glass and pit/ticket records remain intact.

Run `python -X utf8 doc/book/iterations/2026-10-16-entropy-reading/run.py`, then the two `tools/run_encounter_probe.py` commands with `--sequence randomness --render --no-bridges --output-tag entropy-reading`: Random_Entropies uses this folder's museum_probe.gd; Random_Entropy uses jar_probe.gd. Run each map's pathfinder and publish.py. The current reports record '''+str(counts)+''' passing checks. Native rendered views were inspected. A failed initial overview camera outside the workshop was moved onto its floor before publication; jar bases were seated on the shared tabletop. Model counts and snapshots are verified; headset and visitor comprehension remain pending.

Sieve: the jar offers a concrete relation between an arrangement and the observation that reveals it. Prepared versions give up spontaneous dynamics; the adjacent live jar supplies a distinct intervention. The question left open is whether the chosen records help a visitor discover another account, rather than merely rehearse the displayed readings.
''',encoding='utf8')
print('Published',counts)
