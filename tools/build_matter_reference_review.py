"""Publish the inspected port receipts and native screenshot reading desk."""
from pathlib import Path
import hashlib, html, json, shutil, zipfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'ada_run/matter-reference'
DOC = ROOT / 'doc/ports/2026-10-25-matter-and-logic'
GALLERY = ROOT / 'doc/book/iterations/2026-10-25-matter-and-logic'
WEB = ROOT.parent / 'ada_encyclopedia'
TRIAL = 'matter_logic_reference'
PAGES = [
    ('matter-gates', 'Matter Gates', list(range(1, 7)), 'gate-checks.json'),
    ('gate-boards', 'Marble Gate Boards', list(range(7, 13)), 'marble-checks.json'),
    ('tyre-plank-wedge', 'Tyre, plank and wedge', [13], 'chain-checks.json'),
    ('stack-queue', 'Stack and queue', [14], 'stack-queue-checks.json'),
    ('call-stack', 'Call stack', [15], 'program-flow-checks.json'),
    ('if-else-loop', 'If / else loop', [16], 'program-flow-checks.json'),
    ('list-loop', 'List loop', [17], 'program-flow-checks.json'),
    ('prefab-loop', 'Prefab loop', [18], 'program-flow-checks.json'),
    ('matter-programs', 'Material programs', list(range(19, 23)), 'material-program-checks.json'),
    ('matter-pipelines', 'Material pipelines', list(range(23, 27)), 'material-program-checks.json'),
    ('almost-and-just', 'Almost and Just', list(range(27, 33)), 'threshold-checks.json'),
    ('gravity-knitter', 'Gravity Knitter', [33], 'knitter-checks.json'),
    ('rule-knitter', 'Rule Knitter', [34], 'knitter-checks.json'),
    ('collatz-marble-machine', 'Collatz marble machine', [35], 'collatz-checks.json'),
    ('collatz-knitting', 'Collatz knitting', [36], 'collatz-checks.json'),
]
RECEIPTS = ['gate-checks.json', 'review-checks.json', 'marble-checks.json',
            'chain-checks.json', 'stack-queue-checks.json', 'program-flow-checks.json',
            'material-program-checks.json', 'threshold-checks.json', 'knitter-checks.json',
            'collatz-checks.json', 'player-load-checks.json',
            'collection-capture-checks.json', 'editor-checks.json',
            'hand-control-checks.json', 'primary-controls-gates-both-checks.json',
            'primary-controls-gate-inputs-both-checks.json',
            'primary-controls-programs-both-checks.json',
            'primary-controls-programs-both-focus-checks.json',
            'primary-controls-knitting-both-checks.json', 'controls-capture-checks.json',
            'knitter-placement-checks.json', 'threshold-workshop-checks.json',
            'threshold-workshop-controls-checks.json', 'threshold-workshop-capture-checks.json',
            'threshold-main-checks.json', 'threshold-main-east-checks.json',
            'threshold-workshop-controls-focus-checks.json', 'threshold-main-capture-checks.json']

def read(path):
    return json.loads(path.read_text(encoding='utf-8'))

