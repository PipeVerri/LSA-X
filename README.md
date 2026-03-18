# LSA-X Dataset Builder

Pipeline for building an Argentine Sign Language (LSA) dataset by downloading, processing, and annotating videos from various YouTube sources.

## Requirements

- Python 3.x
- `uv` (for the pipeline virtual environment)
- `wget`
- A [Hugging Face](https://huggingface.co) account and access token

## Setup

```bash
make all
```

This will:
1. Create the working directory structure
2. Download the required models (YOLO, MediaPipe)
3. Clone the processing pipeline and set up its virtual environment
4. Prompt you for your Hugging Face token

## Updating the Videolibros index

The scraping script (`scripts/scrape_videolibros_links.py`) iterates over videolibro entries by numeric index. The current upper bound may be outdated as new books get added to the site. Before running the pipeline, check the latest index and update it:

> **[TODO: instructions on how to find the latest index go here]**

Once you know the latest index, open `scripts/scrape_videolibros_links.py` and update line 14:

```python
for i in range(106, 0, -1): # TODO: Update the latest videolibro index
```

Replace `106` with the latest index number.

## Running the pipeline

### Full pipeline (setup + scrape + all steps)

```bash
make dataset
```

### Scrape only

```bash
make scrape
```

### Individual steps

```bash
make step1   # Download videos
make step2   # Separate audio, video, and subtitles
make step3   # Parse subtitles
make step4   # Generate subtitles (Whisper)
make step5   # Generate bounding boxes (YOLO)
make step6   # Generate landmarks (MediaPipe)
```

Each step depends on the previous one, so they can also be run incrementally.

## Cleanup

```bash
make clean
```

Removes the `working/` directory, the cloned pipeline repo, and both virtual environments.
