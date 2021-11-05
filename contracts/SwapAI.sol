pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "./ISwapAI.sol";
import "./SwapUser.sol";

contract SwapAI is ISwapAI, KeeperCompatibleInterface {
    using Address for address;  
    using SafeMath for uint;

    address[] private userAddresses;
    mapping(address => SwapUser) private userData;
    OracleCaller internal oracleCaller;

    /**
    * Use an interval in seconds and a timestamp to slow execution of Upkeep
    */
    uint public immutable interval;
    uint public lastTimeStamp;

    constructor(uint updateInterval) {
      interval = updateInterval;
      lastTimeStamp = block.timestamp;
    }

    function createUser() external override {
      if (userData[msg.sender].userAddress == address(0)) {
        userData[msg.sender] = SwapUser(msg.sender, true);
        userAddresses.push(msg.sender);
        emit CreateUser(true);
      } else {
        emit CreateUser(false);
      }
    } 

    function optInToggle() external override {
      userData[msg.sender].optInStatus = !userData[msg.sender].optInStatus;
      emit OptInToggle(userData[msg.sender].optInStatus);
    }

    function isAtleastOneUserOptIn() private returns (bool) {
      for (uint i=0; i < userAddresses.length; i++) {
        if (userData[userAddresses[i]].optInStatus == true) {
          return true;
        } 
      }
      return false;
    }

    function getSwapEligibleUsers() private returns (SwapUser[]) {
      SwapUser[] users;
      for (uint i=0; i < userAddresses.length; i++) {
        SwapUser user = userData[userAddresses[i]];
        if (swapUser.optInStatus == true) {
          eligibleUsers.push(user);
        }
      }
      return users;
    }

    function swapSingleUserBalance() external {
      uint[] currentUserDataOnly = [userData[msg.sender]];
      oracleCaller.trySwapManual(currentUserDataOnly);
    }

    function swapAllUsersBalances(bool force) external {
      oracleCaller.trySwapAuto(getSwapEligibleUsers(), force); 
    }

    function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool hasIntervalPassed = (block.timestamp - lastTimeStamp) > interval;
        upkeepNeeded = hasIntervalPassed && isAtleastOneUserOptIn();
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        lastTimeStamp = block.timestamp;
        swapAllUsersBalances(false);
        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    }

    function deposit() payable {
      userData[msg.sender] += msg.value;
    };

    receive() external payable {}
}