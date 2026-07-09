FROM node:22-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json* ./
COPY prisma ./prisma
RUN npm ci

COPY . .
RUN npx prisma generate && npm run build

FROM node:22-alpine

WORKDIR /app

ENV NODE_ENV=production

# Prisma necesita OpenSSL en Alpine
RUN apk add --no-cache openssl

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
COPY --from=builder /app/prisma ./prisma

RUN mkdir -p uploads/products

EXPOSE 3000

# Migraciones ya aplicadas en Neon vía setup-neon.sh — solo arrancar el API.
CMD ["node", "dist/src/main"]
