# Academic Bibliography - DAO Research Project

**Last Updated**: 2026-02-09
**Total Sources**: 16 (traditional venues) + TBD (arXiv)
**Target**: 200+ comprehensive sources

---

## Purpose

This directory maintains a comprehensive academic bibliography for the DAO research project, supporting:

1. **Theoretical foundations** for governance mechanisms (triangular voting, conviction voting)
2. **Literature review** for Q2-Q4 2026 publications (ACM AFT, IEEE Blockchain, Journal)
3. **Cross-referencing** with `/docs/07-theory/phase3-theoretical-foundations.md`
4. **Long-term research archive** for PhD-level depth

---

## Structure Overview

```
bibliography/
├── README.md                    # This file - navigation guide
├── references.bib               # Master BibTeX file (all sources)
│
├── arxiv-sources/               # arXiv papers organized by theme/period
│   ├── 01-dao-governance/
│   ├── 02-blockchain-protocols/
│   ├── 03-smart-contract-security/
│   ├── 04-theory-of-firm/
│   └── 05-peripheral-topics/
│
├── traditional-venues/          # IEEE, ACM, journals (migrated from existing)
│   ├── ieee.bib
│   ├── acm.bib
│   └── journals.bib
│
└── citation-templates/          # BibTeX templates and citation guides
    ├── harvard-inline.md
    ├── bibtex-entry-templates.bib
    └── math-notation-guide.md
```

---

## Taxonomy

### Core Domains (arXiv Focus)

| Domain | Scope | Target Papers |
|--------|-------|---------------|
| **01 - DAO Governance** | Voting mechanisms, governance frameworks, participation economics | 40-50 |
| **02 - Blockchain Protocols** | Consensus algorithms, scalability, interoperability | 20-30 |
| **03 - Smart Contract Security** | Formal verification, attack taxonomies, audit tools | 30-40 |
| **04 - Theory of the Firm** | Coase theorem extensions, organizational economics, DAO as firm | 15-20 |
| **05 - Peripheral Topics** | Voting theory, tokenomics, mechanism design, cryptoeconomics | 40-50 |

**Total arXiv Target**: 145-190 papers
**Total with Traditional**: 200+ papers

---

## Time Periods

Each core domain is subdivided by submission period:

- **2024-2025** (Recent) - Priority for Q2 2026 publications
- **2020-2023** (Foundational) - Established baseline research

Papers pre-2020 are included selectively for seminal works only.

---

## Metadata Schema

Each `metadata.json` file follows this structure:

```json
{
  "topic": "dao-governance",
  "time_period": "2024-2025",
  "last_updated": "2026-02-09T10:00:00Z",
  "total_papers": 25,
  "papers": [
    {
      "arxiv_id": "2405.12345",
      "title": "Paper Title",
      "authors": ["Last, First", "Last, First"],
      "submitted_date": "2024-05-15",
      "categories": ["cs.CR", "cs.CY"],
      "abstract": "...",
      "pdf_url": "https://arxiv.org/pdf/2405.12345.pdf",
      "relevance_score": 9,
      "tags": ["voting", "governance"],
      "citation_count": 12,
      "notes": "...",
      "integration_status": "pending_review|reviewed|cited|archived",
      "pdf_stored_locally": false
    }
  ]
}
```

---

## Relevance Scoring (1-10 Scale)

| Score | Criteria | Action |
|-------|----------|--------|
| **9-10** | CRITICAL - Direct contribution, novel methodology, high citations | Summary + BibTeX + PDF storage |
| **7-8** | HIGH - Strong relevance, solid methodology, moderate citations | Summary + BibTeX (no PDF) |
| **5-6** | MEDIUM - Tangential relevance, standard methodology | Metadata only |
| **1-4** | LOW - Weak relevance, poor methodology | Archive or skip |

**PDF Storage Policy**: Only papers scoring ≥8/10 are stored locally (target: 30-50 PDFs = 60-100 MB).

---

## Citation Workflow

### 1. Discovery (via MCP arXiv)

