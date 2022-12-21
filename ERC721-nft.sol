// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/3d7a93876a2e5e1d7fe29b5a0e96e222afdc4cfa/contracts/utils/math/SafeMath.sol";

import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage , ReentrancyGuard  {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    uint256 listingPrice;
    uint royalityPrice;
    uint floorPrice = 0.001 ether;

    enum Royality{FristBuy , SecondBuy , Active}
    mapping(uint256 => Royality) public status;
    mapping(uint256 => uint8) buyCounter;
    mapping(uint256 => MarketItem) private idToMarketItem;

    address payable public owner;

    struct MarketItem {
        uint256 tokenId;
        address payable creator;
        address payable seller;
        address payable owner;
        uint256 price;
        uint8 royalityPercent;
        bool sold;
    }

    event MarketItemCreated(
        uint256 indexed tokenId,
        address creator,
        address seller,
        address owner,
        uint256 price,
        uint royalityPercent,
        bool sold
    );

    constructor() ERC721("NFT Metaverse Tokens", "NMT") {
        owner = payable(msg.sender);
    }

    /* Updates the listing price of the contract */
    function updateListingPrice(uint256 _listingPrice) public payable nonReentrant{
        require(owner == msg.sender,"Only marketplace owner can update listing price.");
        listingPrice = _listingPrice;
    }

    /* Returns the listing price of the contract */
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    /* Mints a token and lists it in the marketplace */
    function createToken(address _creator,string memory tokenURI, uint256 price ,uint8 _royalityPercent)public payable nonReentrant returns (uint256)
    {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        createMarketItem(_creator,newTokenId, price,_royalityPercent);
        return newTokenId;
    }

    function createMarketItem(address _creator, uint256 tokenId, uint256 price ,uint8 _royalityPercent) private  {
        require(price > floorPrice, "Price must be at least 0.001 eth");
        // require(msg.value == listingPrice,"Price must be equal to listing price");

        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(_creator),
            payable(_creator),
            payable(address(this)),
            price,
            _royalityPercent,
            false
        );

        _transfer(msg.sender, address(this), tokenId);
        emit MarketItemCreated(
            tokenId,
            msg.sender,
            msg.sender,
            address(this),
            price,
            _royalityPercent,
            false
        );
    }

    /* allows someone to resell a token they have purchased */
    function resellToken(uint256 tokenId, uint256 price) public payable nonReentrant {
        require(idToMarketItem[tokenId].owner == msg.sender,"Only item owner can perform this operation");
        require(price > floorPrice, "Price must be at least 0.001 eth");
        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].seller = payable(msg.sender);
        idToMarketItem[tokenId].owner = payable(address(this));
        _itemsSold.decrement();

        _transfer(msg.sender, address(this), tokenId);
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function buyMarketItem(uint256 tokenId) public payable nonReentrant{
        uint256 price = idToMarketItem[tokenId].price;
        address creator = idToMarketItem[tokenId].creator;
        address seller = idToMarketItem[tokenId].seller;
        uint royality = idToMarketItem[tokenId].royalityPercent;
        listingPrice = (price.mul(25)).div(1000);
        
        idToMarketItem[tokenId].owner = payable(msg.sender);
        idToMarketItem[tokenId].sold = true;
        idToMarketItem[tokenId].seller = payable(address(0));
        _itemsSold.increment();

        if(buyCounter[tokenId]<=3){buyCounter[tokenId]+=1;}
        setStatus(buyCounter[tokenId] , tokenId);

        _transfer(address(this), msg.sender, tokenId);
        
        if(status[tokenId] == Royality.Active && royality<=100){
            require(msg.value == price,"Please submit the asking price  in order to complete the purchase1");
            royalityPrice = (price.mul(royality)).div(1000);
            console.log(royalityPrice);
            payable(seller).transfer(msg.value-(royalityPrice+listingPrice));
            payable(creator).transfer(royality);
            payable(owner).transfer(listingPrice);
        }else{
            require(msg.value == price,"Please submit the asking price in order to complete the purchase2");
            
            console.log(listingPrice);
            payable(seller).transfer(msg.value-listingPrice);
            payable(owner).transfer(listingPrice);
        }

        
    }

    /* Returns all unsold market items */
    function fetchMarketItems() public view  returns (MarketItem[] memory) {
        uint256 itemCount = _tokenIds.current();
        uint256 unsoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(this)) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /* Returns only items that a user has purchased */
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /* Returns only items a user has listed */
    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function setStatus(uint256 _buyItem , uint256 itemId)private returns(Royality){
        if(_buyItem == 1 ){
            status[itemId] = Royality.FristBuy;
            
        }
        else if(_buyItem == 2){
            status[itemId] = Royality.SecondBuy;
            
        }
        else if(_buyItem > 2){
            status[itemId] = Royality.Active;
            
        }
        return(status[itemId]);
    }
}
