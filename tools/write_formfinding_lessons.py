"""Publish six reconstruction lessons, source-linked review, and scoped hall layout."""
from pathlib import Path
import json, re, html, shutil, hashlib, zipfile
import markdown
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-formfinding-build-and-investigate'
CODE=ROOT/'doc/book/studies/formfinding-lineage'
ROWS=[
dict(key='Descent',title='Choose the next address',script='01_descent.gd',primary='descent_landscape_lab',bay=[10.5,0,6],subjects=['Objective function','Finite-difference gradient','Update rule','Distinct stopping conditions'],
 encounter='At the large blue surface, press STEP and follow the gold point. The point changes address because a rule proposes another one. In Forces, a released body kept velocity. This search keeps no velocity: every accepted step replaces its two-number address.',
 inherit='Keep the point class, Vector2 and Vector3, functions, conditionals and the controls from Forces. The displayed sphere is a marker here; its collider is disabled. A grabbable point would let a hand move the picture without changing the search address.',
 build='Reconstruct the STEP operation and both cost functions. The supplied display samples the same functions into a small surface; it does not decide the step. A Vector2 holds the search coordinates. Its second component becomes spatial Z when plotted; surface height shows cost.',
 explain='The bowl costs one quarter of x² + z². Its gradient is (x/2, z/2). The two-valley expression is the hall’s second authored landscape; it gives us two possible local arrivals. In landscape.gd, sample the cost 0.03 to either side of each coordinate and divide the difference by the full 0.06 separation. This estimates the slope of the cost function, not a normal read from the rendered mesh.\n\nSubtract rate × gradient to propose an address. The rate is a search step size, not seconds. STEP does one update. A small gradient, an exhausted budget and an out-of-frame proposal have different names. The last case retains the old address; it does not clamp the point onto the edge and pretend it has settled.',
 change='On the bowl, predict the first step from (−2.8, −2) at rate 0.7: (−1.82, −1.3). Press STEP once and read it. Set rate to 5 and restart: the first proposal leaves the frame, so the point must stay at its start. These outcomes test the operation and the boundary separately.',
 task='Make a second search beginning at (2.8, −2). Give it its own address, step count and status. Use the same two-valley function and rate 0.2 for both searches. Predict whether they finish together. Record their final costs and stopping reasons. A single shared STEP button can call each search once; do not share the mutable address. Explain why two SMALL SLOPE messages need not identify the same result.',
 carry='You now have an objective, a proposed change and a reason to stop. Keep landscape.gd: Annealing will revisit this exact landscape with another proposal and acceptance rule.',
 limits='The hall adds RUN, three starts, rate and tolerance controls, a history and explanatory boards. This study keeps STEP, RESET and two surfaces. Small slope is a local observation; no code here proves a global minimum.'),
dict(key='Catenary',title='Draw between the points',script='02_curve.gd',primary='cable_builder',bay=[16,0,7],subjects=['Curve3D','Endpoints and handles','Sampling a curve','Parameters versus simulated forces'],
 encounter='Move a point on the cable builder. The hanging line follows immediately. Its shape is drafted by handles; it does not wait for gravity to settle a chain. Walk on to the formula-built catenoid and laundry curves before deciding what their resemblance establishes.',
 inherit='Bring the two held points from Lines and Coordinates, local/world conversion, and the loop that joined neighbouring positions in Trace. Here those familiar points become endpoints of a curved span.',
 build='Make one span using the same handle rule as the existing cable builder. Keep two PointBody instances and 24 thin cylinders. The hand supplies endpoints; the script resamples the span as they move.',
 explain='Curve3D stores endpoints with incoming and outgoing handles. A handle is an offset from its endpoint. The outgoing handle follows 30% of the displacement to the other point; the incoming handle points 30% back. Both also move down by sag × span × 0.5. This is the production artifact’s chosen Bézier construction.\n\ncurve.sample(0, t) evaluates the first span at a parameter between 0 and 1. The loop joins neighbouring evaluations. Equal parameter intervals need not have equal spatial length. to_local converts each held point’s world position into the study’s frame before constructing the curve. Local DOWN remains the study’s down; keep the study upright at unit scale.\n\nSag is a dimensionless control of handle depth. It is not the midpoint’s drop and not the cable’s weight. With level endpoints two metres apart and sag 0.5, both handles drop 0.5 m and the midpoint drops 0.375 m. Zero sag gives a straight span. The script evaluates a shape every frame; it does not integrate velocity or conserve cable length.',
 change='Before pressing SAG, predict which points will stay fixed. The button alternates 0.8 and 0 after the initial 0.5 setting. At sag 0, move an endpoint in height and depth: the line should still join both points. Bring the endpoints together; the zero-length drawing should disappear without an invalid direction.',
 task='Build two neighbouring spans from three held points. The middle point is shared: moving it must change both spans without creating two copies of the joint. Retain the same per-span handle rule. Compare the two sag depths when the spans have different lengths. You will need another set of rods, a loop over adjacent endpoint pairs, and the correct Curve3D span index for each sample.',
 carry='A shape can be determined directly from controls. In Relaxation, keep endpoints but replace the drafted interior with positions that repeatedly correct their relationships.',
 limits='The museum cable has four control points and a swept tube. The study uses two and thin cylinders. Neither is a physical catenary solver. The evaluated cosh curves and surfaces elsewhere in the hall are separate constructions.'),
dict(key='Relaxation',title='Keep correcting the connection',script='03_relaxation.gd',primary='verlet_workbench',bay=[16,0,7],subjects=['Current and previous positions','Pinned endpoints','Distance constraints','Iteration budget','Residual error'],
 encounter='At the cloth bench, switch WIND off, then compare PASSES. Each choice resets the same cloth. Look at its worst length error as well as its shape. Nearby frozen forms retain the result of earlier corrections; their stillness does not mean the calculation was exact.',
 inherit='Keep the endpoint points, arrays and neighbouring-index loop. Forces supplied gravity, time steps and damping. Here positions and their previous values carry the motion; a separate correction loop enforces approximate lengths.',
 build='Reduce the cloth to seven points and six links. Only the endpoints are held. Each STEP advances one fixed 1/60-second model step, then repeats the constraint corrections. The chain has 2.7 m of requested link length across an initial two-metre span, so it has room to hang.',
 explain='positions and previous are separate arrays. duplicate() preserves the previous record while the current one changes. For an interior point, here − previous[i] is displacement during the preceding fixed step, not metres per second. Multiplying by 0.99 damps that displacement. Gravity adds acceleration × DT². Jolt does not integrate these interior points.\n\nA link compares its current length with REST. correct_pair moves its ends toward the requested distance. An endpoint has correction weight zero; a free point has weight one. Two free ends split a correction; beside a pin the free end takes it all. The tiny-distance guard avoids dividing by zero. It cannot invent a direction for coincident points.\n\nLater corrections can disturb earlier links, so one pass need not satisfy the entire chain. Repeating the pass reduces the remaining error in this comparison. It costs more work and does not certify every possible configuration. worst_error reports the largest absolute relative length error. Moving either held endpoint supplies a new pin on the next STEP; RESET returns both original pins. PASSES switches to 1, then 12, resetting each time. The initial budget is 4.',
 change='From RESET, compare one and twelve passes after the same 420 steps. You may drive step_once() with a bounded for loop for this measurement. Predict which budget leaves less worst error. Keep the same pins, time step, initial positions and damping. Do not compare one fresh chain with another that has already been settling.',
 task='Reconstruct a second chain with the same seven points but only the first point pinned. Update the correction weights and the integration range together so the final point is free. Predict its motion before stepping. Show that the first point stays at its pin and that the last point can move. Then explain why leaving the old endpoint weight at zero would contradict your new model.',
 carry='Constraints can shape a configuration through repeated local corrections. Equilibrium next asks when a simpler relation lets you calculate a pose directly.',
 limits='This study is a fixed-step position solver with no contact response for its interior markers or rods. Keep pins near their initial positions and above the floor. The full cloth includes a two-dimensional spring network and optional wind. The chain is not an exact continuous catenary.'),
dict(key='Equilibrium',title='Place the pivot',script='04_balance.gd',primary='calder_mobile',bay=[16,0,7],subjects=['Mass moments','Solving a constraint','Assumptions of a model','Balance versus stability'],
 encounter='Follow one arm of the hanging mobile. The heavier side has less distance to the suspension. Its stillness was constructed from an arithmetic relation. The room’s truss and animated triangle offer other appearances of support without a load test.',
 inherit='Use masses from Forces, displacement and distance from Lines, functions and the drawn rods. We only need two familiar point markers to reconstruct one arm of the recursive mobile.',
 build='Choose two positive masses and a total span. Calculate both distances from the pivot, then place the points. One nearby button changes the left mass while retaining the span.',
 explain='For opposite vertical weights acting on a level, massless arm, equal torque magnitudes require m_left × g × d_left = m_right × g × d_right. The same g cancels. Also, the two arm lengths must add to span. Solving both relations gives d_left = span × m_right / total_mass and the opposite expression for d_right.\n\nWith masses 1 and 2 kg over two metres, the arms are 4/3 and 2/3 m. The heavier mass is closer to the pivot. The label shows mass × arm in kg m; multiply by g for torque magnitude in N m. Equal products express the selected static model.\n\nThe PointBody instances display the calculated places. The masses are numeric inputs, not a claim that these frozen markers are hanging under simulated forces. No joint, collision or settling solver determines this pose. That distinction also applies to the current mobile.',
 change='Predict the pivot’s relation to the points when the left mass changes from 1 to 4 kg. Press LEFT MASS and compare both products. Check that the arm lengths still add to two metres. Then give the sides equal mass and predict the midpoint.',
 task='Build a second two-point arm carrying masses 3 and 7 kg over 1.5 m. Display both distances and the residual m_left × d_left − m_right × d_right. It should be near zero. Construct an intentionally centred pivot as a comparison and show its nonzero residual. Explain why a zero residual in this model does not show that a disturbed physical mobile will return to rest.',
 carry='A calculated relation can construct a pose without waiting. In Annealing we return to a search where a useful next step may first make the objective worse.',
 limits='The museum recurses over many arms and uses nominal disc masses. This lesson isolates one level. It omits rod and wire mass, friction, wind, and dynamic stability. The two points are a diagram of its inputs, not a new physics engine.'),
dict(key='Annealing',title='Keep the best; let the search move',script='05_annealing.gd',primary='simulated_annealing',bay=[16,0,7],subjects=['Random proposals','Acceptance probability','Cooling','Current versus best','Repeatable comparison'],
 encounter='Watch the search point change its mind. At the annealing cabinet, some accepted moves raise the displayed cost. The lower region it has already found remains worth keeping even while the current candidate explores elsewhere.',
 inherit='Return to the two-valley function and point marker from Descent. Keep the objective unchanged so the new rule, rather than a new landscape, carries the comparison. Conditionals, saved values and bounded loops are already available.',
 build='Propose a nearby address, accept improvements, sometimes accept a worse move, and gradually reduce that willingness. Store current and best separately. The smaller raised marker records the best address found so far.',
 explain='RandomNumberGenerator supplies the proposals. seed = 7 restarts its sequence for repeatable comparisons in this engine version. randf_range(-0.5, 0.5) chooses each coordinate offset; randf() supplies the acceptance draw. This is a first use of random sampling, before the later Randomness sequence studies its varieties.\n\nchange is candidate cost minus current cost. A nonpositive change is accepted. For a positive change and positive temperature, exp(-change / temperature) gives an acceptance probability between zero and one. Compare the random draw with that threshold. At change 0.05 and temperature 0.2, the threshold is about 0.779: a draw of 0.7 accepts and 0.9 rejects.\n\nCurrent may become worse. Best only changes when the accepted current cost improves on it. Cooling multiplies temperature by 0.98 after each attempt, including rejected and out-of-frame proposals. The counter counts attempts, not accepted moves. Below 0.01, or at 240 attempts, the search stops. A reset restores the seed, both addresses, temperature and counter.',
 change='Keep the initial state and proposal rule. Set cooling to 0.9 and compare with 0.98. Predict which schedule stops sooner, then record both attempt counts and best costs. A faster cooling schedule gives fewer opportunities; one result does not establish that every slower run will be better.',
 task='Add counters for accepted improvements, accepted worse moves and rejected in-frame proposals. Define where equal-cost moves belong. Verify that their sum plus out-of-frame proposals equals the attempt count. Run several distinct seeds and keep a small table of best costs. Explain why keeping a best record is different from forcing current to move only downhill.',
 carry='A stopping rule finishes a search; it does not decide whether its result serves your purpose. Forge makes that decision into visible code.',
 limits='The installed cabinet uses another objective and a richer adaptive algorithm, including occasional forced hops and reheating. This study isolates basic acceptance and cooling on the earlier landscape. Temperature here is an algorithmic parameter, not a measured material temperature. Finite runs provide no guarantee of the global optimum.'),
dict(key='Forge',title='Write what counts',script='06_criterion.gd',primary='balance_puzzle',bay=[16,0,7],subjects=['Combining conditions','Measured state','Accumulated time','Success criteria','Counterexamples'],
 encounter='At the balance puzzle, make a low quiet arrangement, then a taller one. The detector asks for more than stillness. Turn to the forge’s arriving body and notice that its destination was prescribed in advance. These two forms arrive under different kinds of instruction.',
 inherit='Bring the grabbable cube, engine velocity, conditions, counters and a boolean state. The cube’s complete construction is included with the shared code. The museum floor and XR hands remain the environment.',
 build='Make three small physical cubes. Measure their highest corner above the floor and whether they are moving slowly. Accumulate credit when the height and quietness conditions hold; lose credit when movement returns. Keep ACCEPTED visible once reached.',
 explain='The eight corners of each cube are transformed into the study’s frame before measuring height, so a turned cube’s top is still measured correctly. The study origin must be on the floor and its axes upright at unit scale. The quiet test checks linear speed in m/s and angular speed in radians/s. It also rejects a held cube, whose low reported rigid-body velocity would otherwise be misleading.\n\nobserve is the decision rule separated from measurement. A low result clears credit. A high, quiet result gains delta seconds. A high moving result loses twice delta, down to zero. This follows the museum puzzle’s gain-and-decay idea; it is not a requirement for one perfectly uninterrupted quiet interval. Crossing required_time latches accepted. RESET clears that record and places the cubes separately. Release them before resetting.\n\nThe rule measures height and low motion, not whether the cubes support one another or remain inside a tray. A cube resting on an unrelated high ledge could satisfy these measurements. That limitation is part of what you are learning to inspect, not a property to hide behind the word success.',
 change='Let three separate cubes settle on the floor. They should remain below the 0.5 m threshold. Stack them into a roughly 0.6 m column and let go. Watch the credit rather than assuming the first tall frame will pass. Disturb the stack before acceptance and follow the loss of credit.',
 task='Author a second criterion that rewards a low arrangement. Keep the physical cubes and the measurement code; change the decision function. Supply one measured situation that the original accepts and yours rejects, and another that reverses that judgment. Test both functions with known height, quietness and time values, then build the two arrangements in the room. State what both criteria still fail to measure.',
 carry='An objective, constraint and stopping rule each make a different decision. Keep that distinction when Wavefunctions begins: a continuing oscillation may be a successful behaviour even though it never settles.',
 limits='The installed puzzle has eight mixed pieces and a walking reward animation. Your study has three cubes and a latched caption. It improves height measurement and excludes held cubes, but does not claim to reproduce every part of the production detector. Its success rule does not certify physical stability for all future disturbances.')]

