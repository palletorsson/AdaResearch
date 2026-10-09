# A celebration along the walk

Five familiar wire pickup cubes now lead through the centre of the Rainbow hall. Each crossing releases coloured sparks whose tails hold a short history of their flight. At the far end, two slender poles support a six-stripe banner that the body can pass beneath.

## Decisions

- Reused the existing cube scene and sound. A hall-local collection method provides celebration without adding score or changing progression.
- Kept the level route, optional steps, welcome confetti, RE-DIVIDE and CELEBRATE. Each new cube is collected once per hall load. The button repeats the original confetti.
- Copied the current arch palette into each new spark burst. Each burst has 28 sparks, 14 segments per tail, a 0.75-second history and a 2.8-second lifetime. No more than five bursts can remain active.
- The two-pole banner is a distinct fixed palette. Its cloth has a slight sag and ripple and clears the floor by 2.85 metres. Re-dividing the arch leaves the banner and existing flags alone.
- Added the colour/queer/boundary discussion as a footnote for later. It distinguishes colour's social meanings from any innate queer hue, avoids a general claim about conservatives and pastels, and identifies Kristeva's account of threatened boundaries as a reading lead. Continuous controls remain a proposal.
- Kept the chapter's existing technical explanation and its passage into Pillar. Added the walk and banner to current final.md and refreshed the Colour capture.

## Verification scope

The probe loads the production museum in an isolated run, uses the actual pointer callbacks and ordinary walking controller, and checks collection, cleanup, tail geometry, banner clearance and unchanged band comparisons. The images are native Godot renders. The spark image pauses particle updates at the reached time for one capture; it does not add particles for the image. See report.json for the completed checks.

An initial run found the local generated class cache registering ControlPanel to an archived report copy. That cache entry was corrected to the canonical UI script. No shared ControlPanel source was changed. Existing unrelated UID/catalyst viewport warnings are retained in the engine log. Headset comfort and tracked-controller interaction remain untested.
