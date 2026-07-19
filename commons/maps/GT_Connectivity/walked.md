# GT_Connectivity — walked

> ghost-drafted from the working map (second walk slot, graphtheory thread); Palle rules the voice.

## The cast

tarjan_algorithm · kosaraju_algorithm · topological_sort

## The walk

Direction enters, and with it the question of who can reach whom. The tarjan_algorithm and kosaraju_algorithm hunt the same prey by different routes — strongly connected components, the clusters where every member can reach every other — one in a single elegant descent, one by running the graph forward and then backward. Across the room the topological_sort works the opposite territory: the acyclic remainder, where arrows forbid return and some order becomes mandatory. It extracts the hidden queue inside any dependency web and shows that a graph without loops is secretly a to-do list.

## What it fixes

Connectivity is the chapter's first political fact: in a directed world, "connected" splits into castes. Inside a strong component, movement is mutual — anywhere can reach anywhere. Between components, the arrows only point one way, and the condensation of a graph into its components is always a DAG: cycles inside, hierarchy between. The room teaches you to see any directed system — citations, supply chains, who-follows-whom — as exactly this: pockets of mutuality strung along a one-way street.
