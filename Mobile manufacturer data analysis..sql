
--1. List all the states in which we have customers who have bought cell phones from 2005 
--   till today. 

SELECT DISTINCT D.State
FROM DIM_LOCATION AS D 
INNER JOIN FACT_TRANSACTIONS AS F
ON  D.IDLocation = F.IDLocation 
WHERE DATEPART(YEAR,Date) >= '2005'


--2. What state in the US is buying the most 'Samsung' cell phones? 
	
select TOP 1 L.State --,M.Manufacturer_Name, SUM(T.QUANTITY) AS QUANTITY
from DIM_MANUFACTURER AS M
join 
DIM_MODEL AS D
on M.IDManufacturer = D.IDManufacturer
JOIN 
FACT_TRANSACTIONS AS T
ON T.IDModel = d.IDModel
JOIN DIM_LOCATION AS L
ON t.IDLocation = L.IDLocation
WHERE M.Manufacturer_Name = 'SAMSUNG' and L.country = 'US'
GROUP BY L.State ,M.Manufacturer_Name
ORDER BY SUM(T.QUANTITY) DESC

--3. Show the number of transactions for each model per zip code per state.     
	
SELECT T.IDModel, L.ZipCode, L.State, COUNT(T.TOTALPRICE) AS TRANSACTIONS 
FROM FACT_TRANSACTIONS AS T
INNER JOIN DIM_LOCATION AS L
ON T.IDLocation = L.IDLocation
GROUP BY T.IDModel, L.ZipCode, L.State
ORDER BY TRANSACTIONS DESC

--4. Show the cheapest cellphone (Output should contain the price also)  

SELECT TOP 1 M.Model_Name AS CELLPHONE, M.Unit_price AS PRICE
FROM DIM_MODEL AS M
JOIN FACT_TRANSACTIONS AS T
ON M.IDModel = T.IDModel
ORDER BY PRICE ASC


--5. Find out the average price for each model in the top 5 manufacturers in terms of sales 
--   quantity and order by average price.

with top5
as
(select top 5 m.IDManufacturer, sum(t.TotalPrice) as sales , 
sum(t.Quantity) as qty 
from FACT_TRANSACTIONS as t
join 
DIM_MODEL as m
on t.IDModel = m.IDModel
group by m.IDManufacturer
order by qty desc
),
avg_price
as 
( select m.IDManufacturer, m.Model_Name, avg(Unit_price) as avg_price
  from DIM_MODEL as m
  join 
  FACT_TRANSACTIONS as t
  on m.IDModel = t.IDModel
  where m.IDManufacturer in ( select IDManufacturer from top5 )
  group by  m.IDManufacturer, m.Model_Name 
  ) 
  select*from avg_price
  order by IDManufacturer


--6. List the names of the customers and the average amount spent in 2009, where the 
--   average is higher than 500

SELECT C.Customer_Name, YEAR(T.Date) AS YEAR, AVG(T.TotalPrice) AVG_SPENT
FROM  FACT_TRANSACTIONS AS T
JOIN DIM_CUSTOMER AS C
ON T.IDCustomer = C.IDCustomer 
WHERE DATEPART(YEAR,DATE) = 2009
GROUP BY  C.Customer_Name,T.IDCustomer, YEAR(T.Date)
HAVING AVG(T.TotalPrice) > 500
ORDER BY AVG_SPENT

	
--7. List if there is any model that was in the top 5 in terms of quantity, simultaneously in 
--   2008, 2009 and 2010  
	
SELECT z.model_name FROM (
	(SELECT TOP 5 M.Model_Name, SUM(T.Quantity) AS QUANTITY FROM FACT_TRANSACTIONS AS T
	INNER JOIN 
	DIM_MODEL AS M
	ON T.IDModel = M.IDModel
	WHERE YEAR(T.Date) = 2008
	GROUP BY M.Model_Name
	ORDER BY SUM(T.Quantity) DESC) AS x
INNER JOIN
	(SELECT TOP 5 M.Model_Name, SUM(T.Quantity) AS QUANTITY FROM FACT_TRANSACTIONS AS T
	INNER JOIN 
	DIM_MODEL AS M
	ON T.IDModel = M.IDModel
	WHERE YEAR(T.Date) = 2009
	GROUP BY M.Model_Name
	ORDER BY SUM(T.Quantity) DESC) AS y
ON x.Model_Name = y.Model_Name)
INNER JOIN
    (SELECT TOP 5 M.Model_Name, SUM(T.Quantity) AS QUANTITY FROM FACT_TRANSACTIONS AS T
    INNER JOIN 
    DIM_MODEL AS M
    ON T.IDModel = M.IDModel
    WHERE YEAR(T.Date) = 2010
    GROUP BY M.Model_Name
    ORDER BY SUM(T.Quantity) DESC) as z
	on y.Model_Name = z.model_name	
	

--8. Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer 
--   with the 2nd top sales in the year of 2010.  

select*from 
    (
     select year(t.Date) as [year], m.IDManufacturer, sum(m.Unit_price) as sales, 
     ROW_NUMBER () over(partition by year(t.Date) order by sum(m.Unit_price) desc) as ranks
     from DIM_MODEL as m
	 join 
	 FACT_TRANSACTIONS as t
	 on m.IDModel = t.IDModel 
	 where year(t.Date) in (2009,2010)
	 group by  year(t.Date), m.IDManufacturer 
	 ) as x 
	 where x.ranks = 2


--9. Show the manufacturers that sold cell phones in 2010 but did not in 2009. 
	
SELECT X.IDManufacturer FROM 
           (SELECT DISTINCT M.IDManufacturer, YEAR(T.DATE) AS YEARS FROM DIM_MODEL AS M
            INNER JOIN 
            FACT_TRANSACTIONS AS T
            ON M.IDModel = T.IDModel
            WHERE YEAR(T.DATE) = 2010 ) AS X
            LEFT JOIN
           (SELECT DISTINCT M.IDManufacturer, YEAR(T.DATE) AS YEARS FROM DIM_MODEL AS M
            INNER JOIN 
            FACT_TRANSACTIONS AS T
            ON M.IDModel = T.IDModel
            WHERE YEAR(T.DATE) = 2009) AS Y
			ON X.IDManufacturer = Y.IDManufacturer
			WHERE Y.YEARS IS NULL


--10. Find the top 100 customers and their average spend, and average quantity by each year. 
--    Also, find the percentage of change in their spending.
	
select x.Date,x.IDCustomer,x.avg_spend,x.avg_qty, x.spend
, lag(avg_spend,1) over(order by [date]) as previous,
(avg_spend - lag(avg_spend,1) over(order by [date]))/lag(avg_spend,1) over(order by [date])*100
as percentage_diffrence
from
    ( 
     select [Date], IDCustomer,
	 avg(TotalPrice) as avg_spend,
	 avg(Quantity) as avg_qty,sum(TotalPrice) as spend,
     ROW_NUMBER() over(partition by year(Date) order by [date]) as ranks 
     from FACT_TRANSACTIONS 
	 where TotalPrice > 0
	 group by Date, IDCustomer 
	 ) as x 
	 where x.ranks <= 10 ;

	