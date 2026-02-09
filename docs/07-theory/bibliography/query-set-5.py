#!/usr/bin/env python3
"""
Query Set 5: Peripheral Topics
Execute 4 arXiv queries for voting mechanisms, tokenomics, mechanism design, and cryptoeconomics.
"""

import urllib.request
import urllib.parse
import xml.etree.ElementTree as ET
import json
import time
from pathlib import Path
from typing import List, Dict

# arXiv API configuration
ARXIV_API_BASE = "http://export.arxiv.org/api/query"
RATE_LIMIT_DELAY = 3  # seconds between requests

# Query Set 5 definitions - Peripheral Topics
QUERIES = [
    {
        "query_id": "5A",
        "description": "Voting Mechanisms (quadratic, conviction, liquid democracy)",
        "query_string": "cat:cs.GT OR cat:econ.TH AND (ti:\"quadratic voting\" OR ti:\"conviction voting\" OR ti:\"liquid democracy\" OR ti:\"voting mechanism\") AND submittedDate:[2020 TO 2025]",
        "max_results": 15
    },
    {
        "query_id": "5B",
        "description": "Tokenomics (velocity, bonding curves, dual-token models)",
        "query_string": "cat:econ.TH OR cat:cs.CR AND (ti:tokenomics OR ti:\"token velocity\" OR ti:\"bonding curve\" OR ti:\"token model\") AND abs:blockchain AND submittedDate:[2022 TO 2025]",
        "max_results": 12
    },
    {
        "query_id": "5C",
        "description": "Mechanism Design (incentive compatibility, game theory)",
        "query_string": "cat:cs.GT AND (ti:\"mechanism design\" OR ti:\"incentive compatible\") AND (abs:blockchain OR abs:decentralized) AND submittedDate:[2022 TO 2025]",
        "max_results": 18
    },
    {
        "query_id": "5D",
        "description": "Cryptoeconomics (staking, slashing, economic security)",
        "query_string": "cat:cs.CR OR cat:econ.TH AND (ti:staking OR ti:slashing OR ti:\"economic security\" OR ti:cryptoeconomics) AND abs:blockchain AND submittedDate:[2022 TO 2025]",
        "max_results": 12
    }
]


def fetch_arxiv_papers(query_string: str, max_results: int) -> List[Dict]:
    """Fetch papers from arXiv API."""
    encoded_query = urllib.parse.quote_plus(query_string)
    url = f"{ARXIV_API_BASE}?search_query={encoded_query}&max_results={max_results}&sortBy=submittedDate&sortOrder=descending"

    print(f"  Fetching from arXiv API (max {max_results} results)...")

    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Academic Research Bot)'})
        with urllib.request.urlopen(req, timeout=30) as response:
            xml_data = response.read().decode('utf-8')

        # Parse XML
        root = ET.fromstring(xml_data)
        ns = {'atom': 'http://www.w3.org/2005/Atom', 'arxiv': 'http://arxiv.org/schemas/atom'}

        papers = []
        entries = root.findall('atom:entry', ns)

        for entry in entries:
            # Extract arXiv ID
            arxiv_url = entry.find('atom:id', ns).text
            arxiv_id = arxiv_url.split('/abs/')[-1]

            # Extract metadata
            title = entry.find('atom:title', ns).text.strip().replace('\n', ' ')
            abstract = entry.find('atom:summary', ns).text.strip().replace('\n', ' ')

            # Authors
            authors = []
            for author in entry.findall('atom:author', ns):
                name = author.find('atom:name', ns).text
                authors.append(name)

            # Submitted date
            published = entry.find('atom:published', ns).text[:10]  # YYYY-MM-DD

            # Categories
            categories = [cat.get('term') for cat in entry.findall('atom:category', ns)]

            # PDF URL
            pdf_link = entry.find('atom:link[@title="pdf"]', ns)
            pdf_url = pdf_link.get('href') if pdf_link is not None else f"https://arxiv.org/pdf/{arxiv_id}.pdf"

            papers.append({
                "arxiv_id": arxiv_id,
                "title": title,
                "authors": authors,
                "submitted_date": published,
                "categories": categories,
                "abstract": abstract,
                "pdf_url": pdf_url
            })

        print(f"  Found {len(papers)} papers")
        return papers

    except Exception as e:
        print(f"  ERROR: {str(e)}")
        return []


