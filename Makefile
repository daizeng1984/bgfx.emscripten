# OS & File
UNAME:=$(shell uname)
ifeq ($(UNAME),$(filter $(UNAME),Linux Darwin))
CMD_MKDIR=mkdir -p "$(1)"
CMD_RMDIR=rm -r "$(1)"
ifeq ($(UNAME),$(filter $(UNAME),Darwin))
OS=darwin
else
OS=linux
endif
else
CMD_MKDIR=cmd /C "if not exist "$(subst /,\,$(1))" mkdir "$(subst /,\,$(1))""
CMD_RMDIR=cmd /C "if exist "$(subst /,\,$(1))" rmdir /S /Q "$(subst /,\,$(1))""
OS=windows
endif

TARGET=Debug

BGFX_DIR = deps/bgfx
BX_DIR = deps/bx
BIMG_DIR = deps/bimg
3RD_DIR = deps/bgfx/3rdparty

GENIE?=$(PWD)/$(BX_DIR)/tools/bin/$(OS)/genie $(EXTRA_GENIE_ARGS)
NINJA?=$(PWD)/$(BX_DIR)/tools/bin/$(OS)/ninja

BGFX_BIN = $(BGFX_DIR)/.build/wasm/bin/
BGFX_LIB = $(BGFX_BIN)/bgfx$(TARGET).bc $(BGFX_BIN)/bimg$(TARGET).bc $(BGFX_BIN)/bx$(TARGET).bc $(BGFX_BIN)/bimg_decode$(TARGET).bc
LD_FLAGS = $(BGFX_LIB) -s USE_WEBGL2=1 -s USE_GLFW=3 -s WASM=1  -std=c++1z -s ALLOW_MEMORY_GROWTH=1 --preload-file assets@/ -s DEMANGLE_SUPPORT=1 --shell-file src/shell.html


# CC specifies which compiler we're using
CC = emcc
CXX = em++
MAKE = make
CXXFLAGS = -g -w -D ENTRY_CONFIG_IMPLEMENT_MAIN=1

OUT = ./build
ASSETS_OUT = $(OUT)/assets
SHADER_OUT = $(OUT)/shaders

# BGFX
BGFX_HEADERS =  -I$(BGFX_DIR)/include -I$(BX_DIR)/include -I$(BIMG_DIR)/include -I$(3RD_DIR)
# PC x86
#-stdlib=libstdc++ -ldl -lpthread -lrt

# Shaders


# src files
SRC = ./src
rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

SRC_FILES = $(call rwildcard,$(SRC),*.cpp)
3RD_FILES = $(call rwildcard,$(3RD_DIR)/stb $(3RD_DIR)/meshoptimizer $(3RD_DIR)/dear-imgui,*.cpp)

# build output
.PHONY : deps all shaders out clean clean.all bgfx
# Output
main : deps shaders out
	$(CXX) $(SRC_FILES) $(3RD_FILES) -o  $(OUT)/main.html $(CXXFLAGS) $(LD_FLAGS) $(BGFX_HEADERS)

all : main shaders assets

code : 
	compiledb $(MAKE) main

out:
	$(call CMD_MKDIR,$(OUT))
	$(call CMD_MKDIR,$(SHADER_OUT))
	$(call CMD_MKDIR,$(ASSETS_OUT))

# Deps libs
deps : bgfx
bgfx : 
	cd $(BGFX_DIR) && $(GENIE) --gcc=wasm gmake && $(MAKE) -R -C .build/projects/gmake-wasm config=debug && $(MAKE) -R -C .build/projects/gmake-wasm config=release && $(MAKE) tools
	

shaders: deps out
	cd $(SRC)/shaders && $(MAKE) TARGET=3 #OpenGL ES for wasm

assets: deps out
	PATH="$(PWD)/deps/bgfx/tools/bin/$(OS):$(PATH)" $(NINJA) -C assets


run :
	$(OUT)/main

clean.all: clean
	$(call CMD_RMDIR,$(BGFX_DIR)/.build)
	$(call CMD_RMDIR,$(OUT))

clean:
	$(call CMD_RMDIR,$(OUT))
