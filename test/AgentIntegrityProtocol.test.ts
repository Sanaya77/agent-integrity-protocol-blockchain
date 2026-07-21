import { expect } from "chai";
import { ethers } from "hardhat";

describe("AgentIntegrityProtocol", function () {
    let contract: any;
    let owner: any;
    let agent1: any;
    let user1: any;

    beforeEach(async function () {
        [owner, agent1, user1] = await ethers.getSigners();
        const AgentIntegrityProtocolFactory = await ethers.getContractFactory("AgentIntegrityProtocol");
        contract = await AgentIntegrityProtocolFactory.deploy();
        await contract.waitForDeployment();
    });

    describe("Agent Registration", function () {
        it("should allow an account to register an agent", async function () {
            await contract.connect(agent1).registerAgent("TravelGPT", "Travel", 95, 500);

            const agent = await contract.agents(agent1.address);
            expect(agent.name).to.equal("TravelGPT");
            expect(agent.agentType).to.equal("Travel");
            expect(agent.trustScore).to.equal(95n);
            expect(agent.stake).to.equal(500n);
            expect(agent.registered).to.equal(true);
        });

        it("should emit AgentRegistered event", async function () {
            await expect(contract.connect(agent1).registerAgent("TravelGPT", "Travel", 95, 500))
                .to.emit(contract, "AgentRegistered")
                .withArgs(agent1.address, "TravelGPT");
        });
    });

    describe("Execution Storage", function () {
        beforeEach(async function () {
            await contract.connect(agent1).registerAgent("TravelGPT", "Travel", 95, 500);
        });

        it("should allow registered agent to store execution proof", async function () {
            await contract.connect(agent1).storeExecution("EXEC-001", "0xHASH123");

            const execution = await contract.getExecution("EXEC-001");
            expect(execution.executionId).to.equal("EXEC-001");
            expect(execution.proofHash).to.equal("0xHASH123");
            expect(execution.owner).to.equal(agent1.address);
            expect(execution.verified).to.equal(true);
        });

        it("should reject execution storage from unregistered agent", async function () {
            await expect(
                contract.connect(user1).storeExecution("EXEC-999", "0xHASH999")
            ).to.be.revertedWith("Agent not registered");
        });
    });

    describe("Dispute Resolution & Consensus", function () {
        beforeEach(async function () {
            await contract.connect(agent1).registerAgent("TravelGPT", "Travel", 95, 500);
            await contract.connect(agent1).storeExecution("EXEC-001", "0xHASH123");
        });

        it("should allow any user to raise a dispute", async function () {
            await contract.connect(user1).raiseDispute("EXEC-001", "Conflicting output signature");

            const disputesCount = await contract.getDisputesCount();
            expect(disputesCount).to.equal(1n);

            const dispute = await contract.getDispute(0);
            expect(dispute.executionId).to.equal("EXEC-001");
            expect(dispute.reason).to.equal("Conflicting output signature");
            expect(dispute.resolved).to.equal(false);
        });

        it("should resolve valid dispute and slash agent trust score", async function () {
            await contract.connect(user1).raiseDispute("EXEC-001", "Malicious output");

            await expect(contract.resolveDispute(0, true, 15))
                .to.emit(contract, "DisputeResolved")
                .withArgs(0, "EXEC-001", true, 80);

            const dispute = await contract.getDispute(0);
            expect(dispute.resolved).to.equal(true);

            const agent = await contract.agents(agent1.address);
            expect(agent.trustScore).to.equal(80n);

            const execution = await contract.getExecution("EXEC-001");
            expect(execution.verified).to.equal(false);
        });

        it("should resolve invalid dispute and maintain/increase agent trust score", async function () {
            await contract.connect(user1).raiseDispute("EXEC-001", "False alarm");

            await contract.resolveDispute(0, false, 3);

            const agent = await contract.agents(agent1.address);
            expect(agent.trustScore).to.equal(98n); // 95 + 3

            const execution = await contract.getExecution("EXEC-001");
            expect(execution.verified).to.equal(true);
        });

        it("should prevent resolving an already resolved dispute", async function () {
            await contract.connect(user1).raiseDispute("EXEC-001", "Flawed output");
            await contract.resolveDispute(0, true, 10);

            await expect(contract.resolveDispute(0, true, 5))
                .to.be.revertedWith("Dispute already resolved");
        });
    });

    describe("Admin Control", function () {
        beforeEach(async function () {
            await contract.connect(agent1).registerAgent("TravelGPT", "Travel", 95, 500);
        });

        it("should allow contract owner to update agent trust score directly", async function () {
            await contract.connect(owner).updateAgentTrust(agent1.address, 99);
            const agent = await contract.agents(agent1.address);
            expect(agent.trustScore).to.equal(99n);
        });

        it("should prevent non-owner from updating trust score", async function () {
            await expect(
                contract.connect(user1).updateAgentTrust(agent1.address, 100)
            ).to.be.revertedWith("Only protocol owner can perform this action");
        });
    });
});
