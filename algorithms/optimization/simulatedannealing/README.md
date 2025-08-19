# Simulated Annealing Visualization

## 🔥 Thermal Optimization & Cooling Resistance

A comprehensive implementation of Simulated Annealing with real-time visualization of optimization landscapes, temperature cooling schedules, and acceptance probability mechanics. This algorithm explores global optimization through thermal metaphors and demonstrates resistance to local optima through controlled randomness.

## 🎯 Algorithm Overview

Simulated Annealing is a probabilistic optimization technique inspired by the physical process of annealing in metallurgy. It allows temporary acceptance of worse solutions to escape local optima, with the probability of acceptance decreasing as the system "cools" over time.

### Key Concepts

1. **Temperature**: Controls the probability of accepting worse solutions
2. **Cooling Schedule**: Determines how temperature decreases over time
3. **Energy/Objective Function**: The function being optimized
4. **Acceptance Probability**: exp(-ΔE/T) for worse solutions
5. **Equilibrium**: Number of steps at each temperature level

## 🔧 Technical Implementation

### Core Algorithm Features

- **Multiple Test Functions**: Rastrigin, Ackley, Sphere, Rosenbrock, and custom landscapes
- **Cooling Schedules**: Exponential, linear, logarithmic, and fast cooling
- **3D Landscape Visualization**: Real-time energy surface rendering
- **Optimization Path Tracking**: Visual trail of solution evolution
- **Temperature Animation**: Real-time cooling process visualization

### Optimization Problems

#### 1. Rastrigin Function
```
f(x) = A*n + Σ[x_i² - A*cos(2π*x_i)]
```
- **Characteristics**: Many local minima, global minimum at origin
- **Difficulty**: High multimodality tests global search capability

#### 2. Ackley Function
```
f(x) = -a*exp(-b*√(Σx_i²/n)) - exp(Σcos(c*x_i)/n) + a + e
```
- **Characteristics**: Nearly flat outer region, sharp central peak
- **Difficulty**: Deceptive landscape with single global minimum

#### 3. Sphere Function
```
f(x) = Σx_i²
```
- **Characteristics**: Single global minimum, convex
- **Difficulty**: Easy benchmark for testing basic functionality

#### 4. Rosenbrock Function
```
f(x) = Σ[100(x_{i+1} - x_i²)² + (1 - x_i)²]
```
- **Characteristics**: Narrow curved valley, "banana function"
- **Difficulty**: Easy to find valley, hard to converge to minimum

## 🎮 Interactive Controls

### Basic Controls
- **SPACE**: Start/Stop optimization
- **R**: Reset optimization and generate new random start
- **1-4**: Switch between test functions (Rastrigin, Ackley, Sphere, Rosenbrock)
- **↑/↓**: Adjust initial temperature

### Configuration Parameters
- **Initial Temperature**: Starting temperature (controls initial acceptance)
- **Final Temperature**: Termination temperature
- **Cooling Rate**: Rate of temperature decrease (exponential schedule)
- **Cooling Schedule**: Method of temperature update
- **Max Iterations**: Maximum optimization steps
- **Equilibrium Steps**: Steps per temperature level

## 📊 Visualization Features

### 3D Energy Landscape
- **Surface Mesh**: 3D visualization of objective function
- **Height Mapping**: Energy values mapped to Z-coordinate
- **Transparency**: Allows viewing of optimization path underneath
- **Real-time Updates**: Dynamic landscape for custom problems

### Solution Tracking
- **Current Solution**: Red sphere showing current position
- **Best Solution**: Green sphere showing global best found
- **Optimization Path**: Yellow trail showing solution evolution
- **Temperature Trail**: Color-coded path based on temperature

### Information Display
- **Temperature**: Current system temperature
- **Energy Values**: Current and best objective function values
- **Statistics**: Acceptance rates, move counts, improvements
- **Progress**: Iteration counter and equilibrium tracking

