# Procedural Generation — Critical assessment

Ada Research · 7 halls · Tutorials and reflections · 9 October 2026

Understood: Procedural Generation follows L-systems. This makes the transition particularly important. L-systems established how a description can be generated and interpreted; Procedural Generation asks how rules can select, evaluate, connect, carve and reconstruct the material world.

I've examined the seven-hall review package, including its teaching progression, reflective texts and validation report.

My overall judgment: this is one of the strongest architectural sequences in Ada Research. It develops the student's capacity to move between abstract records and consequential spatial constructions. It also contains one of the clearest tensions in the curriculum: a generated form can look correct, yet fail to provide the connection, support or passage that its appearance seems to promise.

## 1. The seven-hall progression

| Hall                    | Main operation                                   | What the student learns                                         |
| ----------------------- | ------------------------------------------------ | --------------------------------------------------------------- |
| 01. Genetic Evolution   | Evaluate candidate designs using a fitness score | A numerical criterion determines what gets selected             |
| 02. Space Colonization  | Combine directions toward attraction points      | Multiple requests can contribute to one growth direction        |
| 03. Branching Growth    | Select the nearest target                        | Selection differs from averaging competing directions           |
| 04. Percolation Network | Define permitted neighbouring connections        | Proximity is not the same as connectivity                       |
| 05. Caves and Mazes     | Carve volumes around a route                     | A connected path needs clearance to become a passage            |
| 06. Sculpted Forms      | Sample physical positions and generate a mesh    | A representation retains only selected properties of an event   |
| 07. Mirrored Patterns   | Apply symmetry operations to a stored field      | Repetition and symmetry do not necessarily establish connection |

The progression has a strong internal logic: it moves from evaluating forms to growing structures, then to establishing relationships, and finally to reconstructing and comparing representations.

## 2. Genetic Evolution is an excellent opening

The first lesson introduces a significant departure from L-systems.

Previously, a generating rule made a structure. Now a second operation evaluates that structure according to a criterion.

Six candidate bodies are compared, and one is selected through a score. But the score is not an objective statement about which body is better. It measures the properties that the evaluator has been instructed to reward.

The reflection asks:

What does the score notice?

This is an exceptionally productive educational question because students can change the evaluator without necessarily changing the candidate bodies.

It demonstrates that the generating system and the system of judgment are distinct.

The lesson could become even stronger by allowing students to define a new fitness criterion. However, its present focus on reconstructing the evaluator is appropriate given the earlier curriculum.

## 3. Space Colonization and Branching Growth form a strong conceptual pair

These two halls investigate different ways of receiving requests from a spatial field.

In Space Colonization, multiple attraction points contribute directions that are combined into a proposed step.

In Branching Growth, a site selects its nearest unreached target. Other targets remain present but do not contribute to that particular direction.

Two ways to respond to several targets

Schematic of the conceptual difference, not the exact coordinates of the museum artifacts.

This distinction is valuable because it makes selection and aggregation separately inspectable.

It also introduces a conceptual problem that extends beyond procedural trees: when several possibilities are available, does a system combine them, prioritize one, or exclude some altogether?

## 4. Percolation → Caves → Sculpted Forms is the strongest passage

These three lessons form the sequence's most convincing progression.

Percolation establishes connectivity under a chosen neighbourhood rule. Two cubes may touch diagonally but remain disconnected because the program recognizes only six face-adjacent neighbours.

Caves then asks whether a connected route offers sufficient width and height for a body to pass.

Sculpted Forms reverses the relationship: rather than carving space to admit a body, it samples where falling bodies have arrived and constructs a surface from selected information about them.

