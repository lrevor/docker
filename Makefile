#PROJECTS = cbbwiki jellyfin piwigo plex portainer
COMPOSE_FILES = $(wildcard */docker-compose.yml)
COMPOSE_UP_FILES = $(COMPOSE_FILES:.yml=.up)
COMPOSE_DOWN_FILES = $(COMPOSE_FILES:.yml=.down)
COMPOSE_PULL_FILES = $(COMPOSE_FILES:.yml=.pull)
COMPOSE_PS_FILES = $(COMPOSE_FILES:.yml=.ps)
ENV_DIR = ../../env
CERTS_DIR = ../../certs
CERT_FILES = $(CERTS_DIR)/Wildcard.crt $(CERTS_DIR)/Wildcard.key $(CERTS_DIR)/jellyfin/jellyfin.p12 $(CERTS_DIR)/plex/plex.p12 $(CERTS_DIR)/portainer/portainer.crt $(CERTS_DIR)/portainer/portainer.key

cbbwiki/docker-compose.up: cbbwiki/docker-compose.yml $(ENV_DIR)/local.env $(ENV_DIR)/cbbwiki.env
jellyfin/docker-compose.up: jellyfin/docker-compose.yml $(ENV_DIR)/local.env $(CERTS_DIR)/jellyfin/jellyfin.p12
piwigo/docker-compose.up: piwigo/docker-compose.yml $(ENV_DIR)/local.env $(ENV_DIR)/piwigo.env
plex/docker-compose.up: plex/docker-compose.yml $(ENV_DIR)/local.env $(ENV_DIR)/plex.env $(CERTS_DIR)/plex/plex.p12
portainer/docker-compose.up: portainer/docker-compose.yml $(ENV_DIR)/local.env $(CERTS_DIR)/portainer/portainer.crt $(CERTS_DIR)/portainer/portainer.key

$(CERTS_DIR)/Wildcard.crt: 
	@echo Retriving $@ 
	@scp admin@pfsense.irevor.org:/conf/acme/Wildcard.crt $@
	@chmod 660 $@

$(CERTS_DIR)/Wildcard.key: 
	@echo Retriving $@ 
	@scp admin@pfsense.irevor.org:/conf/acme/Wildcard.key $@
	@chmod 660 $@

$(CERTS_DIR)/jellyfin/jellyfin.p12: $(CERTS_DIR)/Wildcard.key $(CERTS_DIR)/Wildcard.crt
	@echo Creating $@
	@openssl pkcs12 -export -in $(CERTS_DIR)/Wildcard.crt -inkey $(CERTS_DIR)/Wildcard.key -out $@ -passout pass:""
	@chmod 660 $@

$(CERTS_DIR)/plex/plex.p12: $(CERTS_DIR)/Wildcard.key $(CERTS_DIR)/Wildcard.crt
	@echo Creating $@
	@openssl pkcs12 -export -in $(CERTS_DIR)/Wildcard.crt -inkey $(CERTS_DIR)/Wildcard.key -out $@ -passout pass:plex
	@chmod 660 $@

$(CERTS_DIR)/portainer/portainer.crt: $(CERTS_DIR)/Wildcard.crt
	@echo Deploying $@ from $<
	@cp $< $@

$(CERTS_DIR)/portainer/portainer.key: $(CERTS_DIR)/Wildcard.key
	@echo Deploying $@ from $<
	@cp $< $@

#@echo target is $@, source is $<, dir is $(dir $<)
%.up: %.yml
	@echo ""
	@echo DIR $(dir $<)
	@cd $(dir $<); docker compose down -v
	@-cd $(dir $<); /bin/rm docker-compose.up
	@cd $(dir $<); docker compose up -d
	@touch $@

%.down: %.yml
	@echo ""
	@echo DIR $(dir $<)
	@cd $(dir $<); docker compose down -v
	@-cd $(dir $<); /bin/rm docker-compose.up

%.pull: %.yml
	@echo ""
	@echo DIR $(dir $<)
	@-cd $(dir $<); docker compose pull

%.ps: %.yml
	@echo ""
	@echo DIR $(dir $<)
	@cd $(dir $<); docker compose ps

up:	$(COMPOSE_UP_FILES) $(CERT_FILES)

down:	$(COMPOSE_DOWN_FILES)

pull:	$(COMPOSE_PULL_FILES)

ps:	$(COMPOSE_PS_FILES)
