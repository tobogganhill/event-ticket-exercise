pragma solidity ^0.5.0;


// The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.

contract EventTicketsV2 {
	// Define an public owner variable. Set it to the creator of the contract when it is initialized.

	address payable public owner;
	uint256 PRICE_TICKET = 100 wei;

	// Create a variable to keep track of the event ID numbers.
	uint256 public idGenerator;

	// Define an Event struct, similar to the V1 of this contract.
	// The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
	// Choose the appropriate variable type for each field.
	// The "buyers" field should keep track of addresses and how many tickets each buyer purchases.

	struct Event {
		string description;
		string website;
		uint256 totalTickets;
		uint256 sales;
		bool isOpen;
		mapping(address => uint256) buyers;
	}

	// Create a mapping to keep track of the events.
	// The mapping key is an integer, the value is an Event struct.
	// Call the mapping "events".

	mapping(uint256 => Event) events;

	event LogEventAdded(
		string desc,
		string url,
		uint256 ticketsAvailable,
		uint256 eventId
	);
	event LogBuyTickets(address buyer, uint256 eventId, uint256 numTickets);
	event LogGetRefund(
		address accountRefunded,
		uint256 eventId,
		uint256 numTickets
	);
	event LogEndSale(address owner, uint256 balance, uint256 eventId);

	/*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
	modifier onlyOwner() {
		require(msg.sender == owner, 'only owner can call');
		_;
	}

	modifier isOpened(uint256 _eventId) {
		require(events[_eventId].isOpen, 'the event is closed');
		_;
	}

	constructor() public {
		owner = msg.sender;
	}

	/*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
	function addEvent(
		string memory _description,
		string memory _website,
		uint256 _numTickets
	) public onlyOwner returns (uint256 eventId) {
		Event memory newEvent = Event(_description, _website, _numTickets, 0, true);
		eventId = idGenerator++;
		events[eventId] = newEvent;
		emit LogEventAdded(_description, _website, _numTickets, eventId);
	}

	/*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. ticket available
            4. sales
            5. isOpen
    */

	function readEvent(uint256 _eventId)
		public
		view
		returns (
			string memory description,
			string memory url,
			uint256 ticketAvailable,
			uint256 sales,
			bool isOpen
		)
	{
		description = events[_eventId].description;
		url = events[_eventId].website;
		ticketAvailable = events[_eventId].totalTickets;
		sales = events[_eventId].sales;
		isOpen = events[_eventId].isOpen;
	}

	/*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
	function buyTickets(uint256 _eventId, uint256 _numTickets)
		public
		payable
		isOpened(_eventId)
	{
		require(
			_numTickets <= (events[_eventId].totalTickets - events[_eventId].sales),
			'not enough available tickets'
		);
		require(msg.value >= _numTickets * PRICE_TICKET, 'not paid enough');
		events[_eventId].buyers[msg.sender] += _numTickets;
		events[_eventId].sales += _numTickets;
		uint256 refund = msg.value - _numTickets * PRICE_TICKET;
		if (refund > 0) {
			msg.sender.transfer(refund);
		}
		emit LogBuyTickets(msg.sender, _eventId, _numTickets);
	}

	/*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
	function getRefund(uint256 _eventId) public isOpened(_eventId) {
		require(events[_eventId].buyers[msg.sender] > 0);
		uint256 numTickets = events[_eventId].buyers[msg.sender];
		events[_eventId].buyers[msg.sender] = 0;
		events[_eventId].sales -= numTickets;
		uint256 refund = numTickets * PRICE_TICKET;
		msg.sender.transfer(refund);
		emit LogGetRefund(msg.sender, _eventId, numTickets);
	}

	/*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
	function getBuyerNumberTickets(uint256 _eventId)
		public
		view
		returns (uint256)
	{
		return events[_eventId].buyers[msg.sender];
	}

	/*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
	function endSale(uint256 _eventId) public onlyOwner isOpened(_eventId) {
		events[_eventId].isOpen = false;
		uint256 balance = events[_eventId].sales * PRICE_TICKET;
		owner.transfer(balance);
		emit LogEndSale(owner, balance, _eventId);
	}
}
