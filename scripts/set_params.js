const ethers = require("ethers");
require("dotenv").config();
const ABI = require("./abi.json");

async function main() {
  const airnodeAddress = "0x55f921E8dc6ff46c608C688949620163cd573642";
  const endPointAddress =
    "0x6db9e3e3d073ad12b66d28dd85bcf49f58577270b1cc2d48a43c7025f5c27af6";
  const SponsorWallet = "0x081a2574eF229b36F99809dCad6F33d276D4687F";
  //const contractAddress = "your_contract_address";
  const contractAddress = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";

  // Connect to a provider (e.g., Infura, Alchemy)
  const provider = new ethers.JsonRpcProvider(process.env.PROVIDER_URL);
  // Use your private key (keep this secure!)
  const privateKey = process.env.PRIVATE_KEY;
  const wallet = new ethers.Wallet(privateKey, provider);

  // Smart contract ABI and address
  const contractABI = ABI;

  // Create a contract instance
  const contract = new ethers.Contract(contractAddress, contractABI, wallet);

  console.log("Setting Params, waiting for it to be confirmed...");

  const receipt = await contract.setRequestParameters(
    airnodeAddress,
    endPointAddress,
    SponsorWallet,
  );

  let txReceipt = await receipt.wait();
  if (txReceipt.status === 0) {
    throw new Error("Transaction failed");
  }
  console.log("Request Parameters set");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
