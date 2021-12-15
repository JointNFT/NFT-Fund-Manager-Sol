// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./Interfaces/IERC20.sol";
import "./Interfaces/IERC20Metadata.sol";
import "./utils/Context.sol";
import "./Interfaces/IERC721.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract erc20Fund is Context, IERC20, IERC20Metadata {
    event NFTBought(string openseaUrl, string imageUrl, uint value, address nftAddress);
    event NFTSold(string openseaUrl, string imageUrl, uint value, address nftAddress);
    
    struct Asset {
        string openseaUrl;
        string imageUrl;
        uint256 value;
        address nftAddress;
        uint256 timeBought;
    }

    mapping(address => uint256) private _balances;
    mapping(uint256 => Asset) private _assetMap;
    uint256 private _noOfAssets = 0;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    uint256 private _totalSupply;
    uint256 private _tokenPrice;
    uint256 private _tokenStartPrice;
    uint256 private _weiBalance;

    string private _fundImgUrl;
    string private _name;
    string private _symbol;
    address private _owner;
    string public _desc;
    string public _twitterHandle;

    /**
     * @dev Sets the values for {name}, {owner} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, uint256 tokenPrice_, address owner_, string memory fundImgUrl_) payable {
        
        _name = name_;
        _symbol = symbol_;
        _owner = owner_;
        _tokenPrice = tokenPrice_;
        _totalSupply = msg.value/tokenPrice_;
        _weiBalance = msg.value;
        _tokenStartPrice = tokenPrice_;
        _fundImgUrl = fundImgUrl_;
        _balances[owner_] = msg.value/tokenPrice_;
    }

    
    /**
     * @dev Returns the name of the fund.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function tokenPrice() public view virtual returns (uint) {
        return _tokenPrice;
    }

    function tokenStartPrice() public view virtual returns (uint) {
        return _tokenStartPrice;
    }

    function weiBalance() public view virtual returns (uint) {
        return _weiBalance;
    }

    function noOfAssets() public view virtual returns (uint) {
        return _noOfAssets;
    }
    
    function getAsset(uint256 nftIndex) public view virtual returns (Asset memory) {
        return _assetMap[nftIndex];
    }

    function fundImgUrl() public view virtual returns (string memory) {
        return _fundImgUrl;
    }

    /**
     * @dev Returns the owner of the fund
     */
    function ownerAddress() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    function getDivided(uint numerator, uint denominator) public pure returns(uint quotient, uint remainder) {
        quotient  = numerator / denominator;
        remainder = numerator - denominator * quotient;
        return (quotient, remainder);
    }
    
    function addFunds() public payable virtual returns (bool) {
        uint256 quotient;
        uint256 remainder;
        (quotient,remainder) = getDivided(msg.value, _tokenPrice);
        _mint(msg.sender, (quotient+remainder));
        _weiBalance += msg.value;
        return true;
    }
    
    function removeFunds(uint256 amount) public virtual {
        _burn(msg.sender, amount);
        uint256 eth_to_return = amount * _tokenPrice;
        _weiBalance -= eth_to_return;
        (bool success, ) = payable(msg.sender).call{value: eth_to_return}("");
        require(success, "Failed to send Ether");
    }

    function buyNFT(address nftAddress, string memory openseaUrl, string memory imgUrl, uint256 value) public virtual onlyOwner { 
        require(_weiBalance - value > 0, "Not enough eth to buy NFT");
        Asset memory asset = Asset(openseaUrl, imgUrl, value, nftAddress, block.timestamp);
        _assetMap[_noOfAssets] = asset;
        _noOfAssets += 1;
        _weiBalance = _weiBalance - value;
        emit NFTBought(openseaUrl, imgUrl, value, nftAddress);
    }

    // Replace item to be deleted by the last element, and delete the last element
    function deleteNFTandRearrange(uint256 assetNumber) public virtual returns(Asset memory){
        Asset memory deletedAsset = _assetMap[assetNumber];
        _assetMap[assetNumber] = _assetMap[_noOfAssets-1];
        _noOfAssets -= 1;
        return deletedAsset;
    }

    function sellNFT(uint256 assetNumber, uint256 value) public virtual onlyOwner{
        require(_noOfAssets > 0);
        Asset memory deletedAsset = deleteNFTandRearrange(assetNumber);
        _weiBalance += value;
        uint256 old_value = deletedAsset.value;
        _tokenPrice = (_tokenPrice * value)/old_value;
        emit NFTSold(deletedAsset.openseaUrl, deletedAsset.imageUrl, deletedAsset.value, deletedAsset.nftAddress);
    }

    function setTokenPrice(uint256 tokenPrice_) public virtual onlyOwner{
        _tokenPrice = tokenPrice_;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can use this function");
        _;
    }
    
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}