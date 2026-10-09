# Directions already in the ground

If hundreds of agents turn together, must they be watching one another?

<!-- @FlowFieldMain -->

Find an arrow near an agent and predict which way that agent will turn. Follow the automatic tour as an open field gains obstacles, then compare those scenes with wind and noise. Give each arrangement time: the tour changes roughly every ten seconds and eventually remains with the noise field.

The arrows offer directions throughout the space. Many agents can follow the same organisation without consulting one another. Around an obstacle, a useful direction may initially point away from the destination you can see, because the direct route is blocked.

During an obstacle scene, compare two agents that arrive at the same patch at different moments. Their immediate histories can differ while the arrow they encounter gives the same local recommendation. Then compare two nearby arrows on opposite sides of an obstacle. Nearness alone need not produce the same direction. This gives you two small checks on your explanation: the field organises movement by position, and the obstacle matters through its effect on that organisation.

In the route-finding scenes, the model first spreads costs outward from a target through a grid. It then assigns directions towards neighbouring cells with lower costs. Each moving agent reads the direction at its present position and steers towards it. The expensive task of organising a route is shared through the field; it is not solved afresh by every agent at every step.

Wind makes the distinction sharper. A field can give a direction without giving a destination. Noise supplies local variation without the same coherent route. Where the direction is zero, the agents have a wandering behaviour rather than a magical knowledge of where to go.

Physarum’s agents helped write the field they subsequently sensed. These agents receive a field prepared for them. From far away, both populations can look collectively intelligent. Looking at the relation between agent and field tells us which explanation the movement supports.

The cost map also contains decisions: which cells are blocked, which routes are costly, and what destination matters. Shared navigation can reproduce those decisions very efficiently. Efficiency alone cannot tell us whether every traveller can use the permitted route.

Try following one arrow that surprises you instead of the largest stream of agents. For a future version, hiding the arrows while holding the scene fixed would test how easily we mistake shared infrastructure for spontaneous agreement.

<!-- @ -->

Boids will remove that supplied direction and let nearby agents become one another’s moving reference.
