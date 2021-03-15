--FOLLOWING EXAMPLES FROM SQL COOKBOOK BY ANTHONY MOLINARO FROM LIBGEN.IS PIRATING
--- ....................
-- Note, a lot of the commands here aren't in alignment with the book I'm following because I didn't use their database, I figured 
-- that, for better or for worse, it'd be a better learning experience. 
-- Further, I'll be adding some other SQL stuff.
--DATABASE IS FROM CHINOOK.DB, DISCOVERED BY REFERENCE https://www.reddit.com/r/learnSQL/comments/aqw4sy/sqlite_for_learning_practicing_databasessql_at/
--next we cover how to use order by *---------------------------------------------------------------------
Select InvoiceId, Total
from
	invoices
where Total > 9;

--1.2 next we cover how to use WHERE and ORDER BY, SUBSETTING *---------------------------------------------------------------------
 Select*
from
	invoices
where
	Total > 8
ORDER BY
	Total;

--1.3Finding Rows That Satisfy Multiple Conditions
	-- issues with date
 Select*
from
	invoices
where
	(CustomerId != 40
	or Total > 3 and Total < 4);

--1.4 subset of table with specific cols.................
 Select
	BillingCountry,
	Total,
	CustomerId,
	InvoiceId,
	InvoiceDate
from
	invoices;
--1.5 Providing Meaningful Names for Columns
--we add a column just for the date, and rename a column to make it clear what it precisely contains (date and time)
	--we can simply alias the variables
 select
	InvoiceDate as InvoiceDateTime,
	Total,
	CustomerId,
	InvoiceId
from
	invoices;
	--Alter invoices rename InvoiceDate to InvoiceDateTime

--1.6 Referencing an Aliased Column in the WHERE Clause
select*
from
 (select
	InvoiceDate as date_time,
	Total,
	CustomerId,
	InvoiceId
  from
	invoices )
	where date_time BETWEEN '2010-01-01' and '2011-05-06';
	--where Total between 6 and 25	

--1.7 Concatenating Column Values
	--not null changes the NULL value to zero, which could be called an unreported department or useful for filling in
 select
	(FirstName || ' works in ' || City), ReportsTo not null, Country    
--	(FirstName || ' works in ' || City), ReportsTo, Country    
from
	employees;

--1.8 Using Conditional Logic in a SELECT Statement
--if an item is underpriced or okay (otherwise ok)
 select UnitPrice, InvoiceId,
	CASE when UnitPrice <= 1 then 'underpriced'
		 when UnitPrice >= 2 then 'overpriced'
		 else 'ok'
	end as status
from invoice_items;

--1.9 limit number of rows returned
select* from genres e2 limit 10

--1.1.10 Returning n Random Records from a Table
select * 
from employees 
order by random() limit 5;

--1.11 Finding Null Values
select * --here we get non americans, essentially
from customers c2 
where state is null

--1.12 Transforming Nulls into Real Values
 select
	COALESCE(state,	'foreign')
from
	customers c2
	
--1.13 Searching for Patterns
	--sales leads the title
	select * 
	from employees
	where ReportsTo in (1,2)
		and (Title like 'Sales%')
	
	--another
	select * 
	from employees
	where ReportsTo in (1,6)
		and Title like '%Man%';
	--like above
	select * 
	from employees
	where ReportsTo in (1,6)
		and Title like '%Man%' or '%Sales%';
-------------------------------------------------------------------------------------------------------------------------------------
--2.1 Returning Query Results in a Specified Order
	--order by hire date
	select FirstName, HireDate, ReportsTo 
		from employees e2 
	where ReportsTo = 6
	order by HireDate ASC;

--2.2 Sorting by Multiple Fields 
	--i add in dropping null
	select FirstName, HireDate, ReportsTo 
		from employees e2 
	where ReportsTo  not null
	order by ReportsTo , HireDate desc
	
-- 2.3 Sorting by Substrings
	--by last two chars in substring
	select * 
	from genres g2
	order by SUBSTRING(Name , length(Name-1),2) ;
	
--2.4 Sorting Mixed Alphanumeric Data
	--create temp table
	--no null values for company
	CREATE view CustHelpedBy1 as 
			select Company || ' ' || SupportRepId as data 
			from  customers
			where Company is not null and SupportRepId is not null;
		-- max string length is 60, smallest 17: select length(data) from CustHelpedBy
	--below takes advantage of the smaller format, not ideal
	 select data
	 from CustHelpedBy1
	 order by substr(data,length(data)-1);     --		select patindex('%[0-9]%', 'ab12');
	
--2.5 Dealing with Nulls When Sorting
 select *
 from customers
 order by Company ASC nulls last -- State ASC nulls last, 
 
--2.6 Sorting on a Data-Dependent Key
select	*
from customers c
order by
case
	when Company not null then Country
	else FirstName
end
-------------------------------------------------------------------------------------------------------------------------------------
--3.1 Stacking One Rowset atop Another

--select CustomerId as buyerId, 
--from invoices
----	where InvoiceId = 1
--union all
--select '----------', null
--	from t1
--union all
--select InvoiceId 
--	from invoices

--3.2 Combining Related Rows
-- using dbeaver sample databases in that script


--Select InvoiceId, Total, InvoiceDate
Select i2.InvoiceDate
from invoices i2
order by i2.InvoiceDate asc
limit length(i2.InvoiceDate ) 	
		
		
		
