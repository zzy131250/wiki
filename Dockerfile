FROM node:6.11.4

RUN npm install gitbook-cli -g

RUN gitbook -V

WORKDIR /usr/src/app

CMD gitbook build . docs
