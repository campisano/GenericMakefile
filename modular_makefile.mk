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

subcomponent_paths		?=



###############################################################################

# define defaults make options
MAKEFLAGS			+= --no-builtin-rules --warn-undefined-variables

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
	MKDIR			?= md
	MV			?= move
	RM			?= del
	RMALL			?= rd /s /q
else
	MKDIR			?= mkdir -p
	MV			?= mv -f
	RM			?= rm -f
	RMALL			?= rm -rf
endif





####################
# define basic flags

# for C pre-processor: add include paths and generate *.d dependency files in compile time
CPPFLAGS			:= $(addprefix -I,$(include_paths)) -MMD -MP

# for C++ compiler
CXXFLAGS			:= -pipe -std=c++11 -fexceptions -pedantic -Wall -Wextra -Wshadow -Wnon-virtual-dtor

# for compilers invoking the linker:
LDFLAGS				:= $(addprefix -L,$(library_paths)) $(addprefix -l,$(libs_to_link))





####################
# define scope-specific flags

# use optimization, remove all symbol table
CXXFLAGS_release		:= -O2 -s
LDFLAGS_release			:=

# use debug optimization, increase debug level to 3, keep frame pointer to use linux 'prof' tool
CXXFLAGS_debug			:= -Og -ggdb3 -fno-omit-frame-pointer
# add all symbols, not only used ones, to the dynamic symbol table
LDFLAGS_debug			:= -rdynamic

# compile code instrumented for coverage analysis
CXXFLAGS_test			:= $(CXXFLAGS_debug) --coverage
# link code instrumented for coverage analysis
LDFLAGS_test			:= $(LDFLAGS_debug) $(addprefix -l,$(test_libs_to_link)) --coverage

CXXFLAGS_lib			:= -fPIC
LDFLAGS_lib			:= -shared

CXXFLAGS_static			:=
LDFLAGS_static			:= -static -static-libgcc -static-libstdc++

# add gprof tool info
CXXFLAGS_profile		:= -g -pg
# add all symbols, not only used ones, to the dynamic symbol table
LDFLAGS_profile			:= -rdynamic -pg





####################
# define build sources

