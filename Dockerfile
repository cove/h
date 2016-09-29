FROM gliderlabs/alpine:3.4
MAINTAINER Hypothes.is Project and contributors

ENV TARGET_ENV=development

# Install system build and runtime dependencies.
RUN apk-install \
    ca-certificates \
    libffi \
    libpq \
    python \
    py-pip \
    nodejs \
    git

# Create the hypothesis user, group, home directory and package directory.
RUN addgroup -S hypothesis && adduser -S -G hypothesis -h /var/lib/hypothesis hypothesis
WORKDIR /var/lib/hypothesis

# Copy minimal data to allow installation of dependencies.
COPY src/memex/__init__.py ./src/memex/
COPY README.rst setup.* requirements* ./

# Install build deps, build, and then clean up if we're a prod build.
RUN apk-install --virtual build-deps \
    build-base \
    libffi-dev \
    postgresql-dev \
    python-dev \
  && pip install --no-cache-dir -U pip \
  && pip install --no-cache-dir -r requirements-$TARGET_ENV.txt \
  && if [ "$TARGET_ENV" == "production" ]; then \
        apk del build-deps || exit -1; \
     fi

# Copy the rest of the application files.
COPY . .

# Build frontend assets
RUN SASS_BINARY_PATH=$PWD/vendor/node-sass-linux-x64.node npm install --$TARGET_ENV \
  && SASS_BINARY_PATH=$PWD/vendor/node-sass-linux-x64.node NODE_ENV=$TARGET_ENV node_modules/.bin/gulp build \
  && find node_modules -name hypothesis -prune -o -mindepth 1 -maxdepth 1 -print0 | xargs -0 rm -r \
  && npm cache clean

# Set the application environment
ENV PATH /var/lib/hypothesis/bin:/var/lib/hypothesis/node_modules/.bin:$PATH
ENV PYTHONIOENCODING utf_8
ENV PYTHONPATH /var/lib/hypothesis:$PYTHONPATH

# Start the web server by default
USER hypothesis