def score_paper(paper: Dict, query_context: str) -> Dict:
    """
    Score paper relevance (1-10 scale).
    Returns: {score: int, breakdown: dict, notes: str}
    """
    title_lower = paper['title'].lower()
    abstract_lower = paper['abstract'].lower()

    # Component 1: Topic Match (1-3 points)
    topic_keywords = {
        "5A": ["voting", "quadratic", "conviction", "liquid democracy", "delegation"],
        "5B": ["tokenomics", "token", "bonding curve", "velocity", "dual-token"],
        "5C": ["mechanism design", "incentive", "game theory", "auction", "allocation"],
        "5D": ["staking", "slashing", "validator", "cryptoeconomics", "economic security"]
    }

    keywords = topic_keywords.get(query_context, [])
    keyword_matches = sum(1 for kw in keywords if kw in title_lower or kw in abstract_lower)
    topic_match = min(3, 1 + keyword_matches // 2)

    # Component 2: Methodology Rigor (1-3 points)
    rigor_indicators = ["formal", "proof", "theorem", "model", "framework", "analysis", "empirical"]
    rigor_count = sum(1 for indicator in rigor_indicators if indicator in abstract_lower)
    methodology_rigor = min(3, 1 + rigor_count // 2)

    # Component 3: Citation Potential (1-2 points)
    high_impact_terms = ["novel", "comprehensive", "survey", "systematic", "state-of-the-art"]
    citation_potential = 2 if any(term in abstract_lower for term in high_impact_terms) else 1

    # Component 4: Recency (1-2 points)
    year = int(paper['submitted_date'][:4])
    recency = 2 if year >= 2024 else 1

    # Total score
    total_score = topic_match + methodology_rigor + citation_potential + recency

    # Generate notes
    if total_score >= 9:
        priority = "HIGH"
    elif total_score >= 7:
        priority = "MEDIUM"
    else:
        priority = "LOW"

    notes = f"{priority} - "
    if topic_match == 3:
        notes += "Strong topic alignment. "
    if methodology_rigor == 3:
        notes += "Rigorous methodology. "
    if citation_potential == 2:
        notes += "High citation potential. "

    return {
        "relevance_score": total_score,
        "scoring_breakdown": {
            "topic_match": topic_match,
            "methodology_rigor": methodology_rigor,
            "citation_potential": citation_potential,
            "recency": recency
        },
        "notes": notes.strip()
    }


def main():
    print("\n" + "="*60)
    print("QUERY SET 5: PERIPHERAL TOPICS")
    print("="*60)

    # Create output directory structure
    base_dir = Path("arxiv-sources/05-peripheral-topics")
    subdirs = {
        "5A": "voting-mechanisms",
        "5B": "tokenomics",
        "5C": "mechanism-design",
        "5D": "cryptoeconomics"
    }

    all_papers = {}

    for query_def in QUERIES:
        print(f"\n[{query_def['query_id']}] {query_def['description']}")
        print(f"  Query: {query_def['query_string'][:80]}...")

        # Fetch papers
        papers = fetch_arxiv_papers(query_def['query_string'], query_def['max_results'])

        if not papers:
            print(f"  WARNING: No papers found for query {query_def['query_id']}")
            continue

        # Score papers
        scored_papers = []
        for paper in papers:
            score_data = score_paper(paper, query_def['query_id'])
            paper.update(score_data)

            # Add default metadata
            paper['tags'] = []
            paper['citation_count'] = 0
            paper['integration_status'] = 'pending_review'
            paper['pdf_stored_locally'] = False

            scored_papers.append(paper)

        # Filter papers >= 7/10
        high_relevance = [p for p in scored_papers if p['relevance_score'] >= 7]
        print(f"  High relevance (>=7/10): {len(high_relevance)}/{len(scored_papers)} papers")

        all_papers[query_def['query_id']] = high_relevance

        # Rate limiting
        if query_def != QUERIES[-1]:  # Don't delay after last query
            print(f"  Rate limiting: waiting {RATE_LIMIT_DELAY}s...")
            time.sleep(RATE_LIMIT_DELAY)

    # Save metadata per subcategory
    for query_id, subdir in subdirs.items():
        papers_subset = all_papers.get(query_id, [])
        if not papers_subset:
            continue

        output_dir = base_dir / subdir / "2024-2025"
        output_dir.mkdir(parents=True, exist_ok=True)

        metadata = {
            "topic": subdir,
            "time_period": "2024-2025",
            "last_updated": "2026-02-09T19:30:00Z",
            "total_papers": len(papers_subset),
            "curation_status": "Phase 1 - Complete",
            "priority": "P3 - Peripheral topics",
            "papers": papers_subset
        }

        output_file = output_dir / "metadata.json"
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(metadata, f, indent=2, ensure_ascii=False)

        print(f"\nMetadata saved to: {output_file}")
        print(f"  Papers: {len(papers_subset)}")

    # Total summary
    total_papers = sum(len(papers) for papers in all_papers.values())
    print(f"\n" + "="*60)
    print(f"TOTAL PAPERS CURATED: {total_papers}")
    print("="*60)

    # Score distribution per subcategory
    for query_id, papers_subset in all_papers.items():
        if not papers_subset:
            continue

        score_dist = {}
        for paper in papers_subset:
            score = paper['relevance_score']
            score_dist[score] = score_dist.get(score, 0) + 1

        print(f"\n[{query_id}] Score Distribution:")
        for score in sorted(score_dist.keys(), reverse=True):
            count = score_dist[score]
            bar = "#" * count
            print(f"  {score}/10: {bar} ({count} papers)")


if __name__ == "__main__":
    main()
