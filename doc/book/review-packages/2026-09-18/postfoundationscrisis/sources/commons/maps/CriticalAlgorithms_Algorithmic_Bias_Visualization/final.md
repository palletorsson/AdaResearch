# Less room for a distinction

Which differences become difficult to recognise when a representation gives some words less room?

<!-- @bias_from_inside -->

Choose two warm-coloured labels and keep both in view while moving PERSPECTIVE. Compare their changing separation with two grey labels. Stop partway through the movement and notice which words are still easy to distinguish individually.

The warm group compresses into a smaller region while the grey group spreads and moves away. The words themselves remain, but the space available to tell them apart changes. Presence in a representation is therefore different from being represented with useful distinctions.

The source makes the operation inspectable:

```gdscript
var pos := _marginalized_positions_default[i].lerp(
    _marginalized_positions_compressed[i], blend
)
var xf := Transform3D.IDENTITY
xf.origin = pos
_marginalized_multimesh.multimesh.set_instance_transform(i, xf)
```

The index i keeps a word attached to its two authored positions. lerp blends those positions; blend chooses how far the word has travelled. The same operation learned in transformation can make a distinction easier or harder to see. The script calls this perspective, but it changes the represented geometry. It is not a camera command.

An embedding places items in a numerical space so that relations between positions can be used in later calculations. This exhibit stages an authored analogy for that operation. Its positions interpolate between two designed arrangements; they are not measured coordinates from a trained language model. The slider changes the geometry rather than retraining a model or changing only your camera.

That limitation helps keep the question exact. The piece can show what spatial compression does to your ability to separate its labels. It cannot, by itself, establish the distances those same words occupy in an actual system. An empirical claim would need a named model, a documented measurement and a comparison that someone else could check.

Now scrutinise the groups chosen for the sculpture. Words such as “queer”, “disabled” and “refugee” do not name interchangeable experiences. Nor are “normal”, “professional” and “objective” equivalent claims. The exhibit risks repeating a flattening if its two colours become a sufficient account of everyone they contain.

Choose one distinction within a colour that you want the representation to retain. For a future version, compare several groupings and ask the people represented which distinctions matter to them. Greater distance alone will not guarantee a better account, but it can make an otherwise hidden question available.

<!-- @ -->

The applied-ethics room moves from word positions to furniture. A plan can distribute the ability to participate before anyone begins speaking.
