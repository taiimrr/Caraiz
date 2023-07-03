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

    function addCar(uint256 price, string memory history) external {
        totalCars++;
        cars[totalCars] = Car(
            msg.sender,
            price,
            block.timestamp,
            history,
            new CarEvent[](0)
        );
        emit CarAdded(totalCars, msg.sender, price);
    }

    function sellCar(
        uint256 carId,
        address newOwner
    ) external onlyCarOwner(carId) {
        require(newOwner != address(0), "Invalid address");
        address previousOwner = cars[carId].owner;
        uint256 price = cars[carId].price;
        cars[carId].owner = newOwner;
        cars[carId].timestamp = block.timestamp;
        emit CarSold(carId, previousOwner, newOwner, price);
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