PLACEMENTS={
'Catenary':{'cable_builder':(6,7,0),'film_catenoid_sections':(6,15,0),'catenoid':(16,9,0),'helicoid':(16,12,0),'laundry_line_cathedral':(16,16,0),'science_screen':(19,15,90)},
'Relaxation':{'verlet_workbench':(10,7,0),'mass_spring_bench':(5,7,0),'frozen_glass_vessel':(17,10,0),'film_form_relaxation':(3,12,90),'science_screen':(18,16,90)},
'Equilibrium':{'calder_mobile':(6,8,0),'fractal_truss_tower':(16,14,0),'tensegrity_triangle':(5,15,0),'science_screen':(18,8,90)},
'Annealing':{'simulated_annealing':(16,8,0),'energy_landscape_bench':(5,7,0),'max_q_basin_room':(10,14,0),'impossible_end_table':(17,14,0),'science_screen':(18,17,90)},
'Forge':{'balance_puzzle':(7,7,0),'self_shaping_forge':(16,9,0),'gradient_descent_optimizer':(5,14,0),'science_screen':(18,15,90)}}

def arrange():
    for r in ROWS:
        path=ROOT/f'commons/maps/FormFinding_{r["key"]}/map_data.json'
        data=json.loads(path.read_text(encoding='utf8'))
        data['map_info']['description']=r['encounter']
        data['map_info']['metadata']['learning_objectives']=r['subjects']
        data['map_info']['metadata']['tutorial_primary']=r['primary']
        data['map_info']['metadata']['student_bay']=r['bay']
        if r['key'] in PLACEMENTS:
            w,d=22,20
            old=data['layers']['interactables']
            records={token.split(':')[0]:token for row in old for token in row if token}
            new=[['' for x in range(w)] for z in range(d)]
            for token,(x,z,yaw) in PLACEMENTS[r['key']].items():
                original=records[token]
                parts=original.split('#')
                head=parts[0].split(':')
                if len(head)==1:head.append(str(yaw))
                else:head[1]=str(yaw)
                new[z][x]='#'.join([':'.join(head)]+parts[1:])
            assert len(records)==len(PLACEMENTS[r['key']])
            data['layers']['interactables']=new
            data['layers']['structure']=[['w' if x in (0,w-1) or z in (0,d-1) else '1' for x in range(w)] for z in range(d)]
            for x in range(w//2-1,w//2+2):
                data['layers']['structure'][0][x]='1';data['layers']['structure'][-1][x]='1'
            data['layers']['utilities']=[['' for x in range(w)] for z in range(d)]
            data['layers']['utilities'][1][w//2]='s'
            data['layers']['utilities'][d-2][w//2]='t'
            data['map_info']['dimensions'].update(width=w,depth=d)
        path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf8')

def source(file):return (CODE/file).read_text(encoding='utf8').rstrip()
def block(file):return f'<!-- student-code:{file} -->\n\n```gdscript\n{source(file)}\n```\n'
def publish():
    OUT.mkdir(parents=True,exist_ok=True)
    for r in ROWS:
        r['map']='FormFinding_'+r['key']
        text=f'# {r["title"]}\n\n## Learning elements\n\n'+''.join('- '+x+'\n' for x in r['subjects'])
        text+=f'\n{r["encounter"]}\n\n## What you bring\n\n{r["inherit"]}\n\n## Build inside the museum\n\n{r["build"]}\n\n'
        text+=f'Save `{r["script"]}` beside the [complete shared code](../../../doc/book/course/formfinding-shared-code.md), on your existing `PointStudy` Node3D. The inspected working bay is hall-local `{tuple(r["bay"])}` metres, floor level, upright, unit scale. The museum supplies the floor, camera, light, hands and button scene. The larger artifact remains available for comparison.\n\n'
        text+=f'## Complete code — {r["script"]}\n\n'+block(r['script'])
        if r['key']=='Descent':text+='\n## landscape.gd — keep this for Annealing\n\n'+block('landscape.gd')
        text+=f'\n## Read the operation\n\n{r["explain"]}\n\n## Predict, then change\n\n{r["change"]}\n\n## Build another experiment\n\n{r["task"]}\n\n## Carry onward\n\n{r["carry"]}\n\n## Model notes\n\n{r["limits"]}\n'
        path=ROOT/f'commons/maps/{r["map"]}/tutorial.md'
        path.write_text(text,encoding='utf8')
        rowdir=OUT/r['map'];rowdir.mkdir(exist_ok=True)
        shutil.copy2(path,rowdir/'tutorial.md')
        shutil.copy2(ROOT/f'commons/maps/{r["map"]}/final.md',rowdir/'final.md')
    (OUT/'halls.json').write_text(json.dumps(ROWS,indent=2,ensure_ascii=False),encoding='utf8')
    shared='''# Form Finding — working inside the museum

Continue after Forces in the existing Endless Museum. Try the primary exhibit, reconstruct its selected operation, then make another experiment. The remaining exhibits belong to the wider inquiry; you do not need to rebuild every one.

Keep the point class from Lines and Coordinates. A class and saved code travel onward; this does not imply that the museum automatically carries a single physical instance between halls. Use your existing PointStudy Node3D and replace its lesson script. Place it in the stated clear bay under the current hall, at unit scale with Y up. If your scene uses a saved study instance rather than a runtime hall child, give it the same world transform as that hall-local position. Do not put it under a scaled artifact.

All four shared files below and the current lesson script live in one folder. Descent introduces landscape.gd; Annealing reuses it unchanged. The already installed XRToolsPickable class and res://commons/interactables/push_button.tscn are declared museum dependencies. No unnamed node or dollar reference is required.

PointBody still supplies a sphere, boundary and pickup. make_point adds its black material. Markers have collision disabled; endpoint points remain grabbable and stay where released. The rod, caption, button and sampled surface are display helpers, printed below in full. None chooses a search step, relaxes a chain, balances a lever or judges a construction. Those operations remain in the lessons.

The cube helper repeats the earlier mesh-and-collider construction using BoxMesh. It releases into Jolt physics. Its contact geometry is part of the environment for the last lesson; the acceptance rule remains yours to inspect.

'''
    for f in ['point_body.gd','study.gd','landscape.gd','cube_body.gd']:shared+='## '+f+'\n\n'+block(f)+'\n'
    (ROOT/'doc/book/course/formfinding-shared-code.md').write_text(shared,encoding='utf8')
    (OUT/'shared.md').write_text(shared,encoding='utf8')
    render()

CSS='''body{margin:0;background:#ecebe6;color:#252329;font:18px/1.65 Georgia,serif}main{max-width:1480px;margin:auto;padding:40px}nav{position:sticky;top:0;background:#17171b;color:white;padding:12px;font:14px system-ui;z-index:2}nav a{color:#f2c2da;margin-right:20px}h1{font-size:42px;line-height:1.12}h2{font-size:24px}a{color:#9b285d}pre{background:#18191d;color:#eee;padding:22px;overflow:auto;font:13px/1.6 Consolas,monospace}code{font-size:.9em}img{width:100%;height:auto}article{background:#faf9f4;padding:32px;margin:20px 0;border-top:3px solid #e69fc2}.spread{display:grid;grid-template-columns:1fr 1fr;gap:24px}.spread article{min-width:0}.small{font:14px/1.5 system-ui;color:#62616a}table{border-collapse:collapse;width:100%}td,th{text-align:left;vertical-align:top;padding:12px;border-bottom:1px solid #ccc}@media(max-width:1000px){.spread{display:block}main{padding:16px}}'''
def md(s):return markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
def page(title,body,nav=''):
    return '<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>'+html.escape(title)+'</title><style>'+CSS+'</style><nav>'+nav+'</nav><main>'+body+'</main>'
def local_images(text):
    def replace(m):
        p=ROOT/m.group(1)
        return p.resolve().as_uri() if p.exists() else m.group(0)
    return re.sub(r'/book-review/([^\s)"<>]+)',replace,text)
def render():
    nav=' '.join(f'<a href="{r["map"]}/parallel.html">{r["key"]}</a>' for r in ROWS)
    intro='<h1>Form Finding: build and investigate</h1><p>Six halls. One selected operation in each. The same points become search addresses, curve endpoints, constrained links and a balance diagram. The cube returns when contact matters.</p><p><a href="tutorials.html">Complete tutorials</a> · <a href="final.html">Complete reflections</a> · <a href="shared.html">All shared code</a> · <a href="formfinding-review.zip">Reviewer ZIP</a> · <a href="REPORT.md">Evidence and changes</a></p>'
    tutorials=[];finals=[];cards=[]
    for i,r in enumerate(ROWS):
        d=OUT/r['map']
        tutorial=local_images(md((d/'tutorial.md').read_text(encoding='utf8')))
        reflection=local_images(md((d/'final.md').read_text(encoding='utf8')))
        before=(OUT/'before/commons/maps'/r['map']/'final.md').read_text(encoding='utf8')
        localnav='<a href="../index.html">Sequence</a> <a href="../shared.html">Shared code</a> '+ ' '.join(f'<a href="../{x["map"]}/parallel.html">{x["key"]}</a>' for x in ROWS)
        body='<h1>'+str(i+1)+'. '+r['key']+'</h1><div class="spread"><article>'+tutorial+'</article><article>'+reflection+'</article></div>'
        (d/'parallel.html').write_text(page(r['title'],body,localnav),encoding='utf8')
        (d/'changes.html').write_text(page(r['key']+' reflection before / after','<div class="spread"><article><h2>Before</h2>'+local_images(md(before))+'</article><article><h2>After</h2>'+reflection+'</article></div>',localnav),encoding='utf8')
        for kind,content in [('tutorial',tutorial),('final',reflection)]:
            (d/(kind+'.html')).write_text(page(r['title'], '<article>'+content+'</article>',localnav),encoding='utf8')
        tutorials.append('<article id="'+r['map']+'">'+tutorial+'</article>');finals.append('<article id="'+r['map']+'">'+reflection+'</article>')
        images=''
        for phase in ['before','after']:
            pic=OUT/phase/r['map']/'entry.png'
            if pic.exists():images+=f'<div><h3>{phase.title()} · inside the museum</h3><img src="{phase}/{r["map"]}/entry.png"></div>'
        student=OUT/'after'/r['map']/'student.png'
        if student.exists():images+=f'<div><h3>Student reconstruction in the hall</h3><img src="after/{r["map"]}/student.png"></div>'
        cards.append(f'<article id="{r["map"]}"><h2>{i+1}. {r["key"]} — {r["title"]}</h2><p>{r["build"]}</p><p class="small">'+ ' · '.join(r['subjects'])+f'</p><p><a href="{r["map"]}/parallel.html">Tutorial left / reflection right</a> · <a href="{r["map"]}/changes.html">Reflection before / after</a></p><div class="spread">'+images+'</div></article>')
    (OUT/'index.html').write_text(page('Form Finding',intro+''.join(cards),nav),encoding='utf8')
    (OUT/'tutorials.html').write_text(page('Form Finding tutorials',''.join(tutorials),nav),encoding='utf8')
    (OUT/'final.html').write_text(page('Form Finding reflections',''.join(finals),nav),encoding='utf8')
    (OUT/'shared.html').write_text(page('Shared code',md((OUT/'shared.md').read_text(encoding='utf8')),nav),encoding='utf8')
    (OUT/'all-tutorials.md').write_text('\n\n---\n\n'.join((OUT/r['map']/'tutorial.md').read_text(encoding='utf8') for r in ROWS),encoding='utf8')
    (OUT/'all-final.md').write_text('\n\n---\n\n'.join((OUT/r['map']/'final.md').read_text(encoding='utf8') for r in ROWS),encoding='utf8')
    with zipfile.ZipFile(OUT/'formfinding-review.zip','w',zipfile.ZIP_DEFLATED) as z:
        for f in ['all-tutorials.md','all-final.md','shared.md','halls.json']:
            z.write(OUT/f,f)
        for p in CODE.glob('*.gd'):z.write(p,'code/'+p.name)

if __name__=='__main__':
    import sys
    if '--arrange' in sys.argv:arrange()
    publish()
