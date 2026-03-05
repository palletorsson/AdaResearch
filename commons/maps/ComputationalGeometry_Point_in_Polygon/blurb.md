# Point in Polygon

Cast a ray from any point toward infinity. Count how many times it crosses the boundary. Odd — inside. Even — outside. The ray casting algorithm reduces a spatial question to arithmetic. Where am I? becomes How many walls did I cross?

The room is the polygon. Irregular walls trace a non-convex outline across the 9×9 grid — no clean symmetry, no convex guarantees. The floor itself is the test region. Stand somewhere and know: the boundary decides what belongs.

The winding number offers a second answer. Instead of counting crossings, it counts how many times the boundary wraps around the point. Zero — outside. Nonzero — enclosed. Two algorithms, same question, different geometry of proof. Containment is not a property of the point. It is a relation to every edge at once.