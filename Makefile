#locations
ENV_DIR = ../../env
CERTS_DIR = ../../certs

#Source Files
COMPOSE_FILES = $(wildcard *-compose.yml)
DOCKERFILE_FILES = $(wildcard *.Dockerfile)

#Temp Files
COMPOSE_UP_FILES = $(COMPOSE_FILES:-compose.yml=.up)
COMPOSE_DOWN_FILES = $(COMPOSE_FILES:-compose.yml=.down)
COMPOSE_PULL_FILES = $(COMPOSE_FILES:-compose.yml=.pull)
COMPOSE_PS_FILES = $(COMPOSE_FILES:-compose.yml=.ps)
COMPOSE_BUILD_FILES = $(DOCKERFILE_FILES:.Dockerfile=.build)
ALL_TEMP_FILES = $(COMPOSE_UP_FILES) $(COMPOSE_DOWN_FILES) $(COMPOSE_PULL_FILES) $(COMPOSE_PS_FILES) $(COMPOSE_BUILD_FILES)

#output files
CERT_FILES = $(CERTS_DIR)/Wildcard.crt $(CERTS_DIR)/Wildcard.key $(CERTS_DIR)/jellyfin/jellyfin.p12 $(CERTS_DIR)/plex/plex.p12 $(CERTS_DIR)/portainer/portainer.crt $(CERTS_DIR)/portainer/portainer.key
ALL_OUTPUT_FILES = $(CERTS_FILES)

$(CERTS_DIR)/Wildcard.crt: 
	@echo Retriving $@ 
	@mkdir -p $(CERTS_DIR)
	@scp admin@pfsense.irevor.org:/conf/acme/Wildcard.crt $@
	@chmod 660 $@

$(CERTS_DIR)/Wildcard.key: 
	@echo Retriving $@ 
	@mkdir -p $(CERTS_DIR)
	@scp admin@pfsense.irevor.org:/conf/acme/Wildcard.key $@
	@chmod 660 $@

$(CERTS_DIR)/jellyfin/jellyfin.p12: $(CERTS_DIR)/Wildcard.key $(CERTS_DIR)/Wildcard.crt
	@echo Creating $@
	@mkdir -p $(CERTS_DIR)/jellyfin
	@openssl pkcs12 -export -in $(CERTS_DIR)/Wildcard.crt -inkey $(CERTS_DIR)/Wildcard.key -out $@ -passout pass:""
	@chmod 660 $@

$(CERTS_DIR)/plex/plex.p12: $(CERTS_DIR)/Wildcard.key $(CERTS_DIR)/Wildcard.crt
	@echo Creating $@
	@mkdir -p $(CERTS_DIR)/plex
	@openssl pkcs12 -export -in $(CERTS_DIR)/Wildcard.crt -inkey $(CERTS_DIR)/Wildcard.key -out $@ -passout pass:plex
	@chmod 660 $@

$(CERTS_DIR)/portainer/portainer.crt: $(CERTS_DIR)/Wildcard.crt
	@echo Deploying $@ from $<
	@mkdir -p $(CERTS_DIR)/portainer
	@cp $< $@

$(CERTS_DIR)/portainer/portainer.key: $(CERTS_DIR)/Wildcard.key
	@echo Deploying $@ from $<
	@mkdir -p $(CERTS_DIR)/portainer
	@cp $< $@

#@echo target is $@, source is $<, dir is $(dir $<)
%.up: %-compose.yml $(ENV_DIR)/local.env %.pull
	@echo ""
	@echo $(@:.up=-compose.yml)
	@docker compose -f $(@:.up=-compose.yml) -p $(@:.up=) down -v
	@-/bin/rm $@
	@docker compose -f $(@:.up=-compose.yml) -p $(@:.up=) up -d
	@touch $@

%.down: %-compose.yml
	@echo ""
	@echo $(@:.down=-compose.yml)
	@docker compose -f $(@:.down=-compose.yml) -p $(@:.down=) down -v
	@-/bin/rm $(@:.down=.up)

%.pull: %-compose.yml
	@echo ""
	@echo $(@:.pull=-compose.yml)
	@-docker compose -f $(@:.pull=-compose.yml) -p $(@:.pull=) pull
	@touch $@

%.ps: %-compose.yml
	@echo ""
	@echo $(@:.ps=-compose.yml)
	@docker compose -f $(@:.ps=-compose.yml) -p $(@:.ps=) ps

%.build: %-compose.yml %.Dockerfile %.pull
	@echo ""
	@echo $(@:.build=-compose.yml)
	@docker compose -f $(@:.build=-compose.yml) -p $(@:.build=) build
	@touch $@

cbbwiki.up: $(ENV_DIR)/cbbwiki.env cbbwiki.build
piwigo.up: $(ENV_DIR)/piwigo.env piwigo.build
plex.up: $(ENV_DIR)/plex.env $(CERTS_DIR)/plex/plex.p12

.PHONY: up down pull ps build certs clean
clean:  down
	@-/bin/rm $(ALL_TEMP_FILES) $(ALL_OUTPUT_FILES)
	@-docker system prune -f
certs: 	$(CERT_FILES)
build:	$(COMPOSE_BUILD_FILES)
up:	build certs $(COMPOSE_UP_FILES)
down:	$(COMPOSE_DOWN_FILES)
pull:	$(COMPOSE_PULL_FILES)
ps:	$(COMPOSE_PS_FILES)
