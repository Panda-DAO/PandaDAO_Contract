/*

__________                    .___      ________      _____   ________   
\______   \_____    ____    __| _/____  \______ \    /  _  \  \_____  \  
 |     ___/\__  \  /    \  / __ |\__  \  |    |  \  /  /_\  \  /   |   \ 
 |    |     / __ \|   |  \/ /_/ | / __ \_|    `   \/    |    \/    |    \
 |____|    (____  /___|  /\____ |(____  /_______  /\____|__  /\_______  /
                \/     \/      \/     \/        \/         \/         \/ 

*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract PandaClaim is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public merkleRoot;
    address public pandaToken;
    mapping(address => uint256) public claimRecord;
    uint256 public claimCycle;

    address public constant ZERO_ADDRESS = address(0);
    


    event MerkleRootChanged(bytes32 merkleRoot);
    event Claim(address indexed claimant, uint256 amount);
    event WithdrawERC20(address recipient, address tokenAddress, uint256 tokenAmount);
    event WithdrawEther(address recipient, uint256 amount);

    modifier notZeroAddr(address addr_) {
        require(addr_ != ZERO_ADDRESS, "Zero address");
        _;
    }



    /**
     * @dev Constructor.
     */
    constructor(
        address pandaToken_
    )
    {
        pandaToken = pandaToken_;
    }

    /**
     * @dev deposit  tokens.
     * @param amount The amount of the deposit $PANDA.
     */
    function depositToken(uint256 amount) public {
        require(amount > 0, "PandaDAO: Valid amount required.");
        IERC20(pandaToken).transferFrom(msg.sender, address(this), amount);
    }


    /**
     * @dev Claims  tokens.
     * @param amount The amount of the claim being made.
     * @param merkleProof A merkle proof proving the claim is valid.
     */
    function claimTokens(uint256 amount, bytes32[] calldata merkleProof) public nonReentrant {
        require(amount > 0, "PandaDAO: Valid amount required.");
        require(claimRecord[msg.sender] < claimCycle, "PandaDAO: Valid claimCycle required.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        bool valid = MerkleProof.verify(merkleProof, merkleRoot, leaf);
        require(valid, "PandaDAO: Valid proof required.");
        claimRecord[msg.sender] = claimCycle;

        IERC20(pandaToken).transfer(msg.sender, amount);
        emit Claim(msg.sender, amount);
    }


    /**
     * @dev Sets the merkle root. Only callable if the root is not yet set.
     * @param _merkleRoot The merkle root to set.
     */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
        claimCycle++;
        emit MerkleRootChanged(_merkleRoot);
    }

    /**
     * @dev withdrawERC20  tokens.
     * @param recipient recipient
     * @param tokenAddress  token
     * @param tokenAmount amount
     */
    function withdrawERC20(
        address recipient,
        address tokenAddress, 
        uint256 tokenAmount
    ) external onlyOwner notZeroAddr(tokenAddress) 
    {
        IERC20(tokenAddress).transfer(recipient, tokenAmount);

        emit WithdrawERC20(recipient, tokenAddress, tokenAmount);
    }

    

    /**
     * @dev withdraw Ether.
     * @param recipient recipient
     * @param amount amount
     */
    function withdrawEther(address payable recipient, uint256 amount) external onlyOwner {
        (bool success,) = recipient.call{value:amount}("");
        require(success, "withdrawEther fail!");
        emit WithdrawEther(recipient, amount);
    }


}