# Ethereum Multisig Wallet Contract. Solidity 0.7.5

Smart contrat for create multisig wallets up to 10 different ethereum addresses per wallet.

Manage funds in shared wallet with 10 addreses where each user have to right to approve or revoke a withdrawal transaction. 

## Deploy on Remix

Single page, to test just deploy it on Remix using the right version 0.7.5

## Contract main Functions

### - createWallet(addreses,signatures require) 
Up to 10 wallets and 10 of 10 signatures.

### - depositTowallet(wallet id) 
Send funds to created wallet, only for wallet members

### - createTransaction(wallet id, amount, member address) 
Create a transaction for send funds from wallet to a member.


### - signTransaction(wallet id, transaction id) 
Wallet member approve a withdrawal transaction.

### - revokeTransaction(wallet id, transaction id) 
Wallet member revoke approval for withdrawal transaction.

### - sendTransaction(wallet id, transaction id) 
Execute created transaction if contain required signatures.
