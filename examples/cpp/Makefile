# Graft C++ Example
# Demonstrates fetching and building multiple C++ libraries
#
# Libraries included:
# - Header-only: nlohmann/json, cpp-httplib, Aurora Units
# - Compiled: fmt, Catch2, yaml-cpp, SQLiteCpp
# - Tool: CMake (downloaded, used to build other libraries)

b := bin
DL := .cache

MAKEFLAGS := -j 8

DIRS += $b $(DL)

all: $b/test

include ../../graft.mk
#--------------------------------------------------------------------------------------------------
#CMAKE BIN (latest sometimes required by other libs)
#--------------------------------------------------------------------------------------------------

CMAKE_TAR_URL:=https://github.com/Kitware/CMake/releases/download/v4.2.1/cmake-4.2.1-linux-x86_64.tar.gz
CMAKE_TGT=$(CMAKE_DIR)/bin/cmake
$(eval $(call GEN_DOWNLOAD_RECIPE,CMAKE))

CMAKE:=$(CMAKE_TGT)

cmake:$(CMAKE_TGT)
#--------------------------------------------------------------------------------------------------
#Lib A 
#--------------------------------------------------------------------------------------------------

AU_COMMIT:=0.5.0
AU_GIT_URL:=https://github.com/aurora-opensource/au.git
AU_PRE_UNPACK=$(CMAKE) -Wno-dev -S $(AU_TMP) -B $(AU_TMP)/build && $(CMAKE) --build $(AU_TMP)/build -j 8 --target au
AU_EXTRA:=$(CMAKE)
$(eval $(call GEN_DOWNLOAD_RECIPE,AU))

au:$(AU_TGT)

AU_INC:=-I$(AU_DIR)
#--------------------------------------------------------------------------------------------------
#JSON (header-only)
#--------------------------------------------------------------------------------------------------

JSON_COMMIT:=v3.11.3
JSON_GIT_URL:=https://github.com/nlohmann/json.git
$(eval $(call GEN_DOWNLOAD_RECIPE,JSON))

JSON_INC:=-I$(JSON_DIR)/single_include
#--------------------------------------------------------------------------------------------------
#Lib FMT
#--------------------------------------------------------------------------------------------------

FMT_COMMIT:=12.1.0
FMT_GIT_URL:=https://github.com/fmtlib/fmt.git
FMT_PRE_UNPACK=$(CMAKE) -S $(FMT_TMP) -B $(FMT_TMP)/build && $(CMAKE) --build $(FMT_TMP)/build -j 8 --target fmt
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
CATCH2_PRE_UNPACK=$(CMAKE) -S $(CATCH2_TMP) -B $(CATCH2_TMP)/build && $(CMAKE) --build $(CATCH2_TMP)/build -j 8 --target Catch2WithMain
CATCH2_EXTRA:=$(CMAKE)
$(eval $(call GEN_DOWNLOAD_RECIPE,CATCH2))

CATCH2_LIB:=$(CATCH2_DIR)/build/src/libCatch2Main.a $(CATCH2_DIR)/build/src/libCatch2.a
CATCH2_INC:=-I$(CATCH2_DIR)/src -I$(CATCH2_DIR)/build/generated-includes
$(CATCH2_LIB): $(CATCH2_TGT)
#--------------------------------------------------------------------------------------------------
#YAML-CPP
#--------------------------------------------------------------------------------------------------

YAMLCPP_COMMIT:=0.8.0
YAMLCPP_GIT_URL:=https://github.com/jbeder/yaml-cpp.git
YAMLCPP_PRE_UNPACK=$(CMAKE) -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -S $(YAMLCPP_TMP) -B $(YAMLCPP_TMP)/build && $(CMAKE) --build $(YAMLCPP_TMP)/build -j 8
YAMLCPP_EXTRA:=$(CMAKE)
$(eval $(call GEN_DOWNLOAD_RECIPE,YAMLCPP))

YAMLCPP_LIB:=$(YAMLCPP_DIR)/build/libyaml-cpp.a
YAMLCPP_INC:=-I$(YAMLCPP_DIR)/include
$(YAMLCPP_LIB): $(YAMLCPP_TGT)
#--------------------------------------------------------------------------------------------------
#SQLITECPP (bundles SQLite)
#--------------------------------------------------------------------------------------------------

SQLITECPP_COMMIT:=3.3.2
SQLITECPP_GIT_URL:=https://github.com/SRombauts/SQLiteCpp.git
SQLITECPP_PRE_UNPACK=$(CMAKE) -S $(SQLITECPP_TMP) -B $(SQLITECPP_TMP)/build -DSQLITECPP_INTERNAL_SQLITE=ON && $(CMAKE) --build $(SQLITECPP_TMP)/build -j 8
SQLITECPP_EXTRA:=$(CMAKE)
$(eval $(call GEN_DOWNLOAD_RECIPE,SQLITECPP))

SQLITECPP_LIB:=$(SQLITECPP_DIR)/build/libSQLiteCpp.a $(SQLITECPP_DIR)/build/sqlite3/libsqlite3.a
SQLITECPP_INC:=-I$(SQLITECPP_DIR)/include
$(SQLITECPP_LIB): $(SQLITECPP_TGT)
#--------------------------------------------------------------------------------------------------
#CPP-HTTPLIB (header-only, with SSL)
#--------------------------------------------------------------------------------------------------

HTTPLIB_COMMIT:=v0.18.1
HTTPLIB_GIT_URL:=https://github.com/yhirose/cpp-httplib.git
$(eval $(call GEN_DOWNLOAD_RECIPE,HTTPLIB))

HTTPLIB_INC:=-I$(HTTPLIB_DIR) -DCPPHTTPLIB_OPENSSL_SUPPORT
#--------------------------------------------------------------------------------------------------
#TEST APP
#--------------------------------------------------------------------------------------------------
LIBS:=$(FMT_LIB) $(CATCH2_LIB) $(YAMLCPP_LIB) $(SQLITECPP_LIB)
INCS:=$(CATCH2_INC) $(FMT_INC) $(AU_INC) $(JSON_INC) $(YAMLCPP_INC) $(SQLITECPP_INC) $(HTTPLIB_INC)
HEADER_DEPS:=$(AU_TGT) $(JSON_TGT) $(HTTPLIB_TGT)

$b/test:main.cpp $(LIBS)|$b $(HEADER_DEPS)
	g++ -std=c++17 -o $@ $^ $(INCS) -pthread -ldl -lssl -lcrypto

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

