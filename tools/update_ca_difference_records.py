"""Record the final CA lesson without changing any other lesson decision."""
from pathlib import Path
import copy,json
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-what-a-difference-keeps'
M=R/'commons/maps/CA_EdgeOfChaos'
code=json.loads((O/'checks.json').read_text());room=json.loads((O/'museum/report.json').read_text())
assert code['passed'] and room['passed']
n=len(code['checks']);q=len(room['checks']);samples=sum(v['samples'] for v in room['observations']['routes'].values())
p=R/'doc/book/course/execution-plan/plan.json';data=json.loads(p.read_text(encoding='utf-8'));old=copy.deepcopy(data)
row=next(r for r in data['lessons'] if r['id']=='CA_EdgeOfChaos')
row.update(
 object='Same PointBody selects a section of two nearly matching fields and triggers their next synchronous update.',
 change='Copy one beginning, alter one address, apply the same procedure and forcing to both; distinguish stored difference, measured spread and display gain.',
 dependsOn=['CA_AgentsCircuits','CA_SoftRules','CA_ElementaryRules','Point_Coordinates'],
 reuses='Carried point/action, world-to-local address, independent arrays, old-to-next update, scalar fields and neighbour exchange, model/display separation, supplied host.',
 given='Day Zero Endless Museum host, player, camera, light and XR Tools. Full paired.gd, difference.gd and unchanged point_body.gd. Reproducible address/update forcing function supplied; no independent-random-sample claim.',
 later='Compact reconstruction uses keyboard parameter controls; installed desk retains VR controls, body-selected depth and shared floor receiver. Finite 11-cubed fields, 100-update cap. Secondary works remain museum companions. No universal critical point or proof of chaos.',
 checks=[f'{n} exact printed-file native checks. All values in 120 paired updates match the installed solver exactly across six settings. Analytic integer/fractional/zero-pull cases; 26 interior versus seven corner neighbours; old arrays, geometry, input, gain and cap.', 'Independent edit moves site to Vector3i(0,0,0): eight affected addresses, corner .75, edge contribution .25/11, interior contribution .25/26, no wrapping. Unmatched forcing and in-place update defects are detected.', f'{q} installed museum checks including camera assertions: held point has priority over walking, trigger STEP cancels pending batch, release returns control to stationary body, slice/coat preserve state, real console actions, clock/cap, four routes/{samples} clearance and level-floor samples, supported portal approaches.'],
 transfer='Move site from (5,5,5) to (0,0,0), keep uniform fractional storage, zero drive and pull .25. Predict eight changed addresses, then explain why receiving cells divide by different neighbour counts.',
 carry='Separate disappearance from view, disappearance from a thresholded count and disappearance from stored state. More affected addresses need not mean a larger difference.',
 next='Fractal_Recursion in the museum: contrast local exchange with explicit repeated construction. The eight CA hall drafts are now ready to read together before another expansion.',
 notes='Installed difference_model.gd and self_organization_ca.gd unchanged. Add carried point beside console and hand priority to walking reader. Retain all five authored works and level floor; move portals to thresholds. Native tests and images only; no physical headset, Quest, independent student or full portal transfer. Rear billboard labels still draw through the main view; secondary interactions remain outside this pass.',
 summary='Bring the same point to two 11-cubed fields. Duplicate the beginning, change one address in B and advance both through the same old-to-next neighbour average and forcing schedule. Move the held point to inspect a Z section; trigger one update. Release returns the installed reader to walking. Compare integer storage erasing the uniform intervention, fractional storage spreading a weaker difference, and zero pull keeping it whole in one place. Read affected count, maximum and image gain separately. Move the changed address to a corner and predict eight affected cells with unequal neighbour denominators. Carry the distinction between a state, its measurement and its image into Fractals.'
)
assert all(a==b for a,b in zip(old['lessons'],data['lessons']) if a['id']!='CA_EdgeOfChaos')
assert all(old[k]==data[k] for k in data if k!='lessons')
p.write_bytes((json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
(O/'after/lesson-plan.json').write_text(json.dumps(row,ensure_ascii=False,indent=2),encoding='utf-8')
s=(O/'before/technical.md').read_text(encoding='utf-8')
s+=f'''

## Complete learner reconstruction — 8 October 2026

`tutorial.md` prints `paired.gd`, `difference.gd` and unchanged `point_body.gd`, maintained under `doc/book/studies/cellular-automata-through-the-hands/CA_EdgeOfChaos`. The existing Day Zero `PointStudy` host supplies player, camera, lighting and XR Tools. The model owns the two fields; the display constructs all study geometry, textures, labels, support and input. The carried class is byte-identical to CA_AgentsCircuits. No prepared study children are required.

The compact model deliberately starts uniform, with DRIVE zero, PULL .25 and integer storage, making the first prediction legible. The installed desk starts scattered with DRIVE one; the lesson explicitly sets the controlled comparison before comparing outcomes. Both store PackedFloat64Arrays. INTEGER means an explicit int conversion before storage, not an integer array type. The supplied forcing schedule matches production exactly but is not presented as independent random sampling.

The first fractional update changes 27 addresses; the peak falls to .75. At generation 20 in the native controlled run, all 1331 addresses exceed the count threshold, the peak is {room['observations']['generation20']['max_difference']:.15f}, and the display gain is {room['observations']['generation20']['gain']:.9f}. This run spreads and weakens the difference. The count threshold is 1e-6. A/B colours use a fixed 0..9 range; only the difference image uses its declared reciprocal-maximum gain. The mean of the entire field is not promised to be conserved at the finite boundary, where neighbour counts differ.

The independent edit changes the intervention site to (0,0,0). The first fractional update then affects eight addresses: corner .75, receiving edge at (1,0,0) gets .25/11, receiving interior (1,1,1) gets .25/26. The changed corner itself has seven neighbours; each receiver uses its own neighbour count. No wrapping is introduced.

The installed walking branch now mounts `difference_hand.gd`, with the existing PointBody on a short rail beside the console. Held local Z chooses a slice. The walking receiver yields while it is held. Trigger calls the existing STEP operation, including cancellation of a pending +10 budget. Moving the point calls only select_spatial_slice and preserves that budget. Release invalidates the walker's previous band so a body still standing in the receiver resumes selection immediately, then the point parks at that slice. This changes selection and input priority, not the solver. Unconfigured studies keep their original behaviour.

The compact reconstruction has the same held-point selection and trigger; Enter steps, R replays, I switches storage, C toggles the intervention, P switches pull zero/.25, N toggles drive zero/one, B switches the seed. Parameter keys reset the fields. The installed desk supplies its existing VR controls, wider parameter ranges, walking reader and floor image. Those differences are declared.

All five authored artifact tokens and placements remain unchanged, as does the level floor. The extra generic gate is disabled and entry/exit move to source(9,0)/(9,29). Only this hall's generated plan row is rederived. Native route tests follow the console, body reader and rear gallery before reaching the exit.

Validation: {n} exact-printed-code and {q} museum checks pass in native Godot 4.6. All values in 120 paired source updates across six settings match exactly. The corner transfer runs the actual edited file. Two deliberate defects—different forcing in B and writing B in place—are detected. Checks cover old-array independence, thresholds, full instance transforms, support, texture gain, control resets and limits. Supplied XRTools poses test pickup, selection, trigger and release in a rotated/translated learner study and in the museum. A real CharacterBody overlap tests walking, dead band and hand/body priority. Four routes contain {samples} layer-1 capsule and level-floor samples; portal approaches are supported.

Nine native after images and five before images record the real hall. The learner model is temporarily mounted only for its photograph. Final logs contain no SCRIPT ERROR or Parse Error. The source model and wrapper remain byte-identical to the baseline. No physical headset, Quest performance, full portal transfer, independent student acceptance or complete secondary interaction audit is claimed. Existing blank frames and rear billboard labels drawing through the main view remain visible.
'''
(M/'technical.md').write_bytes(s.encode('utf-8'))
s=(O/'before/encounter-notes.md').read_text(encoding='utf-8')
s+=f'''

## 8 October 2026 — what a difference keeps

The final CA lesson now has a complete runnable reconstruction and an independently edited corner case. The same black point chooses a spatial section and triggers one update. Holding it takes priority over walking; release gives the selection back to the body. Selection never edits the fields. The existing paired solver and all five authored placements are preserved.

Keep three losses distinct: a changed cell can leave the selected section, fall below a counting threshold, or be removed by the storage conversion. Fractional averaging can spread a difference while reducing its maximum. Image gain makes a fading difference visible. The reflection stays with this encounter and leaves implementation to tutorial.md; it does not turn the hall's historical title into evidence for chaotic amplification.

{n} learner and {q} museum assertions pass; 120 paired updates match source exactly, the corner transfer succeeds, two defects are caught, and four routes/{samples} samples have clearance and level support. Native overhead, raised and visitor images plus both full texts: doc/book/iterations/2026-10-08-ca-what-a-difference-keeps/index.html. The rear labels and blank frames remain visual follow-up items. No headset or independent student assessment.

All eight CA halls now have a draft in this pass. Next editorial step: read the full tutorial and reflection sequences together, checking the carried point's changing roles and the distinctions between state, history, geometry and display. The next museum sequence is Fractals, already developed separately.
'''
(M/'encounter-notes.md').write_bytes(s.encode('utf-8'))
print(f'Updated one lesson contract; {n}/{q} checks; {samples} route samples; decision preserved.')
