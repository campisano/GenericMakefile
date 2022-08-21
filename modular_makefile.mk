# mandatory vars:

# binary_name			:= # example: foo.so
# type				:= # possible values: {lib, exec}



# optional vars:

include_paths			?= inc
library_paths			?=
libs_to_link			?=

source_extension		?= .cpp
base_source_paths		?= src
main_source_paths		?=
test_source_paths		?=

output_folder			?= build
DESTDIR				?=
PREFIX				?= /usr/local

subcomponent_paths		?=



###############################################################################

# define defaults make options
MAKEFLAGS			= --environment-overrides --no-builtin-rules --warn-undefined-variables

# defining variable to avoid warning
MAKECMDGOALS			?=





####################
# check mandatory variables

ifndef binary_name
$(error var 'binary_name' is mandatory)
endif

ifndef type
$(error var 'type' is mandatory)
endif





####################
# define O.S. specific commands

ifdef COMSPEC
	CP			?= copy
	MKDIR			?= md
	MV			?= move
	RM			?= del
	RMALL			?= rd /s /q
else
	CP			?= cp
	MKDIR			?= mkdir -p
	MV			?= mv -f
	RM			?= rm -f
	RMALL			?= rm -rf
endif





####################
# define basic flags

# for C pre-processor: add include paths and generate *.d dependency files in compile time
CPPFLAGS_COMMON			:= $(addprefix -I,$(include_paths)) -MMD -MP

# for C++ compiler
CXXFLAGS_COMMON			:= -pipe -std=c++11 -fexceptions -pedantic -Wall -Wextra -Wshadow -Wnon-virtual-dtor

# for compilers invoking the linker:
LDFLAGS_COMMON			:= $(addprefix -L,$(library_paths)) $(addprefix -l,$(libs_to_link))





####################
# define scope-specific flags

# use optimization, remove all symbol table
CXXFLAGS_RELEASE		:= -O2 -s
LDFLAGS_RELEASE			:=

# use debug optimization, increase debug level to 3, keep frame pointer to use linux 'prof' tool
CXXFLAGS_DEBUG			:= -Og -ggdb3 -fno-omit-frame-pointer
# add all symbols, not only used ones, to the dynamic symbol table
LDFLAGS_DEBUG			:= -rdynamic

# compile code instrumented for coverage analysis
CXXFLAGS_TEST			:= $(CXXFLAGS_DEBUG) --coverage
# link code instrumented for coverage analysis
LDFLAGS_TEST			:= $(LDFLAGS_DEBUG) $(addprefix -l,$(test_libs_to_link)) --coverage

CXXFLAGS_LIB			:= -fPIC
LDFLAGS_LIB			:= -shared

CXXFLAGS_STATIC			:=
LDFLAGS_STATIC			:= -static -static-libgcc -static-libstdc++

# add gprof tool info
CXXFLAGS_PROFILE		:= -g -pg
# add all symbols, not only used ones, to the dynamic symbol table
LDFLAGS_PROFILE			:= -rdynamic -pg





####################
# define build sources

