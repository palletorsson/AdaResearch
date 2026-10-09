# One gap, two stations

Keep five existing primary tokens in order: vector_add, vector_sub, dot_aligner, projection_shadow, torque_crank. All twelve artifacts remain. The new work upgrades vector_sub and projection_shadow through opt-in room_gap and room_projection configurations; other placements keep their original consoles.

Subtraction: A/B selects an address, X-/X+/F-/F+ change a component by 0.5 coordinate metres, SWAP reverses A-B, SHIFT translates both by 0.5 along X and reverses on next accepted press, SAME copies A to B, RESET restores A=(1,.5), B=(-.5,0), RULE reveals arithmetic. Components are bounded to [-1.5,1.5]; common moves are refused atomically at the boundary.

Projection: binds to the gap source inside the same museum segment. TURN rotates a unit rail 30 degrees, SLIDE moves source A perpendicular to that rail by 0.5 metres (alternating sign), FLIP reverses rail orientation, RESET restores both source inputs and rail, RULE reveals arithmetic. The actual shared gap feeds kept=axis*gap.dot(axis), remainder=gap-kept. One coordinate metre is displayed as half a metre on both stages and walls. This is a diagram scale, not player/world position measurement. Values are live while the hall is loaded, not a saved cross-session state.

Test sequence: swap; common translation; coincidence; perpendicular slide; rail turn; sign reversal. Predict first, reveal second. Keep the input fixed while changing the receiver, then change the input in a direction the receiver cannot record. The closed loop is kept+remainder=gap. Zero gaps remain finite; the rail is never a zero direction.

Existing dot and torque consoles are distinct examples, not subscribers to this pair. Dot uses an alignment slider and a chosen threshold; torque uses normalized directions and a displayed wheel angle. Its readout reports sin(theta), the chosen angle and a static wheel pose. The unit-direction cross product sets that pose; it does not integrate angular velocity or report rpm. The final chapter now identifies those limits instead of claiming free aiming, continuous physical wheel motion or a newly simulated force.

Next on the unchanged route: VFM_05_Launch. Motion-before-Launch remains an editorial proposal.

The remaining dot console uses normalized directions and FRIEND at dot >= 0.985. Its ordinary slider spans a limited range; the full signed range of a dot product is mathematical context, not a claim that this control reaches every angle. The crank computes r_dir.cross(f_dir) from unit directions. Actual torque would include arm length and force magnitude; the displayed angular factor alone is not physical torque. Projection recombination and perpendicularity hold to ordinary floating-point precision.

## Reading and retained detail

The canonical [chapter](Vectors_Act2_VectorArithmetic.after.md) follows the encounter. Exact scales, control steps, timing and implementation qualifications remain here. The complete [pre-pass chapter](Vectors_Act2_VectorArithmetic.before.md) is retained for comparison.
