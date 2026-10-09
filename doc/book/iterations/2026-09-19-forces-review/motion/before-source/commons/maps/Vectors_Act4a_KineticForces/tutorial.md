# Kinetic forces: inspect the receiver

This hall follows the field receiver comparison and precedes Vectors_Act4b_Oscillation. Book primary order: drag_corridor, force_mower, centrifuge_ring. All eight source artifacts remain.

## Physical drag

The map opts drag_corridor into kinetic_drag. Three RigidBody3D probes start at local X=-4 with velocity 4 m/s along +X. Each holds a fixed coefficient b: 0.4, 1.3, 3.2 kg/s. The applied force is -b times world velocity. Default mass is 1 kg; MASS cycles 1/2/4 and resets the bodies to a held state. FIRE restarts. Linear and angular damping are explicitly replaced by zero, gravity is zero, rotation is locked and the local scene is at unit scale with no yaw. The observation freezes a probe after X reaches +4, retaining its outgoing state. There is no collision response at that cutoff.

Away from the cutoff the continuous prediction is v(t)=v0 exp(-b t/m). The discrete engine response is checked against this with a numerical tolerance. The coefficient is a chosen model value, not a measured fluid property. Pink force arrows reuse three rigs, drawn at 0.12 m/N. Readouts update at 10 Hz. The force calculation continues each physics update.

WALK starts off. In the central strip |X|<=1.35, Z from -4.5 to +4.5 and local Y between -0.2 and 2.3, it returns a locomotion multiplier 1/(1+b_numeric), where b_numeric is the numeric coefficient in kg/s. This is an explicit illustrative mapping, equivalent to normalising b by 1 kg/s, not another integration of the probe's force.

The ordinary endless-museum desktop path applies that factor to horizontal velocity after input/feel computes it and before move_and_slide. It leaves vertical velocity untouched. The XR adapter runs at order 90 after direct movement requests and scales ground_control_velocity. It respects exclusive movement. Because XRTools caches its providers at ready, the body-owned adapter is inserted once into the cached list when this opted-in room finds an XR body; newly added XR bodies are handled too. It remains a no-op when no enabled medium contains the body. Tracked physical walking is not damped. Headset comfort is untested.

## Signed mower work

The mower remains a constrained pickable prop. Its path counter sums displacement lengths. Signed nominal work now sums nominal_force.dot(displacement), with the drawn F_MAG=0.95 N force aligned to current mower orientation and configured angle. A forward-and-back traversal with fixed orientation cancels nominal work but adds two legs of path. A sideways move contributes zero nominal work. This is not measured hand effort or a physical energy budget. Grass cutting remains a proximity operation and is not undone by returning. The initial placement is excluded from the ledger by seeding the first measured position on the first process update.

## Prescribed circle

The ring's actual angular speed now equals its displayed linear speed divided by radius. The prior two unrelated speed mappings disagreed. This map adds a SPEED button cycling 2/4/6 m/s at radius 3.4 m. An angular phase accumulates independently, so speed edits preserve position on the circle. The button rebuild is deferred until after its press event completes. Two arrows are built on parameter changes and transformed with the pod each frame, avoiding repeated mesh creation. Velocity uses 0.18 m per m/s; required centripetal acceleration uses 0.10 m per m/s squared. The inward arrow is an acceleration, not a mass-specific applied force.

## Verification

The desktop probe exercises actual physics decay, mass response, live pointer controls, the ordinary desktop movement path, XRTools adapter registration and stick-request transformation without hardware, exclusive movement, signed mower work, ring speed/phase, clear corridor samples and control reach. This is not a headset playtest. See the illustrated guide and machine-readable check report for the final count.