[Exploring percolation phase transition in the three-dimensional Ising model with machine learning](https://images.openai.com/static-rsc-4/bgJHsf7Mx_11GouHDOzINj1HH9eV7DjFvIzCx1dRtL-1IPw_Hv9aK9_tzlnqAMWRAVab8DJG5oPHbkNFs3r0VrryM5TyNC4Xe9_rHyurYGLAJIiGHJK4vUDWe5TB-MUHIbjQd_npn-VIFIrhqpHv02xicToHUSGcp3RDCbJt0kg?purpose=inline)

Connectivity

Which cells are permitted to communicate?

[Fotobehang - De Mystieke Blokkloof - Fotobehang](https://images.openai.com/static-rsc-4/fa8pHe0OGhttcVrcddCs13ThSEtQLZsLp_R7kF_mIPI5mAStd_sR3dV6unGArzsUhZgUGVBjF2uiDhaZexvon24vDaP17tXpcIGUE4HGLX_QNDf_iU_crRo5y_xK7c_Wq-q9HWTurQhX8vAfZCESfno3stGDt9JVwO8H63KgjtI?purpose=inline)

Clearance

Which connected spaces can admit a body?

[Flexible Isosurface Extraction for Gradient-Based Mesh Optimization (FlexiCubes)](https://images.openai.com/static-rsc-4/PyVUzb7eDDM1Eu72nF_sJ425BdHhaHYcG2FzvmKy-j3ZnAYOGw7wlsCzS_zExd9sg_IkrL907dKxVyrct6eGFo2mmKJlFRg_o_y6bIpflHgJlKj0efNCzIRHynFY132_rr75pZ6TSjmoL1X1DcqjsK7246DvV7Jn4B-QewlTlFI?purpose=inline)

Reconstruction

Which properties survive a spatial sample?

This is particularly appropriate for a VR-based research project. It continuously tests the difference between a mathematical relation and a physical encounter.

The Sculpted Forms reflection is especially strong because the learner chooses when to sample twelve falling cubes. A moment in a physical process becomes a static geometric record. That record does not preserve the cubes' complete motion, orientation or collision history.

The student is learning that a computational representation is also an act of selective forgetting.

## 5. Mirrored Patterns makes a quieter but valuable conclusion

The last hall holds a cellular field fixed and applies different copying rules.

This is a good choice after the complexity of mesh construction.

It returns to a small, inspectable operation: a source array, an explicit transformation and a resulting array.

But it adds a valuable complication. Two patterns can contain the same number of occupied cells and still differ in arrangement, connectivity or accessibility.

This connects directly to the Randomness sequence's lesson about entropy: counts and distributions cannot tell us everything about spatial relationships.

The final hall is therefore a synthesis of concepts encountered across several sequences, not simply a new technique for making decorative patterns.

## 6. My main criticisms

The first is that the sequence risks becoming a catalogue of procedural techniques. Genetic algorithms, space colonization, percolation, carving, voxel surfaces and symmetry operations belong to different computational families.

The connections are meaningful, but the sequence needs to foreground the distinction between a generated result and the operations that select or interpret it. Otherwise a student might remember seven techniques rather than the larger methodological proposition.

The second is a steep increase in implementation complexity. Space Colonization combines eligibility, target assignment, direction averaging and parent records. Sculpted Forms requires coordinate conversion, voxelization, exposed-face detection and mesh construction.

At this stage students can reasonably be expected to understand these operations, but the tutorial should remain clear about which operation they are being asked to reconstruct. The supplied report recognizes this issue and appropriately limits each exercise.

The third is that the reflections occasionally repeat the tutorial's operating instructions. This is most apparent in Genetic Evolution and Space Colonization. I'd retain the reflections' conceptual arguments while allowing the tutorial to carry more of the step-by-step explanation.

The fourth is spatial integration. The report identifies desks obstructing the intended entrance in five halls—Branching Growth, Percolation, Caves, Sculpted Forms and Mirrored Patterns. The Sculpted Forms dome also extends beyond its room. These are important issues in a museum whose primary educational method depends on bodily navigation.

## 7. Technical evidence

The package reports 200 passing checks on the current printed Godot programs, including guided variants and XR interaction simulations. It separately preserves 231 earlier museum checks. These support the implementations within their tested scope, but do not constitute a complete VR walkthrough or independent student assessment.&#x20;



I would prioritize fixing the documented entrance obstructions before treating the spatial sequence as ready for continuous visitor testing.

## 8. How it extends L-systems

This is the most important relationship.

L-systems teaches students that a symbolic description can be generated independently of the reader that converts it into a form.

Procedural Generation investigates what happens when additional operations determine which forms survive, which targets matter, which cells connect, what space is removed, and which properties of a physical event are retained.

That creates a valuable progression:

L-SYSTEMS

### Description → Interpretation → Form

PROCEDURAL GENERATION

### Selection → Construction → Spatial consequence

LARGER RESEARCH QUESTION

### Which worlds become possible under these rules?

## Final judgment

I would keep the seven halls in their current order.

The progression is convincing, particularly from Percolation to Caves to Sculpted Forms. It allows students to revisit earlier knowledge—arrays, grids, transformations, physics and mesh construction—while asking increasingly sophisticated questions about how computational procedures make spatial relationships consequential.

My strongest recommendation is to make the generated artifact's history more available for comparison. Not necessarily through longer explanations, but through preserved intermediate states and opportunities to revisit a previous decision.

Genetic Evolution already keeps a candidate. Mirrored Patterns keeps a source. Sculpted Forms captures a moment. These could become a recurring research practice: preserve something, transform it, compare the consequence and decide what to carry forward.

I also see an important thematic shift across the curriculum:

Fractals introduced the recursive production of form. L-systems separated generating descriptions from interpreting them. Procedural Generation now explores the conditions under which forms become connected, inhabitable, useful, selected or excluded.

The critical achievement is that students are no longer simply learning algorithms for making things. They are learning to investigate the conditions under which a computational construction becomes a world that can be encountered.