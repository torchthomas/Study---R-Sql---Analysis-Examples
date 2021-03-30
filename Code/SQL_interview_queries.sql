-- Thomas Devine
-- (My)SQL QUERIES from a website that posts interview questions.
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Given a table of product subscriptions with a subscription start date and end date for each user, write a query that returns true or false whether
-- or not each user has a subscription date range that overlaps with any other user.
-- MY NOTES: (Q asked by twitch, nextdoor, pinterest)
--      given table: subscriptions:=[user_id,start_date,end_date] int;datetime;datetime
--      My approach works by taking advantage of the oldest ACTIVE account's start date which will create overlap=1 for like 70%+ of the accounts,
--      then I take the ones with no overlap with the oldest ACTIVE which are accounts that are all INACTIVE. Then I do a cross join to compare the
--      final cohort to pull out the subscriptions with no peers. Then, circling back, only look at user_ids with no peer and set overlap = 0 else overlap =1.
with oldestacct as (
    select min(start_date) start_date_of_oldest_account from subscriptions where end_date is null
),
acctsOverlappedWithOldestActiveAcct as (
    select *, case 
            	when start_date >= (select o.start_date_of_oldest_account from oldestacct o) then 1
            	else 0
        	  end as overlap 
    from subscriptions
),grabZeros as ( -- end_dates HAVE 0 NULLS now!!!
    select * from acctsOverlappedWithOldestActiveAcct 
    where overlap=0
),noPeers as (
    select g1.user_id from grabZeros g1
    cross join grabZeros g2
    where 1=1 -- grab only accounts with no overlapping subscriptions
        and g1.user_id <> g2.user_id 
        and g1.start_date not between g2.start_date and g2.end_date
) -- next, circle back around and just demarcate user_ids with no overlapping subscriptions 
select a.user_id, 
    case 
        when a.user_id in (select noPeers.user_id from noPeers) then 0
        else 1
    end as overlap
