// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./CarNFT.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "hardhat/console.sol";

contract Renting {
    CarNFT cars;
    address vendor;

    struct Contract {
        address customer;
        uint months;
        uint monthlyPayment;
        uint deposit;
        uint mileCap;
        uint yearsOfExp;
        bool exists;
    }

    // carId => contract of the carId
    mapping(uint => Contract) public contracts;

    constructor()
    {
        cars = new CarNFT();
        vendor = msg.sender;
    }

    function getNumberOfCars() public view returns (uint)
    {
        return cars.getNumberOfCars();
    }

    function getCarByIndex(uint idx) public view returns (string memory)
    {
        return cars.getCarByIndex(idx);
    }

    function ownerOf(uint carId) public view returns (bool)
    {
        return contracts[carId].customer == msg.sender;
    }

    function isAvailable(uint carId) public view returns (bool)
    {
        return !contracts[carId].exists;
    }

    function addCar (
        string memory tokenURI,
        string memory brand,
        string memory color,
        string memory matriculation,
        uint originalValue,
        uint mileage) public
    {
        require(msg.sender == vendor, "We must be the vendor");
        cars.addCar(tokenURI, brand, color, matriculation, originalValue, mileage);
    }

    function getMonthlyPayment(uint carId, uint yearsOfExp, uint months, uint mileCap) public view returns (uint)
    {
        return cars.getMonthlyPayment(carId, yearsOfExp, months, mileCap);
    }

    function Rent (uint carId, uint yearsOfExp, uint months, uint mileCap) public payable
    {
        require(cars.exists(carId), "Car does not exists");
        require(isAvailable(carId), "Car not available");
        address buyer = msg.sender;
        uint monthlyPayment=getMonthlyPayment(carId, yearsOfExp, months, mileCap);
        uint firstPayment = cars.getDeposit(carId) + monthlyPayment;
        require(msg.value >= firstPayment, "Not enough either for monthly payment");
        (bool sent, bytes memory data) = payable(vendor).call{value: msg.value}("");
        require(sent, "Failed to send ether");
        contracts[carId] = Contract(buyer, months, monthlyPayment, 1000, mileCap, yearsOfExp, true);
    }

    function Pay (uint carId) public payable
    {
        require(cars.exists(carId), "Car does not exists");
        require(contracts[carId].customer == msg.sender, "Not your car");
        address buyer = msg.sender;
        require(msg.value >= contracts[carId].monthlyPayment, "Not enough either for monthly payment");
        (bool sent, bytes memory data) = payable(vendor).call{value: msg.value}("");
        require(sent, "Failed to send ether");
    }

    function clientTerminate (uint carId) public
    {
        require(ownerOf(carId), "Not yours to terminate");
        delete contracts[carId];
    }

    function vendorTerminate (uint carId) public 
    {
        require(msg.sender == vendor , "Not yours to terminate");
        //require(paymentnotmet)
        //(bool sent, bytes memory data) = payable(ownerOf(carid)).call{value: fromdeposit}("");
        delete contracts[carId];
    }

    function extendYear (uint carId) public
    {
        require(ownerOf(carId),"Not yours to Extend");
        contracts[carId].months += 12;
        contracts[carId].monthlyPayment = getMonthlyPayment(carId, 
                                                            contracts[carId].yearsOfExp,
                                                            contracts[carId].months,
                                                            contracts[carId].mileCap);
    }
}