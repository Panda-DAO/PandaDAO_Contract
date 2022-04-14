# PandaDAO_Contract

## Claim

1. Backend: when time for dividend sharing of current settlement cycle is coming, MerkleTree model of which leaf containing all accounts' income and address will be calculated. 

2. Frontend: send claim request to backend for user's token amount and MerkleProof, then send claiming transaction to ethereum and claimed amount of current settlement cycle.

3. Backend: receive claim notify from frontend and record or update the amount claimed by user.

Interaction process: https://github.com/People-DAO/Panda_Contract/issues/2

## Refund 

1. The user first authorizes the Refund contract to destroy PANDA tokens through the Juicebox's OperatorStore: "0xab47304D987390E27Ce3BC0fA4Fe31E3A98B0db2" contract's setOperator;

2. After authorization, the user destroys the user's PANDA token through the redeem function of the Refund contract and returns ETH. Before destroying, Refund will use the merkle tree to check whether the user is on the refund whitelist and the maximum number of refunds.

## veToken

### Introduction

1. The sources of voting power for DAO governance include: token holders, veToken holders, work group, leader. Work group voting weight is 15%, leader is 5%, and the remaining 80% is allocated according to the number of token or veToken held.

2. Exchange rate is stable(veToken:locked token = 1:1) and token holders are able to stake or claim at any time. It's temporarily decided that dividends are shared out once a year. Multi-signer can decide whether to share out the dividend in advance.

3. Dividend weights emission is at certain ratio. The minimum emission time period is one block.

### Roles

1. Owner: accessible to gnosis safe contract who has admin role.

2. Staker: accessible to public who is able to stake Panda token for voting power as well as earn dividends from DAO treasury.

## Main Operations

1. For Owner

- Emergency Operations: Turn on or off claiming or staking function

- Claim other mistaken tokens from other systems

2. For Staker

- Deposit Panda token for a certain address which could in turn get same amount of veToken

- Withdraw Panda token for burning same amount of veToken

## PandaInsight NFT

ERC1155 Standard Token

## PandaToken

ERC20 Standard Token of which code was originated by juicebox
