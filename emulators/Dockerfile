# Base: Java 21 (necessário para firebase-tools >= 13) + Node 20 + Python 3.12
FROM eclipse-temurin:21-jre-jammy

RUN apt-get update && \
    apt-get install -y curl gnupg software-properties-common && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs python3.12 python3.12-venv && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install firebase-tools globally so we can `exec firebase` directly
# (npx intercepts SIGTERM and kills the child before --export-on-exit runs)
RUN npm install -g firebase-tools

WORKDIR /app
