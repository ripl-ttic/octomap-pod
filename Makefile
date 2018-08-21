#REPO := svn://svn.code.sf.net/p/octomap/code/tags/v1.4.2/
REPO := http://svn.code.sf.net/p/octomap/code/tags/v1.4.2/
# REPO := https://octomap.svn.sourceforge.net/svnroot/octomap/tags/v1.4.2/
CHECKOUT_DIR := octomap-v1.4.2

default_target: all

# Default to a less-verbose build.  If you want all the gory compiler output,
# run "make VERBOSE=1"
$(VERBOSE).SILENT:

# Figure out where to build the software.
#   Use BUILD_PREFIX if it was passed in.
#   If not, search up to four parent directories for a 'build' directory.
#   Otherwise, use ./build.
ifeq "$(BUILD_PREFIX)" ""
BUILD_PREFIX:=$(shell for pfx in ./ .. ../.. ../../.. ../../../..; do d=`pwd`/$$pfx/build;\
               if [ -d $$d ]; then echo $$d; exit 0; fi; done; echo `pwd`/build)
endif
# create the build directory if needed, and normalize its path name
BUILD_PREFIX:=$(shell mkdir -p $(BUILD_PREFIX) && cd $(BUILD_PREFIX) && echo `pwd`)

# Default to a release build.  If you want to enable debugging flags, run
# "make BUILD_TYPE=Debug"
ifeq "$(BUILD_TYPE)" ""
BUILD_TYPE="Release"
endif

all: pod-build/Makefile
	$(MAKE) -C pod-build all install

pod-build/Makefile:
	$(MAKE) configure

.PHONY: configure
configure: $(CHECKOUT_DIR)/CMakeLists.txt
	@echo "\nBUILD_PREFIX: $(BUILD_PREFIX)\n\n"

	# create the temporary build directory if needed
	@mkdir -p pod-build

	# Patch the INSTALL_NAME_DIR for OSX, which ensures that the install name
	# for shared libraries includes the full path
ifeq ($(shell uname),Darwin)
	- patch -p0 -N -s -i octomap-v1.4.2.install_name_dir.patch
endif

	# Patch to fix genCoords issue present in v1.4.2
	echo "Applying genCoords patch for version v1.4.2"
	- patch -p0 -N -s -i octomap-v1.4.2.genCoords.patch

ifeq ($(USE_CLANG),TRUE)
	echo "Applying clang++ patch for version v1.4.2"
	- patch -p0 -N -s -i octomap-v1.4.2.clang.patch
endif

	# run CMake to generate and configure the build scripts
	@cd pod-build && cmake -DCMAKE_INSTALL_PREFIX=$(BUILD_PREFIX) \
		   -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) ../$(CHECKOUT_DIR)/octomap
		   
$(CHECKOUT_DIR)/CMakeLists.txt:
	svn checkout $(REPO) $(CHECKOUT_DIR)
		   

clean:
	-if [ -e pod-build/install_manifest.txt ]; then rm -f `cat pod-build/install_manifest.txt`; fi
	-if [ -d pod-build ]; then $(MAKE) -C pod-build clean; rm -rf pod-build; fi

# other (custom) targets are passed through to the cmake-generated Makefile 
%::
	$(MAKE) -C pod-build $@
