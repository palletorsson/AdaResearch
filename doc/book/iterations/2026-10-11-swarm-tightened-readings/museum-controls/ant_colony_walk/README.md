# Two trails underfoot

Permanent12m walk-in colony,24 grabbable PointBodies, two-channel field. Scene: ant_colony_walk.tscn. Script copies are byte-identical to the printed learner code and validated by tools/test_swarm_aco.py. Runtime dependencies stay under commons/ because exports exclude doc/.

## Controls in the field

The museum wrapper also adds `colony_hand_control.gd`: a portable pad held by the same PointBody grip. It is a control, not a twenty-fifth colony agent. The selected agent's SEARCH/RETURN state, read/write channels, three sensor values, tick and delivery count come directly from the existing model. Channel colours match the floor legend.

Take the black point beside the entrance control bank. Held trigger toggles run/pause. Four buttons call the existing run, single-step, replace and clear methods. Move a colony sphere with the other hand; its trigger selects the record. Release that agent before stepping. Held-agent protections remain in force. Dropping the pad keeps it nearby for five seconds, then returns it to its dock; regrabbing cancels that return.

The original end controls remain active and share the same state. The pad does not steer agents, change fields or add a second simulation. The printed study/model/point files and the entire map layout remain unchanged.

Validation: `tools/test_swarm_aco.py` checks the exact printed/runtime code; `tools/probes/colony_hand_museum.gd` checks the installed pad, supplied desktop/XR interactions and routes; `colony_hand_portals.gd` checks ACO → PSO → ACO. Publish with `tools/publish_colony_hand.py`. Physical headset use and Quest performance remain untested.

The earlier `write_swarm_aco.py` / `place_swarm_aco.py` generators predate the pad and east ant gallery. Do not run them over the current room without reconciling their output. See this hall's technical.md for units, simplifications and evidence limits.
