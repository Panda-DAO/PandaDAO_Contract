// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SmartWalletChecker {

    mapping(address => bool) public isManager;
    mapping(address => bool) public isAllowed;

    constructor() {
        isManager[msg.sender] = true;
    }

    /**
     * @notice Sets the status of a manager
     * @param _manager The address of the manager
     * @param _status The status to allow the manager 
     */
    function setManager(
        address _manager,
        bool _status
    )
        external
        onlyManager
    {
        isManager[_manager] = _status;

        emit SetManager(_manager, _status);
    }

    /**
     * @notice Sets the status of a contract to be allowed or disallowed
     * @param _contract The address of the contract
     * @param _status The status to allow the manager 
     */
    function setAllowedContract(
        address _contract,
        bool _status
    )
        external
        onlyManager
    {
        isAllowed[_contract] = _status;

        emit SetAllowedManager(_contract, _status);
    }

    modifier onlyManager() {
        require(isManager[msg.sender], "!manager");
        _;
    }

    /* ========== EVENTS ========== */
    event SetManager(address manager, bool status);
    event SetAllowedManager(address contractAddr, bool status);
}
