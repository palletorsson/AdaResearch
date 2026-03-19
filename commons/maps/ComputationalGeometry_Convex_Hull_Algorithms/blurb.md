Platforms line the perimeter. The center is open, low — a courtyard surrounded by raised stations at height-3. Walk the border. You are tracing the convex hull.

Imagine a rubber band stretched around pushpins on a board. It snaps to the outermost pins, ignoring everything interior. The convex hull is that rubber band: the tightest convex boundary enclosing all points. Graham scan sorts by angle and marches counterclockwise. Gift wrapping picks the next extreme point by turning. Both find the same boundary — the minimal enclosure.

Most points in a random scatter are interior — they contribute nothing to the hull. The hull is defined entirely by the extremes. The tightest boundary around a set reveals which members actually define the shape, and which are just along for the ride.
