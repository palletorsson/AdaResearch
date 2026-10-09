What changes when a colour becomes part of the body you act through?

The lamps changed what reached a surface. Here a hand has outgrown the furniture. A small manicure table stands before it, complete with bottles, stools and another hand small enough to rest between the tools. Which of these bodies are you about to dress?

<!-- @nail_color_controller -->

Find the movable point in the RGB box on its own plinth beside the manicure table. The space above and in front of the plinth is open for your hand. Take hold of the point and move mainly along one axis. Watch the preview swatch before moving along another. Predict which part of the colour will change on the next movement, then test that prediction with a short return journey.

Look up at the giant nails, then down at the petite hand on the table. Both answer the same choice. A movement small enough for your hand to make crosses two very different scales. Does the colour feel equally delicate on both? Return to a colour you have already tried and compare again.

In VR, raise the hand moving with your controller and turn its nails toward you. Compare them with the petite hand, the giant nails and the swatch. The colour has reached the hand you use to choose it. What seemed like dressing an object now includes the body doing the dressing.

The nail material adds its own response to light. A colour selected in the box can look different on a small glossy surface from the way it appears on the flat preview.

The point's three coordinates are constrained to the box and converted into red, green and blue channel values, each between zero and one. Moving along one axis changes one channel. Moving diagonally can change several at once. The box turns a colour choice into a position that your hand can revisit.

This is a three-channel description of colour. It does not divide every difference you can perceive into three equally noticeable kinds. Equal distances in the box need not feel like equal changes in the preview.

<!-- @hand_color_controller -->

Repeat the comparison at the controller for the hand surface. Change the skin while keeping the nails at the colour you chose. Keep the coordinate gesture simple enough to recognise. Which difference seems to belong to your chosen channels, and which to the surface receiving them?

The two stations use the same position-to-colour mechanism but target different surfaces. The salon hands are two copies of the same source mesh. Their nail materials receive the nail-colour signal; their skin materials receive the hand-colour signal. Each receiving material is assigned the selected value:

```gdscript
material.albedo_color = colour
```

The scale difference lives in the geometry's transform. It does not require a second colour recipe. A nail can become monumental while its material still receives the same three channels as the small one on the cushion.

On desktop, the giant and petite hands carry this comparison. In VR, your hands carry the chosen colours beyond the salon.

<!-- @ -->

Choose a colour because you want it, without requiring a naturalistic match. Try a nail or hand that interrupts the palette you expected from this body. What does that choice make possible for your sense of the figure you act through?

The editable channels are a material choice, not a complete description of identity. A system can make a surface adjustable while leaving many other bodily possibilities fixed. Name one choice the box gives you and another it does not.

Carry one of those chosen colours toward the rainbow. Where would you put it among the bands? The next room gives colour a familiar order; look for the decisions that hold that order in place.
