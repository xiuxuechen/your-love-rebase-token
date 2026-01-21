-include .env

.PHONY: all test clean deploy deploy-sepolia deploy-local deploy-zk deploy-zk-sepolia \
        fund fund-local fund-sepolia withdraw withdraw-local withdraw-sepolia \
        help install snapshot format anvil zk-anvil
		
DEFAULT_ANVIL_PRIVATE_KEY := 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

# ==================== ARBITRUM ====================

ARBITRUM_REGISTRY_MODULE_OWNER_CUSTOM := 0xE625f0b8b0Ac86946035a7729Aba124c8A64cf69
ARBITRUM_TOKEN_ADMIN_REGISTRY := 0x8126bE56454B628a88C17849B9ED99dd5a11Bd2f
ARBITRUM_ROUTER := 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165
ARBITRUM_RNM_PROXY_ADDRESS := 0x9527E2d01A3064ef6b50c1Da1C0cC523803BCFF2
ARBITRUM_CHAIN_SELECTOR := 3478487238524512106
ARBITRUM_LINK_ADDRESS := 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E

ARBITRUM_POOL_ADDRESS := 0xEeDdA1a0aB5931702a135D7f34fD627895310C5a
ARBITRUM_REBASE_TOKEN_ADDRESS := 0xE69696E979A1655F0D3f703088CBD409662dCAC6

# ==================== SEPOLIA ====================
SEPOLIA_REGISTRY_MODULE_OWNER_CUSTOM := 0x62e731218d0D47305aba2BE3751E7EE9E5520790
SEPOLIA_TOKEN_ADMIN_REGISTRY := 0x95F29FEE11c5C55d26cCcf1DB6772DE953B37B82
SEPOLIA_ROUTER := 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59
SEPOLIA_RNM_PROXY_ADDRESS := 0xba3f6251de62dED61Ff98590cB2fDf6871FbB991
SEPOLIA_CHAIN_SELECTOR := 16015286601757825753
SEPOLIA_LINK_ADDRESS := 0x779877A7B0D9E8603169DdbD7836e478b4624789

SEPOLIA_POOL_ADDRESS := 0xceafb5e24907361a8e50597D160105812384cD54
SEPOLIA_REBASE_TOKEN_ADDRESS := 0x9Da0Fea55C5ba62aD89603a8676993A3ca0051Ea


# ==================== 环境检查函数 ====================
define check-env
	@if [ -z "$($(1))" ]; then \
		echo "❌ 错误: $(1) 未设置"; \
		echo "请在 .env 文件中设置: $(1)=值"; \
		exit 1; \
	fi
endef

check-rpc-url:
	$(call check-env,$(NETWORK)_RPC_URL)

check-private-key:
	$(call check-env,SEPOLIA_PRIVATE_KEY)

check-sepolia-env:
	$(call check-env,SEPOLIA_RPC_URL)
	$(call check-env,SEPOLIA_PRIVATE_KEY)

check-arb-sepolia-env:
	$(call check-env,ARBITRUM_SEPOLIA_RPC_URL)
	$(call check-env,SEPOLIA_PRIVATE_KEY)

check-zksync-env:
	$(call check-env,ZKSYNC_SEPOLIA_RPC_URL)

install:
	@echo "📦 安装依赖..."
	forge install --no-git https://github.com/foundry-rs/forge-std \
	forge install --no-git https://github.com/OpenZeppelin/openzeppelin-contracts \
	forge install --no-git https://github.com/smartcontractkit/chainlink-evm \
	forge install --no-git https://github.com/cyfrin/foundry-devops \
	forge install --no-git https://github.com/transmissions11/solmate \
	forge install --no-git https://github.com/smartcontractkit/ccip@v2.17.0-ccip1.5.16 \
	forge install --no-git smartcontractkit/chainlink-local@v0.2.7-beta
 

remove: rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules

anvil:
	@echo "🏗️ 启动本地 Anvil 节点..."
	anvil -m 'test test test test test test test test test test test junk' \
		--steps-tracing \
		--block-time 1 

