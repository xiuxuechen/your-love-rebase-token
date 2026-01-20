// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BankTeller} from "../../src/BankTeller.sol";
import {
    IYourLoverReBaseToken
} from "../../src/interfaces/IYourLoverReBaseToken.sol";
import {YourLoverReBaseToken} from "../../src/YourLoverReBaseToken.sol";
import {YourLoverReBaseTokenPool} from "../../src/YourLoverReBaseTokenPool.sol";
import {Test, console} from "forge-std/Test.sol";
import {
    CCIPLocalSimulatorFork,
    Register
} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {TokenPool} from "@ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {
    RegistryModuleOwnerCustom
} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {
    TokenAdminRegistry
} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import {
    RateLimiter
} from "@ccip/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";
import {
    IERC20
} from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {
    IRouterClient
} from "@ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import {Pool} from "@ccip/contracts/src/v0.8/ccip/libraries/Pool.sol";

contract CrossChainInteractionTest is Test {
    address owner = makeAddr("owner");
    address xxcUser = makeAddr("xxc");
    address xsxUser = makeAddr("xsx");

    CCIPLocalSimulatorFork public ccipLocalSimulatorFork;
    BankTeller bankTeller;

    uint256 sepoliaFork;
    uint256 arbSepoliaFork;

    /**
     * ----------------------源链配置参数------------------------
     */
    YourLoverReBaseToken sepoliaRebaseToken;
    YourLoverReBaseTokenPool sepoliaPool;
    TokenAdminRegistry tokenAdminRegistrySepolia;
    Register.NetworkDetails sepoliaNetworkDetails;
    RegistryModuleOwnerCustom registryModuleOwnerCustomSepolia;

    /**
     * ----------------------目标链配置参数------------------------
     */
    YourLoverReBaseToken arbSepoliaRebaseToken;
    YourLoverReBaseTokenPool arbSepoliaPool;
    TokenAdminRegistry tokenAdminRegistryArbSepolia;
    Register.NetworkDetails arbSepoliaNetworkDetails;
    RegistryModuleOwnerCustom registryModuleOwnerCustomArbSepolia;

    function setUp() public {
        address[] memory allowlist = new address[](0);

        sepoliaFork = vm.createSelectFork(vm.envString("SEPOLIA_RPC_URL"));
        arbSepoliaFork = vm.createFork(
            vm.envString("ARBITRUM_SEPOLIA_RPC_URL")
        );
        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();

        //----------------------源链相关配置----------------------
        vm.makePersistent(address(ccipLocalSimulatorFork));
        sepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(
            block.chainid
        );
        vm.startPrank(owner);
        sepoliaRebaseToken = new YourLoverReBaseToken();
        sepoliaPool = new YourLoverReBaseTokenPool(
            IERC20(address(sepoliaRebaseToken)),
            allowlist,
            sepoliaNetworkDetails.rmnProxyAddress,
            sepoliaNetworkDetails.routerAddress
        );
        bankTeller = new BankTeller(
            IYourLoverReBaseToken(address(sepoliaRebaseToken))
        );
        vm.deal(address(bankTeller), 1 ether);
        sepoliaRebaseToken.grantMintAndBurnRole(address(bankTeller));
        sepoliaRebaseToken.grantMintAndBurnRole(address(sepoliaPool));

        //开启源链自定义权限配置
        registryModuleOwnerCustomSepolia = RegistryModuleOwnerCustom(
            sepoliaNetworkDetails.registryModuleOwnerCustomAddress
        );
        //注册管理员
        registryModuleOwnerCustomSepolia.registerAdminViaOwner(
            address(sepoliaRebaseToken)
        );
        //确认管理员
        tokenAdminRegistrySepolia = TokenAdminRegistry(
            sepoliaNetworkDetails.tokenAdminRegistryAddress
        );
        tokenAdminRegistrySepolia.acceptAdminRole(address(sepoliaRebaseToken));
        //关联代币与代币池
        tokenAdminRegistrySepolia.setPool(
            address(sepoliaRebaseToken),
            address(sepoliaPool)
        );
        vm.stopPrank();

        //----------------------目标链相关配置----------------------
        vm.selectFork(arbSepoliaFork);
        vm.startPrank(owner);
        arbSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(
            block.chainid
        );
        arbSepoliaRebaseToken = new YourLoverReBaseToken();
        arbSepoliaPool = new YourLoverReBaseTokenPool(
            IERC20(address(arbSepoliaRebaseToken)),
            allowlist,
            arbSepoliaNetworkDetails.rmnProxyAddress,
            arbSepoliaNetworkDetails.routerAddress
        );
        arbSepoliaRebaseToken.grantMintAndBurnRole(address(arbSepoliaPool));
        //开启目标链自定义权限配置
        registryModuleOwnerCustomArbSepolia = RegistryModuleOwnerCustom(
            arbSepoliaNetworkDetails.registryModuleOwnerCustomAddress
        );
        //注册管理员
        registryModuleOwnerCustomArbSepolia.registerAdminViaOwner(
            address(arbSepoliaRebaseToken)
        );
        //确认管理员
        tokenAdminRegistryArbSepolia = TokenAdminRegistry(
            arbSepoliaNetworkDetails.tokenAdminRegistryAddress
        );
        tokenAdminRegistryArbSepolia.acceptAdminRole(
            address(arbSepoliaRebaseToken)
        );
        //关联代币与代币池
        tokenAdminRegistryArbSepolia.setPool(
            address(arbSepoliaRebaseToken),
            address(arbSepoliaPool)
        );
        configureTokenPool(
            sepoliaFork,
            sepoliaPool,
            arbSepoliaPool,
            arbSepoliaRebaseToken,
            arbSepoliaNetworkDetails
        );
        configureTokenPool(
            arbSepoliaFork,
            arbSepoliaPool,
            sepoliaPool,
            sepoliaRebaseToken,
            sepoliaNetworkDetails
        );

        vm.stopPrank();
    }

    /**
     * @notice 配置代币池映射关系
     * @param fork 链ID
     * @param localPool 本地代币池
     * @param remotePool 目标链代币池
     * @param remoteToken 目标链代币
     * @param remoteNetworkDetails 目标链网络详情
     */
    function configureTokenPool(
        uint256 fork,
        TokenPool localPool,
        TokenPool remotePool,
        IYourLoverReBaseToken remoteToken,
        Register.NetworkDetails memory remoteNetworkDetails
    ) public {
        vm.selectFork(fork);
        vm.startPrank(owner);
        TokenPool.ChainUpdate[] memory chains = new TokenPool.ChainUpdate[](1);
        chains[0] = TokenPool.ChainUpdate({
            remoteChainSelector: remoteNetworkDetails.chainSelector,
            allowed: true,
            remotePoolAddress: abi.encode(address(remotePool)),
            remoteTokenAddress: abi.encode(address(remoteToken)),
            outboundRateLimiterConfig: RateLimiter.Config({
                isEnabled: false,
                capacity: 0,
                rate: 0
            }),
            inboundRateLimiterConfig: RateLimiter.Config({
                isEnabled: false,
                capacity: 0,
                rate: 0
            })
        });
        //这个方法实际上是根据allowed参数决定是新增还是删除，并没有更新功能
        //且ccip仓库已经被归档，已经不是业界主流的跨链协议了（或许就没是过？I don't know~）
        localPool.applyChainUpdates(chains);
        vm.stopPrank();
    }

    /**
     * @notice 代币跨链
     * @param amountToBridge 跨链代币数量
     * @param localFork 本地链ID
     * @param remoteFork 目标链ID
     * @param localNetworkDetails 本地链网络详情
     * @param remoteNetworkDetails 目标链网络详情
     * @param localToken 本地代币
     * @param remoteToken 目标链代币
     */
    function bridgeTokens(
        uint256 amountToBridge,
        uint256 localFork,
        uint256 remoteFork,
        Register.NetworkDetails memory localNetworkDetails,
        Register.NetworkDetails memory remoteNetworkDetails,
        YourLoverReBaseToken localToken,
        YourLoverReBaseToken remoteToken
    ) public {
        vm.selectFork(localFork);
        vm.startPrank(xsxUser);

        //支持多种代币同批跨链
        Client.EVMTokenAmount[]
            memory tokenToSendDetails = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({
            token: address(localToken),
            amount: amountToBridge
        });
        tokenToSendDetails[0] = tokenAmount;
        //给源链代币池授权，允许转走用户源链上的代币
        IERC20(address(localToken)).approve(
            localNetworkDetails.routerAddress,
            amountToBridge
        );
        //跨链消息
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(xsxUser),
            data: "",
            tokenAmounts: tokenToSendDetails,
            extraArgs: "",
            feeToken: localNetworkDetails.linkAddress
        });
        vm.stopPrank();

        //给用户充值LINK-用于跨链费用
        ccipLocalSimulatorFork.requestLinkFromFaucet(
            xsxUser,
            IRouterClient(localNetworkDetails.routerAddress).getFee(
                remoteNetworkDetails.chainSelector,
                message
            )
        );

        vm.startPrank(xsxUser);
        //授权LINK
        IERC20(localNetworkDetails.linkAddress).approve(
            localNetworkDetails.routerAddress,
            IRouterClient(localNetworkDetails.routerAddress).getFee(
                remoteNetworkDetails.chainSelector,
                message
            )
        );

        uint256 balanceBeforeBridge = IERC20(address(localToken)).balanceOf(
            xsxUser
        );
        console.log(unicode"跨链前源链代币余额:", balanceBeforeBridge);

        //在源链发送跨链消息
        IRouterClient(localNetworkDetails.routerAddress).ccipSend(
            remoteNetworkDetails.chainSelector,
            message
        );
        uint256 sourceBalanceAfterBridge = IERC20(address(localToken))
            .balanceOf(xsxUser);
        console.log(unicode"跨链后源链代币余额:", sourceBalanceAfterBridge);
        assertEq(
            sourceBalanceAfterBridge,
            balanceBeforeBridge - amountToBridge
        );
        vm.stopPrank();

        vm.selectFork(remoteFork);

        vm.warp(block.timestamp + 900);
        uint256 initialArbBalance = IERC20(address(remoteToken)).balanceOf(
            xsxUser
        );
        console.log(unicode"跨链前目标链代币余额:", initialArbBalance);
        vm.selectFork(localFork);
        //确认跨链
        ccipLocalSimulatorFork.switchChainAndRouteMessage(remoteFork);

        console.log(
            unicode"目标链代币利率: %d",
            remoteToken.getUserInterestRate(xsxUser)
        );
        uint256 destBalance = IERC20(address(remoteToken)).balanceOf(xsxUser);
        console.log(unicode"跨链后目标链代币余额:", destBalance);
        assertEq(destBalance, initialArbBalance + amountToBridge);
    }

    function testSepoliaToArbBridge() public {
        vm.selectFork(sepoliaFork);
        vm.deal(xsxUser, 10 ether);
        vm.startPrank(xsxUser);
        BankTeller(payable(address(bankTeller))).deposit{value: 10 ether}();
        uint256 startBalance = IERC20(address(sepoliaRebaseToken)).balanceOf(
            xsxUser
        );
        assertEq(startBalance, 10 ether);
        vm.stopPrank();

        bridgeTokens(
            10 ether,
            sepoliaFork,
            arbSepoliaFork,
            sepoliaNetworkDetails,
            arbSepoliaNetworkDetails,
            sepoliaRebaseToken,
            arbSepoliaRebaseToken
        );
    }

    function testTwiceSepoliaToArbBridge() public {
        vm.selectFork(sepoliaFork);
        vm.deal(xsxUser, 10 ether);
        vm.startPrank(xsxUser);
        BankTeller(payable(address(bankTeller))).deposit{value: 10 ether}();
        uint256 startBalance = IERC20(address(sepoliaRebaseToken)).balanceOf(
            xsxUser
        );
        assertEq(startBalance, 10 ether);
        vm.stopPrank();

        bridgeTokens(
            10 ether,
            sepoliaFork,
            arbSepoliaFork,
            sepoliaNetworkDetails,
            arbSepoliaNetworkDetails,
            sepoliaRebaseToken,
            arbSepoliaRebaseToken
        );

        vm.selectFork(arbSepoliaFork);
        uint256 destBalance = IERC20(address(arbSepoliaRebaseToken)).balanceOf(
            xsxUser
        );

        bridgeTokens(
            destBalance,
            arbSepoliaFork,
            sepoliaFork,
            arbSepoliaNetworkDetails,
            sepoliaNetworkDetails,
            arbSepoliaRebaseToken,
            sepoliaRebaseToken
        );
    }
}
