pragma solidity 0.6.12;

import "https://github.com/sushiswap/sushiswap/blob/master/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/FlashLoanReceiverBase.sol";
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/ILendingPoolAddressesProvider.sol";
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/ILendingPool.sol";
/*
    Ropsten instances:
    - Uniswap V2 Router:                    0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    - Sushiswap V1 Router:                  0x55321ae0a211495A7493A9dE1385EeD9D9027106   <-- borrowing @BoringCrypto's instance on Ropsten since there are no official sushi routers on testnet
    - DAI:                                  0xf80A32A835F79D7787E8a8ee5721D0fEaFd78108
    - ETH:                                  0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    - Aave LendingPoolAddressesProvider:    0x1c8756FD2B28e9426CDBDcC7E3c4d64fa9A54728
    
    Mainnet instances:
    - Uniswap V2 Router:                    0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    - Sushiswap V1 Router:                  0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F
    - DAI:                                  0x6B175474E89094C44Da98b954EedeAC495271d0F
    - ETH:                                  0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    - Aave LendingPoolAddressesProvider:    0x24a42fD28C976A61Df5D00D0599C34c4f90748c8
*/

contract Flashloan is FlashLoanReceiverBase {

    IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)); // sushi / uni V2 router02 address
    address assetToTrade = address(0xf80A32A835F79D7787E8a8ee5721D0fEaFd78108); //  address of the ERC20 token you want to swap for
    uint256 amountToTrade = 1 ether; // how much of the ERC20 token you want to swap for in terms of ether

    // initialize router02 and trade paramaters
    constructor(address _addressProvider) FlashLoanReceiverBase(_addressProvider) public { }

    /*
        This function is called after your contract has received the flash loaned amount
        Note: when testing make sure there is enough ether on the contract to pay for the Aave 0.09% fee plus gas
     */
    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    )
        external
        override
    {
        require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance");

        // execute the ether for ERC20 token trade
        tradeEtherForERC20(amountToTrade, assetToTrade);

        uint totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }

    /**
        Flash loan 1000000000000000000 wei (1 ether) worth of `_asset`
     */
    function flashloan(address _asset) public onlyOwner {
        bytes memory data = "";
        uint amount = 1 ether; // adjust how much you want to flash borrow

        ILendingPool lendingPool = ILendingPool(addressesProvider.getLendingPool());
        lendingPool.flashLoan(address(this), _asset, amount, data);
    }
    
     /*
    @PARAMS:
    amountToTrade - how much Ether (in wei) you'd like to trade for the specified ERC20 token
    ERC20Address - the address of the ERC20 token you want to swap your Ether for
    routerAddress - the address of the Router02 you're interfacing with
    */
    function tradeEtherForERC20(uint256 amountToTrade, address ERC20Address) public payable {

        // setting deadline to avoid scenario where miners hang onto it and execute at a more profitable time
        uint deadline = block.timestamp + 300; // i.e. 5 minutes
        
        // execute ETH to ERC20 token trade
        uniswapV2Router.swapETHForExactTokens{ value: msg.value }(amountToTrade, getPathForETHToToken(ERC20Address), address(this), deadline);

        // refund leftover ETH to user
        msg.sender.call{ value: address(this).balance }("");
    }

    // Using a WETH wrapper here since there are no direct ETH pairs in Uniswap v2 and sushiswap v1 is based on uniswap v2
    function getPathForETHToToken(address ERC20Token) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = ERC20Token;
    
        return path;
    }

}