## 🏳️‍🌈 Thermal Resistance Framework

### Cooling Politics
Simulated Annealing embodies resistance to algorithmic conformity through controlled randomness:

- **Temperature as Agency**: Higher temperatures enable exploration of "forbidden" solutions
- **Cooling as Constraint**: Gradual reduction of freedom mirrors social normalization
- **Acceptance Probability**: Mathematical formulation of resistance to immediate improvement
- **Local Optima as Traps**: How algorithms get stuck in suboptimal solutions

### Algorithmic Justice Questions
1. **Who controls the cooling?** Temperature schedules embed assumptions about optimal exploration
2. **What gets "frozen out"?** Low-temperature phases exclude diverse solutions
3. **How do we balance exploration vs. exploitation?** Core tension in optimization
4. **When is "good enough" sufficient?** Termination criteria and solution quality

## 🔬 Educational Applications

### Optimization Theory
- **Global vs. Local Optimization**: Understanding the exploration-exploitation tradeoff
- **Metaheuristics**: Learning probabilistic optimization approaches
- **Convergence Analysis**: Studying how algorithms approach optimal solutions
- **Parameter Sensitivity**: Effects of temperature schedules and cooling rates

### Physics Integration
- **Thermodynamics**: Statistical mechanics and energy minimization
- **Phase Transitions**: Continuous vs. discontinuous parameter changes
- **Boltzmann Distribution**: Probability distributions in thermal systems
- **Entropy**: Information theory connections to randomness

## 📈 Performance Characteristics

### Computational Complexity
- **Time Complexity**: O(max_iterations × evaluation_cost)
- **Space Complexity**: O(problem_dimensions + path_length)
- **Convergence Rate**: Depends on cooling schedule and problem landscape

### Algorithm Strengths
- **Global Optimization**: Can escape local optima
- **Simple Implementation**: Few parameters to tune
- **General Purpose**: Works on any objective function
- **Theoretical Guarantees**: Proven convergence under certain conditions

### Algorithm Limitations
- **Slow Convergence**: May require many function evaluations
- **Parameter Sensitivity**: Performance depends on cooling schedule
- **No Gradient Information**: Doesn't use derivative information
- **Memory Requirements**: May need to store optimization history

## 🎓 Learning Objectives

### Primary Goals
1. **Understand probabilistic acceptance** and its role in global optimization
2. **Explore temperature schedules** and their impact on search behavior
3. **Analyze landscape characteristics** and their optimization difficulty
4. **Examine the balance** between exploration and exploitation

### Advanced Topics
- **Parallel Simulated Annealing**: Multiple chains and temperature levels
- **Adaptive Cooling**: Dynamic temperature adjustment based on acceptance rates
- **Hybrid Methods**: Combining with local search algorithms
- **Theoretical Analysis**: Convergence proofs and optimal cooling schedules

## 🔍 Experimental Scenarios

### Recommended Explorations

1. **Cooling Schedule Comparison**
   - Test exponential vs. linear vs. logarithmic cooling
   - Observe convergence speed and solution quality
   - Analyze final temperature vs. solution precision

2. **Temperature Range Analysis**
   - Vary initial temperature (10-500)
   - Study acceptance rates at different temperatures
   - Find optimal starting temperature for each problem

3. **Problem Landscape Effects**
   - Compare performance on different test functions
   - Analyze how landscape features affect optimization
   - Identify problem characteristics that favor SA

4. **Equilibrium Step Impact**
   - Adjust steps per temperature level (1-50)
   - Study exploration vs. computational efficiency
   - Find optimal equilibrium for different problems

## 🚀 Advanced Features

### Customization Options
- **Custom Landscapes**: Modify objective functions and add local minima
- **Visualization Modes**: Toggle landscape, path, and marker displays
- **Animation Control**: Adjust optimization speed and visual effects
- **Statistical Analysis**: Detailed performance metrics and convergence plots

