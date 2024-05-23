const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());
  /*
  PLACEHOLDERSINCEBETA = Placeholder while the beta is in development.
  */

  const Oracle = "PLACEHOLDERSINCEBETA"; 
  const JobId = ethers.utils.formatBytes32String("PLACEHOLDERSINCEBETA"); 
  const Fee = ethers.utils.parseUnits("0.1", "ether"); //adjustable fee
  const LinkToken = "PLACEHOLDERSINCEBETA"; 

  const MetadataScanner = await ethers.getContractFactory("ERC721MetadataScanner");
  const metadataScanner = await MetadataScanner.deploy(Oracle, JobId, Fee, LinkToken);

  await metadataScanner.deployed();

  console.log("ERC721MetadataScanner deployed to:", metadataScanner.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
