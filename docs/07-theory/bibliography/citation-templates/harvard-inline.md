# Harvard Citation Style - Inline Reference Guide

**Project**: DAO Research
**Style**: Harvard (Author-Date)
**Last Updated**: 2026-02-09

---

## Basic Patterns

### Single Author

```markdown
Recent work on triangular voting (Smith, 2024) demonstrates...

Smith (2024) proposes a novel mechanism based on triangular numbers.
```

### Two Authors

```markdown
The quadratic voting framework (Lalley & Weyl, 2018) has been widely adopted...

Lalley and Weyl (2018) introduce quadratic voting as a solution to...
```

### Three or More Authors

```markdown
Empirical analysis of DAOs (Chen et al., 2023) reveals...

Chen et al. (2023) conduct a systematic study of 150 DAOs.
```

---

## Special Cases

### Corporate/Team Author

```markdown
The Polkadot whitepaper (Wood, 2016) describes...

According to Ethereum Foundation (2024), DAO governance requires...
```

### Multiple Works by Same Author (Same Year)

```markdown
Buterin (2024a) proposes..., while Buterin (2024b) extends this to...

Two recent papers (Buterin, 2024a, 2024b) explore different aspects.
```

### Multiple Citations in One Parenthetical

```markdown
Several studies (Smith, 2024; Jones, 2023; Chen et al., 2022) confirm...

Chronological order: (Wood, 2016; Lalley & Weyl, 2018; Smith, 2024)
```

### Page-Specific Citation

```markdown
As noted by Coase (1937, p. 390), transaction costs...

Smith (2024, pp. 12-15) provides detailed analysis of...
```

---

## arXiv Preprints

### Unpublished arXiv

```markdown
Recent work (Smith, 2024, arXiv:2405.12345) proposes...

Smith (2024, preprint) explores triangular voting mechanisms.
```

### arXiv with Published Version

```markdown
Jones (2023) introduces conviction voting [published as Jones, 2024]

The original arXiv version (Jones, 2023) differs from the published paper (Jones, 2024).
```

---

## Technical Context

### With Mathematical Notation

```markdown
The voting weight function $w(n) = \frac{n(n+1)}{2}$ (Smith, 2024) represents...

Smith (2024) proves that for triangular voting, the cost function satisfies:
$$C(k) = \sum_{i=1}^{k} i = \frac{k(k+1)}{2}$$
```

### With Algorithm/Protocol Reference

```markdown
The Polkadot consensus algorithm (Wood, 2016, §4.2) utilizes...

Following the GRANDPA finality gadget specification (Stewart & Wood, 2020)...
```

---

## Integration with BibTeX

### Citation Keys in Markdown

When writing, use citation keys that match `references.bib`:

```markdown
Triangular voting (smith2024triangular) offers advantages over quadratic voting
(lalley2018quadratic) in terms of manipulation resistance.
```

### Pandoc Conversion

```bash
# Convert Markdown to PDF with citations
pandoc phase3-theoretical-foundations.md \
  --bibliography=bibliography/references.bib \
  --citeproc \
  -o output.pdf
```

Pandoc will automatically convert citation keys to Harvard format:

```
Input:  (smith2024triangular)
Output: (Smith, 2024)
```

---

## Common Patterns in DAO Research

### Comparing Mechanisms

```markdown
While quadratic voting (Lalley & Weyl, 2018) uses $w(n) = \sqrt{n}$,
triangular voting (Smith, 2024) employs $w(n) = \frac{n(n+1)}{2}$,
and conviction voting (Jones, 2023) implements time-weighted accumulation.
```

### Empirical Studies

```markdown
Analysis of 150 DAOs (Chen et al., 2023) reveals that only 12% implement
sophisticated voting mechanisms beyond simple token-weighted voting.
```

### Theoretical Foundations

```markdown
Building on Coase's theory of the firm (Coase, 1937), recent work
(Buterin, 2024; Davidson et al., 2023) explores DAOs as a new
organizational form with minimal transaction costs.
```

### Security & Audit

```markdown
Formal verification techniques (Williams & Chen, 2023) using the K framework
can detect vulnerabilities that traditional audits miss (Patel et al., 2024).
```

---

## Quote Integration

### Direct Quote (Short)

```markdown
As Smith (2024, p. 15) notes, "triangular voting provides a middle ground
between linear and quadratic mechanisms."
```

### Direct Quote (Long, >40 words)

