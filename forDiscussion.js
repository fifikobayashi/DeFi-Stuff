const Web3 = require('web3');
const INFURA_ID = "YOUR OWN INFURA ID"; // use your own Infura Project ID
const TARGET_ADDRESS = '0x57805e5a227937BAc2B0FdaCaA30413ddac6B8E1'.toLowerCase(); // furu proxy contract

let provider = new Web3.providers.WebsocketProvider('wss://mainnet.infura.io/ws/v3/'+INFURA_ID);
let web3 = new Web3(provider);

// initialise parameters for 1inch dex aggregator
const BigNumber = require('bignumber.js');
const tokenDecimals = 18;
const oneSplitABI = require('./abis/onesplit.json');
const onesplitAddress = "0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E"; // 1plit contract address on Main net
const onesplitContract = new web3.eth.Contract(oneSplitABI, onesplitAddress); // instantiates the 1split contract
const oneSplitDexes = [
  "Uniswap",
  "Kyber",
  "Bancor",
  "Oasis",
  "Curve Compound",
  "Curve USDT",
  "Curve Y",
  "Curve Binance",
  "Curve Synthetix",
  "Uniswap Compound",
  "Uniswap CHAI",
  "Uniswap Aave",
  "Mooniswap",
  "Uniswap V2",
  "Uniswap V2 ETH",
  "Uniswap V2 DAI",
  "Uniswap V2 USDC",
  "Curve Pax",
  "Curve renBTC",
  "Curve tBTC",
  "Dforce XSwap",
  "Shell",
  "mStable mUSD"
];

const subscription = web3.eth.subscribe('pendingTransactions', (err, res) => {
  if (err) console.error(err);
});

subscription.on('data', (txHash) => {
   setTimeout(async () => {
     try {
       let tx = await web3.eth.getTransaction(txHash);

       // filter on outbound transactions from target address
       if (tx && tx.to && tx.to.toLowerCase() === TARGET_ADDRESS) {
            console.log('Pending inbound transaction to Furucombo Proxy contract')
            console.log('Tx Hash: ',txHash );
            console.log('Tx Amount(in Ether): ',web3.utils.fromWei(tx.value, 'ether'));
            console.log('Tx Date/Time: ',new Date());

            /** Step 2: reverse engineer the DeFi lego set used based on tx hash
              - call decombo(txHash), returns a combo object
              - if the combo tx has a successful status AND profitable arb then store in array
            **/

            /** Step 3: calls 1inch aggregator contract functions
              - getQuotes(fromToken, toToken, amount, callback)
              - add net profit calculation logic factoring in:
                    gas, liquidity, slippage and r/r ratios that I'm comfortable with
              - approveToken(tokenInstance, receiver, amount, callback)
            **/

            /** Step 4: execute the series of swaps or notify bot owner via telegram bot
              - call executeTrades() or notifyViaTelegram()
            **/
        }
    } catch (err) {
        console.error(err);
    }
  }, 15 * 1000); // running at 15 second intervals
});
