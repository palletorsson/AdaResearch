from pathlib import Path
import json
H=Path(__file__).resolve().parent;R=H.parents[3];P=H.parent/'2026-09-19-review-comparison';prefix=H.relative_to(R).as_posix();M='QFEP_Phi_Term'
def para(start,old=False):
 p=(H/'before' if old else R)/'commons/maps'/M/'final.md'
 return next(t for t in p.read_text(encoding='utf-8').split('\n\n') if t.startswith(start))
d=json.loads((H/'before/doc/book/iterations/2026-09-19-review-comparison/qfeplaboratory.json').read_text(encoding='utf-8'))
d['status']='Introduction, F, E, Lambda and Phi reviewed; Edge of Chaos next'
d['summary']='QFEP asks who may revise the terms. Introduction keeps different arrangements with a similar total; F changes a prediction while its bits stay fixed; E closes and reopens branches; Lambda moves a recommendation independently of its surroundings. Phi now lets a visitor compare signed movement before revealing the earlier resist/embrace interpretation. Five laboratory halls have received this pass; Sandbox still needs restoration.'
d['items'] += [
 dict(title='Phi: the gesture before its label',description='A signed PHI rail on a plinth starts at zero. Equal magnitudes now produce equal particle speeds in opposite directions, and zero stops new emission. Negative, zero and positive arrive before an interpretation. Its existing XR handle stays full size; other placements retain legacy behaviour.',images=[prefix+'/phi-negative.png',prefix+'/phi-positive.png'],captions=['PHI −0.70: downward feedback.','PHI +0.70: upward feedback at the same speed.'],image_note='Actual Godot museum, identical camera and held wave-pattern time. Particle direction and speed are established by runtime state checks; still images alone do not establish movement. The pattern’s normal independent motion is checked separately.',text_kind='book — preserve the operation; notice what keeps going',before=para('Move PHI',True),after=para('Move PHI'),report=prefix+'/final.diff',report_label='Exact Phi manuscript diff'),
 dict(title='A word arrives after the movement',description='EARLIER LABELS / HIDE changes only the inscription. The old RESIST / EMBRACE reading becomes a proposition to examine after trying the rail. The chapter asks whether the visitor can simply return to the earlier reading after seeing those words.',images=[prefix+'/phi-positive.png',prefix+'/phi-earlier-labels.png'],captions=['Positive movement, before the earlier interpretation is revealed.','Same positive weight, now called EMBRACE by the earlier project reading.'],image_note='The button changes neither PHI nor the neighbouring pattern. Numerical marks remain visible. Colours and vertical directions still carry associations; the text does not call this a neutral interface.',text_kind='book — added encounter',before='[No delayed-label encounter in the earlier chapter.]',after=para('After trying both sides'),report=prefix+'/SUMMARY.md',report_label='Decisions and verification limits'),
 dict(title='At zero, another pattern keeps moving',description='The enlarged wave pattern remains a primary comparison alongside PHI. All eight map placements remain; six works instantiate, while two legacy teleporter tokens are suppressed by continuous-museum rules. Four display bases support the forms; the exit route is kept clear of automatically added sculptures.',images=[prefix+'/phi-pattern.png',prefix+'/phi-gallery.png'],captions=['A closer view of the independently changing pattern.','Six retained works, reachable rail and level circulation.'],image_note='36 interaction/state checks and six selected walking routes pass; rendered Godot exits 0. 73 content and preservation checks pass. Five actual museum images reviewed. Tracked-hand operation, continuous gameplay and learner understanding remain unverified.',text_kind='book — preserve the independent comparison',before=para('This pattern currently',True),after=para('This pattern currently'),report=prefix+'/QFEP_Phi_Term-runtime.json',report_label='Runtime report: controls, independence and walks')]
