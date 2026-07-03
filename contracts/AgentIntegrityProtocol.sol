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

    mapping(address => Agent) public agents;
    mapping(string => Execution) public executions;

    Dispute[] public disputes;

    event AgentRegistered(address indexed owner, string name);

    event ExecutionStored(string executionId, string proofHash);

    event DisputeRaised(string executionId, string reason);

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

    function getDisputes()
        public
        view
        returns (Dispute[] memory)
    {
        return disputes;
    }
}