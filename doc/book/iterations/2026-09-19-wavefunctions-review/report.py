"""Record decisions and extend the existing image/text comparison."""
from pathlib import Path
import json
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
REL=HERE.relative_to(ROOT).as_posix()
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def save(p,text):p.write_text(text,encoding='utf-8')
v=read(HERE/'verification.json');changes=read(HERE/'text-changes.json')
summary='''# Wave Functions — local review, 19 September 2026

The twelve-hall sequence is now present in both the museum plan and the manuscript route. Six existing halls were absent from the old six-hall museum configuration. They were restored using their authored maps, with the existing museum template. No chapter was cut to accommodate that older route.

The guiding question is **what a return keeps, and what it carries elsewhere**: state → sampled history → sine-shaped space → coordinate projection → coupling → phase modulation → architectural form → chance scheduling → struck voices → sampled steps → beats → finite sums. Sine Space deliberately remains before Unit Circle: the body encounters the shape before the graph explains one construction of it.

## What changed

- All **132 authored placements** and their primary/secondary roles remain. No existing artifact was removed or moved. Two existing tokens opt into new comparison/reveal behavior.
- **Eight final.md chapters are byte-for-byte preserved.** Sine Space, Effect Sound and AirMusic receive small route handoffs; Propagation gains a repeatable experiment. Effect Sound also names the implemented phase modulation. Exact originals, proposals and diffs are retained.
- **Unit Circle:** its projection-rod helper mixed local and world coordinates. A placed, rotated or scaled parent could detach the rods by metres. Local orientation now keeps them attached. The saved original fails 51 of 102 regression assertions; the repaired version passes all 102.
- **Propagation:** COUPLED/INDEPENDENT, SINE/PULSE and RESET compare the same initial state and drive. Existing force parameters remain. Default sine motion reaches an immediate neighbour only subtly; the already implemented pulse makes the relation easier to observe. The new console was moved to a measured clear approach after its first location collided with the retained secondary tile field.
- **Effect Sound:** a legible “Phase modulation / FM-style synth” title agrees with its expression. The audio generator is unchanged.
- **Synthesis:** the recipe name waits until H1 ALONE or BASELINE. Coefficients, formula, components and all existing controls remain visible. The bench caption now describes its finite five-harmonic family. This lets the existing prose work without rewriting it.
- Older descriptions/objectives now follow the more careful manuscripts. Bernini does not secretly need a shader; AirMusic does not solve a vibrating bar; Cage’s prepared vocabulary can repeat. Earlier Sky/Trig design texts are retained under explicit archive notices.
- The missing review dependency, ResonatingBar.gd, exists locally. A separately hashed source supplement records it; the original review ZIP is untouched.

## Verification

The source/collection verification records 56 passing checks, including unchanged unrelated plan rows, roles, eight manuscripts and all placement identities. A fresh native Godot route probe passes 52 checks with exit 0: twelve plan entries, authored ownership, cursor progression and refusal of old teleporters. This probes navigation methods without constructing or walking the entire museum.

Focused runtime evidence: Unit Circle 102 checks; Propagation controls 17; the final Propagation museum capture 14; Sound captures 4 before and 4 after; closing-hall focused checks 37; Synthesis museum captures 19 before and 19 after. Accepted runs exit 0. Captures use real Godot scenes, XR off and Dummy audio, with explicit camera assertions and source fingerprints. The before Propagation image replays its frozen original source in the restored room. These are not generated illustrations or headset evidence.

The failed initial Unit Circle log setup, failed membrane-name probe, rear-wall camera and blocked first console approach remain diagnostic records. They are not counted as accepted passes. Existing renderer, UID and environment warnings are recorded in the agent audits. Earlier desktop evidence is separately labelled historical; only matching source fingerprints are carried forward as such.

The long-museum and museum-necklace indexes were regenerated and their checks pass. They reuse existing engine measurements and placement ledgers; regeneration is not a new walk. Their existing layer-size warnings remain visible for Unit Circle, Sky Stairs, TrigWalkingPath and Noise Inside Noise. No layer was silently cropped or padded to silence them.

## Limits and next pass

No headset, human listening assessment, complete staircase ascent, full secondary walkway traversal, learner validation or general performance acceptance was performed. The propagation lattice and analytic tile field still overlap visually; separating or deliberately contrasting them is a later staging task. Synthesis upper labels remain low contrast and high-amplitude presentation deserves its own pass. The newly restored six halls need an entrance-to-exit physical walk.

Concurrent changes to the unrelated biome_inheritance registry are preserved and recorded, not attributed to this pass. The shared museum loader was not edited here. No commit, reset or push was made.

Next: **Randomness**, starting with its declared order, actual route, mature manuscripts and retained artifact ecology. Bring forward the distinction Cage has opened between uncertainty in event order and the vocabulary already chosen for it.

## Evidence

- [Opening audit](opening/AUDIT.md): pendulum, sampling, sine space, Unit Circle and historical provenance.
- [Middle audit](middle/AUDIT.md): propagation, sound, Bernini, Cage; numerical and paired image evidence.
- [Ending audit](ending/AUDIT.md): AirMusic, stairs, beats, synthesis; preserved design documents and current tests.
- [Exact manuscript changes](text-changes.json), [source/collection checks](verification.json), [route checks](navigation.json).
- [Before/after reading page](../2026-09-19-review-comparison/index.html).
'''
save(HERE/'SUMMARY.md',summary)
save(HERE/'WORKING.md','''# Wave Functions pass — complete

Completed 19 September 2026. See SUMMARY.md and verification.json. Twelve-hall order restored in live/shipped plans and map_authored; derived long-museum and necklace indexes refreshed. All 132 placements and roles retained; eight chapters unchanged, four with exact bounded revisions. Unit Circle local-frame fix, opt-in propagation comparison and synthesis naming delay, phase-modulation title. Three agents complete; owned Godot processes exited. No commit or shared loader edit.

Next sequence is Randomness. Preserve mature prose and existing artifacts, verify review claims against live sources/route, strengthen missing encounters before cuts. Do not rerun completed broad tests without a new concern. Future runtime work: physical walk through restored halls, geometry-layer mismatches, lattice/tile staging, Synthesis contrast/overflow, full stairs, headset/listening.
''')
feedback=ROOT/'doc/book/review-feedback/2026-09-18/wavefunctions'
save(feedback/'DECISIONS.md','''# Wave Functions — decisions, 19 September 2026

The source-aware review was useful. Its strongest finding was confirmed: twelve declared chapters had only six map-authored museum entries. We restored the six existing halls rather than cutting their distinct arguments. The deliberate Sine Space → Unit Circle reveal remains.

| Review issue | Local decision |
|---|---|
| Twelve book halls, six museum halls | Restored Unit Circle, Propagation, Bernini, Cage, Sky Stairs and TrigWalkingPath; verified actual route methods. A physical walk is still due. |
| Three stale chapter exits | Small Sine Space, Effect Sound and AirMusic handoffs now follow the restored route. |
| Coupling explained but not testable | Added opt-in coupled/independent, sine/pulse and reproducible reset controls to the existing lattice, then updated the encounter paragraph. |
| Universal oscillation claims and stale teaching metadata | Corrected specific objectives and source identities. Preserved all 132 placements, roles, and eight final chapters. |
| Sound says FM, formula is phase modulation | Corrected the visible title and one manuscript sentence; preserved DSP. |
| Synthesis name arrives too soon | Tested a neutral arrival recipe label until existing comparison actions; kept orientation and controls visible. No chapter rewrite. |
| Missing bar implementation in ZIP | Found it locally and supplied a separate hashed source supplement. No missing behavior was inferred from a missing bundle file. |
| Stair/path documents disagree with book | Kept the careful current book; preserved speculative older designs beneath archive notices and led with current source descriptions. |
| Runtime uncertainty | Fresh bounded evidence and historical evidence are separated. No headset, learner, full traversal or listening claim. |

An additional local repair emerged beyond the review: Unit Circle’s coordinate rods broke when their parent was placed in the museum. A saved-source replay failed 51/102 geometry assertions; the repaired source passes 102/102. This demonstrates why prose should not be weakened before inspecting the actual encounter.

[Full findings and limits](../../../iterations/2026-09-19-wavefunctions-review/SUMMARY.md) · [Text and paired images](../../../iterations/2026-09-19-review-comparison/index.html)

Original 01-review.md, GLANCE.md and package hashes remain unchanged. These are first-pass revision decisions, not a final editorial verdict.
''')
p=feedback/'README.md';text=p.read_text(encoding='utf-8')
text=text.replace('A [preliminary glance](GLANCE.md) is recorded; detailed source verification and decisions remain pending.','The [preliminary glance](GLANCE.md) is retained. A local twelve-hall pass is complete: [decisions](DECISIONS.md), restored route, three encounter repairs, four bounded manuscript revisions and paired runtime evidence. Headset and full traversal remain open.')
save(p,text)
p=feedback.parent/'README.md';text=p.read_text(encoding='utf-8')
text=text.replace('| [wavefunctions](wavefunctions/README.md) | 12 | 1 review received; preliminary glance only |','| [wavefunctions](wavefunctions/README.md) | 12 | Local pass: twelve-hall route restored,132 placements retained, eight chapters preserved; Unit Circle, coupling comparison and Synthesis reveal repaired. [Decisions](wavefunctions/DECISIONS.md) |')
save(p,text)