```markdown
Smith (2024, p. 15) elaborates on the benefits of triangular voting:

> Triangular voting provides a middle ground between linear and quadratic
> mechanisms. While quadratic voting may overcompensate for wealth concentration,
> linear voting fails to address it at all. The triangular function offers a
> tunable parameter that can be calibrated to the specific DAO context.
```

### Paraphrased

```markdown
The triangular voting mechanism balances the trade-off between manipulation
resistance and expressiveness (Smith, 2024).
```

---

## Citing Figures & Tables

```markdown
Figure 2 in Smith (2024) illustrates the cost curves for different voting mechanisms.

As shown in Table 3 (Chen et al., 2023), Moloch DAO exhibits the highest
participation rate among surveyed organizations.
```

---

## Citing Equations

```markdown
Equation (3) in Smith (2024) defines the cost function:

$$C(k) = \frac{k(k+1)}{2}$$ (Smith, 2024, Eq. 3)
```

---

## Multiple Works, Same Point

```markdown
This finding is consistent across multiple studies (Smith, 2024; Jones, 2023;
Chen et al., 2022), suggesting a robust pattern.
```

---

## Controversial Claims (Attribution)

```markdown
Some researchers argue that quadratic voting is vulnerable to collusion
(Weyl & Posner, 2017), though others dispute this claim (Smith, 2024;
Lalley & Weyl, 2019).
```

---

## Chains of Influence

```markdown
Following Coase (1937), subsequent work by Williamson (1985) and Hart (1995)
refined transaction cost theory. Recent extensions to DAOs (Buterin, 2024;
Davidson et al., 2023) apply these principles to blockchain governance.
```

---

## Common Abbreviations

- **et al.** - "and others" (3+ authors)
- **ibid.** - Avoid (use author-date instead)
- **op. cit.** - Avoid (use author-date instead)
- **cf.** - "compare with"
- **e.g.** - "for example"
- **i.e.** - "that is"
- **viz.** - "namely"

---

## Bibliography Section (End of Document)

### Automatic Generation (Pandoc)

Pandoc will generate this automatically from cited works:

```
## References

Buterin, V. (2024). Economics of Decentralized Autonomous Organizations.
   Ethereum Foundation Technical Report.

Chen, W., Smith, J., & Patel, R. (2023). Empirical Analysis of DAO Governance
   Mechanisms. *Proceedings of the 2023 ACM Conference on Economics and Computation*,
   45-62. https://doi.org/10.1145/3580507.3597820

Coase, R. H. (1937). The Nature of the Firm. *Economica*, 4(16), 386-405.

Lalley, S., & Weyl, E. G. (2018). Quadratic Voting: How Mechanism Design Can
   Radicalize Democracy. *AEA Papers and Proceedings*, 108, 33-37.

Smith, J. (2024). Triangular Voting in Decentralized Autonomous Organizations.
   arXiv preprint arXiv:2405.12345.

Wood, G. (2016). Polkadot: Vision for a Heterogeneous Multi-Chain Framework.
   White Paper. https://polkadot.network/PolkaDotPaper.pdf
```

### Manual Bibliography (Markdown)

If not using Pandoc, maintain alphabetical order by first author's last name:

```markdown
## References

Buterin, V. (2024)...
Chen, W., Smith, J., & Patel, R. (2023)...
Coase, R. H. (1937)...
[etc.]
```

---

## Validation Checklist

Before submitting paper:

- [ ] All citations have corresponding BibTeX entries
- [ ] No "?" in generated bibliography
- [ ] Author names spelled consistently
- [ ] Years match BibTeX entries
- [ ] arXiv preprints noted as such
- [ ] No broken DOI links
- [ ] Math notation renders correctly in PDF
- [ ] Quote page numbers provided for all direct quotes

---

## Tools

### BibTeX Validation

```bash
bibtex-tidy references.bib --check
```

### Citation Resolution Test

```bash
pandoc test.md --bibliography=references.bib --citeproc -o test.pdf
```

### Find Missing Citations

```bash
# Extract citation keys from Markdown
grep -o '(\w\+\d\{4\}\w*)' phase3-theoretical-foundations.md

# Check if they exist in references.bib
grep "^@" references.bib | grep -o '{[^,]*' | sed 's/{//'
```

---

**Reference**: Harvard Referencing Guide (Anglia Ruskin University, 2024)
**Pandoc**: https://pandoc.org/MANUAL.html#citations
