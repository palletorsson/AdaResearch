# Interactive VR Dice Roll - Discrete Probability Distributions

## Overview
This VR experience demonstrates discrete probability distributions through dice rolling. Players can throw multiple dice and observe how frequency distributions emerge, learning about expected values, variance, and the additive properties of independent random variables.

## Educational Objectives
- **Discrete Uniform Distribution**: Understanding equal probability outcomes (1-6)
- **Expected Value**: Learning E[X] = 3.5 for a fair die
- **Variance and Standard Deviation**: Measuring spread in outcomes
- **Sum of Random Variables**: How multiple dice create new distributions
- **Law of Large Numbers**: Convergence to theoretical probabilities

## VR Interaction
- **Trigger Button**: Throw all dice with realistic physics
- **Multi-Dice Analysis**: Compare single vs multiple dice distributions
- **Real-Time Histogram**: 3D bar chart showing sum distribution
- **Statistical Dashboard**: Live updates of means, variances, and probabilities

## Algorithm Features
1. **Physics Simulation**: Realistic dice throwing with settling detection
2. **Face Recognition**: Accurate determination of face-up values
3. **Distribution Visualization**: Histogram of sum probabilities
4. **Comparative Analysis**: Theoretical vs observed probabilities

## Statistical Concepts Demonstrated

### Single Die
- **Sample Space**: {1, 2, 3, 4, 5, 6}
- **Probability**: P(X = k) = 1/6 for all k
- **Expected Value**: E[X] = 3.5
- **Variance**: Var(X) = 35/12 ≈ 2.92

### Two Dice (Sum)
- **Sample Space**: {2, 3, 4, ..., 12}
- **Expected Value**: E[X + Y] = 7
- **Variance**: Var(X + Y) = 35/6 ≈ 5.83
- **Distribution Shape**: Triangular (approaches normal)

## Parameters
- `dice_count`: Number of dice to roll (1-6, default: 2)
- `max_rolls`: Maximum number of rolls (default: 500)
- `dice_size`: Physical size of dice (default: 0.08m)
- `throw_force`: Force applied to dice (default: 8.0)

## Usage
1. Select number of dice to use
2. Throw dice using VR controller trigger
3. Watch dice settle and values register
4. Observe histogram building up distribution
5. Compare with theoretical expected values

## Key Insights
- Single die shows uniform distribution
- Multiple dice sums show bell-shaped curves
- More rolls → better approximation to theory
- Variance increases with number of dice
- Central Limit Theorem preview with multiple dice