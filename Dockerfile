# Stage 1: buscar Python de Alpine standard
FROM alpine:3.22 AS python-stage
RUN apk add --no-cache python3 py3-pip

# Stage 2: imagem n8n hardened + Python copiado
FROM n8nio/n8n:2.17.6

USER root
ENTRYPOINT []

# Copiar Python do stage anterior
COPY --from=python-stage /usr/bin/python3 /usr/bin/python3
COPY --from=python-stage /usr/bin/python3.12 /usr/bin/python3.12
COPY --from=python-stage /usr/lib/python3.12 /usr/lib/python3.12
COPY --from=python-stage /usr/lib/libpython3.12.so.1.0 /usr/lib/libpython3.12.so.1.0
COPY --from=python-stage /usr/lib/libz.so.1 /usr/lib/libz.so.1

# Criar virtualenv para o Python task runner do n8n
RUN python3 -m venv /usr/local/n8n-python-venv

# Criar pasta de community nodes e garantir permissoes
RUN mkdir -p /home/node/.n8n/nodes \
  && chown -R node:node /home/node/.n8n

# Instalar community nodes
USER node
WORKDIR /home/node/.n8n/nodes
RUN npm init -y \
  && npm install \
      n8n-nodes-upload-post \
      @apify/n8n-nodes-apify

WORKDIR /home/node

USER root
COPY ./entrypoint.sh /home/node/entrypoint.sh
RUN chmod +x /home/node/entrypoint.sh \
  && chown node:node /home/node/entrypoint.sh

USER node
CMD ["/home/node/entrypoint.sh"]
