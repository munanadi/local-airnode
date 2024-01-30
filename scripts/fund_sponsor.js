const ethers = require("ethers");
const airnodeAdmin = require("@api3/airnode-admin");
require("dotenv").config();

async function main() {

  //Deploy it on the chain with the following providers
  // https://docs.api3.org/reference/qrng/chains.html
  // Sepolia - 0x2ab9f26E18B64848cd349582ca3B55c2d06f507d


  // Airnode Parameters
  // https://docs.api3.org/reference/qrng/providers.html

  const airnodeAddress = "0x4D1AbD47AdaFc2073B6e7E074C411075C0a80B9D";
  const airnodeXpub = "xpub6CpU7QoFYgVu25ki5SEcGHgFFwL3SWzBnTXMoCrUVdfazmEyrJZMzgkSYUGDqypJU6k2vXz3vdwmzncouWqWd7tK3iJqg45gVBV77Z2QGXG";
  const yourDeployedContractAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
  const amountInEther = 0.1;

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
