BIN_DIR := bin
CLI_PKG := ./cmd/mmb-cli
SERVER_PKG := ./cmd/mmb-server
CLI_BIN := $(BIN_DIR)/mmb-cli
SERVER_BIN := $(BIN_DIR)/mmb-server
GO := go

# Directorio donde el paquete webassets espera los ficheros a embeber.
EMBED_DIR := internal/webassets/dist

.PHONY: all cli server run-cli run-server clean webclient build-all prepare

all: build-all

prepare:
	$(GO) mod tidy
	cd web-client && npm install --no-audit --no-fund

# IMPORTANTE: el orden importa. 'webclient' debe ejecutarse ANTES que 'server'
# porque go:embed incrusta el contenido de internal/webassets/dist en el
# binario durante 'go build'. Si el server se compila antes, embebería vacío.
build-all: webclient cli server

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

cli: $(BIN_DIR)
	$(GO) build -o $(CLI_BIN) $(CLI_PKG)

server: $(BIN_DIR)
	$(GO) build -o $(SERVER_BIN) $(SERVER_PKG)

run-cli: cli
	$(CLI_BIN) $(ARGS)

run-server: server
	$(SERVER_BIN) $(ARGS)

# Compila el frontend y coloca el resultado en internal/webassets/dist
# para que go:embed lo incruste en el binario del servidor.
webclient:
	cd web-client && npm install --no-audit --no-fund && npm run build
	rm -rf $(EMBED_DIR)
	mkdir -p $(EMBED_DIR)
	cp -r web-client/dist/public/* $(EMBED_DIR)/
	rm -rf web-client/dist

clean:
	rm -rf $(BIN_DIR)
	rm -rf $(EMBED_DIR)
	# Mantiene el placeholder para que go:embed no falle en un árbol limpio
	mkdir -p $(EMBED_DIR)
	touch $(EMBED_DIR)/.gitkeep
