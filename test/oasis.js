const Oasis = artifacts.require('Oasis');
// const OasisERC20 = artifacts.require('OasisERC20');
const OrderManagement = artifacts.require('OrderManagement');

contract('Oasis', (accounts) => {
  console.log("Accounts: ", accounts);
  
  const admin = accounts[0];
  const client1 = accounts[1];
  const client2 = accounts[2];

  before(async () => {
    oasisInstance = await Oasis.new({ from: accounts[0] });
  });


  it('should register a client', async () => {
    const clientName = 'Client1';
    const deliveryAddress = 'Address1';

    await oasisInstance.registerClient(client1, clientName, deliveryAddress, {from: admin});
    const client = await oasisInstance.clients.call(client1, {from: admin});
    
    assert.equal(client.name, clientName, 'Client name does not match');
    assert.equal(client.deliveryAddress, deliveryAddress, 'Delivery address does not match');
    assert.equal(client.registered, true, 'Client is not registered');
  });

  it('should place an order', async () => {
    const codes = [1, 2, 3];
    const quantities = [10, 20, 30];
    const note = 'Order note';

    const tx = await oasisInstance.placeOrder(codes, quantities, note, {from: client1});
    assert.equal(tx.receipt.status, true, 'Transaction failed');

    const orderId = await oasisInstance.clientOrders.call(client1, 0);
    const orderContractAddress = await oasisInstance.clientOrderManagements.call(client1);

    const orderContractInstance = await OrderManagement.at(orderContractAddress);

    const order = await orderContractInstance.getOrder(orderId, {from: oasisInstance.address});

    assert.equal(order[0], 0, 'Order Status is not PENDING');
    assert.equal(order[1].length, codes.length, 'Order codes length does not match');
    assert.equal(order[2].length, quantities.length, 'Order quantities length does not match');
    assert.equal(order[3], `Place Order - Note: ${note}`, 'Notes does not match');
    assert.equal(order[4], "Address1", 'Delivery address does not match');
    assert.equal(order[5], 20100, 'Total order does not match');
  });

  it('should get an order', async () => {
    const orderIds = await oasisInstance.getAllOrders(client1, { from: client1 });
    assert.equal(orderIds.length, 1, 'Order count does not match');

    const orderId = orderIds[0];
    const order = await oasisInstance.getOrder(client1, orderId, { from: client1 });
    assert.ok(order, 'Order client does not exist');
  });
});
