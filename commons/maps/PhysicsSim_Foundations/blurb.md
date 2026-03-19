Before anything moves, something must be written down.

Newton gave us the laws. Euler gave us the first clumsy approximation. Verlet gave us the elegant trick that holds it all together — a method that forgets velocity and remembers position twice, and somehow that's enough. Side by side, the same orbit: Euler's particle spirals outward as energy leaks in. Verlet's stays bounded, precessing but never escaping. The equation is visible. The difference is visceral.

Then the simulation breaks. A spring system runs stable, then the timestep ramps up. Drift becomes wobble becomes explosion. The instability is not a bug — it's the lesson. Every physics engine is a lie told at sixty frames per second. This is where you learn how the lie is constructed, and where it falls apart.
