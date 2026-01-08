// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IYourLoverReBaseToken {
    /**
     * @notice 铸币
     * @param _to 接收者
     * @param _amount 数量
     */
    function mint(address _to, uint256 _amount) external;

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
}
