# A way back

If you can travel from one vertex to another, can you necessarily return?

<!-- @tarjan_algorithm -->

Choose two vertices joined by a directed path. Trace the arrow directions from the first to the second, then search for a return route. Keep your proposed group in mind while the traversal assigns colours to completed components.

A strongly connected component is a maximal group in which every vertex can reach every other by directed paths. A one-way bridge can connect two groups visually while leaving them separate in this sense. Proximity, shared colour before the search, or a line with the wrong direction cannot substitute for a return path.

Test your proposed component from more than one starting point. A return route for one pair is necessary but does not settle whether every member of a larger group can reach every other. You can make the check manageable by looking for the paths that join a candidate member to the already considered group in both directions. An incoming connection alone may make the drawing feel joined while still leaving the traveller unable to return.

The exhibit runs a depth-first traversal. Each newly visited vertex receives a discovery number and remains on a stack while its group is unresolved. Another value records how far back the current exploration can connect through the relevant routes. This is the low-link information used to recognise when a component can be completed.

Watch the moment several vertices receive one component colour. They are being discharged together from the unresolved stack. The procedure has found a boundary in reachability, not simply collected the next fixed number of vertices. The stack you met with the two travellers now carries information about a question that remains open during the walk.

Try finding an edge between two completed colours. Follow its direction and ask what would need to be added to make the components mutually reachable. One additional return connection can change the component structure much more than its modest length in the drawing suggests.

Strong connectivity is still a limited promise. It establishes the existence of directed routes, not that those routes have equal cost, sufficient capacity or equal accessibility. A long and fragile return journey counts as a return journey under this definition.

<!-- @ -->

Spanning trees will ask how many connections can be removed while everyone remains connected. The useful return route you just found may look like an expendable cycle under a different objective.
