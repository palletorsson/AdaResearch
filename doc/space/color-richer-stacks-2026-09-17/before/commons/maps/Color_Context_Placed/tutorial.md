# Add colour to the construction

This opening uses primitives and transformation already encountered. Follow the current final.md: the tutorial progression is comparison between fixed objects, with the visitor supplying movement.

1. Recognise the same five-piece column under four colour assignments. Separate geometry from how its pieces receive colour.
2. Keep colour by shape while changing the primitive alphabet. A category in code can group a cone and a wedge without making them identical.
3. Keep the cut alphabet and its colour assignment while changing static pose. Successive levels turn around Y, narrow across X/Z, or combine both. Their heights remain unchanged.
4. Compare four-position translation studies. A kept material colour travels with the copied shape; the displacement rule instead calculates a new hue; the step rule colours copy indices.

Relevant implementation: `commons/artifacts/chroma_stack/chroma_stack.gd` and `commons/artifacts/chroma_translation/chroma_translation.gd`. The code sets these transformations during construction and does not animate them. The three coordinates of a material colour are not a complete account of its appearance; later halls investigate that relation through light, surfaces and displays.

The earlier tutorial's hypothetical perceived() function is archived with the previous draft. It is not an implemented model of the viewer's perception and should not be presented as one.
