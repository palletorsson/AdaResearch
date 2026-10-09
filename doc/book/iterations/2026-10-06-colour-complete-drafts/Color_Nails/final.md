# The choosing hand

What changes when a colour becomes part of the body you act through?

The lamps changed what reached a surface. Here a hand has outgrown the furniture. A small manicure table stands before it, complete with bottles, stools and another hand small enough to rest between the tools. Which of these bodies are you about to dress?

<!-- @nail_color_controller -->

Find the movable point in the RGB box on its open plinth beside the manicure table. Take it along one axis, then bring it back. A colour you left can be found again at the same place.

Look up at the giant nails, then down at the petite hand on the table. Both answer the same choice. A movement small enough for your hand to make crosses two very different scales. Does the colour feel equally delicate on both?

![The giant hand and the petite hand on the manicure table, seen from inside the museum salon.](/book-review/doc/book/figures/Color_Nails/salon-red.png)

Raise the hand you are choosing with and turn its nails toward you. Compare them with the petite hand, the giant nails and the swatch. The colour has reached the hand you use to choose it. What seemed like dressing an object now includes the body doing the dressing.

The nail material adds its own response to light. A colour selected in the box can look different on a small glossy surface from the way it appears on the flat preview.

The point's three coordinates are constrained to the box and converted into red, green and blue channel values, each between zero and one. Moving along one axis changes one channel. Moving diagonally can change several at once. The box turns a colour choice into a position that your hand can revisit.

This is a three-channel description of colour. It does not divide every difference you can perceive into three equally noticeable kinds. Equal distances in the box need not feel like equal changes in the preview.

<!-- @hand_color_controller -->

At the controller for the hand surface, leave the nails at the colour you chose and move the point for the skin. Look again at the nails against this new background. Their assigned colour has stayed fixed. Do they still look the same?

The two stations use the same position-to-colour mechanism but target different surfaces. The salon hands are two copies of the same source mesh. Their nail materials receive the nail-colour signal; their skin materials receive the hand-colour signal. Each receiving material is assigned the selected value:

```gdscript
material.albedo_color = colour
```

The scale difference lives in the geometry's transform. It does not require a second colour recipe. A nail can become monumental while its material still receives the same three channels as the small one on the cushion.

The two points move with the same ease. Changing polish and changing skin can feel like neighbouring choices. Yet changing a rendered skin colour does not give us another person's lived history, or undo the racism through which skin is read. Polish is read through the body too: a colour may be called elegant, excessive or defiant according to whose hand wears it.

Audre Lorde asks us to recognise difference while confronting the power that turns it into inferiority.[^color-nails-lorde] Look again at the hand you have chosen. Which colours feel available to you? Which seem to require an explanation, and to whom?

The bottles never need opening. No brush crosses these nails, and no polish has to dry. The room keeps the cushion, the stools, the promise of a hand being attended to. The application has become an assignment. What remains of the manicure in the pleasure of choosing?

The colour leaves with you. Your hands carry it into the halls ahead.

<!-- @ -->

Choose a colour because you want it, without requiring a naturalistic match. Try a nail or hand that interrupts the palette you expected from this body. Reach for the point again. The hand making the next choice is already wearing the last one.

You have chosen their colour. The fingers have kept their length. What else might you want to change?

Carry one of those chosen colours toward the rainbow. Where would you put it among the bands? The next room gives colour a familiar order; look for the decisions that hold that order in place.

[^color-nails-lorde]: Audre Lorde, [“Age, Race, Class, and Sex: Women Redefining Difference”](https://www.ualberta.ca/en/institute-intersectionality-studies/media-library/intersectionality-readings/lorde-age-race-class-and-sex.pdf), in *Sister Outsider* (Crossing Press, 1984), pp. 114–123, especially 115–116 and 120–121. Lorde examines the unequal power attached to difference and refuses to let one aspect of a person stand for their whole life. The comparison between this salon's skin and nail controls is the book's application of her argument.
