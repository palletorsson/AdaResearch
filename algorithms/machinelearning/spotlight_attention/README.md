# Spotlight Attention

## Folder Summary

This module provides a 3D sandbox for exploring the "Spotlight" model of attention. It provides an intuitive, interactive visualization of how attention can be modeled as a focused beam in a field of information.

## How It Works

1.  **Field of Information:** The scene generates a field of floating objects, representing a rich environment of unattended data points.
2.  **The Spotlight:** A `SpotLight3D` node acts as the "cone of attention". This is the user's focus.
3.  **Interactive Control:** The user can move the spotlight around the scene using the mouse.
4.  **Highlighting:** Objects that fall within the spotlight's cone are highlighted, signifying that they are being "attended" to. Objects outside the cone remain dim.

## Key Concepts

### The Spotlight Model
A classic cognitive psychology model where attention is treated as a focused beam that illuminates a small part of the environment for detailed processing, while the rest remains in shadow.
