# The diagonal was already there

Native reference plate for Point_Animatedcube. The same Godot scene is shown in the museum and rendered for the book; no image texture stands in for the geometry.

The left specimen isolates the builder's front face. The right moves only v6 by +0.55 local metres in z. Both retain [4,5,7] and [5,6,7]. Amber marks the shared diagonal, pink marks the moved vertex, and dashed lines retain its former incident edges. Both use one oblique view and equal shallow depth compression for wall legibility. This is a schematic, not a measuring instrument.

The illustration supplies two fixed states. The nearby animatedcubebuilder handles provide the live experiment. Existing builder behavior is unchanged.

Run `python tools/capture_cube_diagonal_plate.py` to verify the vertices/triples against the current builder and render the production plate in an isolated Godot project. The museum placement is cell (7,5), facing into the main room, with its centre at 1.7 m. Headset legibility remains untested.
