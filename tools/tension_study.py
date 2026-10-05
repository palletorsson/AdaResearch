"""Nengudi-related application after the Cloth hall's pin comparison."""
REVIEW = '2026-10-02-nengudi-a-little-give'
SPECS = [('tension_membrane','tension','SoftBodies_Cloth_Physics','softbodies',23,21,0,
          'A little give','Senga Nengudi',['soft','constraint','force'],
          'Change the added load while preserving the four anchors and material compliance.',REVIEW)]
READINGS = {'tension_membrane': '''Four slender posts hold a dark, narrow-waisted surface. Between them it has sunk towards the floor. The pink bead at its edge waits within reach. Pull it towards you. A crease travels back towards an attachment that does not move.

Let go. The bead moves without your hand, passes through a lower position, and comes back more quietly. Stay for the small movements after the large one.

Add a load. A dark weight gathers beneath the middle. Pull again and release. The same four points are held, but the surface now has something more to carry. It settles lower. Removing the load allows another return.

Nengudi's stretched hosiery brings a used material, close to skin, into this question of how far something can give. Our surface has no wearer and no remembered damage. Each return is calculated from lengths that the code has kept intact. To recover here is to approach an arrangement the program still remembers.

The anchors have asked nothing of themselves. We have asked the middle to accommodate another weight.'''}
ANCHORS = {'SoftBodies_Cloth_Physics':'Carry the fixed edge into the next hall.'}
EDITS = {'tension_membrane':('commons/artifacts/spine_studies/tension_score.gd',
                           'const LOAD_KG := [0.0, 1.0, 2.0]',
                           'In tension_score.gd, change the last entry of LOAD_KG from 3.0 to 2.0. Predict and compare the settled centre height after the same pull and release. Keep the pins and compliance fixed. The constraint solver and mesh renderer are supplied; no new foundational capability is required.')}
REFERENCE = ('Senga Nengudi: Internal I (1977, refabricated 2014)',
             'https://whitney.org/collection/works/46609',
             'Whitney identifies nylon hosiery and places the work in the RSVP series. Nengudi discusses bodily and psychological elasticity and the energy associated with previously worn material. Ada makes an original four-anchor membrane encounter, not a reconstruction or a measurement of her sculpture. Its knit-like opaque surface is procedural. It models reversible distance constraints, damping and a distributed downward load, with a floor limit; it does not simulate nylon, damage, self-collision, skin or a human body.')
