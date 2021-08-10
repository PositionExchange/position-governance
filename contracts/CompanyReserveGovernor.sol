pragma solidity ^0.8.2;

import "../openzeppelin-contracts/token/ERC20/IERC20.sol";
import "../openzeppelin-contracts/governance/Governor.sol";
import "../openzeppelin-contracts/governance/extensions/GovernorTimelockControl.sol";
import "../openzeppelin-contracts/governance/compatibility/GovernorCompatibilityBravo.sol";
import "../openzeppelin-contracts/utils/math/SafeMath.sol";

contract CompanyReserveGovernor is Governor, GovernorCompatibilityBravo , GovernorTimelockControl {
    using SafeMath for uint256;
    IERC20 posi = IERC20(0x5CA42204cDaa70d5c773946e69dE942b85CA6706);
    uint256 private _delay = 4800; // 4 hours
    uint256 private _period = 28800; // ~ 1 day
    uint256 private _threshold = 0;
    uint256 private _quorum = 100000*10**18;
    // Dev has right to propose a proposal only
    address public dev;
    address public timelockController;

    struct ProposalReward {
        uint256 totalReward;
        uint256 totalCountedReward;
        uint256 maxAmount;
        uint256 totalDistributed;
    }

    mapping(uint256 => ProposalReward) public proposalReward;

    modifier onlyDev(){
        require(_msgSender() == dev, "Only dev");
        _;
    }

    event DevChanged(address indexed oldDev, address indexed newDev);
    event DelayChanged(uint256 indexed oldDelay, uint256 indexed newDelay);
    event PeriodChanged(uint256 indexed oldPeriod, uint256 indexed newPeriod);
    event ThresholdChanged(uint256 indexed oldThreshold, uint256 indexed newThreshold);
    event QuorumChanged(uint256 indexed oldQuorum, uint256 indexed newQuorum);

    constructor(TimelockController _timelock)
        Governor("POSICompanyReserveGovernor")
        GovernorTimelockControl(_timelock)
    {
        timelockController = address(_timelock);
        dev = _msgSender();
    }

    function changeDev(address newDev) public onlyDev {
        emit DevChanged(dev, newDev);
        dev = newDev;
    }

    function changeDelay(uint256 delay) public onlyGovernance {
        emit DelayChanged(_delay, delay);
        _delay = delay;
    }

    function changePeriod(uint256 period) public onlyGovernance {
        emit PeriodChanged(_period, period);
        _period = period;
    }

    function changeThreshold(uint256 threshold) public onlyGovernance {
        emit ThresholdChanged(_threshold, threshold);
        _threshold = threshold;
    }

    function changeQuorum(uint256 quorum_) public onlyGovernance {
        emit QuorumChanged(_quorum, quorum_);
        _quorum = quorum_;
    }

    function votingDelay() public view override returns (uint256) {
        return _delay;
    }

    function votingPeriod() public view override returns (uint256) {
        return _period;
    }

    function proposalThreshold() public view override returns (uint256) {
        return _threshold;
    }

    function getProposalReward(uint256 proposalId, address account) public view returns (uint256) {
        if(proposalReward[proposalId].totalDistributed < proposalReward[proposalId].totalCountedReward){
            uint256 _reward = getVotes(account, 0).mul(proposalReward[proposalId].totalReward).div(proposalReward[proposalId].totalCountedReward);
            if(_reward > proposalReward[proposalId].maxAmount){
                return proposalReward[proposalId].maxAmount;
            }
        }
        return 0;
    }

    // The functions below are overrides required by Solidity.

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernor)
        returns (uint256)
    {
        return _quorum;
    }


    function getVotes(address account, uint256 blockNumber)
        public
        view
        override(IGovernor)
        returns (uint256)
    {
        return posi.balanceOf(account);
    }

     function cancelWithoutReward(uint256 proposalId) public {
        super.cancel(proposalId);
    }

    function cancel(uint256 proposalId) public virtual override (GovernorCompatibilityBravo) {
        super.cancel(proposalId);
        uint256 rewardLeft = proposalReward[proposalId].totalReward.sub(proposalReward[proposalId].totalDistributed);
        if(rewardLeft > 0){
            if(posi.balanceOf(address(this)) < rewardLeft){
                rewardLeft = posi.balanceOf(address(this));
            }
             posi.transfer(_msgSender(), rewardLeft);
        }
    }

    function state(uint256 proposalId)
        public
        view
        override(Governor, IGovernor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function proposeWithReward(
        address[] memory targets, 
        uint256[] memory values, 
        bytes[] memory calldatas, 
        string memory description, 
        uint256 totalReward,
        uint256 totalCountedReward,
        uint256 maxAmount
    )
        public
        onlyDev
        returns (uint256)
    {
        uint256 proposalId = super.propose(targets, values, calldatas, description);
        posi.transferFrom(_msgSender(), address(this), totalReward);
        proposalReward[proposalId] = ProposalReward(totalReward, totalCountedReward, maxAmount, 0);
        return proposalId;
    }

    function propose(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, string memory description)
        public
        onlyDev
        override(Governor, GovernorCompatibilityBravo, IGovernor)
        returns (uint256)
    {
        return super.propose(targets, values, calldatas, description);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public
      onlyDev
      virtual 
      override(GovernorCompatibilityBravo) 
      returns (uint256)
    {
        return super.propose(targets, values, signatures, calldatas, description);
    }

    function _execute(uint256 proposalId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal
        override(Governor, GovernorTimelockControl)
    {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal
        override(Governor, GovernorTimelockControl)
        returns (uint256)
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return timelockController;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, IERC165, GovernorTimelockControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason
    ) internal virtual override(Governor) returns (uint256)
    {
        uint256 _weight = super._castVote(proposalId, account, support, reason);
        if(proposalReward[proposalId].totalDistributed < proposalReward[proposalId].totalCountedReward){
            uint256 myReward = getProposalReward(proposalId, account);
            if(posi.balanceOf(address(this)) > myReward){
                posi.transfer(_msgSender(), myReward);
                proposalReward[proposalId].totalDistributed+=myReward;
            }
        }
        return _weight;
    }
}