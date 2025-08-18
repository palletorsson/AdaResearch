#!/usr/bin/env python3
"""
Fix 'var progress' lines that use % operator to use fmod() instead
"""

import os
import re

def fix_progress_modulo(file_path):
    """Fix var progress lines using % to use fmod()"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        changes_made = []
        
        # Pattern: var progress = (expression) % float_value
        pattern = r'(var progress = )(\([^)]+\)) % ([0-9]+\.[0-9]+)'
        matches = list(re.finditer(pattern, content))
        
        for match in matches:
            var_declaration = match.group(1)  # "var progress = "
            expression = match.group(2)       # "(time * 0.3 + float(i) * 0.08)"
            modulo_value = match.group(3)     # "1.0"
            
            old_line = f'{var_declaration}{expression} % {modulo_value}'
            new_line = f'{var_declaration}fmod({expression}, {modulo_value})'
            
            content = content.replace(old_line, new_line)
            changes_made.append(f'progress % {modulo_value}')
        
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            if changes_made:
                print(f"Fixed {file_path}: {len(changes_made)} progress modulo operations")
            return True
        else:
            return False
            
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

def main():
    """Process files with progress modulo issues"""
    files_to_fix = [
        'algorithms/wavefunctions/fourier_transform/FourierTransform.gd',
        'algorithms/MachineLearning/variational_autoencoders_VAEs/VariationalAutoencodersVAEs.gd',
        'algorithms/MachineLearning/transformers/Transformers.gd',
        'algorithms/MachineLearning/time_series_analysis/TimeSeriesAnalysis.gd',
        'algorithms/MachineLearning/reinforcement_learning/ReinforcementLearning.gd',
        'algorithms/MachineLearning/recommendation_systems/RecommendationSystems.gd',
        'algorithms/MachineLearning/optimization_algorithms/OptimizationAlgorithms.gd',
        'algorithms/MachineLearning/natural_language_processing_NLP/NaturalLanguageProcessingNLP.gd',
        'algorithms/MachineLearning/LSTMs/LSTMs.gd',
        'algorithms/MachineLearning/generative_adversarial_networks_GANs/GenerativeAdversarialNetworksGANs.gd',
        'algorithms/MachineLearning/feature_engineering/FeatureEngineering.gd',
        'algorithms/MachineLearning/explainable_AI_XAI/ExplainableAIXAI.gd',
        'algorithms/MachineLearning/ensemble_methods/EnsembleMethods.gd',
        'algorithms/MachineLearning/dimensionality_reduction/DimensionalityReduction.gd',
        'algorithms/MachineLearning/computer_vision/ComputerVision.gd'
    ]
    
    print("Fixing 'var progress' modulo operations to use fmod()...")
    print("=" * 60)
    
    fixed_count = 0
    total_fixes = 0
    
    for file_path in files_to_fix:
        if os.path.exists(file_path):
            if fix_progress_modulo(file_path):
                fixed_count += 1
    
    print("=" * 60)
    print(f"Fixed {fixed_count} files with progress modulo operations")

if __name__ == "__main__":
    main()
