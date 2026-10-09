from pathlib import Path
import json
r=Path.cwd();o=r/'doc/book/iterations/2026-09-25-wavefunctions-review-comments'
text={
1:'Kept the finite graph and made continued circle/projection motion an explicit map option. Other placements retain the old held default. Native museum inspection also exposed the lower semicircle below the floor; raised this placement by 1.7 m and moved it from (1,1) to the empty cell (1,2), clear of the entrance wall. All 400 local step transforms stay unchanged through ongoing motion. The chapter and preceding handoff now distinguish the retained graph from its continuing source.',
2:'Moved mark counting after COARSE, when roughly fifteen marks rather than about 118 occupy a full swing. Retained the FINE timing mismatch and the trade between detail and recorded duration.',
3:'Named the captions visible before pressing: SINE becomes PULSE, COUPLED becomes INDEPENDENT, and pressing INDEPENDENT restores COUPLED. Verified real button signals and the same pulse with and without coupling in the museum.',
4:'Replaced the maker-facing walking-check note with a concrete distinction: following the spiral from the floor does not establish that a body can complete it. Full ascent and headset comfort remain unverified, recorded here rather than as a production instruction in the chapter.',
5:'Restored the separate wall voice attempting “right here, right now”. Distinguished it from the column hum whose level follows rotation speed. The loop pauses three seconds after a phrase; the review’s claim of a phrase every three seconds was too exact. No recorded listening test claimed.',
6:'Kept the substantial Lucier encounter, gave the bench and return their own headings, and stated that ENTER ROOM leaves the hall. The longer return compares feedback with calculating a sum afresh. HOLD/BASELINE/fifth-slider signals reproduce restoration at a held phase; BASELINE does not rewind time. Travel wiring was inspected, not an end-to-end scene-return or microphone acceptance test.',
7:'Removed the premature AirMusic handoff. Effect Sound now leads directly into Bernini, as the sequence does.',
8:'Replaced compass-only orientation with visible cues: sampler panel and drum, tray and corridor mouth, case beside tray, dark board above the synthesis bench. No new compass convention introduced.',
9:'Specified that the final fade lasts one tenth of a second, rather than leaving “final tenth” open to a fraction-of-duration reading.',
10:'Returned the existing paired red/blue steps to the chapter as a brief supporting encounter: quarter-turn separation becomes a question about support. Kept the beat display primary. The step source has colliders and the placed scene enables escalator motion; no full route or headset traversal claimed.',
11:'Located the two-ball sound rig past the racks near the far end of the hall before giving the first listening instruction.',
12:'Explained RELIEF as a cycle through three height ranges. From the middle setting it steepens, then becomes shallower than on arrival; it does not increase indefinitely. Positions across the tray remain fixed.',
13:'Clarified the Lucier footnote: the stutter belongs to the voice received by the room, rather than being a defect the process is presumed to correct. Both references retained.'}
D={f'book_wavefunctions.{i:03d}':{'decision':t,'status':'done','triage':'fix'} for i,t in text.items()};(o/'decisions.json').write_text(json.dumps(D,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('13 decisions prepared.')
