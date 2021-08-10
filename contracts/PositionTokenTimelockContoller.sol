
pragma solidity ^0.8.2;

import "../openzeppelin-contracts/governance/TimelockController.sol";

interface PositionToken {
    function notifyGenesisAddresses(address[] memory _receivers, uint _value) external;
    function excludeAccount(address account) external;
    function includeAccount(address account) external;
}

contract PositionTokenTimelockContoller is TimelockController {
    address public dev;
    PositionToken posi = PositionToken(0x5CA42204cDaa70d5c773946e69dE942b85CA6706);

    event DevChanged(address indexed oldDev, address indexed newDev);

    modifier onlyDev(){
        require(_msgSender() == dev, "Only dev");
        _;
    }

    constructor(address[] memory proposers,
        address[] memory executors) TimelockController(20 hours, proposers, executors) 
    {
        dev = _msgSender();
    }

     /**
     * @dev Changes new dev.
     *
     * Emits a {DevChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the timelock itself. This can only be achieved by scheduling and later executing
     * an operation where the timelock is the target and the data is the ABI-encoded call to this function.
     */
    function changeDev(address newDev) external {
        require(msg.sender == address(this), "caller must be timelock");
        emit DevChanged(dev, newDev);
        dev = newDev;
    }

    /**
     * @dev Call to `notifyGenesisAddresses` in Position token contract
     * this function only emit the event `Transfer` to notify `receivers` have received
     * the Genesis reward.
     * 
     * Requirements:
     *
     * - The caller must be the dev address.
     */
    function notifyGenesisAddresses(address[] memory _receivers, uint _value) external onlyDev {
        posi.notifyGenesisAddresses(_receivers, _value);
    }

    /**
     * @dev Call to `excludeAccount` in Position token contract
     * this function will exclude `account` out of RFI list. That means that account cannot receive the transfer fee
     * 
     * Allowing dev to call directly in order to exclude the accounts faster.
     *
     * Requirements:
     *
     * - The caller must be the dev address.
     */
    function excludeAccount(address account) external onlyDev {
        posi.excludeAccount(account);
    }

    /**
     * @dev Call to `includeAccount` in Position token contract
     * this function will include `account` into RFI list. That means that account can receive the transfer fee
     * 
     * Allowing dev to call directly in order to include the accounts faster.
     *
     * Requirements:
     *
     * - The caller must be the dev address.
     */
    function includeAccount(address account) external onlyDev {
        posi.includeAccount(account);
    }
}