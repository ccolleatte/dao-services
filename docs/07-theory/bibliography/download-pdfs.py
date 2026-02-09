#!/usr/bin/env python3
"""
Download PDFs for papers scoring ≥8/10 relevance.
Implements rate limiting and graceful error handling.
"""

import json
import os
import time
import urllib.request
import urllib.error
from pathlib import Path
from typing import List, Dict, Tuple


def load_metadata_files() -> List[Tuple[Path, Dict]]:
    """Load all metadata.json files with their paths."""
    metadata_files = []
    base_dir = Path(__file__).parent / "arxiv-sources"

    for metadata_file in base_dir.rglob("metadata.json"):
        with open(metadata_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
            if 'papers' in data and data['papers']:
                metadata_files.append((metadata_file, data))

    return metadata_files


def filter_high_scoring_papers(metadata_files: List[Tuple[Path, Dict]]) -> List[Dict]:
    """Filter papers with relevance_score ≥ 8."""
    high_scoring = []

    for metadata_path, data in metadata_files:
        topic_dir = metadata_path.parent
        for paper in data['papers']:
            if paper.get('relevance_score', 0) >= 8:
                # Add directory context
                paper['_topic_dir'] = str(topic_dir)
                paper['_metadata_file'] = str(metadata_path)
                high_scoring.append(paper)

    return high_scoring


def download_pdf(paper: Dict, output_dir: Path, delay: float = 3.0) -> bool:
    """
    Download PDF for a single paper with rate limiting.

    Args:
        paper: Paper metadata dict
        output_dir: Directory to save PDF
        delay: Delay in seconds between requests (rate limiting)

    Returns:
        True if successful, False otherwise
    """
    arxiv_id = paper.get('arxiv_id', '')
    pdf_url = paper.get('pdf_url', f'https://arxiv.org/pdf/{arxiv_id}')

    # Sanitize filename
    safe_id = arxiv_id.replace('/', '_')
    pdf_filename = f"{safe_id}.pdf"
    pdf_path = output_dir / pdf_filename

    # Skip if already downloaded
    if pdf_path.exists():
        print(f"  [SKIP] {arxiv_id} - already exists")
        return True

    # Create output directory if needed
    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"  [DOWNLOAD] {arxiv_id} from {pdf_url}")

    try:
        # Rate limiting delay
        time.sleep(delay)

        # Download with timeout
        req = urllib.request.Request(
            pdf_url,
            headers={'User-Agent': 'Mozilla/5.0 (Academic Research Bot)'}
        )

        with urllib.request.urlopen(req, timeout=30) as response:
            if response.status == 200:
                with open(pdf_path, 'wb') as f:
                    f.write(response.read())
                print(f"  [SUCCESS] {arxiv_id} saved to {pdf_path.name}")
                return True
            else:
                print(f"  [ERROR] {arxiv_id} - HTTP {response.status}")
                return False

    except urllib.error.HTTPError as e:
        print(f"  [ERROR] {arxiv_id} - HTTP {e.code}: {e.reason}")
        if e.code == 429:
            print(f"  [RATE LIMIT] Waiting 60 seconds before retry...")
            time.sleep(60)
        return False

    except urllib.error.URLError as e:
        print(f"  [ERROR] {arxiv_id} - Network error: {e.reason}")
        return False

    except Exception as e:
        print(f"  [ERROR] {arxiv_id} - Unexpected error: {str(e)}")
        return False


def update_metadata_pdf_status(metadata_file: Path, arxiv_id: str):
    """Mark paper as having PDF stored locally in metadata.json."""
    with open(metadata_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    updated = False
    for paper in data['papers']:
        if paper.get('arxiv_id') == arxiv_id:
            paper['pdf_stored_locally'] = True
            updated = True
            break

    if updated:
        with open(metadata_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print(f"  [METADATA] Updated {metadata_file.name} for {arxiv_id}")


def download_all_pdfs(rate_limit_delay: float = 3.0):
    """Download all PDFs for high-scoring papers."""
    print("Loading metadata files...")
    metadata_files = load_metadata_files()
    print(f"Found {len(metadata_files)} metadata files")

    print("\nFiltering papers with relevance_score >= 8...")
    high_scoring = filter_high_scoring_papers(metadata_files)
    print(f"Found {len(high_scoring)} papers to download")

    # Statistics
    success_count = 0
    failed_count = 0
    skipped_count = 0

    print(f"\nStarting downloads (rate limit: {rate_limit_delay}s between requests)...\n")

    for i, paper in enumerate(high_scoring, 1):
        arxiv_id = paper.get('arxiv_id', 'unknown')
        title = paper.get('title', 'Unknown')
        score = paper.get('relevance_score', 0)
        topic_dir = Path(paper['_topic_dir'])
        metadata_file = Path(paper['_metadata_file'])

        # PDF output directory
        pdfs_dir = topic_dir / "pdfs"

        print(f"[{i}/{len(high_scoring)}] {arxiv_id} (score: {score}/10)")
        print(f"  Title: {title[:80]}{'...' if len(title) > 80 else ''}")

        # Check if already exists
        pdf_path = pdfs_dir / f"{arxiv_id.replace('/', '_')}.pdf"
        if pdf_path.exists():
            skipped_count += 1
            print(f"  [SKIP] Already downloaded")
            continue

        # Download
        success = download_pdf(paper, pdfs_dir, delay=rate_limit_delay)

        if success:
            success_count += 1
            # Update metadata
            update_metadata_pdf_status(metadata_file, arxiv_id)
        else:
            failed_count += 1

        print()  # Blank line between papers

    # Summary
    print("\n" + "="*60)
    print("DOWNLOAD SUMMARY")
    print("="*60)
    print(f"Total papers: {len(high_scoring)}")
    print(f"Successfully downloaded: {success_count}")
    print(f"Already existed (skipped): {skipped_count}")
    print(f"Failed: {failed_count}")
    print(f"Success rate: {(success_count/(len(high_scoring)-skipped_count)*100):.1f}%" if (len(high_scoring)-skipped_count) > 0 else "N/A")


if __name__ == "__main__":
    print("PDF Download Script for High-Scoring Papers (>=8/10)")
    print("="*60)

    # Adjust rate limit delay as needed (3-5 seconds recommended)
    download_all_pdfs(rate_limit_delay=3.0)

    print("\nPDF download complete!")
