// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BankTeller} from "../../src/BankTeller.sol";
import {YourLoverReBaseToken} from "../../src/YourLoverReBaseToken.sol";
import {
    IYourLoverReBaseToken
} from "../../src/interfaces/IYourLoverReBaseToken.sol";
import {Test} from "forge-std/Test.sol";

contract BankTellerTest is Test {
    YourLoverReBaseToken public token;
    BankTeller public bankTeller;

    address MINT_AND_BURN_ROLE_USER = makeAddr("xxc");
    address XSX_USER = makeAddr("xsx");

    event Deposit(address indexed user, uint256 indexed amount);
    event Redeem(address indexed user, uint256 indexed amount);

    function setUp() public {
        token = new YourLoverReBaseToken();
        bankTeller = new BankTeller(IYourLoverReBaseToken(address(token)));
        token.grantMintAndBurnRole(address(bankTeller));
    }

    function testBaseDeposit() public {
        vm.deal(XSX_USER, 1 ether);
        vm.startPrank(XSX_USER);
        bankTeller.deposit{value: 1 ether}();
        vm.stopPrank();
        assertEq(token.balanceOf(XSX_USER), 1 ether);
    }

    function testDepositEmit() public {
        vm.deal(XSX_USER, 1 ether);
        vm.startPrank(XSX_USER);
        vm.expectEmit(true, true, false, false, address(bankTeller));
        emit Deposit(XSX_USER, 1 ether);
        bankTeller.deposit{value: 1 ether}();
        vm.stopPrank();
    }

    function testBaseRedeem() public {
        vm.deal(XSX_USER, 1 ether);
        vm.startPrank(XSX_USER);
        bankTeller.deposit{value: 1 ether}();
        assertEq(XSX_USER.balance, 0);
        bankTeller.redeem(1 ether);
        vm.stopPrank();
        assertEq(XSX_USER.balance, 1 ether);
    }

    function testRedeemEmit() public {
        vm.deal(XSX_USER, 1 ether);
        vm.startPrank(XSX_USER);
        bankTeller.deposit{value: 1 ether}();
        vm.expectEmit(true, true, false, false, address(bankTeller));
        emit Redeem(XSX_USER, 1 ether);
        bankTeller.redeem(1 ether);
        vm.stopPrank();
    }

    function testDepositLiner() public {
        vm.deal(XSX_USER, 3 ether);

        vm.startPrank(XSX_USER);
        // 第一次存款
        bankTeller.deposit{value: 1 ether}();

        uint256 startTime = token.getUserDepositTime(XSX_USER);
        uint256 startBalance = token.balanceOf(XSX_USER);
        assertEq(startBalance, 1 ether);

        // 第二次存款
        vm.warp(1 days);
        bankTeller.deposit{value: 1 ether}();
        uint256 depositedTime = token.getUserDepositTime(XSX_USER) - startTime;
        uint256 interest = (1 ether *
            token.getUserInterestRate(XSX_USER) *
            depositedTime) / (365 days * 1e18);

        uint256 middleBalance = token.balanceOf(XSX_USER);
        assertGt(middleBalance, startBalance);

        // 第三次存款
        vm.warp(1 days);
        bankTeller.deposit{value: 1 ether}();
        uint256 endBalance = token.balanceOf(XSX_USER);
        vm.stopPrank();

        assertApproxEqAbs(
            endBalance - middleBalance,
            middleBalance - startBalance,
            interest
        );
    }

    function testRedeemWhenTimePassed() public {
        // 给银行柜员充点钱，否则没钱付利息
        vm.deal(address(bankTeller), 10 ether);

        vm.deal(XSX_USER, 1 ether);
        vm.startPrank(XSX_USER);
        bankTeller.deposit{value: 1 ether}();
        uint256 startTime = token.getUserDepositTime(XSX_USER);
        vm.warp(1 days);

        bankTeller.redeem(type(uint256).max);
        vm.stopPrank();

        uint256 depositedTime = token.getUserDepositTime(XSX_USER) - startTime;
        uint256 interest = (1 ether *
            token.getUserInterestRate(XSX_USER) *
            depositedTime) / (365 days * 1e18);

        assertEq(XSX_USER.balance, 1 ether + interest);
        assertEq(address(bankTeller).balance, 10 ether - interest);
    }
}
