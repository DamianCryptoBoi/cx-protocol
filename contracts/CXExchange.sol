//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract CXExchange is EIP712("CXExchange", "1.0") {
    using SafeERC20 for IERC20;
    using Address for address payable;

    enum state {
        OPEN,
        TAKEN,
        CLAIMED,
        CANCELLED
    }

    struct Order {
        IERC20 makerToken;
        IERC20 takerToken;
        uint8 sourceChainId;
        uint8 destinationChainId;
        uint256 makingAmount;
        uint256 takingAmount;
        uint256 expireTime;
        uint256 salt;
    }

    bytes32 public constant FIXED_ORDER_TYPE_HASH =
        keccak256(
            "Order(address makerToken,address takerToken,uint8 sourceChainId,uint8 destinationChainId,uint256 makingAmount,uint256 takingAmount,uint256 expireTime,uint256 salt)"
        );

    mapping(address => mapping(bytes32 => state)) public orderState;
    mapping(address => mapping(bytes32 => uint256)) public holdingAmount;

    uint256 public makerFee;
    uint256 public takerFee;
    uint256 public constant FEE_DENOMINATOR = 10000;
    address public feeRecipient;
    address public operator;

    event OrderCreated(
        address indexed maker,
        address makerToken,
        address takerToken,
        uint8 sourceChainId,
        uint8 destinationChainId,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 expireTime,
        uint256 salt,
        bytes signature
    );

    event OrderAccepted(
        address indexed taker,
        address makerToken,
        address takerToken,
        uint8 sourceChainId,
        uint8 destinationChainId,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 expireTime,
        uint256 salt,
        bytes signature
    );

    event MakerClaimedOrder(address indexed maker, bytes32 orderHash);
    event TakerClaimedOrder(address indexed taker, bytes32 orderHash);

    event OrderCancelled(bytes32 orderHash, address maker);

    event FeeChanged(uint256 makerFee, uint256 takerFee);

    event FeeRecipientChanged(address feeRecipient);

    constructor(
        uint256 _makerFee,
        uint256 _takerFee,
        address _feeRecipient,
        address _operator
    ) {
        makerFee = _makerFee;
        takerFee = _takerFee;
        feeRecipient = _feeRecipient;
        operator = _operator;
    }

    function hashOrder(Order memory order) public view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(abi.encode(FIXED_ORDER_TYPE_HASH, order))
            );
    }

    function cancelOrder(bytes32 _orderHash) external {
        orderState[msg.sender][_orderHash] = state.CANCELLED;

        emit OrderCancelled(_orderHash, msg.sender);
    }

    function _takeFee(
        address _from,
        address _tokenAddress,
        uint256 _amount,
        uint256 _feeRatio
    ) private returns (uint256) {
        uint256 feeAmount = (_amount * _feeRatio) / FEE_DENOMINATOR;

        if (_tokenAddress == address(0)) {
            payable(feeRecipient).sendValue(feeAmount);
        } else {
            IERC20(_tokenAddress).safeTransferFrom(
                _from,
                feeRecipient,
                feeAmount
            );
        }

        return _amount - feeAmount;
    }

    // userA create order: sign => deposit token A to sc on chain 1 => emit event => save sig to DB
    // user B accept order: sign => depoit token B to sc on chain 2 => emit event => save sig to DB

    // user A claim on chain 2: call to BE to get sig from user B and another sig from BE
    // => pass 2 sigs to SC on chain 2 to claim the amount that user B deposited
    // the same for user B to claim tokens on chain 1

    function createOrder(
        Order calldata _order,
        bytes calldata _signatureFromOrderMaker
    ) external payable {
        require(_order.expireTime > block.timestamp + 60, "invalid expireTime");
        bytes32 orderHash = hashOrder(_order);

        require(
            SignatureChecker.isValidSignatureNow(
                msg.sender,
                orderHash,
                _signatureFromOrderMaker
            ),
            "bad signature from maker"
        );

        if (address(_order.makerToken) == address(0)) {
            require(msg.value == _order.makingAmount, "invalid making amount");
        } else {
            _order.makerToken.safeTransferFrom(
                msg.sender,
                address(this),
                _order.makingAmount
            );
        }

        emit OrderCreated(
            msg.sender,
            address(_order.makerToken),
            address(_order.takerToken),
            _order.sourceChainId,
            _order.destinationChainId,
            _order.makingAmount,
            _order.takingAmount,
            _order.expireTime,
            _order.salt,
            _signatureFromOrderMaker
        );
    }

    function acceptOrder(
        Order calldata _order,
        bytes calldata _signatureFromOrderTaker
    ) external payable {
        bytes32 orderHash = hashOrder(_order);
        require(
            orderState[msg.sender][orderHash] == state.OPEN,
            "Order already taken"
        );

        require(
            SignatureChecker.isValidSignatureNow(
                msg.sender,
                orderHash,
                _signatureFromOrderTaker
            ),
            "bad signature from taker"
        );
        if (address(_order.takerToken) == address(0)) {
            require(msg.value == _order.takingAmount, "invalid making amount");
        } else {
            _order.takerToken.safeTransferFrom(
                msg.sender,
                address(this),
                _order.takingAmount
            );
        }

        emit OrderAccepted(
            msg.sender,
            address(_order.makerToken),
            address(_order.takerToken),
            _order.sourceChainId,
            _order.destinationChainId,
            _order.makingAmount,
            _order.takingAmount,
            _order.expireTime,
            _order.salt,
            _signatureFromOrderTaker
        );
    }

    function takerClaimOrder(
        address maker,
        Order calldata _order,
        bytes calldata _signatureFromOrderMaker,
        bytes calldata _signatureFromOperator
    ) external {
        bytes32 orderHash = hashOrder(_order);

        require(
            SignatureChecker.isValidSignatureNow(
                maker,
                orderHash,
                _signatureFromOrderMaker
            ),
            "bad signature from maker"
        );

        require(
            SignatureChecker.isValidSignatureNow(
                operator,
                orderHash,
                _signatureFromOperator
            ),
            "bad signature from operator"
        );

        if (address(_order.makerToken) == address(0)) {
            payable(msg.sender).sendValue(_order.makingAmount);
        } else {
            _order.makerToken.transfer(msg.sender, _order.makingAmount);
        }

        emit TakerClaimedOrder(msg.sender, orderHash);
    }

    function makerClaimOrder(
        address taker,
        Order calldata _order,
        bytes calldata _signatureFromOrderTaker,
        bytes calldata _signatureFromOperator
    ) external {
        bytes32 orderHash = hashOrder(_order);

        require(
            SignatureChecker.isValidSignatureNow(
                taker,
                orderHash,
                _signatureFromOrderTaker
            ),
            "bad signature from taker"
        );

        require(
            SignatureChecker.isValidSignatureNow(
                operator,
                orderHash,
                _signatureFromOperator
            ),
            "bad signature from operator"
        );

        if (address(_order.takerToken) == address(0)) {
            payable(msg.sender).sendValue(_order.takingAmount);
        } else {
            _order.takerToken.transfer(msg.sender, _order.takingAmount);
        }

        emit TakerClaimedOrder(msg.sender, orderHash);
    }

    // function fillOrder(Order memory _order, bytes calldata _signature)
    //     external
    //     payable
    // {
    //     address maker = _order.maker;

    //     require(
    //         address(_order.makerToken) != address(0),
    //         "invalid maker token"
    //     );

    //     bytes32 orderHash = hashOrder(_order);

    //     require(
    //         SignatureChecker.isValidSignatureNow(maker, orderHash, _signature),
    //         "bad signature"
    //     );

    //     require(block.timestamp <= _order.expireTime, "order expired");
    //     require(!orderClosed[_order.maker][orderHash], "order closed");

    //     orderClosed[_order.maker][orderHash] = true;

    //     uint256 makingAmount = _order.makingAmount;
    //     uint256 takingAmount = _order.takingAmount;

    //     require(makingAmount > 0 && takingAmount > 0, "can't swap 0 amount");

    //     uint256 takerReceiveAmount = _takeFee(
    //         maker,
    //         address(_order.makerToken),
    //         makingAmount,
    //         takerFee
    //     );

    //     uint256 makerReceiveAmount = _takeFee(
    //         msg.sender,
    //         address(_order.takerToken),
    //         takingAmount,
    //         makerFee
    //     );

    //     // Maker => Taker: only ERC20
    //     _order.makerToken.safeTransferFrom(
    //         maker,
    //         msg.sender,
    //         takerReceiveAmount
    //     );

    //     // Taker => Maker
    //     if (address(_order.takerToken) == address(0)) {
    //         require(msg.value == takingAmount, "invalid eth value");
    //         payable(maker).sendValue(makerReceiveAmount);
    //     } else {
    //         _order.takerToken.safeTransferFrom(
    //             msg.sender,
    //             maker,
    //             makerReceiveAmount
    //         );
    //     }

    //     emit OrderFilled(
    //         orderHash,
    //         _order.maker,
    //         msg.sender,
    //         address(_order.makerToken),
    //         address(_order.takerToken),
    //         makingAmount,
    //         takingAmount
    //     );
    // }
}
