// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BankTeller} from "../../src/BankTeller.sol";
import {YourLoverReBaseToken} from "../../src/YourLoverReBaseToken.sol";
import {
    IYourLoverReBaseToken
} from "../../src/interfaces/IYourLoverReBaseToken.sol";
import {Test, console} from "forge-std/Test.sol";

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

    function testDepositLiner() public {}
}
