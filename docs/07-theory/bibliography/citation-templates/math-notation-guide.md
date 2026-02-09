# Mathematical Notation Guide for Academic Papers

**Project**: DAO Research
**Format**: LaTeX Math Mode (Pandoc/Markdown compatible)
**Last Updated**: 2026-02-09

---

## Purpose

This guide provides LaTeX math notation conventions for DAO research papers, ensuring consistency across `phase3-theoretical-foundations.md` and future publications.

---

## Inline vs Display Math

### Inline Math (Within Text)

Use single dollar signs `$...$`:

```markdown
The triangular number formula $T(n) = \frac{n(n+1)}{2}$ represents...

For a voter holding $n$ tokens, the voting weight is $w(n) = T(n)$.
```

**Renders as**: The triangular number formula T(n) = n(n+1)/2 represents...

---

### Display Math (Standalone)

Use double dollar signs `$$...$$`:

```markdown
The cost function for $k$ votes is defined as:

$$C(k) = \sum_{i=1}^{k} i = \frac{k(k+1)}{2}$$
```

**Renders as**:

C(k) = Σᵢ₌₁ᵏ i = k(k+1)/2

---

## Common Notation for DAO Research

### Voting Mechanisms

```latex
% Token holdings
n, m, t

% Voting weight function
w(n) = \frac{n(n+1)}{2}

% Cost function (tokens required for k votes)
C(k) = \frac{k(k+1)}{2}

% Quadratic voting (for comparison)
w_{QV}(n) = \sqrt{n}
C_{QV}(k) = k^2

% Conviction voting (time-weighted)
CV(t, n) = n \cdot f(t)
\text{where } f(t) = 1 - e^{-\alpha t}
```

### Game Theory

```latex
% Utility function
U_i(a_i, a_{-i}) = v_i(a) - c_i(a_i)

% Nash equilibrium
a^* \in \text{NE} \iff U_i(a_i^*, a_{-i}^*) \geq U_i(a_i, a_{-i}^*) \; \forall i, a_i

% Incentive compatibility
U_i(\theta_i, \theta_i) \geq U_i(\theta_i, \hat{\theta}_i) \; \forall \hat{\theta}_i

% Social welfare
W = \sum_{i=1}^{n} U_i
```

### Mechanism Design

```latex
% Mechanism
M = (\Theta, A, g, t)

% Allocation function
g: \Theta \to A

% Payment function
t: \Theta \to \mathbb{R}^n

% Expected utility
\mathbb{E}[U_i(\theta_i)] = \mathbb{E}[v_i(g(\theta)) - t_i(\theta)]
```

### Probability & Statistics

```latex
% Probability
P(A), P(A|B)

% Expected value
\mathbb{E}[X], \mathbb{E}[X|Y]

% Variance
\text{Var}(X) = \mathbb{E}[(X - \mathbb{E}[X])^2]

% Cumulative distribution
F(x) = P(X \leq x)
```

### Sets & Relations

```latex
% Set membership
x \in S, x \notin S

% Subset
A \subseteq B, A \subset B

% Set operations
A \cup B, A \cap B, A \setminus B

% Cardinality
|S|, \#S

% Real numbers
\mathbb{R}, \mathbb{R}^n, \mathbb{R}_{+}

% Natural numbers
\mathbb{N}, \mathbb{N}_0
```

---

## Greek Letters (Common in Economics/CS)

```latex
% Lowercase
\alpha, \beta, \gamma, \delta, \epsilon, \theta, \lambda, \mu, \sigma

% Uppercase
\Gamma, \Delta, \Theta, \Lambda, \Sigma

% Examples in context
\alpha \text{-fairness criterion}
\beta \text{-decay factor in conviction voting}
\gamma \text{-discount factor}
\theta \text{-type (private information)}
\lambda \text{-arrival rate (Poisson process)}
```

---

## Operators & Symbols

### Arithmetic

```latex
% Basic
+, -, \times, \div

% Fractions
\frac{a}{b}

% Exponents
n^2, e^{-\alpha t}

% Roots
\sqrt{n}, \sqrt[3]{n}
```

### Summation & Products

```latex
% Summation
\sum_{i=1}^{n} x_i

% Product
\prod_{i=1}^{n} x_i

% Limits
\lim_{n \to \infty} f(n)
```

### Comparisons

```latex
% Inequalities
<, >, \leq, \geq, \neq

% Approximately
\approx, \sim

% Proportional
\propto
```

### Logic

```latex
% Logical AND/OR
\land, \lor, \neg

% Implies
\implies, \Rightarrow

% For all/exists
\forall, \exists
```

---

## Equation Numbering

### Pandoc (Automatic)

```markdown
The cost function is:

$$C(k) = \frac{k(k+1)}{2}$$ {#eq:triangular-cost}

As shown in Equation {@eq:triangular-cost}, the cost grows quadratically.
```

### Manual (Without Auto-numbering)

```markdown
$$C(k) = \frac{k(k+1)}{2} \quad \text{(1)}$$

As shown in Equation (1), the cost grows quadratically.
```

---

