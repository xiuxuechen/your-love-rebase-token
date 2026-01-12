// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BankTeller} from "../../src/BankTeller.sol";
import {YourLoverReBaseToken} from "../../src/YourLoverReBaseToken.sol";
import {Test, console} from "forge-std/Test.sol";

contract YourLoverReBaseTokenTest is Test {
    YourLoverReBaseToken public token;

    address MINT_AND_BURN_ROLE_USER = makeAddr("xxc");
    address XSX_USER = makeAddr("xsx");
    uint256 yearInterestRate;

    function setUp() public {
        token = new YourLoverReBaseToken();
        token.grantMintAndBurnRole(MINT_AND_BURN_ROLE_USER);
        yearInterestRate = token.getYearInterestRate();
    }

    function testOwner() public view {
        address owner = token.owner();
        assertEq(owner, address(this));
    }

    /**
     * @notice -----------测试grantMintAndBurnRole----------
     */

    function testNotOwnerCantGrantMintAndBurnRole() public {
        vm.startPrank(makeAddr("xsx"));
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                makeAddr("xsx")
            )
        );
        token.grantMintAndBurnRole(MINT_AND_BURN_ROLE_USER);
        vm.stopPrank();
    }

    function testGrantMintAndBurnRole() public view {
        assertEq(
            token.hasRole(token.MINT_AND_BURN_ROLE(), MINT_AND_BURN_ROLE_USER),
            true
        );
    }

    /**
     * @notice -----------测试setInterestRate-----------
     */

    function testNotOwnerCantSetInterestRate() public {
        vm.startPrank(makeAddr("xsx"));
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                makeAddr("xsx")
            )
        );
        token.setInterestRate(1e16);
        vm.stopPrank();
    }

    function testCantSetIncreaseInterestRate() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                YourLoverReBaseToken
                    .YourLoverReBaseToken__InterestRateOnlyCanBeDecreased
                    .selector,
                5e16,
                6e16
            )
        );
        token.setInterestRate(6e16);
    }

    function testSetInterestRate() public {
        token.setInterestRate(1e16);
        uint256 interestRate = token.getYearInterestRate();
        assertEq(interestRate, 1e16);
    }

    /**
     * @notice -----------测试mint-----------
     */

    function testDontHasRoleUserCantMint() public {
        vm.startPrank(XSX_USER);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)",
                XSX_USER,
                token.MINT_AND_BURN_ROLE()
            )
        );
        token.mint(address(this), 10e18, yearInterestRate);
        vm.stopPrank();
    }

    function testCantMintZero() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                YourLoverReBaseToken
                    .YourLoverReBaseToken__NeedsMoreThanZero
                    .selector
            )
        );
        token.mint(address(this), 0, yearInterestRate);
    }

    function testMintInterest() public {
        vm.startPrank(MINT_AND_BURN_ROLE_USER);
        token.mint(XSX_USER, 10 ether, yearInterestRate);
        uint256 firstMintTime = token.getUserDepositTime(XSX_USER);
        vm.warp(1 days);
        token.mint(XSX_USER, 10 ether, yearInterestRate);
        uint256 secondMintTime = token.getUserDepositTime(XSX_USER);
        uint256 depositedTime = secondMintTime - firstMintTime;
        //利息
        uint256 interest = (10 ether *
            token.getUserInterestRate(XSX_USER) *
            depositedTime) / (365 days * 1e18);
        assertEq(token.principalBalanceOf(XSX_USER), 20 ether + interest);
        vm.stopPrank();
    }

    /**
     * @notice -----------测试burn-----------
     */

    function testDontHasRoleUserCantBurn() public {
        vm.startPrank(XSX_USER);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)",
                XSX_USER,
                token.MINT_AND_BURN_ROLE()
            )
        );
        token.burn(address(this), 10e18);
        vm.stopPrank();
    }

    /**
     * @notice -----------测试balance-----------
     */

    function testBalance() public {
        vm.startPrank(MINT_AND_BURN_ROLE_USER);
        token.mint(address(this), 10e18, yearInterestRate);
        uint256 balance = token.balanceOf(address(this));
        vm.stopPrank();
        assertEq(balance, 10e18);
    }

    function testPrincipalBalance() public {
        vm.startPrank(MINT_AND_BURN_ROLE_USER);
        token.mint(address(this), 10 ether, yearInterestRate);
        uint256 balance = token.principalBalanceOf(address(this));
        vm.stopPrank();
        assertEq(balance, 10e18);
    }

    /**
     * @notice -----------测试transfer-----------
     */

    function testTransfer() public {
        vm.prank(MINT_AND_BURN_ROLE_USER);
        token.mint(address(this), 10 ether, yearInterestRate);

        assertEq(token.getUserInterestRate(XSX_USER), 0);

        vm.prank(address(this));
        (bool success) = token.transfer(XSX_USER, 10 ether);
        assertTrue(success);
        assertEq(token.balanceOf(address(this)), 0);

        vm.prank(XSX_USER);
        assertEq(token.balanceOf(XSX_USER), 10 ether);
        assertEq(token.getUserInterestRate(XSX_USER), 5e16);
    }

    /**
     * @notice -----------测试transferFrom-----------
     */

    function testTransferFrom() public {
        vm.prank(MINT_AND_BURN_ROLE_USER);
        token.mint(address(this), 10 ether, yearInterestRate);

        vm.prank(address(this));
        token.approve(XSX_USER, 10 ether);
        vm.prank(XSX_USER);
        (bool success) = token.transferFrom(address(this), XSX_USER, 10 ether);
        assertTrue(success);
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(XSX_USER), 10 ether);
    }
}
