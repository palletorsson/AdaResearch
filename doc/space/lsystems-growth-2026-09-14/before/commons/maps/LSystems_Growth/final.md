# What a branch inherits

<!-- @parametric_lsystem -->

How can a branch become shorter while another branch resumes at its earlier length?

Start near the base of the parametric tree and trace a route through several forks. Compare an early branch with one nested farther towards a tip. Then return your attention to the fork and follow its other descendant. Look for a repeated relation of scale, even where the directions differ.

At one junction, mentally mark the place where a branch begins. Follow that branch to its end, then return to the marked place and continue along another route. This is a spatial way to rehearse saving and restoring a state. Ask what information your rehearsal needed: a location alone would not tell you which direction to face or how long the next segment should be. The visible tree gives you those relations together; naming them separately reveals why the interpreter stores more than a collection of disconnected positions.

The grammar produces a string before the tree is drawn. Its interpreter carries numerical state as it travels: position, orientation, branch length and depth. Entering a branch saves that state, changes the length used by its descendants, and continues drawing. Leaving the branch restores the saved state so that another route can begin from the appropriate place and scale.

That restoration is easy to miss in a finished silhouette. Without it, the shortened length or altered direction of one branch could accidentally become the starting condition for its sibling. The saved state keeps a branch's local history from rewriting every route that follows it.

The turn variation is generated with a fixed seed. It introduces differences between branches while keeping this particular specimen reproducible. It does not mean the tree is responding to light, weight or the visitor's position.

The previous room let you distinguish rewriting from interpretation. This tree develops the second part: a symbol can act on numerical state, so the same kind of instruction has different dimensions at different nesting depths. That is a precise sense in which parameters participate in the construction.

<!-- @ -->

For an extension, compare two copies with identical grammar and seed but different length decay, keeping their scales comparable. Ask where the difference first appears and how it accumulates towards the tips. The next room will go further by letting an interpreter give an ordinary movement symbol an unfamiliar meaning.
