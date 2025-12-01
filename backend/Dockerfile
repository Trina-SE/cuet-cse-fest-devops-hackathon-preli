###########
# Backend #
###########

# ---- Base image for building ----
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies (only package.json is needed for caching).
# We need devDependencies (TypeScript) in the *builder* stage so that `npm run build` works.
COPY package.json tsconfig.json ./
RUN npm install

# Copy source and build
COPY src ./src
RUN npm run build

# ---- Production runtime image ----
FROM node:20-alpine AS runner

ENV NODE_ENV=production
WORKDIR /app

# Copy only what we need for runtime
COPY package.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist

# Backend listens on BACKEND_PORT (3847 by requirement)
ENV BACKEND_PORT=3847
EXPOSE 3847

CMD ["npm", "run", "start"]

