Concept: A cloth pinned along its left edge under gravity plus a constant sideways wind settles into a drooping, slightly asymmetric wave shape. The map is a gallery study exposing the live simulation as a single soft-body marker centerpiece.

Sequence role: Third cloth-drape study (sb03) in the imported soft-body gallery cluster within the Soft Bodies sequence (13th spine, integration phase). Sits between sb02 (top-row pinned, no wind) and sb04 (flat tablecloth). Introduces a directional force field beyond gravity to the cluster, demonstrating that a boundary-rotation plus an added force selects a fundamentally different drape signature.

Technical angle: Spring-mass cloth with structural and shear constraints. Left column of vertices pinned. Per-face wind force computed as a constant world-space velocity dotted with each triangle's normal, scaled by face area — so faces presenting broadside to the wind take the strongest push. Gravity unchanged. Integration is the usual Verlet or position-based step with damping. The wave at rest is the steady balance between sideways aerodynamic force pulling each free vertex out and gravity pulling it down, mediated by the spring network whose pinned column anchors one side.

Critical angle: Sb01 and sb02 show that two pin patterns under gravity-only produce two shapes. Sb03 shows that adding a directional load to a third pin pattern produces yet another distinct family. The cluster is a small combinatorial study: pin-set × external-force = shape signature. The cloth is doing what a thin sail or a stretched skin does in the real world. The simulation makes the mapping legible.

Key artifacts: gallery_marker_soft-body presents the sb03_cloth_flag_sideways configuration. The drooping wave shape and the live wind force together compose the room's pedagogy.

Gap: A wind-vector arrow artifact (a directional gizmo above the cloth showing wind direction and magnitude) would let learners read the force field before they read its consequence in the drape, making cause-and-effect inspectable as separate layers.
