# Test: Caching behavior
b := build_test_caching
DL := .cache_test_caching
DIRS := $b $(DL)

include ../graft.mk

MINIZ_COMMIT := 3.0.2
MINIZ_GIT_URL := https://github.com/richgel999/miniz.git
MINIZ_TGT := $(MINIZ_DIR)/miniz.h
$(eval $(call GEN_DOWNLOAD_RECIPE,MINIZ))

$(foreach V,$(sort $(DIRS)),$(eval $(call MK_DIR,$V)))

.PHONY: test
test:
	@# First build - creates cache
	@$(MAKE) -f test_caching.mk $(MINIZ_TGT)
	@test -f $(DL)/miniz_3.0.2.tar.gz || (echo "ERROR: cache not created" && exit 1)
	@# Record cache timestamp
	@CACHE_TIME=$$(stat -c %Y $(DL)/miniz_3.0.2.tar.gz) && \
	 sleep 1 && \
	 rm -rf $(MINIZ_DIR) && \
	 $(MAKE) -f test_caching.mk $(MINIZ_TGT) && \
	 NEW_TIME=$$(stat -c %Y $(DL)/miniz_3.0.2.tar.gz) && \
	 test "$$CACHE_TIME" = "$$NEW_TIME" || (echo "ERROR: cache was re-downloaded" && exit 1)
	@echo "Caching test: OK"
