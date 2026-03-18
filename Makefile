# ==============================================================================
# Dataset Build Makefile
# ==============================================================================

.ONESHELL:

CONFIG   := $(CURDIR)/config.yaml
PIPELINE := Sign_pipeline
PYTHON   := $(CURDIR)/$(PIPELINE)/.venv/bin/python

# Local venv (separate from the pipeline's venv)
LOCAL_VENV        := $(CURDIR)/.venv
LOCAL_PYTHON      := $(LOCAL_VENV)/bin/python
LOCAL_REQUIREMENTS := $(CURDIR)/requirements.txt

# ------------------------------------------------------------------------------
# Phony targets
# ------------------------------------------------------------------------------

.PHONY: all dirs models repo setup dataset \
        local-venv scrape \
        step1 step2 step3 step4 step5 step6 \
        clean help

# ------------------------------------------------------------------------------
# 1. Create directory structure
# ------------------------------------------------------------------------------

dirs:
	mkdir -p ./working/scraped
	mkdir -p ./working/models

# ------------------------------------------------------------------------------
# 2. Download models
# ------------------------------------------------------------------------------

models: dirs
	cd ./working/models
	wget -nc https://github.com/ultralytics/assets/releases/download/v8.4.0/yolo11m.pt -O yolo11m.pt

# ------------------------------------------------------------------------------
# 3. Clone repo + uv sync + .env
# ------------------------------------------------------------------------------

repo: dirs
	@if [ ! -d "$(PIPELINE)/.git" ]; then \
	    git clone https://github.com/PipeVerri/Sign-pipeline $(PIPELINE); \
	else \
	    echo "Repo already cloned, skipping."; \
	fi

$(PIPELINE)/.venv: repo
	@echo "Running uv sync..."
	cd $(PIPELINE) && uv sync

$(PIPELINE)/.env: $(PIPELINE)/.venv
	@printf "Enter your Hugging Face token (HF_TOKEN): "; \
	read -r token; \
	if [ -f "$(PIPELINE)/.env" ]; then \
	    if grep -q "^HF_TOKEN=" "$(PIPELINE)/.env"; then \
	        sed -i "s/^HF_TOKEN=.*/HF_TOKEN=$$token/" "$(PIPELINE)/.env"; \
	    else \
	        echo "HF_TOKEN=$$token" >> "$(PIPELINE)/.env"; \
	    fi; \
	else \
	    echo "HF_TOKEN=$$token" > "$(PIPELINE)/.env"; \
	fi
	@echo ".env updated."

setup: $(PIPELINE)/.venv $(PIPELINE)/.env

# ------------------------------------------------------------------------------
# 4. Local venv for scripts/
# ------------------------------------------------------------------------------

$(LOCAL_VENV): $(LOCAL_REQUIREMENTS)
	@echo "Creating local venv..."
	python3 -m venv $(LOCAL_VENV)
	$(LOCAL_VENV)/bin/pip install --quiet --upgrade pip
	$(LOCAL_VENV)/bin/pip install --quiet -r $(LOCAL_REQUIREMENTS)
	@echo "Local venv ready."

local-venv: $(LOCAL_VENV)

# ------------------------------------------------------------------------------
# 5. Scrape — runs before the pipeline
# ------------------------------------------------------------------------------

scrape: local-venv
	@echo "[0/6] Scraping Videolibros links..."
	$(LOCAL_PYTHON) scripts/scrape_videolibros_links.py --config $(CONFIG)

# ------------------------------------------------------------------------------
# 6. Setup: dirs + models + repo + venv + .env
# ------------------------------------------------------------------------------

all: dirs models setup
	@echo ""
	@echo "Setup complete. Run 'make dataset' to generate the dataset."

# ------------------------------------------------------------------------------
# 7. Dataset pipeline — individual steps
# ------------------------------------------------------------------------------

step1: repo
	@echo "[1/6] Downloading..."
	cd $(PIPELINE) && $(PYTHON) pipeline/01_download.py --config $(CONFIG)

step2: step1
	@echo "[2/6] Separating audio/video/subtitles..."
	cd $(PIPELINE) && $(PYTHON) pipeline/02_separate_audio_video_subtitles.py --config $(CONFIG)

step3: step2
	@echo "[3/6] Parsing subtitles..."
	cd $(PIPELINE) && $(PYTHON) pipeline/03_parse_subtitles.py --config $(CONFIG)

step4: step3
	@echo "[4/6] Generating subs..."
	cd $(PIPELINE) && $(PYTHON) pipeline/04_generate_subs.py --config $(CONFIG)

step5: step4
	@echo "[5/6] Generating bounding boxes..."
	cd $(PIPELINE) && $(PYTHON) pipeline/05_generate_bounding_boxes.py --config $(CONFIG)

step6: step5
	@echo "[6/6] Generating landmarks..."
	cd $(PIPELINE) && $(PYTHON) pipeline/06_generate_landmarks.py --config $(CONFIG)

# Run all dataset steps
dataset: all scrape step1 step2 step3 step4 step5 step6
	@echo ""
	@echo "Dataset generation complete."

# ------------------------------------------------------------------------------
# Clean
# ------------------------------------------------------------------------------

clean:
	rm -rf ./working $(PIPELINE) $(LOCAL_VENV)