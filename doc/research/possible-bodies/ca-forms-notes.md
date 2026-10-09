# Walk inside a history — form study, 14 September 2026

User request: walk inside stacked cellular generations, combine sine and cellular automata, and compare form-making strategies.

Implemented standalone scene: res://commons/artifacts/ca_history_vault/workshop.tscn. Registered reusable artifact: ca_history_vault. Museum map/plan/primary/book sources remain guarded and unchanged. This is an experiment, not a new main-sequence hall.

25 × 15 binary cross-section, 28 generations, 0.4 m XY cells, 0.5 m slabs in Z. Eight-neighbour Moore update, synchronous previous state, empty outer boundary, survival >=4, birth >=5. The seed already contains an imperfect arch, and y=0 is held solid. The ordinary section stabilizes at generation 3. This is 2D CA plus recorded time, not 3D neighbourhood evolution. The workshop supplies a stable floor as well.

Strategies: straight history; x += 1.4 sin(2πz/14+phase); scale x by 1+.5sin and y by 1+.25sin; or change birth threshold to 4+floor(2sin(2πg/12+phase)+.5). These controls are separate alternatives. The geometry is held still during traversal. A declared optional corridor forces abs(x-12)<=2, y=1..6 empty after every update; its gold marks disclose intervention. This reserves a 2 m-wide, 2.4 m-high strip before geometric scaling.

At phase zero, straight/bend/breath each contain 3,965 occupied cells and preserve all binary states. Actual desktop traversal passed all three. The sine-rule history contains 8,289 occupied cells; the tested centre walk stops near z=3.20 m. Reserving the corridor yields 7,710 occupied cells and a complete traversal while suppressing 160 birth or survival decisions. The 579-cell difference includes propagation of those interventions.

35 rendered Godot checks: independent Python cell oracle; history preservation and change; phase changes state; neighbour locality; surface/collision triangle agreement; floor normals; five real physical walks; all eight actual pointer controls; eight-layer end face; occupied-room rebuild guard. All pass; no runtime script errors. A pre-existing missing-UID startup diagnostic remains unrelated. Walk tests use the actual 1.8 m-tall, 0.6 m-wide desktop capsule. Parameter tests do not establish all seeds, phases or amplitudes. Headset review is deferred.

Interpretation: a continuous geometric bend need not alter connectivity. It does change visibility and routes in physical coordinates. Scale can change which fixed-size body fits even while connectivity stays intact. Rule changes can fill an opening. Reserving a route is an explicit architectural decision, not spontaneous hospitality of the automaton.

Next useful comparison: multiple seeds without a preformed arch, fixed rule/volume budget, visible connected voids, and measured body access. Then compare a true 3D neighbourhood to the 2D history. Do not treat this initial arch test as proof of open-ended morphogenesis.
