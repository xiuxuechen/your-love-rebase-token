// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ILoveReBaseToken} from "./interfaces/ILoveReBaseToken.sol";

/**
 * @title 银行柜员
 * @dev 负责存款、赎回
 */
contract BankTeller {
    ILoveReBaseToken public immutable iLoveReBaseToken;

    /**
     * ----------------------事件------------------------
     */
    event Deposit(address indexed user, uint256 indexed amount);
    event Redeem(address indexed user, uint256 indexed amount);

    /**
     * --------------------装饰器----------------------
     */
    /// @dev 确保大于0
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert BankTeller__NeedsMoreThanZero();
        }
        _;
    }

    /**
     * ----------------------异常------------------------
     */
    error BankTeller__RedeemFailed();
    error BankTeller__NeedsMoreThanZero();

    /**
     * --------------------构造函数----------------------
     */
    constructor(ILoveReBaseToken _yourLoverReBaseToken) {
        iLoveReBaseToken = _yourLoverReBaseToken;
    }

    receive() external payable {}

    /**
     * @notice 存款
     */
    function deposit() external payable {
        iLoveReBaseToken.mint(
            msg.sender,
            msg.value,
            iLoveReBaseToken.getYearInterestRate()
        );
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice 赎回
     * @param _amount 赎回数量
     */
    function redeem(uint256 _amount) external moreThanZero(_amount) {
        if (_amount == type(uint256).max) {
            _amount = iLoveReBaseToken.balanceOf(msg.sender);
        }
        iLoveReBaseToken.burn(msg.sender, _amount);
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert BankTeller__RedeemFailed();
        }
        emit Redeem(msg.sender, _amount);
    }
}
