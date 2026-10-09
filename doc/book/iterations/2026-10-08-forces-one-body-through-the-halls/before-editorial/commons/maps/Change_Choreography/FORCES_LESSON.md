# The same return, a different cause

Primary: `phase_rod_array`.

Keep two sphere points as the tips of two thin arms. Freeze them and remove collision for this diagram. Store one angle for each arm. OFFSET changes an angle once; DRIFT changes how much one angle gains each second. The small study uses accumulated angles so a rate edit preserves current position.

Carry: Keep the distinction between authored position and simulated force. The next two points attract each other; neither is assigned a circular path.

Check: Apply OFFSET while rates are equal: the 45° gap remains. Restart, apply DRIFT, and wait thirty seconds: the 4% rate difference adds 72°. Halve that difference to 2% and predict 36°. A new input changes one term, not every part of the study.
