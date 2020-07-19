# mandatory vars:

# binary_name			:= # example: foo.so
# type				:= # possible values: {lib, exec}



# optional vars:

include_folders			?= inc
library_folders			?=
libs_to_link			?=

source_extension		?= .cpp
source_folders			?= src
main_folders			?=
test_folders			?=

output_folder			?= out

subcomponent_folders		?=



###############################################################################

# define defaults make options
MAKEFLAGS			+= --no-builtin-rules

# defining default target
MAKECMDGOALS			?= debug





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

# for C pre-processor
CPPFLAGS			:= $(addprefix -I,$(include_folders)) -MMD -MP

# for C++ compiler
CXXFLAGS			:= -pipe -std=c++11 -fexceptions -pedantic -Wall -Wextra -Wshadow -Wnon-virtual-dtor

# for compilers invoking the linker:
LDFLAGS				:= $(addprefix -L,$(library_folders)) $(addprefix -l,$(libs_to_link))





####################
# define build sources

sources				= $(foreach tmp_dir, $(source_folders), $(wildcard $(tmp_dir)/*$(source_extension)))

ifeq ($(MAKECMDGOALS), test)
	sources			+= $(foreach tmp_dir, $(test_folders), $(wildcard $(tmp_dir)/*$(source_extension)))
# compile code instrumented for coverage analysis
	CXXFLAGS		+= --coverage
# link code instrumented for coverage analysis
	LDFLAGS			+= $(addprefix -l,$(test_libs_to_link)) --coverage
else
	sources			+= $(foreach tmp_dir, $(main_folders), $(wildcard $(tmp_dir)/*$(source_extension)))
ifeq ($(type), lib)
	CXXFLAGS		+= -fPIC
	LDFLAGS			+= -shared
endif
endif

# one object for source, one dep for object
objects				= $(sources:%=$(output_folder)/%.o)
dependencies			= $(objects:.o=.d)





####################
# define build flags

#TODO
#ifeq ($(MAKECMDGOALS), debug)
ifneq ($(filter $(MAKECMDGOALS), debug test),)
# use debug optimization, increase debug level to 3, keep frame pointer to use linux 'prof' tool
	CXXFLAGS		+= -Og -ggdb3 -g3 -fno-omit-frame-pointer
# add all symbols, not only used ones, to the dynamic symbol table
	LDFLAGS			+= -rdynamic
else ifeq ($(MAKECMDGOALS), release)
# use optimization, remove all symbol table
	CXXFLAGS		+= -O3 -s
else ifeq ($(MAKECMDGOALS), static)
	CXXFLAGS		+= -O3 -s
	LDFLAGS			+= -static -static-libgcc -static-libstdc++
else ifeq ($(MAKECMDGOALS), profile)
# add gprof tool info
	CXXFLAGS		+= -g -pg
# add all symbols, not only used ones, to the dynamic symbol table
	LDFLAGS			+= -rdynamic -pg
endif





####################
# define targets



# default target
.PHONY: all debug release static profile
all debug release static profile: submakefiles $(output_folder)/$(binary_name)



.PHONY: test
test: all
# for run with library path
	LD_LIBRARY_PATH=$(subst $(subst ,, ),:,$(library_folders)) $(output_folder)/$(binary_name) -c



.PHONY: ddd nemiver
ddd nemiver:
# for run with library path
	LD_LIBRARY_PATH=$(subst $(subst ,, ),:,$(library_folders)) $@ $(output_folder)/$(binary_name)


.PHONY: egdb
egdb:
# for run with library path
	LD_LIBRARY_PATH=$(subst $(subst ,, ),:,$(library_folders)) "${SOFTWARE_PATH}"/emacs/bin/emacs --execute '(gdb-many-windows)' --execute '(gdb "gdb -i=mi $(output_folder)/$(binary_name)")'



.PHONY: run
run:
ifneq ($(MAKECMDGOALS), test)
ifneq ($(type), lib)
# for run with library path
	LD_LIBRARY_PATH=$(subst $(subst ,, ),:,$(library_folders)) $(output_folder)/$(binary_name)
endif
endif


# binary_name target
$(output_folder)/$(binary_name): $(dependencies) $(objects)
	@$(MKDIR) $(dir $@)
	$(CXX) $(objects) -o $@ $(LDFLAGS)



# rule to generate a dep file by using the C preprocessor
$(output_folder)/%.d: %
	@$(MKDIR) $(dir $@)
	$(CPP) -o $@ $< $(CPPFLAGS) -MM -MP -MT $(@:.d=.o)

ifeq (0, $(words $(findstring $(MAKECMDGOALS), clean)))
# include all dep files in the makefile
-include $(dependencies)
endif



$(output_folder)/%.o: % $(output_folder)/%.d
	@$(MKDIR) $(dir $@)
	$(CXX) -o $@ -c $< $(CPPFLAGS) $(CXXFLAGS)



.PHONY: clean
clean: submakefiles
	$(RM) $(dependencies) $(objects) $(objects:.o=.gcno) $(output_folder)/$(binary_name)



.PHONY: submakefiles
submakefiles:
	@for tmp_dir in $(subcomponent_folders); do \
	echo "----- $$tmp_dir -----"; \
	$(MAKE) -C $$tmp_dir $(MAKECMDGOALS) || exit; \
	echo; \
	done;