from acctsOverlappedWithOldestActiveAcct a 
where overlap=1 -- pull out the user_ids with overlaps
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Write a query to create a new table, named flight routes, that displays unique pairs of two locations.
-- table: flights:= [id,source_location,destination_location] integer;string;string
-- MY NOTES:
--	Example outocme:= {[destination_one,destination_two]} string;string
-- 	Duplicate pairs from the flights table, such as Dallas to Seattle and Seattle to Dallas, should have one entry in the flight routes table.
-- ...... AFTER REVIEW, it's clear this problem accepts various solutions with various number of dest1 and dest2 (which is troublesome to me)
-- ...... I post another answer that I found later on stackoverflow that worked as well (it's more robust, and increases the count)
SELECT DISTINCT a.source_location as destination_one, a.destination_location as destination_two
FROM(SELECT source_location, destination_location FROM flights 
    UNION ALL
    SELECT destination_location, source_location  FROM flights 
    )as a
WHERE source_location <  destination_location 
	-- -- WORKS AS WELL by Gordon Linoff: seen here: https://stackoverflow.com/questions/43646046/sql-distinct-field-combination-disregard-the-position
	--	select source_location as destination_one, destination_location as destination_two from flights f
	--		where source_location < destination_location
	--		union all
	--		select destination_location, source_location from flights f
	--		where source_location < destination_location and 
	--		      not exists (select 1 from flights f2 where f2.destination_location = f.source_location and f2.source_location = f.destination_location)
-- .................................................................
-- Given the two tables, write a SQL query that creates a cumulative distribution of number of comments per user.
-- Assume bin buckets class intervals of one.
-- My NOTES: (q for Amazon)
--          Im going to count deleted comments since engagement is key
--    TABLES:
--      users:=[id,name,created_at]
--      comments:=[user_id,body,created_at]
with ncom as(
	select u.id, count(user_id) freq from users u
	left join comments c on c.user_id=u.id
    group BY 1 order BY 1
),rec as (
    select ncom.freq as frequency, count(*) cnt from ncom
    group by freq order by 1,2
)
select x.frequency, sum(y.cnt) cum_total 
from rec x 
inner join rec y 
    where y.frequency <= x.frequency 
group BY x.frequency
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- -- Q for nerdwallet and google (this is "hard" problem but it took like 4 minutes, fastest I ever did a "hard" problem [mostly spent reading] )
-- The schema above is for a retail online shopping company consisting of two tables, attribution and user_sessions. 
--      -The attribution table logs a session visit for each row.
--      -If conversion is true, then the user converted to buying on that session.
--      -The channel column represents which advertising platform the user was attributed to for that specific session.
--      -Lastly the  table maps many to one session visits back to one user.
-- First touch attribution is defined as the channel to which the converted user was associated with when they first discovered the website.
-- Q: CALCULATE THE FIRST TOUCH attribution for each user_id that converted. 
--  MY NOTES:
--      tables
--          attribution:=[session_id,channel,conversion] ie 1:N; google,facebook,organic,...;0,1
--          user_sessions:=[session_id,created_at,user_id] ie 1:N; datetime; 1:M M\in\Natural#s
--      EXAMPLE OUTPUT (a table): {[user_id,channel],...}:=
--                  {[432,twitter],[41,google][42,facebook],[85,organic]}
--      APPROACH: (people kept coming back to the same site so conversion isn't the last number)
--          this looks like we just need a rownumber =1 kind of pull after joining, grouping, and grouping 
with jor as
(   select conversion as conv,a.session_id as sid
    ,a.channel,us.user_id as uid,created_at as date
    ,row_number() over(partition by us.user_id order by created_at asc) as rn
from user_sessions us
join attribution a on a.session_id = us.session_id
order by date asc,uid asc
)
select j.uid as user_id
    ,j.channel
    from jor j
where 1=1
    and j.conv = 1
    and j.rn=1
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- question was asked by Reddit 
-- We're given three tables representing a forum of users and their comments on posts.
--      We want to figure out if users are creating multiple accounts to upvote their own comments. 
--      1. What kind of metrics could we use to figure this out?
--      2. Write a query that could display the percentage of users on our forum that would be acting fradulently in this manner. 
-- MY NOTES:
-- 		tables: users:=[id,created_at,username]  ,  comments:=(id,created_at,post_id,user_id)  ,  comment_votes:=(id,created_at,user_id,comment_id,is_upvote)
--
-- I look at the average age of a voter on a user’s comment. It’s kind of complicated, but it’s clear there are two cheaters: buckchristina AND amberbrown. 
-- If you remove limit 2, then you’ll see the next avg age of voter is like 27 (still suspicious but not overly suspicious). We could go further and look at the 
-- AVERAGE of the average age of the voter over each user so we just get the number of users on the ‘users’ table. This metric would actually be the most concise
-- by law of large numbers, but there would have to be obvious exceptions (given this is reddit) for major r/AMA posts—that’s when famous people post so you often
-- have thousands of new accounts posting to ask a question.
-- 1.
-- -we could analyze exclusive interactions btwn accts (assuming farming for just oneself)
-- -we could just simply look at the average age of users since the post was created
--      meaning we create a column using datediff(comments.created_at,users.created_at)
--      so it's negative when the the comment is before the user_id's creation
-- NOTE on 1: new accounts are going to like older posts so we can't look at a user's 
--            average age of posts, so we can only look at the age users on a 
--            post or datediff from post creation and user_id creation. 
--          HOWEVER the reverse is obviously ok and sensible given who'd see a post on average
-- 2.
with apc as -- apc:= agePerComment 
(
select u.id as uid,u.created_at as ucreatedat
    ,postid,cuid,u.username,cid,ccreatedat,cvid,cvcreatedat,cvuid,cvcomid,isupv
from users u
left join 
   (select c.id as cid
        ,c.created_at as ccreatedat   -- comment creation date (object of interest)
        ,c.post_id as postid          -- nonobvious use
        ,c.user_id as cuid
    from comments c
    ) cc
on cc.cuid = u.id 
left join 
   (select cv.id as cvid              -- comment voter's id (key for grouping later)
        ,cv.created_at as cvcreatedat -- comment voter's created date of vote
        ,cv.user_id as cvuid,cv.comment_id as cvcomid,cv.is_upvote as isupv
    from comment_votes cv
    ) ccv
on 1=1 
    and ccv.cvuid <> u.id
    and ccv.cvcomid = cc.cid
) 
select x.username,  x.postid as post_id, x.cid as comment_id
    ,avg(datediff(x.ccreatedat,x.ucreatedat)) over (partition by x.cuid) as avgAgeOfVoter
    from apc x -- , apc y
where x.postid IS NOT NULL
    AND cvuid IS NOT NULL
group by x.postid,x.cuid
ORDER BY avgAgeOfVoter asc
limit 2
-- .................................................................
-- We're given a table of user experiences representing each person's past work experiences and timelines. 
-- Specifically let's say we're interested in analyzing the career paths of data scientists. Let's say that the titles we care about are bucketed into data scientist, senior data scientist, and data science manager. 
-- We're interested in determining if a data scientist who switches jobs more often ends up getting promoted to a manager role faster than a data scientist that stays at one job for longer. 
-- Write a query to prove or disprove this hypothesis.
-- My notes: 
--         My answer isn't complete enough for the data set given, but doesn't extend yet for massive data sets.
--         To correctly implement this, I still need a final metric (the median number of jobs). Currently, my FINAL columns shown: title, user_id, njobs, nDays2Manager.
--         What I need to do is make this a binary decision by splitting people into TWO groups by the median number of jobs they had
--         to become a manager, then AVG "nDays2Manager" (the ndays between the user_id's first job's start_date and the user_id's first manager role 
--         start_date)
--         AND voila, we got the correct answer. It's a shame I can't make the median number that easily in mysql.
--         For this particular dataset provided on the site, I can gimmickly get the right answer, but it just happens to work because of the 
--         particular use of the floor() on THIS dataset's average. I commented-out that incorrect portion (associated with v2.* and following v) when I realized my (then) method
--         wouldn't extend if the data were bigger... I know the correct idea which is honestly the most important part. I could do this in R in like 15 minutes.
with ndays_njobs as (
    select o.company,o.title
        ,DATE_FORMAT(o.start_date, '%Y-%m-%d')as  start_date
        ,DATE_FORMAT(o.end_date, '%Y-%m-%d')as  end_date
        ,o.user_id,nJobs_title,o.is_current_role as icr
        -- ,ifnull(datediff(o.start_date,lag(o.end_date) over(order by o.user_id, o.start_date)),0) as ndaysUnemp
    from user_experiences o
    join (
        select x.user_id, x.id, x.title, count(*) nJobs_title from user_experiences x
        group by x.user_id, x.title
    ) ds
    on ds.user_id=o.user_id and ds.title = o.title
    -- group by user_id, title
    order by o.user_id, start_date
),
working_lifespan as 
(	-- simple approach just looking at data science role and manager date
    select *
    from 
    (   select z.title ,z.user_id as uuid
        from user_experiences z
        group by z.user_id, z.title
    ) s
    join
    (   select k.user_id 
        -- get days between first role and current role (max starting date)
        ,datediff(max(k.start_date),min(k.start_date)) as ndayfrom1stJtolastJ
        from user_experiences k
        group by k.user_id
    )as firstDayCurrentjob 
    on firstDayCurrentjob.user_id = s.uuid
)
select 
    v.title
    ,v.uid as user_id
    ,sum(asdf) as njobs
    ,v.ndayfrom1stJtolastJ as nDays2Manager
    -- ,v2.*
from(
    select n.title,n.start_date
            ,max(n.end_date) as end_date
            ,n.user_id       as uid
            ,n.nJobs_title as asdf
            ,n.icr
            -- ,sum(ndaysUnemp) as ndaysUnemp
            ,a.ndayfrom1stJtolastJ
        from ndays_njobs n
        join working_lifespan as a
            on a.uuid = n.user_id
        group by n.user_id, title
        order by n.icr desc
) as v
-- ,(
--     select floor(avg(justmedian.sumJobs)) as median
--         from
--         (
--             select sum(p.nJobs_title), p.user_id as sumJobs from ndays_njobs p
--             group by p.user_id
--         ) justmedian
-- ) as v2 
group by v.uid
having title like "%manager"
order by njobs
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 -- In the table above, column action represents either ('post_enter', 'post_submit', 'post_canceled') for when a user starts a post (enter), ends up canceling it (cancel), or ends up posting it (submit).
 -- Write a query to get the post success rate for each day in the month of January 2020.
 -- select e.id,e.user_id,e.action,e.created_at from events e order by user_id
 -- MY NOTES; TABLE:= events= [id,useR_id,created_at,action,url,platform]; int,int,datetime,string,string,string
 --      hardest this is filling the missing date/dates interval 
with enters as 
(   select e.user_id
        ,e.action,date(e.created_at) as dt
        ,count(*) as totalenters
    from events e where e.action="post_enter"
    group by date(e.created_at),e.user_id
    order by user_id asc
),
submits as
(   select e.user_id
         , e.action
         , date(e.created_at) as dt
         , count(*) as totalsubmits
    from events e where e.action="post_submit"
    group by e.created_at, e.user_id
),
daterange as (
    select a.Date as datee
    from (
        select date("2020-02-01")- INTERVAL (a.a + (10 * b.a) + (100 * c.a) + (1000 * d.a) ) DAY as Date
        from (select 0 as a union all select 1 union all select 2 union all select 3 union all select 4 union all select 5 union all select 6 union all select 7 union all select 8 union all select 9) as a
        cross join (select 0 as a union all select 1 union all select 2 union all select 3 union all select 4 union all select 5 union all select 6 union all select 7 union all select 8 union all select 9) as b
        cross join (select 0 as a union all select 1 union all select 2 union all select 3 union all select 4 union all select 5 union all select 6 union all select 7 union all select 8 union all select 9) as c
        cross join (select 0 as a union all select 1 union all select 2 union all select 3 union all select 4 union all select 5 union all select 6 union all select 7 union all select 8 union all select 9) as d
    ) a
    where a.Date between '2020-01-01' and '2020-01-31' 
),
joined as 
 (   select e.dt,e.totalenters, s.totalsubmits, avg(s.totalsubmits/e.totalenters) as post_success_rate
    from enters e
    join submits s on s.dt=e.dt and e.user_id=s.user_id
    group by e.dt
)
select date_format(d.datee,"%Y-%m-%d") dt, ifnull(post_success_rate,0) post_success_rate from daterange d 
left join joined j
on d.datee=j.dt
order by dt asc
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Write a query to return pairs of projects where the end date of one project matches the start date of another project. 
-- MY NOTES:
--  		table: [id,title,start_date,end_date,budget]; integer,string,datetime,datetime,float
--  		output: [project_title_end,project_title_start,date]; string,string,datetime
-- 	  Given multiple DIFFERENT projects could end and start on the same day AND some projects could start and stop on the SAME day,
--   this is going to match projects with different ids (or titles, but titles aren't guaranteed  to be unique).
    select p.title as project_title_end,p2.title as project_title_start,date(p.end_date) as date
    from projects p
    cross join projects p2
    where 1=1 
        and date(p.end_date)<date(p2.start_date) 
        and date(p.end_date)>date(p2.start_date) 
        and p.id <> p2.id -- exclude projects which start and stop on the same day 
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- A dating websites schema is represented by a table of people that like other people. The table has three columns. One column is the user_id, another column is the liker_id which is the user_id of the user doing the liking, and the last column is the date time that the like occured.
-- Write a query to count the number of liker's likers (the users that like the likers) if the liker has one.
-- MY NOTES: I had a simple and nice solution so I figured why not show it first, after all, this was ranked hard.
select user_id as user, count(*) as count
	from likes 
where user_id in (select distinct liker_id from likes) group by 1
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Given a users table, write a query to get the cumulative number of new users added by day, with the total reset every month. 
-- MY NOTES: (q by Amazon)
--  table: users:=[id,name,created_at] int;string;datetime
--  simple count then sum over partition by and order by. The trick is to partition by year and monthotherwise the counts are messed up
with cnt as
(
    select date(u.created_at) as created_at
            ,count(u.id) as md_cnt from users u
    group by u.created_at
)
select c.created_at as date
    ,sum(c.md_cnt) over(partition by year(c.created_at),month(c.created_at) 
                        order by c.created_at asc
                    ) as  monthly_cumulative
from cnt c
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Let's say we have a table with an id and name field. The table holds over 100 million rows and we want to sample a random row in the table without throttling the database.
-- Write a query to randomly sample a row from this table.
select b.* from big_table b
order by RAND() limit 1;
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
-- The events table that tracks every time a user performs a certain action (like, post_enter, etc.) on a platform.
-- Write a query to determine the top 5 actions performed during the week of Thanksgiving (11/22 - 11/28, 2020), and rank them based on number of times performed.
-- The output should include the action performed and their rank in ascending order. If two actions performed equally, they should have the same rank. 
-- MY NOTES:
--   top 5 is a simple limit at the end
--   date filter is date between "2020-11-22" and "2020-11-28"
--   aggregation is counting over action grouping by action 
select e2.action, rank () over(order by e2.cnt desc)  as ranks
from(
    select user_id as var, action, created_at, count(e.user_id) as cnt
        from events e
    where created_at between "2020-11-22" and "2020-11-28"
    group by action
) e2
limit 5
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 1. Design a database for a stand-alone fast food restaurant. 
-- 2. Based on the above database schema, write a SQL query to find the top three highest revenue items sold yesterday. 
-- 3. Write a SQL query using the database schema to find the percentage of customers that order drinks with their meal. 
-- ans: 1
	-- what's missing is a the link dissecting order into the order_content table, but that link is crucial since it lists what's purchased.
	CREATE TABLE transactions (
	    order_id int                -- will be distinct in this table
	    , created_at datetime        -- creates a datetime stamp
	    , payment_option string      -- cash, debit, credit
	    , transaction_status string  -- complete, cancelled, voided
	    , ticket_price float         -- transaction price
	);
	-- next we want a table to track what each list ordered
	CREATE TABLE order_content ( 
	    order_id int          -- will NOT be distinct since we show items in orders,
	    , meal string         -- chicken fajita, dr pepper, 1/3 lb burger, fries
	    , drink_size string   -- large, medium, small
	    , food_group string   -- combo, drink, meal  (combo=drink+meal)
	    , price float
	);
-- ans: 2
	select t.order_id, o.price, o.meal  , o.drink , o.food_group  
	from transactions t	join order_content o on o.order_id = t.order_id
	where t.created_at = date(subdate(curdate(), 1)) -- yesterday but without time in the timestamp
	order by o.price desc limit 3
-- ans: 3
	-- we assume that pricing of combos is cheaper and that all that order drinks and meal will have it down as a combo
	with joined as (
	    select t.order_id , o.price, o.items_sold, o.item_size, o.item_group  from transactions t
	    join order_content o on o.order_id = t.order_id    
	),
	cnt_combos as (
	    select count(distinct order_id) as nCombo_orders from joined where food_group = 'combo'
	) 
	select 100*(select cnt_combos.nCombo_orders from cnt_combos)/(select count(distinct order_id) from order_content)
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Let's say we want to build a naive recommender. We're given two tables, one table called `friends` with a user_id and friend_id columns representing each user's friends, and another table called `page_likes` with a user_id and a page_id representing the page each user liked.
-- Write an SQL query to create a metric to recommend pages for each user based on recommendations from their friends liked pages. 
-- Note: It shouldn't recommend pages that the user already likes.
-- MY NOTES: tables, friends:=[user_id,friend_id] int,int; page_likes:=[user_id,page_id] int,int
--      1. first subquery gets all the pages 'your' friends like (including the ones 'you' like)
--      2. second subquery joins the first subquery and excludes the pages 'you' like 
--      3. select statement counts rows of the grouping by your id and friends_page_id (i.e., user_id, 
with pages_of_friends as 
(   select f.user_id , f.friend_id,p.page_id as friends_page_id
    from page_likes p
    join friends f on f.friend_id=p.user_id
    order by 1 asc
),
joined as 
(   select pf.*  -- essentially, just removing pages shared
    from pages_of_friends pf
    join page_likes pm on 1=1
        and pm.user_id = pf.user_id
        and pm.page_id <> pf.friends_page_id
    group by 1,2,3
    order by user_id asc,friends_page_id asc
) select j.user_id, j.friends_page_id as page_id
      ,count(*) as num_friend_likes
  from joined j
  group by 1,2
  order by 1 asc, 3 desc
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
	        -- can filter year, is_deleted, c.user_id <> cv.user_id, and vote positive (unecessary control but it's ok)
select u.id, u.username, count(cv.id) as upvotes
from users u
left join comments c
	on u.id = c.user_id
left join comment_votes cv
	on c.id = cv.comment_id
where c.is_deleted = 0          -- exclude deleted comments
    and year(c.created_at)=2020 -- only comments created in 2020 (would be a bit more fun to get upvotes only from 2020)
    and cv.user_id <> c.user_id -- no self-votes
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
-- Given a table of transactions and products, write a query to return the product id and average product price 
-- for that id. Only return the products where the average product price is greater than the average price of all transactions.
-- My notes: tables: products:=[id,name,price]int,string,float; 
--                  transactions:=[id,user_id,created_at,product_id,quantity] int,int,datetime,int,int
--      there was a mistake in the solution where the solution demanded avg( p.price) over() as avg_price for the avg transactions price,
--      which is wrong since whoever wrote it forgot quantity, which I have
--      the question doesn't ask for this filter to be for transaction ids which makes more sense how it's worded now
--      but I comment out a group by product_id filter since how the solution is given one can infer this is neater since there are no duplicates
with join_TandP_and_calculate_cost as (
    select t.product_id
        ,avg(p.price) over(partition by t.product_id) as avg_product_price  -- get avg price t
        ,avg(t.quantity * p.price) over() as avg_price  -- get avg cost of all t.id
    from transactions as t
    inner join products as p
    on p.id=t.product_id
)
select j.product_id
    ,round(j.avg_product_price,2) as product_avg_price
    ,round(j.avg_price,2) avg_price
    -- ,j.name
from join_TandP_and_calculate_cost j
where j.avg_product_price > avg_price
-- group by j.product_id
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- We have a table that represents the total number of messages sent between two users by date on messenger.
--      select * from messages 
-- 1. What are some insights that could be derived from this table?
-- 2. What do you think the distribution of the number of conversations created by each user per day looks like?
-- 3. Write a query to get the distribution of the number of conversations created by each user by day in the year 2020.
-- MY ANSWERS: (table: messages:= [id,date,user1,user2,msg_count]; int,datetime,int,int,int)
-- 1. We could find frequent relationships people tend to, what seasonality there is in messaging behavior based off of user information (shared school, holidays, bdays, etc.)
-- 2. There is is likely some time dependency (early morning, lunch, after work to the end of the night). Further, 
--    like in (1), seasonality can be inferred from dates, shared interest, or other personal info.
-- 3.
with t as (
    select *,count(id) as nconvs
        from messages 
    group by date,user1
    having year(date) = 2020
    order by user1 asc, date asc
)
select nconvs num_conversations, count(*) frequency from t
group by nconvs
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
-- We're given two tables. One is named `projects` and the other maps employees to the projects they're working on. 
-- We want to select the five most expensive projects by budget to employee count ratio. But let's say that we've found a bug where there exists duplicate rows in the `employees_projects` table.
-- Write a query to account for the error and select the top five most expensive projects by budget to employee count ratio.
-- MY NOTES: tables: projects:=[id,title,start_date,end_date,budget]; int,varchar,date,date,int
--           employees_projects:=[project_id,employee_id]; int,int
--       the group by in the subquery is the "trick", otherwise this is easy
select title,p.budget/count(e.employee_id) budget_per_employee from projects p
join (select * from employees_projects group by 1,2) e
on e.project_id=p.id
group by e.project_id order by p.budget/count(e.employee_id) desc limit 5
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Write a query to identify managers with the biggest team size
-- MY notes: table: employees:=[id, manager_id,firstname,lastname,salary,departmentid] int,,int,string,string,int,int
--                  managers :=[id,name,team]; int,string,string
select m.name as manager ,count(e.id) as team_size
    from employees e 
join managers m on m.id=e.manager_id
group by m.name order by count(e.id) desc
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
-- Given the tables above, select the top 3 departments with at least ten employees and rank them according to the percentage of their employees making over 100K in salary.
-- MY NOTES (two tables, employees and depatments, easy problem)
--       count rank departments by employee ids
with df as 
(   select d.name 
        ,case 
            when e.salary > 100000 then 1
            else 0
        end as salOver100k
      , count(e.id) over(partition by department_id) nEmps
      ,e.*
    from employees e
    left join departments d
    on d.id=e.department_id
)
select sum(df.salOver100k)/df.nEmps as percentage_over_100K
        ,df.name as department_name
        ,df.nEmps as number_of_employees
from df
group by name
having nEmps>9
limit 3
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
-- You're given a table that represents search results from searches on Facebook. The `query` column is the search term, `position` column represents each position the search result came in, and the rating column represents the human rating of the result from 1 to 5 where 5 is high relevance and 1 is low relevance.
-- Write a query to get the percentage of search queries where all of the ratings for the query results are less than a rating of 3. Please round your answer to two decimal points.
-- MY NOTES: search_results:= [query,result_id,position,rating] varchat,int,int,int
--      output:= [percentage_less_than_3]; float
select round(1 - (
		    select count(distinct s.query) as high_quality 
		    from search_results s
		    where s.rating >= 3
		) /(select count(distinct s2.query) 
		    from search_results s2)
		,2) as percentage_less_than_3
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
-- Write a query to return only odd row numbers
	--my notes1: too easy
select a.* 
from (select rownum as rn,e.* from emp e) a
where Mod(a.rn,2)=1
	--my notes2: here is how I'd do this without rownum given since row numbers are not frequently given
	select a.* 
	from (
		select c.*, rank() over(partition by c.id) as rn 
		from emp c
	) a 
	where Mod(a.rn,2)=1
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
-- We're given two tables. One is named `projects` and the other maps employees to the projects they're working on.
-- Write a query to get the top five most expensive projects by budget to employee count ratio.
-- Note: Exclude projects with 0 employees. Assume each employee works on only one project.
select title,budget/ep.cnt as budget_per_employee from projects
join(select e.project_id,count(e.employee_id) as cnt from employees_projects e
        group by e.project_id 
    ) ep on projects.id = ep.project_id
order by projects.budget/ep.cnt desc limit 5
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- We're given a table of product purchases. Each row in the table represents an individual user product purchase.
-- Write a query to get the number of customers that were upsold by purchasing additional products.
-- Note that if the customer purchased two things on the same day that does not count as an upsell as they were purchased within a similar timeframe.
-- MY NOTES:
--  table: transactions:= [id,user_id,created_at,product_id,quantity] int,int,datetime,int,int
--      could count noncontemporaneous dates while grouping by user_id, but this was the first I thought of 
select count(distinct t.user_id) as num_of_upsold_customers
from 
(   select t2.id,t2.user_id,t2.created_at
        ,dense_rank() over(partition by t2.user_id order by t2.created_at asc) as ranks
    from transactions t2
) t
where t.ranks >1
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Let’s say we have a table representing a company payroll schema.
-- Due to an ETL error, the employees table instead of updating the salaries every year when doing compensation adjustments, did an insert instead. The head of HR still needs the current salary of each employee.
-- Write a query to get the current salary for each employee.
-- Assume no duplicate combination of first and last names. (I.E. No two John Smiths)
-- MY NOTES: table: employees:= [id,first_name,last_name,salary,department_id]
--      insert issue means we should have more people
select em.first_name,em.last_name,em.salary from employees em
join(   select e1.first_name, e1.last_name, max(e1.id)  as maxid 
    from employees e1
    group by 1,2
    ) e
on maxid = em.id and e.first_name=em.first_name and e.last_name = em.last_name 
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
	    -- cat      123 	1	    4	    picture of cat
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
-- Display x 50% records from Employee table?
	-- first 50%
	select rn, e.* from emp e where rn<=(select count(*)/2 from emp)
	-- last 50%
	Select rn,e.* from emp e
	minus
	Select rn,e.* from emp e where rn<=(Select count(*)/2) from emp)
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Write a query to fetch only common records between 2 tables.
Select * from Employee
Intersect
Select * from Employee1
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Write a query to return a list of employees with their respective manager's ID 
-- my notes: manager_id is a column so we can use that 
Select e.employee_name,m.employee name 
from emp e,emp m 
where e.Employee_id=m.Manager_id
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
