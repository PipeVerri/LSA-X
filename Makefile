# ==============================================================================
# Dataset Build Makefile
# ==============================================================================

.ONESHELL:

CONFIG  := $(CURDIR)/config.yaml
PIPELINE := Sign_pipeline
PYTHON  := $(CURDIR)/$(PIPELINE)/.venv/bin/python

# ------------------------------------------------------------------------------
# Phony targets
# ------------------------------------------------------------------------------

.PHONY: all dirs models repo setup dataset \
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
	wget -nc https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_heavy/float16/latest/pose_landmarker_heavy.task -O pose_landmarker.task
	wget -nc https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/latest/hand_landmarker.task -O hand_landmarker.task
	wget -nc https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/latest/face_landmarker.task -O face_landmarker.task

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
# 4. Setup: dirs + models + repo + venv + .env
# ------------------------------------------------------------------------------

all: dirs models setup
	@echo ""
	@echo "Setup complete. Run 'make dataset' to generate the dataset."

# ------------------------------------------------------------------------------
# 5. Dataset pipeline — individual steps
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
dataset: all step1 step2 step3 step4 step5 step6
	@echo ""
	@echo "Dataset generation complete."

# ------------------------------------------------------------------------------
# Clean
# ------------------------------------------------------------------------------

clean:
	rm -rf ./working $(PIPELINE)