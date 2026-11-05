# BOOKIA API image (DOC-02). The source arrives from ../bookia/api as the
# additional build context "api_src" (see docker-compose.yml).

FROM node:24-alpine AS deps
WORKDIR /app
COPY --from=api_src package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

FROM node:24-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY --from=api_src --chown=node:node . .
# Never ship a local .env, tests or the host's node_modules
RUN rm -rf node_modules .env tests coverage
COPY --from=deps --chown=node:node /app/node_modules ./node_modules
USER node
EXPOSE 4000
HEALTHCHECK --interval=15s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -qO- http://localhost:4000/api/health || exit 1
CMD ["node", "server.js"]
