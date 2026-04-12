# Jipple Engine: CMS Mathematics Research

## The Core Memory State (CMS)
The CMS is a 2D float64 tensor $A$ of size $(W, H)$.
Each element $A_{x,y}$ represents the current amplitude of the medium.

## Wave Propagation Equation
We will implement a discretized version of the 2D Wave Equation:
$\frac{\partial^2 u}{\partial t^2} = c^2 \nabla^2 u$

In discrete form (finite difference):
$u(x, y, t+1) = 2u(x, y, t) - u(x, y, t-1) + c^2 \Delta t^2 \left[ \frac{u(x+1, y, t) - 2u(x, y, t) + u(x-1, y, t)}{\Delta x^2} + \frac{u(x, y+1, t) - 2u(x, y, t) + u(x, y-1, t)}{\Delta y^2} \right]$

### Simplified Update Step
$A_{new} = 2A_{curr} - A_{prev} + c^2 \cdot (\text{Laplacian}(A_{curr}))$

## Modifiers (Geometric Lenses & Dams)
- **Dams:** A binary mask $M_{dam}$ where $1.0$ is open and $0.0$ is a wall. We multiply the update by this mask.
- **Lenses:** A scalar field $C(x, y)$ where $c$ (wave speed) varies locally. This allows for refraction.

## White Noise Generator
A stochastic source $S(t)$ injected at specific boundary coordinates to "power" the computation.
