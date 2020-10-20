const Web3 = require('web3');
let provider = new Web3.providers.WebsocketProvider('wss://rinkeby.infura.io/ws/v3/YOUR INFURA KEY');
let web3 = new Web3(provider);

const account = 'INSERT CONTRACT ADDRESS'.toLowerCase();
    const subscription = web3.eth.subscribe('pendingTransactions', (err, res) => {
        if (err) console.error(err);
    });

 subscription.on('data', (txHash) => {

   setTimeout(async () => {
     try {
       let tx = await web3.eth.getTransaction(txHash);
       if (tx && tx.from && tx.from.toLowerCase() === account) {
            console.log('Transaction Hash: ',txHash );
            console.log('Transaction Confirmation Index: ',tx.transactionIndex );// 0 when transaction is pending
            console.log('Transaction Received from: ',tx.from );
            console.log('Transaction Amount(in Ether): ',web3.utils.fromWei(tx.value, 'ether'));
            console.log('Transaction Receiving Date/Time: ',new Date());
        }
    } catch (err) {
        console.error(err);
    }
  }, 15 * 1000); // running at 15 seconds
});
