/*
 **                                                                                                                                                              
 **                                                                   dddddddd                                                                                   
 **  PPPPPPPPPPPPPPPPP                                                d::::::d                  DDDDDDDDDDDDD                  AAA                 OOOOOOOOO     
 **  P::::::::::::::::P                                               d::::::d                  D::::::::::::DDD              A:::A              OO:::::::::OO   
 **  P::::::PPPPPP:::::P                                              d::::::d                  D:::::::::::::::DD           A:::::A           OO:::::::::::::OO 
 **  PP:::::P     P:::::P                                             d:::::d                   DDD:::::DDDDD:::::D         A:::::::A         O:::::::OOO:::::::O
 **    P::::P     P:::::Paaaaaaaaaaaaa  nnnn  nnnnnnnn        ddddddddd:::::d   aaaaaaaaaaaaa     D:::::D    D:::::D       A:::::::::A        O::::::O   O::::::O
 **    P::::P     P:::::Pa::::::::::::a n:::nn::::::::nn    dd::::::::::::::d   a::::::::::::a    D:::::D     D:::::D     A:::::A:::::A       O:::::O     O:::::O
 **    P::::PPPPPP:::::P aaaaaaaaa:::::an::::::::::::::nn  d::::::::::::::::d   aaaaaaaaa:::::a   D:::::D     D:::::D    A:::::A A:::::A      O:::::O     O:::::O
 **    P:::::::::::::PP           a::::ann:::::::::::::::nd:::::::ddddd:::::d            a::::a   D:::::D     D:::::D   A:::::A   A:::::A     O:::::O     O:::::O
 **    P::::PPPPPPPPP      aaaaaaa:::::a  n:::::nnnn:::::nd::::::d    d:::::d     aaaaaaa:::::a   D:::::D     D:::::D  A:::::A     A:::::A    O:::::O     O:::::O
 **    P::::P            aa::::::::::::a  n::::n    n::::nd:::::d     d:::::d   aa::::::::::::a   D:::::D     D:::::D A:::::AAAAAAAAA:::::A   O:::::O     O:::::O
 **    P::::P           a::::aaaa::::::a  n::::n    n::::nd:::::d     d:::::d  a::::aaaa::::::a   D:::::D     D:::::DA:::::::::::::::::::::A  O:::::O     O:::::O
 **    P::::P          a::::a    a:::::a  n::::n    n::::nd:::::d     d:::::d a::::a    a:::::a   D:::::D    D:::::DA:::::AAAAAAAAAAAAA:::::A O::::::O   O::::::O
 **  PP::::::PP        a::::a    a:::::a  n::::n    n::::nd::::::ddddd::::::dda::::a    a:::::a DDD:::::DDDDD:::::DA:::::A             A:::::AO:::::::OOO:::::::O
 **  P::::::::P        a:::::aaaa::::::a  n::::n    n::::n d:::::::::::::::::da:::::aaaa::::::a D:::::::::::::::DDA:::::A               A:::::AOO:::::::::::::OO 
 **  P::::::::P         a::::::::::aa:::a n::::n    n::::n  d:::::::::ddd::::d a::::::::::aa:::aD::::::::::::DDD A:::::A                 A:::::A OO:::::::::OO   
 **  PPPPPPPPPP          aaaaaaaaaa  aaaa nnnnnn    nnnnnn   ddddddddd   ddddd  aaaaaaaaaa  aaaaDDDDDDDDDDDDD   AAAAAAA                   AAAAAAA  OOOOOOOOO     
 **  
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Interfaces/ITickets.sol";
import "./Operations.sol";
import "./Interfaces/ITerminalV1_1.sol";
import "./Interfaces/IOperatorStore.sol";


contract PandaRefund is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public pandaToken;
    IERC20 public JBXToken;
    ITerminalV1_1  public terminalv1_1;
    IOperatorStore public operatorStore;
    uint256 public treasuryRedeemAmount;
    bytes32 public merkleRoot;
    bool public openRefund = true;
    uint256[] private operationsRedeem = [Operations.Redeem];
    mapping(address => uint256) public refundMap;
    uint256 public lastNow;
    uint256 public timeInterval = 7 days;

    uint256 public constant JBXTotal = 6_364_650 ether;
    uint256 public constant PandaTotle = 1_928_747_627 ether;
    uint256 public constant PandaPerETH = 500_000;

    address public constant BLACK_HOLE_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant PANDADAO_PROJECT_ID = 573;//409;
    
    


    event Redeem(address recipient, uint256 tokenAmount, uint256 receiveEther);
    event Treasury_Redeem(address recipient, uint256 tokenAmount);
    event MerkleRootChanged(bytes32 merkleRoot);
    event WithdrawERC20(address recipient, address tokenAddress, uint256 tokenAmount);
    event WithdrawEther(address recipient, uint256 amount);


    modifier refundOpenning() {
        require(openRefund, "PandaDAO: refund close.");
        _;
    }

    modifier timeOut() {
        require(block.timestamp - lastNow < timeInterval, "PandaDAO: time out!");
        _;
    }



    /**
     * @dev Constructor.
     */
    constructor(
        address pandaToken_,
        address jbxToken_,
        address terminalv1_1_,
        address operatorStore_
    )
    {
        pandaToken = IERC20(pandaToken_);
        JBXToken = IERC20(jbxToken_);
        terminalv1_1 = ITerminalV1_1(terminalv1_1_);
        operatorStore = IOperatorStore(operatorStore_);
        lastNow = block.timestamp;
    }


    // function hasPermission(
    //     address _operator,
    //     address _account,
    //     uint256 _domain,
    //     uint256 _permissionIndex
    // ) external view returns (bool) {
    //     return operatorStore.hasPermission(_operator, _account, _domain, _permissionIndex);
    // }


    /**
     * @dev redeem $PANDA  tokens.
     * @param amount The amount of the $PANDA.
     , bytes32[] calldata merkleProof
     */
    function redeem(uint256 amount, uint256 totalAmount) external nonReentrant refundOpenning timeOut{
        require(openRefund, "PandaDAO: refund close.");
        require(amount > 0, "PandaDAO: Valid amount required.");
        require(pandaToken.balanceOf(msg.sender) >= refundMap[msg.sender] +  amount, "PandaDAO: you do not have enough PandaToken.");
        require(totalAmount >= refundMap[msg.sender] + amount, "PandaDAO: you do not have enough PandaToken.");

        // bytes32 leaf = keccak256(abi.encodePacked(msg.sender, totalAmount));
        // bool valid = MerkleProof.verify(merkleProof, merkleRoot, leaf);
        // require(valid, "PandaDAO: Valid proof required.");

        refundMap[msg.sender] = refundMap[msg.sender] + amount;

        terminalv1_1.redeem(msg.sender, PANDADAO_PROJECT_ID, amount, 0, payable(msg.sender), false);
        treasuryRedeemAmount += amount;

        uint256 jbxAmount = amount * JBXTotal * 2 / PandaTotle;
        JBXToken.safeTransfer(msg.sender, jbxAmount);
        uint256 etherAmount = amount / PandaPerETH * 95 / 100;
        (bool success,) = msg.sender.call{value:etherAmount}("");
        require(success, "redeem ether fail!");
        emit Redeem(msg.sender, amount, etherAmount);
    }

    /**
     * @dev treasury redeem $PANDA  tokens.
     */
    function treasuryRedeem() external nonReentrant onlyOwner {
        require(treasuryRedeemAmount > 0, "PandaDAO: Valid amount required.");
        require(pandaToken.balanceOf(msg.sender) >= treasuryRedeemAmount, "PandaDAO: you do not have enough PandaToken.");
        terminalv1_1.redeem(msg.sender, PANDADAO_PROJECT_ID, treasuryRedeemAmount, 0, payable(msg.sender), false);
        treasuryRedeemAmount = 0;
        emit Treasury_Redeem(msg.sender, treasuryRedeemAmount);
    }

    /**
     * @dev Sets the merkle root. Only callable if the root is not yet set.
     * @param _merkleRoot The merkle root to set.
     */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
        emit MerkleRootChanged(_merkleRoot);
    }

    function setRefundOpen(bool open_) external onlyOwner {
        openRefund = open_;
    }

    function refreshLastNow() external onlyOwner {
        lastNow = block.timestamp;
    }

    function setTimeInterval(uint256 timeInterval_) external onlyOwner {
        timeInterval = timeInterval_;
    }


    /**
     * @dev withdrawERC20  tokens.
     * @param tokenAddress  token
     * @param tokenAmount amount
     */
    function withdrawERC20(
        address tokenAddress, 
        uint256 tokenAmount
    ) external onlyOwner 
    {
        require(tokenAddress != address(0), "Zero Token address!");
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);

        emit WithdrawERC20(msg.sender, tokenAddress, tokenAmount);
    }

    

    /**
     * @dev withdraw Ether.
     * @param amount amount
     */
    function withdrawEther(uint256 amount) external onlyOwner {
        (bool success,) = msg.sender.call{value:amount}("");
        require(success, "withdrawEther fail!");
        emit WithdrawEther(msg.sender, amount);
    }

    fallback () external payable {}

    receive () external payable {}

}
