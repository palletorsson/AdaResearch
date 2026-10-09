"""Publish the opening lesson and an explicitly unfinished twelve-hall review route."""
from pathlib import Path
import html, json, re
import markdown

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations/2026-10-08-wavefunctions-what-returns'
MAP = ROOT/'commons/maps/WaveFunctions_Intro'
CODE = ROOT/'doc/book/studies/wavefunctions-lineage/01_cube_return.gd'

def block(name, text):
    return f'<!-- student-code:{name} -->\n\n```gdscript\n{text.rstrip()}\n```\n'

TUTORIAL = (CODE.parent/'intro-tutorial.md').read_text(encoding='utf8')
FINAL = (CODE.parent/'intro-final.md').read_text(encoding='utf8')

ROWS = [
('WaveFunctions_Intro','The cube returns','Periodic motion, amplitude, frequency, phase','y_oscillation_cube','Continue Transformation with the cube. Read its height from time; compare how far it moves, how often it returns and where its cycle begins. Build two cubes with independent phases.','Author correction: start with the cube. Pendulum is a comparison, not the opening tutorial object.','Carry elapsed time and cycle parameters into a comparison with a recorded swing.'),
('WaveFunctions_Pendulum','Record','Responding swing, sampling, timestamps, bounded history','PendulumWave','Compare the prescribed cube cycle with a responding pendulum. Reuse Trace to retain named position/time records and give their age visible depth. Compare coarse and fine sampling.','Rewritten and natively tested: cube bob, named position/time records, bounded history. The room is now an open gallery with a larger pendulum, floor projection, enlarged paintings and an accessible hand timeline.','A sampled return can become spatial spacing.'),
('WaveFunctions_Sine_Space','Space','Spatial frequency, height field, collision','sine_flow_tray','Return to the grid and familiar triangles. Sample one spatial rule and predict its relief. Release the sphere over the separate collision surface.','Rewritten and natively tested: one static surface, the carried PointBody, and a coarse grid that misses the crests. The room now gives tray, corridor and terrain a supported route.','A repeating coordinate invites inspection of its circle construction.'),
('WaveFunctions_Unit_Circle','Projection','Radians, sine/cosine, phase','unit_circle_advanced','Open the circular sampler used earlier. Move the same point around a circle, project its coordinates and predict the quarter turns.','Rewritten and natively tested: one centred circle function, shared angle and a graph with declared axes. Seven exhibits retained in an open gallery with a reachable angle control.','A local oscillator can now be coupled to its neighbours.'),
('WaveFunctions_3D_Wave_Propagation','Neighbour','Local coupling, old/next arrays','coupled_oscillator_lattice','Carry PointBody and LineSkin into nine vertical oscillators. Raise the centre. Read one shared old state before committing the next; compare coupled and independent motion, then test seven points and half the initial height.','Rewritten and natively tested: 28 printed-code checks, three rejected faults and 54 actual-museum checks. All five exhibits retained in separate bays. Distinguish neighbour coupling from the prescribed radial field.','A rule can let one oscillation affect another.'),
('WaveFunctions_Effect_Sound','Modulation','Phase modulation, time units, sampling','DualBallFMController','Use one sine inside another’s phase. Retain a reference, change depth, predict a sample and listen through a declared encoder.','Preserve the accurate phase-modulation distinction despite the artifact’s FM name.','The same periodic coordinates can also build a surface.'),
('Wavefunctions_Bernini','Twist','Ring profiles, phase through height','bernini_columns','Return to Primitives’ rings and connectivity. Rotate successive profiles by different angles. Stop whole-object rotation and inspect the twist that remains.','Replace the old breathing-mesh framing with the installed shaft’s construction.','Distinguish a stored spatial pattern from events arriving in time.'),
('WaveFunctions_John_Cage','Event','Bounded choice, event list, replay','john_cage_tech_noir','Compose from a declared vocabulary. Keep chosen events and their times, then replay the record before asking for another.','Current reflection is useful. Tutorial needs a bounded score; do not claim a microphone or a Cage score.','A strike supplies an event whose response has its own age.'),
('WaveFunctions_AirMusic','Voice','Independent onset, age, decay','resonating_metallophone','Strike one voice, then another. Keep each voice’s start time. Compare overlapping voices with restriking a voice whose buffer restarts.','Keep the distinction between a synthesised response and a physical bar model.','Sampling and timing also determine a route a body can use.'),
('Wavefunctions_Sky_Stairs','Footing','Circular placement, rise, usable width','sine_cylinder_staircase','Reuse the circular sampler to place a few treads. Compare centre spacing with inner and outer edges. Inspect the collision that actually supports the visitor.','Remove archived alternative-stair material from the tutorial when rewriting.','A regular rule can still give unequal conditions across its extent.'),
('WaveFunctions_TrigWalkingPath','Beat','Frequency difference, signed sum, gain','beat_frequency_demo','Sample two close frequencies at shared times. Keep A, B and their raw sum; predict reinforcement before normalising any drawing.','Separate the beat exhibit from the finite circulating path; remove the obsolete endless-path proposal.','Two components become a finite recipe of many components.'),
('WaveFunctions_Synthesis_Lab','Compose','Harmonic coefficients, shared phase, finite sum','additive_wave_demo','Store five coefficients and evaluate every term at one time. Retain another recipe and compare. State what the restricted coefficient set cannot express.','Keep room-memory listening as another encounter, not a hidden audio dependency of the five-term lesson.','Carry explicit recipes and limits into the next sequence.')
]

