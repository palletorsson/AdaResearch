# Technical contract

Wave 3 adds four distinctions to the placement language:

- wall safety fixtures can share architectural territory while retaining individual reach and sightline rules;
- museum furniture stands directly on the floor and owns service circulation rather than receiving another plinth;
- one-sided signs and boards can declare an artifact-local facing correction independent of room rotation;
- dynamic artifacts declare a behavioral envelope when mesh AABB measurement cannot represent their particles, and their placement config must constrain the emitted result to that envelope.

The generated map contains ten rooms on the one-metre grid, one connected visitor route, one spawn, and one exit teleporter. Pathfinder validation reaches 282 of 306 walkable cells with no warnings. Composer negotiation accepts all ten candidate rooms without writing during dry-run validation. Fresh staged renders verify ten visual passes and zero Wave 3 reviews.
