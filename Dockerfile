FROM node:19

WORKDIR /app

RUN mkdir api
RUN mkdir ui

#I guess you run npm install w/o the coed first
#not sure why but this is the pattern I've seen everywhere
COPY api/package*.json ./api/
COPY ui/package*.json ./ui/

RUN cd api && npm ci
RUN cd ui && npm ci

#bundle app source
COPY . .


RUN cd api && npm run build
RUN cd ui && npm run build

EXPOSE 3000
ENV PORT 3000

CMD ["node", "api/build/bundle.js"]

