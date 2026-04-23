# Machine Learning — Curriculum Audit

**Sequence ID:** `machinelearning`
**Spine order:** 15 (integration phase)
**Truth:** "Learning is optimization in a landscape you can't fully see."
**QFEP term:** Integration — ML systems navigate F↔E by descending loss landscapes. Gradient descent IS the oscillation between order (model) and entropy (data). Overfitting is F-collapse; underfitting is E-dominance.
**Maps:** 9 (8 teaching + 1 chamber)
**Prerequisites:** forces, randomness
**Unlocks:** foundationscrisis
**Evolutions written:** 0 (intent.md exists for all 8 teaching maps)

## 1. Core Concept

Machine learning is **optimization under uncertainty** — the practice of finding structure in data by navigating high-dimensional loss landscapes no agent can see in full. The sequence stages this as a progression from biology to calculus to composition to self-critique: first blind variation-and-selection (evolution), then directed descent (gradients), then boundary-drawing (classification), then layered feature extraction (nets), then specialized perception (CNNs), then memory over time (LSTMs/transformers), then learned generation (GANs/VAEs), and finally agents that act and models that can be questioned. The spine argument is that all of these are the same move in different costumes — every ML algorithm is a navigator of an incomprehensible landscape, and every choice of loss function smuggles in values.

## 2. The Red Thread

1. **Gradient-Free Search** (ML_Evolution)
   - Variation + selection walks a fitness landscape without calculus
   - Captures: population-based exploration, emergence without design, distributed "knowing"
   - Leaks: slow, wasteful, no credit assignment — why forces aren't pointed, just weighted

2. **Directed Descent** (ML_Gradient_Landscape)
   - Follow the local slope downhill; calculus replaces luck
   - Captures: the loss surface as terrain, local minima, learning rate as step size, PCA as dimension-reduction for visibility
   - Leaks: you need differentiability; you get stuck; you never see the whole landscape

3. **Boundary Drawing** (ML_Classification)
   - Three strategies for the same question "which side?": centroids (K-means), margins (SVM), forests of questions (random forest)
   - Captures: decision boundary, unsupervised vs supervised, ensembles
   - Leaks: a line is not a reason — classification collapses features into a label without explaining

4. **Layered Composition** (ML_Neural_Networks)
   - Stacking simple non-linear units yields arbitrary function approximation
   - Captures: universal approximation, depth as hierarchy, backprop as chain rule writ large
   - Leaks: why does depth help? what exactly is each layer learning?

5. **Specialized Perception** (ML_Perception)
   - CNNs + attention: convolution as learned pattern-matching, receptive fields as structured priors
   - Captures: translation invariance, feature hierarchies (edge→texture→object), attention weighting
   - Leaks: adversarial examples; perception isn't understanding; CV is culturally loaded

6. **Memory & Time** (ML_Sequence_Memory)
   - Gates (LSTM) and attention (transformer) let models carry state across sequences
   - Captures: long-range dependency, selective remembering, self-attention as content-addressable memory
   - Leaks: quadratic attention cost; "context" as a political frame; what about causality?

7. **Learned Generation** (ML_Generative)
   - GANs (adversarial) and VAEs (latent) learn distributions well enough to sample from
   - Captures: density estimation, latent space, mode collapse, reconstruction vs. realism
   - Leaks: whose distribution? synthetic media ethics; the training corpus becomes destiny

8. **Self-Questioning Agency** (ML_Synthesis)
   - RL agents that act, XAI methods that ask "why," anomaly detection that flags the unexpected
   - Captures: reward hacking, explanation as an additional model, the bias-variance tension as a universal ML law
   - Leaks: explanations disagree with each other; no single "true" account — opens onto foundations crisis

9. **Chamber: The Hunter Learns You** (Chamber_ML)
   - Proximity spawner + gradient_hunter creature that adapts to the player's movement pattern
   - Captures: ML as embodied adversary; learning in the second person
   - Leaks: into foundationscrisis (what cannot be learned), into QFEP (free energy minimization in a body)

## 3. Map-to-Concept Mapping

