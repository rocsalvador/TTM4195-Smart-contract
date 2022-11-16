// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract CarNFT is ERC721URIStorage, Ownable {

  
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    struct Car {
        string brand;
        string color;
        string matriculation;
        uint originalValue;
        uint deposit;
        uint mileage;
        bool exists;
    }
    mapping(uint => Car) public cars;
    uint nCars = 0;
    address vendor;

    constructor() ERC721("MyNFT", "NFT") {
      vendor=msg.sender;
    }

    function mintNFT(address recipient, string memory tokenURI, uint256 newItemId)
        private onlyOwner
    {
        //_tokenIds.increment();
        //uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);
    }

    function exists(uint carId) public returns (bool) 
    {
        return cars[carId].exists;
    }

    function addCar (
        string memory tokenURI,
        string memory brand,
        string memory color,
        string memory matriculation,
        uint originalValue,
        uint mileage) public onlyOwner returns (uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        cars[newItemId]=Car(brand,color,matriculation,originalValue,originalValue/20,mileage,true);
        mintNFT(vendor,tokenURI,newItemId);
        ++nCars;
        return newItemId;
    }

    function getCarByIndex(uint idx) public view returns (string memory){
        return cars[idx].brand;
    }

    function getDeposit(uint carId) public returns(uint)
    {
        return cars[carId].deposit;
    }

    function getNumberOfCars() public view returns (uint)
    {
        return nCars;
    }

    function getMonthlyPayment(uint carId, uint yearsofexp, uint months, uint mileCap) public view returns (uint) {
        uint weighed_originalvalue=2*cars[carId].originalValue;//dominate, 5 year rent worth a car
        uint weighed_mileage=cars[carId].mileage/100>1?1:cars[carId].mileage/100;//older car gets cheaper with a limit
        uint weighed_yearofexp=yearsofexp>=5?90:100;//experience driver get discount
        uint weighed_milecap=10*mileCap<1?10*mileCap:100;//wear and tear with a limit
        uint weighed_month=months>=12?90:100;//rent a year or more get discount
        uint payment=(weighed_originalvalue*yearsofexp*months+weighed_milecap-weighed_mileage)/100;
        return payment;
    }
}
