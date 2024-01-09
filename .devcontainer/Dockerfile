# syntax=docker/dockerfile:1

ARG VARIANT="20"
FROM mcr.microsoft.com/vscode/devcontainers/javascript-node:0-${VARIANT}

# Install some generally useful tools
RUN apt-get update && apt-get -y install --no-install-recommends curl git

# Install SAP CAP SDK globally
USER node
RUN npm install -g @sap/cds-dk
WORKDIR /home/node
