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
    event CarAdded(
        uint256 indexed carId,
        address indexed owner,
        uint256 price,
        uint256 timestamp
    );
    event CarSold(
        uint256 indexed carId,
        address indexed previousOwner,
        address indexed newOwner,
        uint256 price,
        uint256 timestamp
    );
    event CarEventAdded(
        uint256 indexed carId,
        string eventType,
        uint256 timestamp,
        string details
    );
    modifier onlyCarOwner(uint256 carId) {
        require(
            cars[carId].owner == msg.sender,
            "You are not the owner of this car"
        );
        _;
    }

    constructor() {
        totalCars = 0;
    }

    function addCar(uint256 price) external {
        totalCars++;
        cars[totalCars] = Car(msg.sender, price, new CarEvent[](0));
        emit CarAdded(totalCars, msg.sender, price, block.timestamp);
    }

    function sellCar(
        uint256 carId,
        address newOwner
    ) external onlyCarOwner(carId) {
        require(newOwner != address(0), "Invalid address");
        address previousOwner = cars[carId].owner;
        uint256 price = cars[carId].price;
        cars[carId].owner = newOwner;
        emit CarSold(carId, previousOwner, newOwner, price, block.timestamp);
    }

    function addCarEvent(
        uint256 carId,
        string memory eventType,
        string memory details
    ) external onlyCarOwner(carId) {
        cars[carId].events.push(CarEvent(eventType, block.timestamp, details));
        emit CarEventAdded(carId, eventType, block.timestamp, details);
    }

    function getCarEvents(
        uint256 carId
    ) external view returns (CarEvent[] memory) {
        return cars[carId].events;
    }
}
