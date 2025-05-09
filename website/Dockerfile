# use the official Bun image
# see all versions at https://hub.docker.com/r/oven/bun/tags
FROM oven/bun:1.2.7 AS base
WORKDIR /usr/src/app

# install dependencies into temp directory
# this will cache them and speed up future builds
FROM base AS install

# install with --production (exclude devDependencies)
RUN mkdir -p /temp/prod
COPY package.json bun.lock /temp/prod/
RUN cd /temp/prod && bun install --frozen-lockfile --production

# copy node_modules from temp directory
# then copy all (non-ignored) project files into the image
FROM base AS build
COPY --from=install /temp/prod/node_modules node_modules
COPY . .

ENV NODE_ENV=production
RUN mkdir /public
RUN bun build ./index.html --outdir=/public

# copy production dependencies and source code into final image
FROM nginx
COPY --from=build /public /usr/share/nginx/html