deploy-pool-sepolia: check-sepolia-env
	@echo "🚀 部署到 Sepolia 测试网..."
	@if [ -z "$(ETHERSCAN_API_KEY)" ]; then \
		echo "⚠️  跳过合约验证 (ETHERSCAN_API_KEY 未设置)"; \
		forge script script/LoveReBaseTokenPoolDeploy.s.sol \
			--rpc-url $(SEPOLIA_RPC_URL) \
			--private-key $(SEPOLIA_PRIVATE_KEY) \
			--broadcast \
			--sig "run(string)" "MLRBT" \
			-vvvv; \
	else \
		echo "✅ 启用合约验证"; \
		forge script script/LoveReBaseTokenPoolDeploy.s.sol \
			--rpc-url $(SEPOLIA_RPC_URL) \
			--private-key $(SEPOLIA_PRIVATE_KEY) \
			--broadcast \
			--sig "run(string)" "MLRBT" \
			--verify \
			--etherscan-api-key $(ETHERSCAN_API_KEY) \
			-vvvv; \
	fi		

deploy-pool-arb: check-sepolia-env
	@echo "🚀 部署到 Arb-Sepolia 测试网..."
	@if [ -z "$(ETHERSCAN_API_KEY)" ]; then \
		echo "⚠️  跳过合约验证 (ETHERSCAN_API_KEY 未设置)"; \
		forge script script/LoveReBaseTokenPoolDeploy.s.sol \
			--rpc-url $(ARBITRUM_SEPOLIA_RPC_URL) \
			--private-key $(SEPOLIA_PRIVATE_KEY) \
			--broadcast \
			--sig "run(string)" "YLRBT" \
			-vvvv; \
	else \
		echo "✅ 启用合约验证"; \
		forge script script/LoveReBaseTokenPoolDeploy.s.sol \
			--rpc-url $(ARBITRUM_SEPOLIA_RPC_URL) \
			--private-key $(SEPOLIA_PRIVATE_KEY) \
			--broadcast \
			--sig "run(string)" "YLRBT" \
			--verify \
			--etherscan-api-key $(ETHERSCAN_API_KEY) \
			-vvvv; \
	fi	

deploy-bankTeller-sepolia: check-sepolia-env
	@echo "🚀 部署到 Sepolia 测试网..."
	@if [ -z "$(ETHERSCAN_API_KEY)" ]; then \
		echo "⚠️  跳过合约验证 (ETHERSCAN_API_KEY 未设置)"; \
		forge script script/BankTellerDeploy.s.sol \
			--rpc-url $(SEPOLIA_RPC_URL) \
			--private-key $(SEPOLIA_PRIVATE_KEY) \
			--broadcast \
			--sig "run(address)" ${SEPOLIA_REBASE_TOKEN_ADDRESS} \
			-vvvv; \
	else \
		echo "✅ 启用合约验证"; \
		forge script script/BankTellerDeploy.s.sol \
			--rpc-url $(SEPOLIA_RPC_URL) \
			--private-key $(SEPOLIA_PRIVATE_KEY) \
			--broadcast \
			--sig "run(address)" ${SEPOLIA_REBASE_TOKEN_ADDRESS} \
			--verify \
			--etherscan-api-key $(ETHERSCAN_API_KEY) \
			-vvvv; \
	fi	

deploy-bankTeller-arb: check-arb-sepolia-env
	@echo "🚀 部署到 Arb-Sepolia 测试网..."
	@if [ -z "$(ETHERSCAN_API_KEY)" ]; then \
		echo "⚠️  跳过合约验证 (ETHERSCAN_API_KEY 未设置)"; \
		forge script script/BankTellerDeploy.s.sol \
			--rpc-url $(ARBITRUM_SEPOLIA_RPC_URL) \
			--private-key $(SEPOLIA_PRIVATE_KEY) \
			--broadcast \
			--sig "run(address)" ${ARBITRUM_REBASE_TOKEN_ADDRESS} \
			-vvvv; \
	else \
		echo "✅ 启用合约验证"; \
		forge script script/BankTellerDeploy.s.sol \
			--rpc-url $(ARBITRUM_SEPOLIA_RPC_URL) \
			--private-key $(SEPOLIA_PRIVATE_KEY) \
			--broadcast \
			--sig "run(address)" ${ARBITRUM_REBASE_TOKEN_ADDRESS} \
			--verify \
			--etherscan-api-key $(ETHERSCAN_API_KEY) \
			-vvvv; \
	fi		

