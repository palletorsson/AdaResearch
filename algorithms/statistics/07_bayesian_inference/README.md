# Interactive VR Bayesian Inference - Prior and Posterior Updating

## Overview
This VR experience teaches Bayesian inference through coin bias estimation. Players flip a coin with unknown bias and watch their belief about the bias update with each observation, demonstrating how prior knowledge combines with new evidence to form posterior beliefs.

## Educational Objectives
- **Bayes' Theorem**: P(θ|data) ∝ P(data|θ) × P(θ)
- **Prior vs Posterior**: How beliefs update with evidence
- **Conjugate Priors**: Beta-Binomial conjugacy for mathematical convenience  
- **Credible Intervals**: Bayesian uncertainty quantification
- **Frequentist vs Bayesian**: Comparing different statistical approaches

## VR Interaction
- **Trigger**: Flip coin and observe outcome
- **Grip**: Reset all observations and return to prior
- **Real-Time Updates**: Watch distributions change with each flip
- **Visual Convergence**: See estimate approach true value

## Algorithm Features
1. **Beta-Binomial Model**: Mathematically elegant conjugate prior system
2. **Real-Time Visualization**: Prior and posterior distributions update live
3. **Credible Intervals**: Bayesian uncertainty bounds calculation
4. **Convergence Tracking**: Visual history of estimate evolution
5. **True Value Comparison**: Optional display of hidden true bias

## Bayesian Framework

### Model
- **Likelihood**: P(heads|θ) = θ, P(tails|θ) = 1-θ
- **Prior**: θ ~ Beta(α₀, β₀) 
- **Posterior**: θ|data ~ Beta(α₀ + #heads, β₀ + #tails)

### Key Concepts
- **Prior Belief**: Initial assumption about coin bias
- **Likelihood**: Probability of observed data given parameter
- **Posterior**: Updated belief after observing data
- **Conjugacy**: Beta prior + Binomial likelihood = Beta posterior

## Statistical Properties
- **Mean Estimate**: α/(α+β) 
- **Uncertainty**: Decreases as (α+β) increases
- **Credible Intervals**: Exact Bayesian confidence bounds
- **Convergence**: Posterior concentrates around true value

## Comparison with Frequentist
- **Frequentist**: θ̂ = #heads/#flips (fixed, no uncertainty)
- **Bayesian**: Full probability distribution over θ
- **Interpretation**: Bayesian intervals have direct probability meaning
- **Prior Information**: Bayesian naturally incorporates existing knowledge

## Parameters
- `true_coin_bias`: Hidden true bias of the coin (default: 0.7)
- `prior_alpha`: Beta prior α parameter (default: 1.0)
- `prior_beta`: Beta prior β parameter (default: 1.0)  
- `max_observations`: Maximum coin flips allowed (default: 100)

## Key Insights
- **Learning**: Beliefs update optimally with new evidence
- **Uncertainty**: Bayesian methods naturally quantify uncertainty
- **Prior Influence**: Strong priors require more evidence to overcome
- **Convergence**: Eventually dominates prior with enough data

## Visual Elements
- **Prior Distribution**: Initial belief (blue curve)
- **Posterior Distribution**: Updated belief (green curve)
- **Convergence Chart**: Estimate trajectory over time
- **Observation History**: Recent coin flip outcomes
- **Credible Intervals**: Uncertainty bounds around estimate

## Extensions
- Experiment with different priors (informative vs uninformative)
- Compare convergence rates for different true biases
- Explore how sample size affects uncertainty
- Try other conjugate prior families (Normal-Normal, etc.)

## Applications
- **Medical Diagnosis**: Updating disease probability with test results
- **Machine Learning**: Bayesian neural networks, hyperparameter tuning
- **A/B Testing**: Continuous monitoring of conversion rates
- **Robotics**: Sensor fusion and state estimation
- **Finance**: Risk assessment with updating information