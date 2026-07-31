# --- Etapa de Construcción ---
FROM golang:1.24-alpine AS builder

# Dependencias de compilación (make + node para el frontend)
RUN apk add --no-cache make nodejs npm

WORKDIR /app

# Copiamos archivos de dependencias primero para aprovechar la caché de Docker
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Construimos frontend + binarios.
# 'make prepare' instala deps del web-client.
# 'make all' compila el frontend, lo copia a internal/webassets/dist y
# luego 'go build' lo EMBEBE en el binario (go:embed).
RUN make prepare && make all

# --- Etapa Final ---
FROM alpine:latest

RUN apk --no-cache add ca-certificates wget \
    && addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# El binario es AUTOCONTENIDO: los assets web van embebidos dentro.
# Ya no hace falta copiar bin/web-client por separado ni pelear con permisos.
COPY --from=builder --chown=appuser:appgroup /app/bin/mmb-server ./mmb-server
RUN chmod 555 ./mmb-server

# Directorio de datos, propiedad de appuser
RUN mkdir -p /app/data && chown -R appuser:appgroup /app/data

USER appuser
RUN touch data/proxies.txt data/uas.txt

# --- HEALTHCHECK ---
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

EXPOSE 3000

CMD ["./mmb-server"]