def main():
    source = read(ROOT / 'ada_run/matter-logic-reference/source.json')
    archive = Path(source['zip'])
    assert hashlib.sha256(archive.read_bytes()).hexdigest() == source['sha256']
    original = Path(source['reference'])
    with zipfile.ZipFile(archive) as z:
        for entry in z.infolist():
            if entry.is_dir():
                continue
            relative = Path(*Path(entry.filename).parts[1:])
            assert (original / relative).read_bytes() == z.read(entry), entry.filename
    receipts = {name: read(OUT / name) for name in RECEIPTS}
    assert all(r['passed'] for r in receipts.values())
    assert 'neighboring exhibits hidden' in receipts['collection-capture-checks.json']['scope']
    assert receipts['editor-checks.json']['floors'] == 36
    manifest = read(WEB / 'public/void-trials' / TRIAL / 'manifest.json')
    assert not manifest['failures'] and not manifest['export_shutdown_diagnostics']
    count = 0
    urls = set()
    label_only = 0
    for floor in manifest['floors'].values():
        for item in floor['artifacts'].values():
            for part in item['parts'].values():
                count += 1
                if part.get('url'):
                    urls.add(part['url'])
                else:
                    label_only += 1
    photos = [int(c['name'].split()[1]) for c in receipts['collection-capture-checks.json']['checks']]
    GALLERY.mkdir(parents=True, exist_ok=True)
    for n in photos:
        shutil.copy2(OUT / f'collection-f{n:02}.png', GALLERY / f'floor-{n:02}.png')
    console_photos = [int(c['name'].split()[2]) for c in receipts['controls-capture-checks.json']['checks']]
    for n in console_photos:
        shutil.copy2(OUT / f'controls-floor-{n:02}-desktop.png', GALLERY / f'controls-{n:02}.png')
    for mode in ['desktop', 'xr']:
        shutil.copy2(OUT / f'hand-gate-{mode}.png', GALLERY / f'hand-gate-{mode}.png')
    status = {
        'request': 'All 15 examples from the newest downloaded ZIP, starting with logic gates.',
        'stage': 'All 15 native ports and their primary hands-on controls reviewed. Six threshold studies integrated additively into main floor 14 / Trans Introduction. Complete HTML widget parity and physical-headset acceptance remain outside this review.',
        'trial': TRIAL, 'study_floors': 36, 'editable_parts': count,
        'referenced_artifact_glbs': len(urls), 'label_only_parts': label_only,
        'screenshots': len(photos), 'console_screenshots':len(console_photos), 'hand_screenshots':2, 'source': source,
        'main_integration': {'floor':14,'map':'Trans_Introduction','artifacts':['threshold-workshop-'+k for k in ['again','almost','just','barely','still','descent']]},
        'pages': {slug: {'state': 'native_port_reviewed_with_documented_limits',
                         'floors': floors, 'mechanism_receipt': f'ada_run/matter-reference/{receipt}',
                         'editor_receipt': 'ada_run/matter-reference/editor-checks.json'}
                  for slug, _, floors, receipt in PAGES},
        'checks': {name: {'passed': r['passed'], 'assertions': len(r.get('checks', []))}
                   for name, r in receipts.items()},
        'known_limits': [
            'Jolt translation and per-body contact materials differ from Cannon; threshold numbers are not cross-engine guarantees.',
            'Almost uses a documented smooth native arc collider for its unedited original plank run; edited planks restore individual source box colliders.',
            'Tall knitting studies span the six-metre storey. Full multi-floor clearance and curation are not accepted.',
            'Native controls expose selected source presets, not every webpage editing widget or arbitrary source program.',
            'Collatz is source kinematic animation; its original 2D knitting page is translated into three editable panels.',
            'Desktop and synthetic XR primary-control interaction passed; no physical-headset, reach or complete walkthrough acceptance.',
            'Arbitrary physical rearrangements can change results; editor save parity does not assert every rearranged machine works.',
        ],
        'remaining_in_scope': [],
    }
    DOC.mkdir(parents=True, exist_ok=True)
    (DOC / 'STATUS.json').write_text(json.dumps(status, indent=2) + '\n', encoding='utf-8')
    table = '\n'.join(f'| {name} | {", ".join(map(str, floors))} | `{receipt}` |'
                      for _, name, floors, receipt in PAGES)
    details = f'''# Matter and Logic — native port review

All 15 downloaded source pages have native Godot studies in the separate
`{TRIAL}` trial: 36 study floors, {count} independently editable parts,
{len(urls)} referenced artifact GLBs and {label_only} label-only parts.
The earlier main-floor-12 pallet sketches are preserved. Standard floors remain
42 × 18 metres with six-metre storeys. This is a source-comparison collection,
not acceptance of final staging in the main spine.

The ZIP SHA-256 is `{source['sha256']}`. Every original archive file still matches
the local source copy byte for byte. Source canvas texture recipes and Three.js
mesh recipes were reconstructed as native assets; screenshots are from Godot.

| Source page | Trial floors | Focused receipt in ada_run/matter-reference |
| --- | --- | --- |
{table}

## Evidence and its limits

- Six full-size gates: all 22 input rows passed with outputs read from native
  bodies. Production pointer RELEASE/RESET and moved/rotated negative-floor
  AND/NAND checks passed separately.
- Marble boards: 18 gate rows plus eight counter increments passed. The tyre
  chain and stack/queue also passed moved/rotated baseline checks.
- Call/loop studies: source default programs reached the real exit with the
  expected outputs and no route errors. This is not arbitrary-program coverage.
- Material programs/pipelines: 19 checks include array indices 0–5, all loop counts
  1–5, IF/IFELSE input values and four physical cup pipelines. The source automatic
  pin timing is explicit auto_pull configuration in these baseline checks.
- All six threshold studies produced finite completed Jolt observations. These
  are physical observations, not assertions of identical Cannon thresholds.
- Gravity Knitter: all 16 pattern/output combinations passed without a computed
  fallback, using rules 0 and 255. Rule 90's direct output also matched its
  neighbourhood rule. A separate actual-floor receipt follows the marble through
  the registered floor rather than assuming an empty test world's clearance.
- Collatz: arbitrary-precision values beyond int64, the full 7 → 1 path with 16
  parity stitches, three separate knitting panels and all 17 base-six decoded
  states passed. Its source machine uses programmed paths, not Cannon gravity.
- The actual desktop player and synthetic XR trackers loaded all 36 study floors.
  This establishes startup/instantiation, not headset ergonomics or a walkthrough.
- Primary controls on all study floors also passed actual rendered desktop clicks
  and synthetic XR triggers. Separate hand checks cover real AND/OR pickup/drop,
  RELEASE/RESET while held, a 1000-frame hold without timing out, and physical
  results after releasing the mover by hand. The source program-flow checks now
  pause a moving machine, verify its physical poses/cursor stay put, resume it and
  check the original outputs. These are not physical-headset tests.
- All {count} parts passed the real editor model's move/rotate paths. Copies on
  every floor passed the shared save validator using validateOnly; saved layouts
  were not replaced by the test. All referenced GLBs were parsed and contain mesh
  geometry; explicit text-only parts use exported Label3D data.
- The final export completed without runtime errors or resource-leak diagnostics.
  The broader player-load harness reports an ObjectDB shutdown warning; no startup
  or per-floor load check failed. Physical-headset testing remains unperformed.

## Explicit native adaptations

Cannon pair-contact materials become Godot per-body materials. Native planar
guides use joints instead of per-step pose overwrites. The NAND beam needs 50/s
angular damping; marble XOR/NOT/HALF use 1/s sphere drag. The tyre-chain stack
boxes use zero friction while the loose plank retains its supports. The material
array pointer uses .5 friction. These are Jolt calibrations, not source constants.

Almost retains its 44 visible/editable planks but uses a welded 264-segment arc
collision surface for the unedited run, avoiding repeated impacts on overlapping
plank ends. Editing any pipe plank restores the source's individual box colliders.
Its h=1.046 take returns at a native margin around .90; the h=1.12 diagnostic also
returned (about .93), so the source's dial does not guarantee crossing in Jolt.
Just's source dashpot is translated into damping; its baseline tipped with six
grains for a source threshold of 5.6. No Boolean result forces target movement.

Computing pages' large helper floor/table is supplied by the Void slab so it does
not close shafts. Small source pedestals remain. Original tall knitters span
storeys; the images hide neighbouring exhibits and show only one floor slab for
inspection. They do not prove clearance. The Collatz well is aligned to shaft A,
with its native console moved onto standing ground.

Actual-player input testing exposed a separate Gravity Knitter placement defect:
its source marble starts 6.65 metres above the slab and landed on Floor32 instead
of entering the machine. The old entry and collider trace are preserved in
`gravity-knitter-before-shaft-placement.json` and `knitter-placement-before-shaft.json`.
The trial feed now passes through shaft A at root position [-8.25, 0], retaining
its original scale and height. Its controls and spawn are on solid slab beside
the shaft. The corrected trace reaches the actual trough and completes a stitch
without a jam. This fixes the feed; it does not assert complete visual clearance
for every tall frame or a curated multi-floor walkthrough.

The Collatz editor fabric is explicitly a completed-preview sample; gameplay
starts empty and adds a stitch per reading. Knitter screenshot fabrics use the
explicit source COMPUTE mode. Gravity Knitter pauses after three jams instead of
silently using the original source's fallback answer. Native controls provide
selected source presets; a complete replica of every HTML editor widget, all
source programs or the 2D knitting page's stream/schematic modes is not claimed.

## Hands-on controls

- Gates and tyre chain: right-click or XR grip carries loose parts. Beams and
  hinges remain attached. Arrange supports first, then drop the mover or press
  RELEASE. RESET releases the actual hand before restoring the authored homes.
  Holding pauses the observation timer; it does not overwrite the other bodies'
  physical motion. Hand rearrangements can change or break the canonical result.
- Marble boards: DROP feeds the chosen hopper; queued drops retain the source's
  .8–1.3 second spacing. CLEAR removes the delivered marbles and resets rockers.
- Stack/queue: TYPE selects the prefab; PUSH/POP and ENQUEUE/DEQUEUE operate the
  source containers. CLEAR starts a fresh comparison.
- Call/list/loop machines: PRESET, LESS and MORE show the active parameter. RUN
  becomes PAUSE/RESUME. The generated bodies and logical cursor pause together;
  resume restores stored velocities rather than moving a marble to a new station.
  PRESET rebuilds preserve the source rack's edited position and rotation.
- Material programs: X changes condition, index or lap count. Pipelines now wait
  for the player's PULL PINS command after RELEASE; they no longer remove the pins
  automatically before the player can reach that control. RESET replaces them.
- Threshold studies: the setting button prints its actual parameter/value and
  cycles three source settings. Almost also offers source-equation millimetre
  release changes and a measured high-water mark. Just waits for a requested
  grain and a settled needle; automatic source feeding is explicitly selected.
  Each study keeps three measured takes across RESET/REPEAT/preset changes.
  Readable time, angle, energy-height and cooling readings replace raw JSON.
  All six are placed on the north side and east bay of floor 14 / Trans Introduction;
  the existing crossings, logic and user arrangements are retained.
- Knitters: eight switches address patterns 111 through 000, allowing any rule
  from 0–255. RULE selects a preset; SEED cycles single/random/blank; EDGE switches
  blank/wrap boundaries. A random seed stays the same across reset/rule changes.
  The source rule display and output-ball colours follow the selected bits.
  RUN pauses/resumes a live marble, STEP produces one stitch, COMPUTE is an
  explicit mathematical finish, and CLEAR resets. Completed fabric can restart.
- Collatz: START selects a source start value; RUN pauses/resumes; STEP completes
  one reading; FINISH completes the source arithmetic; CLEAR clears the step
  latch. RUN/STEP can restart a finished take. The dead PAGE button was removed
  from the machine; PAGE/METHOD remain on the knitting panels, preserving panel
  identities and authored poses as they are rebuilt.

Local console labels now have contrast against their dark backing. Passive loose
parts explicitly let desktop clicks reach controls while carried; soundscape's
action-signal observation no longer turns them into trigger-consuming tools.

## Reproduce

`python tools/run_reference_probe.py <probe_name>` runs one focused native receipt
under the shared OS mutex. `python tools/export_void_trial.py {TRIAL}` exports the
built scenes. `node tools/check_matter_reference_editor.cjs` checks the actual
editor/save paths. `reference_player_load` covers actual desktop/synthetic XR
startup; `reference_collection_capture --capture --void-trial={TRIAL}` captures
the inspected views. The published gallery links each page to its editor floors
and the untouched browser original. No chapter texts were rewritten.
'''
    (DOC / 'REVIEW.md').write_text(details, encoding='utf-8')
    controls_status = read(DOC / 'CONTROLS-STATUS.json')
    controls_status.update(stage='Primary hands-on controls complete and reviewed for all 15 source examples; physical headset and full HTML editor parity remain outside this acceptance.', remaining=[], evidence={name:status['checks'][name] for name in RECEIPTS if 'control' in name}, editable_parts=count)
    controls_status.pop('active_native_job',None)
    controls_status.update(no_main_floor_changes=False,main_floor_changes=[14])
    (DOC / 'CONTROLS-STATUS.json').write_text(json.dumps(controls_status,indent=2)+'\n',encoding='utf-8')
    cards = []
    for slug, title, floors, _ in PAGES:
        shown = [n for n in floors if n in photos]
        first, *more = shown
        links = ' · '.join(f'<a href="/lab-editor?mode=void&trial={TRIAL}&floor={n}">Floor {n}</a>' for n in floors)
        extras = ''.join(f'<figure><img loading="lazy" src="floor-{n:02}.png" alt="Native Godot study on floor {n}"><figcaption>Floor {n}</figcaption></figure>' for n in more)
        console_view = next((n for n in floors if n in console_photos),None)
        console_card = f'<details><summary>Desktop control panel</summary><img loading="lazy" src="controls-{console_view:02}.png" alt="Actual desktop control panel for {html.escape(title)}"></details>' if console_view else ''
        cards.append(f'<article id="{slug}"><header><span>GODOT / {floors[0]:02}</span><h2>{html.escape(title)}</h2></header><a href="floor-{first:02}.png"><img loading="lazy" src="floor-{first:02}.png" alt="{html.escape(title)} in Godot"></a><p>{links}</p><p><a href="/studies/matter-and-logic/pages/{slug}.html">Original browser example ↗</a></p>'+console_card+ (f'<details><summary>{len(more)} more native views</summary>{extras}</details>' if more else '')+'</article>')
    page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Matter and Logic — 15 Godot studies</title><style>
    *{box-sizing:border-box}body{margin:0;background:#eee9df;color:#241f28;font:16px/1.5 system-ui,sans-serif}main{max-width:1260px;margin:auto;padding:40px 24px}h1{font-size:clamp(32px,5vw,62px);line-height:1.05;max-width:850px;margin:16px 0 24px}a{color:#7e2150;text-underline-offset:3px}p{max-width:950px}.intro{border-bottom:3px solid #e45391;padding-bottom:22px;margin-bottom:32px}.eyebrow,article span{font-size:12px;letter-spacing:.12em;font-weight:700}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,480px),1fr));gap:24px}article{background:#faf7f1;border:1px solid #c8beb0;align-self:start}article header,article p,details{padding:0 20px}article header{padding-top:18px}h2{font-size:24px;margin:4px 0 18px}img{display:block;width:100%;height:auto}article p{font-size:14px}figure{margin:16px 0}figcaption{font-size:13px}summary{cursor:pointer;padding-bottom:16px}.notice{background:#e8dce2;border-left:4px solid #bd3a77;padding:16px 20px}
    </style><main><section class="intro"><div class="eyebrow">MATTER / LOGIC / SOURCE COMPARISON</div><h1>15 browser examples.<br>36 editable Godot studies.</h1><p>Original mechanisms, source mesh recipes, wooden supports and real native geometry. Start with the gates, then follow the chains, programs, thresholds and knitting machines.</p><p><a href="/lab-editor?mode=void&trial=matter_logic_reference&floor=1">Open the editable collection ↗</a> · <a href="/studies/matter-and-logic/index.html">All downloaded originals ↗</a></p><p class="notice">Inspection views show one floor at a time; neighbouring exhibits are hidden. Tall knitters span storeys and still need staging. Collatz follows its original programmed paths; knitting previews use explicit FINISH/COMPUTE mode. Jolt thresholds differ from Cannon. Desktop and synthetic XR startup passed; physical-headset testing remains.</p></section><section class="grid">'''+''.join(cards)+'''</section><p>998 independent parts · 974 artifact GLBs + 24 text-only parts · Existing floor-12 pallet sketches preserved.</p></main></html>'''
    control_intro = '<section id="controls" class="intro"><h2>Hands on, in the game</h2><p>Carry the loose gate pieces and release the ball by hand. Pause and resume the program machines, pull the pipeline pins, and edit all eight knitter rule bits, seeds and edges. Primary controls passed real desktop clicks and synthetic XR triggers.</p><div class="grid"><figure><img src="hand-gate-desktop.png" alt="A gate ball carried by the actual desktop player"><figcaption>Actual desktop pickup. Right-click to release.</figcaption></figure><figure><img src="controls-34.png" alt="Rule Knitter control panel with eight pattern switches"><figcaption>Rule Knitter: each switch sets one neighbourhood output.</figcaption></figure></div></section>'
    threshold_intro = '<section id="thresholds" class="intro"><h2>Almost, Just and the physical margin</h2><p>The six threshold studies are now in the main tutorial on <a href="/lab-editor?mode=void&floor=14">floor 14 / Trans Introduction</a>, below the crossings. Adjust Almost by one millimetre, add each grain to Just, and repeat to compare the actual observations. <a href="/book-review/doc/book/iterations/2026-10-25-almost-and-just/index.html">Open the new floor review and screenshots ↗</a></p></section>'
    page = page.replace('<section class="grid">',threshold_intro+control_intro+'<section class="grid">',1).replace('998 independent parts',f'{count} independent parts').replace('974 artifact GLBs + 24 text-only parts',f'{len(urls)} artifact GLBs + {label_only} text-only parts').replace('Desktop and synthetic XR startup passed;', 'Desktop and synthetic XR controls passed;')
    (GALLERY / 'index.html').write_text(page, encoding='utf-8')
    print(json.dumps({'pages': len(PAGES), 'study_floors': 36, 'parts': count,
                      'artifact_models': len(urls), 'photos': len(photos)}))

if __name__ == '__main__':
    main()
