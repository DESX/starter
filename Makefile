b:=bin
DL:=.cache

MAKEFLAGS:=-j 8

DIRS+=$b $(DL)

all:$b/test

include tools/mklib.mk
#--------------------------------------------------------------------------------------------------
#CMAKE BIN (latest sometimes required by other libs)
#--------------------------------------------------------------------------------------------------

CMAKE_TAR_URL:=https://github.com/Kitware/CMake/releases/download/v4.2.1/cmake-4.2.1-linux-x86_64.tar.gz
CMAKE_TGT=$(CMAKE_DIR)/bin/cmake
$(eval $(call GEN_DOWNLOAD_RECIPE,CMAKE))

CMAKE:=$(abspath $(CMAKE_TGT))
cmake:$(CMAKE_TGT)
#--------------------------------------------------------------------------------------------------
#Lib A 
#--------------------------------------------------------------------------------------------------

AU_COMMIT:=0.5.0
AU_GIT_URL:=https://github.com/aurora-opensource/au.git
AU_PRE_UNPACK=cd $(AU_TMP) && $(CMAKE) -S . -B build && $(CMAKE) --build build -j 8 
AU_EXTRA:=$(CMAKE)
$(eval $(call GEN_DOWNLOAD_RECIPE,AU))

au:$(AU_TGT)
#--------------------------------------------------------------------------------------------------
#Lib FMT
#--------------------------------------------------------------------------------------------------

FMT_COMMIT:=12.1.0
FMT_GIT_URL:=https://github.com/fmtlib/fmt.git
FMT_PRE_UNPACK=cd $(FMT_TMP) && $(CMAKE) -S . -B build && $(CMAKE) --build build -j 8  --target fmt
FMT_EXTRA:=$(CMAKE)
$(eval $(call GEN_DOWNLOAD_RECIPE,FMT))
FMT_LIB:=$(FMT_DIR)/build/libfmt.a
FMT_INC:=-I$(FMT_DIR)/include
$(FMT_LIB): $(FMT_TGT)

#--------------------------------------------------------------------------------------------------
#CATCH 2
#--------------------------------------------------------------------------------------------------

CATCH2_COMMIT:=v3.11.0
CATCH2_GIT_URL:=https://github.com/catchorg/Catch2.git
CATCH2_PRE_UNPACK=cd $(CATCH2_TMP) && $(CMAKE) -S . -B build && $(CMAKE) --build build -j 8 --target Catch2WithMain
CATCH2_EXTRA:=$(CMAKE)
$(eval $(call GEN_DOWNLOAD_RECIPE,CATCH2))

CATCH2_LIB:=$(CATCH2_DIR)/build/src/libCatch2Main.a $(CATCH2_DIR)/build/src/libCatch2.a
CATCH2_INC:=-I$(CATCH2_DIR)/src -I$(CATCH2_DIR)/build/generated-includes
$(CATCH2_LIB): $(CATCH2_TGT)

#--------------------------------------------------------------------------------------------------
#TEST APP
#--------------------------------------------------------------------------------------------------
$b/test:main.cpp $(FMT_LIB) $(CATCH2_LIB)|$b
	g++ -o $@ $^ $(CATCH2_INC) $(FMT_INC)

go:$b/test
	$b/test

watch:
	echo main.cpp | tr ' ' '\n'| entr make go
#--------------------------------------------------------------------------------------------------
#Cleanup
#--------------------------------------------------------------------------------------------------

clean:
	rm -rf $b

clean-all:
	rm -rf $b $(DL)

$(foreach V ,$(sort $(DIRS)), $(eval $(call MK_DIR, $V)))

