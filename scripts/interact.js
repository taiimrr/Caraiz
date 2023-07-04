async function main() {
  const contractAddress = "0x9a676e781a523b5d0c0e43731313a708cb607508";
  const myContract = await hre.ethers.getContractAt(
    "CarMarketplace",
    contractAddress
  );

  console.log(`Total Cars ${await myContract.totalCars()}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
