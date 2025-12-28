# Test: OVERLAY symlinks
b := build_test_overlay
DL := .cache_test_overlay
DIRS := $b $(DL)
OVERLAY_DIR := overlay_test

include ../graft.mk

# Use a small repo with overlay
MINIZ_COMMIT := 3.0.2
MINIZ_GIT_URL := https://github.com/richgel999/miniz.git
MINIZ_TGT := $(MINIZ_DIR)/miniz.h
MINIZ_OVERLAY := $(OVERLAY_DIR)
$(eval $(call GEN_DOWNLOAD_RECIPE,MINIZ))

$(foreach V,$(sort $(DIRS)),$(eval $(call MK_DIR,$V)))

# Create overlay directory with a replacement file
$(OVERLAY_DIR)/custom.txt:
	@mkdir -p $(OVERLAY_DIR)
	@echo "OVERLAY CONTENT" > $@

.PHONY: test
test: $(OVERLAY_DIR)/custom.txt $(MINIZ_TGT)
	@# Verify overlay file exists as symlink
	@test -L $(MINIZ_DIR)/custom.txt || (echo "ERROR: overlay not symlinked" && exit 1)
	@# Verify content
	@grep -q "OVERLAY CONTENT" $(MINIZ_DIR)/custom.txt || (echo "ERROR: overlay content wrong" && exit 1)
	@echo "Overlay test: OK"
	@rm -rf $(OVERLAY_DIR)
