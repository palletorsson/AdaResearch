# Attention Mechanisms

## Folder Summary

The `Attention Mechanisms` module provides a 3D sandbox for exploring the ideas behind self-attention workflows. It invites visitors to tune parameters, watch spatial feedback evolve in real time, and connect the algorithm's theory to an intuitive scene.

It ships with the scene file `attention_mechanisms.tscn` and the controller script `AttentionMechanisms.gd`.

## How It Works: A Functional QKV Model

This scene implements a functional **self-attention** mechanism based on the **Query-Key-Value (QKV)** model. It provides a tangible, interactive way to understand how a sequence of inputs can pay attention to itself.

1.  **Tokens as Queries and Keys:** The scene creates a sequence of "token" objects. In this self-attention model, every token acts as both a potential Query and a Key.
2.  **Interactive Query Selection:** You can choose which token acts as the **Query** by changing the `query_index` parameter in the Inspector. The selected Query token is highlighted with a distinct color. All other tokens in the sequence act as **Keys**.
3.  **Real-Time Score Calculation:** The script continuously calculates the "attention score" between the active Query and all Key tokens (including itself). The score is based on **inverse distance**: the closer a Key is to the Query, the higher its attention score.
4.  **Normalization (Softmax):** The raw scores are then normalized (using a softmax-like approach) so that they all sum to 1. This creates a probability distribution, showing how attention is distributed across the sequence for the given Query.
5.  **Visual Feedback:**
    *   **Token Emission:** The brightness of each token is directly proportional to its attention score. Brighter tokens are receiving more attention from the Query.
    *   **Attention Matrix:** The 2D grid visualizes the attention scores. The row corresponding to the active `query_index` will show bright cells, with the brightness of each cell representing the attention score for the corresponding token in the sequence.
6.  **Tunable Falloff:** The `attention_falloff` parameter allows you to control how quickly attention scores decrease with distance. A higher value creates a sharper, more focused attention, while a lower value creates a softer, more distributed attention.

## Key Concepts

### Self-Attention
This scene demonstrates self-attention, where a sequence of data learns to attend to different parts of itself to build a more context-aware representation.

### Attention Components
- **Query (Q)**: The currently selected token, which is "looking" for information.
- **Key (K)**: All the tokens in the sequence, which provide the information.
- **Value (V)**: In this visualization, the Keys and Values are the same tokens.
- **Attention Weights**: The calculated, normalized scores that determine how much the Query focuses on each Key.

## Use Cases
- **Understanding Transformers:** This visualization provides a foundational understanding of the core mechanism behind Transformer models (like GPT and BERT).
- **Machine Learning Education:** A clear, interactive tool for teaching the concept of self-attention.
- **Research and Prototyping:** A sandbox for experimenting with different distance metrics or scoring functions for attention.