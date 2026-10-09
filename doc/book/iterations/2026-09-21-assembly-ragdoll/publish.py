from pathlib import Path
import difflib,hashlib,html,json,re
import markdown
H=Path(__file__).resolve().parent;R=H.parents[3]
room='AdvancedLaboratory_Lab_Equipment_Simulation';M=R/'commons/maps'/room
rel=H.relative_to(R).as_posix()
report=json.loads((H/'museum-runtime.json').read_text(encoding='utf-8'))
assert report['passed'] and all(c['ok'] for c in report['checks']) and all(w['passed'] for w in report['walks'])
old=(H/'before/commons/maps'/room/'final.md').read_text(encoding='utf-8');new=(M/'final.md').read_text(encoding='utf-8')
assert old.split('<!-- @ -->')[0] in new
assert 'SCRIPT ERROR' not in (H/'museum-process.log').read_text(encoding='utf-8',errors='replace')
changed=['algorithms/computationalbiology/molecular_framework/'+f for f in ['MolecularDesigner.gd','AssemblyRagdoll.gd','AssemblyRagdollGrip.gd']]+['commons/maps/'+room+'/'+f for f in ['map_data.json','final.md','technical.md','critical.md']]+['commons/data/museum_core_encounters.json']
for name in changed:
    before=H/'before'/name;original=before.read_text(encoding='utf-8') if before.exists() else ''
    current=(R/name).read_text(encoding='utf-8')
    diff=''.join(difflib.unified_diff(original.splitlines(True),current.splitlines(True),fromfile='before/'+name,tofile=name))
    target=H/('final.diff' if name.endswith('/final.md') else name.replace('/','__')+'.diff')
    target.write_text(diff,encoding='utf-8')
