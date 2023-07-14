// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./OasisToken.sol";
import "./OrderManagement.sol";

contract Oasis is AccessControl {
    address private oasisERC20;

    // Clients
    struct Client {
        string name;
        string deliveryAddress;
        bool registered;
    }
    mapping(address => Client) public clients;

    // Access Control
    bytes32 public constant CLIENT_ROLE = keccak256("CLIENT_ROLE");
    bytes32 public constant WAREHOUSE_ROLE = keccak256("WAREHOUSE_ROLE");
    bytes32 public constant CARRIER_ROLE = keccak256("CARRIER_ROLE");

    // Order
    mapping(address => address) public clientOrderManagements;
    mapping(address => uint256[]) public clientOrders;

    // Events
    // event OrderRegistered(uint256 orderId, address indexed customer);
    // event OrderCancelled(uint256 orderId);
    // event OrderPrepared(uint256 orderId);
    // event OrderInTransit(uint256 orderId);
    // event OrderDelivered(uint256 orderId);
    // event OrderVerified(uint256 orderId, string reason);
    //event ChangeOrderStatus(OrderStatus status);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        oasisERC20 = address(new OasisToken());
    }

    // Admin add/remove Clients, Warehouse, Carrier
    function registerClient(address _newClient, string memory _name, string memory _deliveryAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!clients[_newClient].registered, "Client is already registered!");
        clients[_newClient] = Client(_name, _deliveryAddress, true);
        _grantRole(CLIENT_ROLE, _newClient);
        // emit register client
    }

    function removeClient(address _client) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(clients[_client].registered, "Client does not exist!");
        clients[_client].registered = false;
        _revokeRole(CLIENT_ROLE, _client);
        // emit remove client
    }

    // Manage Orders
    function placeOrder(uint16[] memory _codes, uint16[] memory _quantities, string memory _note) external onlyRole(CLIENT_ROLE) {
        if (clientOrderManagements[_msgSender()] == address(0)) {
            initOrderManagement();
        }
        uint256 orderId = OrderManagement(clientOrderManagements[_msgSender()]).placeOrder(_codes, _quantities, clients[_msgSender()].deliveryAddress, _note);
        clientOrders[_msgSender()].push(orderId);
        // emit place order
    }

    function initOrderManagement() internal {
        address addressOrderManagement = address(new OrderManagement());
        clientOrderManagements[_msgSender()] = addressOrderManagement;
    }

    modifier onlyAdminOrClient() {
        require(hasRole(CLIENT_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must be Admin or Client to perform this action.");
        _;
    }

    function getOrder(address _client, uint256 _orderId) external view onlyAdminOrClient returns (uint8, uint16[] memory, uint16[] memory, string[] memory, string memory, uint256) {      
        return OrderManagement(clientOrderManagements[_client]).getOrder(_orderId);
    }

    function getAllOrders(address _client) external view onlyAdminOrClient returns (uint256[] memory) {
        return clientOrders[_client];
    }
}