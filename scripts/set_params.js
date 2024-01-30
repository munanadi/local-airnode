const ethers = require("ethers");
require("dotenv").config();
const ABI = require("./abi.json");

async function main() {
  const airnodeAddress = "0x4D1AbD47AdaFc2073B6e7E074C411075C0a80B9D";
  const endPointAddress =
    "0x6db9e3e3d073ad12b66d28dd85bcf49f58577270b1cc2d48a43c7025f5c27af6";
  const SponsorWallet = "0x6fDf1e43519ec7D7B9a6788f735a267CDe00EA92";
  //const contractAddress = "your_contract_address";
  const contractAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";

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
