The floor is an irregular shape — not a rectangle, not convex. Walls jut inward at odd angles, creating a polygon boundary you can trace with your eyes but not easily classify. Stand inside it. Are you sure you are inside?

The ray casting algorithm answers by drawing an imaginary line from the test point to infinity and counting boundary crossings. Odd count: inside. Even: outside. The winding number method asks instead how many times the boundary wraps around you. Both reduce containment to counting.

A convex shape makes inside and outside obvious. But add one concavity — one inward notch — and intuition fails. You need an algorithm. Containment is not a feeling. It is a crossing count, and the crossing count does not lie.
