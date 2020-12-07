pragma solidity 0.6.6;

import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";

contract UniswapV2Swap {
    
  IUniswapV2Router02 public uniswapRouter;
  address private kovanAsset;
  address private router02Address;

  // initialise the Uniswap v2 Router02 address on deployment
  constructor(IUniswapV2Router02 _routerAddress) public {
    uniswapRouter = IUniswapV2Router02(_routerAddress);
  }

  function convertEthToERC20(uint _erc20Amount, address _erc20Address) public payable {
    uint deadline = block.timestamp + 15; // to prevent miners executing it at a later date that advantages them
    uniswapRouter.swapETHForExactTokens{ value: msg.value }(_erc20Amount, getPathForETHtoERC20(_erc20Address), address(this), deadline);
    
    // return remaining balance to user
    (bool success,) = msg.sender.call{ value: address(this).balance }("");
    require(success, "refund failed");
  }
  
  function getEstimatedETHforERC20(uint _swapAmount, address _token) public view returns (uint[] memory) {
    return uniswapRouter.getAmountsIn(_swapAmount, getPathForETHtoERC20(_token));
  }

  // no direct ETH pairs in UniV2 so need to use a WETH wrapper
  function getPathForETHtoERC20(address _token) private view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = _token;
    
    return path;
  }
  
  // payable for the contract to receive ETH
  receive() payable external {}
}