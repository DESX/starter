# Graft - Dependency management with fetch, patch, and overlay
# https://github.com/[owner]/graft
# MIT License
#
# Required variables before include:
#   b   - Output directory for dependencies (e.g., bin/)
#   DL  - Cache directory for downloads (e.g., .cache/)
#
# Per-dependency variables (NAME = uppercase identifier):
#   NAME_GIT_URL    - Git repository URL (use with NAME_COMMIT)
#   NAME_TAR_URL    - Direct tarball download URL
#   NAME_ZIP_URL    - Direct zip download URL
#   NAME_COMMIT     - Git tag/branch/commit (required for GIT_URL)
#   NAME_TGT        - Target file to check existence (default: README.md)
#   NAME_DIR        - Install directory (default: $b/name)
#   NAME_PRE_UNPACK - Command to run after clone, before caching
#   NAME_POST_UNPACK- Command to run after extraction
#   NAME_PATCH      - Patch file to apply after extraction
#   NAME_OVERLAY    - Directory to symlink over dependency
#   NAME_EXTRA      - Dependencies that must be built first
#
# Generated variables:
#   NAME_DIR        - Path to extracted dependency
#   NAME_TGT        - Target file path
#   NAME_TAR        - Cached tarball path
#
# Generated targets:
#   name_tgt        - Build the dependency
#   name_patch      - Regenerate patch from modifications (if NAME_PATCH set)

TO_LOWER = $(shell echo '$(1)' | tr '[:upper:]' '[:lower:]')
OVERLAY=find $1 -type f -printf '%P\n' | while read -r file; do mkdir -p "$2/$$(dirname "$$file")" && rm -f "$2/$$file" && ln -rs "$$(realpath "$1/$$file")" "$2/$$file"; done

define GEN_DOWNLOAD_RECIPE=

$(eval GDPLL:=$(call TO_LOWER,$1))
$(eval $1_DIR?=$b/$(GDPLL))
$(eval $1_TGT?=$($1_DIR)/README.md)
$(eval $1_TMP?=/tmp/$(GDPLL))
$(eval $1_EXTRA?=)

DIRS+=$($1_DIR)

ifneq ($($1_TAR_URL),)
$(eval $(if $($1_TAR_URL),$1_TAR?=$(DL)/$(GDPLL)$(patsubst $(basename $(basename $($1_TAR_URL)))%,%,$($1_TAR_URL))))
$($1_TAR): | $(DL)
	curl -L $($1_TAR_URL) > $$@
endif

ifneq ($($1_ZIP_URL),)
$($1_ZIP): | $(DL)
	curl -L $($1_ZIP_URL) > $$@

$($1_TGT): | $($1_ZIP) $($1_DIR)
	cd $($1_DIR) && unzip $(abspath $($1_ZIP))
	echo $$@
endif

ifneq ($($1_GIT_URL),)
$(eval $1_TAR?=$(DL)/$(GDPLL)_$($1_COMMIT).tar.gz)
$($1_TAR): | $(DL) $($1_EXTRA)
	rm -rf $($1_TMP) && mkdir -p $($1_TMP) 
	git clone -c advice.detachedHead=false --branch $($1_COMMIT) --depth 1 --recursive --shallow-submodules $($1_GIT_URL) $($1_TMP)
ifneq ($($1_PRE_UNPACK),)
	$($1_PRE_UNPACK)
endif
	tar -czf $($1_TAR) -C $(dir $($1_TMP)) --exclude='.git*'  $(notdir $($1_TMP))
endif
.PHONY:$(GDPLL)_tgt
$(GDPLL)_tgt:$($1_TGT)

ifneq ($($1_ZIP_URL),)
else
$($1_TGT): | $($1_TAR) $($1_DIR)
	tar -xf $($1_TAR) --strip-components=1 -C $($1_DIR) --touch
ifneq ($($1_POST_UNPACK),)
	$($1_POST_UNPACK)
endif
	echo $$@
endif

ifneq ($($1_PATCH),)
	patch -p2 -d $($1_DIR) < $($1_PATCH)
endif
ifneq ($($1_OVERLAY),)
	$$(call OVERLAY,$($1_OVERLAY),$($1_DIR))
endif

ifneq ($($1_PATCH),)
.PHONY:$(GDPLL)_patch
$(GDPLL)_patch: |$($1_TGT) $($1_PATCH)
	rm -rf $($1_TMP) && mkdir -p $($1_TMP)/old
	cp -r $($1_DIR) $($1_TMP)/new
	tar -xf $($1_TAR) --strip-components=1 -C $($1_TMP)/old
	find "$($1_TMP)/new" -mindepth 1 | while read -r item; do rel="$$$${item#$($1_TMP)/new/}"; [[ ! -e "$($1_TMP)/old/$$$$rel" ]] && rm -rf "$$$$item" || echo -n ""; done
endif
ifneq ($($1_OVERLAY),)
	$$(call OVERLAY,$($1_OVERLAY),$($1_TMP)/old)
	$$(call OVERLAY,$($1_OVERLAY),$($1_TMP)/new)
endif
ifneq ($($1_PATCH),)
	cd $($1_TMP) && diff -ruN ./old ./new > $(abspath $($1_PATCH)) | true
endif
endef

define MK_DIR =
$1:
	mkdir -p $$@
endef