| Order | Map | Concept | Anchor Artifacts | Status |
|-------|-----|---------|------------------|--------|
| 1 | ML_Evolution | Gradient-Free Search | evolved_creatures, evolvingflowers, 9_3_smart_rockets_vr, 9_5_evolving_bloops_vr, non_teleological_evolution, gradient_descent_visualization | Map + intent; no evolution |
| 2 | ML_Gradient_Landscape | Directed Descent | gradient_descent_visualization, pca_visualization, loss_function_comparator | Map + intent; no evolution |
| 3 | ML_Classification | Boundary Drawing | enhanced_kmeans, svm_visualization, random_forest_visualization | Map + intent; no evolution |
| 4 | ML_Neural_Networks | Layered Composition | neural_networks_vr, neural_network_visualization, learn_world_stacked | Map + intent; no evolution |
| 5 | ML_Perception | Specialized Perception | computer_vision_vr, convolutional_neural_networks_cnns_vr | Map + intent; no evolution |
| 6 | ML_Sequence_Memory | Memory & Time | lstms_vr, transformers_vr | Map + intent; no evolution |
| 7 | ML_Generative | Learned Generation | generative_adversarial_networks_gans_vr | Map + intent; no evolution |
| 8 | ML_Synthesis | Self-Questioning Agency | joint_learn_walk, explainable_ai_xai_vr, anomaly_detection | Map + intent; no evolution |
| 9 | Chamber_ML | Integration / Adversary | catalyst_target (x4), proximity_spawner#gradient_hunter, science_screen | Minimal map, no intent/blurb, no evolution |

All 8 teaching maps use amphitheater / terrain / pipeline / gallery / corridor / arena metaphors deliberately keyed to the concept. Spatial choices read clearly (gradient landscape literally has height-varied terrain; sequence_memory is a long corridor; generative is mirrored halves). Ordering matches the concept flow cleanly.

## 4. Artifact Inventory

### Strong (built, @identity present, placed)

| Concept | Artifact | File | Notes |
|---------|----------|------|-------|
| Evolution | evolved_creatures | algorithms/machinelearning/evolutionaryalgorithms2/scripts/evolved_creatures.gd | has @identity |
| Evolution | evolvingflowers | algorithms/machinelearning/evolvingflowers/evolvingflowers.gd | has @identity, L-system + fitness |
| Evolution | 9_3_smart_rockets_vr | algorithms/machinelearning/noc_ch09/9_3_smart_rockets_vr.gd | has @identity |
| Evolution | 9_5_evolving_bloops_vr | algorithms/machinelearning/noc_ch09/9_5_evolving_bloops_vr.gd | has @identity |
| Evolution | non_teleological_evolution | algorithms/machinelearning/non_teleological_evolution/non_teleological_evolution.gd | has @identity |
| Gradient | pca_visualization | algorithms/machinelearning/pca/pca_visualization.gd | has @identity |
| Gradient | loss_function_comparator | algorithms/machinelearning/loss_function_comparator/loss_function_comparator.gd | has @identity |
| Classification | enhanced_kmeans | algorithms/machinelearning/kmeansclustering/enhanced_kmeans.gd | has @identity; missing VR sliders |
| Classification | svm_visualization | algorithms/machinelearning/supportvectormachine/svm_visualization.gd | has @identity |
| Classification | random_forest_visualization | algorithms/machinelearning/randomforest/random_forest_visualization.gd | has @identity |
| Neural Net | neural_networks_vr | algorithms/machinelearning/neural_networks/NeuralNetworks_VR.gd | has @identity |
| Neural Net | neural_network_visualization | algorithms/machinelearning/neuralnetworkvisualization/neural_network_visualization.gd | has @identity |
| Neural Net | learn_world_stacked | algorithms/machinelearning/stacked/LearnWorldStacked.gd | has @identity |
| Perception | computer_vision_vr | algorithms/machinelearning/computer_vision/ComputerVision_VR.gd | has @identity |
| Perception | convolutional_neural_networks_cnns_vr | algorithms/machinelearning/convolutional_neural_networks_CNNs/ConvolutionalNeuralNetworksCNNs_VR.gd | has @identity |
| Memory | lstms_vr | algorithms/machinelearning/LSTMs/LSTMs_VR.gd | has @identity |
| Memory | transformers_vr | algorithms/machinelearning/transformers/Transformers_VR.gd | has @identity |
| Generative | generative_adversarial_networks_gans_vr | algorithms/machinelearning/generative_adversarial_networks_GANs/GenerativeAdversarialNetworksGANs_VR.gd | has @identity |
| Synthesis | joint_learn_walk | algorithms/machinelearning/reinforcementlearning/joint_learn_walk.gd | has @identity; Q-learning locomotion |
| Synthesis | explainable_ai_xai_vr | algorithms/machinelearning/explainable_AI_XAI/ExplainableAIXAI_VR.gd | strong @identity — SHAP/LIME/Grad-CAM, fully VR-equipped |
| Synthesis | anomaly_detection | algorithms/machinelearning/anomaly_detection/AnomalyDetection.gd | has @identity |

### Present but weaker / orphaned

