// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TokenClaims is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public  token; 
    string public label; 


    constructor () { 
        _disableInitializers();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    modifier vestingScheduleExists {
        require(_vestingSchedule.start != 0, "Vesting not started yet.");
        _;
    }
    
    modifier nonReentrant() {
        require(!_nonReentrant[msg.sender], "Claims: reentrancy attack");
        _nonReentrant[msg.sender] = true;
        _;
        _nonReentrant[msg.sender] = false;
    }

    modifier admin () {
        require (admins[msg.sender], "Claims: not admin");
        _;
    }

    mapping (address => uint256) private allocations;
    mapping (address => uint256) private claimed;
    mapping (address => bool) private _nonReentrant;
    mapping (address => bool) private admins;
    uint256 private totalVestedAmount;
    uint256 private totalClaimedAmount;

    struct VestingSchedule {
        uint256 start;
        uint256 rounds;
        uint256 interval;
    }

    struct Allocated {
        address who;
        uint256 amount;
    }

    mapping (address => bool) private addressExists;
    mapping (address => uint256) private  addressIndices;

    Allocated[] private _allocated;
    VestingSchedule private _vestingSchedule;

    event Claim     (address claimer, uint256 amount);
    event Withdraw  (address owner, uint256 amount);
    event Allocate  (address to, uint256 amount);


    function initialize (address _token, string memory _label) public initializer {
        __Ownable_init();
        token = IERC20Upgradeable(_token);
        label = _label;
        admins[msg.sender] = true;
    }


/*
State modifier fonctions
*/  

    function setAdmin (address _admin, bool _status) public onlyOwner {
        admins[_admin] = _status;
    }

    function updateToken (address _token) public onlyOwner {
        token = IERC20Upgradeable(_token);
    }

    function setVestingSchedule (uint256 _start, uint256 _rounds, uint256 _interval) public admin {
        require (_rounds > 0 && _interval > 0 && _start + _rounds * _interval > block.timestamp, "Not valid input.");
        _vestingSchedule = VestingSchedule(_start, _rounds, _interval);
    }

    function setAllocations (address[] calldata _beneficiaries, uint256[] calldata amounts, bool add) public admin {
        
        require(_beneficiaries.length == amounts.length, "Unmatched addresses and amounts.");

        for (uint i; i < _beneficiaries.length; i++) {
            /* 
            do we need to emit an event for each allocation? 
            */
            emit Allocate(_beneficiaries[i], amounts[i]);

            if (!addressExists[_beneficiaries[i]]) {
                _allocated.push(Allocated(_beneficiaries[i], amounts[i]));
                addressIndices[_beneficiaries[i]] = _allocated.length - 1;
                addressExists[_beneficiaries[i]] = true;
                totalVestedAmount += amounts[i];
                allocations[_beneficiaries[i]] = add? amounts[i] + allocations[_beneficiaries[i]] : amounts[i];
                continue;
            } else {
                totalVestedAmount -= allocations[_beneficiaries[i]];
                totalVestedAmount += amounts[i];
                allocations[_beneficiaries[i]] = amounts[i];
                _allocated[addressIndices[_beneficiaries[i]]].amount = amounts[i];
            }


        }
    }

    function claim () public nonReentrant vestingScheduleExists {
        int256 amount = getClaimable();
        require(amount > 0, "Negative amount");
        uint256 _amount = uint256(amount);
        emit Claim(msg.sender, _amount);
        require(_amount < token.balanceOf(address(this)), "Not enough contract balance.");
        claimed[msg.sender] += _amount;
        totalClaimedAmount += _amount;
        token.transfer(msg.sender, _amount);   
    }

    function setLabel (string memory newLabel) public admin {
        label = newLabel;
    }

    function transferToken (IERC20Upgradeable _token, address to, uint256 amount) public onlyOwner {
        IERC20Upgradeable tokken = _token;
        tokken.transfer(to, amount);
    }


/*
State read functions 
*/

    function getAdmin (address account) public view returns (bool) {
        return admins[account];
    }

    function getLeftout () public view admin returns (int256) {
        return int256(totalVestedAmount) - int256(totalClaimedAmount);
    }
    function allAllocations () public view admin returns (Allocated[] memory) {
        return _allocated;
    }

    function totalVested () public view admin returns (uint256) {
        return totalVestedAmount;
    }

    function singleAllocation (address who) public view admin returns (uint256) {
        return allocations[who];
    }

    function totalClaimed () public view admin returns (uint256) {
        return totalClaimedAmount;
    }

    function singleClaimed (address who) public view admin returns (uint256) {
        return claimed[who];
    }

    function getAllocation () public view returns (uint256) {
        return allocations[msg.sender];
    }

    function getClaimed () public view returns (uint256) {
        return claimed[msg.sender];
    }

    /*
    Returns how much of allocation have been unlocked till the given moment. 
    This includes the amount alreadhy claimed and the amount is awailable to claim
    */
    function getUnlocked () public view vestingScheduleExists returns (uint256) {
        if (!isVestingScheduleStarted() || allocations[msg.sender] == 0) {
            return 0;
        }
        if (getEndTime() < block.timestamp) {
            return allocations[msg.sender];
        }
        uint256 _round;
        for (uint tmp = _vestingSchedule.start; tmp < block.timestamp; tmp += _vestingSchedule.interval) {
            _round += 1;
        }
        uint256 unlocked = (allocations[msg.sender] / _vestingSchedule.rounds) * _round;

        return unlocked;
    }

    /*
    Retunrs how much can the message sender claim at that given moment of interaction 
    */
    function getClaimable () public view vestingScheduleExists returns (int256) {
        return (int256(getUnlocked()) - int256(claimed[msg.sender]));
    }


    /* 
    If the start time has already been passed, a vesting pool has started 
    */
    function isVestingScheduleStarted () public view returns (bool) {
        if (_vestingSchedule.start > 0 && _vestingSchedule.start < block.timestamp) {
            return true;
        } 
        
        return false;
    }

    /* 
    If the start time has already been passed and end time not still arrived, a vesting pool is active 
    */
    function isVestingScheduleActive () public view returns (bool) {
        if (
            _vestingSchedule.start > 0 
            && _vestingSchedule.start < block.timestamp 
            && (_vestingSchedule.start + _vestingSchedule.interval * _vestingSchedule.rounds) > block.timestamp 
            ) {
            return true;
        } 
        
        return false;
    }
    /*
    Returns the time left to the schedule end
    */
    function getTimeLeft () public view returns (uint256) {
        require(isVestingScheduleActive(), "No vesting schedule esists.");
        return _vestingSchedule.start + _vestingSchedule.rounds * _vestingSchedule.interval - block.timestamp;
    }

    /*
    Returns the start time of the schedule
    */
    function getStartTime () public view returns (uint256 ) {
        return _vestingSchedule.start;
    }
    /*
    Returns the ending time of schedule
    */
    function getEndTime () public view returns (uint256) {
        return _vestingSchedule.interval * _vestingSchedule.rounds + getStartTime(); 
    }

    /*
    Returns the interval in seconds => interval is the gap period between unlocking 
    */
    function getIntervalInSeconds () public view returns (uint256) {
        return _vestingSchedule.interval;
    }
}

    
