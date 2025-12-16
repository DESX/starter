
TO_LOWER = $(shell echo '$(1)' | tr '[:upper:]' '[:lower:]')
OVERLAY=find $1 -type f -printf '%P\n' | while read -r file; do mkdir -p "$2/$$(dirname "$$file")" && rm -f "$2/$$file" && ln -rs "$$(realpath "$1/$$file")" "$2/$$file"; done

define GEN_DOWNLOAD_RECIPE=

$(eval GDPLL:=$(call TO_LOWER,$1))
$(eval $1_DIR?=$b/$(GDPLL))
$(eval $1_TGT?=$($1_DIR)/README.md)
$(eval $1_TMP?=/tmp/$(GDPLL))

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
$($1_TAR): | $(DL)
	rm -rf $($1_TMP) && mkdir -p $($1_TMP) 
	git clone --branch $($1_COMMIT) --depth 1 --recursive --shallow-submodules $($1_GIT_URL) $($1_TMP)
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
