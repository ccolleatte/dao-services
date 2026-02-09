#!/usr/bin/env python3
"""
Generate BibTeX entries from arXiv metadata JSON files.
Format: Harvard author-date style for ACM AFT 2026 submission.
"""

import json
import os
from pathlib import Path
from typing import List, Dict


def load_metadata_files() -> List[Dict]:
    """Load all metadata.json files from arxiv-sources directory."""
    papers = []
    base_dir = Path(__file__).parent / "arxiv-sources"

    # Find all metadata.json files
    for metadata_file in base_dir.rglob("metadata.json"):
        with open(metadata_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
            if 'papers' in data and data['papers']:
                papers.extend(data['papers'])

    return papers


def generate_citation_key(paper: Dict) -> str:
    """Generate citation key in format: firstauthor{year}{keyword}"""
    # Extract first author's last name
    authors = paper.get('authors', [])
    if not authors:
        first_author = "unknown"
    else:
        first_author = authors[0].split(',')[0].split()[-1].lower()

    # Extract year from submitted_date
    submitted_date = paper.get('submitted_date', '2025-01-01')
    year = submitted_date.split('-')[0]

    # Extract keyword from title (first significant word)
    title = paper.get('title', '')
    # Remove common words
    stop_words = {'a', 'an', 'the', 'of', 'for', 'in', 'on', 'with', 'and', 'or', 'to'}
    words = [w.lower() for w in title.split() if w.lower() not in stop_words and len(w) > 3]
    keyword = words[0] if words else "paper"

    return f"{first_author}{year}{keyword}"


def format_authors_bibtex(authors: List[str]) -> str:
    """Format author list for BibTeX."""
    if not authors:
        return ""

    # BibTeX author format: "Last, First and Last, First and ..."
    formatted_authors = []
    for author in authors:
        # Authors are already in "Last, First" format
        formatted_authors.append(author.strip())

    return " and ".join(formatted_authors)


def generate_bibtex_entry(paper: Dict, citation_key: str) -> str:
    """Generate BibTeX entry for a single paper."""
    arxiv_id = paper.get('arxiv_id', '')
    title = paper.get('title', '').replace('{', '\\{').replace('}', '\\}')
    authors = format_authors_bibtex(paper.get('authors', []))
    year = paper.get('submitted_date', '2025-01-01').split('-')[0]
    abstract = paper.get('abstract', '').replace('{', '\\{').replace('}', '\\}')
    pdf_url = paper.get('pdf_url', f'https://arxiv.org/pdf/{arxiv_id}')

    # BibTeX entry format
    entry = f"""@misc{{{citation_key},
  author = {{{authors}}},
  title = {{{{{title}}}}},
  year = {{{year}}},
  eprint = {{{arxiv_id}}},
  archivePrefix = {{arXiv}},
  primaryClass = {{cs.GT}},
  url = {{{pdf_url}}},
  note = {{arXiv preprint}},
  abstract = {{{{{abstract}}}}}
}}
"""
    return entry


def generate_references_bib(output_file: str):
    """Generate references.bib file with all papers."""
    papers = load_metadata_files()

    print(f"Loaded {len(papers)} papers from metadata files")

    # Generate BibTeX entries
    bibtex_entries = []
    citation_keys_used = set()

    for paper in papers:
        citation_key = generate_citation_key(paper)

        # Handle duplicate citation keys
        original_key = citation_key
        counter = 2
        while citation_key in citation_keys_used:
            citation_key = f"{original_key}_{counter}"
            counter += 1

        citation_keys_used.add(citation_key)
        bibtex_entries.append(generate_bibtex_entry(paper, citation_key))

    # Write to file
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("% BibTeX Bibliography for DAO Project\n")
        f.write("% Auto-generated from arXiv metadata\n")
        f.write(f"% Total entries: {len(bibtex_entries)}\n")
        f.write("% Format: Harvard author-date style\n")
        f.write("% Last updated: 2026-02-09\n\n")

        for entry in bibtex_entries:
            f.write(entry)
            f.write("\n")

    print(f"Generated {len(bibtex_entries)} BibTeX entries")
    print(f"Output file: {output_file}")


if __name__ == "__main__":
    output_path = Path(__file__).parent / "references.bib"
    generate_references_bib(str(output_path))
    print("BibTeX generation complete!")
