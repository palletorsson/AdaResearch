# Interactive VR Monte Carlo Simulation - Computational Statistics

## Overview
This VR experience demonstrates Monte Carlo methods - using random sampling to solve complex mathematical problems. The primary example estimates π by randomly throwing darts at a circle inscribed in a square, showcasing how randomness can solve deterministic problems.

## Educational Objectives
- **Monte Carlo Methods**: Understanding random sampling for computation
- **Convergence**: How estimates improve with more samples  
- **Law of Large Numbers**: Random processes approaching theoretical values
- **Computational Statistics**: Using simulation when analytical solutions are difficult
- **Error Analysis**: Measuring accuracy and convergence rates

## VR Interaction
- **Trigger**: Start/stop the Monte Carlo simulation
- **Grip**: Reset simulation data  
- **Visual Sampling**: Watch random points appear in real-time
- **Convergence Chart**: See π estimate converge to true value

## Algorithm Features
1. **π Estimation**: Classic circle-in-square dart throwing method
2. **Real-Time Visualization**: Animated random point generation
3. **Convergence Analysis**: Chart showing estimate accuracy over time
4. **Error Tracking**: Continuous measurement of estimation error
5. **Batch Processing**: Efficient sampling with visual feedback

## Monte Carlo Method - π Estimation

### Algorithm
1. Generate random point (x,y) in square [-1,1] × [-1,1]
2. Check if point is inside unit circle: x² + y² ≤ 1
3. Count inside points vs total points
4. Estimate: π ≈ 4 × (inside_count / total_count)

### Mathematical Foundation
- **Circle Area**: π × r² = π (for unit circle)
- **Square Area**: (2r)² = 4 (for square containing circle)
- **Ratio**: Circle/Square = π/4
- **Estimation**: π = 4 × (points_in_circle / total_points)

## Statistical Properties
- **Convergence Rate**: Error decreases as O(1/√n)
- **Central Limit Theorem**: Estimate distribution approaches normal
- **Confidence Intervals**: Can calculate uncertainty bounds
- **Sample Size**: More samples = better accuracy (but slower convergence)

## Parameters
- `sample_size`: Total number of random points (default: 10,000)
- `batch_size`: Points processed per animation frame (default: 100)
- `animation_speed`: Speed of visualization (default: 10.0)
- `show_sample_points`: Whether to display individual points

## Key Insights
- **Random → Deterministic**: Random process estimates fixed value (π)
- **Diminishing Returns**: Error reduction slows with more samples
- **Statistical Fluctuation**: Estimates vary around true value
- **Practical Applications**: When integration/calculation is impossible

## Extensions
- Compare different random number generators
- Explore variance reduction techniques
- Try other Monte Carlo applications (integration, option pricing)
- Analyze convergence rates for different problems

## Real-World Applications
- **Financial Modeling**: Option pricing, risk assessment
- **Physics**: Radiation transport, particle interactions  
- **Engineering**: Reliability analysis, optimization
- **Computer Graphics**: Ray tracing, global illumination
- **Scientific Computing**: Complex system simulation