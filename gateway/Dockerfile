############
# Gateway  #
############

FROM node:20-alpine

WORKDIR /app

ENV NODE_ENV=production

COPY package.json ./
# Use `npm install` instead of `npm ci` because there is no package-lock.json in this repo.
RUN npm install --omit=dev

COPY src ./src

# Gateway listens on GATEWAY_PORT (5921 by requirement)
ENV GATEWAY_PORT=5921
EXPOSE 5921

CMD ["npm", "run", "start"]

