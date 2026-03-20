# Algorithmic Bias Visualization - Critical Reflection

## Spivak and the Subaltern Data Point

Gayatri Chakravorty Spivak asks: can the subaltern speak? The question is not whether marginalized people have voices but whether the structures of knowledge production are built to hear them. The bias_visualizer answers this question computationally. The word embedding space — trained on corpora written predominantly by the overrepresented — encodes proximity as co-occurrence frequency. Terms that appear together become geometrically close. Terms that the corpus ignores remain distant or absent entirely. The subaltern data point is the vector that was never trained, the embedding that does not exist, the concept with no geometric position because the training corpus never mentioned it.

The divided room literalizes Spivak's analysis. The left half — spacious, six columns wide — is the representational space of the overrepresented. The right half — cramped, two columns — is the space allocated to those the system acknowledges but confines. But Spivak's subaltern is not in the cramped half. The subaltern is in the void at grid position (6,7) — the floor removed, height zero, the structural gap where the classification system has no category at all. The cramped side is misrepresentation. The void is non-representation. Both are products of the same system.

Spivak's concept of strategic essentialism offers a provisional response: the marginalized may strategically deploy the categories that confine them in order to gain political leverage, while knowing those categories are inadequate. The bias visualizer allows the learner to switch analogy pairs — gender-profession, race-lending — revealing that the same embedding space encodes multiple axes of bias simultaneously. The categories are not fixed. They are strategic deployments of a geometric structure that could be reorganized. The question is not whether the embedding space is biased (it is, necessarily) but who controls the reorganization.

## Wynter and the Overrepresentation of Man

Sylvia Wynter argues that Western humanism constructed "Man" — specifically propertied European Man — as the universal template for the human, and that all other modes of being human are measured as deviations from this template. The word embedding space performs Wynter's overrepresentation with mathematical precision. The vectors cluster around a center defined by the most frequent terms in the training corpus. Terms associated with the dominant demographic occupy the dense center. Terms associated with others occupy the sparse periphery.

The man-doctor vector is short because both terms are well-represented and frequently co-occurring. The woman-doctor vector is longer — not because the concept is less valid but because the training data reflects a world where the association is less frequent. The embedding space is a map of Wynter's overrepresentation: the center is "Man," the periphery is everything else, and the distances encode the degree of deviation from the universal template.

The height-5 wall is the material form of this overrepresentation. It does not argue for inequality. It instantiates it. The wall has no justification within the room's formal logic — both halves have height-1 floors, both are structurally identical except for the wall's imposition. Wynter would call this the invention of "race" or "gender" as classificatory apparatus: a structure imposed from above (height 5 towering over height 1) that creates the categories it then naturalizes.

The spacious left half is not naturally spacious. It is spacious because the wall was placed where it was placed. Move the wall to column 3 and the proportions reverse. The wall's position is a design choice presented as architecture — the same operation Wynter identifies in the colonial construction of "Man" as default human.

## hooks and the Spatial Pedagogy of Oppression

bell hooks writes that education is either a practice of freedom or a practice of domination — there is no neutral pedagogy. The map's spatial layout is a pedagogical argument about who gets to learn comfortably. The bias_visualizer sits at (2,4) in the spacious half. The learner spawns at (0,0) in the spacious half. The primary interactive experience — rotating the embedding cloud, examining analogy pairs, understanding bias — takes place in comfort. The cramped side offers no artifact, no interactive element, no reason to visit except curiosity.

hooks would ask: what does it mean to learn about bias from the comfortable side? The map enacts the very dynamic it critiques. The learner stands in the spacious half and observes that the other half is cramped. The observation is safe. The discomfort is conceptual, not bodily. hooks's engaged pedagogy demands that the learner's body participate in the knowledge — not as spectator but as situated agent. The map attempts this through architecture (walk through the gap to the cramped side and feel the contraction) but does not require it.

The void at (6,7) — the exit point — is where hooks's pedagogy activates. To leave the map, the learner must step into the gap. Must stand where the classification system has no floor. The passage from one map to the next goes through structural absence. hooks: liberation is not found within the master's house. It is found in the spaces the house cannot contain.

The announcement board at (1,0) tells the learner what they are about to see. hooks would note that advance framing is a pedagogical strategy with costs: it prepares the learner for discomfort, which also domesticates the discomfort. The map does not ambush. It announces. Whether that announcement is ethical preparation or premature inoculation depends on who the learner is and what they bring to the room.

Can an algorithm visualize its own bias without reproducing it? Can a map critique spatial inequality without distributing its artifacts unequally?
