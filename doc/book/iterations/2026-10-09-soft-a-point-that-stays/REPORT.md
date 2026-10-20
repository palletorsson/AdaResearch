# One point stays

Soft Bodies, hall 1 of 9. The cube continues from the earlier chapters; the carried black point becomes a probe. One attachment stays fixed while the surface responds around it. This makes a clear new step after generating forms: the student now supplies conditions under which a form keeps changing.

|Part|Before|Now|
|---|---|---|
|Tutorial|Encounter prose and three coefficient assignments|A complete cube class, host and unchanged PointBody, with setup, contact and one student edit|
|Selection|An attachment described without a learner implementation|Top-face search returns an index into retained reference positions|
|Reflection|Softness, constraints and the mill, with code and an outdated engine note|A separate reflective reading, no code blocks; current Jolt and hand assumptions stated|
|Entrance|Desk on the authored arrival point|Same desk moved four metres sideways and two metres into the hall, from cell (15,3) to (11,5)|

**28 exact-code checks and 29 native museum checks pass.** The tested program is extracted from the visible tutorial code. It constructs its own geometry and label; it inherits the prepared museum and XRTools. The pin is checked under a translated, rotated parent. Removing it makes the formerly fixed point fall. Contact with the carried sphere is compared with an otherwise equivalent host whose point-contact mask is disabled.

The first implementation put the soft mesh in `_ready()`. In this setup that was too late: the body entered the world without a mesh and failed to start a Jolt simulation. Moving construction into `_init()` fixed the failure. This order now appears in the explanation. Merely compiling the code would not have caught the missing behaviour.

The student changes one constant, DIVISIONS, from 4 to 2. The full host still runs; mesh entries fall from 216 to 96 and the selected upper point remains pinned. These counts include the mesh’s face entries, not a count of distinct spatial positions. A visibly coarser surface is not automatically a softer material.

The same body survives RESET. Its coefficients return; its positions do not rewind. This is the lesson’s bridge from Procedural Generation’s retained inputs into a simulation with ongoing state.

## The actual room

The original hanging cube remains the primary encounter. The learner reconstruction was placed temporarily beside it at hall-local (11.5,0,8.5), yaw 180 degrees, for the native checks and pictures. **It is not a newly installed main-route artifact.** The study is ready to place there from the printed files. The installed cube and other artifact algorithms are unchanged.

The entrance collision was traced to the workshop desk’s buttons and body. Moving that one placement restores the authored arrival without the blocked-entry fallback. All 273 samples along the centre entrance and right-side route have capsule clearance and floor support. This tests the local route; it does not certify a complete streamed portal crossing or headset comfort.

From above, the room has ample separation but a long empty stretch before the retained rear structure. The small encounters could eventually form a more compact court. That wider arrangement is a design finding, not a completed redesign.

The mill’s soft surface visibly stretches into long spikes in the native capture. Its drive control works, but that does not establish stable soft-body behaviour. It remains a comparison with an explicit open issue, rather than a second code task. The learner cube is the bounded, tested object for this hall.

## Evidence and limits

The six installed desk controls were activated with the supplied desktop pointer. The learner point was carried, pressed into the cube, activated and released through supplied XRTools poses. Code tests separately isolate point contact from an equivalent disabled-contact control. Native photos include both mesh resolutions, the existing artifacts and the hall from above.

The captures use the compatibility renderer and camera exposure 0.45. Lighting and running bodies are not frozen for the before/after room photographs, so those images establish placement, not a controlled material comparison. Existing project warnings remain in the logs, including an unrelated missing UID and renderer feature warnings. No script/parse errors or missing-physics-space errors occur in the passing runs.

These are author-led executable checks. Physical headset use, Quest performance and an independent ghost student’s understanding have not been tested. Browser layout was not automated in this pass.

Next: Cloth Physics. The object becomes a sheet, and the new decision is which boundary positions must stay.
