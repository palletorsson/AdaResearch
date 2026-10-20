# Boids — step outside

The large flock already moves beyond the museum walls. A new west balcony gives the visitor somewhere to stand within that wider view. Walk through the three-metre opening beside the flock displays. The eight-by-five-metre deck stays level with the hall; thin dark rails and a pink edge light leave the sky visible. All three exposed edges have collision guards. Turn back through the same doorway to return to the tutorial.

The museum's automatic exterior wall initially sealed the authored opening. The balcony declaration now opens that wall too. The walking probe caught the obstruction before release. The failed first attempt is retained in `investigation/`.

16 native checks pass, including an actual CharacterBody walking out and back with gravity, a continuous floor, clearance through the doorway, all three edge guards and standing sightlines. The photographs come from Godot with the flock running. These checks do not constitute physical headset testing.

The flock's algorithms, counts, materials and movement parameters are unchanged. The tutorial code and reflective text are unchanged. Only the Boids plan row changes; the architecture feature is inactive in halls without a balcony declaration. Reload the Boids hall to build the new architecture. Existing engine UID/render warnings remain outside this change.

Next lesson remains Agent-Based Modeling, the fourth Swarm hall.
