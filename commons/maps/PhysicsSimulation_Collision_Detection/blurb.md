# Collision Detection

Every pair against every pair. That's the naive answer — O(n²), computational death. So the engine cheats. Broad phase carves space into a hash grid, tests bounding boxes, throws away everything that can't possibly touch. What survives gets handed to narrow phase: GJK, SAT, the algorithms that compute exact contact — penetration depth, collision normal, the precise geometry of impact.

Two zones, one passage. Objects drift between chambers, entering and exiting spatial partitions. Bounding boxes light up on overlap. Contact points flare on collision. The pipeline is a sieve — coarse filter, then fine — and what falls through is the only physics that matters.

Contact is expensive. The entire architecture exists to avoid computing it. Most of the engine's intelligence is spent proving that two things will *not* touch. Collision detection is the art of elimination — what remains, after everything impossible has been discarded, is the moment of meeting.