sources_base			:= $(foreach tmp_path,$(base_source_paths),$(wildcard $(tmp_path)/*$(source_extension)))
sources_test			:= $(foreach tmp_path,$(test_source_paths),$(wildcard $(tmp_path)/*$(source_extension)))
sources_main			:= $(foreach tmp_path,$(main_source_paths),$(wildcard $(tmp_path)/*$(source_extension)))





####################
# define targets



ifeq ($(type), exec)
output_subfolder		:= bin
CXXFLAGS_TYPE			:=
LDFLAGS_TYPE			:=
else ifeq ($(type), lib)
output_subfolder		:= lib
CXXFLAGS_TYPE			:= $(CXXFLAGS_LIB)
LDFLAGS_TYPE			:= $(LDFLAGS_LIB)
else
$(error wrong value for var 'type', valid are {exec,lib})
endif

build_targets	 		:= $(output_folder)/$(output_subfolder)/$(binary_name)
objects_main			:= $(foreach source,$(strip $(sources_base) $(sources_main)),$(output_folder)/$(output_subfolder)/$(source).o)


# add test target sources when exists
ifneq ($(strip $(sources_test)),)
build_targets			+= $(output_folder)/test/$(binary_name)
objects_test			:= $(foreach source,$(strip $(sources_base) $(sources_test)),$(output_folder)/test/$(source).o)
endif



.PHONY: all
all: release

.PHONY: release
release: CXXFLAGS_SCOPE=$(CXXFLAGS_RELEASE)
release: LDFLAGS_SCOPE=$(LDFLAGS_RELEASE)
release: submakefiles $(build_targets)

.PHONY: debug
debug: CXXFLAGS_SCOPE=$(CXXFLAGS_DEBUG)
debug: LDFLAGS_SCOPE=$(LDFLAGS_DEBUG)
debug: submakefiles $(build_targets)



####################
# binary targets

$(output_folder)/bin/$(binary_name): $(objects_main)
	@$(MKDIR) $(dir $@)
	$(CXX) -Wl,--no-as-needed -o $@ $(objects_main) $(LDFLAGS_COMMON) $(LDFLAGS_SCOPE) $(LDFLAGS_TYPE)

$(output_folder)/bin/%.o: %
	@$(MKDIR) $(dir $@)
	$(CXX) -o $@ -c $< $(CPPFLAGS_COMMON) $(CXXFLAGS_COMMON) $(CXXFLAGS_SCOPE) $(CXXFLAGS_TYPE)



####################
# library targets

$(output_folder)/lib/$(binary_name): $(objects_main)
	@$(MKDIR) $(dir $@)
	$(CXX) -Wl,--no-as-needed -o $@ $(objects_main) $(LDFLAGS_COMMON) $(LDFLAGS_SCOPE) $(LDFLAGS_TYPE)

$(output_folder)/lib/%.o: %
	@$(MKDIR) $(dir $@)
	$(CXX) -o $@ -c $< $(CPPFLAGS_COMMON) $(CXXFLAGS_COMMON) $(CXXFLAGS_SCOPE) $(CXXFLAGS_TYPE)



####################
# test targets

$(output_folder)/test/$(binary_name): $(objects_test)
	@$(MKDIR) $(dir $@)
	$(CXX) -Wl,--no-as-needed -o $@ $(objects_test) $(LDFLAGS_COMMON) $(LDFLAGS_SCOPE) $(LDFLAGS_TEST)

$(output_folder)/test/%.o: %
	@$(MKDIR) $(dir $@)
	$(CXX) -o $@ -c $< $(CPPFLAGS_COMMON) $(CXXFLAGS_COMMON) $(CXXFLAGS_SCOPE) $(CXXFLAGS_TEST)



NODEPS				:= clean run test
ifeq (0, $(words $(findstring $(MAKECMDGOALS), $(NODEPS))))
-include $(patsubst %$(source_extension),$(output_folder)/%$(source_extension).d,$(strip $(sources_base) $(sources_test) $(sources_main)))
-include $(patsubst %$(source_extension),$(output_folder)/test/%$(source_extension).d,$(strip $(sources_base) $(sources_test) $(sources_main)))
endif





####################
# runnable targets



ifeq ($(type), exec)
.PHONY: run
run:
	LD_LIBRARY_PATH=$(subst $(subst ,, ),:,$(library_paths)) $(output_folder)/bin/$(binary_name)
endif



.PHONY: test
test: submakefiles
	LD_LIBRARY_PATH=$(subst $(subst ,, ),:,$(library_paths)) $(output_folder)/test/$(binary_name)



.PHONY: gcov
gcov: submakefiles
	$(foreach source,$(strip $(sources_base) $(sources_main)),gcov -p -r -o $(output_folder)/test/$(source).o $(source); )



# .PHONY: ddd nemiver
# ddd nemiver:
# # for run with library path
# 	LD_LIBRARY_PATH=$(subst $(subst ,, ),:,$(library_paths)) $@ $(output_folder)/$(binary_name)


# .PHONY: egdb
# egdb:
# # for run with library path
# 	LD_LIBRARY_PATH=$(subst $(subst ,, ),:,$(library_paths)) "${SOFTWARE_PATH}"/emacs/bin/emacs --execute '(gdb-many-windows)' --execute '(gdb "gdb -i=mi $(output_folder)/$(binary_name)")'





####################
# other targets



.PHONY: clean
clean: submakefiles
	$(RM) $(objects_main) $(objects_main:.o=.gcno)
	$(RM) $(objects_test) $(objects_test:.o=.gcno) $(objects_test:.o=.gcda)
	$(RM) $(output_folder)/bin/$(binary_name) $(output_folder)/lib/$(binary_name) $(output_folder)/test/$(binary_name)



.PHONY: install
install: submakefiles
	$(MKDIR) $(DESTDIR)$(PREFIX)/$(output_subfolder)
	$(CP) $(output_folder)/$(output_subfolder)/$(binary_name) $(DESTDIR)$(PREFIX)/$(output_subfolder)



.PHONY: submakefiles
submakefiles:
	@for tmp_path in $(subcomponent_paths); do \
	echo "----- $$tmp_path -----"; \
	$(MAKE) -C $$tmp_path $(MAKECMDGOALS) PREFIX=$(PREFIX) || exit; \
	echo; \
	done;
