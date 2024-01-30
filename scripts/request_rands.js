const ethers = require("ethers");
const airnodeAdmin = require("@api3/airnode-admin");
const { decode } = require("@api3/airnode-abi");
require("dotenv").config();
const ABI = require("./abi.json");

async function main() {
  //const contractAddress = "your_contract_address";
  const contractAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
  //How many random numbers to request
  const requestCount = 3;

  // Connect to a provider (e.g., Infura, Alchemy)
  const provider = new ethers.JsonRpcProvider(process.env.PROVIDER_URL);
  // Use your private key (keep this secure!)
  const privateKey = process.env.PRIVATE_KEY;
  const wallet = new ethers.Wallet(privateKey, provider);

  // Smart contract ABI and address
  const contractABI = ABI;

  // Create a contract instance
  const contract = new ethers.Contract(contractAddress, contractABI, wallet);

  // Make request for random number
  console.log("Requesting Random Number...");
  const requestRandomNumber = await contract.makeRequestUint256Array(
    requestCount,
  );

  let requestID;
  // Listen for all events from the contract
  contract.once("*", (event) => {
    // filter out with the specific transaction hash
    if (event.log.transactionHash === requestRandomNumber.hash) {
      requestID = event.args[0];
      console.log("requestID: ", requestID);
    }
  });

  let txReceipt2 = await requestRandomNumber.wait();
  if (txReceipt2.status === 0) {
    throw new Error("Transaction failed");
  }
  console.log("Random Numbers Requested...");

  const response = await new Promise((resolve) => {
    contract.once(
      contract.filters.ReceivedUint256Array(requestID, null),
      (event) => {
        resolve(event);
      },
    );
  });

  const args = response.args;
  // console.log("Response:", args);
  // console.log("Response [1][0]:", args[1][0]);

  // Check if args is defined and is an array
  if (args && Array.isArray(args)) {
    // Iterate over the array inside args[1]
    // Assuming the numbers are in args[1] based on your provided structure
    args[1].forEach((num, index) => {
      console.log(`Number ${index}:`, num.toString());
    });
  } else {
    console.log("Arguments not found or not in expected format.");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
