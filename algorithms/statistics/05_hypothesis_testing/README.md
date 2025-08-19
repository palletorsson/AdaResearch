# Interactive VR Hypothesis Testing - Statistical Significance

## Overview
This VR experience teaches hypothesis testing fundamentals through interactive t-tests. Players collect sample data, formulate hypotheses, calculate test statistics, and make statistical decisions about population parameters using p-values and significance levels.

## Educational Objectives
- **Null vs Alternative Hypotheses**: Setting up statistical questions
- **Test Statistics**: Converting sample data to standardized measures
- **P-values**: Probability of observing data given null hypothesis
- **Type I/II Errors**: False positives and false negatives
- **Statistical Significance**: Decision-making with uncertainty

## VR Interaction
- **Trigger**: Collect sample data and perform test
- **Grip**: Change test type (one-sample, two-sample, paired)
- **Visual Feedback**: See distributions, critical regions, and test statistics
- **Real-Time Decisions**: Watch p-values update with new data

## Algorithm Features
1. **Multiple Test Types**: One-sample, two-sample, and paired t-tests
2. **Animated Sampling**: Watch data points appear in real-time
3. **Distribution Visualization**: Null distribution with critical regions
4. **Decision Framework**: Clear reject/fail-to-reject outcomes
5. **Statistical Accuracy**: Proper t-distribution calculations

## Hypothesis Testing Framework

### Steps
1. **Formulate Hypotheses**: H₀ (null) vs H₁ (alternative)
2. **Choose Significance Level**: α (typically 0.05)
3. **Collect Sample Data**: Random sampling from population
4. **Calculate Test Statistic**: Standardized measure of evidence
5. **Find P-value**: Probability under null hypothesis
6. **Make Decision**: Reject H₀ if p < α

### Test Types

#### One-Sample t-test
- **H₀**: μ = μ₀ (population mean equals hypothesized value)
- **H₁**: μ ≠ μ₀ (two-tailed test)
- **Test Statistic**: t = (x̄ - μ₀)/(s/√n)

#### Two-Sample t-test
- **H₀**: μ₁ = μ₂ (two population means are equal)
- **H₁**: μ₁ ≠ μ₂ (means are different)
- **Test Statistic**: t = (x̄₁ - x̄₂)/sp√(1/n₁ + 1/n₂)

#### Paired t-test
- **H₀**: μd = 0 (mean difference is zero)
- **H₁**: μd ≠ 0 (there is a difference)
- **Test Statistic**: t = d̄/(sd/√n)

## Key Concepts

### P-values
- **Definition**: P(observing data this extreme | H₀ is true)
- **Interpretation**: Smaller p-values = stronger evidence against H₀
- **Common Misconception**: P-value ≠ P(H₀ is true)

### Type I and Type II Errors
- **Type I Error (α)**: Rejecting true H₀ (false positive)
- **Type II Error (β)**: Failing to reject false H₀ (false negative)
- **Power**: 1 - β (probability of detecting true effect)

### Statistical vs Practical Significance
- **Statistical**: p < α (mathematically significant)
- **Practical**: Effect size matters for real-world importance
- **Sample Size**: Larger samples can detect smaller effects

## Parameters
- `null_hypothesis_mean`: Hypothesized population mean (default: 100.0)
- `sample_size`: Number of observations per sample (default: 30)
- `alpha_level`: Significance level threshold (default: 0.05)
- `true_population_mean`: Hidden true mean for simulation

## Visual Elements
- **Null Distribution**: t-distribution showing sampling variability under H₀
- **Critical Regions**: Shaded areas representing rejection regions
- **Test Statistic Line**: Vertical line showing calculated t-value
- **P-value Bar**: Visual representation of evidence strength
- **Decision Display**: Clear reject/fail-to-reject outcome

## Key Insights
- **Evidence vs Proof**: Statistics provides evidence, not absolute proof
- **Sample Size Matters**: Larger samples detect smaller effects
- **Multiple Testing**: Running many tests increases Type I error risk
- **Effect Size**: Statistical significance doesn't guarantee importance

## Extensions
- Compare different sample sizes and their effect on power
- Explore how effect size influences detectability
- Try different significance levels (α = 0.01, 0.10)
- Understand confidence intervals as hypothesis testing equivalents

## Real-World Applications
- **Medical Trials**: Testing drug effectiveness
- **Quality Control**: Manufacturing process monitoring
- **A/B Testing**: Website/app feature comparison  
- **Psychology**: Experimental effect validation
- **Business**: Market research and decision making