sources_base			:= $(foreach tmp_path,$(base_source_paths),$(wildcard $(tmp_path)/*$(source_extension)))
sources_test			:= $(foreach tmp_path,$(test_source_paths),$(wildcard $(tmp_path)/*$(source_extension)))
sources_main			:= $(foreach tmp_path,$(main_source_paths),$(wildcard $(tmp_path)/*$(source_extension)))





####################
# define targets



ifeq ($(type), exec)
release_targets 		:= $(output_folder)/release/bin/$(binary_name)
objects_release_main		:= $(foreach source,$(strip $(sources_base) $(sources_main)),$(output_folder)/release/bin/$(source).o)
debug_targets	 		:= $(output_folder)/debug/bin/$(binary_name)
objects_debug_main		:= $(foreach source,$(strip $(sources_base) $(sources_main)),$(output_folder)/debug/bin/$(source).o)
CXXFLAGS_type			:=
LDFLAGS_type			:=
else ifeq ($(type), lib)
release_targets 		:= $(output_folder)/release/lib/$(binary_name)
objects_release_main		:= $(foreach source,$(strip $(sources_base) $(sources_main)),$(output_folder)/release/lib/$(source).o)
debug_targets	 		:= $(output_folder)/debug/lib/$(binary_name)
objects_debug_main		:= $(foreach source,$(strip $(sources_base) $(sources_main)),$(output_folder)/debug/lib/$(source).o)
CXXFLAGS_type			:= $(CXXFLAGS_lib)
LDFLAGS_type			:= $(LDFLAGS_lib)
else
$(error wrong value for var 'type', valid are {exec,lib})
endif

ifneq ($(strip $(sources_test)),)
debug_targets			+= $(output_folder)/debug/test/$(binary_name)
objects_debug_test		:= $(foreach source,$(strip $(sources_base) $(sources_test)),$(output_folder)/debug/test/$(source).o)
endif



.PHONY: all
all: debug

.PHONY: release
release: submakefiles $(release_targets)

.PHONY: debug
debug: submakefiles $(debug_targets)



####################
# binary targets

$(output_folder)/release/bin/$(binary_name): $(objects_release_main)
	@$(MKDIR) $(dir $@)
	$(CXX) -Wl,--no-as-needed -o $@ $(objects_release_main) $(LDFLAGS) $(LDFLAGS_release) $(LDFLAGS_type)

$(output_folder)/release/bin/%.o: %
	@$(MKDIR) $(dir $@)
	$(CXX) -o $@ -c $< $(CPPFLAGS) $(CXXFLAGS) $(CXXFLAGS_release) $(CXXFLAGS_type)

$(output_folder)/debug/bin/$(binary_name): $(objects_debug_main)
	@$(MKDIR) $(dir $@)
	$(CXX) -Wl,--no-as-needed -o $@ $(objects_debug_main) $(LDFLAGS) $(LDFLAGS_debug) $(LDFLAGS_type)

$(output_folder)/debug/bin/%.o: %
	@$(MKDIR) $(dir $@)
	$(CXX) -o $@ -c $< $(CPPFLAGS) $(CXXFLAGS) $(CXXFLAGS_debug) $(CXXFLAGS_type)



####################
# library targets

$(output_folder)/release/lib/$(binary_name): $(objects_release_main)
	@$(MKDIR) $(dir $@)
	$(CXX) -Wl,--no-as-needed -o $@ $(objects_release_main) $(LDFLAGS) $(LDFLAGS_release) $(LDFLAGS_type)

$(output_folder)/release/lib/%.o: %
	@$(MKDIR) $(dir $@)
	$(CXX) -o $@ -c $< $(CPPFLAGS) $(CXXFLAGS) $(CXXFLAGS_release) $(CXXFLAGS_type)

$(output_folder)/debug/lib/$(binary_name): $(objects_debug_main)
	@$(MKDIR) $(dir $@)
	$(CXX) -Wl,--no-as-needed -o $@ $(objects_debug_main) $(LDFLAGS) $(LDFLAGS_debug) $(LDFLAGS_type)

$(output_folder)/debug/lib/%.o: %
	@$(MKDIR) $(dir $@)
	$(CXX) -o $@ -c $< $(CPPFLAGS) $(CXXFLAGS) $(CXXFLAGS_debug) $(CXXFLAGS_type)



####################
# test targets

$(output_folder)/debug/test/$(binary_name): $(objects_debug_test)
	@$(MKDIR) $(dir $@)
	$(CXX) -Wl,--no-as-needed -o $@ $(objects_debug_test) $(LDFLAGS) $(LDFLAGS_debug) $(LDFLAGS_test)

$(output_folder)/debug/test/%.o: %
	@$(MKDIR) $(dir $@)
	$(CXX) -o $@ -c $< $(CPPFLAGS) $(CXXFLAGS) $(CXXFLAGS_debug) $(CXXFLAGS_test)



NODEPS				:= clean run test
ifeq (0, $(words $(findstring $(MAKECMDGOALS), $(NODEPS))))
-include $(patsubst %$(source_extension),$(output_folder)/release/%$(source_extension).d,$(strip $(sources_base) $(sources_test) $(sources_main)))
-include $(patsubst %$(source_extension),$(output_folder)/release/test/%$(source_extension).d,$(strip $(sources_base) $(sources_test) $(sources_main)))
-include $(patsubst %$(source_extension),$(output_folder)/debug/%$(source_extension).d,$(strip $(sources_base) $(sources_test) $(sources_main)))
-include $(patsubst %$(source_extension),$(output_folder)/debug/test/%$(source_extension).d,$(strip $(sources_base) $(sources_test) $(sources_main)))
endif





####################
# runnable targets



ifeq ($(type), exec)
.PHONY: run_debug
run_debug:
	LD_LIBRARY_PATH=$(subst $(subst ,, ),:,$(library_paths)) $(output_folder)/debug/bin/$(binary_name)

.PHONY: run_release
run_release:
	LD_LIBRARY_PATH=$(subst $(subst ,, ),:,$(library_paths)) $(output_folder)/release/bin/$(binary_name)
endif



.PHONY: test
test: submakefiles
	LD_LIBRARY_PATH=$(subst $(subst ,, ),:,$(library_paths)) $(output_folder)/debug/test/$(binary_name) -c -p



.PHONY: gcov
gcov: submakefiles
	@$(MKDIR) gcov
	cd gcov && gcov -a -p $(foreach object,$(objects_debug_main),../$(object)) $(foreach source,$(strip $(sources_base) $(sources_main)),-o ../$(output_folder)/debug/test/$(source).gcno -o ../$(output_folder)/debug/test/$(source).gcda)



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
	$(RM) $(objects_debug_main) $(objects_debug_main:.o=.gcno)
	$(RM) $(objects_debug_test) $(objects_debug_test:.o=.gcno) $(objects_debug_test:.o=.gcda)
	$(RM) $(output_folder)/debug/bin/$(binary_name) $(output_folder)/debug/lib/$(binary_name) $(output_folder)/debug/test/$(binary_name)
	$(RM) $(objects_release_main) $(objects_release_main:.o=.gcno)
	$(RM) $(output_folder)/release/bin/$(binary_name) $(output_folder)/release/lib/$(binary_name)



.PHONY: submakefiles
submakefiles:
	@for tmp_path in $(subcomponent_paths); do \
	echo "----- $$tmp_path -----"; \
	$(MAKE) -C $$tmp_path $(MAKECMDGOALS) || exit; \
	echo; \
	done;
