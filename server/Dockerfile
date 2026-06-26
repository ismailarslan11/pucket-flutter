FROM node:20-alpine
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --production
COPY server.js store.js ./
COPY scripts/ ./scripts/
ENV PORT=8080
EXPOSE 8080
CMD ["node", "server.js"]