STYLE = '''body{margin:0;background:#f0efe9;color:#222;font:18px/1.6 Georgia,serif}header,main{max-width:1420px;margin:auto;padding:28px}header{border-bottom:2px solid #333}h1{font-size:44px;line-height:1.1;max-width:900px}h2{font-size:28px}h3{font-size:21px}a{color:#31586c}nav{display:flex;gap:24px;flex-wrap:wrap;font:16px system-ui}article{background:#fffdf6;padding:30px;min-width:0}pre{overflow:auto;padding:18px;background:#edf0ed;font:13px/1.6 Consolas,monospace}code{font-size:.86em}p{max-width:75ch}.parallel,.pictures{display:grid;grid-template-columns:1fr 1fr;gap:24px}img{width:100%;display:block}figure{margin:0}figcaption,.note{font:14px/1.5 system-ui;margin:10px 0 25px;color:#555}.route{display:grid;grid-template-columns:repeat(3,1fr);gap:18px}.route article{padding:22px;border-top:4px solid #668690}.tag{font:13px system-ui;letter-spacing:.08em;text-transform:uppercase;color:#44616b}.status{background:#e2ebe7;padding:12px;font:15px system-ui}table{border-collapse:collapse;width:100%;font:15px/1.5 system-ui}td,th{padding:12px;border:1px solid #bbb;text-align:left;vertical-align:top}@media(max-width:950px){.parallel,.pictures,.route{grid-template-columns:1fr}h1{font-size:32px}main,header{padding:18px}}@media print{nav{display:none}.route{grid-template-columns:1fr 1fr}article{break-inside:avoid}pre{white-space:pre-wrap}}'''

def render(text): return markdown.markdown(text, extensions=['fenced_code','tables'])
def page(title, content):
    return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+STYLE+'</style><header><div class="tag">Endless Museum · Wavefunctions · 8 October 2026</div><h1>'+html.escape(title)+'</h1><nav><a href="index.html">Route & evidence</a><a href="parallel.html">Tutorial left · reflection right</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="ROUTE.md">Editable route</a></nav></header><main>'+content+'</main></html>'

