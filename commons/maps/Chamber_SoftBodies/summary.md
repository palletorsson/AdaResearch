# Chamber SoftBodies — Summary

Chamber_SoftBodies is the catalyst chamber for the Soft Bodies sequence. It removes the projection catalyst entirely. Contact is the interaction: the learner pushes, the creature deforms, and the energy redistributes across the creature's mesh rather than rebounding as velocity.

The chamber holds a single creature, the spring_hopper. It is built from a mass-spring lattice, so every push produces a local deformation that propagates through the whole body. The learner walks up to the hopper and pushes; the contact region compresses, the surrounding springs pull on their neighbours, and the deformation travels through the body as a slow wave. The hopper rebounds softly, redistributing the force across its structure.

A science screen on the wall renders the contact as a field rather than as a scatter. Displacement is drawn as a continuous surface in space, with colour tracking magnitude. A second display traces the energy of the system over time: incoming impulse, stored spring potential, damping loss, restitution. No single frame names a point of impact; the whole body is participating at once.

Within the sequence, Chamber_SoftBodies makes the sequence's argument physical. Rigidity was the simplifying assumption that the earlier maps deliberately relaxed. When both sides of a contact are soft, the boundary between actor and receiver blurs, and the chamber trains the body to feel that blur before returning the learner to the Lab.
