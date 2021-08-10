
pragma solidity ^0.8.2;

import "../openzeppelin-contracts/governance/TimelockController.sol";

contract CompanyReserveTimelock is TimelockController {
    constructor(address[] memory proposers,
        address[] memory executors) TimelockController(12 hours, proposers, executors) {
    }
}