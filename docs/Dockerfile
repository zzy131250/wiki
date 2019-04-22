FROM node:6.11.4-alpine

RUN npm install gitbook-cli -g

RUN gitbook -V

# Fixes https://github.com/GitbookIO/gitbook/issues/1309
RUN sed -i.bak 's/confirm: true/confirm: false/g' \
    /root/.gitbook/versions/3.2.3/lib/output/website/copyPluginAssets.js

WORKDIR /usr/src/app

CMD gitbook build . docs
