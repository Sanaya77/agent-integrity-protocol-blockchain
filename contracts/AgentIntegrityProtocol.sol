// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract AgentIntegrityProtocol {

    struct Agent {
        string name;
        string agentType;
        uint256 trustScore;
        uint256 stake;
        bool registered;
    }

    struct Execution {
        string executionId;
        string proofHash;
        address owner;
        uint256 timestamp;
        bool verified;
    }

    struct Dispute {
        string executionId;
        string reason;
        bool resolved;
    }

    address public owner;

    mapping(address => Agent) public agents;
    mapping(string => Execution) public executions;

    Dispute[] public disputes;

    event AgentRegistered(address indexed owner, string name);
    event ExecutionStored(string executionId, string proofHash);
    event DisputeRaised(string executionId, string reason);
    event DisputeResolved(uint256 indexed disputeIndex, string executionId, bool validDispute, uint256 updatedTrustScore);
    event TrustScoreUpdated(address indexed agentOwner, uint256 newTrustScore);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only protocol owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function registerAgent(
        string memory name,
        string memory agentType,
        uint256 trustScore,
        uint256 stake
    ) public {
        agents[msg.sender] = Agent(
            name,
            agentType,
            trustScore,
            stake,
            true
        );

        emit AgentRegistered(msg.sender, name);
    }

    function storeExecution(
        string memory executionId,
        string memory proofHash
    ) public {
        require(
            agents[msg.sender].registered,
            "Agent not registered"
        );

        executions[executionId] = Execution(
            executionId,
            proofHash,
            msg.sender,
            block.timestamp,
            true
        );

        emit ExecutionStored(executionId, proofHash);
    }

    function raiseDispute(
        string memory executionId,
        string memory reason
    ) public {
        disputes.push(
            Dispute(
                executionId,
                reason,
                false
            )
        );

        emit DisputeRaised(
            executionId,
            reason
        );
    }

    function resolveDispute(
        uint256 disputeIndex,
        bool validDispute,
        uint256 trustScoreDelta
    ) public {
        require(disputeIndex < disputes.length, "Invalid dispute index");
        require(!disputes[disputeIndex].resolved, "Dispute already resolved");

        disputes[disputeIndex].resolved = true;
        string memory execId = disputes[disputeIndex].executionId;
        address agentOwner = executions[execId].owner;

        if (validDispute) {
            // Dispute is valid -> Agent was non-compliant
            executions[execId].verified = false;
            if (agents[agentOwner].registered) {
                if (agents[agentOwner].trustScore > trustScoreDelta) {
                    agents[agentOwner].trustScore -= trustScoreDelta;
                } else {
                    agents[agentOwner].trustScore = 0;
                }
            }
        } else {
            // Dispute is invalid -> Agent was compliant
            executions[execId].verified = true;
            if (agents[agentOwner].registered) {
                agents[agentOwner].trustScore += trustScoreDelta;
                if (agents[agentOwner].trustScore > 100) {
                    agents[agentOwner].trustScore = 100;
                }
            }
        }

        uint256 finalTrust = agents[agentOwner].registered ? agents[agentOwner].trustScore : 0;

        emit DisputeResolved(disputeIndex, execId, validDispute, finalTrust);
        if (agents[agentOwner].registered) {
            emit TrustScoreUpdated(agentOwner, finalTrust);
        }
    }

    function updateAgentTrust(
        address agentOwner,
        uint256 newTrustScore
    ) public onlyOwner {
        require(agents[agentOwner].registered, "Agent not registered");
        require(newTrustScore <= 100, "Trust score cannot exceed 100");

        agents[agentOwner].trustScore = newTrustScore;
        emit TrustScoreUpdated(agentOwner, newTrustScore);
    }

    function getDisputes()
        public
        view
        returns (Dispute[] memory)
    {
        return disputes;
    }

    function getDisputesCount()
        public
        view
        returns (uint256)
    {
        return disputes.length;
    }

    function getDispute(uint256 index)
        public
        view
        returns (Dispute memory)
    {
        require(index < disputes.length, "Index out of bounds");
        return disputes[index];
    }

    function getExecution(string memory executionId)
        public
        view
        returns (Execution memory)
    {
        return executions[executionId];
    }
}