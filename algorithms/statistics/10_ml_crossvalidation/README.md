# Interactive VR Cross-Validation - Model Evaluation and Selection

## Overview
This VR experience teaches cross-validation through interactive model evaluation. Players can watch k-fold CV in action, compare different model complexities, and understand the bias-variance tradeoff while learning to avoid overfitting and underfitting.

## Educational Objectives
- **Model Validation**: Proper evaluation of predictive models
- **Bias-Variance Tradeoff**: Understanding overfitting vs underfitting
- **Cross-Validation Types**: K-fold, LOO, stratified, time series
- **Model Selection**: Choosing optimal complexity
- **Generalization**: How models perform on unseen data

## VR Interaction
- **Trigger**: Start/stop full cross-validation process
- **Grip**: Run single CV step manually
- **Visual Feedback**: Watch training/validation splits in action
- **Real-Time Results**: See CV scores update for each model

## Algorithm Features
1. **Multiple CV Types**: K-fold, leave-one-out, stratified, time series
2. **Polynomial Model Comparison**: Degrees 1, 2, 3, 5, 8
3. **Animated CV Process**: Watch each fold train and validate
4. **Statistical Visualization**: CV scores with error bars
5. **Overfitting Detection**: Clear visualization of model complexity effects

## Cross-Validation Methods

### K-Fold Cross-Validation
- **Process**: Split data into k equal folds
- **Training**: Use k-1 folds for training
- **Validation**: Test on remaining fold
- **Repeat**: Rotate through all folds
- **Score**: Average performance across folds

### Leave-One-Out (LOO)
- **Special Case**: k = n (number of data points)
- **Training**: Use all data except one point
- **Validation**: Test on single left-out point
- **Properties**: Unbiased but high variance
- **Use Case**: Small datasets

### Stratified CV
- **Purpose**: Maintain class distribution in each fold
- **Application**: Classification problems
- **Benefit**: Reduces variance in imbalanced datasets
- **Implementation**: Proportional sampling

### Time Series CV
- **Structure**: Expanding or sliding window
- **Constraint**: No future data in training
- **Application**: Temporal data with trends
- **Validation**: Always on future time points

## Bias-Variance Tradeoff

### Underfitting (High Bias)
- **Characteristics**: Too simple models
- **Symptoms**: Poor performance on both training and validation
- **Example**: Linear model for complex curved data
- **Solution**: Increase model complexity

### Overfitting (High Variance)
- **Characteristics**: Too complex models
- **Symptoms**: Great training performance, poor validation
- **Example**: High-degree polynomial on noisy data
- **Solution**: Reduce complexity, add regularization

### Optimal Complexity
- **Goal**: Minimize validation error
- **Balance**: Sufficient complexity without overfitting
- **Identification**: Peak in CV performance curve
- **Validation**: Consistent performance across folds

## Model Selection Process

### 1. Data Splitting
- **Training Set**: Model development and CV
- **Test Set**: Final unbiased evaluation
- **Importance**: Test set never used in model selection

### 2. Cross-Validation
- **Inner Loop**: Train/validate on CV folds
- **Score Calculation**: Average performance metric
- **Error Estimation**: Standard deviation across folds

### 3. Model Comparison
- **Multiple Models**: Different complexities/algorithms
- **Statistical Significance**: Consider error bars
- **Parsimony**: Prefer simpler models when performance similar

### 4. Final Evaluation
- **Best Model**: Selected based on CV performance
- **Test Performance**: Unbiased final evaluation
- **Generalization**: How model performs in practice

## Visual Elements
- **Dataset Display**: Full data with train/test split
- **Fold Visualization**: Current training (blue) and validation (orange) data
- **Model Curves**: Fitted polynomials for each degree
- **CV Scores Chart**: Bar chart with error bars
- **True Function**: Green curve showing underlying pattern

## Key Metrics
- **Mean Squared Error (MSE)**: Primary evaluation metric
- **CV Score**: Average performance across folds
- **Standard Deviation**: Measure of score variability
- **Test Error**: Final generalization performance

## Parameters
- `k_folds`: Number of cross-validation folds (default: 5)
- `polynomial_degrees`: Model complexities to compare [1,2,3,5,8]
- `num_data_points`: Size of generated dataset (default: 100)
- `test_size`: Proportion held out for final testing (default: 0.2)

## Key Insights
- **CV Reduces Overfitting**: Better generalization estimates
- **Computational Cost**: K-fold is K times more expensive
- **Variance Reduction**: Averaging across folds stabilizes estimates
- **Model Selection**: Choose complexity that maximizes CV performance
- **Test Set**: Only use once for final evaluation

## Common Pitfalls
- **Data Leakage**: Using test data in model selection
- **Temporal Leakage**: Future information in past predictions
- **Insufficient Validation**: Single train/test split unreliable
- **Multiple Testing**: Need correction for many model comparisons

## Real-World Applications
- **Machine Learning Pipelines**: Standard model evaluation practice
- **Hyperparameter Tuning**: Grid/random search with CV
- **Feature Selection**: Choose optimal feature subsets
- **Model Ensembles**: Select models for combination
- **AutoML Systems**: Automated model selection

## Extensions
- Explore different performance metrics (R², MAE, etc.)
- Try regularized models (Ridge, Lasso regression)
- Compare with holdout validation
- Learn about nested CV for hyperparameter tuning
- Study learning curves vs validation curves