## Multi-line Equations

### Aligned Equations

```latex
$$
\begin{aligned}
C(k) &= \sum_{i=1}^{k} i \\
     &= \frac{k(k+1)}{2} \\
     &= \frac{k^2 + k}{2}
\end{aligned}
$$
```

### Cases (Piecewise Functions)

```latex
$$
w(n) = \begin{cases}
  0 & \text{if } n = 0 \\
  \frac{n(n+1)}{2} & \text{if } n > 0
\end{cases}
$$
```

---

## Matrices

```latex
$$
A = \begin{bmatrix}
  a_{11} & a_{12} \\
  a_{21} & a_{22}
\end{bmatrix}
$$

% Determinant
\det(A) = a_{11}a_{22} - a_{12}a_{21}
```

---

## Vectors

```latex
% Column vector
\mathbf{v} = \begin{pmatrix} v_1 \\ v_2 \\ v_3 \end{pmatrix}

% Row vector
\mathbf{w} = (w_1, w_2, w_3)

% Dot product
\mathbf{v} \cdot \mathbf{w} = \sum_{i=1}^{n} v_i w_i

% Norm
\|\mathbf{v}\| = \sqrt{\sum_{i=1}^{n} v_i^2}
```

---

## Text in Math Mode

```latex
% Use \text{} for words
w(n) = \frac{n(n+1)}{2} \text{ tokens}

% Use \quad or \qquad for spacing
x = 5 \quad \text{(initial value)}

% Use \text{if/where/such that}
U_i = v_i - c_i \text{ where } v_i \text{ is the valuation}
```

---

## Common DAO Research Formulas

### 1. Triangular Voting Cost

```latex
$$
C_{\text{triangular}}(k) = \frac{k(k+1)}{2}
$$

Tokens required to cast $k$ votes.
```

### 2. Quadratic Voting Cost (Comparison)

```latex
$$
C_{\text{quadratic}}(k) = k^2
$$

Quadratic voting requires more tokens for the same number of votes.
```

### 3. Conviction Voting Accumulation

```latex
$$
CV_i(t) = n_i \cdot (1 - e^{-\alpha t})
$$

Where $n_i$ is token stake and $\alpha$ is decay parameter.
```

### 4. Token-Weighted Voting (Baseline)

```latex
$$
w_{\text{linear}}(n) = n
$$

Simple 1 token = 1 vote.
```

### 5. Comparative Cost Analysis

```latex
$$
\frac{C_{\text{triangular}}(k)}{C_{\text{quadratic}}(k)} = \frac{k+1}{2k}
\quad \xrightarrow{k \to \infty} \quad \frac{1}{2}
$$

Triangular voting is asymptotically half the cost of quadratic voting.
```

### 6. Manipulation Resistance (Shapley Value)

```latex
$$
\phi_i(v) = \sum_{S \subseteq N \setminus \{i\}} \frac{|S|!(n-|S|-1)!}{n!} [v(S \cup \{i\}) - v(S)]
$$

Power index for voter $i$ in a voting game.
```

### 7. Quorum Requirement

```latex
$$
Q_{\text{min}} = \lceil \theta \cdot T \rceil
$$

Where $\theta$ is quorum threshold (e.g., 0.15) and $T$ is total token supply.
```

### 8. Expected Turnout Model

```latex
$$
P(\text{turnout}) = 1 - e^{-\lambda \cdot \text{stake}}
$$

Exponential model linking stake size to participation probability.
```

---

## Theorems & Proofs

### Theorem Statement

```markdown
**Theorem 1** (Triangular Voting Optimality). For a DAO with $n$ voters and
budget constraint $B$, triangular voting maximizes social welfare under the
assumptions:

$$
\max \sum_{i=1}^{n} U_i \quad \text{s.t.} \quad \sum_{i=1}^{n} C(k_i) \leq B
$$

**Proof**. (Sketch) By Lagrangian optimization... $\square$
```

---

## Rendering Tips

### Pandoc Conversion

```bash
# Convert Markdown with math to PDF
pandoc phase3-theoretical-foundations.md \
  --bibliography=bibliography/references.bib \
  --citeproc \
  --mathjax \
  -o output.pdf
```

### Common Errors

1. **Unescaped underscores**: Use `\_` outside math mode
2. **Missing brackets**: `$\frac{a}{b}$` not `$\frac a b$`
3. **Inline display math**: Don't use `$$` inline (use `$`)
4. **Text without \text{}**: `w(n) = tokens` → `w(n) \text{ tokens}`

---

## Accessibility

### Alt Text for Complex Equations

```markdown
$$C(k) = \frac{k(k+1)}{2}$$

*Figure 1*: Cost function for triangular voting, where $k$ is the number of
votes and $C(k)$ is the total token cost.
```

---

## Reference

- **LaTeX Math**: https://en.wikibooks.org/wiki/LaTeX/Mathematics
- **Pandoc Math**: https://pandoc.org/MANUAL.html#math
- **MathJax**: https://docs.mathjax.org/en/latest/

---

**Maintainer**: DAO Research Team
**Version**: 1.0.0
