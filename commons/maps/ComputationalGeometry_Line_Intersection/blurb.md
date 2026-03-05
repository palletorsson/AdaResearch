# Line Intersection

Two corridors cross. The intersection point is the entire problem.

Given two line segments, do they meet? The cross product answers: compute the signed area of the triangle formed by three points. If the signs differ, the segments straddle each other's supporting lines. Two straddle tests — one per segment — and the answer falls out. No quadratics, no special cases for slope. Just the sign of a determinant.

One pair is trivial. A thousand pairs is not. The sweep line moves left to right, maintaining only the segments currently alive. When segments swap vertical order, check that pair — and only that pair. O(n log n) instead of brute force. Order imposed on disorder through a moving frontier.

The cross at the center of the room is the algorithm made architectural. Two paths share a single cell. Intersection is not collision — it is the point where independent trajectories produce shared coordinates. Geometry's most basic question: where does one line's logic meet another's?