```bash
# Example query
mcp-arxiv search --query "cat:cs.CR AND ti:DAO AND submittedDate:[2024 TO 2025]" --max-results 50
```

### 2. Metadata Extraction

For each paper of interest:
- Fetch full metadata via arXiv API
- Score relevance (1-10)
- Add to `metadata.json`

### 3. Summary Generation (≥7/10 papers)

Write 1-paragraph summary (150-200 words) in `summaries.md`:
- Problem addressed
- Approach/methodology
- Key results/contributions
- Relevance to project

### 4. BibTeX Entry (≥7/10 papers)

Add to `references.bib` using citation key format:
`{firstauthorlastname}{year}{keyword}`

Example:
```bibtex
@misc{smith2024triangular,
  author       = {Smith, John and Doe, Alice},
  title        = {Triangular Voting in Decentralized Organizations},
  year         = {2024},
  eprint       = {2405.12345},
  archivePrefix = {arXiv},
  primaryClass = {cs.CR},
  url          = {https://arxiv.org/abs/2405.12345}
}
```

### 5. PDF Storage (≥8/10 papers only)

- Download from `https://arxiv.org/pdf/{arxiv_id}.pdf`
- Rename to `{citationkey}.pdf`
- Store in `{topic}/{period}/pdfs/`
- Update `pdf_stored_locally: true` in metadata

### 6. Integration Status

```
pending_review → reviewed → cited → archived
```

---

## Using Citations in Documentation

### Inline Citation (Harvard Style)

```markdown
Recent work on triangular voting (Smith et al., 2024) demonstrates...
```

### Bibliography Generation (Pandoc)

```bash
cd C:\dev\DAO\docs\07-theory

pandoc phase3-theoretical-foundations.md \
  --bibliography=bibliography/references.bib \
  --citeproc \
  -o phase3-with-citations.pdf
```

---

## Maintenance Schedule

### Weekly (Automated - Phase 4)
- Monitor arXiv RSS feeds
- Author alerts (key researchers)
- Update citation counts via Semantic Scholar API

### Monthly (Manual)
- Execute bulk queries (top 20 new papers/topic)
- Relevance scoring
- Update summaries + BibTeX

### Quarterly (Comprehensive)
- Taxonomy review (new sub-topics?)
- Quality audit (obsolete papers → archive)
- Publication alignment (prioritize for Q2-Q4 papers)
- Citation refresh

---

## Validation Commands

### BibTeX Syntax Check
```bash
bibtex-tidy references.bib --check
```

### Count Entries
```bash
grep -c "^@" references.bib
```

### Check Duplicates
```bash
bibtex-tidy references.bib --duplicates
```

### Pandoc Citation Test
```bash
pandoc test.md --bibliography=references.bib --citeproc -o test.pdf
```

---

## Statistics (Updated Post-Curation)

**Traditional Venues** (Migrated):
- IEEE: 8 papers
- ACM: 8 papers
- Journals: TBD

**arXiv Sources** (Target):
- DAO Governance: 40-50
- Blockchain Protocols: 20-30
- Smart Contract Security: 30-40
- Theory of Firm: 15-20
- Peripheral Topics: 40-50

**PDFs Stored Locally**: TBD / 30-50 target

**Last Curation**: TBD

---

## Related Documentation

- **Main theoretical foundations**: `../phase3-theoretical-foundations.md`
- **Visual explainers**: `../phase3-visual-explainers.md`
- **Citation templates**: `citation-templates/`

---

## Contributing Guidelines

When adding new sources:

1. **Verify no duplicates** in `references.bib` (check citation key)
2. **Score relevance** honestly (1-10 scale)
3. **Write summaries** for papers ≥7/10 only
4. **Store PDFs** for papers ≥8/10 only
5. **Update metadata** with `integration_status`
6. **Validate BibTeX** with `bibtex-tidy --check`

---

**Maintainer**: DAO Research Team
**Version**: 1.0.0
**Next Review**: Post-Phase 1 completion (Week 2)
