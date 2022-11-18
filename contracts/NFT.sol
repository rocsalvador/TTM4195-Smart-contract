    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;

    import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
    import "@openzeppelin/contracts/utils/Counters.sol";
    import "@openzeppelin/contracts/access/Ownable.sol";
    import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
    import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
    import "hardhat/console.sol";

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
        uint totalMonth;
        uint start;
        uint balance;
        bool available;//available for renting
        address customer;
        uint status;// 0 uninitialized; 1 waiting for vendor decision, 2 accepted; 3 refused
        }

        mapping(address => mapping(uint => uint)) private balanceReceived;
        mapping(uint => Car) private cars;
        mapping(uint => TXinfo) private txinfos;
        address vendor;
        constructor() ERC721("MyNFT", "NFT") {
        vendor=msg.sender;
        }

        function mintNFT(address recipient, string memory tokenURI, uint256 newItemId)
            private onlyOwner
        {
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

        
        function listCars() public view {
            for (uint i = 1; i <= _tokenIds.current(); ++i) {
                console.log("Id %s:", i);
                console.log("Model: %s %s %s ", cars[i].Brand, cars[i].Color, cars[i].Matriculation);
                console.log("Price: %s", cars[i].Originalvalue);
                if(available(i)){
                    console.log("Available");
                }
                else {
                    console.log("Not Available");
                }
            }
        }

        function listDealsWaiting() public onlyOwner view {
            for (uint i = 1; i <= _tokenIds.current(); ++i) {
                if(txinfos[i].status==1){
                    console.log("Id %s:", i);
                    console.log("TXinfo: %s %s %s ", txinfos[i].price, txinfos[i].totalMonth, txinfos[i].customer);
                } 
            }
        }

        function proposeLease(uint id, address customer, uint month, uint monthlypayment) private 
        {
            txinfos[id].price=monthlypayment;
            txinfos[id].start=block.timestamp;
            txinfos[id].totalMonth=month;
            txinfos[id].customer=customer;
            txinfos[id].available=false;
            txinfos[id].status=1;
        }

        function leasingCar(uint id) private 
        {
            _transfer(vendor, txinfos[id].customer, id);
            txinfos[id].start=block.timestamp;
            txinfos[id].status=2;
        }

        function returningCar(uint id) private 
        {
            _transfer(ownerOf(id),vendor, id);//NFT
            txinfos[id].price=0;
            txinfos[id].start=0;
            txinfos[id].totalMonth=0;
            txinfos[id].status=0;
            txinfos[id].available=true;
        }

        function fetchMonthlyPayment(uint id) private view returns (uint) 
        {
            return txinfos[id].price;
        }
        
        function exists(uint id) private view returns (bool) 
        {
            return id <= _tokenIds.current();
        }

        function available(uint id) private view returns (bool) 
        {
            return txinfos[id].available;
        }

        function getMonthlyPayment( uint id, uint mileage, uint yearofex, uint milecap, uint month) public view returns(uint)
        {
            uint weighted_originalvalue=cars[id].Originalvalue*10**18/100;// 1% of the original value is the baseline
            uint weighted_mileage=3*weighted_originalvalue*mileage/100/100000;//older car gets cheaper
            uint weighted_yearofex=yearofex>=7?weighted_originalvalue/10:0;//experience driver get discount
            uint weighted_milecap=weighted_originalvalue/10*milecap/5000;//wear and tear
            uint weighted_month=5*weighted_originalvalue*(month/12)/100;//rent longer duration is cheaper
            uint payment=weighted_originalvalue-weighted_yearofex-weighted_month+weighted_milecap-weighted_mileage;
            return payment;
        }

        function Rent (uint id, uint mileage, uint yearofex, uint milecap, uint month) public payable{
            require(exists(id), "Car does not exists");
            require(available(id), "Car does not available");
            require(milecap<500000,"Mileage cap maximum 500000 miles");
            require(month<60,"Contract duration maximun 60 months");
            address customer = msg.sender;
            uint monthlypayment=getMonthlyPayment(id, mileage, yearofex, milecap, month);
            require(msg.value >= 4 * monthlypayment, "Not enough either for monthly payment");//3month deposit, 1 month payment
            balanceReceived[customer][id] += msg.value;
            proposeLease(id, customer, month, monthlypayment);//waiting for vendor decision
        }

        function Decision(uint id, bool decision) public onlyOwner {
            require(txinfos[id].status==1,"not waiting for decision");
            if(decision){//accept the deal, take the first month payment rent, lease the car.
                payable(vendor).transfer(txinfos[id].price);
                leasingCar(id); 
                txinfos[id].balance+=txinfos[id].price;//add one month rent to balance
                balanceReceived[txinfos[id].customer][id]-=txinfos[id].price;//remaining is deposit 
            }
            else{//return deposit and first month rent, Vendor pays gas if refuse, fair exchange 
                payable(txinfos[id].customer).transfer(balanceReceived[txinfos[id].customer][id]);
                txinfos[id].available=true;
            }
        }

        function Pay (uint id) public payable{
            require(exists(id), "Car does not exists");
            require(!available(id), "Car does not rented");
            uint monthlypayment=fetchMonthlyPayment(id);
            require(msg.value >= monthlypayment, "Not enough either for monthly payment");
            (bool sent,) = payable(vendor).call{value: msg.value}("");
            require(sent, "Failed to send ether");
            txinfos[id].balance+=msg.value;
        }

        function withdraw(uint id) public { // customer decide to withdraw money before vendor decision
            require(balanceReceived[msg.sender][id]>0,"You have no locked fund");//you are the one who locked the money
            require(txinfos[id].status==1,"Can only withdraw before vender decision");
            address payable to = payable(msg.sender);
            to.transfer(balanceReceived[msg.sender][id]);
            txinfos[id].available=true;
        }

        function recomputePrice(uint id) private {
            txinfos[id].price -= cars[id].Originalvalue*10**18/2000;
        }

        function ExtendYear(uint id) public {
            require(msg.sender == ownerOf(id),"Not yours to Extend");
            txinfos[id].totalMonth += 12;
            recomputePrice(id);
        }

        function clientTerminate (uint id) public{//client terminate before deal complete lose deposit
            require(msg.sender == ownerOf(id) , "Only client can terminate here");
            uint monthPassed=(block.timestamp-txinfos[id].start)/2592000;//30-day month
            bool dealcompeleted=monthPassed>=txinfos[id].totalMonth;
            console.log("passed %s",monthPassed);
            console.log("passed %s",txinfos[id].totalMonth);
            if(dealcompeleted){
                payable(msg.sender).transfer(balanceReceived[msg.sender][id]);
            }
            returningCar(id);
        }

        function vendorTerminate (uint id) public{//vendor terminate only when payment are not met
            require(msg.sender == vendor , "Only vendor can terminate here");
            uint monthPassed=(block.timestamp-txinfos[id].start)/2592000;
            require(txinfos[id].balance<monthPassed*txinfos[id].price,"Can only terminate if payment not enough");//balance not enough to cover payment
            returningCar(id);
        }
    }