deploy-configurePool-sepolia:
	@echo "🚀 部署到 Sepolia 测试网..."
	@if [ -z "$(ETHERSCAN_API_KEY)" ]; then \
		echo "⚠️  跳过合约验证 (ETHERSCAN_API_KEY 未设置)"; \
		forge script script/ConfigurePool.s.sol \
			--rpc-url $(SEPOLIA_RPC_URL) \
			--private-key $(SEPOLIA_PRIVATE_KEY) \
			--account updraft \
			--broadcast \
			--sig "run(address,uint64,address,address,bool,uint128,uint128,bool,uint128,uint128)" \
			${SEPOLIA_POOL_ADDRESS} \
			${ARBITRUM_CHAIN_SELECTOR} \
			${ARBITRUM_POOL_ADDRESS} \
			${ARBITRUM_REBASE_TOKEN_ADDRESS} \
			false 0 0 false 0 0 \
			-vvvv; \
	else \
		echo "✅ 启用合约验证"; \
		forge script script/ConfigurePool.s.sol \
			--rpc-url $(SEPOLIA_RPC_URL) \
			--private-key $(SEPOLIA_PRIVATE_KEY) \
			--broadcast \
			--verify \
			--etherscan-api-key $(ETHERSCAN_API_KEY) \
			--sig "run(address,uint64,address,address,bool,uint128,uint128,bool,uint128,uint128)" \
			${SEPOLIA_POOL_ADDRESS} \
			${ARBITRUM_CHAIN_SELECTOR} \
			${ARBITRUM_POOL_ADDRESS} \
			${ARBITRUM_REBASE_TOKEN_ADDRESS} \
			false 0 0 false 0 0 \
			-vvvv; \
	fi	

deploy-configurePool-arb:
	@echo "🚀 配置代币池映射关系..." 
	cast send $(ARBITRUM_POOL_ADDRESS) \
		--rpc-url $(ARBITRUM_SEPOLIA_RPC_URL) \
		--private-key $(SEPOLIA_PRIVATE_KEY) \
		"applyChainUpdates((uint64,bool,bytes,bytes,(bool,uint128,uint128),(bool,uint128,uint128))[])" \
		"[($(SEPOLIA_CHAIN_SELECTOR), true, \
		  $(shell cast abi-encode "f(address)" $(SEPOLIA_POOL_ADDRESS)), \
		  $(shell cast abi-encode "f(address)" $(SEPOLIA_REBASE_TOKEN_ADDRESS)), \
		  (false, 0, 0), (false, 0, 0))]"


call-bankTeller-deposit-sepolia:
	@echo "🚀 调用 BankTeller..."
	cast send 0x16D2328F3FCDA61785151F243C1eac6F2342BeAF --value 1000000000000000000 --rpc-url ${SEPOLIA_RPC_URL} --private-key $(SEPOLIA_PRIVATE_KEY) "deposit()"

call-bankTeller-redeem-sepolia:
	@echo "🚀 调用 BankTeller..."
	cast send 0x16D2328F3FCDA61785151F243C1eac6F2342BeAF --rpc-url ${SEPOLIA_RPC_URL} --private-key $(SEPOLIA_PRIVATE_KEY) "redeem(uint256)" 1000000000000000000	

call-bridge-tokens: check-sepolia-env
	@echo "🚀 桥接代币..."
	@if [ -z "$(ETHERSCAN_API_KEY)" ]; then \
	    echo "⚠️  跳过合约验证 (ETHERSCAN_API_KEY 未设置)"; \
	    forge script script/BridgeTokens.s.sol:BridgeTokens \
	        --rpc-url $(SEPOLIA_RPC_URL) \
	        --private-key $(SEPOLIA_PRIVATE_KEY) \
	        --broadcast \
	        --sig "run(address,uint64,address,uint256,address,address)" \
	        $(USER) \
	        $(ARBITRUM_CHAIN_SELECTOR) \
	        $(SEPOLIA_REBASE_TOKEN_ADDRESS) \
	        100000000000000 \
	        $(SEPOLIA_LINK_ADDRESS) \
	        $(SEPOLIA_ROUTER) \
	        -vvvv; \
    else \
	    echo "✅ 启用合约验证"; \
	    forge script script/BridgeTokens.s.sol:BridgeTokens \
	        --rpc-url $(SEPOLIA_RPC_URL) \
	        --private-key $(SEPOLIA_PRIVATE_KEY) \
	        --broadcast \
	        --verify \
	        --etherscan-api-key $(ETHERSCAN_API_KEY) \
	        --sig "run(address,uint64,address,uint256,address,address)" \
	        $(USER) \
	        $(ARBITRUM_CHAIN_SELECTOR) \
	        $(SEPOLIA_REBASE_TOKEN_ADDRESS) \
	        100000000000000 \
	        $(SEPOLIA_LINK_ADDRESS) \
	        $(SEPOLIA_ROUTER) \
	        -vvvv; \
    fi

