    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;

    import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
    import "@openzeppelin/contracts/utils/Counters.sol";
    import "@openzeppelin/contracts/access/Ownable.sol";
    import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
    import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
    contract CarNFT is ERC721URIStorage, Ownable {

    
        using Counters for Counters.Counter;
        Counters.Counter private _tokenIds;
        struct Car {
            string Brand;
            string Color;
            string Matriculation;
            uint Originalvalue;
        }
        struct TXinfo {//renting aggrement between vendor and customer
        uint price;
        uint month;
        uint start;
        uint balance;
        bool available;
        }
        mapping(uint => Car) public cars;
        mapping(uint => TXinfo) public txinfos;
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

        function addCar (
            string memory tokenURI,
            string memory Brand,
            string memory Color,
            string memory Matriculation,
            uint Originalvalue) public onlyOwner returns (uint256)
        {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            cars[newItemId]=Car(Brand,Color,Matriculation,Originalvalue);
            txinfos[newItemId].available=true;
            mintNFT(vendor,tokenURI,newItemId);
            return newItemId;
        }

        
        function ListCars(uint id) public view returns (string memory){
            return cars[id].Brand;
        }

        function getCarBrandByID(uint id) public view returns (string memory){
            return cars[id].Brand;
        }

        function leasingCar(uint id, address customer, uint month, uint monthlypayment) private 
        {
            _transfer(vendor, customer, id);
            txinfos[id].price=monthlypayment;
            txinfos[id].start=block.timestamp;
            txinfos[id].month=month;
            txinfos[id].available=false;
        }

        function returningCar(uint id) private 
        {
            _transfer(ownerOf(id),vendor, id);
            txinfos[id].price=0;
            txinfos[id].start=0;
            txinfos[id].month=0;
            txinfos[id].available=true;
        }

        function paying(uint id, uint monthlypayment) public
        {
            txinfos[id].balance=txinfos[id].balance+monthlypayment;
        }

        function fetchMonthlyPayment(uint id) public view returns (uint) 
        {
        return txinfos[id].price;
        }
        function fetchMonthRemain(uint id) public view returns (uint) 
        {
        return txinfos[id].month;
        }
        
        function Extend(uint id,uint monthlypay) public
        {
            txinfos[id].month=txinfos[id].month+1;
            txinfos[id].price=monthlypay;
        }

        function exists(uint id) public view returns (bool) 
        {
            return id <= _tokenIds.current();
        }

        function available(uint id) public view returns (bool) 
        {
            return txinfos[id].available;
        }

        function getMonthlyPayment( uint id, uint mileage, uint yearofex, uint milecap, uint month) public returns(uint)
        {
            uint weighed_originalvalu=cars[id].Originalvalue/5;//dominate, 5 year rent worth a car
            uint weighed_mileage=mileage/100>1?1:mileage/100;//older car gets cheaper with a limit
            uint weighed_yearofex=yearofex>=5?9:10;//experience driver get discount
            uint weighed_milecap=milecap/10<1?milecap/10:1;//wear and tear with a limit
            uint weighed_month=month>=12?9:10;//rent a year or more get discount
            uint payment= weighed_originalvalu * weighed_yearofex* weighed_month/100+weighed_milecap-weighed_mileage;
            return payment;
        }

        function Rent (uint id, uint originalvalu, uint mileage, uint yearofex, uint milecap, uint month) public payable{
            require(exists(id), "Car does not exists");
            require(available(id), "Car does not available");
            require(milecap<20000,"Mileage cap maximum 1000 miles");
            require(month<60,"Contract duration maximun 60 months");
            address buyer = msg.sender;
            uint monthlypayment=getMonthlyPayment(originalvalu, mileage, yearofex, milecap, month);
            //leasingCar{value:monthlypayment}(id, buyer, month, monthlypayment);
            require(msg.value >= monthlypayment, "Not enough either for monthly payment");
            (bool sent, bytes memory data) = payable(vendor).call{value: msg.value}("");
            require(sent, "Failed to send ether");
            leasingCar(id, buyer, month, monthlypayment);
        }

        function Pay (uint id) public payable{
            require(exists(id), "Car does not exists");
            uint monthlypayment=fetchMonthlyPayment(id);
            require(msg.value >= monthlypayment, "Not enough either for monthly payment");
            (bool sent, bytes memory data) = payable(vendor).call{value: msg.value}("");
            require(sent, "Failed to send ether");
            paying(id, monthlypayment);
        }

        function ExtendYear(uint id) public{
            require(msg.sender == ownerOf(id),"Not yours to Extend");
            uint monthlypayment=fetchMonthlyPayment(id);
            Extend(id,monthlypayment);
        }

        function clientTerminate (uint id) public{
            require(msg.sender == ownerOf(id) , "Only client can terminate here");
            returningCar(id);
        }

        function vendorTerminate (uint id) public{
            require(msg.sender == vendor , "Only vendor can terminate here");
            uint timelaps=block.timestamp-txinfos[id].start;
            require(txinfos[id].balance<timelaps/2592000*txinfos[id].price);//balance not enough to cover payment, vender can terminate
            //(bool sent, bytes memory data) = payable(nft.ownerOf(id)).call{value: fromdeposit}("");
            returningCar(id);
        }

    }
