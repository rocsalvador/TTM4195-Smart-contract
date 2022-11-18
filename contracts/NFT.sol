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
        uint month;
        uint start;
        uint balance;
        bool available;
        address customer;
        int status;// 0 waiting for vendor decision; 1 accepted; -1 refutsed
        }

        mapping(address => mapping(uint => uint)) public balanceReceived;
        mapping(address => mapping(uint => uint)) public lockedUntil;
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

        function listDealsWaiting() public view {
            for (uint i = 1; i <= _tokenIds.current(); ++i) {
                if(txinfos[i].status==0 && txinfos[i].available==false){
                    console.log("Id %s:", i);
                    console.log("TXinfo: %s %s %s ", txinfos[i].price, txinfos[i].month, txinfos[i].start);
                } 
            }
        }

        //function getCarBrandByID(uint id) public view returns (string memory){
        //    return cars[id].Brand;
        //}

        function proposeLease(uint id, address customer, uint month, uint monthlypayment) private 
        {
            txinfos[id].price=monthlypayment;
            txinfos[id].start=block.timestamp;
            txinfos[id].month=month;
            txinfos[id].customer=customer;
            txinfos[id].available=false;
            txinfos[id].status=0;
        }

        function leasingCar(uint id) private 
        {
            _transfer(vendor, txinfos[id].customer, id);
            txinfos[id].start=block.timestamp;
            txinfos[id].status=1;
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
            uint weighed_originalvalu=cars[id].Originalvalue/5;//dominate, 5 year rent worth a car 7/5=1
            uint weighed_mileage=mileage/50000>1?1:mileage/50000;//older car gets cheaper with a limit 12345/50000=0
            uint weighed_yearofex=yearofex>=5?9:10;//experience driver get discount 3<5, return 10
            uint weighed_milecap=milecap/10<1?milecap/100:1;//wear and tear with a limit 1234/10=123>1, so 1234/100=10
            uint weighed_month=month>=12?9:10;//rent a year or more get discount 2<12, 10
            uint payment= (weighed_originalvalu * weighed_yearofex* weighed_month/100+weighed_milecap-weighed_mileage)* 10**18;
            console.log("Monthly Payment is %s", weighed_originalvalu);
            console.log("Monthly Payment is %s", weighed_mileage);
            console.log("Monthly Payment is %s", weighed_yearofex);
            console.log("Monthly Payment is %s", weighed_milecap);
            console.log("Monthly Payment is %s", weighed_month);
            console.log("Monthly Payment is %s", payment);
            return 2*10**17; //This is the Wei
        }

        function Rent (uint id, uint mileage, uint yearofex, uint milecap, uint month) public payable{
            require(exists(id), "Car does not exists");
            require(available(id), "Car does not available");
            require(milecap<20000,"Mileage cap maximum 1000 miles");
            require(month<60,"Contract duration maximun 60 months");
            address customer = msg.sender;
            uint monthlypayment=getMonthlyPayment(id, mileage, yearofex, milecap, month);
            //leasingCar{value:monthlypayment}(id, customer, month, monthlypayment);
            require(msg.value >= 4 * monthlypayment, "Not enough either for monthly payment");//3month deposit, 1 month payment
            balanceReceived[customer][id] += msg.value;
            lockedUntil[customer][id] = block.timestamp + 3 days; //if vendor does agree the deal in 3 days, customer can take back the money
            //(bool sent, bytes memory data) = payable(vendor).call{value: msg.value}("");
            //require(sent, "Failed to send ether");
            //leasingCar(id, customer, month, monthlypayment);
            proposeLease(id, customer, month, monthlypayment);//waiting for decision
        }

        function Decision(uint id, bool decision) public onlyOwner {
            require(txinfos[id].status==0&&txinfos[id].available==false,"not waiting for decision");
            if(decision){//accept, take the rent, lease the car.
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
            uint monthlypayment=fetchMonthlyPayment(id);
            require(msg.value >= monthlypayment, "Not enough either for monthly payment");
            (bool sent, bytes memory data) = payable(vendor).call{value: msg.value}("");
            require(sent, "Failed to send ether");
            paying(id, monthlypayment);
        }

        function withdrawMoney(uint id) public { // customer decide to withdraw money before vendor decision
            require(balanceReceived[msg.sender][id]>0);//you are the one who locked the money
            require(block.timestamp>lockedUntil[msg.sender][id]);//after 3 days no response from vendor or vendor refused
            address payable to = payable(msg.sender);
            to.transfer(balanceReceived[msg.sender][id]);
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