(H/'current-final.md').write_text(new,encoding='utf-8')
(H/'current-inputs.json').write_text(json.dumps({p:hashlib.sha256((R/p).read_bytes()).hexdigest() for p in changed},indent=2)+'\n',encoding='utf-8')
images=[('museum-hanging.png','The body hangs at standing scale. Coral rings mark the parts you can take.'),('museum-pulled.png','A controlled hand pull travels through the elbow and shoulder. A thin elastic tether makes the distance from the held target visible.'),('museum-released.png','The hand has been released. Gravity, rotating joints and floor contact settle the body.'),('museum-bodies.png','Three encounters in Assembly: the automatic catalogue, the gold editable body, and the physical puppet.')]
figures=''.join('<figure><a href="'+n+'"><img src="'+n+'" alt="'+html.escape(c)+'" loading="lazy"></a><figcaption>'+html.escape(c)+'</figcaption></figure>' for n,c in images)
style="""*{box-sizing:border-box}body{margin:0;background:#eee9df;color:#213238;font:18px/1.7 Georgia,serif}main{max-width:1360px;margin:auto;padding:48px 32px}.eyebrow,nav,.note,figcaption{font-family:system-ui,sans-serif}.eyebrow{text-transform:uppercase;letter-spacing:.12em;font-size:12px;color:#357078}h1{font-size:clamp(40px,6vw,76px);font-weight:400;line-height:1.08;max-width:950px;margin:20px 0}.intro{font-size:25px;max-width:840px}a{color:#176976}nav{display:flex;gap:12px;flex-wrap:wrap;margin:26px 0}nav a{padding:8px 14px;border:1px solid #9cada8;border-radius:30px;text-decoration:none;font-size:14px}.gallery{display:grid;grid-template-columns:1fr 1fr;gap:22px}figure{margin:0}img{width:100%;display:block;border-radius:5px}figcaption{font-size:14px;padding:10px 0 20px}.note{font-size:14px;background:#dfe6df;padding:18px 22px;margin:30px 0}h2{font-weight:400;font-size:34px}.reading{display:grid;grid-template-columns:1fr 1fr;gap:40px}.reading article{padding:25px;background:#f8f5ee}.reading h1{font-size:33px}.reading p{font-size:17px}pre{white-space:pre-wrap;overflow-wrap:anywhere;font-size:13px;line-height:1.5;background:#dfe6df;padding:14px}summary{cursor:pointer;font-family:system-ui,sans-serif;padding:15px 0}.excerpt{max-width:780px;font-size:21px;border-left:3px solid #d87951;padding-left:25px}@media(max-width:800px){.gallery,.reading{grid-template-columns:1fr}main{padding:25px 18px}}"""
excerpt=new.split('Another body waits')[1].split('<!-- @ -->')[0]
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Assembly — a body with weight</title><style>'+style+'</style><main><div class="eyebrow">Ada Research · Assembly Laboratory · 21 September 2026</div><h1>Pull one part.<br>What follows?</h1><p class="intro">A ragdoll made from the familiar body. You can pull a hand, a foot, a shoulder — and watch the rest negotiate the movement.</p><p>The gold body keeps your alteration. This one has weight, rotating joints and a floor to meet. The comparison belongs in the room.</p><nav><a href="#encounter">Read the new passage</a><a href="#compare">Original / current chapter</a><a href="final.diff">Exact text diff</a><a href="SUMMARY.md">Build and checks</a><a href="/compose/sources?map='+room+'&doc=final">Read in Compose</a></nav><div class="gallery">'+figures+'</div><p class="note">Actual Godot museum captures from the same new implementation: hanging, controlled pull, release, and the wider hall. Twenty-four interaction and physics checks and five selected walking segments pass. Desktop carry and synthetic XRTools controllers were exercised. Headset feel, comfort and Quest performance are still to be tested.</p><section id="encounter"><h2>This elbow comes with it.</h2><div class="excerpt">'+markdown.markdown('Another body waits'+excerpt)+'</div></section><section id="compare"><h2>The chapter, before and now</h2><p>The earlier opening and coordinate/connection experiment are retained. The new encounter follows them; the closing sentence identifies the gold workshop as the body whose changes are saved.</p><div class="reading"><article><h3>Before</h3>'+markdown.markdown(old,extensions=['fenced_code','footnotes'])+'</article><article><h3>Current</h3>'+markdown.markdown(new,extensions=['fenced_code','footnotes'])+'</article></div></section></main></html>'
(H/'index.html').write_text(page,encoding='utf-8')
summary=f"""# Assembly: a body with weight

Implemented beside the existing automatic catalogue and gold coordinate/graph workshop in AdvancedLaboratory_Lab_Equipment_Simulation. The opt-in `body_ragdoll` reuses VRBody's thirteen named points, with ten rigid parts and nine freely rotating pin joints. Its ten physical bodies remain unfrozen while a held coral ring supplies a bounded spring-force target. Non-adjacent parts collide; anatomical angular limits are not implemented. The two hip attachments are separated to keep the legs distinct. No new scene token, primary filter change or catalogue-wide behavior was needed.

First grab releases the head support. Any limb can be pulled, including two at once with XRTools controllers. Releasing removes the hand force; the puppet falls and settles on the floor. A visible elastic tether makes the held target's lag legible. HANG AGAIN resets and supports it; reset refuses while held. This study does not write a pose. The gold workshop and its Synthesis return are preserved.

## Evidence

- {len(report['checks'])} runtime/interaction checks pass, including actual desktop ray selection and carrying, synthetic two-controller XRTools pickup/release, force transmission, release/fall, reset, opt-in isolation and unchanged gold/save state.
- {len(report['walks'])} continuous selected walking segments pass, from entrance through the central lane to the mat approach and exit.
- Measured controlled pull: hand moved {report['drag']['hand_distance']:.3f} m; elbow moved {report['drag']['elbow_distance']:.3f} m; maximum sampled constraint-anchor separation at the checked drag state was {report['drag']['constraint_gap']:.4f} m.
- After release the highest part centre was {report['released']['highest_part_center']:.3f} m above the study floor. This is a centre measurement, not maximum mesh height. Reset head-position error was {report['reset_head_error']:.4f} m.
- Godot exits 0, no script errors. An existing unrelated unrecognized UID warning and museum environment/dressing warnings remain in the saved log.
- Four actual rendered views inspected. They show states of the new implementation, not a human session or a before/after implementation comparison.

Creation and reset originally exposed stale physics attachment transforms. Synchronizing body transforms before joint creation/reset fixes both the misplaced initial hand and head reset. The final repeat passes all checks. The grab spring was then made firmer and its elastic gap drawn explicitly; this final implementation is the one captured and measured here.

The chapter preserves its entire earlier encounter before the new addition. The extension moves from a hand that lengthens a visual relation to one that pulls its neighbours, then asks how support and constraint contribute to a perceived gesture. Exact text/source diffs, baseline copies, source manifest and current input hashes are beside this report.

## Scope

Headset reach, physical feel, haptics, comfort, Quest performance and learner understanding remain open. Free pin joints make this a stylized ragdoll rather than an anatomical model. The live game was not restarted; no live museum bake or visitor pose was replaced. No commit was made. The full-book export for Claude remains frozen.

Collective Knowledge restoration remains separately parked; see ../2026-09-21-commons-restoration/PENDING.md before resuming it.
"""
(H/'SUMMARY.md').write_text(summary,encoding='utf-8')
p=R/'doc/book/iterations/2026-09-19-review-comparison/postfoundationscrisis.json';d=json.loads(p.read_text(encoding='utf-8'));title='Assembly: a body with weight'
d['items']=[i for i in d['items'] if i.get('title')!=title]
d['items'].append(dict(title=title,description='The familiar body becomes a grabbable physics puppet. Pulling a hand carries the elbow and shoulder; release lets it fall. Compare it with the gold body that keeps a pose.',images=[rel+'/'+n for n,c in images[:3]],captions=[c for n,c in images[:3]],image_note='Actual Godot views of hanging, controlled pull and release in the new implementation. Synthetic VR checks are not headset experience.',text_kind='New immersive comparison; existing chapter retained — 21 September',before='Moving the hand does not pull the elbow after it. The gold connection follows its endpoints, but it does not enforce the length of a bone.',after='Another body waits over a dark mat. You recognise its head, shoulders, hands. Coral rings mark places your hand can take. Pull one wrist. This elbow comes with it.',report=rel+'/index.html',report_label='See the ragdoll and compare the chapter'))
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Published review, four captures, exact diffs and verified evidence.')
