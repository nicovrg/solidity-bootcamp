// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol"; 

import "./ERC721_.sol";

contract Vote {

    /*//////////////////// CONFIG //////////////////*/
    using Strings for string;

    /*//////////////////// ERRORS //////////////////*/
    error NotAnHolder();
    error NotProposalOwner();
    error ProposalPending(string errorMsg, uint256 start);
    error ProposalEnded();
    error ProposalCanceled();

    /*//////////////////// EVENTS //////////////////*/
    
    event CreateProposal(uint256 proposalId, bytes32 name, string[] optionsContentArray);
    event CancelProposal(uint256 proposalId, bytes32 name);
    event VoteOnProposal(uint256 proposalId, bytes32 name, string selected, uint nbVote);
    event ProposalQuorum(uint256 proposalId, bytes32 name, uint256 nbVotes, uint256 quorum);
    event ProposalFailed(uint256 proposalId, bytes32 name, uint256 nbVotes, uint256 quorum);
    event ProposalSucceded(uint256 proposalId, bytes32 name, string result, uint256 votes);
    event ProposalEndedWithEquality(uint256 proposalId, bytes32 name);

    /*//////////////////// VARIABLES //////////////////*/
    
    enum STATE {
        PENDING,
        ACTIVE,
        SUCCESS,
        FAIL,
        CANCELED
    }
    
    struct Proposal {
        STATE state;
        address owner;
        uint256 start;
        bytes32 name;
        uint256 nbVotes;
        uint256[] optionsResultArray;
        string[] optionsContentArray;
        uint256 winningProposalIndex;
        bool equality;
    }

    uint256 private _proposalId;
    uint256 private _quorum; // how many votes as a percentage are required to pass or fail a proposal
    uint256 private _notice; // how much time is given as notice prior to vote
    uint256 private _period; // how much time the vote post notice last
    uint8 private _maxOptions;

    mapping(uint256 => Proposal) private _proposals;

    address private immutable ERC721_CONTRACT_ADDR;

    /*//////////////////// CONSTRUCTOR //////////////////*/

    constructor(uint256 quorum, uint256 notice, uint256 period, uint8 maxOptions, address nftContractAddr) {
        _proposalId = 0;
        _quorum = quorum;
        _notice = notice;
        _period = period;
        _maxOptions = maxOptions;
        ERC721_CONTRACT_ADDR = nftContractAddr;
    }

    /*//////////////////// GETTERS //////////////////*/

    function getQuorum() external view returns(uint256) {
        return _quorum;
    }
    function getNotice() external view returns(uint256) {
        return _notice;
    }
    function getPeriod() external view returns(uint256) {
        return _period;
    }
    function getMaxOptions() external view returns(uint8) {
        return _maxOptions;
    }
    function getProposalState(uint256 proposalId) external view returns(STATE) {
        return _proposals[proposalId].state;
    }
    function getProposalOwner(uint256 proposalId) external view returns(address) {
        return _proposals[proposalId].owner;
    }
    function getProposalName(uint256 proposalId) external view returns(bytes32) {
        return _proposals[proposalId].name;
    }
    function getProposalStart(uint256 proposalId) external view returns(uint256) {
        return _proposals[proposalId].start;
    }
    function getProposalEnd(uint256 proposalId) external view returns(uint256) {
        return _proposals[proposalId].start + _period;
    }
    function getProposalNbVotes(uint256 proposalId) external view returns(uint256) {
        return _proposals[proposalId].nbVotes;
    }
    function getProposalOptionsContent(uint256 proposalId) external view returns(string[] memory) {
        return _proposals[proposalId].optionsContentArray;
    }
    function getProposalOptionsResult(uint256 proposalId) external view returns(uint256[] memory) {
        return _proposals[proposalId].optionsResultArray;
    }

    function getProposalOptionsResultFromId(uint256 proposalId, uint256 id) external view returns(uint256) {
        return _proposals[proposalId].optionsResultArray[id];
    }

    function getWinningProposalIndex(uint256 proposalId) external view returns(uint256) {
        return _proposals[proposalId].winningProposalIndex;
    }

    function getEquality(uint256 proposalId) external view returns(bool) {
        return _proposals[proposalId].equality;
    }
    function getNftContractAddr() external view returns(address) {
        return ERC721_CONTRACT_ADDR;
    }

    /*//////////////////// LOGIC PROPOSALS //////////////////*/
    modifier canCancel(address addr, uint256 proposalId) {
        if (addr != _proposals[proposalId].owner)
            revert NotProposalOwner();
        _;
    }

    function createProposal(bytes32 name, string[] memory optionsContentArray) external returns (uint256) {
        require(name.length > 0, "proposal need a name");
        _proposalId++;
        _proposals[_proposalId].state = STATE.PENDING;
        _proposals[_proposalId].owner = msg.sender;
        _proposals[_proposalId].start = block.timestamp + _notice;
        _proposals[_proposalId].name = name;
        _proposals[_proposalId].nbVotes = 0;
        _proposals[_proposalId].optionsContentArray = optionsContentArray;
        _proposals[_proposalId].optionsResultArray = new uint8[](optionsContentArray.length);
        emit CreateProposal(_proposalId, name, optionsContentArray);
        return _proposalId;
    }

    function cancelProposal(uint256 proposalId) external canCancel(msg.sender, proposalId) {
        if (_proposals[proposalId].state != STATE.CANCELED) {
            _proposals[proposalId].state = STATE.CANCELED;
            emit CancelProposal(proposalId, _proposals[proposalId].name);      
        }
    }

    /*//////////////////// LOGIC VOTES //////////////////*/

    modifier canVote(address addr) {
        (bool success, bytes memory data) = ERC721_CONTRACT_ADDR.call(abi.encodeWithSignature('balanceOf(address)', addr));
        require (success, "cannot fetch voter balance");
        if (0 == uint256(bytes32(data)))
            revert NotAnHolder();
        _;
    } 

    modifier proposalIsActive(uint256 proposalId) {
        if (_proposals[proposalId].state  == STATE.CANCELED)
            revert ProposalCanceled();
        if (block.timestamp < _proposals[proposalId].start)
            revert ProposalPending("proposal pending wait for block", _proposals[proposalId].start);
        if (block.timestamp > _proposals[proposalId].start + _period)
            revert ProposalEnded();
        _;
    }

    function updateProposalState(uint256 proposalId) public {
        if (block.timestamp > _proposals[proposalId].start + _period) {
            if (_proposals[proposalId].nbVotes < _quorum) {
                emit ProposalFailed(proposalId, _proposals[proposalId].name, _proposals[proposalId].nbVotes, _quorum);
                _proposals[proposalId].state = STATE.FAIL;
            } else {
                _proposals[proposalId].state = STATE.SUCCESS;
                emit ProposalQuorum(proposalId, _proposals[proposalId].name, _proposals[proposalId].nbVotes, _quorum);
                (_proposals[proposalId].equality, _proposals[proposalId].winningProposalIndex) = checkWinningProposal(proposalId);
                if (_proposals[proposalId].equality == false) {
                    _proposals[proposalId].winningProposalIndex = _proposals[proposalId].winningProposalIndex;
                    emit ProposalSucceded(proposalId, _proposals[proposalId].name, _proposals[proposalId].optionsContentArray[_proposals[proposalId].winningProposalIndex], _proposals[proposalId].optionsResultArray[_proposals[proposalId].winningProposalIndex]);
                } else {
                    emit ProposalEndedWithEquality(proposalId, _proposals[proposalId].name);
                }
            }
        }
    }

    function checkWinningProposal(uint256 proposalId) internal view returns (bool, uint256) {
        bool equality = false;
        uint256 winningProposalIndex = 0;
        uint256 winningProposalNbVote = 0;

        for (uint i = 0; i < _proposals[proposalId].optionsResultArray.length; i++) {
            if (winningProposalNbVote < _proposals[proposalId].optionsResultArray[i]) {
                winningProposalNbVote = _proposals[proposalId].optionsResultArray[i];
                winningProposalIndex = i;
            }
        }

        for (uint i = winningProposalIndex + 1; i < _proposals[proposalId].optionsResultArray.length; i++) {
            if (winningProposalNbVote == _proposals[proposalId].optionsResultArray[i])
                equality = true;
        }

        return (equality, winningProposalIndex);
    }

    function voteOnProposal(uint256 proposalId, uint8 choice) external canVote(msg.sender) proposalIsActive(proposalId) {
        (, bytes memory data) = ERC721_CONTRACT_ADDR.call(abi.encodeWithSignature('balanceOf(address)', msg.sender));
        _proposals[proposalId].nbVotes += uint256(bytes32(data));
        _proposals[proposalId].optionsResultArray[choice] += uint256(bytes32(data));
        emit VoteOnProposal(proposalId, _proposals[proposalId].name, _proposals[proposalId].optionsContentArray[choice], uint256(bytes32(data)));
        updateProposalState(proposalId);
    }
}