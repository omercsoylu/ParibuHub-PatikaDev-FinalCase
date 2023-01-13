# Business Card NFT Play2Earn Game

It is a repo ParibuHub-Patika.dev-Solidity-Practicum-Final-Case.


- @author/developer :[@omercsoylu](https://github.com/omercsoylu)

[Please visit this repo for frontend demo](https://github.com/omercsoylu/ParibuHub-PatikaDev-FinalCase-Frontend)


Firstly, BusinessToken ERC20 and BusinessCard ERC721 Contract must be deploy to any EVM-based blockchain network.
Then the "contract addresses" should be replaced with the variables in Contracts.js
The ABIs of each contract should be replaced with ​​in Abi.js

The BusinessWorld contract is deployed with the addresses of the BusinessToken and BusinessCard contracts.
In the same way, contract address and ABI of BusinessWorld should be replaced with in Contracts.js and Abi.js.

In order for the BusinessWorld contract to access the BusinessToken, 
the BusinessWorld contract address must be added as the owner with the "addOwner" function of the BusinessToken contract.

!!"polygon testnet" mumbai is used in this project.
Please make sure you have polygon mumbai tesnet in your wallet and active network is mumbai when testing.


## Demo

https://heartfelt-florentine-6a4329.netlify.app/

  
## Snapshots

![Uygulama Ekran Görüntüsü](https://cdn.discordapp.com/attachments/1023613609105952812/1062768255229509804/image.png)
![Uygulama Ekran Görüntüsü](https://cdn.discordapp.com/attachments/1023613609105952812/1062770282332422164/image.png)

  
## Contents

- ERC20 Token to be minted by staking business card NFTs
- in ERC721 standard, Business card NFTs 
- A demo frontend made with React

  
## Used technologies

**:** React, ethers.js, Solidity(ERC20 Token, ERC721 NFTs, Staking and Earn Contract)

**:** Alchemy for blockchain nodes.
## FAQ

#### Can you give information about ERC20Token supply and mint?

The token supply is unlimited and the mint function only be controlled by the Game's contract.

#### What benefit do nft's features offer?

NFTs are each owned by employees with a title. The salary coefficients of these titles are different in the game. in this way, each NFT provides a different income.

#### What is the game time format?

-This is not valid for now. There is no time limit

 1 hour in real time means 1 day in game. an employee must work for at least one month, that is, 30 days. which is equivalent to 30 hours in real time. you stake one nft, so if you start the employee you cannot unstake for 30 hours.
  
#### How does the contract calculate revenue?

This game is a demo so we have defined a title for each id for convenience. For example, ids like 1-11-21 are CEOs. And the title of CEO has a revenue coefficient. Companies also have a revenue multiplier. In which company the NFT is employed, a salary calculation is made from these values ​​and the owner of the NFT can withdraw it in certain periods.
## References

- [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts) ERC20 and ERC721 contracts.
- [ethers.js](https://docs.ethers.org/v5/)
- [patika.dev](patika.dev)

  
## Licences

[MIT](https://choosealicense.com/licenses/mit/)

  Anyone can use the contracts used in this project as they wish. However, it should be known that this is prepared for an assignment and no responsibility can be accepted for its safety. You assume your own controls and responsibility if commercial development is to be made.