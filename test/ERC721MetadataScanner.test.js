const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ERC721MetadataScanner", function () {
  let MetadataScanner, metadataScanner, oracle, jobId, fee, linkToken, deployer;

  before(async function () {
    [deployer] = await ethers.getSigners();
    MetadataScanner = await ethers.getContractFactory("ERC721MetadataScanner");
    oracle = "0xYourOracleAddress";
    jobId = ethers.utils.formatBytes32String("YourJobId");
    fee = ethers.utils.parseUnits("0.1", "ether");
    linkToken = "0xYourLinkTokenAddress";

    metadataScanner = await MetadataScanner.deploy(oracle, jobId, fee, linkToken);
    await metadataScanner.deployed();
  });

  /* 
    --> Should -->
  */
  
  it("Should deploy the contract", async function () {
    expect(metadataScanner.address).to.properAddress;
  });

  it("Should set the correct oracle", async function () {
    await metadataScanner.setOracle(oracle);
    expect(await metadataScanner.oracle()).to.equal(oracle);
  });

  it("Should set the correct jobId", async function () {
    await metadataScanner.setJobId(jobId);
    expect(await metadataScanner.jobId()).to.equal(jobId);
  });

  it("Should set the correct fee", async function () {
    await metadataScanner.setFee(fee);
    expect(await metadataScanner.fee()).to.equal(fee);
  });

  it("Should set the correct LINK token address", async function () {
    await metadataScanner.setLinkToken(linkToken);
    expect(await metadataScanner.linkToken()).to.equal(linkToken);
  });

});
