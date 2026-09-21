"""Publish the agreed learning arc from the actual route and existing collection."""
from pathlib import Path
import hashlib, html, json, shutil

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/research/possible-bodies'
EVIDENCE=ROOT/'doc/space/fractal-arc-2026-09-14'
REVIEW=ROOT/'ada_run/fractal-arc-review-2026-09-14'

def load(p):return json.loads(p.read_text(encoding='utf-8'))
def save(p,s):
    p.parent.mkdir(parents=True,exist_ok=True)
    tmp=p.with_name(p.name+'.arc-tmp');tmp.write_bytes(s.encode('utf-8'));tmp.replace(p)
def dump(p,d):save(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')

STEPS=[
('Fractal_Recursion','A rule calls again','Repeat within a form, then branch.',
 'From CA: a held beginning, an explicit update and attention to what a difference can retain.',
 'What is passed into another call, and what makes it stop?',
 'Four reachable desks compare one self-call, four self-calls, selected subdivision and an authored chair. Add levels, rearrange, change packing, choose where to split, and reveal excluded cells. All ten existing works remain. The four principal book passages follow the controls.',
 'A call count, number of objects, smallest drawn feature and measured build time are different costs. A single selected split does not multiply the whole population.',
 'Does another level make a useful difference, or a difference too small for this encounter to reveal?',
 'IMPLEMENTED · four desks and four book passages; current runtime evidence is checked below.',
 ['fractal_recursion_2','example_8_3_recursion_circles_vr','cube_subdivision','recursive_chair']),
('Fractal_RecursiveTrees','Where growth goes','Branch, transform and vary.',
 'From Recursion: the difference between one descendant and several, plus a stopping condition.',
 'Which paths receive further growth?',
 'Follow corresponding forks under a held seed. Compare direction, length and depth separately. Give pruning or changed branch allocation a visible consequence before describing it as a new capability.',
 'Branch count can increase while individual branches become shorter. Dense drawing, collision and useful support are separate decisions.',
 'Which body could shelter in these branches? Which routes finish early, and why?',
 'EXISTING · collection and text retained; next hall-specific review follows Recursion.',
 ['recursive_tree','recursive_tree_2','inverted_tree_cloud']),
('Fractal_CantorSet','What the rule keeps','Construct through repeated removal.',
 'From Trees: descendants. From Arrays: addresses. Now descendants retain selected portions of a parent interval.',
 'What survives, and what becomes a gap?',
 'Predict the next row. Keep the history distinguishable from its last generation. Compare retained parts with the existing removal displays at the same stage.',
 'More intervals can coexist with less total retained length. The displayed finite construction keeps positive length; its infinite limit is a different claim.',
 'Can removal make room? What would count as a passage when the construction is given thickness?',
 'EXISTING · retain the specimens; test their mapping and reachable controls in the hall pass.',
 ['cantor_set','example_8_4_cantor_set_vr','example_8_4_cantor_pagoda_vr']),
('Fractal_KochSierpinski','Detail changes measurement','Replace a segment; remove parts of a surface.',
 'From Trace: sample resolution. From Cantor: repeated selection. From Transformation: scale and turns.',
 'How does finer detail change what can be measured?',
 'Compare consecutive construction depths at fixed outer scale. Read the box-counting instrument across several sampling scales. Keep segment counts and the instrument’s finite estimate visible.',
 'Geometry, sample scale and display resolution affect different parts of the result. The equal-copy dimension formula has conditions; a non-integer dimension is not a universal definition of every fractal.',
 'What can we infer beyond the last visible feature? Where does this instrument stop supporting the inference?',
 'EXISTING · repair staging and audit the instrument before updating technical claims.',
 ['fractal_koch_curve','sierpinski_triangle','box_counting_dimension','sierpinski_pyramid']),
('Fractal_MengerSponge','A hole becomes a place','Carry repeated removal into a volume.',
 'From Koch/Sierpinski: replacement and removal. From Scale: a player has finite dimensions.',
 'Which opening can this body enter?',
 'The nine-metre specimen and all five works are retained. A twelve-metre glass cube lends flight: enter at floor level, rise through the central passage, circle above the sponge, then descend to leave. The movement capability belongs to the installation; the retained cubes remain solid.',
 'The existing second generation has 400 retained cubes. A third would have 8,000. Neither count establishes acceptable headset performance or bodily access.',
 'A visible opening, a connected passage and an accessible route are three things to test separately.',
 'FLIGHT ADDED · museum walker and simulated XR controls checked; headset experience and the wider teaching encounter remain to develop.',
 ['menger_sponge','diffusion_limited_aggregation']),
('Fractal_GoldenSpiral','A number needs a mapping','Relate recurrence, proportion and spatial arrangement.',
 'From the sponge: repeat within retained volumes. Here the input is a short numerical history.',
 'How does a numerical relationship become a form?',
 'Predict the next Fibonacci value before comparing tower heights. Separate the recurrence from the logarithmic height mapping. Use the other existing works to investigate additional rules for position, turn and scale.',
 'Compression keeps more values in view while changing which differences are easy to compare. Repeating an arithmetic operation alone does not establish fractal geometry.',
 'What did the mapping make legible? What did its attractiveness persuade us to assume?',
 'TRANSITION REPAIRED · now leads to Synthesis; existing artifacts remain.',
 ['fibonacci_sequences','golden_rectangle','fibonacci_terrain','romanesco']),
('Fractal_Synthesis','Choose a procedure','Compare constructions and prepare symbolic rewriting.',
 'Bring calls, branching, removal, scale, measurement and numerical history into one comparison.',
 'Which rule could produce the space we want?',
 'Describe one step without using the artifact’s name. Specify what is received, retained, transformed and stopped. Carry the familiar Koch construction into the first L-system editor.',
 'Compare procedures at declared budgets. A complex outline by itself is not evidence of entropy, accessibility or freedom.',
 'What must change for a different body to have room here?',
 'TRANSITION REPAIRED · now leads directly to the Koch preset in Grammar Lab.',
 ['cantor_set','recursive_tree','koch_curve'])
]


def valid_hall_receipt(receipt, map_name, sequence='fractals'):
    """Accept shared-book edits only if this hall's recorded slice is unchanged.

    The archived pre-edit file must match the receipt's complete original hash.
    Executable sources still require exact hashes. Synthesis's editor source was
    recorded only for the next hall's preset comparison; that constant must match.
    This avoids invalidating a
    previous hall merely because another hall's book or role record changed.
    """
    if not (receipt.get('exit')==0 and not receipt.get('failures') and receipt.get('sources_unchanged') is True): return False
    def slice_(rel,d):
        if rel.endswith('artifact_roles.json'):
            return {k:d.get(k,{}).get(map_name) for k in ['roles','order','groups']}
        if rel.endswith(f'book/{sequence}.json'):
            return [x for x in d['pearls'] if x.get('map')==map_name]
        if rel.endswith('trunk_branches.json'):
            return [[x for x in d['hand_pearls'].get(sequence,[]) if x.get('map')==map_name],
                    [p for n in d['trunk'] if n.get('node')==sequence for p in n['pearls'] if p.get('map')==map_name]]
        return None
    shared={'commons/data/artifact_roles.json',f'commons/data/book/{sequence}.json','commons/data/trunk_branches.json'}
    hashes=receipt.get('source_sha256',{})
    if not hashes:return False
    for rel,h in hashes.items():
        current=ROOT/rel
        if not current.exists():return False
        if hashlib.sha256(current.read_bytes()).hexdigest()==h:continue
        archives=[ROOT/'doc/space'/name/'before'/rel for name in ['recursive-trees-2026-09-14','cantor-encounter-2026-09-14','koch-sierpinski-2026-09-14','menger-encounter-2026-09-14','golden-mapping-2026-09-14','fractal-synthesis-2026-09-14','grammar-lab-2026-09-14','lsystems-growth-2026-09-14','grammar-curves-2026-09-14','lsystems-architecture-2026-09-14','lsystems-competition-2026-09-14','lsystems-living-2026-09-14','assemblage-2026-09-14','genetic-evolution-2026-09-14','space-colonization-2026-09-14']]
        old=next((p for p in archives if p.exists() and hashlib.sha256(p.read_bytes()).hexdigest()==h),None)
        if map_name=='Fractal_Synthesis' and rel=='commons/artifacts/lsystem_editor/lsystem_editor.gd' and old is not None:
            # No editor is instantiated by Synthesis. Its final/technical only
            # cite PRESETS[0]. Verify the entire unchanged preset table, anchored
            # in the complete original file hash; do not relax executable checks.
            def presets(p):
                text=p.read_text(encoding='utf-8-sig')
                if 'const PRESETS = {' not in text:return None
                return text.split('const PRESETS = {',1)[1].split('\n}',1)[0]
            if presets(old) is not None and presets(old)==presets(current):continue
            return False
        if rel not in shared or old is None:return False
        if slice_(rel,load(old))!=slice_(rel,load(current)):return False
    return True

def main():
    plan=load(ROOT/'commons/data/museum/em_plan.json')
    route=[r['map'] for r in plan['plans'] if r.get('sequence')=='fractals']
    assert route==[s[0] for s in STEPS]
    roles=load(ROOT/'commons/data/artifact_roles.json')['roles']
    rows=[]
    for s in STEPS:
        name,title,cap,carry,question,encounter,cost,pressure,status,candidates=s
        m=load(ROOT/f'commons/maps/{name}/map_data.json')
        tokens=[c.split(':')[0].split('#')[0] for row in m['layers']['interactables'] for c in row if c.strip()]
        rows.append(dict(map=name,title=title,capability=cap,carry=carry,question=question,encounter=encounter,
            cost=cost,pressure=pressure,status=status,candidates=candidates,artifact_count=len(tokens),
            primaries=[a for a,v in roles.get(name,{}).items() if v=='primary'],
            next_map=route[route.index(name)+1] if name!=route[-1] else 'LSystems_Grammar_Lab'))
    receipt=load(REVIEW/'run.json') if (REVIEW/'run.json').exists() else {}
    verified=receipt.get('exit')==0 and not receipt.get('failures') and receipt.get('sources_unchanged') is True and all(hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in receipt.get('source_sha256',{}).items())
    data={'date':'2026-09-14','route':route,'following_sequence':'lsystems','next_work':'Fractal_Recursion',
        'thesis':'What bodies become possible with the tools we have learned, their combinations and the resources we can afford?',
        'halls':rows,'menger_restoration_verified':verified,'runtime_checks':receipt.get('checks') if verified else None,
        'interior_access_verified':False,'player_input_verified':False,'headset_verified':False,
        'extensions':['Fractal_JuliaSet','Fractal_MandelbrotSet','Fractal_CrossSequence']}
    flight_path=ROOT/'ada_run/menger-flight-review-2026-09-14/run.json'
    flight=load(flight_path) if flight_path.exists() else {}
    flight_verified=valid_hall_receipt(flight,'Fractal_MengerSponge')
    if flight_verified:
        data.update(menger_restoration_verified=True,runtime_checks=flight['checks'],interior_access_verified=True,
                    player_input_verified=True,headset_verified=False,flight_review='menger-flight.html',
                    input_method='Synthetic keyboard events through the actual museum walker; synthetic XR controller through XRToolsPlayerBody')
    recursion_path=ROOT/'ada_run/recursion-review-2026-09-14/run.json'
    recursion=load(recursion_path) if recursion_path.exists() else {}
    recursion_verified=valid_hall_receipt(recursion,'Fractal_Recursion')
    if recursion_verified:
        data.update(next_work='Fractal_RecursiveTrees',recursion_verified=True,recursion_checks=recursion['checks'],recursion_review='recursion-encounter.html')
        rows[0]['status']=f"REVIEWED · {recursion['checks']} Godot checks pass; physical desktop pointer, counts, repeated conditions and central aisle. Headset review remains pending."
    else:
        rows[0]['status']='IMPLEMENTED · the saved runtime evidence needs a fresh review of the current source.'
    trees_path=ROOT/'ada_run/trees-review-2026-09-14/run.json'
    trees=load(trees_path) if trees_path.exists() else {}
    if valid_hall_receipt(trees,'Fractal_RecursiveTrees'):
        data.update(next_work='Fractal_CantorSet',trees_verified=True,trees_checks=trees['checks'],trees_review='recursive-trees.html')
        rows[1]['status']=f"REVIEWED · {trees['checks']} rendered checks: growth, held-variable comparisons, replay, twelve placements, two physical desks and a walk around the enclosure. Headset testing remains pending."
        rows[1]['encounter']='A waiting trunk: grow one generation, then vary angle, inherited length and two/three descendants. Compare 31 and 121 segments at four generations. Across the approach, strata, bounds and terminal marks reveal a fixed-seed block tree without rebuilding it. All twelve placements remain.'
    cantor_path=ROOT/'ada_run/cantor-review-2026-09-14/run.json'
    cantor=load(cantor_path) if cantor_path.exists() else {}
    if valid_hall_receipt(cantor,'Fractal_CantorSet'):
        data.update(next_work='Fractal_KochSierpinski',cantor_verified=True,cantor_checks=cantor['checks'],cantor_review='cantor-encounter.html')
        rows[2]['status']=f"REVIEWED · {cantor['checks']} rendered checks: two physical desks, finite counts, history and ghost modes, extrusion, three gap widths, ramp and exit. Headset testing remains pending."
        rows[2]['encounter']='Advance one cut. Separate the latest intervals from their history and mark the new removals. On the retained deck, give those intervals thickness; compare three-metre, one-metre and third-metre gaps with the player body. All eight placements remain.'
    koch_path=ROOT/'ada_run/koch-review-2026-09-14/run.json'
    koch=load(koch_path) if koch_path.exists() else {}
    if valid_hall_receipt(koch,'Fractal_KochSierpinski'):
        data.update(next_work='Fractal_MengerSponge',koch_verified=True,koch_checks=koch['checks'],koch_review='koch-sierpinski.html')
        rows[3]['status']=f"REVIEWED · {koch['checks']} rendered checks: three desks, growth and removal, held-sample counts and fits, retained specimens and walking route. Headset testing remains pending."
        rows[3]['encounter']='Follow the Koch detour between fixed endpoints. Cut a triangle, then make its removed middles the visible work. Hold an 8,000-point sample while comparing six grid sizes and three fitting ranges. All ten placements remain; the old rear room and its raised cell are retained.'
    menger_path=ROOT/'ada_run/menger-encounter-review-2026-09-14/run.json'
    menger=load(menger_path) if menger_path.exists() else {}
    if valid_hall_receipt(menger,'Fractal_MengerSponge'):
        data.update(next_work='Fractal_GoldenSpiral',menger_encounter_verified=True,menger_checks=menger['checks'],menger_review='menger-encounter.html',menger_restoration_verified=True,runtime_checks=menger['checks'],interior_access_verified=True,player_input_verified=True,flight_review='menger-encounter.html',input_method='Synthetic pointer through DesktopPlayer; native museum keyboard flight and synthetic XR controller through XRToolsPlayerBody')
        rows[4]['status']=f"REVIEWED · {menger['checks']} checks: compact desk, counts and volume, complement views, occupied-room interlock, native museum flight, XR adapter and a small opening that refuses the standing capsule. Headset testing remains pending."
        rows[4]['encounter']='Compare the uncut cube with twenty and four hundred descendants at the same nine-metre outer size. Mark removed volume without adding collision. Enter the existing glass flight enclosure, pass through a large opening, then inspect a one-metre tunnel a ray can cross but the native capsule cannot enter. All five placements and the existing structure remain.'
    golden_path=ROOT/'ada_run/golden-review-2026-09-14/run.json'
    golden=load(golden_path) if golden_path.exists() else {}
    if valid_hall_receipt(golden,'Fractal_GoldenSpiral'):
        data.update(next_work='Fractal_Synthesis',golden_verified=True,golden_checks=golden['checks'],golden_review='golden-mapping.html')
        rows[5]['status']=f"REVIEWED · {golden['checks']} rendered checks: two desks, values and height mappings, fixed-unit sums, rectangle proportions and arcs, retained specimens and walking route. Headset testing remains pending."
        rows[5]['encounter']='Predict the next sum. Hold ten Fibonacci values while switching logarithmic and linear heights; compare their fixed-unit addition stacks. Inspect the retained spatial examples, then cut the upright golden rectangle, measure its remainder and add circular arcs. All seven existing artifacts remain.'
    synthesis_path=ROOT/'ada_run/synthesis-review-2026-09-14/run.json'
    synthesis=load(synthesis_path) if synthesis_path.exists() else {}
    if valid_hall_receipt(synthesis,'Fractal_Synthesis'):
        data.update(next_work='LSystems_Grammar_Lab',synthesis_verified=True,synthesis_checks=synthesis['checks'],synthesis_review='fractal-synthesis.html',fractal_first_pass=True)
        rows[6]['status']=f"REVIEWED · {synthesis['checks']} rendered checks: two compact desks, interval selection versus history, unchanged tree geometry across readings, held specimens and museum traversal. Headset testing remains pending."
        rows[6]['encounter']='Predict the Cantor descendants, then separate a new cut from hiding history or marking removed middles. Follow one block-tree fork through four readings without regenerating it. All ten original works remain. Carry an explicit rule into the grammar laboratory.'
    data['iteration_strategy']={'pass_one':'Reach the end of the active spine with a grounded encounter and matching book per hall.','threshold':['observable question and feasible action','primary artifacts in both room and book','prose and code match runtime','entry, controls and exit usable in available testing','existing material preserved; unknowns recorded'], 'next_pass':['review transitions across sequences','fix repeated accessibility and performance problems','develop the most promising rule changes and recombinations'], 'headset_review':'pending; do not block desktop-supported work'}
    dump(OUT/'fractal-learning-arc.json',data)
    direction='''# What can a rule make room for?

Agreed book direction, 14 September 2026.

The journey accumulates the capacity to construct different kinds of space and to investigate their limits. A sampled trace, a triangulated surface, a sine landscape, noise, cellular growth, branching and porous volumes each make different relations possible. Their combinations reopen earlier questions: what bodies can exist here, and what can they do?

The desire to make new worlds gives the inquiry its erotic and artistic urgency. The digital grotesque can expose an unfamiliar body, an excessive ornament or an opening that becomes inhabitable. Queer possibility is investigated through changes in relations and uses; a complex or irregular outline does not settle the question by itself.

Every further difference has a cost in computation and attention. We cannot inspect every branch or retain every detail. The trace already taught that some differences fall between samples. Later halls return to that decision through generation limits, finite storage, rendering and collision. Make the actual cost observable where the instrument supports it; keep unmeasured cost as a question.

Topology as escape becomes an experiment: change connections, create an opening, connect separated regions or provide shelter. Geometry and metrics govern shape and distance; topology concerns connectivity and continuity. A connected opening can still be inaccessible to a particular body. Entropy should be specified and measured for the chosen state distribution or process whenever a technical claim is made. Neither object count nor recursion depth is automatically an entropy value, and no universal threshold for freedom is asserted.

The rhythm of each passage is question → action → observation → actual code → an assumption pressed → a capability carried onward. Let discovery move between the unfamiliar consequence and the concrete operation that made it possible. Preserve strong existing work and give confident examples room in the book; one primary artifact was an initial scaffold, not a quota.

We want another opening. We subdivide the surface, add neighbours, let the rule run longer. The room becomes more intricate. Still, there may be no way through. What must change for this body to pass?
'''
    save(OUT/'book-red-thread.md',direction)
    md=direction+'\n## The active fractal walk\n\nFractals comes before L-systems. Seven active halls follow CA_EdgeOfChaos.\n\n'
    for n,r in enumerate(rows,1):
        md+=f"### {n}. {r['map']} — {r['title']}\n\n{r['capability']}\n\n**Carry in:** {r['carry']}\n\n**Question:** {r['question']}\n\n{r['encounter']}\n\n**Cost:** {r['cost']}\n\n**Press:** {r['pressure']}\n\n**Status:** {r['status']}\n\n"
    md+='## Beyond this walk\n\nJulia, Mandelbrot and CrossSequence remain available extensions. They are outside this route and are no longer treated by the adjoining prose as rooms the reader has already visited. The existing L-system order is retained. Its first editor uses a Koch preset, separating symbol rewriting from spatial interpretation.\n\n'
    md+=f"The next hall is {data['next_work']}. Inspect its complete collection before restaging; test its particular operation and connect the observed differences to the book. Illustrated reviews: recursion-encounter.html, recursive-trees.html and cantor-encounter.html.\n"
    save(OUT/'fractal-learning-arc.md',md)
    runtime=(f"Restoration checked in Godot: {receipt['checks']} checks passed. A 0.6-metre-wide, 1.8-metre-tall physical capsule clears the surrounding route. This is a collision check; player input, access to the elevated central passage and headset testing remain pending." if verified else 'Museum route and source restoration are in place. Rendered circulation review is pending; the elevated central passage needs an access design.')
    photo=''
    assets=['fractal-learning-arc.html','fractal-learning-arc.json','fractal-learning-arc.md','book-red-thread.md','learning-ladder.html']
    if verified:
        for kind in ['entrance','side','overview']:
            dest=OUT/f'fractal-menger-restored-{kind}.png'
            shutil.copy2(REVIEW/'Fractal_MengerSponge'/f'{kind}.png',dest);assets.append(dest.name)
        photo='<figure><img src="fractal-menger-restored-side.png" alt="Actual Godot view of the restored Menger specimen and surrounding museum floor"><figcaption>Actual museum capture. The nine-metre specimen is restored; its central opening is above the surrounding floor.</figcaption></figure>'
        dump(OUT/'fractal-arc-verification.json',receipt);assets.append('fractal-arc-verification.json')
    if flight_verified:
        runtime=f"Flight enclosure checked in Godot: {flight['checks']} checks passed. The museum walker ascends through the central opening, circles above and around the sponge, then returns to walking. Synthetic VR controller steering also passed. Headset testing remains pending."
        photo='<figure><a href="menger-flight.html"><img src="menger-flight-enclosure.png" alt="Actual Godot view of the sponge inside its glass flight cube"></a><figcaption><a href="menger-flight.html">Explore the flight cube, its controls and the recorded tests.</a></figcaption></figure>'
    template='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>What can a rule make room for? · Ada Research</title>
<style>:root{color-scheme:dark;--ink:#f3eee4;--muted:#b4c5c2;--rose:#f3b7cc;--line:#415657}*{box-sizing:border-box}body{margin:0;background:#10292e;color:var(--ink);font:17px/1.65 system-ui,sans-serif}main{max-width:1200px;margin:auto;padding:34px 28px 70px}nav{display:flex;gap:24px;flex-wrap:wrap;font-size:14px}a{color:var(--rose)}.eyebrow{letter-spacing:.14em;font-size:12px;margin-top:48px;color:var(--muted)}h1{font:clamp(42px,7vw,82px)/1.08 Georgia,serif;max-width:850px;margin:20px 0}h2{font:32px/1.2 Georgia,serif;margin:0 0 18px}h3{font-size:13px;letter-spacing:.09em;text-transform:uppercase;color:var(--muted);margin:24px 0 6px}.lead{font:23px/1.55 Georgia,serif;max-width:820px}.rail{border-block:1px solid var(--line);padding:18px 0;margin:30px 0;display:flex;gap:16px;align-items:center;flex-wrap:wrap}.rail strong{color:var(--rose)}.layout{display:grid;grid-template-columns:290px minmax(0,1fr);gap:22px}.steps{display:flex;flex-direction:column;gap:8px}.steps button{border:1px solid var(--line);border-radius:4px;padding:16px;text-align:left;background:#19383e;color:var(--ink);font:inherit;cursor:pointer}.steps button:hover{background:#29474c}.steps button[aria-pressed=true]{background:#eac4cc;color:#182f34;border-color:#eac4cc}.number{display:inline-block;min-width:29px;font:15px monospace;opacity:.65}.step-title{font-size:15px}.detail{padding:30px;background:#1c3b40;border:1px solid var(--line);border-radius:4px}.question{font:28px/1.4 Georgia,serif;color:#f7d5de}.status{border-left:3px solid #efb3cb;padding-left:13px;font-size:14px;color:var(--muted)}.cost{background:#132d32;padding:16px;border-radius:4px}code{font-size:13px;overflow-wrap:anywhere}.facts{display:flex;gap:18px;font-size:13px;color:var(--muted);flex-wrap:wrap}section{margin-top:48px;max-width:950px}blockquote{margin:30px 0;padding-left:24px;border-left:3px solid var(--rose);font:26px/1.5 Georgia,serif}figure{margin:28px 0}img{width:100%;height:auto;display:block;border:1px solid var(--line)}figcaption{color:var(--muted);font-size:14px;margin-top:8px}.next{padding:24px;background:#25494a;border:1px solid #6c8583}footer{border-top:1px solid var(--line);margin-top:48px;padding-top:22px;font-size:14px;color:var(--muted)}@media(max-width:760px){main{padding:24px 16px}.layout{grid-template-columns:1fr}.steps{display:grid;grid-template-columns:1fr 1fr}.steps button{padding:12px}.detail{padding:22px}.lead{font-size:20px}}
</style></head><body><main><nav><a href="learning-ladder.html">← Learning ladder</a><a href="/museum-progress?sequence=fractals">Museum progress</a><a href="/necklace/thread?map=Fractal_Recursion&role=primary">Current hall / book</a></nav>
<p class="eyebrow">ADA RESEARCH · THE BOOK AND THE WALK · 14 SEPTEMBER 2026</p><h1>What can a rule<br>make room for?</h1><p class="lead">We learn another way to construct a world. We discover what it carries, what it excludes, and what it costs to continue. Then we carry the question into the next room.</p>
<div class="rail"><span>Cellular automata</span><span aria-hidden="true">→</span><strong>Fractals · 7 halls</strong><span aria-hidden="true">→</span><span>L-systems</span></div>
<p>The route below is in the museum. Its questions guide the next hall-by-hall work; they are not claims that every proposed interaction has already been built.</p><div class="layout"><div class="steps" aria-label="Choose a fractal hall">__BUTTONS__</div><article class="detail" id="detail" aria-live="polite"></article></div>
<section><h2>Desire, detail and the opening.</h2><p>Making another world can carry an erotic desire: to approach an unfamiliar body, inhabit it, alter it, and discover what it allows us to become. The digital grotesque gives that desire form. Every additional difference also asks for computation and attention.</p><blockquote>We want another opening. The room becomes more intricate. Still, there may be no way through. What must change for this body to pass?</blockquote><p>Keep geometry, connectivity, bodily access and entropy distinguishable. A change in shape can leave connections intact; a connected passage can remain too narrow for the player. The experiment gives these terms their consequences.</p><p><a href="book-red-thread.md">Read the agreed book direction</a></p></section>
<section><h2>The sponge returns.</h2><p>Repeated removal becomes a volume we can approach. The original grid and all five artifacts are retained together inside an enclosing wall ring. The museum supplies glass over the old voids; that support belongs to the installation.</p><p class="status">__RUNTIME__</p>__PHOTO__<p><a href="/necklace/thread?map=Fractal_MengerSponge&role=primary">Menger Sponge / primary and book</a></p></section>
<section><h2>A familiar curve, another way to write it.</h2><p>The first L-system editor is already configured with a Koch preset. Recognition makes room for the new distinction: the grammar rewrites a sentence; an interpreter turns the resulting symbols into movements and turns. Later halls carry this into growth, paths, architecture and living arrangements.</p><p>Julia, Mandelbrot and CrossSequence remain available extensions. Their collections are preserved outside this seven-hall walk.</p><p><a href="https://natureofcode.com/fractals/">The Nature of Code</a> also develops recursion, Koch curves and trees before introducing L-systems.</p></section>
<section class="next"><h2>First traverse. Then return.</h2><p><a href="fractal-synthesis.html">Fractal Synthesis</a> now compares two procedures and keeps the full collection. The next encounter is <a href="/necklace/thread?map=LSystems_Grammar_Lab&amp;role=primary">LSystems_Grammar_Lab</a>: rewrite a sentence, then give it a spatial reading.</p><p>For the first pass, each hall needs a discoverable action, usable controls, a matching book passage and a record of its limits. Preserve strong existing work. Complete the spine before deeply polishing individual halls, while fixing failures that prevent learning or passage as they arise.</p><p>Afterward, walk the whole book and museum together, review the transitions, then develop recurring improvements and the most promising experiments. Headset testing remains a separate pending review.</p><a href="spine-iteration.md">Working method and next actionable improvements →</a></section>
<footer><a href="fractal-learning-arc.md">Full plan</a> · <a href="fractal-learning-arc.json">Structured route</a><p>Existing artifact roles are preserved. The next hall review may bring further confident examples into the book.</p></footer></main><script>
const data=__DATA__;
const escape=s=>String(s).replace(/[&<>\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
function show(i,update=true){const r=data.halls[i];document.querySelectorAll('[data-hall]').forEach((b,n)=>b.setAttribute('aria-pressed',String(n===i)));document.getElementById('detail').innerHTML=`<p class="facts"><span>HALL ${i+1} / 7</span><span>${r.artifact_count} placed artifacts</span><span>${r.primaries.length} current primaries</span></p><h2>${escape(r.title)}</h2><p>${escape(r.capability)}</p><p class="question">${escape(r.question)}</p><h3>Carry in</h3><p>${escape(r.carry)}</p><h3>The encounter to develop</h3><p>${escape(r.encounter)}</p><div class="cost"><h3>What continuing costs</h3><p>${escape(r.cost)}</p></div><h3>Press an assumption</h3><p>${escape(r.pressure)}</p><p class="status">${escape(r.status)}</p><h3>Existing works to inspect</h3><p><code>${r.candidates.map(escape).join(' · ')}</code></p><p><a href="/necklace/thread?map=${encodeURIComponent(r.map)}&role=primary">Open this hall and its book passage →</a></p>`;if(update)history.replaceState(null,'','#'+r.map);}
document.querySelectorAll('[data-hall]').forEach((b,i)=>b.addEventListener('click',()=>show(i)));const ix=data.halls.findIndex(r=>r.map===location.hash.slice(1));show(ix<0?0:ix,false);
</script></body></html>'''
    buttons=''.join(f'<button data-hall="{i}" aria-pressed="{str(i==0).lower()}"><span class="number">{i+1:02}</span><span class="step-title">{html.escape(r["title"])}</span></button>' for i,r in enumerate(rows))
    page=template.replace('__BUTTONS__',buttons).replace('__DATA__',json.dumps(data,ensure_ascii=False).replace('</','<\\/')).replace('__RUNTIME__',html.escape(runtime)).replace('__PHOTO__',photo)
    save(OUT/'fractal-learning-arc.html',page)
    targets=['possible-bodies/'+a for a in assets]
    dump(EVIDENCE/'publish-targets.json',targets)
    dump(EVIDENCE/'publish-hashes.json',{r:hashlib.sha256((ROOT/'doc/research'/r).read_bytes()).hexdigest() for r in targets})
    print(f'Built learning arc, {len(targets)} assets; restoration verified: {verified}.')

if __name__=='__main__':main()
