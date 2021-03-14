-- Thomas Devine
-- (My)SQL QUERIES from a website that posted interview questions.

--Write a SQL query to select the 2nd highest salary in the engineering department. If more than one person shares the highest salary, the query should select the next highest salary.
SELECT salary
	FROM employees
JOIN departments
    ON employees.department_id = departments.id
WHERE departments.name = 'engineering'
ORDER BY salary DESC
LIMIT 1 offset 1
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--Let's say we have a table representing vacation bookings.
--How would you make an aggregate table represented below called `listing_bookings` with values grouped by the `listing_id` and columns that represented the total number of bookings in the last 90 days, 365 days, and all time? 
select listing_id, 
sum(
    case when datediff(date_check_in, current_date()) < 90 then 1 
    else 0 end
) as num_bookings_last90d,
sum(
    case when datediff(date_check_in, current_date()) between 91 and 365 then 1
    else 0 end
) as num_bookings_last365d,
count(date_check_in) as num_bookings_total, ds_book
from bookings
group by 1,5
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--Given the employees and departments table, write a query to get the top 3 highest employee salaries by department. If the department contains less that 3 employees, the top 2 or the top 1 highest salaries should be listed (assume that each department has at least 1 employee). 
--The output should include the full name of the employee in one column, the department name, and the salary.
--The output should be sorted by department name in ascending order and salary in descending order. 
select employee_name,name as department_name, salary, rn
    from (
        select e.salary, d.name,
                concat(e.first_name," ", e.last_name) as employee_name,
                dense_rank() over(
                    PARTITION BY name 
                    ORDER BY salary DESC
                ) as rn
            from employees e
        join departments  d
            on d.id=e.department_id
        ) a
where rn<=3
order by name asc, salary desc
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Write a query to create a new table, named flight routes, that displays unique pairs of two locations.
-- Example:
-- Duplicate pairs from the flights table, such as Dallas to Seattle and Seattle to Dallas, should have one entry in the flight routes table.

SELECT DISTINCT leaving_from as destination_one, landing_in as destination_two
FROM
    (SELECT leaving_from, landing_in
        FROM flights 
    UNION ALL
    SELECT landing_in, leaving_from
        FROM flights 
    ) as a
WHERE leaving_from <  landing_in 
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- A dating websites schema is represented by a table of people that like other people. The table has three columns. One column is the user_id, another column is the liker_id which is the user_id of the user doing the liking, and the last column is the date time that the like occured.
-- Write a query to count the number of liker's likers (the users that like the likers) if the liker has one.
select user_id as user, count(*) as count
	from likes 
where user_id in 
    (
    select distinct liker_id
        from likes
    ) group by 1
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~








