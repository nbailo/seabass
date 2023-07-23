// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {AutomationRegistryInterface, State, Config} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface1_2.sol";
import "./CircuitBreaker.sol";

interface KeeperRegistrarInterface {
    function register(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source,
        address sender
    ) external;
}

interface KeeperRegistryInterface {
    function withdrawFunds(uint256 id, address to) external;

    function cancelUpkeep(uint256 id) external;

    function getState()
        external
        view
        returns (
            State memory state,
            Config memory config,
            address[] memory keepers
        );
}

interface Link677Interface {
    function transferAndCall(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);
}

interface PegSwapInterface {
    function swap(uint256 amount, address source, address target) external;
}

contract CircuitBreakerFactory {
    using SafeCast for uint256;

    struct UserInfo {
        address circuitBreaker;
        uint256 taskId;
    }

    Link677Interface public link677;
    IERC20 public link20;
    PegSwapInterface public pegSwap;
    mapping(address => UserInfo[]) users;
    KeeperRegistrarInterface private registrar;
    KeeperRegistryInterface private registry;

    address public companyWallet;

    event CircuitBreakerCreated(address circuitBreaker, uint256 taskId);

    constructor(
        address _link20,
        address _link677,
        address _registrar,
        address _registry,
        address _pegSwap,
        address _companyWallet
    ) {
        link20 = IERC20(_link20);
        link677 = Link677Interface(_link677);
        registrar = KeeperRegistrarInterface(_registrar);
        registry = KeeperRegistryInterface(_registry);
        pegSwap = PegSwapInterface(_pegSwap);
        companyWallet = _companyWallet;
    }

    function createCircuitBreaker(
        uint256 _amount,
        address _priceFeed,
        address _owner,
        uint256 _oracleDeviationLimit,
        address _externalContract,
        string memory _functionName
    ) external {
        require(
            link20.transferFrom(msg.sender, address(this), _amount),
            "Failed to transfer LINK"
        );
        uint256 fee = (_amount * 10) / 100;
        uint256 amount = _amount - fee;
        require(link20.transfer(companyWallet, fee), "Failed to transfer LINK");
        require(
            link20.approve(address(pegSwap), amount),
            "Failed to approve LINK"
        );
        pegSwap.swap(amount, address(link20), address(link677));
        CircuitBreaker circuitBreaker = new CircuitBreaker(
            _owner,
            _priceFeed,
            _oracleDeviationLimit,
            _externalContract,
            _functionName
        );

        (State memory state, , ) = registry.getState();
        uint256 oldNonce = state.nonce;

        bytes4 registerSig = KeeperRegistrarInterface.register.selector;
        uint96 amount96 = amount.toUint96();

        bytes memory data = abi.encode(
            "Circuit Breaker Upkeep",
            "",
            address(circuitBreaker),
            500000,
            address(this),
            "",
            amount96,
            0,
            address(this)
        );

        link677.transferAndCall(
            address(registrar),
            amount,
            bytes.concat(registerSig, data)
        );

        (state, , ) = registry.getState();
        uint256 newNonce = state.nonce;
        if (newNonce == oldNonce + 1) {
            uint256 upkeepID = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        address(registry),
                        uint32(oldNonce)
                    )
                )
            );
            users[_owner].push(UserInfo(address(circuitBreaker), upkeepID));
            emit CircuitBreakerCreated(address(circuitBreaker), upkeepID);
        } else {
            revert("Auto-approve disabled");
        }
    }

    function cancel(uint256 _id) public {
        registry.cancelUpkeep(_id);
    }

    function withdraw(uint256 _id, address _to) public {
        registry.withdrawFunds(_id, _to);
    }

    function getUserInfo(
        address _user,
        uint256 _id
    ) public view returns (UserInfo memory) {
        return users[_user][_id];
    }
}
