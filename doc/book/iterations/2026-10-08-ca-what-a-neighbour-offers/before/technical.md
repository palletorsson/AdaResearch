# Incremental exchange in two fields

`rd_artifact:0:0#study:exchange#plinth:0` mounts the optional live study. The original configured batch-heightmap path remains available and unchanged. The bare wrapper still requires a config outside study mode. This is a Gray–Scott reaction–diffusion discretisation, not an implementation of Lenia or stochastic CA.

## State and update

`live_field.gd` stores two 32×32 PackedFloat32Arrays U,V and separate next buffers. Beginning: U=1,V=0 except x,y=13..18 inclusive, where U=.5,V=.25. Both fields use the same fixed beginning. No random input is added. Five-point periodic Laplacian: left+right+above+below−4×centre. Du=.16,Dv=.08,F=.037,K=.060,dt=1. Explicit synchronous updates clamp each concentration to [0,1], then swap buffers. Exchange OFF sets both diffusion contributions to zero; reaction, feed and removal continue.

W=(12,15) lies directly outside the seed. One update gives A: U=.92,V=.02; B with exchange off: U=1,V=0. At a uniform interior seed address, the first update is U=.48725,V=.257. The unchanged legacy batch implementation is `commons/graph_grammar/operations/rd_displace_op.gd`; the incremental solver is compared against it using exactly the same eight seeded disks in the runtime probe.

## Controls

STEP advances one update and holds. RUN toggles continuous stepping; at most four updates execute per 0.1-second opportunity, without catching up a delayed frame. Ticks denote numerical updates, not real seconds. +100 schedules exactly one hundred further updates (limited by the 2,400 total observation budget). REPLAY restores both fields and clears the intervention count while retaining view, coating and B exchange selection. EXCHANGE B toggles B's diffusion and restores both beginnings. A always has diffusion enabled. INJECT sets U=.5,V=.25 at x=3..5,y=14..16 in both current fields, without advancing their clocks. VIEW U/V and COAT do not change stored values or time.

## Spatial mapping

Two 1.6 m table fields share their respective textures with two curved 3 m tall wall displays. Their grid edges are visible, but simulation edges wrap. Each CPU ImageTexture is 32² RGBA8, nearest filtered; no smoothing conceals the lattice. V colours interpolate from dark blue to pink using clamp(2V,0,1); U colours interpolate from violet to green using U. The wall surfaces have no changing collision. Plinths and the museum floor provide fixed support. A mounted witness instrument and eight pointer-compatible rack buttons stand to the side. The gold table frame nominates W; it does not follow a moving feature.

## Preservation and limits

The old 13×10 map's retained gallery is carried into a 17×26 hall, with an added front bay and eastern aisle. All six authored works remain. rd_artifact and the_clockmaker_of_rules are primary and each has a book passage. Four other works remain secondary for later interaction review. The clockmaker lacked map_ready in the museum registry; its scene is restored and its labels now distinguish calculated histories from static illustrations. Current sequence order is unchanged. Desktop evidence accompanies the review page; headset reach, readability and performance remain unverified.

## 25 September: a body leaves a seed

The map adds `#seed:walk` to its existing exchange-study token. `walk_seed.gd` adds a flush visual mark, 1.5 × 1 m, centred at local (0,0,2.15). Its 1.8 m high Area3D receives the actual museum CharacterBody or XRToolsPlayerBody. Props, hands and unrelated characters are ignored. This measures body-volume overlap, not foot pressure or a chemical response to weight. The ordinary museum floor remains the collider beneath it.

The first accepted arrival calls the existing `inject()` once. Both fields receive U=.5,V=.25 at the existing nine addresses x=3..5,y=14..16. No numerical time advances. Remaining in the mark does not replenish the patch; after all visitors leave, another arrival can inject again. REPLAY while occupied restores and holds the clean beginning until a fresh entrance. VIEW and COAT retain the body input and stored values. The original eight controls and solver are unchanged; the unconfigured exchange study has no floor receiver.

After the first hundred updates, the controlled body enters and leaves this second patch. One further update transports V outside its original edge in A relative to a matched no-entry control; B's unseeded neighbour stays zero. After a hundred further updates, the patch centre is weaker in A than B. This is dispersal as well as propagation, not evidence that exchange guarantees a seed's persistence. Current native checks and limits are recorded in `encounter-notes.md`.
