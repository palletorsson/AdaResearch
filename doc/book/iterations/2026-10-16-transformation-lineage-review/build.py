"""Read the existing Transformation lessons; publish an editorial review only."""
from pathlib import Path
import hashlib
import html
import json
import re
import urllib.request

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
EARLIER = ROOT / 'doc/book/iterations/2026-10-12-transformation-in-the-book'
HALLS = ['Trans_Pre', 'Trans_Introduction', 'Trans_Translation', 'Trans_Rotation', 'Trans_Scale', 'Trans_Body', 'Trans_Pit']

ROWS = [
    dict(id='Trans_Pre', title='A familiar shape gains behaviour',
         bring='Point Zero’s clock; coordinates; visible geometry versus a boundary; the cube construction already understood.',
         learn='Position, orientation and uniform scale; elapsed time; a returning fraction; collection through an overlap signal.',
         carry='A whole-box visual, a time-driven pose and the player-filtered collection connection. Preserve the collectible version for Arrays.',
         fix='Resolve the upstream promise to carry CubeBody. The accepted lesson deliberately uses BoxMesh. Name this as a change of representation, including its centred origin. Read the existing lesson in two stages: movement, then collection.',
         mismatch='The current subject labels fit. The contradiction is with Cube and Melencolia’s promised class handoff.',
         print_new='The first complete transform-and-collection program. Identify inherited construction; explain the new pose and signal.',
         check='At a fixed elapsed time, predict each property. Double period: rise and pulse slow; turning does not. Only a qualifying body collects it.'),
    dict(id='Trans_Introduction', title='The same fraction compares three crossings',
         bring='Pre’s box construction, three transform properties and returning time value; functions and loops from Primitives.',
         learn='A held pose fraction; scalar interpolation; a returning constructor reused to make independent visual models.',
         carry='A reusable visual construction and apply_pose(t): input and resulting pose can be inspected separately from the clock.',
         fix='Keep the construction function available to later lessons instead of returning to inline mesh setup. Correct the card that currently selects the bank-slider/reset lesson. Say that duration is one leg here; Pre’s period was the whole return cycle.',
         mismatch='The saved card selects slider/RESET signals, target/current state and gradual reset. The canonical program instead compares three visual models. Its code contains none of that control wiring.',
         print_new='The small returning constructor, apply_pose and the exact arrangement changes. Link the complete current host online.',
         check='Hold t at 0, 0.5 and 1. Move the far bank 0.5 m; the same final transform now leaves a gap.'),
    dict(id='Trans_Translation', title='Prescribe a journey',
         bring='Introduction’s travelling visual and interpolation; Lines’ displacement; Trace’s positions and conditions.',
         learn='Vector interpolation; a bounded one-way journey; a branch choosing a direct or two-part route.',
         carry='Positions can prescribe a route as well as record one. The object’s orientation and dimensions remain independent of travel.',
         fix='Carry the box constructor rather than rebuild it. Align the card with the actual two-segment lesson. Keep waypoint indexing and zero-length-leg guards as a possible later extension; they are not in this program.',
         mismatch='The saved card promises waypoint lists, retained route index and zero-length guards. The program has start/finish/corner variables and two branches. Unequal legs intentionally receive equal time.',
         print_new='The start/finish values and complete route-selection update. Explicitly replace the returning clock with a clamped one-way fraction.',
         check='At two seconds the direct path reaches (0,2,0), the corner path (-2,3,0). Both finish at (2,3,0); the basis and dimensions stay fixed.'),
    dict(id='Trans_Rotation', title='Move the reference frame',
         bring='The visual box and clock; Coordinates’ local/world distinction; Translation’s separation of position from orientation.',
         learn='Axis, angle and pivot; degree-to-radian conversion; a fixed child offset beneath a rotating parent.',
         carry='The parent-child relation: a fixed local position can have a changing world position. Rotation preserves internal distances.',
         fix='Reuse visual construction for the cube and its face mark. Print the changed hierarchy and orientation calculation. Remove operation-order comparison from the required lesson labels unless a separate extension is deliberately selected.',
         mismatch='The card promises reversed rotation order; the canonical tutorial explicitly leaves that museum comparison beyond its single-axis lesson.',
         print_new='Pivot attachment, fixed offset, visible face mark and the complete orientation update. Keep the complete result online.',
         check='Quarter-turn prediction with a two-metre offset; local offset stays fixed, world centre changes, full turn returns the mark.'),
    dict(id='Trans_Scale', title='Change one group, keep a reference',
         bring='Rotation’s parent-child relationship and the box construction; the sphere’s earlier geometric recipe.',
         learn='Uniform and unequal scale; the scaling origin; which children inherit a change; fixed reference measurements.',
         carry='A transform’s scope and a deliberately chosen factor. Origin placement determines whether the base stays on the floor.',
         fix='Keep the visual constructor while changing its parent explicitly. Link the complete fixed witness construction once: it is a new mesh instance using a familiar sphere shape, not the carried pickable PointBody. Narrow the card from editing the supplied room to constructing the small doorway comparison.',
         mismatch='The subjects broadly fit, but the card’s focus describes the installed room and a supplied opening comparison; the lesson constructs a three-box doorway. Relocation is discussed, not reconstructed.',
         print_new='The parent assignment, three placements and factor; a one-line reference identifies the fixed witness code and its role.',
         check='Uniform 4× produces a 1.80 × 2.40 m opening. Width-only 4× leaves height at 0.60 m. Witness diameter stays 0.65 m.'),
    dict(id='Trans_Body', title='Replace the clock with approach',
         bring='Scale’s factor, Lines’ distance, Coordinates’ world frame, and the museum player contract already named in Pre.',
         learn='Horizontal world separation; range mapping and clamping; one input controlling scale or turn; reversible response.',
         carry='A bounded response driven by the visitor. The body can change and return without keeping a history.',
         fix='Reuse the box visual; concentrate printed code on the input connection and respond(distance). Remove retained-flag and collision-update promises from the card. The current program is visual and intentionally has no visit memory.',
         mismatch='The card selects a remembered visit and says visitor input/collision updates are supplied. The program performs the player lookup itself, has no retained visit flag and creates no collider.',
         print_new='Declared player lookup, same-frame subtraction and the complete mapping/response function. No repeat of visual construction.',
         check='Near/mid/far sizes, crouching does not affect horizontal distance, departure restores the pose; increasing far_distance to 6 moves the halfway response to 3.5 m.'),
    dict(id='Trans_Pit', title='Compose a solid opening',
         bring='Pre’s player filter and overlap area; Introduction’s shared pose; Rotation’s axis; Scale’s scope; Body’s reversible response; Trace’s arrays and loops.',
         learn='Continuing occupancy; target versus current progress; physics-time updates; moving solid bodies; matched visual/collision size; aligned reference arrays.',
         carry='A composed, solid opening. Arrays takes a separate return to Pre’s collectible cube, adding stable addresses and presence records.',
         fix='Keep the hall, but present three steps: construct and hold the solid leaves; derive a target from occupancy; approach the target over physics time. Declare the MeshInstance3D-to-AnimatableBody3D change. Reuse only the visual part of construction; the physics wrapper is new teaching code.',
         mismatch='The card calls frame, occupancy and physical wrappers supplied. The canonical 67-line program constructs all of them. This is the largest real teaching jump, not unchanged support.',
         print_new='Solid wrapper and matching boundary; occupancy-to-target logic; complete progress and pose functions. Link unchanged visual support and the full resulting files.',
         check='Closed blocks/open passes; intermediate visual and solid dimensions match; leaving midway reverses gradually; either remaining qualifying body holds it open.'),
]

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    api = json.load(urllib.request.urlopen('http://localhost:3003/api/tutorial-plan', timeout=60))
    route = next(s for s in api['cards']['sequences'] if s['id'] == 'transformation')
    assert route['maps'] == HALLS, 'Live order changed; review the selection.'
    archived = json.loads((EARLIER / 'verification.json').read_text(encoding='utf-8'))
    records = []
    pins = {}
    for row in ROWS:
        mid = row['id']
        source = ROOT / 'commons/maps' / mid / 'tutorial.md'
        pins[source.relative_to(ROOT).as_posix()] = sha(source)
        text = source.read_text(encoding='utf-8')
        blocks = re.findall(r'<!-- student-code:lesson.gd -->\s*```gdscript\n(.*?)^```', text, re.M | re.S)
        assert len(blocks) == 1
        script = EARLIER / mid / 'lesson.gd'
        same_text = pins[source.relative_to(ROOT).as_posix()] == archived['inputs'][source.relative_to(ROOT).as_posix()]
        same_code = blocks[0] == script.read_text(encoding='utf-8') and sha(script) == archived['inputs'][script.relative_to(ROOT).as_posix()]
        assert same_text and same_code, f'12 October evidence no longer matches {mid}'
        card = next(h for h in api['cards']['halls'] if h['id'] == mid)
        plan = next(p for p in api['plan']['lessons'] if p['id'] == mid)
        image = ROOT / f'doc/book/iterations/2026-10-04-museum-tutorial-storyboards/images/{mid}-1.webp'
        assert image.exists()
        records.append({**row, 'current_subjects': card['subjects'], 'current_focus': card['focus'],
                        'current_plan': plan, 'code_lines': len(blocks[0].splitlines()),
                        'tutorial_matches_12_oct_evidence': same_text, 'program_matches_12_oct_evidence': same_code})
    for mid in ['Point_Animatedcube', 'Primitives_Melencolia', 'Array']:
        p = ROOT / 'commons/maps' / mid / 'tutorial.md'
        pins[p.relative_to(ROOT).as_posix()] = sha(p)
    for rel in ['commons/maps/sequences/transformation.json','doc/book/course/execution-plan/plan.json']:
        pins[rel] = sha(ROOT / rel)
    report = {'date':'2026-10-16', 'kind':'editorial review and proposed fixes', 'route':HALLS,
              'decision':'Keep hall order. Reconcile teaching labels, state the representation branch, and make actual code continuations recoverable.',
              'changed_curriculum_or_runtime':False, 'rows':records, 'source_revision':api['revision'], 'source_hashes':pins,
              'checks':{'source_matches':14, 'native_rerun':False, 'archived_date':'2026-10-12', 'archived_assertions':archived['assertions'],
                        'archived_variants':archived['variant_count'], 'archived_faults_detected':sum(f['detected'] for f in archived['faults'].values()),
                        'limit':'Current source parity and editorial reading. No new runtime, headset or human learning assessment.'}}
    (HERE/'audit.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    e = html.escape
    cards = []
    for n, r in enumerate(records, 1):
        mid=r['id']
        cards.append(f'''<article id="{mid}"><div class="hall-top"><figure><img loading="lazy" src="/book-review/doc/book/iterations/2026-10-04-museum-tutorial-storyboards/images/{mid}-1.webp" alt="Archived museum view of {mid}"><figcaption>Museum context · archived 4 October; not a new learner render.</figcaption></figure><div><p class="kicker">{n:02} / {mid} · {r['code_lines']} printed code lines</p><h2>{e(r['title'])}</h2><p class="fix">{e(r['fix'])}</p><nav><a href="/book-review/commons/maps/{mid}/tutorial.md">Current tutorial</a><a href="/tutorial-cards?map={mid}">Current teaching card</a><a href="/book-review/doc/book/iterations/2026-10-12-transformation-in-the-book/{mid}/lesson.gd">Complete tested file</a></nav></div></div><div class="columns"><section><h3>Bring</h3><p>{e(r['bring'])}</p></section><section><h3>Learn</h3><p>{e(r['learn'])}</p></section><section><h3>Carry</h3><p>{e(r['carry'])}</p></section></div><details><summary>Where the current records disagree</summary><p>{e(r['mismatch'])}</p><p><b>Current card subjects:</b> {e('; '.join(r['current_subjects']))}</p><p><b>Current card focus:</b> {e(r['current_focus'])}</p></details><details><summary>Proposed book treatment and check</summary><p><b>Print:</b> {e(r['print_new'])}</p><p><b>Check:</b> {e(r['check'])}</p></details></article>''')
    page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Transformation — what actually carries forward</title><style>
    *{box-sizing:border-box}body{margin:0;background:#f1efe5;color:#24342f;font:16px/1.65 system-ui,sans-serif}main{max-width:1260px;margin:auto;padding:40px 40px 70px}a{color:inherit;text-underline-offset:4px}nav{display:flex;gap:20px;flex-wrap:wrap;font-size:13px}.kicker{font-size:12px;text-transform:uppercase;letter-spacing:.12em;color:#8c3e5b}h1,h2{font-family:Georgia,serif;font-weight:normal;line-height:1.15}h1{font-size:clamp(38px,5vw,64px);max-width:940px}h2{font-size:30px;margin:10px 0 20px}h3{font-size:12px;text-transform:uppercase;letter-spacing:.12em;color:#8c3e5b}.lead{font-size:22px;max-width:950px}.callout{border-left:4px solid #8c3e5b;background:#fff8;padding:18px 25px;margin:30px 0}.route{padding:20px;background:#dde5db;font-size:18px}.route small{display:block;font-size:14px;margin-top:10px}article{margin:55px 0;border-top:2px solid #273d35;padding-top:25px;scroll-margin-top:20px}.hall-top{display:grid;grid-template-columns:34% 1fr;gap:32px}figure{margin:0}img{width:100%;aspect-ratio:16/10;object-fit:cover}figcaption{font-size:11px;color:#607067}.fix{font-size:17px}.columns{display:grid;grid-template-columns:repeat(3,1fr);gap:30px;border-block:1px solid #c7d0c5;margin:25px 0 15px;padding:10px 0}details{border-bottom:1px solid #d7d9cd;padding:12px 0}summary{cursor:pointer;color:#77344e}details p{max-width:1000px}footer{border-top:2px solid #273d35;padding-top:25px;margin-top:50px}.facts{font-size:13px;color:#53645b}.priority li{margin:15px 0}code,pre{font-family:Consolas,monospace}pre{white-space:pre-wrap;background:#e3e8dc;padding:22px;font-size:13px}@media(max-width:760px){main{padding:25px 18px}.hall-top,.columns{display:block}.columns section{padding:8px 0}.hall-top figure{margin-bottom:20px}}@media print{body{background:white}main{padding:0}nav,details{display:none}article{break-before:page}img{max-height:180px}h1{font-size:30pt}}
    </style><main><nav><a href="/tutorial-plan/lineage?seq=transformation">Transformation overview</a><a href="README.md">Written review</a><a href="audit.json">Source checks and proposed rows</a></nav><header><p class="kicker">Endless Museum / Tutorial lineage review / 16 October 2026</p><h1>A moving box becomes a responsive opening.</h1><p class="lead">The hall order works. The learning builds through time, paths, moving frames, scale and bodily input. The main repairs concern what we promise to carry, which code really continues, and what the overview claims each lesson teaches.</p></header><div class="route">Clock + box → shared pose → journey → pivot → scale → approach → solid opening<small>Pre’s collectible cube also returns directly in Arrays. The door remains a completed composition; every future cube does not need its mechanisms.</small></div><div class="callout"><b>Review scope.</b> These are proposed repairs to the seven existing lessons. Tutorial code, final.md, teaching choices and museum order have not been changed. The pictures are dated museum context.</div><h2>The repairs that matter</h2><ol class="priority"><li><b>Resolve the Primitives handoff.</b> Cube and Melencolia promise CubeBody; the accepted Transformation opening deliberately uses BoxMesh. Keep that simpler accepted branch and correct the upstream promise. Its origin changes too: CubeBody runs from y=0 to 1; BoxMesh is centred. Reusing geometry knowledge is not carrying the same class.</li><li><b>Reconcile the teaching cards.</b> Several select older lessons: slider reset, waypoint index, reversed turns or remembered visits. The current tested programs choose smaller operations. Match the cards to those choices before expanding the writing.</li><li><b>Give repeated construction a recoverable source.</b> Introduction earns a box constructor, but Translation goes back to inline construction. A small shared visual helper is a reasonable next refactor. Parent choice and solid wrappers must stay explicit. Until that refactor is tested, keep the existing full scripts and show exact continuation edits in the book.</li><li><b>Make time and responsibility explicit.</b> Pre’s period means a full cycle; Introduction’s duration means one leg; Translation clamps at its destination. Pit introduces physics updates and solid boundaries. These are meaningful changes, not setup to hide.</li><li><b>Stage the last hall.</b> Hold a solid pose, read occupancy, then move toward the target. This lets the final composition collect earlier capabilities without presenting every new detail at once.</li></ol>
    ''' + ''.join(cards) + '''<footer><h2>How we can fix this sequence</h2><p>Start with the Primitives → Pre handoff and reconcile the current card labels. Then prepare one continuation at a time, beginning with Pre → Introduction. Retain complete, versioned online files; show complete new functions and exact edits in the book. Extract a helper only when its repetition earns that abstraction. Never describe Scale’s or Pit’s differently implemented box function as an unchanged file.</p><pre>BRING exact predecessor files + stated assumptions.
KEEP inherited construction; name a representation change.
BUILD one new capability; print complete changed units.
ASSEMBLE from predecessor + edits; compare with full result.
CHECK behaviour + variation + deliberate fault.
CARRY actual files/capacity; name a branch or return honestly.</pre><p class="facts">Evidence: all seven current tutorial hashes and seven printed programs match the 12 October source-bound verification. That archived run reports 204 assertions, 19 variants and 12 detected faults. This review did not rerun Godot. Those tests validate individual resulting programs; the runner does not mechanically reconstruct each hall from its predecessor. Learner understanding and headset use remain separate evidence.</p><nav><a href="/book-review/doc/book/iterations/2026-10-12-transformation-in-the-book/verification.json">12 October execution evidence</a><a href="/book-review/doc/book/iterations/2026-10-16-tutorial-lineage-and-editions/index.html">Book / encyclopedia reading proposal</a></nav></footer></main></html>'''
    (HERE/'index.html').write_text(page, encoding='utf-8')
    lines=['# Transformation: what actually carries forward','',
           '16 October 2026. Editorial review of all seven canonical tutorials, their saved teaching choices and the Primitives/Arrays handoffs. Keep the hall order. The conceptual progression holds; exact code continuity and some planning labels need repair.','',
           '**No canonical tutorial, final.md, teaching choice or museum code changed in this review.**','',
           '## Hall-by-hall repair plan','',
           '| Hall | Bring | Learn | Carry | Repair |','| --- | --- | --- | --- | --- |']
    for r in records:
        lines.append('| '+ ' | '.join(r[k].replace('|','\\|') for k in ['id','bring','learn','carry','fix'])+' |')
    lines+=['','## Where the records disagree','']
    for r in records: lines += [f"- **{r['id']}:** {r['mismatch']}"]
    lines+=['','## The first decisions','',
            '1. Keep the accepted whole BoxMesh branch. Update Cube/Melencolia’s forward promise to say which knowledge carries and which construction is replaced. CubeBody’s y=0..1 recipe and BoxMesh’s centred origin are not interchangeable. Returning to CubeBody is an alternative requiring an intentional lesson redesign, not an automatic repair.',
            '2. Reconcile the saved focus with the smaller accepted canonical lessons. Do not implement waypoint machinery, retained flags or reversed rotation order merely because an older card still lists them.',
            '3. Keep one lineage for the reusable visual construction. A candidate `box_visual.gd` would make a MeshInstance3D with an owned BoxMesh; the caller chooses parent and placement. This is proposed code, not an existing dependency. The last hall adds its solid wrapper explicitly. Avoid a universal artifact class or hidden collision support.',
            '4. Keep the full current scripts as recoverable edition states while trying the compact reading view. Show complete new functions and exact edits. Changed files are changed; the current three different `box` functions cannot be called unchanged support.',
            '5. Treat the Pit as a composition in three passes: solid pose; occupancy target; time-driven progress. Preserve Pre’s collectible snapshot for the branch into Arrays. A lineage can branch and reuse earlier work without passing every responsibility to every later object.','',
            '## What the tests establish','',
            'The 12 October runner extracts and runs each complete resulting lesson and its variants. It does not apply printed edits to a predecessor. Add that source-reconstruction gate when the compact continuation views are written: uniquely anchored edits + pinned incoming files must produce the downloadable full state. Then run the existing behavioural checks on that assembled output. Keep variation and fault tests. Do not turn automated execution into a claim about student understanding.','',
            'Current audit: all seven tutorial hashes and seven extracted programs match the archived evidence. That run records 204 assertions, 19 variants and 12 detected faults. No new Godot run was performed. See `audit.json` for source hashes and current/proposed teaching records.','',
            'The generic planner currently links older Pre ghost evidence as stale and no native record for the other six; the sequence’s 12 October evidence exists separately. Evidence discovery needs a later source-bound link, not an invented fresh test or a claim that these lessons have no checks.','',
            '## Compact writer instruction','',
            '```text','KEEP order and accepted simple BoxMesh branch.','RECONCILE card focus with the actual selected lesson.','BRING exact files; distinguish code carry from conceptual reuse.','PRINT new complete units + exact edits; link versioned full states.','NAME origin, duration, parent and physics responsibility changes.','ASSEMBLE from predecessor; test output, variation and fault.','RETURN Pre pickup to Arrays; retain Pit as a composition.','```','']
    (HERE/'README.md').write_text('\n'.join(lines), encoding='utf-8')
    for rel, original in pins.items():
        assert sha(ROOT/rel) == original, 'Source changed during review: '+rel
    print(json.dumps({'halls_reviewed':len(records),'source_parity_checks':14,'all_match':True,'archived_assertions':204,'native_rerun':False,'report':str(HERE/'index.html')}))

if __name__ == '__main__':
    main()
