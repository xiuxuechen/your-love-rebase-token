// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IYourLoverReBaseToken} from "./interfaces/IYourLoverReBaseToken.sol";

contract YourLoverReBaseToken is
    ERC20,
    Ownable,
    AccessControl,
    IYourLoverReBaseToken
{
    /**
     * ----------------------异常------------------------
     */
    error YourLoverReBaseToken__InterestRateOnlyCanBeDecreased(
        uint256 currentInterestRate,
        uint256 newInterestRate
    );
    error YourLoverReBaseToken__NeedsMoreThanZero();

    /**
     * --------------------常量----------------------
     */
    //标准精度
    uint256 private constant PRECISION = 1e18;
    //年（默认单位秒）
    uint256 private constant SECONDS_PER_YEAR = 365 days;
    //授权密钥
    bytes32 public constant MINT_AND_BURN_ROLE =
        keccak256("MINT_AND_BURN_ROLE");

    /**
     * --------------------状态变量----------------------
     */
    /// @dev 默认年利率5%
    uint256 private sYearInterestRate = 5e16;
    /// @dev 用户利率
    mapping(address => uint256) public sUserInterestRate;
    /// @dev 用户最新存款时间
    mapping(address => uint256) public sUserLatestDepositTime;

    /**
     * ----------------------事件------------------------
     */
    event InterestRateChanged(uint256 oldInterestRate, uint256 newInterestRate);

    /**
     * --------------------装饰器----------------------
     */
    /// @dev 确保大于0
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert YourLoverReBaseToken__NeedsMoreThanZero();
        }
        _;
    }

    /**
     * --------------------构造函数----------------------
     */
    constructor() Ownable(msg.sender) ERC20("YourLoverReBaseToken", "YLRBT") {}

    /**
     * --------------------外部调用函数---------------------
     */

    /**
     * @notice 授权
     * @param _address 授权地址
     */
    function grantMintAndBurnRole(address _address) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, _address);
    }

    /**
     * @notice 设置利率
     * @param _interestRate 利率
     */
    function setInterestRate(uint256 _interestRate) external onlyOwner {
        if (_interestRate > sYearInterestRate) {
            revert YourLoverReBaseToken__InterestRateOnlyCanBeDecreased(
                sYearInterestRate,
                _interestRate
            );
        }
        sYearInterestRate = _interestRate;
        emit InterestRateChanged(sYearInterestRate, _interestRate);
    }

    /**
     * @notice 铸币
     * @param _to 接收者
     * @param _amount 数量
     * @param _yearInterestRate 年利率
     */
    function mint(
        address _to,
        uint256 _amount,
        uint256 _yearInterestRate
    ) external moreThanZero(_amount) onlyRole(MINT_AND_BURN_ROLE) {
        //先把之前的存款结息
        _mintAccruedInterest(_to);
        //更新用户利率
        sUserInterestRate[_to] = _yearInterestRate;
        //打钱
        _mint(_to, _amount);
    }

    /**
     * @notice 销毁
     * @param _amount 数量
     */
    function burn(
        address _from,
        uint256 _amount
    ) external moreThanZero(_amount) onlyRole(MINT_AND_BURN_ROLE) {
        //先结息
        _mintAccruedInterest(_from);
        // 销毁
        _burn(_from, _amount);
    }

    /**
     * @notice 转账
     * @param _to 接收者
     * @param _amount 数量
     */
    function transfer(
        address _to,
        uint256 _amount
    ) public override moreThanZero(_amount) returns (bool) {
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }
        //双方结息（避免多计算利息）
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_to);
        //如果是新用户，继承老用户利率（鼓励老带新）
        if (balanceOf(_to) == 0) {
            sUserInterestRate[_to] = sUserInterestRate[msg.sender];
        }
        return super.transfer(_to, _amount);
    }

    /**
     * @notice 授权转账
     * @param _from 授权方
     * @param _to 被授权方
     * @param _amount 被授金额
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public override moreThanZero(_amount) returns (bool) {
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }
        //双方结息（避免多计算利息）
        _mintAccruedInterest(_from);
        _mintAccruedInterest(_to);
        if (balanceOf(_to) == 0) {
            sUserInterestRate[_to] = sUserInterestRate[msg.sender];
        }
        return super.transferFrom(_from, _to, _amount);
    }

    /**
     * --------------------内部调用函数---------------------
     */

    /**
     * @notice 计算利息
     * @param _user 用户
     * @param _principal 本金
     * @param _yearInterestRate 年利率
     * @dev 利息 = （本金 * 秒利率 * 储蓄时长（单位秒）） / 标准精度
     * @dev                  ↑
     * @dev                秒利率 = 年利率 / 年秒
     * @dev solidity运算先乘再除，以避免精度丢失
     * @dev 最终公式为： 利息 = （本金 * 年利率 * 储蓄时长） / （年秒 * 标准精度）
     */
    function _calculateInterest(
        address _user,
        uint256 _principal,
        uint256 _yearInterestRate
    ) internal view returns (uint256) {
        if (sUserLatestDepositTime[_user] == 0) {
            return 0;
        }
        uint256 time = block.timestamp - sUserLatestDepositTime[_user];
        //假如用户存入10个LRBT，存入年利率为5%，存了1天，区块链时间单位为秒，则时间1天为86400秒
        //原始公式计算 利息=10*0.05/31536000*86400=0.0013698630136986
        //solidity公式计算 利息=10e18*5e16*86400/31536000=13698630136986e2
        return
            (_principal * _yearInterestRate * time) /
            (SECONDS_PER_YEAR * PRECISION);
    }

    /**
     * @notice 结息
     * @param _user 用户
     */
    function _mintAccruedInterest(address _user) internal {
        //计算利息
        uint256 interest = _calculateInterest(
            _user,
            principalBalanceOf(_user),
            getUserInterestRate(_user)
        );
        if (interest == 0) {
            sUserLatestDepositTime[_user] = block.timestamp;
            return;
        }
        _mint(_user, interest);
        sUserLatestDepositTime[_user] = block.timestamp;
    }

    /**
     * --------------------公共调用函数---------------------
     */

    /**
     * @notice 获取用户余额(包含利息)
     * @param _user 用户
     */
    function balanceOf(
        address _user
    ) public view override(ERC20, IYourLoverReBaseToken) returns (uint256) {
        uint256 userBalance = principalBalanceOf(_user);
        uint256 userInterestRate = getUserInterestRate(_user);
        return
            userBalance +
            _calculateInterest(_user, userBalance, userInterestRate);
    }

    /**
     * @notice 获取用户本金余额
     * @param _user 用户
     */
    function principalBalanceOf(address _user) public view returns (uint256) {
        return super.balanceOf(_user);
    }

    /**
     * @notice 获取用户利率
     * @param _user 用户
     */
    function getUserInterestRate(address _user) public view returns (uint256) {
        return sUserInterestRate[_user];
    }

    /**
     * @notice 获取用户存款时间
     * @param _user 用户
     */
    function getUserDepositTime(address _user) public view returns (uint256) {
        return sUserLatestDepositTime[_user];
    }

    function getYearInterestRate() public view returns (uint256) {
        return sYearInterestRate;
    }

    function getOwner() public view returns (address) {
        return owner();
    }
}
