const { version } = require('chai');
const hre = require('hardhat')

async function verifyContract(address, args, contract ) {
    const verifyObj = {address}
    if(args){
        verifyObj.constructorArguments = args
    }
    if(contract){
        verifyObj.contract = contract;
    }
    console.log("verifyObj", verifyObj)
    return hre
    .run("verify:verify", verifyObj)
    .then(() =>
      console.log(
        "Contract address verified:",
        address
      )
    );
}

async function processTransactionAndWait(tx, w = 5){
  return tx.wait(w)
}

async function main() {
    const {ethers} = hre
    const accounts = await hre.ethers.getSigners();
    let contract
    const contract1 = await ethers.getContractFactory("PositionTokenTimelockContoller")
    contract = await contract1.deploy([accounts[0].address],[accounts[0].address],{gasLimit: 9000000})
    await contract.deployTransaction.wait(5)
    console.log("Contract Address", contract.address)
    await verifyContract(contract.address, [[accounts[0].address],[accounts[0].address]], "contracts/PositionTokenTimelockContoller.sol:PositionTokenTimelockContoller")
    const contract2 = await ethers.getContractFactory("PositionTokenGovernor")
    const contract2Deploy = await contract2.deploy(contract.address, {gasLimit: 9000000})
    await contract2Deploy.deployTransaction.wait(5)
    console.log("Contract Address", contract2Deploy.address)
    await verifyContract(contract2Deploy.address,[contract.address])
    await processTransactionAndWait(await contract.grantRole('0xd8aa0f3194971a2a116679f7c2090f6939c8d4e01a2a8d7e41d55e5351469e63', contract2Deploy.address))
    await processTransactionAndWait(await contract.grantRole('0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1', contract2Deploy.address))
    
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error.message);
    process.exit(1);
  });