| Artifact | File | Note |
|----------|------|------|
| adaboost | algorithms/machinelearning/adaboost/adaboost.gd | has @identity but not placed — natural fit in ML_Classification (boosting) |
| random_forest (non-viz) | algorithms/machinelearning/random_forest/random_forest.gd | duplicates `randomforest/` folder — naming drift |
| ga_ca_shape_learner | algorithms/machinelearning/ga_ca_shape_learner/ | listed as source for ML_Evolution but not placed |
| shape_learner_3d | algorithms/machinelearning/shape_learner_3d/ShapeLearner3D.gd | orphaned — could anchor a "learning to model" side map |
| geneticalgorithm | algorithms/machinelearning/geneticalgorithm/ | Shakespeare-style GA, not placed — would deepen ML_Evolution |
| feature_engineering | algorithms/machinelearning/feature_engineering/ | orphaned; implicit in Classification but unplaced |
| dimensionality_reduction | algorithms/machinelearning/dimensionality_reduction/ | duplicates pca coverage, unplaced |
| optimization_algorithms | algorithms/machinelearning/optimization_algorithms/ | natural second artifact for Gradient_Landscape (SGD vs Adam vs RMSProp) |
| recommendation_systems | algorithms/machinelearning/recommendation_systems/ | no map placement — social-ML angle unused |
| natural_language_processing_NLP | algorithms/machinelearning/natural_language_processing_NLP/ | present but sequence has no language map |
| variational_autoencoders_VAEs | algorithms/machinelearning/variational_autoencoders_VAEs/ | sequence rationale names VAEs but ML_Generative only places the GAN |
| time_series_analysis | algorithms/machinelearning/time_series_analysis/ | source for Sequence_Memory but unplaced |
| reinforcement_learning / reinforcementlearning | two folders | duplication — the `joint_learn_walk` lives in one, generic RL in the other |
| ensemble_methods, fine_tuning, switchboard_attention, spotlight_attention | various | orphaned — attention variants could reinforce ML_Perception & ML_Sequence_Memory |
| thegame_a (test iterations) | algorithms/machinelearning/thegame_a/_iterations/ | prototype scaffolding; not curriculum content |

### Missing

- **VAE artifact** placed in ML_Generative — the map's title "Adversarial Creation from Noise" names the GAN half only; VAE side is promised by sequence rationale but the map holds only one interactable.
- **Explicit backpropagation artifact** in ML_Neural_Networks — the three placed artifacts show architecture but not the learning step.
- **Bias audit / dataset-composition artifact** in ML_Synthesis — called out as a gap in the intent.md for ML_Synthesis.
- **Fitness-landscape visualizer** for ML_Evolution — called out as a gap in the intent.md (watching population diversity collapse over generations).
- **Overfitting / bias-variance demonstrator** — the intent.md for ML_Synthesis names the bias-variance tradeoff as the fundamental ML law; no artifact dramatizes it.
- **Chamber_ML content** — the chamber has a single gradient_hunter creature and four catalyst_targets; it has no intent.md, no blurb.md, no library rack, no science summary beyond a scatter screen. Compared to the primitives chamber structure, this is a stub.

## 5. Gap Analysis

### Missing evolutions (highest leverage)
Every teaching map has an `intent.md` but no `evolution.md` — this sequence is in the integration phase and should be among the most pedagogically polished, but its narrative arc is only half-written. Priority: ML_Evolution (opener), ML_Synthesis (closer), Chamber_ML (closure ritual).

### Artifact placement gaps
- **ML_Evolution**: houses `gradient_descent_visualization`, which belongs next door in ML_Gradient_Landscape (and is also placed there). This double-placement muddies the "evolution before calculus" narrative. Recommend removing from ML_Evolution and swapping in `ga_ca_shape_learner` or `geneticalgorithm` (Shakespeare GA) to keep evolution pure.
- **ML_Generative**: single artifact despite two being named in the concept. Place a VAE artifact beside the GAN to make the "adversarial vs. latent" contrast readable.
- **ML_Classification**: consider adding `adaboost` as a fourth boundary strategy (boosting) — the map currently shows three classifiers, a fourth would break the "three ways" tagline but round out the boundary-drawing vocabulary. Alternately leave as-is and move adaboost to a deferred extension map.
- **ML_Neural_Networks**: has three architectural viewers but no training-dynamics artifact. A backprop or loss-curve artifact would complete the layer story.