def main():
    tutorial = TUTORIAL.replace('{CODE}',block('01_cube_return.gd',CODE.read_text(encoding='utf8')))
    tutorial = tutorial.rstrip() + '\n'
    (MAP/'tutorial.md').write_text(tutorial,encoding='utf8')
    (MAP/'final.md').write_text(FINAL,encoding='utf8')
    (OUT/'tutorial.md').write_text(tutorial,encoding='utf8')
    (OUT/'final.md').write_text(FINAL,encoding='utf8')
    route = '# Wavefunctions — what returns\n\nStart with the cube from Transformation. Open its repeating movement through amplitude, frequency and phase; then compare a responding pendulum, records, spaces, sounds and sums. Reuse earlier constructions without forcing every hall to use the same shape.\n\nStatus: the opening, Pendulum, Sine Space, Unit Circle and Propagation lessons are rewritten. The following seven rows await the teaching pass. The museum order is retained; Pendulum’s room has been spatially redesigned at the author’s request. See ../2026-10-08-pendulum-a-record-of-return/index.html and ../2026-10-08-sine-space-a-surface/index.html; Unit Circle is at ../2026-10-08-unit-circle-two-coordinates/index.html. Propagation is at ../2026-10-08-wave-propagation-between-points/index.html. These contain the new lessons and native evidence. Form Finding remains a separate, paused rethink.\n\n'
    cards = ''
    for i,(key,title,subjects,primary,task,status,carry) in enumerate(ROWS,1):
        route += f'## {i}. {key} — {title}\n\n{task} Carry onward: {carry}\n\n- Learning elements: {subjects}.\n- Primary artifact: `{primary}`.\n- Review: {status}\n\n'
        cards += f'<article><div class="tag">{i:02} · {html.escape(key)}</div><h3>{title}</h3><p><strong>{subjects}</strong></p><p>{task}</p><p>{carry}</p><div class="note">{status}</div></article>'
    route += '## Rule for the next pass\n\nEncounter the existing artifact → carry the prior code → add one operation → predict one result → build an independent case → test the printed source in Godot → place it in the actual hall → read tutorial and final together. Declare support code, clocks, units and model limits. A passing engine test is not proof of human understanding or headset comfort.\n'
    (OUT/'ROUTE.md').write_text(route,encoding='utf8')
    (OUT/'route.json').write_text(json.dumps([dict(map=r[0],title=r[1],subjects=r[2],primary=r[3],summary=r[4],review=r[5],carry=r[6]) for r in ROWS],indent=2),encoding='utf8')
    (OUT/'tutorial.html').write_text(page('The cube returns','<article>'+render(tutorial)+'</article>'),encoding='utf8')
    (OUT/'final.html').write_text(page('The cube comes back','<article>'+render(FINAL)+'</article>'),encoding='utf8')
    (OUT/'parallel.html').write_text(page('Two readings of a return','<p>Left: reconstruct and investigate. Right: reflect on the existing artifact. They meet at the same question without asking the prose to explain every line of code.</p><div class="parallel"><article><div class="tag">Tutorial</div>'+render(tutorial)+'</article><article><div class="tag">final.md</div>'+render(FINAL)+'</article></div>'),encoding='utf8')
    report = '''<p>Start with the cube from Transformation. Its rise and return make amplitude, frequency and phase visible. The pendulum remains a comparison in the hall and develops later in the sequence.</p><p class="status">Corrected after the author’s instruction: start with the cube. Tutorial and reflection now begin there. Pendulum, Sine Space, Unit Circle and Propagation are now also rewritten and tested; the later seven lessons remain planned. See the next hall’s review below.</p><h2>Inside the existing hall</h2><div class="pictures"><figure><img src="after/WaveFunctions_Intro/primary.png"><figcaption>The existing oscillating cube near the entrance, with its rail and markers.</figcaption></figure><figure><img src="after/WaveFunctions_Intro/student.png"><figcaption>The complete student cube script, temporarily mounted in the same museum hall.</figcaption></figure></div><h2>What changed</h2><p>The first draft jumped to a constrained sphere and hand release. The corrected lesson carries the cube’s existing mesh and time-based translation forward. It introduces three distinct controls: amplitude, frequency and phase. The full program is printed once and creates its own readout. The reflection follows the cube before meeting the pendulum.</p><h2>Validation</h2>{VALIDATION}<p class="note">These tests are teacher-authored. No independent ghost reconstruction or physical-headset test is claimed. The old pendulum results are archived under superseded-pendulum and do not validate this correction.</p><p><a href="../2026-10-08-pendulum-a-record-of-return/index.html#museum">Continue to Pendulum: new room, lesson and captures</a></p><p><a href="../2026-10-08-sine-space-a-surface/index.html#museum">Continue to Sine Space: surface, contact and a clear route</a></p><p><a href="../2026-10-08-unit-circle-two-coordinates/index.html">Continue to Unit Circle: one angle, two coordinates</a></p><p><a href="../2026-10-08-wave-propagation-between-points/index.html">Continue to Propagation: between points</a></p><h2>The twelve-hall route</h2><p>Cube cycle → responding swing and record → space → projection → coupling → modulation → geometry → event → voice → footing → beat → composition.</p><div class="route">{CARDS}</div>'''

    validation = ''
    test = OUT/'student-test.json'
    museum = OUT/'after/WaveFunctions_Intro/report.json'
    for path,title in [(test,'Native study'),(museum,'Museum placement')]:
        if path.exists():
            data=json.loads(path.read_text(encoding='utf8'))
            checks=data.get('checks',[])
            validation += f'<p>{title}: {sum(bool(c["passed"]) for c in checks)}/{len(checks)} checks. <a href="{path.relative_to(OUT).as_posix()}">Full results</a>.</p>'
    mutation_path = OUT/'mutation-tests.json'
    if mutation_path.exists():
        rejected = json.loads(mutation_path.read_text(encoding='utf8'))
        validation += f'<p>{sum(x["rejected"] for x in rejected)}/{len(rejected)} deliberately broken updates rejected: missing cycle-to-radian conversion and accumulated height. <a href="mutation-tests.json">Fault checks</a>.</p>'
    validation += '<p><a href="code-check.json">Printed-source correspondence</a> · <a href="ROUTE.md">Editable sequence plan</a></p><p class="note">The existing museum reports a blocked authored entrance and uses its safe fallback. This pass checks the study bay; full passage and headset validation remain open. Existing UID and renderer warnings are retained in the logs.</p>'
    (OUT/'index.html').write_text(page('Wavefunctions: what returns',report.replace('{CARDS}',cards).replace('{VALIDATION}',validation)),encoding='utf8')
    extracted=OUT/'extracted'; extracted.mkdir(exist_ok=True)
    entries={}
    for name,source in re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```', tutorial,re.S):
        original=CODE
        equal=source==original.read_text(encoding='utf8').rstrip()
        assert equal,name
        (extracted/name).write_text(source+'\n',encoding='utf8')
        entries[name]={'matches_source':equal,'lines':len(source.splitlines()),'source':original.relative_to(ROOT).as_posix()}
    (OUT/'code-check.json').write_text(json.dumps(entries,indent=2),encoding='utf8')
    print('Published opening lesson, paired readings and twelve-hall route.')

if __name__ == '__main__': main()
