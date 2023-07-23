// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./interfaces/KeeperRegistrarInterface.sol";
import "./interfaces/KeeperRegistryInterface.sol";
import "./interfaces/Link677Interface.sol";
import "./interfaces/PegSwapInterface.sol";
import "./CircuitBreaker.sol";

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

    /**
     * @notice Create a circuit breaker contract
     * @param _amount The amount of LINK to send to the circuit breaker contract
     * @param _priceFeed The address of the price feed to use
     * @param _owner The owner of the circuit breaker contract
     * @param _oracleDeviationLimit The deviation limit of the oracle
     * @param _externalContract The address of the external contract to call
     * @param _functionName The name of the function to call on the external contract
     */
    function createCircuitBreaker(
        uint256 _amount,
        address _priceFeed,
        address _owner,
        uint256 _oracleDeviationLimit,
        address _externalContract,
        string memory _functionName
    ) external {
        require(_amount >= 5e17, "Amount must be at least 0.5 LINK");
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
            _functionName,
            address(registry)
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

    /**
     * @notice Cancel upkeep
     * @param _id The ID of the upkeep to cancel
     */
    function cancel(uint256 _id) public {
        registry.cancelUpkeep(_id);
    }

    /**
     * @notice Withdraw LINK from upkeep
     * @param _id The ID of the upkeep to withdraw from
     * @param _to The address to withdraw to
     */
    function withdraw(uint256 _id, address _to) public {
        registry.withdrawFunds(_id, _to);
    }

    /**
     * @notice Get the user info
     * @param _user The address of the user
     * @param _id The ID of the upkeep
     * @return The user info
     */
    function getUserInfo(
        address _user,
        uint256 _id
    ) public view returns (UserInfo memory) {
        return users[_user][_id];
    }
}
