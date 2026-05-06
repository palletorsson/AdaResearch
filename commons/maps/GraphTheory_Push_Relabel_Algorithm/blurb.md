Most flow algorithms think globally. Ford-Fulkerson searches for paths. Edmonds-Karp measures distance. Push-relabel refuses the overview. It works locally — each node knows only its own excess, its own height. Too much flow? Push it downhill. Nowhere to push? Relabel — rise higher. No coordination. No augmenting paths. Just local pressure and vertical escape.

The algorithm floods the network from source, then spends its entire runtime cleaning up the mess. Excess pools at nodes. Heights shift. Flow reverses. The global optimum emerges not from planning but from thousands of local corrections — water finding its level through purely selfish acts.

A maximum flow solved without ever seeing the whole graph. Structure from pressure. Order from overflow.