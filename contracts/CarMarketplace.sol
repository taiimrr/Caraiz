pragma solidity ^0.8.0;

contract CarMarketplace {
    struct Car {
        address owner;
        uint256 price;
        CarEvent[] events;
    }
    struct CarEvent {
        string eventType;
        uint256 timestamp;
        string details;
    }
    mapping(uint256 => Car) public cars;
    uint256 public totalCars;
    event CarAdded(uint256 indexed carId, address indexed owner, uint256 price);
    event CarSold(
        uint256 indexed carId,
        address indexed previousOwner,
        address indexed newOwner,
        uint256 price
    );
    event CarEventAdded(
        uint256 indexed carId,
        string eventType,
        uint256 timestamp,
        string details
    );

    constructor() {
        totalCars = 0;
    }
}
