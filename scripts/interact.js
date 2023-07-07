async function main() {
  const [owner, addr1] = await ethers.getSigners();

  const contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
  const myContract = await hre.ethers.getContractAt(
    "CarMarketplace",
    contractAddress
  );
  const car = await myContract.connect(addr1).addCar(123, 456, "testurl", {
    value: hre.ethers.parseEther("0.01"),
  });
  console.log(`${car}`);

  console.log(`Total Cars ${await myContract.totalCars()}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
