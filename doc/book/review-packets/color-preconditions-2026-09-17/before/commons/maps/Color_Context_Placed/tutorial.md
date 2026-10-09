# Add colour to the construction

This opening uses primitives and transformation already encountered. Follow the current final.md: the tutorial progression is comparison between fixed objects, with the visitor supplying movement.

1. Recognise the same five-piece column under four colour assignments. Separate geometry from how its pieces receive colour.
2. Keep colour by shape while changing the primitive alphabet. A category in code can group a cone and a wedge without making them identical.
3. Keep the cut alphabet and its colour assignment while changing static pose. Successive levels turn around Y, narrow across X/Z, or combine both. Their heights remain unchanged.
4. Compose richer stacks from the same vocabulary: unequal heights, broad discs, small beads, sideways offsets and chosen colours. These fixed sculptures do not simulate balance.
5. Read art and design DNA as composed choices: proportion, ordering and palette. The gallery configurations are the actual source data.
6. Change the rainbow pedestal shaft to 6.2 m while keeping a broad cap. Inspect how a familiar form changes its relation to your reach.
7. Combine whole configurations into taller stacks: rainbow plus Bauhaus; Memphis plus rainbow plus beads.

Relevant implementation: `commons/artifacts/chroma_stack/chroma_stack.gd` and `commons/artifacts/color_dna_stack/color_dna_stack.gd`. The code sets these transformations during construction and does not animate them. The three coordinates of a material colour are not a complete account of its appearance; later halls investigate that relation through light, surfaces and displays.

The earlier tutorial's hypothetical perceived() function is archived with the previous draft. It is not an implemented model of the viewer's perception and should not be presented as one.
