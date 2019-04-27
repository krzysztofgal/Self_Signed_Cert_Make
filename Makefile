
DOMAIN ?= example.com


COUNTRY := US
STATE := LA
COMPANY := Cert Ltd.

OUT_DIR := ./Cert_$(DOMAIN)
MKDIR := $(shell mkdir -p $(OUT_DIR))

# credits to: https://gist.github.com/fntlnz/cf14feb5a46b2eda428e000157447309
# original makefile: https://gist.github.com/xenogenesi/1b2137f769aa80b6c99d573071f5d086

# usage:
# make rootCA.crt # (rootCA.key implicitly created)
# make DOMAIN=somedomain.dev somedomain.dev.csr somedomain.dev.crt   or   make DOMAIN=somedomain.dev
# make DOMAIN=somedomain.dev verify-csr
# make DOMAIN=somedomain.dev verify-crt

# Arch / Manjaro
#The way local CA certificates are handled has changed. If you have added any locally trusted certificates:
#    Move /usr/local/share/ca-certificates/*.crt to /etc/ca-certificates/trust-source/anchors/
#    Do the same with all manually-added /etc/ssl/certs/*.pem files and rename them to *.crt
#    Instead of update-ca-certificates, run trust extract-compat
# Also see man 8 update-ca-trust and trust --help.

# Debian / Ubuntu
# Copy your CA to dir /usr/local/share/ca-certificates/
# Use command: sudo cp foo.crt /usr/local/share/ca-certificates/foo.crt
#Update the CA store: sudo update-ca-certificates

# CentOs
# Install the ca-certificates package: yum install ca-certificates
# Enable the dynamic CA configuration feature: update-ca-trust force-enable
# Add it as a new file to /etc/pki/ca-trust/source/anchors/: cp foo.crt /etc/pki/ca-trust/source/anchors/
# Use command: update-ca-trust extract

all: $(DOMAIN).csr $(DOMAIN).crt

rootCA.key:
	openssl genrsa -des3 -out $(COMPANY)_rootCA.key 4096

# create and self sign root certificate
rootCA.crt: rootCA.key
	echo -ne "$(COUNTRY)\n$(STATE)\n\n$(COMPANY)\n\n\n\n" | openssl req -x509 -new -nodes -key $(COMPANY)_rootCA.key -sha256 -days 1024 -out $(COMPANY)_$@

$(DOMAIN).key:
	openssl genrsa -out $(OUT_DIR)/$@ 2048

$(DOMAIN).conf:
	sh mkconf.sh "$(DOMAIN)" > $(OUT_DIR)/$@

$(DOMAIN).csr: $(DOMAIN).key $(DOMAIN).conf
	${MKDIR} \
	openssl req -new -sha256 -key $(OUT_DIR)/$(DOMAIN).key -subj "/C=$(COUNTRY)/ST=$(STATE)/O=$(COMPANY)/CN=$(DOMAIN)" \
		-reqexts SAN \
		-config $(OUT_DIR)/$(DOMAIN).conf \
		-out $(OUT_DIR)/$@

# verify .csr content
.PHONY: verify-csr
verify-csr:
	openssl req  -in $(OUT_DIR)/$(DOMAIN).csr -noout -text

$(DOMAIN).san.conf:
	sh mksan.sh "$(DOMAIN)" $(COUNTRY) $(STATE) "$(COMPANY)" > $(OUT_DIR)/$@

$(DOMAIN).crt: rootCA.key rootCA.crt $(DOMAIN).csr $(DOMAIN).san.conf
	openssl x509 -req -in $(OUT_DIR)/$(DOMAIN).csr -CA $(COMPANY)_rootCA.crt -CAkey $(COMPANY)_rootCA.key \
		-CAcreateserial -out $(OUT_DIR)/$@ -days 500 -sha256 \
		-extfile $(OUT_DIR)/$(DOMAIN).san.conf -extensions req_ext

# verify the certificate
.PHONY: verify-crt
verify-crt:
	openssl x509 -in $(OUT_DIR)/$(DOMAIN).crt -text -noout

.PHONY: clean
clean:
	-rm -f $(OUT_DIR)/$(DOMAIN).key $(OUT_DIR)/$(DOMAIN).csr $(OUT_DIR)/$(DOMAIN).conf $(OUT_DIR)/$(DOMAIN).san.conf $(OUT_DIR)/$(DOMAIN).crt
