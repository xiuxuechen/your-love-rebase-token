// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {YourLoverReBaseToken} from "../src/YourLoverReBaseToken.sol";
import {
    IYourLoverReBaseToken
} from "../src/interfaces/IYourLoverReBaseToken.sol";
import {YourLoverReBaseTokenPool} from "../src/YourLoverReBaseTokenPool.sol";
import {
    CCIPLocalSimulatorFork,
    Register
} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {
    RegistryModuleOwnerCustom
} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {
    TokenAdminRegistry
} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import {
    IERC20
} from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

contract YourLoverReBaseTokenPoolDeploy is Script {
    function run()
        external
        returns (
            YourLoverReBaseToken,
            YourLoverReBaseTokenPool,
            Register.NetworkDetails memory
        )
    {
        CCIPLocalSimulatorFork ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        Register.NetworkDetails
            memory sepoliaNetworkDetails = ccipLocalSimulatorFork
                .getNetworkDetails(block.chainid);
        vm.startBroadcast();
        YourLoverReBaseToken yourLoverReBaseToken = new YourLoverReBaseToken();

        YourLoverReBaseTokenPool pool = new YourLoverReBaseTokenPool(
            IERC20(address(yourLoverReBaseToken)),
            new address[](0),
            sepoliaNetworkDetails.rmnProxyAddress,
            sepoliaNetworkDetails.routerAddress
        );
        yourLoverReBaseToken.grantMintAndBurnRole(address(pool));

        RegistryModuleOwnerCustom registryModuleOwnerCustomSepolia = RegistryModuleOwnerCustom(
                sepoliaNetworkDetails.registryModuleOwnerCustomAddress
            );
        //注册管理员
        registryModuleOwnerCustomSepolia.registerAdminViaOwner(
            address(yourLoverReBaseToken)
        );
        //确认管理员
        TokenAdminRegistry tokenAdminRegistrySepolia = TokenAdminRegistry(
            sepoliaNetworkDetails.tokenAdminRegistryAddress
        );
        tokenAdminRegistrySepolia.acceptAdminRole(
            address(yourLoverReBaseToken)
        );
        //关联代币与代币池
        tokenAdminRegistrySepolia.setPool(
            address(yourLoverReBaseToken),
            address(pool)
        );
        vm.stopBroadcast();

        return (yourLoverReBaseToken, pool, sepoliaNetworkDetails);
    }
}
