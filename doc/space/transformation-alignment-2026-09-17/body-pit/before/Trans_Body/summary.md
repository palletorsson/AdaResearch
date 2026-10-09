# Trans Body — Summary

The visitor becomes the input to three thresholds. `approach_wall` rotates slats near a body and closes behind it. `carve_grid` deletes occupied cells near the visitor's collision volume and retains the passage. `approach_scale` shrinks blocks according to proximity and restores their size when the visitor leaves.

The distinction is between what returns and what remains. Carving changes which cells exist; it is not translation. The scaling field keeps each block's horizontal location while lowering its centre as it shrinks, keeping its base on the floor.

The labels name TURN, REMOVE and SCALE. The exit now continues over floor rather than an unintended hole. Trans_Pit takes the same question of occupied space into timed obstacles: its motion continues without reading the visitor's approach.