(P/'qfeplaboratory.json').write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
summary='''# QFEP Phi Term — giving change a sign

Completed 20 September 2026. Scope: the signed-parameter encounter and its relation to the existing manuscript. No live museum restart, live bake replacement or commit.

## Decision

The external review identified an actual reveal-timing conflict: the chapter asks whether direction need already mean improvement, but the rail had answered RESIST / EMBRACE. Its other primary artifact already provides a useful independent comparison. Preserve that independence and most of the chapter; change how the earlier interpretation becomes available.

## Encounter

The existing phi_slider gets an optional sign_study:on mode for this hall. A full-size rail on a plinth starts at zero with NEGATIVE / ZERO / POSITIVE marks. Equal magnitudes produce equal speeds in opposite vertical directions without particle gravity. Zero stops new emission; old particles expire over their lifetime. The emitter is raised so the downward trail stays visible above the plinth for its full lifetime, even at maximum magnitude. An EARLIER LABELS / HIDE button reveals the earlier project reading without changing either PHI or the independent pattern.

The study stays outside global PHI aggregation. Other placements retain their original labels, registration and particle behaviour. Late configuration and repeated configuration are covered by runtime checks.

All eight map tokens remain placed: six distinct works plus two secondary teleporter tokens. The museum suppresses those teleporters because its halls occupy one continuous map. Both primary roles and all secondary roles are retained. The 6 by 6 transforming pattern is enlarged for viewing, four works have display bases, and the visitor can circulate around the console. Authored placements override the older necklace stamp. The sculpture exclusion extends through the exit row; its first version left the final cell boundary available for an automatic statue, which the failed walking probe caught.

## Writing

The chapter's question, signed-weight explanation, sign/magnitude comparison, distinction from entropy measurement, two-cell observation, trajectory paragraph and exit remain. Add the delayed label encounter, zero-emission observation and question of who chooses what counts as change and how its score is used. The technical note distinguishes Delta E from a rate and states the sign consequences under minimization. This encounter does not calculate entropy or classify an identity.

Earlier technical and critical drafts are preserved in design-proposals.md. They imagined vertex restoration, contagion and global coupling that the implementation does not supply. They remain possible development material, not runtime evidence. Book speech, sequence description, registry note and core encounter references now agree with this hall.

## Evidence and limits

- Final rendered probe: **36 interaction/state checks, six selected CharacterBody walking routes, exit 0**.
- **73 content/preservation checks**: other laboratory map manuscripts and geometry, roles, plan rows, registry entries and speech remain unchanged; scoped hashes and references match.
- Five actual Godot images inspected, including equal opposite weights and the same positive setting before/after the label reveal. The main wave pattern is held at one instant for comparison; its independent motion is tested separately.
- The first probes found an exit obstruction and floating display objects; both corrected before the final passing run. A selected hand-reach coordinate was refined; actual tracked-hand comfort remains a headset check.
- The engine still prints existing UID, root-certificate and renderer cache-write warnings. No script or shader compilation errors in the final run. Existing six-map dimension disagreements elsewhere remain in the derived-data refresh log.
- No headset session, learner evaluation, continuous gameplay or philosophical conclusion is implied by these checks.

See final.diff, content-checks.json, current-inputs.json, QFEP_Phi_Term-runtime.json and process-result.json beside this file.

## Next bounded pass

QFEP_Edge_Of_Chaos. Read the chapter's controlled-comparison proposal and inspect its reaction-diffusion timestep before calling an observed pattern a stable regime. Keep the QFEP definition from the project documents in view: making a model revisable includes questioning its measures and the people who set them. Sandbox restoration follows later.
'''
(H/'SUMMARY.md').write_text(summary,encoding='utf-8')
w=R/'doc/book/iterations/WORKING.md';s=w.read_text(encoding='utf-8');a=s.index('**Completed:**');b=s.index('Earlier [QFEP E Term]',a)
s=s[:a]+'''**Completed:** [QFEP Phi Term](2026-09-20-qfep-phi-review/SUMMARY.md). Signed PHI feedback now comes before the optional earlier RESIST / EMBRACE interpretation. A reachable plinth supports the original rail; equal magnitudes have equal speeds in opposite directions, zero stops new emission, and the neighbouring pattern remains independent. Most of the manuscript is preserved, with the delayed-label encounter added. All eight tokens remain (six instantiated works and two suppressed legacy teleporters). Display heights and the exit obstruction were corrected. 36 interaction/state checks, six walks and 73 content checks pass; rendered Godot exits 0. Five actual museum images and exact text diffs published. Headset and learner checks remain pending. No live restart, bake replacement or commit.

Earlier [QFEP Lambda Spectrum](2026-09-20-qfep-lambda-review/SUMMARY.md) remains intact: its movable recommendation, unchanged spectrum, all ten placements and published evidence are preserved. The prior rendered shutdown crash remains a separate harness follow-up; this Phi run exits cleanly.

'''+s[b:]
a=s.index('**Next bounded pass:');b=s.index('\n\n**Curatorial correction',a)
s=s[:a]+'''**Next bounded pass: QFEP_Edge_Of_Chaos.** Inspect the reaction-diffusion timestep and the chapter's controlled comparisons; distinguish a solver artifact from a stable pattern regime. Carry forward the QFEP question of who specifies and weights change. Seven of eight declared laboratory halls remain authored; QFEP_Sandbox still needs restoration. Separate follow-ups: Lambda's prior rendered-process shutdown crash and registry-disabled bifurcation walkway; E Term's secondary microstate_counter formatting error; F Term's headset puzzle checks and stale plate_scale export; Introduction's large wave screen and synthesis-stand viewport errors. Phi's tracked-hand comfort and learner interpretation remain unverified. Do not reopen mature earlier chapters without new evidence.'''+s[b:]
w.write_text(s,encoding='utf-8');print('Phi comparison and handoff published')
