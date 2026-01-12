// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IYourLoverReBaseToken {
    /**
     * @notice 授权
     * @param _address 授权地址
     */
    function grantMintAndBurnRole(address _address) external;

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
    ) external;

    /**
     * @notice 销毁
     * @param _amount 数量
     */
    function burn(address _from, uint256 _amount) external;

    /**
     * @notice 获取用户余额(包含利息)
     * @param _user 用户
     */
    function balanceOf(address _user) external view returns (uint256);

    /**
     * @notice 获取用户利率
     * @param _user 用户
     */
    function getUserInterestRate(address _user) external view returns (uint256);

    /**
     * @notice 获取当前年利率
     */
    function getYearInterestRate() external view returns (uint256);
}
