# swapai-backend
 Chainlink Fall Hackathon 2021 project backend

Frontend repo: https://github.com/Dhanush123/swapai-frontend

Link to the deployed frontend https://dhanush123.github.io/swapai-frontend/

## Dev Quick Start

The first things you need to do are cloning this repo and installing its
dependencies:

```sh
git clone https://github.com/Dhanush123/swapai-backend.git
cd swapai-backend
npm install
```

Then to deploy the contract to Kovan run the following (it is assumed you've put your credentials in a .env in the backend repo's root folder):
```sh
npm run deploy-kovan
```

To locally tinker with and run the frontend, in another terminal, run the following commands:

```sh
git clone https://github.com/Dhanush123/swapai-frontend.git
cd swapai-frontend
npm install
npm start
```

Note: Each time you redeploy the contract or delete the ```/contracts``` folder in the frontend repo, you will need to stop and restart the frontend.
