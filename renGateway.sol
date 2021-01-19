pragma solidity >=0.6.12;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface IGateway {
    function mint(bytes32 _pHash, uint256 _amount, bytes32 _nHash, bytes calldata _sig) external returns (uint256);
    function burn(bytes calldata _to, uint256 _amount) external returns (uint256);
}

interface IGatewayRegistry {
    function getGatewayBySymbol(string calldata _tokenSymbol) external view returns (IGateway);
    function getTokenBySymbol(string calldata _tokenSymbol) external view returns (IERC20);
}

contract RenGateway {
    IGatewayRegistry public registry;

    // allows the user to attach a message to their deposits and withdrawals
    event Deposit(uint256 _amount, bytes _msg);
    event Withdrawal(bytes _to, uint256 _amount, bytes _msg);

    // provide the gateway registry contract on deployment
    // find them here https://docs.renproject.io/developers/docs/deployed-contracts
    constructor(IGatewayRegistry _registry) public {
        registry = _registry;
    }
    
    /**
    * @dev The deposit function accepts the underlying amount of an asset and mints a scaled amount of RenERC20.
    * @param _msg - optional message for the mint tx
    * @param _amount - represents the amount of BTC we are transferring into Ethereum
    * @param _nHash - none hash used to uniquely identify a lock into Ethereum
    * @param _sig - signature from RenVM to approve the mint
    **/
    function deposit (
        // Parameters from users
        bytes calldata _msg,
        
        // Parameters from Darknodes
        uint256        _amount,
        bytes32        _nHash,
        bytes calldata _sig
        ) external {
        
        // The hash of any extra data being used e.g. attached messages
        bytes32 pHash = keccak256(abi.encode(_msg));
        
        // obtains the address of the BTCGateway and call mint(), which returns the 
        // amount of renBTC token received from the transfer minus a small fee to RenVM
        uint256 mintedAmount = registry.getGatewayBySymbol("BTC").mint(
            pHash, 
            _amount, 
            _nHash, 
            _sig
        );
        
        emit Deposit(mintedAmount, _msg);
    }
    
    /**
    * @dev calls the burn function on the gateway contract and logs the withdrawal
    * @param _msg - message of the withdraw
    * @param _to - Bitcoin address to receive the funds to
    * @param _amount - amount of BTC to withdraw
    **/
    function withdraw(
        bytes calldata _msg, 
        bytes calldata _to, 
        uint256 _amount
        ) external {
        
        // obtains the address of the BTCGateway and call burn(), which returns the 
        uint256 burnedAmount = registry.getGatewayBySymbol("BTC").burn(_to, _amount);
        
        emit Withdrawal(_to, burnedAmount, _msg);
    }
    
    /**
     * @dev retrieves the balance of this contract
     **/
    function balance() public view returns (uint256) {
        return registry.getTokenBySymbol("BTC").balanceOf(address(this));
    }
}