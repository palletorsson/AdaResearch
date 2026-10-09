# Book and artifact revision archive

These folders preserve earlier files and evidence for individual revisions.
They are reference material, not a second copy of the running Godot project.

For ongoing work, read [the working method and current handoff](WORKING.md).
It defines how to scope each continuation, reuse evidence and choose an appropriate level of effort.

Keep `.gdignore` in this directory. Archived `.gd` files may declare the same
global classes as their live counterparts. Godot must not import or register
these copies. Git and the documentation tools can still read and preserve them.
