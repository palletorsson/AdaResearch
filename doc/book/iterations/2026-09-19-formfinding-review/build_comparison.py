from pathlib import Path
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PAGE = HERE.parent / '2026-09-19-review-comparison'
REL = HERE.relative_to(ROOT).as_posix()
def path(p): return REL + '/' + p
def para(name, prefix, before=False):
    base = HERE / 'before' if before else ROOT
    text = (base / f'commons/maps/{name}/final.md').read_text(encoding='utf-8')
    matches=[p for p in text.split('\n\n') if p.startswith(prefix)]
    assert len(matches)==1, (name,prefix)
    return matches[0]

items = [dict(title='The six halls stay; their methods become distinct',
    description='All 28 authored placements remain. The washing-line cathedral and end table return through catalog repair. Laundry, the glass vessel and the basin comparison become primary. Descent stays unchanged; the four middle chapters distinguish their actual methods; Forge gains one stop-condition correction.',
    report=path('SUMMARY.md')),
    dict(title='Descent: keep the chapter, recover the evidence',
    description='The quoted valley costs were already recorded in a 36-check museum run. All ten source fingerprints still match. The smaller diagram below is a separate repair: its geometry stays, while its labels now acknowledge fixed seeded offsets. It asks about a remainder without inventing a running solver.',
    images=[path('diagram/before.png'),path('diagram/after.png')],
    captions=['Saved original labels · a solver and ongoing trembling were claimed.', 'Current labels · fixed differences and the question of what counts as settled.'],
    image_note='Same camera, isolated actual Godot artifact, saved original versus current source. These images do not show a new whole-museum or headset test.',report=path('diagram/check.json')),
    dict(title='Catenary: the washing and the cathedral share a curve',
    description='The existing cathedral is admitted by the catalog again. Its outside lines gain their missing supports; a separate plaque identifies the analytic construction. The two parametric surfaces now appear in the pickup collision query. The chapter moves from a cable in the hand to a formula, then asks what a physical version would have to establish.',
    images=[path('structure/capture-before-accepted-FormFinding_Catenary/laundry-standing.png'),path('structure/capture-after-verified-FormFinding_Catenary/laundry-standing.png')],
    captions=['Saved-source replay · the outer endpoints float.', 'Current source · crossbars support the three lines.'],
    image_note='Actual museum assembly, matched camera and frozen shared loader. The restored catalog is held constant in this pair; it compares support repairs, not the earlier absence of the entire exhibit. The plaque faces the entrance on its own stand.',
    before=para('FormFinding_Catenary','Four cyan beads',True),after=para('FormFinding_Catenary','Four cyan beads'),
    map='FormFinding_Catenary',text_kind='final.md · Catenary',report=path('structure/AUDIT.md')),
    dict(title='Relaxation: let the visitor change the correction budget',
    description='PASSES, RESET and WIND replace the decorative dial in this hall. The panel reports average and worst relative spring error. Configuration-before-ready now builds one cloth and one readout. The frozen lattice stays where it already worked; the vessel becomes primary.',
    images=[path('relaxation/paired-before/workbench.png'),path('relaxation/final-visible-after/workbench.png')],
    captions=['Saved original · the dial has no input.', 'Current · repeat a condition, change passes, switch the drive.'],
    image_note='Same-camera actual museum comparison, with the original script replayed for the baseline. Final controls and cloth visibility were inspected; headset reach and Quest performance remain untested.',
    before=para('FormFinding_Relaxation','On the panel below it',True),after=para('FormFinding_Relaxation','The panel now offers'),
    map='FormFinding_Relaxation',text_kind='final.md · Relaxation',report=path('relaxation/AUDIT.md')),
    dict(title='A small mean can conceal a larger local error',
    description='The original worst-spring reversal did not reproduce. Under the same undriven conditions, four passes improved both measures. The revised question follows the observed discrepancy instead of preserving a false measurement.',
    before=para('FormFinding_Relaxation','Two things about the number',True),after=para('FormFinding_Relaxation','In a matched desktop calculation'),
    map='FormFinding_Relaxation',text_kind='final.md · Relaxation',report=path('relaxation/measures/measurement.json')),
    dict(title='Equilibrium: inspect the model that holds the image still',
    description='The mobile retains its recursive lever arithmetic. Its label now names the modelled disc masses and massless rods and wires. Triangle scaling and recursive bracing remain visible, with their physical tests identified as further work.',
    images=[path('structure/capture-before-verified-FormFinding_Equilibrium/calder-plaque.png'),path('structure/capture-after-verified-FormFinding_Equilibrium/calder-plaque.png')],
    captions=['Saved original · balance was presented without the model limits.', 'Current · the mass model is available to inspect.'],
    image_note='Actual museum assembly with the same camera, authored geometry and shared source snapshot. No dynamic balancing or load experiment is claimed.',
    before=para('FormFinding_Equilibrium','It is genuinely balanced',True),after=para('FormFinding_Equilibrium','For each disc'),
    map='FormFinding_Equilibrium',text_kind='final.md · Equilibrium',report=path('structure/AUDIT.md')),
    dict(title='Annealing: compare before interpreting',
    description='The source distinguishes random proposals, uphill acceptance, adaptive cooling and a separate forced hop. The basin comparison starts with DEEP and SHALLOW; INTERPRET brings in the Q proposition. Its bodies have different drives, so their difference is an authored argument rather than a measured law of life.',
    images=[path('search/standing/Annealing/q-standing.png'),path('search/standing/Annealing/q-interpretation.png')],
    captions=['Current encounter · compare the two responses.', 'Same view · interpretation requested through the control.'],
    image_note='Two states of the updated actual museum, not before/after software versions. Camera world height 1.7 m; the museum route repair installs this tank at half its authored size. The narrow well is best inspected from its outside edge. Headset reach remains untested.',
    before=para('FormFinding_Annealing','The claim on the floor',True),after=para('FormFinding_Annealing','Press INTERPRET'),
    map='FormFinding_Annealing',text_kind='final.md · Annealing',report=path('search/AUDIT.md')),
    dict(title='Forge: let the second history happen',
    description='The default optimiser stalled at the frame edge instead of beginning another history. It now distinguishes BOUNDARY from SMALL SLOPE and restarts. The puzzle still allows a low, useful arrangement to remain a refusal of its success criterion.',
    before=para('FormFinding_Forge','Here a numerical rule',True),after=para('FormFinding_Forge','Here a numerical rule'),
    map='FormFinding_Forge',text_kind='final.md · Forge',report=path('search/AUDIT.md')),
    dict(title='What remains to be tested',
    description='The evidence covers the recorded controls, source behavior and selected museum views. A full headset visit and learner reading remain open. An isolated Annealing/Q probe completes its behavior checks but crashes during native teardown; that failure remains visible in the report. Next: Wave Functions.',report=path('SUMMARY.md'))]

review=dict(status='six-hall local pass',summary='A form can be drawn, calculated, relaxed, balanced in a model, or accepted by a detector. Keep the differences available to the visitor. Restore the work that makes those differences visible.',items=items)
(PAGE/'formfinding.json').write_text(json.dumps(review,indent=2,ensure_ascii=False),encoding='utf-8')
print('Prepared Form Finding comparison entries')
