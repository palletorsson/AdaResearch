"""Publish inspected native evidence of the threshold workshop on main floor 14."""
from pathlib import Path
import html,json,shutil
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/threshold-workshop';NATIVE=ROOT/'ada_run/matter-reference';DOC=ROOT/'doc/ports/2026-10-25-matter-and-logic';GALLERY=ROOT/'doc/book/iterations/2026-10-25-almost-and-just'
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
receipts={name:read(NATIVE/(name+'.json')) for name in ['threshold-workshop-checks','threshold-workshop-controls-checks','threshold-workshop-controls-focus-checks','threshold-main-checks','threshold-main-east-checks','threshold-main-capture-checks']}
receipts.update({name:read(OUT/(name+'.json')) for name in ['save-checks','editor-checks','export']})
assert all(r['passed'] for r in receipts.values())
rooms=read(ROOT/'commons/void/rooms.json');floor=rooms['floors'][14];assert len(floor['artifacts'])==10
GALLERY.mkdir(parents=True,exist_ok=True)
names=['threshold-main-overview','threshold-main-east-bay','threshold-main-almost-detail','threshold-main-just-detail',*['threshold-main-'+k for k in ['again','almost','just','barely','still','descent']]]
for name in names:shutil.copy2(NATIVE/(name+'.png'),GALLERY/(name+'.png'))
status=dict(request='Continue Almost and the related threshold ideas; place them into the main tutorial now.',state='reviewed',floor=14,map='Trans_Introduction',studies=['Again','Almost','Just','Barely','Still','Eventually'],placement='Five on the north slab, Eventually rotated into the east bay. Original crossings and logic retained.',editable_parts=receipts['editor-checks']['parts'],checks={k:dict(passed=v['passed'],assertions=len(v.get('checks',[]))) for k,v in receipts.items()},limitations=['Jolt observations are not identical Cannon thresholds.','Synthetic XR is not physical-headset acceptance.','Take history and live dial changes last for the loaded encounter; authored member positions use the shared editor save.','Main-floor inspection overview hides neighbouring floors/exhibits; actual-player aisle and controls have separate receipts.'])
(DOC/'THRESHOLD-WORKSHOP-STATUS.json').write_text(json.dumps(status,indent=2)+'\n',encoding='utf-8')
(DOC/'THRESHOLD-WORKSHOP.md').write_text('''# Almost and Just in the tutorial

The user explicitly chose main-tutorial placement. Six original threshold
mechanisms now live on floor 14 / Trans Introduction, following the existing
gravity logic. Five occupy the north strip, clear of the shafts; Eventually is
turned into the east bay. Its first position was visually blocked by the entry
ramp. The east-bay correction was reviewed with actual desktop/synthetic XR
walking, reachable controls and a settled native ball. Original floor objects,
crossings, floors 0–13 and 15–204 remain unchanged.

The grammar is adjustment → release → wait → witness → repeat. Almost changes
the real release centre in one-millimetre steps using the original source
equation, and its red witness holds the actual maximum height. Just starts with
the source's preloaded pan, accepts one pending physical grain, waits for the
needle to settle and lets the sixth grain tip its default 5.6-grain balance.
Automatic feeding is available only as an explicit selected mode. Neither
the witness nor the control buttons decide the physical outcome.

Again compares return/drift/escape; Barely measures the block's actual tilt;
Still records hesitation before a side is reached; Eventually exposes cooling
and the valley actually reached. Each keeps the last three completed takes
across RESET, REPEAT and source-preset changes. History is encounter-local;
it is not a persistent player experiment notebook yet. Source presets retain
their original values; Cannon/Jolt numerical thresholds are not asserted equal.

The two added witness types and existing bodies/frames/consoles remain separate
editor parts. Native geometry was exported from Godot. The actual editor model
moved/rotated every member, copied all six ledgers and passed the production
validate-only save path. Placement itself was saved by that production API and
verified against the shared Desktop/VR mirror. No test edits were saved.

`threshold-main-checks.json` retains the first layout receipt. The later
`threshold-main-east-checks.json` supersedes its Eventually position and east
approach. Final canonical facing is 270 degrees, equivalent to tested −90.
The gallery distinguishes first-person player screenshots from isolated-floor
inspection views. Physical headset ergonomics and the whole tutorial route are
not accepted by synthetic XR.
''',encoding='utf-8')
studies=[('again','Again','Bowl, flat, dome: does the same small release return, drift or escape?'),('almost','Almost','Change one millimetre. The red witness holds how high the ball actually climbed.'),('just','Just','Add a grain, wait for the needle, then add another. The sixth tips this balance.'),('barely','Barely','Watch the block rock onto its corner and compare its peak tilt.'),('still','Still','A tiny offset and a long hesitation before the ball chooses a side.'),('descent','Eventually','Let the shaking cool. Which valley does the ball actually reach?')]
cards=''.join(f'<article><h2>{title}</h2><p>{html.escape(text)}</p><a href="threshold-main-{kind}.png"><img loading="lazy" src="threshold-main-{kind}.png" alt="Actual main-floor desktop view of {title}"></a></article>' for kind,title,text in studies)
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Almost and Just — main tutorial</title><style>*{box-sizing:border-box}body{margin:0;background:#eee9df;color:#241f28;font:16px/1.5 system-ui,sans-serif}main{max-width:1250px;margin:auto;padding:40px 24px}h1{font-size:clamp(36px,5vw,66px);line-height:1.08}a{color:#7e2150;text-underline-offset:3px}p{max-width:900px}img{width:100%;height:auto;display:block}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,450px),1fr));gap:24px}article{border-top:3px solid #e45391;padding-top:12px}figure{margin:28px 0}figcaption{font-size:13px}.notice{border-left:4px solid #bd3a77;padding:14px 20px;background:#e8dce2}</style><main><p>MATTER / MARGINS / FLOOR 14</p><h1>Almost. Just.<br>Wait for what happens.</h1><p>Six physical studies join the gravity logic beneath Trans Introduction's crossings. Adjust, release, wait, compare, try again. The parts remain independently editable.</p><p><a href="/lab-editor?mode=void&floor=14">Open main floor 14 in the editor ↗</a> · <a href="/book-review/doc/book/iterations/2026-10-25-matter-and-logic/index.html#almost-and-just">The full source collection ↗</a></p><p class="notice">Real desktop input, synthetic XR, aisle walking and native physical readings passed. Physical headset testing remains. The overview and detail inspection views hide neighbouring floors; the six player views below come from the actual game.</p><figure><img src="threshold-main-overview.png" alt="Floor 14 inspection view with five threshold studies beside the existing crossings"><figcaption>North side of floor 14. Existing crossings and logic remain.</figcaption></figure><div class="grid"><figure><img src="threshold-main-almost-detail.png" alt="Almost's actual maximum-height witness"><figcaption>Almost: the red mark records the measured rise.</figcaption></figure><figure><img src="threshold-main-just-detail.png" alt="Just after its sixth physical grain tips the balance"><figcaption>Just: the sixth grain tips a 5.6-grain counterweight.</figcaption></figure></div><figure><img src="threshold-main-east-bay.png" alt="Eventually turned into the east bay away from the entrance ramp"><figcaption>Eventually turns toward the east aisle, clear of the entrance ramp.</figcaption></figure><section class="grid">'''+cards+'''</section><p>Native Jolt measurements; source Cannon threshold numbers can differ. The last three takes are retained while the encounter is loaded.</p></main></html>'''
(GALLERY/'index.html').write_text(page,encoding='utf-8')
print(json.dumps(dict(published=True,floor=14,studies=6,parts=status['editable_parts'],screenshots=len(names))))
