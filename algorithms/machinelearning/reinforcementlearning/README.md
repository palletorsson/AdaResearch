# Reinforcement Learning Creature

## Overview
This implementation demonstrates a reinforcement learning system where a creature with randomly generated joints learns to walk through trial and error. The system combines procedural body generation with Q-learning reinforcement learning to create emergent locomotion behaviors.

## Algorithm Description
The algorithm creates a creature with random joint configurations and uses reinforcement learning to discover optimal walking strategies. The creature learns through interaction with its environment, gradually improving its movement patterns based on rewards for forward progress.

### Key Components
1. **Procedural Body Generation**: Creates creatures with random joint configurations
2. **Q-Learning Algorithm**: Reinforcement learning for action selection
3. **Physics Simulation**: Realistic joint physics and collision detection
4. **Reward System**: Distance-based rewards for forward movement
5. **Exploration Strategy**: Epsilon-greedy exploration with decay

### Learning Process
1. **State Representation**: Joint angles, velocities, and body orientation
2. **Action Space**: Torque values applied to each joint
3. **Reward Function**: Distance traveled from starting position
4. **Q-Table Updates**: Temporal difference learning with experience replay

## Algorithm Flow
1. **Body Generation**: Create creature with random limb lengths and joint configurations
2. **State Observation**: Measure current joint states and body position
3. **Action Selection**: Choose actions using epsilon-greedy policy
4. **Environment Interaction**: Apply torques and simulate physics
5. **Reward Calculation**: Measure progress and calculate rewards
6. **Learning Update**: Update Q-values based on experience

## Files Structure
- `joint_learn_walk.gd`: Main RL creature implementation with physics and learning
- `joint_learn_walk.tscn`: Scene setup with creature and environment

## Parameters
- **Body Structure**: 5 limbs, variable length (0.5-1.5), radius (0.1)
- **Learning**: Learning rate (0.1), discount factor (0.9)
- **Exploration**: Initial rate (0.3), decay (0.995), minimum (0.01)
- **Physics**: Torque strength (2.0), update frequency (0.1)

## Theoretical Foundation
Based on:
- **Q-Learning**: Model-free reinforcement learning algorithm
- **Temporal Difference Learning**: Learning from experience without environment model
- **Exploration vs Exploitation**: Balancing learning and performance
- **Evolutionary Robotics**: Learning locomotion through trial and error

## Applications
- Robotic locomotion learning
- Game AI character behavior
- Evolutionary computation research
- Adaptive control systems
- Procedural animation systems

## Visual Features
- Real-time 3D creature visualization
- Dynamic joint movement and physics
- Learning progress indicators
- Performance metrics display

## Usage
Run the simulation to watch the creature learn to walk. Initially, movements will be random and ineffective. Over time, the creature will develop coordinated movement patterns that maximize forward progress. Observe how different random body configurations lead to different learned gaits.