FROM node:10-alpine

# Create app directory
WORKDIR /usr/src/app

# For npm@5 or later, copy package-lock.json as well
COPY package.json package-lock.json ./

# Install app dependencies
RUN npm install && npm cache clean --force

# Bundle app source
COPY . .

EXPOSE 8080

CMD [ "npm", "start" ]
