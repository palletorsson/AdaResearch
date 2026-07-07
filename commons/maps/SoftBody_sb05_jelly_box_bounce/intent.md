Concept: An 8-corner jelly cube with a 28-spring internal topology is dropped under gravity, lands, and oscillates while the wireframe makes the spring network legible. The map is a gallery study — a single soft-body marker exposes the live simulation.

Sequence role: First jelly-grid study (sb05) opening the jelly cluster within the Soft Bodies sequence (13th spine, integration phase). Follows the cloth cluster (sb01–sb04) and precedes denser jelly grids (sb06–sb08) that progressively raise mass count and reveal stiffness gradients. Establishes the spring-mass cube as the irreducible soft-3D primitive.

Technical angle: 8 vertex masses arranged as cube corners; 12 edge springs (axis-aligned), 12 face-diagonal springs (shear resistance per face), 4 body-diagonal springs (volumetric stability) = 28 springs total. Semi-implicit Euler or Verlet integration with damping. Collision against a rigid floor via penalty forces or position correction. Visible spring rendering exposes the topology that produces the bounce signature.

Critical angle: The 28-spring cube is the minimum sufficient structure for a deformable 3D solid — fewer springs collapse degrees of freedom; more add redundancy without changing qualitative behavior. This is structural minimalism as design constraint: the simplest network that still encodes "cube-ness" under deformation. The wires are the explanatory artifact; the bounce is the consequence.

Key artifacts: gallery_marker_soft-body presents the imported DNA gallery configuration (sb05_jelly_box_bounce) with spring wireframe rendering enabled.

Gap: A stiffness-slider artifact would let learners scrub the spring constant k from very soft to very stiff in real time on this same cube, making the continuous spectrum between rubber-ball and rigid-cube directly perceptible rather than implied across separate jelly variants.
