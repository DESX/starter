
b:=bin
DL:=.cache

MAKEFLAGS:=-j 8

DIRS+=$b $(DL)

all:$b/test

include tools/mklib.mk

#--------------------------------------------------------------------------------------------------
#Lib FMT
#--------------------------------------------------------------------------------------------------

FMT_COMMIT:=12.1.0
FMT_GIT_URL:=https://github.com/fmtlib/fmt.git
FMT_PRE_UNPACK=cd $(FMT_TMP) && cmake -S . -B build && cmake --build build -j 8  --target fmt
$(eval $(call GEN_DOWNLOAD_RECIPE,FMT))

FMT_LIB:=$(FMT_DIR)/build/libfmt.a

$(FMT_LIB): $(FMT_TGT)
#--------------------------------------------------------------------------------------------------
#CATCH 2
#--------------------------------------------------------------------------------------------------

CATCH2_COMMIT:=v3.11.0
CATCH2_GIT_URL:=https://github.com/catchorg/Catch2.git
CATCH2_PRE_UNPACK=cd $(CATCH2_TMP) && cmake -S . -B build && cmake --build build -j 8 --target Catch2WithMain
$(eval $(call GEN_DOWNLOAD_RECIPE,CATCH2))

CATCH2_LIB:=$(CATCH2_DIR)/build/src/libCatch2Main.a $(CATCH2_DIR)/build/src/libCatch2.a

$(CATCH2_LIB): $(CATCH2_TGT)

#--------------------------------------------------------------------------------------------------
#TEST APP
#--------------------------------------------------------------------------------------------------
$b/test:main.cpp  $(FMT_LIB) $(CATCH2_LIB)|$b $(FMT_TGT)
	g++ -o $@ $^ -I$(FMT_DIR)/include -I$(CATCH2_DIR)/src -I$(CATCH2_DIR)/build/generated-includes

go:$b/test
	$b/test
#--------------------------------------------------------------------------------------------------
#Cleanup
#--------------------------------------------------------------------------------------------------

clean:
	rm -rf $b

clean-all:
	rm -rf $b $(DL)

$(foreach V ,$(sort $(DIRS)), $(eval $(call MK_DIR, $V)))

