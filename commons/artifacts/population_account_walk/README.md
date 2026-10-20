# Population Support — the account in hand

Permanent museum lesson in `SwarmIntelligence_Swarm_Intelligence_Algorithms`.
The four printed files (`study.gd`, `observed.gd`, `account.gd`, `point_body.gd`)
remain byte-identical to the student source under
`doc/book/studies/swarm-through-the-hands/SwarmIntelligence_Swarm_Intelligence_Algorithms`.
Runtime uses the copies under commons and the existing ecosystem under algorithms;
it does not depend on the export-excluded doc folder.

The wrapper adds `population_hand_account.gd`. A small PointBody grip carries
a tilted account: initial, born, lost, supplied, expected, actual and gap,
with separate prey/predator columns. The selected organism's species, arrival
source and health remain visible while standing beside it. Hold a large sphere
and press its trigger to select it. Holding an organism pauses the simulation;
release it before stepping. The control grip itself is not an organism.

Four buttons call the original Run, Step, Restart and Supply Row commands.
The grip trigger toggles Run/Pause. Supply Row changes the account view only;
it never disables replenishment or deletes a body/event. The gap is actual minus
expected. With supply omitted it equals cumulative supplied arrivals, including
supplied bodies that have subsequently died; it is not a count of live gold rings.
Food/pressure support remains in the original wall notes and full event history.

The pad reads the original account and lists without adding events or drawing
random numbers. Drop it for five seconds to dock; regrabbing cancels the return.
Its text and buttons are inclined 25 degrees, matching the preceding PSO panel.
Both original control banks and the full-size ecosystem remain.

Validate the printed code with `tools/test_swarm_account.py`. Installed-museum
checks/captures: `tools/probes/account_hand_museum.gd`; passage checks:
`tools/probes/account_hand_portals.gd`, via `tools/run_encounter_probe.py`.
The report builder is `tools/publish_account_hand.py`.

Old write/place_swarm_account scripts predate this wrapper; inspect before rerunning.
