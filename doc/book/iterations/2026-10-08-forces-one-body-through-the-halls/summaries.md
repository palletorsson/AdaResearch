# Forces — eleven lesson summaries

## 1. Vectors_Act1_WhatAVectorIs — The relation between two points

Take the two familiar points. Move one and watch the cylinder between them. Then move both by the same amount. Their addresses change; the gap between them stays the same. Continue the point class from Lines. Make two points report their separation as a vector, a length and a direction. Begin with those three readings; return to the projection after they make sense. Keep the distinction between a position and a displacement. In Launch, a vector describes how much position changes each second.

## 2. VFM_05_Launch — Give the point a beginning

Press FIRE and watch the point rise and return. Before revealing PATH, trace the curve you expect with your hand. Then compare your prediction with the displayed path. Continue the sphere as a marker. Give it an initial velocity and calculate its position as time passes. Freeze its rigid body and turn collision off so this first flight follows the calculation alone. You have calculated where the point should be. Next, let the physics engine keep its velocity while you supply a push.

## 3. VFM_03_Motion — When the push ends

Press PUSH 1 s. Three equally sized black points start moving. Their masses are 1, 2 and 4 kilograms. Watch after the second has passed: the push ends, but the points keep going. Use three instances of the familiar point. Give each the same force for the same time and vary only mass. The supplied `free_point.gd` lets them move freely, with gravity and damping set to zero. A push can end while its consequence continues. Next, choose the push from where the point is now.

## 4. Vectors_Act3_FieldsAndMotion — Ask the field where you are

Follow one point through the vortex arrows. At each place it meets a different direction. Watch it turn before switching ONE / MANY to bring back the circulating cargo. Keep the moving point. Replace the fixed push with `sample()`, a function that reads its position and returns an acceleration. Combine an inward pull with a sideways turn. This force reads position. The next one reads how fast, and in which direction, the point is moving.

## 5. Vectors_Act4a_KineticForces — Let motion meet resistance

Drop a point into a coloured region. Watch it slow as it falls. Begin with DRAG ONLY; leave BUOYANCY for a later comparison. Use RESET before the next drop. Keep the sphere and enable gravity. Add resistance while its centre lies between heights zero and two metres. The small study uses a height test; it does not build a liquid surface. Drag resists motion. A spring adds a reason to move back toward an attachment.

## 6. Vectors_Act4b_Oscillation — Release the point; keep the attachment

Pull the rose grip beside the hanging point and release. The point returns, passes its resting place and turns again. The grip lets you pull while the spring keeps acting. Make one spring from the familiar point and a fixed anchor. In your small study, grab the point itself to set its position, then release it to see the spring act. The thin cylinder shows the attachment. Here a repeating movement comes from forces changing velocity. Next, make a similar repetition by assigning positions.

## 7. Change_Choreography — The same return, a different cause

Watch the rods turn together, then notice one that is out of step. Look back toward the spring. Both repeat. What keeps each one moving? Use two sphere points as the tips of two arms. Give each an angle and a turning rate. OFFSET changes one angle once; DRIFT changes how quickly that angle advances. A circular path can be prescribed. Next, let two points attract each other and see what path results.

## 8. VFM_07_Gravity — Let both points answer

Begin with PAIR. Follow both spheres: each turns toward a source that is itself moving. Neither one is fixed. Save PAIR / FIVE until you have watched the pair. Return to two physical points. Give them opposite starting velocities. Calculate the attraction between them once, apply it to one body, and apply its negative to the other. These points attract while passing through each other. Bring back collision to ask what lets one body support another.

## 9. VFM_09_Legs — What lets the cube stay up?

Pull the rose leg from under the loaded table. Watch what loses support first, then what it meets on the way down. The fall follows the changed arrangement. Bring back the cube from Primitives. Start with one box resting on one support. Move the support sideways and let the physics engine determine what happens to the load. Contact can hold a body still. Next, let contact pass motion from one body to another.

## 10. VFM_08_Arena — One impact, then the world

Send the black bowling point down the lane. Watch the first pin it reaches and follow that pin into the next contact. Your throw starts a sequence you no longer direct. Use the same point twice: one striker and one target. Give the striker one impulse, then let their collision unfold. Start without gravity or a floor so the first question is the impact. An impulse happens once. In the last hall, hold a trigger to keep adding acceleration to your own movement.

## 11. Vectors_Act5_ForceAsPlace — The player becomes the receiver

Take the two black points. Aim where you want to travel and hold the triggers. Let go of the triggers while keeping hold of the points. The thrust ends; your movement continues under gravity and contact. Extend the familiar point into a thruster. While held and activated, it reports an acceleration in the direction of your hand. The small station script creates two of these points. The point now gives you a capacity in the world. Direction, acceleration, resistance and contact are things you can use together. The racer and the larger experiments give you places to try.
