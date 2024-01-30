## Running a local airnode to generate random numbers

```sh
npx @api3/airnode-admin generate-airnode-mnemonic
```

> Plug this mnemonic in the secrets.env file

This mnemonic is created locally on your machine using "ethers.Wallet.createRandom" under the hood.
Make sure to back it up securely, e.g., by writing it down on a piece of paper:

#################################### MNEMONIC ####################################

   ****** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****

#################################### MNEMONIC ####################################

The Airnode address for this mnemonic is: 0x4D1AbD47AdaFc2073B6e7E074C411075C0a80B9D
The Airnode xpub for this mnemonic is: xpub6CpU7QoFYgVu25ki5SEcGHgFFwL3SWzBnTXMoCrUVdfazmEyrJZMzgkSYUGDqypJU6k2vXz3vdwmzncouWqWd7tK3iJqg45gVBV77Z2QGXG

---

To get the endpointId

```sh
 npx @api3/airnode-admin derive-endpoint-id --ois-title "Random Number Request" --endpoint-name "randomNumberArray"
```

---

To run a docker process, this will run on PORT `3000`

```sh
docker run \
  --volume "$(pwd):/app/config" \
  --name random-airnode \
  --publish 3000:3000 \
  api3/airnode-client:latest
```

---

This particular endpopint from [this](https://www.randomnumberapi.com/) takes three query parameters

1. `count`

Testing this locally over the http before testing it from the contract side

```sh
curl -X POST -H 'Content-Type: application/json' -d '{"parameters": {"count": "5"}}' 'http://localhost:3000/http-data/01234567-abcd-abcd-abcd-012345678abc/0x6db9e3e3d073ad12b66d28dd85bcf49f58577270b1cc2d48a43c7025f5c27af6/'
```

This is the output we get

> {"rawValue":[1,5,3,5,4]}%

---

forge create AirnodeRrpV0 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

forge create Qrng --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
--constructor-args 0x5FbDB2315678afecb367f032d93F642f64180aa3

> So, I have my Qrng and my AirnodeRrpContract both on my local chain, my airnode up and running

fund_sponsor.js to fund sposor wallet

set_params.js to set params

can request using request_rands.js

---

airnodeAdd 0x4D1AbD47AdaFc2073B6e7E074C411075C0a80B9D
airnodeXpub xpub6CpU7QoFYgVu25ki5SEcGHgFFwL3SWzBnTXMoCrUVdfazmEyrJZMzgkSYUGDqypJU6k2vXz3vdwmzncouWqWd7tK3iJqg45gVBV77Z2QGXG
deployedQrng Contract 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
Sponsor wallet address: 0x6fDf1e43519ec7D7B9a6788f735a267CDe00EA92
endPointAddress 0x6db9e3e3d073ad12b66d28dd85bcf49f58577270b1cc2d48a43c7025f5c27af6
