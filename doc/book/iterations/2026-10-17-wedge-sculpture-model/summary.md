# Blocking, climbing, sculpture — then a route in the hand

On the Primitives_Polythedra platform, six copies of the original prism_block make a 1.95 m sculptural column: three paired diamond modules. Its joints remain fixed. The side ramps, three-metre passages and descending route are unchanged.

The second addition is a 2.8 × 1.0 m plinth with a brown wedge mouse and cheese. The player steers the mouse using a returning joystick, and presses JUMP to leap in the last steered direction. Seven identical right-triangular pieces are grabbable: two stoppers, an incline, two platform halves and two landing halves. Turning and placing pieces changes contact and support. The cheese is a gravity-enabled body and falls if unsupported.

HOME returns only the mouse. RESTORE resets all seven construction pieces, the mouse and the cheese. Construction pieces remain where released; there is no persistent layout save. Hand grabbing, pointer dragging and poke/ray buttons use existing interaction components. These controls leave avatar input alone.

Final, tutorial, technical, summary, intent, inventory and this map's curation/spine order follow blocking → climbing → sculpture → small model → descent. Existing notes are retained. Other maps and museum plan rows are unchanged.

98/98 native hall checks pass; 24/24 supplied-control model checks pass; 13 scoped data checks pass. The mouse is stationary without input, the central stoppers resist direct steering, a detour reaches the ramp, and a player-directed jump reaches the raised landing. Moving the ramp removes that ascent; removing the far support lowers the landing. HOME preserves edits and RESTORE returns the arrangement. Joystick pointer direction and release are checked. Native capture caught inward-facing button caps; they now face outwards and are checked explicitly.

The one-millimetre convex margin is important at this scale: the default four-centimetre rounding caused the small mouse to meet an artificially steep contact at the ramp foot. The miniature uses slowed gravity and is not a scaled model of real mouse mechanics. Fixed sculptural joints are not a balancing test.

Pathfinder: zero failures, with existing edge-teleporter and enclosed-rock-spawner warnings. Engine reports retain existing registry/renderer warnings. VR grip comfort, button reach and visitor interpretation still need a wearer. No commit or push requested.
