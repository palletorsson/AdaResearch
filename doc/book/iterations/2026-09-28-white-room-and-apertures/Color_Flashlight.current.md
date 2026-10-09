# What reaches the surface

<!-- @flashlight_demo -->

Several pools of colour meet on a pale board. Their edges are easier to follow than their crowded middle. Pick one edge. Which lamp is responsible for it?

Take the red lamp and turn it aside. Follow what leaves the surface. Bring it back slowly, across the other pools. There is a place where its red becomes difficult to name on its own. Move through that place again. Nothing has been painted over, yet something has appeared that neither lamp makes alone.

Leave the red lamp aimed at the surface. It stays where you release it. Take the green one and move its pool across the red. Separate them, then let their edges meet. Try the blue. The white lamp begins aimed aside; bring it into the comparison when you want to see what another contribution does. If the middle grows too pale to distinguish, separate the pools again. Their edges give you somewhere to begin.

In the previous room, colour was assigned to forms and positions. Here you can move one of the conditions of its appearance with your hand. What, exactly, have you changed?

The receiving surface keeps the same material throughout. Its stored base colour, its *albedo*, is a near-white value. Each lamp carries a `SpotLight3D`: a light with a position, a direction and a cone. Turning the handle turns the cone. The surface receives a different contribution because you have changed where that cone falls.

Aim a beam off the board and onto the floor or the cube standing to its side. The cone can cross the boundary of its intended exhibit. Does the colour still read the same way? Follow a shadow or an edge before giving the result a name. The lamp carries a value, but it cannot carry a complete account of what you will see wherever you point it.

Beside the board stands a coarse, pale sphere. Carry the red beam across it. One face brightens while its neighbour stays dull. Move the lamp to the other side and watch the difference change places. No face has been repainted.

We met these flat faces among the primitives, where they interrupted the promise of a smooth sphere. Here they give the light different directions to meet. Each face has a direction, called its *normal*, which the renderer uses along with the light and material to calculate its appearance. What looked like one pale body begins to answer face by face. Bring a second colour across the first. The construction you could barely see now divides their meeting.

![The same pale sphere under a red lamp held on either side. The camera, mesh and material stay fixed.](/book-review/doc/book/iterations/2026-09-23-flashlight-faceted-sphere/same-sphere-moving-light.png)

The red lamp has crossed from board to sphere without changing its assigned colour. Inside each lamp, `flashlight_color.gd` finds the light and gives it its colour:

```gdscript
var spot = _find_spot_light(target_root)
if spot:
    spot.light_color = light_color
```

Four copies of the same scene receive four values. The red instance is given `Color(1, 0, 0, 1)`; the green instance `Color(0, 1, 0, 1)`. The first three numbers address red, green and blue channels, each from zero to one. Zero contributes none of that channel; one gives its full value. The fourth number, alpha, stays at one here.

The assignment happens when the scene starts. While you move the lamp, its colour value stays fixed. You have changed where its light meets the room.

There is a useful limit here. These lamps offer RGB values to a renderer. They do not calculate a spectrum of wavelengths. The room also has other illumination: turning the lamps away does not promise darkness. Even the pale surface we have kept fixed is a chosen condition of this experiment. We have made a comparison manageable by leaving much of the world in place.

Perhaps the surprising body here is the patch of colour. You cannot pick it up separately from the meeting that produces it. Move one participant and its boundary moves; withdraw another and it changes again. The code gives us a way to repeat that meeting. There is still more to ask of it.

<!-- @colour_light_rooms -->

Through the side opening, a white room waits with a small light hanging near its centre. The walls, floor and ceiling receive its colour. Stay with one corner as the rose passes into violet. Its edges remain, but the distance between them can feel less certain.

Nothing has been repainted. Earlier, your hand moved a lamp whose colour stayed fixed. Here the lamp stays in place while its colour changes. You can keep walking, or let the room change around you while you stand still.

![The same white room at two moments in its light cycle. The camera, walls and their base colour are unchanged.](/book-review/doc/book/iterations/2026-09-28-white-room-and-apertures/white-room-pair.png)

The next doorway opens below three layers of ceiling. Each has a rectangle cut through it. Colour gathers along their edges; beyond the last opening is the museum's sky. From below, a bright rectangle can look almost solid. Walk towards it. The rims slide across one another as your position changes, and the space between them becomes easier to see.

A shallow ramp brings you onto a raised landing. You have changed your height within the same light. What had seemed to be one nested image now has an underside, a nearer edge and a farther opening.

James Turrell's work offers a way into this attention: the architectural opening participates in what the light seems to be.[^apertures] Our rooms keep their own limits. Their colours come from RGB lights and luminous edges calculated by the engine. The openings are real gaps in the geometry. The sky beyond them is rendered too.

![Looking through the three ceiling openings from inside the museum.](/book-review/doc/book/iterations/2026-09-28-white-room-and-apertures/apertures-from-floor.png)

<!-- @ -->

Carry the distinction with you: changing the light that reaches a surface and changing the surface's own material can both change its appearance. In the next room, the receiving surface begins to resemble part of the body you act through. What happens when the colour is something you choose to wear?

[^apertures]: Turrell is a reference for this study, not its author. The Guggenheim describes *Aten Reign* (2013) as concentric elliptical rings of changing light, reorganising the rotunda as an experience viewed from below. Our rectangular rooms explore another arrangement, with a walkable change of eye level. See the [Guggenheim exhibition release, hosted by James Turrell](https://jamesturrell.com/wp-content/uploads/2013/06/gug_turrell-release-final.pdf).
