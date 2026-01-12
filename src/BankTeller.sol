// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IYourLoverReBaseToken} from "./interfaces/IYourLoverReBaseToken.sol";

/**
 * @title 银行柜员
 * @dev 负责存款、赎回
 */
contract BankTeller {
    IYourLoverReBaseToken public immutable iYourLoverReBaseToken;

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
    constructor(IYourLoverReBaseToken _yourLoverReBaseToken) {
        iYourLoverReBaseToken = _yourLoverReBaseToken;
    }

    receive() external payable {}

    /**
     * @notice 存款
     */
    function deposit() external payable {
        iYourLoverReBaseToken.mint(
            msg.sender,
            msg.value,
            iYourLoverReBaseToken.getYearInterestRate()
        );
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice 赎回
     * @param _amount 赎回数量
     */
    function redeem(uint256 _amount) external moreThanZero(_amount) {
        if (_amount == type(uint256).max) {
            _amount = iYourLoverReBaseToken.balanceOf(msg.sender);
        }
        iYourLoverReBaseToken.burn(msg.sender, _amount);
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert BankTeller__RedeemFailed();
        }
        emit Redeem(msg.sender, _amount);
    }
}
