# Multi-stage Dockerfile for SprintDock
# Targets:
#  - builder: installs dev deps, builds the app
#  - production: clean install of production deps only, copies built artifacts from builder
#  - development: installs all deps and runs the app in watch/dev mode

# Builder stage: installs all dependencies (including dev) and builds the app
FROM node:25-alpine3.21 AS builder
WORKDIR /usr/src/app

# Install build dependencies (use npm ci for reproducible installs)
COPY package*.json ./
# Install both prod and dev deps so build tools (typescript, nest-cli, etc.) are available
RUN npm ci

# Copy source and build
COPY . .
RUN npm run build


# Production stage: clean install of production-only dependencies and copy built artifacts
FROM node:25-alpine3.21 AS production
WORKDIR /usr/src/app
ENV NODE_ENV=production

# Copy only package manifests and lockfile for a clean install
COPY package*.json ./
# Perform a clean install and omit dev dependencies
RUN npm ci --omit=dev

# Copy built artifacts and any runtime files from builder
COPY --from=builder /usr/src/app/dist ./dist
# If your app needs other runtime files (public, prisma, migrations, etc.) copy them too
# COPY --from=builder /usr/src/app/prisma ./prisma
# COPY --from=builder /usr/src/app/public ./public

EXPOSE 3000
CMD ["node", "dist/main"]


# Development stage: installs all dependencies and keeps the source for live development
FROM node:25-alpine3.21 AS development
WORKDIR /usr/src/app
ENV NODE_ENV=development

# Install dependencies including dev for local development
COPY package*.json ./
RUN npm install

# Copy full source
COPY . .

EXPOSE 3000
# Use your dev start script; adjust if different in package.json
CMD ["npm", "run", "start:dev"]