### Extension Possibilities
- **Multi-objective Optimization**: Pareto frontier exploration
- **Constrained Optimization**: Penalty methods and feasibility handling
- **Population-based SA**: Multiple parallel chains
- **Adaptive Parameters**: Self-tuning temperature schedules

## 🎯 Critical Questions for Reflection

1. **How does temperature control the balance between exploration and exploitation?**
2. **What are the ethical implications of probabilistic decision-making in algorithms?**
3. **When might accepting worse solutions lead to better long-term outcomes?**
4. **How do cooling schedules embed assumptions about optimal search strategies?**

## 📚 Further Reading

### Foundational Papers
- Kirkpatrick, S., Gelatt, C. D., & Vecchi, M. P. (1983). Optimization by Simulated Annealing
- Černý, V. (1985). Thermodynamical Approach to the Traveling Salesman Problem
- Metropolis, N., et al. (1953). Equation of State Calculations by Fast Computing Machines

### Optimization Literature
- Aarts, E., & Korst, J. (1989). Simulated Annealing and Boltzmann Machines
- Van Laarhoven, P. J., & Aarts, E. H. (1987). Simulated Annealing: Theory and Applications
- Henderson, D., et al. (2003). The Theory and Practice of Simulated Annealing

### Critical Algorithm Studies
- Winner, L. (1980). Do Artifacts Have Politics?
- Gillespie, T. (2014). The Relevance of Algorithms
- Introna, L. D., & Wood, D. (2004). Picturing Algorithmic Surveillance

## 🔧 Technical Implementation Details

### Core Algorithm Loop
```gdscript
func simulated_annealing():
    current_solution = random_solution()
    current_energy = evaluate(current_solution)
    best_solution = current_solution
    best_energy = current_energy
    
    while temperature > final_temperature:
        for equilibrium_steps:
            neighbor = generate_neighbor(current_solution)
            neighbor_energy = evaluate(neighbor)
            delta_energy = neighbor_energy - current_energy
            
            if delta_energy < 0 or random() < exp(-delta_energy/temperature):
                current_solution = neighbor
                current_energy = neighbor_energy
                
                if current_energy < best_energy:
                    best_solution = current_solution
                    best_energy = current_energy
        
        temperature = update_temperature(temperature)
    
    return best_solution
```

### Cooling Schedules
```gdscript
# Exponential cooling
temperature = temperature * cooling_rate

# Linear cooling
temperature = initial_temp * (1 - iteration/max_iterations)

# Logarithmic cooling
temperature = initial_temp / log(2 + iteration)

# Fast cooling
temperature = initial_temp / (1 + iteration)
```

### Acceptance Probability
```gdscript
func acceptance_probability(delta_energy, temperature):
    if delta_energy < 0:
        return 1.0  # Always accept improvements
    else:
        return exp(-delta_energy / temperature)
```

## 📊 Performance Metrics

### Optimization Quality
- **Best Energy Found**: Global minimum approximation quality
- **Convergence Rate**: Speed of approach to optimal solution
- **Success Rate**: Percentage of runs finding global optimum
- **Solution Diversity**: Exploration of different regions

### Algorithm Behavior
- **Acceptance Rate**: Percentage of moves accepted
- **Improvement Rate**: Percentage of moves that improve solution
- **Temperature Decay**: Rate of cooling over time
- **Path Length**: Total distance traveled in solution space

### Statistical Analysis
- **Mean Performance**: Average solution quality across runs
- **Standard Deviation**: Consistency of algorithm performance
- **Convergence Curves**: Energy vs. iteration plots
- **Temperature Profiles**: Cooling curves and acceptance rates

---

**Status**: ✅ Complete - Production Ready  
**Complexity**: Advanced Optimization  
**Prerequisites**: Calculus, Probability Theory, Optimization Fundamentals  
**Estimated Learning Time**: 3-4 hours for basic concepts, 8-10 hours for advanced understanding 