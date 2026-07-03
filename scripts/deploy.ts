import { ethers } from "hardhat";

async function main() {
    console.log("Deploying AgentIntegrityProtocol...");

    const AgentIntegrityProtocol = await ethers.getContractFactory(
        "AgentIntegrityProtocol"
    );

    const contract = await AgentIntegrityProtocol.deploy();

    await contract.waitForDeployment();

    const address = await contract.getAddress();

    console.log("====================================");
    console.log("✅ Contract deployed successfully!");
    console.log("📍 Address:", address);
    console.log("====================================");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});