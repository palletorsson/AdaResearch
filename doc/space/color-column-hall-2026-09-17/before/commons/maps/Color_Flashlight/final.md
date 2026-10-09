# What reaches the surface

<!-- @flashlight_demo -->

The colour is already there when you arrive. Several pools meet on a pale surface. Their edges are easier to follow than their crowded middle. Pick one edge. Which lamp is responsible for it?

Take the red lamp and turn it aside. Follow what leaves the surface. Bring it back slowly, across the other pools. There is a place where its red becomes difficult to name on its own. Move through that place again. Nothing has been painted over, yet something has appeared that neither lamp makes alone.

Leave the red lamp aimed at the surface. It stays where you release it. Take the green one and move its pool across the red. Separate them, then let their edges meet. Try the blue. The white lamp begins aimed aside; bring it into the comparison when you want to see what another contribution does. If the middle grows too pale to distinguish, separate the pools again. Their edges give you somewhere to begin.

In the previous room, a colour had neighbours. Here you can move one of the conditions of its appearance with your hand. What, exactly, have you changed?

The receiving surface keeps the same material throughout. Its stored base colour, its *albedo*, is a near-white value. Each lamp carries a `SpotLight3D`: a light with a position, a direction and a cone. Turning the handle turns the cone. The surface receives a different contribution because you have changed where that cone falls.

Inside each lamp, `flashlight_color.gd` finds the light and gives it its colour:

```gdscript
var spot = _find_spot_light(target_root)
if spot:
    spot.light_color = light_color
```

Four copies of the same scene receive four values. The red instance is given `Color(1, 0, 0, 1)`; the green instance `Color(0, 1, 0, 1)`. The first three numbers address red, green and blue channels. The last is alpha. The assignment happens when the scene starts. Your hand supplies the subsequent movement; the lamp does not need to change its colour value to make the surface look different.

Aim a beam off the board and onto the floor or the cube standing to its side. The cone can cross the boundary of its intended exhibit. Does the colour still read the same way? Follow a shadow or an edge before giving the result a name. The lamp carries a value, but it cannot carry a complete account of what you will see wherever you point it.

There is a useful limit here. These lamps offer RGB values to a renderer. They do not calculate a spectrum of wavelengths. The room also has other illumination: turning the lamps away does not promise darkness. Even the pale surface we have kept fixed is a chosen condition of this experiment. We have made a comparison manageable by leaving much of the world in place.

Perhaps the surprising body here is the patch of colour. You cannot pick it up separately from the meeting that produces it. Move one participant and its boundary moves; withdraw another and it changes again. The code gives us a way to repeat that meeting. There is still more to ask of it.

<!-- @ -->

Carry the distinction with you: changing the light that reaches a surface and changing the surface's own material can both change its appearance. In the next room, the receiving surface begins to resemble part of the body you act through. What happens when the colour is something you choose to wear?
