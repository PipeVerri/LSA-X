[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.19087120.svg)](https://doi.org/10.5281/zenodo.19087120)
# LSA-X Dataset Builder

Tools and configuration for building an Argentine Sign Language (LSA) dataset by downloading, processing, and annotating videos from various YouTube sources.

The dataset can be downloaded on [Zenodo](https://doi.org/10.5281/zenodo.19087120)

---

## Dataset Description

This dataset contains body pose landmarks extracted from publicly available Argentine Sign Language (LSA) videos, stored in COCO keypoint format. Landmarks cover the full upper body — including face, hands, and body pose — and were extracted using an automated pipeline applied frame by frame to each video.

The dataset comprises **1,553 videos** totaling approximately **507.75 hours** of footage, divided into two subsets:

- **Labeled** (513 videos / 151.79h): Videos with associated Spanish subtitles, either downloaded directly from the platform, sourced from YouTube's auto-generated captions, or generated from audio using automatic speech recognition (ASR). Each sample includes the video ID, the temporally aligned subtitle text, and the corresponding landmark annotations per frame.
- **Unlabeled** (1,040 videos / 355.96h): Videos that likely contain sign language content but lack audio or any available subtitle track, and therefore carry no associated text labels. Frame-level landmark annotations are provided without transcription.

This resource is intended to support research in sign language recognition, continuous signing translation, and multimodal learning for low-resource languages.

---

## Dataset Format

The structure of the output files — including directory layout, file naming conventions, landmark schema, and annotation fields — is documented in the processing pipeline repository:

**[Sign-pipeline](https://github.com/PipeVerri/Sign-pipeline)**

That repository also contains the code used to run each processing step (audio separation, subtitle parsing, YOLO bounding boxes, MediaPipe landmark extraction). Refer to its documentation before working with the raw output files or integrating the dataset into a training pipeline.

---

## Data Sources

All videos were collected from publicly accessible sources. The table below summarizes each source, its content type, and the subtitle acquisition method.

| Source | URL / Origin | Content | Subtitle Method |
|---|---|---|---|
| **Canales Asociación Civil** | [YouTube](https://www.youtube.com/c/CanalesAsociaci%C3%B3nCivil/videos) | Educational organization focused on quality education for deaf children in Argentina. Produces LSA content including the Videolibros project. | Generated from audio (ASR) |
| **Videolibros LSA (public)** | [YouTube](https://www.youtube.com/@VideolibrosLSA/videos) | Children's books and stories read in LSA by deaf signers, with Spanish voiceover. A project of Canales Asociación Civil. | Generated from audio (ASR) |
| **Videolibros LSA (private)** | [videolibros.org](https://www.videolibros.org) (scraped) | Same content as the public Videolibros channel. These videos were publicly accessible on videolibros.org but unlisted on YouTube, and were collected via web scraping. | Generated from audio (ASR) |
| **CNSordos** | [YouTube](https://www.youtube.com/@CNSORDOSARGENTINA/videos) | News channel produced by deaf presenters. | Human-authored subtitles (downloaded) |
| **Locufre** | [YouTube](https://www.youtube.com/channel/UCPJr7e9V_07DAID60F0pXVw) | A weekly streaming program. | YouTube auto-generated captions |

### Dataset Statistics

| Source | Labeled | Unlabeled | Total |
|---|---|---|---|
| Canales Asociación Civil | 231 videos (14.43h) | 477 videos (24.35h) | 708 videos (38.78h) |
| Videolibros LSA (public) | 41 videos (0.87h) | 63 videos (1.59h) | 104 videos (2.46h) |
| Videolibros LSA (private) | 63 videos (8.67h) | 63 videos (8.67h) | 126 videos (17.33h) |
| CNSordos | 67 videos (28.50h) | 109 videos (37.72h) | 176 videos (66.23h) |
| Locufre | 111 videos (99.33h) | 328 videos (283.63h) | 439 videos (382.95h) |
| **TOTAL** | **513 videos (151.79h)** | **1,040 videos (355.96h)** | **1,553 videos (507.75h)** |

---

## Usage Notes

**Unlabeled subset:** The unlabeled portion is not intended to be discarded or treated as auxiliary data. It is provided as a resource for semi-supervised learning approaches, where large amounts of unannotated signing footage can complement the labeled subset to improve model generalization — particularly given the limited availability of annotated LSA data.

**Locufre source — signer attribution:** Although Locufre videos feature clear signing, consistent video quality, and reliable Spanish subtitles, most episodes present two signers on screen simultaneously with a single shared voiceover track. Determining which signer produced each utterance — and therefore which portion of the subtitle corresponds to which individual — is non-trivial. Researchers should account for this when using this subset for tasks requiring speaker-level annotation, signer segmentation, or isolated signing sequence extraction.

---

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

The scraping script (`scripts/scrape_videolibros_links.py`) iterates over Videolibros entries by numeric index. The current upper bound may be outdated as new titles are added to the site. Before running the pipeline, verify the latest index and update it accordingly:

> **[TODO: instructions on how to find the latest index go here]**

Once the latest index is known, open `scripts/scrape_videolibros_links.py` and update line 14:

```python
for i in range(106, 0, -1): # TODO: Update the latest videolibro index
```

Replace `106` with the current upper bound.

## Running the Pipeline

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

Each step depends on the previous one and can be run incrementally.

## Cleanup

```bash
make clean
```

Removes the `working/` directory, the cloned pipeline repository, and both virtual environments.

---

## Attribution

This dataset was conceptually based on [LSA-T](https://midusi.github.io/LSA-T/), a pioneering Argentine Sign Language translation dataset.
