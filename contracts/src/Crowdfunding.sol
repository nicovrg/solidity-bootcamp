// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "../lib/forge-std/src/console2.sol";

error CampaignIsNotActive(string errorMsg);
error CampaignExpired (string errorMsg1, uint256 currentBlockNumber, string errorMsg2, uint256 endCampaignBlockNumber);

contract Crowdfunding {

    uint256 campaignId = 0;
    mapping (uint256 => Campaign) private _campaigns;
    mapping (address => uint256) private _userDeposit;

    enum TYPE {
        STARTUP,
        CHARITY
    }

    enum STATE {
        ACTIVE,
        NOT_FUNDED,
        PARTIALLY_FUNDED,
        FULLY_FUNDED
    }

    struct Campaign {
        uint256 id;
        string name;
        address owner;
        uint256 goal;
        uint256 fund;
        uint256 start;
        uint256 end;
        STATE state;
        TYPE campain_type;
    }

    event created(uint256 indexed campaignId, address owner);
    event canceled(uint256 indexed campaignId);
    event fundReceived(uint256 indexed campaignId, uint256 indexed value);
    event fundWithdraw(uint256 indexed campaignId);

    modifier isOwner(uint256 id, address addr) {
        require(_campaigns[id].owner == addr, "cannot withdraw funds from a campaign you're not the owner of");
        _;
    }

    modifier isActive(uint256 id) {
        if (_campaigns[id].state != STATE.ACTIVE) {
            revert CampaignIsNotActive("this campaign isn't active");
        }
        _;
    }

    function getCampaign(uint256 id) external returns(Campaign memory CampaignsMap) {
        updateCampaignState(id, false);
        return _campaigns[id];
    }

    function getUserDeposit(address addr) external view returns(uint256) {
        return _userDeposit[addr];
    }
    function createCampaign(string memory _name, uint256 _goal, uint256 _duration, bool  _startup, bool _charity) external returns (uint256) {
        require(_startup != _charity, "campaign cannot be startup and charity at the same time");
        require(_duration < 60 days, "campaign duration should be less than 60d");
        campaignId++;
        _campaigns[campaignId].id = campaignId;
        _campaigns[campaignId].name = _name;
        _campaigns[campaignId].owner = msg.sender;
        _campaigns[campaignId].start = block.timestamp;
        _campaigns[campaignId].end = block.timestamp + _duration;
        _campaigns[campaignId].fund = 0;
        _campaigns[campaignId].goal = _goal;
        _campaigns[campaignId].state = STATE.ACTIVE;
        if (_startup == true)
            _campaigns[campaignId].campain_type = TYPE.STARTUP;
        else if (_charity == true)
            _campaigns[campaignId].campain_type = TYPE.CHARITY;
        emit created(campaignId, _campaigns[campaignId].owner);
        return campaignId;
    }

    function fundCampaign(uint256 id) external payable isActive(id) {
        require(block.timestamp < _campaigns[id].end, "campaign ended");
        _campaigns[id].fund += msg.value;
        _userDeposit[msg.sender] += msg.value;
        updateCampaignState(id, false);
        emit fundReceived(id, msg.value);
    }

    function updateCampaignState(uint256 id, bool endCampaign) internal {
        if (endCampaign == true || block.timestamp >= _campaigns[id].end || _campaigns[id].fund >= _campaigns[id].goal) {
            if (_campaigns[id].fund >= _campaigns[id].goal)
                _campaigns[id].state = STATE.FULLY_FUNDED;
            else if (_campaigns[id].fund > 0 && _campaigns[id].fund < _campaigns[id].goal)
                _campaigns[id].state = STATE.PARTIALLY_FUNDED;
            else
                _campaigns[id].state = STATE.NOT_FUNDED;
        }
    }

    function cancelCampaign(uint256 id) external payable isActive(id) isOwner(id, msg.sender) {
        updateCampaignState(id, true);
        emit canceled(id);
    }

    function withdrawFund(uint256 id) external isOwner(id, msg.sender) {
        updateCampaignState(id, false);
        require(_campaigns[id].state != STATE.ACTIVE, "cannot withdraw funds from a campaign that is active");
        (bool success, ) = msg.sender.call{value: _campaigns[id].fund}("");
        if (success == true)
            _campaigns[id].fund = 0;
        emit fundWithdraw(id);
    }
}