items=[]
def add(title,description,**kwargs):items.append(dict(title=title,description=description,**kwargs))
add('Six missing halls return to the walk','The declared twelve-hall order was already doing useful work. We restored its six omitted museum entries and retained the encounter-before-explanation move from Sine Space to Unit Circle.',
    before='Intro → Pendulum → Sine Space → Effect Sound → AirMusic → Synthesis Lab',
    after='Intro → Pendulum → Sine Space → Unit Circle → Propagation → Effect Sound → Bernini → John Cage → AirMusic → Sky Stairs → Beats / TrigWalkingPath → Synthesis Lab',text_kind='museum route',report=REL+'/SUMMARY.md')
add('The rods must stay with the circle','A local/world-coordinate error let Unit Circle’s projection rods drift by metres when their parent moved. The saved original fails 51 of 102 transformed-parent checks; the repair passes all 102. The chapter and all six placements remain.',report=REL+'/opening/AUDIT.md')
add('Give the lattice a question it can answer','The new panel repeats the same initial state and forcing with coupling present or absent. Original parameters and the retained analytic tile field remain. A body-sized collision check moved the new console to a clear edge.',
 images=[REL+'/middle/propagation-replay-before/lattice.png',REL+'/middle/propagation-final-after/lattice.png'],
 captions=['Before · frozen original artifact replayed in its restored museum hall.','After · comparison controls at the same placement; SINE state at 2.50 s.'],
 image_note='Actual Godot museum, matched camera. Only the new opt-in panel is added. Surrounding procedural dressing is not pixel-locked. The two wave representations still overlap visually; broader staging remains open.',report=REL+'/middle/AUDIT.md')
