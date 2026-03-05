# Convex Hull Algorithms

Given a scatter of points, find the tightest boundary that contains them all. No point left outside, no boundary segment that bends inward. Graham scan sorts by polar angle, then walks counterclockwise — rejecting any turn that curves the wrong way. Gift wrapping starts from the leftmost point and pivots, always choosing the most counterclockwise neighbor. Both algorithms converge on the same shape. The minimal enclosure.

Walk the perimeter. Platforms rise along the outer edge — each one a vertex of the hull. The interior stays open, unstructured, irrelevant to the boundary. Points that fall inside are discarded. They contribute nothing to the shape.

Every convex hull is an act of exclusion. The algorithm decides what counts as edge and what gets swallowed by interior. Structure defined not by what it contains but by what it refuses to fold around.