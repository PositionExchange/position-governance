pragma solidity ^0.8.2;
import "../openzeppelin-contracts/token/ERC20/IERC20.sol";
import "../openzeppelin-contracts/access/Ownable.sol";

/**
 * The company reserve contract to hold POSI. Controlled by a Timelock and Governor contract
 * Whenever dev want to withdraw money from this contract. 
 * They need to propose a proposal to vote for approval from the Community
 */

contract POSICompanyReserve is Ownable {
    IERC20 public posi = IERC20(0x5CA42204cDaa70d5c773946e69dE942b85CA6706);

    // Only withdrawable to dev address inorder to avoid attacking in governor contract
    address public dev;
    event DevChanged(address oldDev, address newDev);

    constructor() {
        dev = msg.sender;
    }

    function changeDev(address newDev) public {
        require(msg.sender == dev, "only dev");
        emit DevChanged(dev, newDev);
        dev = newDev;
    }

    function withdraw(uint256 amount) external onlyOwner {
        posi.transfer(dev, amount);
    }

    function withdrawToken(IERC20 token, uint256 amount) external onlyOwner {
        token.transfer(dev, amount);
    }
}