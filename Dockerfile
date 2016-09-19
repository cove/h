FROM debian:jessie
MAINTAINER Hypothes.is Project and contributors

WORKDIR /h
VOLUME /h

EXPOSE 5000

ENV LANG C.UTF-8
ENV PATH /usr/local/bin:$PATH

# Install dependencies.
RUN apt-get -y update \
    && apt-get -y install ca-certificates \
                          build-essential \
                          libffi6 libffi-dev libpq5 libpq-dev \
                          python-dev git netcat curl \
    && curl -o get-pip.py https://bootstrap.pypa.io/get-pip.py \
    && python get-pip.py

# Install latest offical Node distribution binary.
# https://github.com/nodejs/docker-node/blob/62a39d8d527a8992734ba2d066c3983fe560ee44/6.6/wheezy/Dockerfile
# gpg keys listed at https://github.com/nodejs/node
RUN set -ex \
  && for key in \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
  ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done

ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 6.6.0

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar --no-same-owner -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs

# Copy the in the application files.
COPY . ./

# Install Python packages.
ENV PATH /h/bin:$PATH
ENV PYTHONIOENCODING utf_8
ENV PYTHONPATH /h:$PYTHONPATH
RUN pip install --no-cache-dir -r requirements.txt


# Build frontend assets.
RUN npm install --production \
  && NODE_ENV=production node_modules/.bin/gulp build \
  && (find node_modules -name hypothesis -prune -o -mindepth 1 -maxdepth 1 -print0 | xargs -0 rm -r) \
  && npm cache clean

# Clean up to reduce image size.
RUN rm -rf /root/.npm /root/.cache /tmp/* \
    && apt-get -y remove build-essential \
    && apt-get -y autoremove

# Run server as non-root user.
RUN groupadd hypothesis && useradd -d /h -g hypothesis hypothesis
USER hypothesis

CMD ["newrelic-admin", "run-program", "gunicorn", "--paste", "conf/app.ini"]

