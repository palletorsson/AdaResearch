# CA_BeyondBinary — a pattern visits an address

Completed 13 September 2026. Primary: game_of_life_petri with study:addresses. All six previous works retained; no primary-role or active-route changes. The book hero is corrected to the actual primary. The 15×27 map gives the new study a front bay and separates the retained hexagonal work from it.

## Implementation and text

`commons/artifacts/game_of_life_petri/address_study.gd` coordinates the original B3/S23 solver, dish, fixed floor plane and three receivers. `life_address_receiver.gd` supplies the lamps and housed readouts. Other dish placements retain the default 64×64 mode. STEP, RUN, REPLAY, GLIDER, BLINKER, MEET and LINK support repeatable comparisons. Generation limit 48 is a local observation budget.

Ten room texts now follow the implemented encounter. The new final contains the actual rule branch and receiver call, formatted for reading. Source backups are in before/, with the original snapshot's hashes in before-hashes.json; the handoff backup was added later. Neither the lamps nor the floor are independent Life simulations.

## Evidence

- Final rendered run: PID 30560, exit 0, 30 checks, zero failures. runtime-receipt.json and runtime-verification.json record source hashes, measurements, real pointer events and support rays. No SCRIPT ERROR or Parse Error in the final engine log. The pre-existing unrelated UID diagnostic remains.
- The initial colour check used a tolerance inappropriate to GPU instance storage. Measured maximum channel error is 0.0002528, accepted below 0.002; logical lamp and event assertions are separate. Screenshots also caused added spacing and readout cases.
- Twelve content checks pass: rectangular layers, retained inventory, unchanged roles/order/other book pearls, only this hall changed in each museum plan, matching primary/hero/final marker, actual code excerpts, and correct next active hall.
- All thirteen published assets respond with HTTP 200 and exact source hashes. Eleven browser behaviour/image checks pass; the revised chapter has two rendered code blocks and no horizontal page overflow. The primary UI shows one written Life dish and opens its matching 641-word passage.
- Actual images: doc/research/possible-bodies/ca-life-{entrance,controls,floor,readout,whole-hall}.png. Review: http://localhost:3003/research/possible-bodies/ca-life-addresses.html.

## Remaining scope

Headset reach, comfort and performance are deferred. Only a portion of the ordinary museum margin was walked; the retained rear collection has not received a full interaction/traversal review. No general proof of a critical or entropy regime is claimed. The next hall is CA_ExpandingSpace, requiring proximity/health/support witnesses and investigation of its update order before describing it as synchronous CA.

Rebuild the page with tools/build_ca_life_review.py; its source-hash/runtime gates prevent publishing stale captures. ada_run/review_ca_life.py starts an isolated hidden, muted review and terminates only its own process on error/timeout. Do not stop the user's editor or game. Publish the bounded manifest with ada_run/publish_ca_life.ps1. No agent work dispatched.
