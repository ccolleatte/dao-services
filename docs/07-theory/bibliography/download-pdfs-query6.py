#!/usr/bin/env python3
"""
Download PDFs for Query Set 6 papers with relevance_score >= 8/10.
Follows selective storage pattern (only high-relevance papers).
"""

import json
import urllib.request
import time
from pathlib import Path


def download_pdfs():
    """Download PDFs for Query Set 6 high-scoring papers."""
    metadata_path = Path(__file__).parent / "arxiv-sources/06-complementary/2024-2025/metadata.json"
    pdf_dir = Path(__file__).parent / "arxiv-sources/06-complementary/2024-2025/pdfs"

    # Create PDF directory if it doesn't exist
    pdf_dir.mkdir(parents=True, exist_ok=True)

    # Load metadata
    with open(metadata_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Filter papers with score >= 8
    high_score_papers = [p for p in data['papers'] if p.get('relevance_score', 0) >= 8]

    print(f"\n{'='*60}")
    print(f"PDF DOWNLOADS - QUERY SET 6")
    print(f"{'='*60}")
    print(f"Total high-scoring papers (>=8/10): {len(high_score_papers)}")
    print(f"Target directory: {pdf_dir}")
    print(f"{'='*60}\n")

    downloaded = 0
    skipped = 0
    errors = []

    for idx, paper in enumerate(high_score_papers, 1):
        arxiv_id = paper['arxiv_id']
        title = paper['title'][:60]
        score = paper['relevance_score']
        pdf_url = paper['pdf_url']

        # Generate filename
        pdf_filename = f"{arxiv_id.replace('/', '-')}.pdf"
        pdf_path = pdf_dir / pdf_filename

        print(f"[{idx}/{len(high_score_papers)}] {arxiv_id} ({score}/10)")
        print(f"  {title}...")

        # Skip if already downloaded
        if pdf_path.exists():
            print(f"  [OK] Already exists ({pdf_path.stat().st_size // 1024} KB)")
            skipped += 1
            continue

        # Download PDF
        try:
            print(f"  Downloading from {pdf_url}")

            headers = {'User-Agent': 'Mozilla/5.0 (Academic Research Bot)'}
            req = urllib.request.Request(pdf_url, headers=headers)

            with urllib.request.urlopen(req, timeout=60) as response:
                pdf_content = response.read()

            # Save to file
            with open(pdf_path, 'wb') as f:
                f.write(pdf_content)

            file_size_kb = len(pdf_content) // 1024
            print(f"  [OK] Downloaded ({file_size_kb} KB)")

            # Update metadata
            paper['pdf_stored_locally'] = True

            downloaded += 1

            # Rate limiting (3 seconds between downloads)
            if idx < len(high_score_papers):
                print(f"  Rate limiting: waiting 3s...")
                time.sleep(3)

        except Exception as e:
            error_msg = f"{arxiv_id}: {str(e)}"
            errors.append(error_msg)
            print(f"  [ERROR] {str(e)}")

    # Update metadata.json with pdf_stored_locally flags
    with open(metadata_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    # Summary
    print(f"\n{'='*60}")
    print(f"DOWNLOAD SUMMARY")
    print(f"{'='*60}")
    print(f"Downloaded: {downloaded}")
    print(f"Skipped (already exists): {skipped}")
    print(f"Errors: {len(errors)}")

    if errors:
        print(f"\nErrors encountered:")
        for error in errors:
            print(f"  - {error}")

    print(f"\nTotal PDFs in directory: {len(list(pdf_dir.glob('*.pdf')))}")
    print(f"Metadata updated: {metadata_path}")
    print(f"{'='*60}\n")


if __name__ == "__main__":
    download_pdfs()
