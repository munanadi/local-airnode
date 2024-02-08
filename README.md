# Running a airnode setup locally.

This is a repo to get started on running a airnode locally that talks to a random number api online [here](https://www.randomnumberapi.com/) and writes it to our contract back. This project uses Foundry.

> The below image is how I think this works. If not, please feel free to ignore this and help me out.

![alt outline-of-rrp](https://github.com/munanadi/local-airnode/blob/main/outline.png)

> `secrets.env` and `config.json` are the two files required to start the airnode docker container.

---

## Setps (Major)

#### 0. Have `docker` and `foundry` installed.

#### 1. Get `anvil` up and running.

#### 2. Deploy contracts - AirnodeRrpV0, AirnodeRrpV0DryRun, Qrng

```sh
forge create AirnodeRrpV0DryRun --private-key $PRIVATE_KEY
```

```sh
[⠊] Compiling...No files changed, compilation skipped
[⠒] Compiling...
Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
Transaction hash: 0x593feb4bb7b6a6db37046ae9c662108ed6ae536e30de4598065c96429b0c5924
```

```sh
forge create AirnodeRrpV0 --private-key $PRIVATE_KEY
```

```sh
[⠊] Compiling...No files changed, compilation skipped
[⠒] Compiling...
Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Deployed to: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
Transaction hash: 0x1cd64fc273ac067ef8166ea818db86450ef91cee11998b9d6b2385a4d06f20c9
```

> Use the above `AirnodeRrpV0` address as the construtor param in our `Qrng.sol` `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512` in my case

```sh
forge create Qrng --rpc-url $PROVIDER_URL \
--private-key $PRIVATE_KEY \
--constructor-args 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
```

```sh
[⠊] Compiling...No files changed, compilation skipped
[⠒] Compiling...
Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Deployed to: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
Transaction hash: 0x05f3cd46018e7afa43ffc3aebb856307b2f0da508206b640444d50a967a827da
```

> This is our deployed contract address now.
> `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0` in my case.

Now, swap the `AirnodeRrpV0` and `AirnodeRrpV0DryRun` addresses in `config.json` under here

```json
"contracts": {
  "AirnodeRrp": "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
  "AirnodeRrpDryRun": "0x5FbDB2315678afecb367f032d93F642f64180aa3"
},
```

3. Create airnode mnemonic

```sh
npx @api3/airnode-admin generate-airnode-mnemonic
```

```sh
This mnemonic is created locally on your machine using "ethers.Wallet.createRandom" under the hood.
Make sure to back it up securely, e.g., by writing it down on a piece of paper:

################################### MNEMONIC ###################################

aerobic describe assault acid valley mom cruise evolve tiger journey live melody

################################### MNEMONIC ###################################

The Airnode address for this mnemonic is: 0x164c9E7a1Bd4a9d6F38B32FFCd7732CA6d02C9A7
The Airnode xpub for this mnemonic is: xpub6CNu7RScbvuhc9xxSQ6gYVcrCUFMgrxffbzrFXkC4DJ9SFHsodXPN5dN3DX2MWu23iM9nzc7evjGrivjhim2y4NJgMtq2A4LYL7yBRmqaCu
```

Copy the above `mnemonic` to `secrets.env` and store this `airnodeAddress` and `airnodeXpub` for later.

4. Fund the sponsor address

Now we need to add funds to our sponsor wallet that pays for gas. This wallet will be used to write our data to the chain.

Swap out the values for `airnodeAddress`, `airnodeXpub` and `contractAddress` in `fund_sponsor.js` and run it.

```sh
node scripts/fund_sponsor.js
```

```sh
Sponsor wallet address: 0xE73C6f4CB4f64A5828e6f5c99E97c456534E90A0
Funding sponsor wallet at 0xE73C6f4CB4f64A5828e6f5c99E97c456534E90A0 with 1 ...
Sponsor wallet funded
```

> Now we get out sponsor wallet address. Save this.

5. Deploy the airnode using docker

Finally now run the airnode locally as a docker container that will tie the whole thing together.

```sh
docker run \
  --network bridge \
  --volume "$(pwd):/app/config" \
  --name random-airnode \
  --publish 3000:3000 \
  api3/airnode-client:latest
```

```sh
WARNING: The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested
[2024-02-08 17:10:19.931] INFO Gateway "httpSignedDataGateway" not enabled.
[2024-02-08 17:10:19.940] INFO Gateway "oevGateway" not enabled.
[2024-02-08 17:10:19.943] INFO HTTP (testing) gateway listening for request on "http://localhost:3000/http-data/01234567-abcd-abcd-abcd-012345678abc/:endpointId"
[2024-02-08 17:10:19.946] INFO API gateway server running on "http://localhost:3000"
```

> We can use the above localhost:3000 url to see if the airnode is working alright or not.

Making a request to check if things are alright.

```sh
 curl -X POST -H 'Content-Type: application/json' -d '{"parameters": {"count": "5"}}' 'http://localhost:3000/http-data/01234567-abcd-abcd-abcd-012345678abc/0x6db9e3e3d073ad12b66d28dd85bcf49f58577270b1cc2d48a43c7025f5c27af6/'
```

`0x6db9e3e3d073ad12b66d28dd85bcf49f58577270b1cc2d48a43c7025f5c27af6` is the endpoint id that is derived from the title and name
using the `npx @api3/airnode-admin derive-endpoint-id` command.

We see, we do get the number of random numbers that we requested back

```
{"rawValue":[48,73,88,25,11],"encodedValue":"0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000004900000000000000000000000000000000000000000000000000000000000000580000000000000000000000000000000000000000000000000000000000000019000000000000000000000000000000000000000000000000000000000000000b","values":[["48","73","88","25","11"]]}%
```

6. Set params on your contracat

Now call the `setRequestParameters` in `Qrng.sol` with the requried parameters.

Swap out `airnodeAddress`, `endPointAddress`, `SponsorWallet`, `contractAddress` in `set_params.js` and run the script.

```sh
node scripts/set_params.js
```

```sh
Setting Params, waiting for it to be confirmed...
Request Parameters set
```

Now that the parameters have been set. We can finally request for the random numbers in our contract.

7. Request for random numbers

Swap out the `contractAddress` and `requestCount` (to get that many random numbers) in the `request_rands.js` script and call it.

```sh
node scripts/request_rands.js
```

```
Requesting Random Number...
Random Numbers Requested...
Number 0: 84
Number 1: 45
Number 2: 42
```

DONE! Now you can use the random numbers or any other data from the internet inside your contracts like this.

---

## What's in the repo.

#### `./mocks` has all the contracts that are required for this.

1. `Qrng.sol` is the requester contract that has requested for random numbers
2. `AirnodeRrpV0.sol` is the contract that fulfills the requests for random number
3. `AirnodeRrpV0DryRun.sol` is the contract present to calculate for gas on localnets
4. `RrpRequesterV0.sol` is the contract that is actually inherited by `Qrng.sol`

> NOTE: I have flattened most of the files to be accomodated as a single solidity file instead of using libraries.

> There are some breaking changes wrt Openzeppellin, and API3's contracts compiled only on solidity@0.8.9

#### `./scripts` has all the scripts that will mimic the interactions that we will make with the contracts

1. `fund_sponsor.js` script that will help us fund a sponsor wallet
2. `set_params.js` script will help us set params in our smart contract
3. `request_rand.js` script will make the request for random numbers and print them out.

#### Commands to know

1. `npx @api3/airnode-admin generate-airnode-mnemonic` will help us create a airnode address and xpub address
2. `npx @api3/airnode-admin derive-endpoint-id --ois-title "<TITILE>" --endpoint-name "<ENDPOINT_NAME>"` will help us create a endpoint id
