# Switchboard Attention

## Folder Summary

This module provides a 3D sandbox for exploring the "Switchboard" model of attention. It visualizes attention as a dynamic routing and connection mechanism, similar to an old-fashioned telephone switchboard.

## How It Works

1.  **Inputs and Outputs:** The scene contains a set of "Input" nodes and a set of "Output" nodes.
2.  **Query Selection:** The user can select an Input node, which designates it as the "Query".
3.  **Key Connection:** The script then identifies the most relevant "Key" (an Output node) based on some criteria (e.g., proximity).
4.  **Visual Connection:** A "cable" is drawn between the Query and the Key, visualizing the connection and the flow of information.

## Key Concepts

### The Switchboard Model
A model where attention acts as an operator that dynamically connects an input (the Query) to an output (the Key), allowing information (the Value) to flow. Multi-head attention can be visualized as multiple operators making parallel connections.
