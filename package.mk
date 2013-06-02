DEPS:=rabbitmq-server rabbitmq-erlang-client elixir_wrapper
RETAIN_ORIGINAL_VERSION:=true
ORIGINAL_VERSION:=0.1
DO_NOT_GENERATE_APP_FILE:=

CONSTRUCT_APP_PREREQS:=mix-compile
define construct_app_commands
	mkdir -p $(APP_DIR)/ebin
	cp $(PACKAGE_DIR)/ebin/* $(APP_DIR)/ebin
endef

define package_rules

$(PACKAGE_DIR)/deps/.done:
	rm -rf $$(@D)
	mkdir -p $$(@D)
	@echo [elided] unzip ezs
	@cd $$(@D) && $$(foreach EZ,$$(wildcard $(PACKAGE_DIR)/build/dep-ezs/*.ez),unzip -q $$(abspath $$(EZ)) &&) :
	touch $$@

mix-compile: $(PACKAGE_DIR)/deps/.done
	mix clean
	ERL_LIBS=$(PACKAGE_DIR)/deps mix compile

endef