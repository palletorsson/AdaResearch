# Interactive VR Markov Chain - Stochastic Processes

## Overview
This VR experience teaches Markov chains through interactive state-based simulations. Players can watch systems evolve through probabilistic state transitions, understand memoryless properties, and observe convergence to steady-state distributions.

## Educational Objectives
- **Stochastic Processes**: Systems that evolve randomly over time
- **Markov Property**: Future depends only on current state, not history
- **Transition Matrices**: Probabilities governing state changes
- **Steady State**: Long-term equilibrium distributions
- **Ergodicity**: Convergence properties of Markov chains

## VR Interaction
- **Trigger**: Start/stop continuous simulation
- **Grip**: Take single simulation step
- **Visual Tracking**: Watch current state indicator move
- **Real-Time Charts**: See empirical vs theoretical probabilities

## Algorithm Features
1. **Multiple Chain Types**: Weather, random walk, gene expression, market models
2. **Animated Transitions**: Visual state changes with probability labels
3. **Matrix Visualization**: Interactive transition probability display
4. **Convergence Analysis**: Empirical vs steady-state probability comparison
5. **Step-by-Step Control**: Manual or automatic simulation progression

## Markov Chain Types

### Weather Model (3 States)
- **States**: Sunny, Cloudy, Rainy
- **Applications**: Weather forecasting, climate modeling
- **Properties**: Irreducible, aperiodic chain
- **Insights**: How current weather influences tomorrow's forecast

### Random Walk (5 States)
- **States**: Barrier L, Left, Center, Right, Barrier R
- **Properties**: Absorbing boundaries, recurrent center states
- **Applications**: Stock prices, particle diffusion, gambling
- **Insights**: Absorption probabilities and hitting times

### Gene Expression (3 States)
- **States**: Off, Low Expression, High Expression
- **Applications**: Biological modeling, protein dynamics
- **Properties**: Regulatory feedback mechanisms
- **Insights**: Bistability and cellular decision-making

### Market Model (3 States)
- **States**: Bull Market, Neutral, Bear Market
- **Applications**: Financial modeling, economic cycles
- **Properties**: Persistence and regime switching
- **Insights**: Market memory and trend continuation

## Key Concepts

### Markov Property
- **Definition**: P(Xₙ₊₁ = j | X₀, X₁, ..., Xₙ) = P(Xₙ₊₁ = j | Xₙ)
- **Interpretation**: Future state depends only on current state
- **Memoryless**: Past history is irrelevant given present
- **Applications**: Simplifies modeling complex systems

### Transition Matrix
- **Definition**: P = [pᵢⱼ] where pᵢⱼ = P(Xₙ₊₁ = j | Xₙ = i)
- **Properties**: Rows sum to 1 (stochastic matrix)
- **Visualization**: Color-coded intensity matrix
- **Chapman-Kolmogorov**: P⁽ⁿ⁾ = Pⁿ for n-step transitions

### Steady State Distribution
- **Definition**: π such that π = πP (left eigenvector)
- **Existence**: Guaranteed for finite, irreducible, aperiodic chains
- **Convergence**: πₙ → π as n → ∞
- **Independence**: Steady state independent of initial distribution

### Classification of States
- **Transient**: Eventually left forever
- **Recurrent**: Visited infinitely often
- **Absorbing**: Once entered, never left
- **Periodic**: Return times have common divisor > 1

## Mathematical Foundation

### Fundamental Matrix
- **Definition**: N = (I - Q)⁻¹ for transient states
- **Interpretation**: Expected number of visits to transient states
- **Applications**: Absorption probabilities, expected hitting times

### Long-Run Behavior
- **Ergodic Theorem**: Time averages equal space averages
- **Convergence Rate**: Determined by second-largest eigenvalue
- **Mixing Time**: Steps needed to approach steady state

## Visual Elements
- **State Nodes**: Circular arrangement with state-specific colors
- **Transition Arrows**: Probability-weighted connections between states
- **Transition Matrix**: Heat map showing probability intensities
- **Current State Ring**: Glowing indicator of present location
- **Probability Charts**: Empirical (blue) vs steady-state (red) bars

## Parameters
- `simulation_steps`: Maximum steps in continuous mode (default: 1000)
- `animation_speed`: Steps per second during simulation (default: 2.0)
- `show_steady_state`: Display theoretical equilibrium probabilities
- `show_transition_matrix`: Visual probability matrix representation

## Key Insights
- **Path Independence**: Long-term behavior independent of starting state
- **Convergence**: Empirical frequencies approach theoretical probabilities
- **Absorption**: Some states trap the process permanently
- **Periodicity**: Some chains have cyclical behavior patterns

## Real-World Applications
- **PageRank Algorithm**: Web page ranking via random walks
- **Hidden Markov Models**: Speech recognition, bioinformatics
- **Queueing Theory**: Service systems, network analysis
- **Game Theory**: Strategic interactions, evolutionary dynamics
- **Finance**: Credit risk modeling, option pricing

## Extensions
- Explore different transition matrices and their properties
- Study absorption probabilities in random walks
- Compare convergence rates for different chain structures
- Investigate continuous-time Markov processes
- Learn about reversible chains and detailed balance

## Statistical Properties
- **Stationary Distribution**: π₀P = π₀
- **Limiting Distribution**: limₙ→∞ P⁽ⁿ⁾
- **Return Times**: Expected return to starting state
- **Communicating Classes**: Sets of mutually accessible states