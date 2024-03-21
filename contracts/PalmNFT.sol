pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

contract ACL is AccessControlEnumerable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

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

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
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
}

contract PalmNFT is ERC721URIStorage, ERC721Enumerable, ACL {
    event Memo(string memo);

    bool public isPubliclyMintable = false;
    bool public isSBT = false; //soul-bound nft
    uint256 private _tokenIds;

    mapping(address => bool) public freezeAccounts;

    event Freeze(address account);
    event Unfreeze(address account);


    bool internal locked;

    modifier noReentrant() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    constructor() ERC721("Palm-NFT", "PalmNFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
    }

    function setPubliclyMintable(bool mintable) public onlyAdmin {
        isPubliclyMintable = mintable;
    }

    function setToSBT(bool SBT) public onlyAdmin {
        isSBT = SBT;
    }

    function freeze(address account) public onlyAdmin {
        freezeAccounts[account] = true;
        emit Freeze(account);
    }

    function unfreeze(address account) public onlyAdmin {
        freezeAccounts[account] = false;
        emit Freeze(account);
    }

    function safeMint(address to, string memory uri) public noReentrant returns (uint256) {
        bool isMinter = hasRole(MINTER_ROLE, msg.sender);

        if (isPubliclyMintable || isMinter) {
            uint256 tokenId = _tokenIds;
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, uri);
            _tokenIds += 1;

            return tokenId;
        } else {
            require(isPubliclyMintable, "This NFT is not publicly mintable");
            return 0;
        }
    }

    function setTokenURI(uint256 tokenId, string memory uri) public onlyAdmin {
        _setTokenURI(tokenId, uri);
    }

    function burn(uint256 tokenId) public {
        require(!isSBT, "This NFT was not permitted to burn");
        require(freezeAccounts[msg.sender] != true, "Caller has been freeze");

        bool isBurner = hasRole(BURNER_ROLE, msg.sender);
        if (isBurner) {
            _burn(tokenId);
        } else {
            require(
                msg.sender == ownerOf(tokenId),
                "Caller does not own this NFT"
            );

            _burn(tokenId);
        }
    }
    function transfer(address to, uint256 tokenId) public {
        require(!isSBT, "This NFT was not permitted to transfer");
        require(freezeAccounts[msg.sender] != true, "Caller has been freeze");
        safeTransferFrom(msg.sender, to, tokenId);
    }


    function safeTransfer(address to, uint256 tokenId) public {
        require(!isSBT, "This NFT was not permitted to transfer");
        require(freezeAccounts[msg.sender] != true, "Caller has been freeze");
        safeTransferFrom(msg.sender, to, tokenId);
    }

    // overrides

    // The following functions are overrides required by Solidity.

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _increaseBalance(
        address account, 
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function _update(
        address to, 
        uint256 tokenId, 
        address auth
    ) internal virtual override(ERC721, ERC721Enumerable) returns (address){
        return super._update(to, tokenId, auth);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(AccessControlEnumerable, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}