FROM node:6

RUN npm install -g brunch

WORKDIR /workdir
EXPOSE 3333
EXPOSE 9485

CMD ["brunch", "watch", "--server"]