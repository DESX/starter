# Test: EXTRA dependencies ordering
b := build_test_dependencies
DL := .cache_test_dependencies
DIRS := $b $(DL)
LOG := $(b)/order.log

include ../graft.mk

# First dependency (will be built first)
MINIZ_COMMIT := 3.0.2
MINIZ_GIT_URL := https://github.com/richgel999/miniz.git
MINIZ_TGT := $(MINIZ_DIR)/miniz.h
MINIZ_POST_UNPACK = echo "MINIZ" >> $(abspath $(LOG))
$(eval $(call GEN_DOWNLOAD_RECIPE,MINIZ))

# Second dependency depends on first via EXTRA
TINYEXPR_COMMIT := master
TINYEXPR_GIT_URL := https://github.com/codeplea/tinyexpr.git
TINYEXPR_TGT := $(TINYEXPR_DIR)/tinyexpr.h
TINYEXPR_POST_UNPACK = echo "TINYEXPR" >> $(abspath $(LOG))
TINYEXPR_EXTRA := $(MINIZ_TGT)
$(eval $(call GEN_DOWNLOAD_RECIPE,TINYEXPR))

$(foreach V,$(sort $(DIRS)),$(eval $(call MK_DIR,$V)))

.PHONY: test
test: | $(b)
	@rm -f $(LOG)
	@touch $(LOG)
	@$(MAKE) -f test_dependencies.mk $(TINYEXPR_TGT)
	@# Verify MINIZ was built before TINYEXPR
	@head -1 $(LOG) | grep -q "MINIZ" || (echo "ERROR: MINIZ should be first" && exit 1)
	@tail -1 $(LOG) | grep -q "TINYEXPR" || (echo "ERROR: TINYEXPR should be second" && exit 1)
	@echo "Dependencies test: OK"
