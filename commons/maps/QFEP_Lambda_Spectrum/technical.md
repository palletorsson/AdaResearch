# A recommendation independent of its surroundings

In the Introduction, lambda weights the E contribution to an arithmetic total. Here it becomes a spatial analogy: an authored spectrum has repeated cubes on one side, jittered and animated cubes on the other, and six intermediate rows. No entropy distribution is measured to assign their places.

The existing lambda_value configuration controls the corridor's initial clearance and the colour/emission emphasis of its rows. It remains at 0.35 in this hall. Previously changing it also moved the lit floor, so a comparison could not distinguish a changed recommendation from changed surroundings.

The optional recommendation_control:on adds a LIT STRIP rail and RETURN button at the entrance. Its recommendation_position ranges from 0.20 to 0.80. The lit strip has no separate collider. It moves above a continuous floor:

```gdscript
_recommendation.position.x = (value - 0.5) * hall_width
```

The recommendation node contains the lit floor mesh, its two bright edge strips and its inscriptions. Changing this value moves that node and updates the suggested-value labels and console reading. It does not rebuild the spectrum, move its rows, recolour their materials, reseed them, move the capture camera or reset animation time. RETURN restores the initial authored recommendation without rebuilding the environment.

The slider interval keeps the 1.4 m strip inside the side kerbs of the seven-metre hall. Those bounds are interface choices. They are not claims about optimal lambda. The kerbs have taller invisible containment colliders than their visible mesh. The cube rows themselves are rendered forms without individual solid collision; the continuous floor carries the walker. A glowing strip under a cube is therefore a visual contradiction, not a newly computed traversable route.

The full fourteen-metre-long artifact now fits inside a seventeen-by-twenty-four gallery. Nine secondary placements remain in the outer bays. The bifurcation_walkway token is retained but its registry still disables it; enabling that comparison is separate development work. The other works do not receive this rail's value. A malformed noise hash in the dissolving form's shader is corrected so that retained comparison can render again. The map's older along-z/body-as-slider captions are removed because no such player-position coupling is implemented. artifact_placement:map makes these placements authoritative over an older stamped necklace that omitted the main hall. The central encounter is kept clear of automatically added sculptures.

Default placements without recommendation_control keep their original coupling between configured lambda, geometry and floor placement, without the new console. Configuration rebuilds now free only nodes made by the artifact, preserving external framing.

The comparison asks whether moving a recommendation changes a visitor's preference. The runtime checks establish that the controls keep the intended variables fixed; a response from visitors is still needed to investigate the question.
