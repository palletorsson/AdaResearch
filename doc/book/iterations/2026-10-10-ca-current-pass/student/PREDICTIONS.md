# Predictions written before Godot execution

These are AI reconstruction and transfer predictions, not human-learning evidence. No Godot execution or pre-existing probe was used to write them.

## CA_Introduction

Original: Rule 90 single 16 gives [15,17]; next [14,18]. Variation source seeds [3,5] gives [2,6], because cell 4 receives two true neighbours and cancels. Traversal cannot affect synchronous answers; original state must remain untouched. Saved rows must not alias the current array. Visible first row must match states.

## CA_ElementaryRules

Original centre states/counts are (1,11),(2,14),(0,5), following the printed small seed. Variation is a 2x2 square at x=2,3 z=2,3 y=3. The nominated centre (3,3,3) has (1,3),(2,0),(0,0). No cell can see six active neighbours initially, so all four fade then the entire field is empty. A fading centre with seven neighbours must still empty. Outer shell remains empty.

## CA_GameOfLife

Original seed 7 gives [6,7,8]. Variation changes only screen X from .85 to .85 + .012*x, producing a diagonal screen; a cell at x=7 is at X=.934. Deck and collision retain the original mapping. Occupied recorded cells have both meshes and deck support; recorded false cells and future cells do not. Reading row zero cannot rewind the current state; saved rows must remain copies.

## CA_BeyondBinary

Original glider shifts (1,1) after four steps; fixed A is lit at 8 and dark at 12. Variation replaces seed with a block at (2,2),(3,2),(2,3),(3,3) and SITE=(2,2). Its states and lamp stay true for every tested step. Unlinking darkens globe/light without changing the state or clock; replay preserves link. A block tests survival plus lack of births, not the worked blinker.

## CA_ExpandingSpace

Variation changes RADIUS to .75 simulation metres. A synthetic held path approaches cell (1,4), pauses for six committed steps .05 view metres above it, then withdraws for two steps. At paused time the target is .76 in both programs; W=(2,6) stays 1.0. Diagonal (2,5), distance sqrt(.6^2+.6^2+.25^2), is .76 with original radius 1.35 but 1.0 with .75. All neighbouring values stay >.5, so after withdrawal target=.84. Moving without stepping cannot alter state. Exact health .2 keeps support; .199 loses it. Transformed study must preserve local input.

## CA_SoftRules

Original W first A=(.92,.02), B=(1,0). Variation adds same 3x3 seed centred (5,6) with U=.7,V=.1 to both resets. Untouched (3,6) has one changed axial neighbour: lapU=-.3, lapV=.1, so first A=(.952,.008), B=(1,0). Unchanged central seed still behaves as printed. Exchange enabled in both must give equal arrays. View changes only textures; valid held planting changes both fields without clock advance, invalid/unheld planting does nothing.

## CA_AgentsCircuits

Original single seed gives [15,17], and at generation 16 the ring is empty. Variation source [1,4,8] gives [0,2,3,5,7,9] at generation one. Cube recipe remains 216 entries/transforms regardless of seed or step. The chosen feature is separation of the two outer tips from the four inner tips: its row intervals differ from the single-seed symmetry, while the sculpture remains fixed. Dark recorded zero cells remain drawn; future slots are hidden.

## CA_EdgeOfChaos

Original integer centre difference is discarded after one update. Fractional centre control yields count=27 and peak=.75. Variation uses face site (0,5,5), fractional storage and pull=.5: after one step self plus 17 valid neighbours differ, so count=18, peak=.5. A face receiver (0,4,5) gets .5/17; an interior receiver (1,5,5) gets .5/26. Far face is unchanged. Slice selection cannot change arrays/time. Identical beginnings with shared forcing must remain identical. Display gain=2 after the variation first step; a bright difference pixel does not imply growth.
