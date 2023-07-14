// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

contract OrderManagement is Ownable {

    // Product
    enum Code {
        P01500,
        P02500,
        P03150,
        P04100,
        P05100
    }

    struct Product {
        string description;
        uint256 price;
        uint256 stock;
    }

    mapping(Code => Product) public products;

    // Order
    enum OrderStatus {
        PENDING,
        CANCELLED,
        IN_PREPARATION,
        PREPARED,
        IN_TRANSIT,
        DELIVERED,
        VERIFIED
    }

    OrderStatus private orderStatus;

    struct Order {
        address customer;
        OrderStatus status;
        mapping(uint16 => uint16) productQuantity;
        uint256[] productQuantityKeys;
        string[] notes;
        string deliveryAddress;
        uint256 total;
    }
    mapping(uint256 => Order) public orders;

    uint256 private orderId;

    constructor() {
        initializeProducts();
    }

    function initializeProducts() private {
        // Code: 01500, Description: Tropical Blends Natural Juices with Pineapple
        products[Code.P01500] = Product(
            "Tropical Blends Natural Juices with Pineapple.",
            150,
            10000
        );

        // Code: 02500, Description: Fresh Tea Iced Tea with Lemon
        products[Code.P02500] = Product(
            "Fresh Tea Iced Tea with Lemon.",
            150,
            20000
        );

        // Code: 03150, Description: Garden Lemonades Lemonade flavored with Mint
        products[Code.P03150] = Product(
            "Garden Lemonades Lemonade flavored with Mint.",
            315,
            15000
        );

        // Code: 04100, Description: Natural Boost Energizing Drink with Ginger
        products[Code.P04100] = Product(
            "Natural Boost Energizing Drink with Ginger.",
            410,
            8000
        );
    }

    function placeOrder(uint16[] memory _codes, uint16[] memory _quantities, string memory _deliveryAddress, string memory _note) public onlyOwner
        returns (uint256) {

        require(
            _codes.length == _quantities.length,
            "Codes array and quantities array lengths do not match"
        );

        ++orderId;
        Order storage order = orders[orderId];

        order.customer = msg.sender;
        order.status = OrderStatus.PENDING;
        if (bytes(_note).length!=0) {
            order.notes.push(string.concat("Place Order - Note: ", _note));
        }
        order.deliveryAddress = _deliveryAddress;

        for (uint16 i = 0; i < _codes.length; i++) {
            Code code = Code(_codes[i]);
            uint16 quantity = _quantities[i];
            require(
                products[code].stock >= quantity,
                "Insufficient quantity available for the product"
            );
            order.total += products[code].price * quantity;
            order.productQuantity[uint16(code)] = quantity;
            order.productQuantityKeys.push(uint16(code));
            products[code].stock -= quantity;
        }
        //emit OrderRegistered(orderId.current(), msg.sender);
        return orderId;
    }

    function getOrder(uint256 id) onlyOwner public view
        returns (uint8, uint16[] memory, uint16[] memory, string[] memory, string memory, uint256) {
        
        Order storage order = orders[id];

        uint16[] memory codes = new uint16[](
            order.productQuantityKeys.length
        );
        uint16[] memory quantities = new uint16[](
            order.productQuantityKeys.length
        );

        for (uint16 i = 0; i < order.productQuantityKeys.length; i++) {
            codes[i] = i;
            quantities[i] = order.productQuantity[i];
        }

        return (uint8(order.status), codes, quantities, order.notes, order.deliveryAddress, order.total);
    }

    function cancelOrder(uint256 id) public onlyOwner {
        Order storage order = orders[id];
        require(
            order.status == OrderStatus.PENDING,
            "Order cannot be cancelled"
        );
        order.status = OrderStatus.CANCELLED;
        //emit OrderCancelled(id);
    }
}