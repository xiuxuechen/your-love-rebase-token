pragma solidity ^0.8.28;

import {BankTeller} from "../../src/BankTeller.sol";
import {
    IYourLoverReBaseToken
} from "../../src/interfaces/IYourLoverReBaseToken.sol";
import {YourLoverReBaseToken} from "../../src/YourLoverReBaseToken.sol";
import {Test, console} from "forge-std/Test.sol";

contract InteractionTest is Test {
    YourLoverReBaseToken public token;
    BankTeller public bankTeller;

    address MINT_AND_BURN_ROLE_USER = makeAddr("xxc");
    address XSX_USER = makeAddr("xsx");

    function setUp() public {
        token = new YourLoverReBaseToken();
        token.grantMintAndBurnRole(MINT_AND_BURN_ROLE_USER);

        bankTeller = new BankTeller(IYourLoverReBaseToken(address(token)));
    }

    function testDepositLinear(uint256 amount) public {}
}
