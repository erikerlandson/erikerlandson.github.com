---
layout: post
title: "Smooth Gradients for Cubic Hermite Splines"
date: 2013-03-16 07:39
comments: true
categories: [ computing, math, spline, cubic hermite spline, gradient ]
---
One of the advantages of cubic Hermite splines is that their interval interpolation formula is an explicit function of gradients $$ m_0, m_1, ... m_{n-1} $$ at knot-points:

$$
y(t) = h_{00}(t) y_j + h_{10}(t) m_j + h_{01}(t) y_{j+1} + h_{11}(t) m_{j+1} \\
$$

where the Hermite bases are:

$$
h_{00} = 2t^3 - 3t^2 + 1 \\
h_{10} = t^3 - 2t^2 + t \\
h_{01} = -2t^3 + 3t^2 \\
h_{11} = t^3 - t^2 \\
$$

(For now, I will be using the unit-interval form of the interpolation, where t runs from 0 to 1 on each interval.  I will also discuss the non-uniform interval equations below)

This formulation allows one to explicitly specify the interpolation gradient at each knot point, and to choose from various gradient assignment policies, for example [those listed here](http://en.wikipedia.org/wiki/Cubic_Hermite_spline#Interpolating_a_data_set), even supporting policies for [enforcing monotonic interpolations](http://en.wikipedia.org/wiki/Monotone_cubic_interpolation).

One important caveat with cubic Hermite splines is that although the gradient $$ y'(t) $$ is guaranteed to be continuous, it is _not_ guaranteed to be smooth (that is, differentiable) _across_ the knots (it is of course smooth _inside_ each interval). Therefore, another useful category of gradient policy is to obtain gradients $$ m_0, m_1, ... m_{n-1} $$ such that $$ y'(t) $$ is also smooth across knots.

(I feel sure that what follows was long since derived elsewhere, but my attempts to dig the formulation up on the internet failed, and so I decided the derivation might make a useful blog post)

To ensure smooth gradient across knot points, we want the 2nd derivative $$ y''(t) $$ to be equal at the boundaries of adjacent intervals:

$$
h_{00}^"(t) y_{j-1} + h_{10}^"(t) m_{j-1} + h_{01}^"(t) y_j + h_{11}^"(t) m_j \\
= \\
h_{00}^"(t) y_j + h_{10}^"(t) m_j + h_{01}^"(t) y_{j+1} + h_{11}^"(t) m_{j+1}
$$

or substituting the 2nd derivative of the basis definitions above:

$$\left( 12 t - 6 \right) y_{j-1} + \left( 6 t - 4 \right) m_{j-1}  + \left( 6 - 12 t \right) y_j + \left( 6 t - 2 \right) m_j \\
= \\
\left( 12 t - 6 \right) y_{j} + \left( 6 t - 4 \right) m_{j}  + \left( 6 - 12 t \right) y_{j+1} + \left( 6 t - 2 \right) m_{j+1}
$$

Observe that t = 1 on the left hand side of this equation, and t = 0 on the right side, and so we have:

$$
6 y_{j-1} + 2 m_{j-1} - 6 y_j + 4 m_j
=
-6 y_j - 4 m_j + 6 y_{j+1} - 2 m_{j+1}
$$

which we can rearrange as:

$$
2 m_{j-1} + 8 m_j + 2 m_{j+1}
=
6 \left( y_{j+1} - y_{j-1} \right)
$$

Given n knot points, the above equation holds for j = 1 to n-2 (using zero-based indexing, as nature intended).  Once we define equations for j = 0 and j = n-1, we will have a system of equations to solve.  There are two likely choices.  The first is to simply specify the endpoint gradients $$ m_0 = G $$ and $$ m_{n-1} = H $$ directly, which yields the following [tri-diagonal matrix equation:](http://en.wikipedia.org/wiki/Tridiagonal_matrix_algorithm)

$$
\left( \begin{array} {ccccc}
1 &   &   &   &   \\
2 & 8 & 2 &   &   \\
  & 2 & 8 & 2 &   \\
  &   & \vdots &   &   \\
  &   & 2 & 8 & 2 \\ 
  &   &   &   & 1 \\
\end{array} \right)

\left( \begin{array} {c}
m_0 \\
m_1 \\
 \\
\vdots \\
 \\
m_{n-1}
\end{array} \right)
=
\left( \begin{array} {c}
G \\
6 \left( y_2 - y_0 \right) \\
6 \left( y_3 - y_1 \right) \\
\vdots \\
6 \left( y_{n-1} - y_{n-3} \right) \\
H \\
\end{array} \right)
$$

The second common endpoint policy is to set the 2nd derivative equal to zero -- the "natural spline."   Setting the 2nd derivative to zero at the left-end knot (and t = 0) gives us:

$$
4 m_0 + 2 m_1   =   6 \left( y_1 - y_0 \right)
$$

Similarly, at the right-end knot (t = 1), we have:

$$
2 m_0 + 4 m_1   =   6 \left( y_{n-1} - y_{n-2} \right)
$$

And so for a natural spline endpoint policy the matrix equation looks like this:

$$
\left( \begin{array} {ccccc}
4 & 2 &   &   &   \\
2 & 8 & 2 &   &   \\
  & 2 & 8 & 2 &   \\
  &   & \vdots &   &   \\
  &   & 2 & 8 & 2 \\ 
  &   &   & 2 & 4 \\
\end{array} \right)

\left( \begin{array} {c}
m_0 \\
m_1 \\
 \\
\vdots \\
 \\
m_{n-1}
\end{array} \right)
=
\left( \begin{array} {c}
6 \left( y_1 - y_0 \right) \\
6 \left( y_2 - y_0 \right) \\
6 \left( y_3 - y_1 \right) \\
\vdots \\
6 \left( y_{n-1} - y_{n-3} \right) \\
6 \left( y_{n-1} - y_{n-2} \right) \\
\end{array} \right)
$$


The derivation above is for uniform (and unit) intervals, where t runs from 0 to 1 on each knot interval.  I'll now discuss the variation where knot intervals are non-uniform.   The non-uniform form of the interpolation equation is:

$$
y(x) = h_{00}(t) y_j + h_{10}(t) d_j m_j + h_{01}(t) y_{j+1} + h_{11}(t) d_j m_{j+1} \\
\text{ } \\
\text{where:} \\
\text{ }  \\
d_j = x_{j+1} - x_j \text{  for  } j = 0, 1, ... n-2 \\
t = (x - x_j) / d_j
$$

Taking $$ t = t(x) $$ and applying the chain rule, we see that 2nd derivative equation now looks like:

$$
y''(x) = \frac { \left( 12 t - 6 \right) y_{j} + \left( 6 t - 4 \right) d_j m_{j}  + \left( 6 - 12 t \right) y_{j+1} + \left( 6 t - 2 \right) d_j m_{j+1} } { d_j^2 }
$$

Applying a derivation similar to the above, we find that our (interior) equations look like this:

$$
\frac {2} { d_{j-1} }  m_{j-1} + \left( \frac {4} { d_{j-1} } + \frac {4} { d_j } \right) m_j + \frac {2} {d_j} m_{j+1}
=
\frac { 6 \left( y_{j+1} - y_{j} \right) } { d_j^2 } + \frac { 6 \left( y_{j} - y_{j-1} \right) } { d_{j-1}^2 }
$$

and natural spline endpoint equations are:

$$
\text{left:  } \frac {4} {d_0} m_0 + \frac {2} {d_0} m_1   =   \frac {6 \left( y_1 - y_0 \right)} {d_0^2} \\
\text{right: } \frac {2} {d_{n-2}} m_0 + \frac {4} {d_{n-2}} m_1   =   \frac {6 \left( y_{n-1} - y_{n-2} \right)} {d_{n-2}^2}
$$

And so the matrix equation for specified endpoint gradients is:

$$
\small
\left( \begin{array} {ccccc}
\normalsize 1 \scriptsize &   &   &   &   \\
\frac{2}{d_0} & \frac{4}{d_0} {+} \frac{4}{d_1} & \frac{2}{d_1} &   &   \\
  & \frac{2}{d_1} & \frac{4}{d_1} {+} \frac{4}{d_2} & \frac{2}{d_2} &   \\
  &   & \vdots &   &   \\
  &   & \frac{2}{d_{n-3}} & \frac{4}{d_{n-3}} {+} \frac{4}{d_{n-2}} & \frac{2}{d_{n-2}} \\ 
  &   &   &   & \normalsize 1 \scriptsize \\
\end{array} \right)

\left( \begin{array} {c}
m_0 \\
m_1 \\
 \\
\vdots \\
 \\
m_{n-1}
\end{array} \right)
=
\left( \begin{array} {c}
G \\
6 \left( \frac{y_2 {-} y_1}{d_1^2} {+} \frac{y_1 {-} y_0}{d_0^2} \right) \\
6 \left( \frac{y_3 {-} y_2}{d_2^2} {+} \frac{y_2 {-} y_1}{d_1^2} \right)  \\
\vdots \\
6 \left( \frac{y_{n-1} {-} y_{n-2}}{d_{n-2}^2} {+} \frac{y_{n-2} {-} y_{n-3}}{d_{n-3}^2} \right) \\
H \\
\end{array} \right)
\normalsize
$$

And the equation for natural spline endpoints is:

$$
\small
\left( \begin{array} {ccccc}
\frac{4}{d_0} & \frac{2}{d_0}  &   &   &   \\
\frac {2} {d_0} & \frac {4} {d_0} {+} \frac {4} {d_1} & \frac{2}{d_1} &   &   \\
  & \frac{2}{d_1} & \frac{4}{d_1} {+} \frac{4}{d_2} & \frac{2}{d_2} &   \\
  &   & \vdots &   &   \\
  &   & \frac{2}{d_{n-3}} & \frac{4}{d_{n-3}} {+} \frac{4}{d_{n-2}} & \frac{2}{d_{n-2}} \\ 
  &   &   & \frac{2}{d_{n-2}} & \frac{4}{d_{n-2}} \\
\end{array} \right)

\left( \begin{array} {c}
m_0 \\
m_1 \\
 \\
\vdots \\
 \\
m_{n-1}
\end{array} \right)
=
\left( \begin{array} {c}
\frac{6 \left( y_1 {-} y_0 \right)}{d_0^2} \\
6 \left( \frac{y_2 {-} y_1}{d_1^2}  {+}  \frac{y_1 {-} y_0}{d_0^2} \right) \\
6 \left( \frac{y_3 {-} y_2}{d_2^2}  {+}  \frac{y_2 {-} y_1}{d_1^2} \right)  \\
\vdots \\
6 \left( \frac{y_{n-1} {-} y_{n-2}}{d_{n-2}^2}  {+}  \frac{y_{n-2} {-} y_{n-3}}{d_{n-3}^2} \right) \\
\frac{6 \left( y_{n-1} {-} y_{n-2} \right)}{d_{n-2}^2} \\
\end{array} \right)
\normalsize
$$
