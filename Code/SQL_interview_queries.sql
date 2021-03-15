-- Thomas Devine
-- (My)SQL QUERIES from a website that posted interview questions.
-- /////////////////////////////////////////////////////////////////////////
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Over budget on a project is defined when the salaries, prorated to the day, exceed the budget of the project.
-- For example, if Alice and Bob both combined income make 200K and work on a project of a budget of 50K that takes half a year, then the project is over budget given 0.5 * 200K = 100K > 50K.
-- Write a query to select all projects that are over budget. Assume that employees only work on one project at a time.
select title,project_forecast 
from(select title, budget, datediff(end_date,start_date)/365 *sum(salary) as project_forecast
      from employees e
join employees_projects ep
    on e.id =ep.employee_id
join projects p
    on ep.project_id = p.id
group by 1,2
) s1
where project_forecast>budget
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- We're given three tables representing a forum of users and their comments on posts.
-- Write a query to get the top ten users that got the most upvotes on their comments written in 2020. 
-- Note: Do not count deleted comments and upvotes by users on their own comments.
	-- MY NOTES:
		-- 3 tables (users,comments,comment_votes), users and comments have a column "id", respectively for user_id and comment_id
	    -- 2 joins for users to comments and comments to comment_votes (only comments in 2020, votes from 2021 don't matter)
	        -- join on users.id=comments.user_id
	        -- join on comments.id = comment_votes.comment_id
	            -- this data should have post_id and counts of votes on ACTIVE posts
	        -- can filter year, is_deleted, c.user_id != cv.user_id, and vote positive (unecessary control but it's ok)
select u.id, u.username, count(cv.id) as upvotes
from users u
left join comments c
	on u.id = c.user_id
left join comment_votes cv
	on c.id = cv.comment_id
where c.is_deleted = 0          -- exclude deleted comments
    and year(c.created_at)=2020 -- only comments created in 2020 (would be a bit more fun to get upvotes only from 2020)
    and cv.user_id != c.user_id -- no self-votes
group by 1						-- grouping by the comment-maker 
order by 3						-- ordering by most votes
limit 10
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- The events table tracks every time a user performs a certain action (like, post_enter, etc.) on a platform (android, web, etc.).
-- Write a query to determine the top 5 actions performed during the month of November 2020, for actions performed on an Apple platform (iphone, ipad).
-- The output should include the action performed and their rank in ascending order. If two actions performed equally, they should have the same rank. 
select action, rank() over(order by cnt desc) ranks
    from(select action, count(distinct id) cnt,
            case
                when substr(platform,1,2) = "ip" then 1
                else 0
            end apple
            from events 
        where created_at between "2020-11-1" and "2020-11-30" 
        group by action, apple
    ) b
where apple=1
limit 5
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- We're given a table of bank transactions with three columns, user_id, a deposit or withdrawal value (determined if the value is positive or negative), and created_at time for each transaction.
-- Write a query to get the total three day rolling average for deposits by day.

SELECT distinct date(a.created_at) as dt,
    --   a.transaction_value,
      Round( ( SELECT SUM(b.transaction_value) / COUNT(b.transaction_value)
                FROM bank_transactions AS b
                WHERE DATEDIFF(date(a.created_at), date(b.created_at)) BETWEEN 0 AND 2
                and a.transaction_value>0 OR b.transaction_value>0
              ), 2 ) AS 'rolling_three_day'
     FROM bank_transactions AS a
     ORDER BY dt asc
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
    from (select e.salary, d.name, concat(e.first_name," ", e.last_name) as employee_name,
                dense_rank() over( PARTITION BY name ORDER BY salary DESC) as rn
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
FROM(SELECT leaving_from, landing_in
    	FROM flights 
    UNION ALL
    SELECT landing_in, leaving_from
    	FROM flights 
    ) as a
WHERE leaving_from <  landing_in 
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- We're given two tables, one that represents SMS sends to phone numbers and the other represents confirmations from SMS sends. 
	-- #1
	 SELECT carrier, country, COUNT(DISTINCT phone_number)
	 FROM sms_sends WHERE type = 'confirmation'
	 	AND ds = DATE_SUB(CURDATE(), 1) 
	 GROUP BY carrier, country;
	--#2 
	SELECT date(date),round(100*COUNT(DISTINCT c.phone_number)/COUNT(DISTINCT s.phone_number),2)
	FROM sms_sends s 
	LEFT JOIN confirmers c 
		ON s.phone_number = c.phone_number 
		AND c.date = s.ds
	WHERE type = 'confirmation' GROUP BY date;
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--Write a SQL query to select the 2nd highest salary in the engineering department. If more than one person shares the highest salary, the query should select the next highest salary.
SELECT salary
	FROM employees
JOIN departments
    ON employees.department_id = departments.id
WHERE departments.name = 'engineering'
ORDER BY salary DESC
LIMIT 1 offset 1
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Write a query to identify the names of users who placed less than 3 orders or ordered less than $500 worth of product.
    -- MY NOTES: 3 tables, transactions, users, products, w/ ea. having id for respective [tablename]_id type
select distinct y.name as users_less_than
from(select x.id, x.name, x.quantity, x.tbill
	from(select t.id, t.user_id, u.name, t.quantity, p.price*t.quantity as tbill
	 from transactions t 
	    left join users u 
		on u.id = t.user_id
	    left join products p
		on p.id = t.product_id) x
	group by x.id
	having (x.tbill<500 or x.quantity<=2)
) y
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Given three tables: user_dimension, account_dimension, and download_facts, find the average number of downloads for free vs paying customers broken out by day.
-- Note: The account_dimension table maps users to multiple accounts where they could be a paying customer or not. Also, round average_downloads to 2 decimal places.
select DATE_FORMAT(date, '%Y-%m-%d') date, u.paying_customer ,
        avg(df.downloads) average_downloads
from (
    select user_id, 
        case 
            when sum(ad.paying_customer)>0 then 1
            else 0
        end paying_customer
        from user_dimension ud
    join account_dimension ad
    on ad.account_id = ud.account_id
    group by user_id
) u
join download_facts df
on df.user_id = u.user_id
group by paying_customer, date 
order by 1 asc, 2 asc
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- We're given a table bank transactions with two columns, transaction_value representing deposit or withdrawal value determined if the value is positive or negative, and created_at representing date and time for each transaction.
-- Write a query to get the last transaction for each day.
-- The output should include the datetime of the transaction and the transaction amount ordered by datetime in ascending order. 
select t.created_at, t.transaction_value
from(SELECT t1.*,
    row_number() over(partition by date(created_at) order by created_at desc) rn
FROM bank_transactions  t1) t
where t.rn=1
order by created_at asc
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Write a query to identify customers who placed more than three transactions each in both 2019 and 2020.
SELECT 
temp.name AS customer_name
FROM (
    SELECT name,
        SUM(CASE WHEN YEAR(t.created_at)= '2019' THEN 1 ELSE 0 END) AS t_2019,
        SUM(CASE WHEN YEAR(t.created_at)= '2020' THEN 1 ELSE 0 END) AS t_2020
    FROM transactions t
    JOIN users u
        ON u.id = user_id
    GROUP BY 1
    HAVING t_2019 > 3 AND t_2020 > 3
) temp
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Write a SQL query to create a histogram of number of comments per user in the month of January 2020. Assume bin buckets class intervals of one.
with h as (
    select u.id, COUNT(c.user_id) AS comments_count  
        from comments c
    right join users u
        on u.id=c.user_id and c.created_at between "2020-01-01" and "2020-01-31"
    group by u.id
)
select comments_count, count(*) AS frequency 
    from h
group by comments_count 
order by comments_count asc
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- An ads table holds an ID and the advertisement name like "Labor day shirts sale". The feed_comments table holds the comments on ads by different users that occurs in the regular feed. The moments_comments table holds the comments on ads by different users in the moments section.
-- Write a query to get the percentage of comments, by ad, that occurs in the feed versus mentions sections of the app.
SELECT a.name,
100*SUM(CASE
            WHEN f.comment_id IS NULL THEN 0
            ELSE 1
        end )/(
            SUM(CASE WHEN f.comment_id IS NULL THEN 0 ELSE 1 end) +
            SUM(CASE WHEN m.comment_id IS NULL THEN 0 ELSE 1 end)) AS "% feed", 
100*SUM(CASE
            WHEN f.comment_id IS NULL THEN 0
            ELSE 1 
        end )/(
    SUM(CASE 
            WHEN f.comment_id IS NULL THEN 0 
            ELSE 1 
        end) +  
    SUM(CASE WHEN m.comment_id IS NULL THEN 0 ELSE 1 end )) AS "% mentions"
FROM ads AS a
JOIN feed_comments AS f ON a.id = f.ad_id
JOIN moments_comments AS m ON a.id = m.ad_id
GROUP BY a.name, a.id
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- The schema above represents advertiser campaigns and impressions. The campaigns table specifically has a goal, which is the number that the advertiser wants to reach in total impressions. 
-- 1. Given the table above, generate a daily report that tells us how each campaign delivered during the previous 7 days.
-- 2. Using this data, how do we evaluate how each campaign is delivering and by what heuristic do we surface promos that need attention?
-- #1
select campaign_id, count(impression_id) 
from ad_impressions
where dt between (select date(max(date(dt))-7) as sevd from ad_impressions) 
        and (select date(max(date(dt))-1) as ystd from ad_impressions)
group by campaign_id
order by campaign_id
-- #2
with final as(
select c.id,goal,total_impr_b4last7, count(impression_id) total_impr_last7,count(impression_id)/7 as impr_day_last7, 
	   count(impression_id)/datediff((select date(max(date(dt))-7) from ad_impressions ),c.sd) as impr_day_b4Last7
from ad_impressions a
join(select t.id, count(i.impression_id) total_impr_b4last7,
           t.goal, t.end_dt as ed, t.start_dt as sd
           from campaigns t
     join ad_impressions i
     on i.campaign_id=t.id
     group by campaign_id
    ) c
on c.id=a.campaign_id
where dt between (select date(max(date(dt))-7) from ad_impressions) 
        and (select date(max(date(dt))-1) from ad_impressions)
group by c.id 
order by c.id asc
)
select id,goal,total_impr_b4last7 as tot_imp_b4Last7, total_impr_last7 as tot_imp_last7, 
    impr_day_last7 as cnt_imp_last7, impr_day_b4Last7 as cnt_imp_b4Last7,
    100*(impr_day_last7-impr_day_b4Last7)/impr_day_b4Last7 as percRateChange
from final 
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Given the table of account statuses, compute the percentage of accounts that were closed on January 1st, 2020 (over the total number of accounts). Each account can have only one record at the daily level indicating the status at the end of the day.
select 
    sum(case when status = "closed" then 1 else 0 end)/count(account_id) as percentage_closed
from account_status where date="2020-01-01"
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- A dating websites schema is represented by a table of people that like other people. The table has three columns. One column is the user_id, another column is the liker_id which is the user_id of the user doing the liking, and the last column is the date time that the like occured.
-- Write a query to count the number of liker's likers (the users that like the likers) if the liker has one.
select user_id as user, count(*) as count
	from likes 
where user_id in 
    (select distinct liker_id
     	from likes
    ) group by 1
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Given a table of user logs with platform information, count the number of daily active users on each platform for the year of 2020.
select  platform, created_at, count(distinct user_id) as daily_users
    from events
where year(created_at)="2020"
group by platform
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- We're given two tables. `friend_requests`holds all the friend requests made and `friend_accepts` is all of acceptances.
-- Write a query to find the overall acceptance rate of friend requests.
select sum(case when acceptor_id=requested_id then 1 else 0 end)/
       count(fr.requester_id) acceptance_rate
from friend_requests fr
left join friend_accepts fa
    on ( fa.requester_id = fr.requester_id)
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- The events table that tracks every time a user performs a certain action (like, post_enter, etc.) on a platform.
-- How many users have ever opened an email?
select count( user_id) as num_users_open_email
    from (select e.user_id, e.action
        from events e
        group by 1,2
        having e.action = "email_opened") k
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Given the transactions table, write a query to get the average quantity of each product purchased for each transaction, every year. 
-- The output should include the year, product_id, and average quantity for that product sorted by year and product_id ascending. Round avg_quantity to two decimal places. 
select year(created_at) year,
       product_id,
       round(avg(quantity),2) avg_quantity
from transactions
group by 1,2 
order by 1,2 asc
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- The events table that tracks every time a user performs a certain action (like, post_enter, etc.) on a platform.
-- Write a query to determine how many different users gave a like on June 6, 2020. 
select  count(a.action) as num_users_gave_like
from events a
where action = "like" 
      and created_at= "2020-06-06%"
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- You're given a table that represents search results from searches on Facebook. The query column is the search term, position column represents each position the search result came in, and the rating column represents the human rating of the search result from 1 to 5 where 5 is high relevance and 1 is low relevance.
    -- 1. Write a query to compute a metric to measure the quality of the search results for each query. 
    -- 2. You want to be able to compute a metric that measures the precision of the ranking system based on position. For example, if the results for dog and cat are....
	    -- query	result_id	position	rating	notes
	    -- dog	    1000	1	    2	    picture of hotdog
	    -- dog	    998 	2	    4  	    dog walking
	    -- dog	    342 	3	    1	    zebra
	    -- cat     123 	1	    4	    picture of cat
	    -- cat	    435 	2	    2	    cat memes
	    -- cat	    545 	3	    1	    pizza shops
	--...we would rank 'cat' as having a better search result ranking precision than 'dog' based on the correct sorting by rating.
--Write a query to create a metric that can validate and rank the queries by their search result precision. Round the metric (avg_rating column) to 2 decimal places.
select sr.query, round(avg((rating)/(position)),2) avg_rating
from search_results sr
group by query
order by avg_rating desc
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- We're given two tables, a users table with demographic information and the neighborhood they live in and a neighborhoods table.
-- Write a query that returns all of the neighborhoods that have 0 users. 
select n.name as name
    from users u 
right outer join neighborhoods n
on n.id=u.neighborhood_id
where u.id IS NULL
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Write a query to report the distance travelled by each user in descending order.
select u.name, sum(r.distance) distance_traveled
    from rides r
left outer join users u 
on u.id=r.passenger_user_id
group by passenger_user_id
order by r.passenger_user_id
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
