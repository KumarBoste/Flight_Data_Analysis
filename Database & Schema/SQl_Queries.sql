-- Q1. Find the bussines airport by the number of flights take off:
SELECT A.Name AS Airport,
	COUNT(*) AS TotalFlights
FROM Flights F 
INNER JOIN Airports A ON A.AirportID = F.Origin
GROUP BY A.Name
ORDER BY TotalFlights DESC;

-------------------------------------------------------------------------------------------------

-- Q2. Find the total number of tickets sold per airline.
SELECT AL.Name,
	COUNT(*) AS TicketsSold
FROM Tickets T
INNER JOIN Flights F ON  T.FlightID = F.FlightID
INNER JOIN Airlines AL ON F.AirlineID = AL.AirlineID
GROUP BY AL.Name;

-------------------------------------------------------------------------------------------------

-- Q3. List all flights operated by 'Indigo' with airport names (origin and destination).
SELECT F.FlightID, A.Name AS OriginAirport, A2.Name AS DestinationAirport, F.DepartureTime, F.ArrivalTime 
FROM  Flights F 
INNER JOIN Airlines AL ON F.AirlineID = AL.AirlineID
INNER JOIN Airports A ON F.Origin = A.AirportID
INNER JOIN Airports A2 ON F.Destination = A2.AirportID
WHERE AL.Name ='IndiGo';

---------------------------------------------------------------------------------------------

-- Q4. For each airport, show the top airlines by number of flights departing from there.
WITH FlightCounts AS(
SELECT F.Origin, F.AirlineID, COUNT(*) AS FlightCount
FROM Flights F
GROUP BY F.Origin, F.AirlineID
),
RANKEDAirlines AS (
	SELECT *,
		ROW_NUMBER() OVER (PARTITION BY Origin ORDER BY FlightCount DESC) AS rn
	FROM FlightCounts
)
SELECT A.Name AS AirportName,
	   AL.Name AS AirlineName,
       R.FlightCount
FROM RANKEDAirlines R
INNER JOIN Airports A ON R.Origin = A.AirportID
INNER JOIN AIrlines AL ON R.AirlineId = AL.AirlineID
WHERE rn = 1;

------------------------------------------------------------------------------------------------------------

-- Q5. For each flight, show time in hours and categorize it as Short (<2h), Medium (2-5h), or Long (>5h)
SELECT 
    FlightID,
    DepartureTime,
    ArrivalTime,
    TIMESTAMPDIFF(MINUTE, DepartureTime, ArrivalTime) / 60.0 AS DurationHours,
    CASE
        WHEN TIMESTAMPDIFF(MINUTE, DepartureTime, ArrivalTime) < 120 THEN 'Short'
        WHEN TIMESTAMPDIFF(MINUTE, DepartureTime, ArrivalTime) <= 300 THEN 'Medium'
        ELSE 'Long'
    END AS FlightCategory
FROM Flights;

---------------------------------------------------------------------------------------

-- Q6. Show each passenger's first and last flight dates and number of flights
WITH RankedTickets AS (
SELECT 
	PassengerID,
    MIN(F.DepartureTime) AS FirstFlight,
    MAX(F.DepartureTime) AS LastFlight,
    COUNT(*) AS TotalFlights
FROM Tickets T
INNER JOIN FLights F ON T.FlightID = F.FlightID
GROUP BY PassengerID
)
SELECT
	P.Name,
    R.FirstFlight,
    R.LastFlight,
    R.TotalFlights
FROM RankedTickets R 
INNER JOIN Passengers P ON R.PassengerID = P.PassengerID

-----------------------------------------------------------------------------------------------
  
-- Q7. Find Flights with the highest price tickets sold for each route (Origin -> Destination)
WITH RouteTickets AS (
SELECT F.FlightID,
	    F.Origin,
		F.Destination,
        T.TicketID,
        T.Price,
        RANK() OVER (PARTITION BY F.Origin, F.Destination ORDER BY T.Price DESC) AS rnk
FROM Tickets T
INNER JOIN Flights F ON T.FlightID = F.FlightID 
)
SELECT 
	A1.Name AS Origin,
    A2.Name AS Destination,
    RT.Price,
    Rt.TicketID
FROM RouteTickets RT
INNER JOIN Airports A1 ON RT.Origin = A1.AirportID
INNER JOIN Airports A2 ON RT.Destination = A2.AirportID
WHERE rnk = 1

-------------------------------------------------------------------------------------------------------
  
-- Q8. Find the highest-spending passenger in each Frequent Flyer Status group
WITH SpendingByPassenger AS ( 
SELECT 
	P.PassengerID,
    P.Name,
    P.FrequentFlyerStatus,
    SUM(T.Price) AS TotalSpent
FROM Passengers P
INNER JOIN Tickets T ON P.PassengerID = T.PassengerID
GROUP BY P.PassengerID, P.Name, P.FrequentFlyerStatus    
),
RankedSpending AS (
	SELECT *,
		RANK() OVER (PARTITION BY FrequentFlyerStatus ORDER BY TotalSpent DESC) AS rn
	FROM SpendingByPassenger
)
SELECT
	Name,
    FrequentFlyerStatus,
    TotalSpent
FROM RankedSpending
WHERE rn = 1