add('Same pulse, different relation','At 1.40 simulated seconds, the coupled lattice has passed movement to its neighbours. In the independent version they stay still while the centre rises higher. The switch restarts the same pulse rather than severing a wave midway.',
 images=[REL+'/middle/propagation-final-after/pulse-coupled.png',REL+'/middle/propagation-final-after/pulse-independent.png'],
 captions=['Experiment A · COUPLED / PULSE; neighbouring displacement is visible.','Experiment B · INDEPENDENT / PULSE; isolated centre near the top of the frame.'],
 image_note='Two states of the updated artifact, not before/after software versions. Same elapsed simulation time and camera; three clear approach capsules do not certify a headset visit.')
for c in changes:
 name=Path(c['path']).parent.name
 add(name.replace('_',' ')+' — revised passage',c.get('reason','Align the writing with the retained encounter and its available comparison.'),before=c['old'],after=c['new'],text_kind='book prose',report=REL+f'/diffs/{name}.diff')
add('Name the synthesis method clearly','The two-ball instrument exposes phase modulation. Its more legible title now says so while retaining the familiar FM-style context. The signal generator is unchanged.',
 images=[REL+'/middle/sound-before/instrument.png',REL+'/middle/sound-after/instrument.png'],
 captions=['Before · original title from the operating view.','After · Phase modulation / FM-style synth.'],
 image_note='Matched actual Godot museum views. No new human listening test or DSP alteration is claimed.',report=REL+'/middle/AUDIT.md')
add('Let comparison arrive before the recipe name','Synthesis now shows ARRIVAL RECIPE until H1 ALONE or BASELINE. Sliders, coefficients, sum and formula remain visible. Its existing chapter already asks for those comparisons, so the text stays intact.',
 images=[REL+'/ending/before/museum/arrival.png',REL+'/ending/after/museum/arrival.png'],
 captions=['Before · the approximate sawtooth name appears on arrival.','After · the name waits; finite-family caption replaces a universal claim.'],
 image_note='Actual museum, same bench scale, camera world Y 1.7 m and held waveform phase. Nineteen checks pass per run; upper labels remain low contrast, and headset reach is still untested.',report=REL+'/ending/AUDIT.md')
add('Preserve what is already working','Eight final chapters stay byte-for-byte unchanged; all 132 authored placements and roles remain. Bernini, Cage, the struck voices, the stairs and the beat display already sustain distinct questions. Supporting descriptions now catch up with that precision. The omitted bar source is supplied separately without changing the original review package.',report=REL+'/SUMMARY.md')
add('What remains to experience','The twelve-hall route contract passes 52 native checks. A full physical walk through the restored halls, complete stair ascent, human listening and headset comfort are still open. Derived indexes retain known layer-size warnings; they are not spatial certification. Randomness is next.',report=REL+'/verification.json')
data=dict(status='twelve halls restored; focused repairs; eight chapters retained',summary='Returning to a position is not returning to the same state. This pass keeps the sequence’s different kinds of return, restores missing halls, and lets two existing instruments support stronger comparisons.',items=items)
save(ROOT/'doc/book/iterations/2026-09-19-review-comparison/wavefunctions.json',json.dumps(data,ensure_ascii=False,indent=2)+'\n')
print('Summary, decisions, continuation state and comparison data written.')
