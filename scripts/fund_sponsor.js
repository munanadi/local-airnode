const ethers = require("ethers");
const airnodeAdmin = require("@api3/airnode-admin");
require("dotenv").config();

async function main() {

  //Deploy it on the chain with the following providers
  // https://docs.api3.org/reference/qrng/chains.html
  // Sepolia - 0x2ab9f26E18B64848cd349582ca3B55c2d06f507d


  // Airnode Parameters
  // https://docs.api3.org/reference/qrng/providers.html

  const airnodeAddress = "0x55f921E8dc6ff46c608C688949620163cd573642";
  const airnodeXpub = "xpub6BkKZrd73VX9C4vbsry9Y9woAMnhoGLZKE1xnCFmHfDWb7WdP2cdPEfCNuwnDTvyfNRUkYgCA87vHRsMyTS4RCMkPvFqHbXX6cvK2DeqWYX";
  const yourDeployedContractAddress = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";
  const amountInEther = 1;

  // Connect to a provider (e.g., Infura, Alchemy)
  const provider = new ethers.JsonRpcProvider(process.env.PROVIDER_URL);

  // Use your private key (keep this secure!)
  const privateKey = process.env.PRIVATE_KEY;
  const wallet = new ethers.Wallet(privateKey, provider);

  // We are deriving the sponsor wallet address from the RrpRequester contract address
  // using the @api3/airnode-admin SDK. You can also do this using the CLI
  // https://docs.api3.org/airnode/latest/reference/packages/admin-cli.html
  // Visit our docs to learn more about sponsors and sponsor wallets
  // https://docs.api3.org/airnode/latest/concepts/sponsor.html
  const sponsorWalletAddress = await airnodeAdmin.deriveSponsorWalletAddress(
    airnodeXpub,
    airnodeAddress,
    yourDeployedContractAddress
  );

  console.log(`Sponsor wallet address: ${sponsorWalletAddress}`);

  const receipt = await wallet.sendTransaction({
    to: sponsorWalletAddress,
    value: ethers.parseEther(amountInEther.toString()),
  });
  console.log(
    `Funding sponsor wallet at ${sponsorWalletAddress} with ${amountInEther} ...`
  );
  
  let txReceipt = await receipt.wait();
  if (txReceipt.status === 0) {
    throw new Error("Transaction failed");
  }
  console.log("Sponsor wallet funded");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
