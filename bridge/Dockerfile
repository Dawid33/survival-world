from node:23-alpine3.20

run mkdir /app
workdir /app
copy package.json /app
run npm install 

copy main.js /app
cmd ["npm", "run", "main"]

