# FormFinding_Annealing — walked

> R-021/R-028: considered critical tutorial, ghost-drafted from the working map;
> Palle rules the voice. The walk (tutorial) woven with the turn (critical).

## The cast

simulated_annealing · max_q_basin_room · energy_landscape_bench

## The walk

The first stable shape you fall into is rarely the best one. The `energy_landscape_bench` shows why — a wavy surface of hills and valleys where height is energy, and a body rolling downhill will stop in the *first* valley it reaches, a local minimum, even if a deeper one waits just over the ridge. Pure descent is greedy and gets stuck. The `simulated_annealing` station is the escape: it shakes the system with heat, letting the body *climb* sometimes, accept a worse position, jump out of the shallow valley — and then cools slowly, so as the shaking dies down it settles into a deeper rest than descent alone could reach. Basin-hopping, the physicists call it, borrowed from how a cooling metal finds its strong crystalline order by annealing rather than quenching. Then walk the `max_q_basin_room`: a deep, narrow, *dead* well on one side and a shallow, wide, *alive* well on the other, and the whole map's stakes are in which one you let the system fall into.

## The turn (critical)

Two turns, and they lock together. The first is method and quietly political: **you have to get worse to get better.** Greedy descent — always improve, never accept a loss — is exactly the trap, the local minimum dressed as success, the good-enough shape you can't leave because every direction out is uphill. Escaping it costs heat, disorder, deliberate wrongness, a willingness to be worse for a while; annealing is the algorithm's admission that improvement is not monotonic and the refusal to ever step backward is itself the thing that dooms you. The second turn is the dark room returning, one last time, as an energy landscape. The `max_q_basin_room` insists the landscape is *not neutral*: the deepest well of all — the global minimum, the perfect crystal, F driven all the way down — is **dead**. It is finished, frozen, incapable of the next change; it has minimized so completely that nothing can happen to it again. The alive form is the one that stops *short* of the bottom, resting in the shallow wide basin, low enough to hold its shape and high enough to still be moved. This is QFEP's whole thesis said in the language of form-finding: F wants zero, and zero is death, so life is minimization that *doesn't finish* — poised at the edge, the way the lambda map poised you between the crystal and the static. The marble that finds the deepest bowl has solved the problem perfectly and killed itself doing it.

## Room for improvement

*(Palle: "you have to get worse to get better, AND the deepest minimum is dead —
life stops short of the bottom" is the double turn, QFEP's F/dark-room in landscape
form. Note whether the deep-dead vs shallow-alive wells read as an ethics, not just
two holes.)*
