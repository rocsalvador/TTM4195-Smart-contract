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
        bool exists;
    }

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
        uint originalValue) public
    {
        require(msg.sender == vendor, "We must be the vendor");
        cars.addCar(tokenURI, brand, color, matriculation, originalValue);
    }

    function getMonthlyPayment(uint originalvalue, uint mileage, uint yearofex, uint milecap, uint month) public pure returns (uint)
    {
        uint weighed_originalvalue=2*originalvalue;//dominate, 5 year rent worth a car
        uint weighed_mileage=mileage/100>1?1:mileage/100;//older car gets cheaper with a limit
        uint weighed_yearofex=yearofex>=5?90:100;//experience driver get discount
        uint weighed_milecap=10*milecap<1?10*milecap:100;//wear and tear with a limit
        uint weighed_month=month>=12?90:100;//rent a year or more get discount
        uint payment=(weighed_originalvalue*yearofex*month+weighed_milecap-weighed_mileage)/100;
        return payment;
    }

    function Rent (uint carId, uint originalvalu, uint mileage, uint yearofex, uint milecap, uint months) public payable
    {
        require(cars.exists(carId), "Car does not exists");
        require(isAvailable(carId), "Car not available");
        address buyer = msg.sender;
        uint monthlyPayment=getMonthlyPayment(originalvalu, mileage, yearofex, milecap, months);
        uint firstPayment = cars.getDeposit(carId) + monthlyPayment;
        require(msg.value >= firstPayment, "Not enough either for monthly payment");
        (bool sent, bytes memory data) = payable(vendor).call{value: msg.value}("");
        require(sent, "Failed to send ether");
        contracts[carId] = Contract(buyer, months, monthlyPayment, 1000, true);
        return cars.leasing(carId, buyer, months, monthlyPayment);
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
        cars.Returned(carId);
        delete contracts[carId];
    }

    function vendorTerminate (uint carId) public 
    {
        require(msg.sender == vendor , "Not yours to terminate");
        //require(paymentnotmet)
        //(bool sent, bytes memory data) = payable(ownerOf(carid)).call{value: fromdeposit}("");
        cars.Returned(carId);
        delete contracts[carId];
    }

    function ExtendYear(uint carId) public
    {
        require(ownerOf(carId),"Not yours to Extend");
        uint monthlypayment=cars.fetchMonthlyPayment(carId);
        contracts[carId].months += 12;
        cars.Extend(carId, 12);
    }
}
