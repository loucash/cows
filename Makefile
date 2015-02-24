PROJECT := cows

ERL := erl
EPATH = -pa ebin -pz deps/*/ebin
PLT_APPS = $(shell ls $(ERL_LIB_DIR) | grep -v interface | sed -e 's/-[0-9.]*//')
DIALYZER_OPTS= -Wno_undefined_callbacks --fullpath

.PHONY: all build_plt compile configure console deps clean depclean dialyze

all:
	@./rebar skip_deps=true compile

build_plt:
	@dialyzer --build_plt --apps $(PLT_APPS)

compile:
	@./rebar compile

configure:
	@./rebar get-deps compile

console:
	$(ERL) -sname $(PROJECT) $(EPATH)

deps:
	@./rebar get-deps update-deps

clean:
	@./rebar skip_deps=true clean

depclean:
	@./rebar clean

dialyze:
	@dialyzer $(DIALYZER_OPTS) -r ebin