### Redundancies / naming drift
- Two parallel folders: `random_forest/` and `randomforest/`; `reinforcement_learning/` and `reinforcementlearning/`. One should be canonical; the duplicates either merged or renamed. This is technical debt in the algorithms tree.
- `ComputerVision_backup.gd`, `ExplainableAIXAI_backup.gd`, `NeuralNetworks_backup.gd`, `Transformers_backup.gd`, `LSTMs_backup.gd`, `VariationalAutoencodersVAEs_backup.gd`, `GenerativeAdversarialNetworksGANs_backup.gd` — seven `_backup.gd` files in the tree. Likely from a VR-refactor sweep. Should be deleted once the VR versions are validated.
- `thegame_a/_iterations/` contains nine test_iteration files — prototype scaffolding left in the algorithms tree.

### Chamber_ML is under-built
Compared to Chamber_Primitives (which has `becoming_catalyst` + thematic closure), Chamber_ML has one hunter creature and four catalyst_targets on an empty 11×7 floor. The concept ("the hunter learns your patterns") is strong — gradient descent re-read as predation — but there is no:
- intent.md / blurb.md
- library rack summarizing the eight ML concepts
- catalyst pickup
- science screen beyond a scatter mode
- connection back to the specific artifacts walked through the sequence

### Deferred maps (intentional)
The sequence JSON lists 10 `deferred_maps` (Transformers, GANs, VAEs, Clustering, Dimensionality_Reduction, Transfer_Learning, Fine_tuning, Recommendation_Systems, Classification_Algorithms, Attention_Mechanisms). These are the "zoom-in" maps. The current 9-map spine treats them as condensed themes; deferring is the right call for integration-phase pacing. Flag only: Transfer_Learning + Fine_tuning concepts are genuinely missing from the spine and could live in ML_Synthesis or a lightweight extension.

## 6. Forward Leaks

Concepts this sequence raises but cannot answer:
- **What cannot be learned** → Foundations Crisis (next sequence) — Gödel, halting, no-free-lunch
- **Whose data, whose loss function** → Critical Algorithms (ethics, surveillance, bias propagation)
- **Explanations disagreeing with each other** → Foundations Crisis (indeterminacy) and Critical Algorithms (accountability)
- **Reward hacking and Goodhart's law** → Critical Algorithms, QFEP (mis-specified fitness)
- **Generative models' cultural consequences** → Critical Algorithms (deepfakes, authorship, training-data ethics)
- **Learning in the second person (hunter learning you)** → QFEP (active inference, embodied optimization)
- **Scaling, compute, and power** → Critical Algorithms (political economy of ML)
- **Meaning vs. pattern** → Foundations Crisis, language & symbolic systems
- **Consciousness / understanding** → held open, not promised — the sequence deliberately does not answer

## 7. Proposed Ordering

The current ordering is correct and clean. Proposed keep-as-is:

```
1. ML_Evolution          — gradient-free search (biology before calculus)
2. ML_Gradient_Landscape — directed descent on a felt terrain
3. ML_Classification     — boundary drawing, three strategies
4. ML_Neural_Networks    — layered composition
5. ML_Perception         — specialized seeing (CNN + attention)
6. ML_Sequence_Memory    — gating and attending over time
7. ML_Generative         — learned distributions, sampling
8. ML_Synthesis          — agents + explanation + anomaly (self-questioning)
9. Chamber_ML            — hunter-learns-you closure
```

One structural note: the sequence is unusual in that it hands Evolution the task of introducing "optimization without gradient" but then also places `gradient_descent_visualization` inside ML_Evolution. Either remove that artifact from ML_Evolution (recommended, since Gradient_Landscape already places it) or rename the opening map's title, which currently claims "Selection Without Design" but sits atop a gradient artifact.

## Summary

Machine Learning is a structurally sound, well-ordered integration-phase sequence with strong spatial metaphors and a clear pedagogical arc from blind search to self-questioning agency. Every teaching map has an intent.md, nearly every placed artifact has an @identity block, and the 9-map shape reads as a coherent argument about optimization under uncertainty. The main gaps are:

1. **No evolutions written** — intent exists, narrative does not
2. **VAE missing from ML_Generative**, **backprop missing from Neural_Networks**, **bias-audit missing from Synthesis** — three named-but-absent artifacts
3. **Chamber_ML is a stub** — strong concept (gradient_hunter predation), minimal realization
4. **gradient_descent_visualization double-placed** in Evolution and Gradient_Landscape, muddling the "before-calculus" framing
5. **Algorithm-tree debt** — `_backup.gd` files, duplicate folders (random_forest/randomforest, reinforcement_learning/reinforcementlearning), orphaned prototypes (thegame_a)

This sequence is ready to be finished rather than redesigned. The skeleton is right; what it needs is flesh (evolutions), one narrative cleanup (gradient-in-evolution), three named artifact builds, and a chamber promoted from stub to ritual.
