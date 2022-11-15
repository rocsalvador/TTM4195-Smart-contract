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
        string Brand;
        string Color;
        string Matriculation;
        uint originalvalue;
        uint deposit;
        bool exists;
    }
    struct TXinfo {//renting aggrement between vendor and customer
      uint price;
      uint month;
    }
    mapping(uint => Car) public cars;
    mapping(uint => TXinfo) public txinfos;
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
        string memory Brand,
        string memory Color,
        string memory Matriculation,
        uint originalvalue) public onlyOwner returns (uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        cars[newItemId]=Car(Brand,Color,Matriculation,originalvalue,originalvalue/20,true);
        mintNFT(vendor,tokenURI,newItemId);
        ++nCars;
        return newItemId;
    }

    function getCarByIndex(uint idx) public view returns (string memory){
      return cars[idx].Brand;
    }

    function leasing(uint carid, address customer, uint month, uint monthlypayment) public
    {
        Leased(carid,month);
        _transfer(vendor, customer, carid);
        txinfos[carid].price=monthlypayment;
    }

    function fetchMonthlyPayment(uint carid) public view returns (uint) 
    {
      return txinfos[carid].price;
    }
    function fetchMonthRemain(uint carid) public view returns (uint) 
    {
      return txinfos[carid].month;
    }

    function Leased(uint carid, uint month) public
    {
        txinfos[carid].month=month;
    }

    function Returned(uint id) public
    {
        txinfos[id].month=0;
    }
    
    function Extend(uint id,uint monthlypay) public
    {
        txinfos[id].month=txinfos[id].month+1;
        txinfos[id].price=monthlypay;
    }

    function getDeposit(uint carId) public returns(uint)
    {
      return cars[carId].deposit;
    }

    function getNumberOfCars() public view returns (uint)
    {
      return nCars;
    }
}
