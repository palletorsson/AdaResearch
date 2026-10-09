# SwarmIntelligence FlowFields — Artifacts
*Swarm Intelligence: No Leader, Yet Coordinated · lambda_edge · 1 artifacts*

> The flow field assigns direction to space. Agents read the field and follow. No pathfinding, no goals — just local obedience to arrows. Thousands of agents streaming through invisible currents. The field is the program; the swarm is the execution.

The map, read through what it holds — its artifacts in the order you meet them:

## FlowFieldMain
![FlowFieldMain](/scene-catalog/FlowFieldMain.png)

v_i(t+1) = field[grid(pos_i)] — each agent reads one arrow and moves; the entire "decision" is a lookup

`FlowFieldMain`
