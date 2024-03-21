pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract ACL is AccessControlEnumerable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller does not has a DEFAULT_ADMIN_ROLE"
        );
        _;
    }

    modifier onlyMinter() {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "Caller does not has a MINTER_ROLE"
        );
        _;
    }

    modifier onlyBurner() {
        require(
            hasRole(BURNER_ROLE, msg.sender),
            "Caller does not has a BURNER_ROLE"
        );
        _;
    }

    modifier onlyPauser() {
        require(
            hasRole(PAUSER_ROLE, msg.sender),
            "Caller does not has a DEFAULT_ADMIN_ROLE"
        );
        _;
    }

    function grantAdmin(address admin) external onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function revokeAdmin(address admin) external onlyAdmin {
        revokeRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function grantMinter(address minter) external onlyAdmin {
        grantRole(MINTER_ROLE, minter);
    }

    function revokeMinter(address minter) external onlyAdmin {
        revokeRole(MINTER_ROLE, minter);
    }

    function grantBurner(address burner) external onlyAdmin {
        grantRole(BURNER_ROLE, burner);
    }

    function revokeBurner(address burner) external onlyAdmin {
        revokeRole(BURNER_ROLE, burner);
    }

    function grantPauser(address pauser) external onlyAdmin {
        grantRole(PAUSER_ROLE, pauser);
    }

    function revokePauser(address pauser) external onlyAdmin {
        revokeRole(PAUSER_ROLE, pauser);
    }
}

contract PalmToken is ERC20, ERC20Burnable, Pausable, ACL, ERC20Permit {

    uint256 public totalMintAmount = 0;
    uint256 public totalBurnAmount = 0;
    uint256 public totalTransferedAmount = 0;

    mapping(address => bool) public freezeAccounts;
    
    event Memo(string memo);
    event Freeze(address account);
    event Unfreeze(address account);

    modifier notFreeze() {
        require(
            freezeAccounts[msg.sender] != true,
            "Caller has been freeze"
        );
        _;
    }
    
    constructor() ERC20("PalmToken", "PTKN") ERC20Permit("PTKN") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    function pause() public onlyPauser {
        _pause();
    }

    function unpause() public onlyPauser {
        _unpause();
    }

    function freeze(address account) public onlyAdmin {
        freezeAccounts[account] = true;
        emit Freeze(account);
    }

    function unfreeze(address account) public onlyAdmin {
        freezeAccounts[account] = false;
        emit Freeze(account);
    }

    function mint(uint256 amount) public onlyMinter {
        _mint(msg.sender, amount);
        totalMintAmount += amount;
    }

    function mintTo(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
        totalMintAmount += amount;
    }

    function burn(uint256 amount) public override(ERC20Burnable){
        _burn(msg.sender, amount);
        totalBurnAmount += amount;
    }

    function burnFrom(address from, uint256 amount) public override(ERC20Burnable){
        bool isBurner = hasRole(BURNER_ROLE, msg.sender);
        require(freezeAccounts[msg.sender] != true, "Caller has been freeze");

        if(isBurner || from == msg.sender){
            _burn(from, amount);
            totalBurnAmount += amount;
        }else{
            require(isBurner, "Caller does not has a BURNER_ROLE");
        }
    }

    function transfer(address to, uint256 amount) public override returns (bool){
        require(freezeAccounts[msg.sender] != true, "Caller has been freeze");

        address owner = _msgSender();
        _transfer(owner, to, amount);
        totalTransferedAmount += amount;

        return true;
    }

    function transfer(address to, uint256 amount, string memory memo) public {
        require(freezeAccounts[msg.sender] != true, "Caller has been freeze");

        if (transfer(to, amount)) {
            totalTransferedAmount += amount;
            if (bytes(memo).length > 0) {
                emit Memo(memo);
            }
        }
    }

    function transferFrom(address from, address to, uint256 amount, string memory memo) public {
        require(freezeAccounts[msg.sender] != true, "Caller has been freeze");

        if (transferFrom(from, to, amount)) {
            totalTransferedAmount += amount;
            if (bytes(memo).length > 0) {
                emit Memo(memo);
            }
        }
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool){
        require(freezeAccounts[msg.sender] != true, "Caller has been freeze");
        totalTransferedAmount += amount;

        super.transferFrom(from, to, amount);

        return true;
    }

}