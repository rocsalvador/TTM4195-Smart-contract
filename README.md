# Smart contract in Solidity

For this assignment, we ask you to write a Solidity smart contract (SC) and an nonfungible token (NFT) for a car leasing system. Here is the scenario.
Mattia wants to drive a new and shiny electric car, but living on a PhD salary, he cannot aﬀord to buy one. He therefore decides to sign a car lease with the famous BilBoyd dealership, leader in both automotive and blockchain markets.

1. (3 points). BilBoyd has several cars available for leasing. Implement each car using an NFT, containing the model, the colour, the year of matriculation and the original value.

2. (1 point). Each NFT comes with (in the sense that it determines) a monthly quotathat depends on
• the original car value;
• the current car mileage;
• the driver’s experience (years of possession of a driving license, which affects the insurance cost);
• a mileage cap (among a set of ﬁxed values);
• the contract duration (among a set of ﬁxed values).
Implement a function to compute this value, which should not cost any gas.

3. (3 points). After evaluating all the options, Mattia chooses one and registers a deal on the blockchain. After BilBoyd has conﬁrmed, this results in the transfer of a down payment (equivalent to 3 monthly quotas) and the ﬁrst monthly quota. Write some functions to implement this phase as a fair exchange (the amount is locked in the SC, and it is unlocked only when BilBoyd signs too).

4. (2 points). This event (it is not required of you to implement events in Solidity for this assignment) also implies an expected monthly payment. Bilboyd must protect itself against insolvent customers. Implement some functionality that guarantees this.

5. At the end of the lease, Mattia has four options:
    1. (1 point) to simply terminate the contract;
    2. (1 point) to extend the lease by one year. In this case, the monthly amount will be recomputed (in his favour, because of the change in the above parameters;
    3. (1 point) to sign a lease for a new vehicle.

