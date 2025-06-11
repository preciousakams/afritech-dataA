-- Create Customer Data Table
create table Customer_Data(
	customerid int primary key,
    customername varchar(255),
    region varchar(255),
    age int,
    income numeric(10,2),
    customertype varchar(50)
);

-- Create Transaction Data Table
create table Transaction_Data(
	transactionID serial primary key,
	customerID int,
	transactionyear int,
    transactiondate date,
    productpurchased varchar(255),
    purchaseamount numeric(10,2),
    productrecalled bool,
    competitor_x varchar(255),
	foreign key (customerID) references Customer_Data(customerid)
);

-- Create Socialmedia Data Table
create table Socialmedia_Data(
	postID serial primary key,
	customerID int,
	interactiondate date,
    platform varchar(255),
    posttype varchar(255),
    engagementlikes int,
    engagementshares int,
    engagementcomments int,
    userfollowers int,
    influencerscore numeric(10,2),
    brandmention bool,
    competitormention bool,
    sentiment varchar(50),
    crisiseventtime date,
    firstresponsetime date,
    resolutionstatus bool,
    npsresponse integer,
	foreign key (customerID) references Customer_Data(customerid)
);

-- Insert Customer Data
insert into customer_data(customerid,customername,region,age,income,customertype)
select distinct customerid,customername,region,age,income,customertype
from staging_data;

-- Insert Transaction Data
insert into transaction_Data(customerID,transactionyear,transactiondate,productpurchased,purchaseamount,productrecalled,competitor_x)
select customerID,transactionyear,transactiondate,productpurchased,purchaseamount,productrecalled,competitor_x
from staging_data where transactiondate is not NULL;

-- Insert Socialmedia Data
insert into socialmedia_data(customerID,interactiondate,platform,posttype,engagementlikes,engagementshares,engagementcomments,userfollowers,influencerscore,
brandmention,competitormention,sentiment,crisiseventtime,firstresponsetime,resolutionstatus,npsresponse)
select customerID,interactiondate,platform,posttype,engagementlikes,engagementshares,engagementcomments,userfollowers,influencerscore,
brandmention,competitormention,sentiment,crisiseventtime,firstresponsetime,resolutionstatus,npsresponse
from staging_data where interactiondate is not NULL

drop table staging_data;

select count(*) from customer_data;

select count(*) from transaction_data;

select count(*) from socialmedia_data;

-- identify missing columns
select count(*) from transaction_data
where competitor_x is null;

----------------------------------------
-- Customer EDA

--customer demographics
create or replace view customer_region_demo as
Select region, count(*) as customer_region
from customer_data
group by region;


Select age, count(*) as customer_age
from customer_data
group by age;

create or replace view customer_type_demo as
Select customertype, count(*) as customer_type
from customer_data
group by customertype
order by customer_type Desc;

create or replace view customer_age_demo as
SELECT 
  CASE 
    WHEN age < 20 THEN 'Below 20'
    WHEN age < 30 THEN '21 to 30'
    WHEN age < 40 THEN '31 to 40'
    WHEN age < 50 THEN '41 to 50'
	WHEN age < 60 THEN '51 to 60'
    ELSE 'Above 60'
  END AS age_range,
  COUNT(*) AS customer_count
FROM customer_data
GROUP BY age_range;

create or replace view customer_income_demo as
SELECT 
  CASE 
    WHEN income < 20000 THEN 'less than 20K'
    WHEN income < 40000 THEN 'less than 40K'
    WHEN income < 60000 THEN 'less than 60K'
    WHEN income < 80000 THEN 'less than 80K'
    WHEN income < 100000 THEN 'less than 100K'
    ELSE 'above 100K'
  END AS income_range,
  COUNT(*) AS customer_count
FROM customer_data
GROUP BY income_range;


-- Cstomer lifetime Value(top 5 customers)

create or replace view customer_lifetimeValue as

Select c.customerid,c.customername, sum(t.purchaseamount) as lifetimeValue
from customer_data c
left join
transaction_data t on c.customerid = t.customerid
group by c.customerid, c.customername
order by lifetimeValue desc
limit 5;
------------------------------
-- Transaction EDA

select 
	avg(purchaseamount) as AveragePurchaseAmount,
	min(purchaseamount) as MinPurchaseAmount,
	max(purchaseamount) as maxPurchaseAmount,
	sum(purchaseamount) as totalSales
from transaction_data;

--convert to string so as to include the $ sign(currency)
create or replace view transaction_summary as
select 
	to_char(avg(purchaseamount), '$999,999,999.99') as AveragePurchaseAmount,
	to_char(min(purchaseamount), '$999,999,999.99') as MinPurchaseAmount,
	to_char(max(purchaseamount), '$999,999,999.99') as maxPurchaseAmount,
	to_char(sum(purchaseamount), '$9,999,999,999.99') as totalSales
from transaction_data;

--total product purchased
select productpurchased, count(*) as totalPurchased
from transaction_data
group by productpurchased;

--total revenue by product after recall
select productpurchased,count(*) as number_of_sales,
to_char(sum(purchaseamount), '$9,999,999,999.99') as total_revenue
from transaction_data
where productrecalled = false
group by productpurchased;

--total sales per product

select productpurchased, count(*) as number_of_sales,
to_char(sum(purchaseamount), '$9,999,999,999.99') as total_revenue
from transaction_data
group by productpurchased;

--total product recalled
select transactiondate, productpurchased,
sum(purchaseamount) as lost_revenue 
from transaction_data where productrecalled = true
group by transactiondate, productpurchased;

-- total_product_sold_and_recalled
create or replace view total_product_sold_and_recalled as

SELECT
  productpurchased,
  COUNT(*) AS total_sales,
  COUNT(CASE WHEN productrecalled = true THEN 1 END) AS total_recall,
  SUM(purchaseamount) AS total_revenue,
  SUM(CASE WHEN productrecalled = true THEN purchaseamount ELSE 0 END) AS lost_revenue
FROM transaction_data
GROUP BY productpurchased;

--average product recall
create or replace view avg_product_recalled as

select productrecalled, 
	count(*) as total_transaction,
	avg(purchaseamount) as average_amount
from transaction_data
where purchaseamount is not null
group by productrecalled;

-------------------------------------
-- Social media EDA

select platform,
	round(avg(engagementlikes),0) as average_engagementlikes,
	to_char(sum(engagementlikes),'999,999,999') as total_engagementlikes
from socialmedia_data
group by platform;

select platform,
	round(avg(engagementshares),0) as average_engagementshares,
	to_char(sum(engagementshares),'999,999,999') as total_engagementshares
from socialmedia_data
group by platform;

select platform,
	round(avg(engagementcomments),0) as average_engagementcomments,
	to_char(sum(engagementcomments),'999,999,999') as total_engagementcomments
from socialmedia_data
group by platform;
	
select platform,
	round(avg(userfollowers),0) as average_userfollowers,
	to_char(sum(userfollowers),'999,999,999') as total_userfollowers
from socialmedia_data
group by platform;

select platform,
	round(avg(influencerscore),2) as average_influencerscore,
	to_char(sum(influencerscore),'999,999,999') as total_influencerscore
from socialmedia_data
group by platform;

-- Sentiments
select sentiment, count(*) as total_count
from socialmedia_data
where sentiment is not null
group by sentiment;

-- group sentiment by platform
select platform, count(*) as positive_sentiment
from socialmedia_data
where sentiment = 'Positive'
group by platform;

select platform, count(*) as negative_sentiment
from socialmedia_data
where sentiment = 'Negative'
group by platform;

select platform, count(*) as neutral_sentiment
from socialmedia_data
where sentiment = 'Neutral'
group by platform;

-- group sentiment
select sentiment, count(*) as Count
from socialmedia_data
where sentiment is not null
group by sentiment;


--confirming if null values will affect outcome
select 'platform' as columnName, count(*) as null_content
from socialmedia_data
where platform is not null
union
select 'sentiment', count(*) as null_content
from socialmedia_data
where sentiment is not null;

-- total brand mentions across socialmedia

select  count(*) as total_brandmention
from socialmedia_data
where brandmention = true;

-- brand mention for each socialmedia platform
select  platform, count(*) as total_brandmention
from socialmedia_data
where brandmention = true
group by platform;

--Sentiment percentage breakdown

select  sentiment, count(*) * (100.0)/
(select count(*) from socialmedia_data)
as percentage
from socialmedia_data
group by sentiment;

--engagement rate

select Avg((engagementlikes + engagementshares + engagementcomments)/
nullif (userfollowers, 0))
as engagement_rate
from socialmedia_data;

--brand mention by competitior mention

create or replace view brand_and_competitior_mention as

select interactiondate, platform, sum(case when brandmention = 'TRUE' 
then 1 else 0 end) as brand_mention,
sum(case when competitormention = 'TRUE' 
then 1 else 0 end) as competitor_mention
from socialmedia_data
group by interactiondate,platform;

--avg influencer score

create or replace view avg_influencer_score as
select interactiondate,platform,round(avg(influencerscore), 2)
as influence_score
from socialmedia_data
group by interactiondate,platform;

-- Time trend analysis

select to_char(date_trunc('month', interactiondate), 'YYYY-MM') as month, 
count(*) as mentions, platform
from socialmedia_data
where brandmention = true 
group by month, platform;

-- crisis response over time
create or replace view avg_crisis_response as

select crisiseventtime,firstresponsetime, platform, avg(date_part('epoch', cast(firstresponsetime as timestamp) - cast(crisiseventtime as timestamp)))/3600/24 as time_btw_crisis_and_response
from socialmedia_data
where crisiseventtime is not null
and firstresponsetime is not null
group by crisiseventtime,firstresponsetime,platform;

--resolution rate
create or replace view crisis_resolution_rate as
select interactiondate,platform,count(*) * 100.0/
(select count(*) from socialmedia_data where crisiseventtime is not null) 
as resolutionrate 
from socialmedia_data
where resolutionstatus = 'True'
group by interactiondate,platform;

--unresolved issue
create or replace view unresolved_issue_rate as
select interactiondate,platform,count(*) * 100.0/
(select count(*) from socialmedia_data where crisiseventtime is not null) 
as unresolved_issue_rate 
from socialmedia_data
where resolutionstatus = 'False'
group by interactiondate,platform;

--top influencers
create or replace view top_influencers as
select customerid, round(AVG(influencerscore), 0) as influencer_score
from socialmedia_data
group by customerid
order by influencer_score desc
limit 10;

--content effectiveness
select platform, round(Avg(engagementlikes + engagementshares + engagementcomments),0)
as engagement
from socialmedia_data
group by platform;

--total revenue by platform without table join
select s.platform as platform,to_char(count(*), '9,999,999,999') as number_of_sales,
to_char(sum(t.purchaseamount), '$9,999,999,999.99') as total_revenue
from socialmedia_data s, transaction_data t
where t.customerid = s.customerid
group by platform
order by total_revenue desc;

--total revenue by platform

create or replace view revenue_by_platform as

select s.interactiondate,s.platform,to_char(sum(t.purchaseamount), '$9,999,999,999.99') as total_revenue
from socialmedia_data s
left join transaction_data t on s.customerid = t.customerid
where t.purchaseamount is not null                                                                             
group by s.interactiondate,s.platform
order by total_revenue desc;

--top buy customers and region
select 
	c.customerid,
	c.customername,
	c.region,
	coalesce(sum(t.purchaseamount), 0) as total_purchase
from customer_data c
left join transaction_data t on c.customerid = t.customerid                                                                            
group by c.customerid,c.customername,c.region
order by total_purchase desc
limit 10;

-- average engagement metrics by product

select 
	t.productpurchased, 
	avg(s.engagementlikes) as avg_engagement_likes,
	avg(s.engagementshares) as avg_engagement_shares,
	avg(s.engagementcomments) as avg_engagement_comments
from transaction_data t
left join socialmedia_data s  on t.customerid = s.customerid                                                                           
group by t.productpurchased
order by avg_engagement_likes desc,avg_engagement_shares desc,avg_engagement_comments desc;

--products with negative socialmedia buzz and recall (A CTE)
create or replace view negetive_buzzeffect as
with negativeBuzzAndRecalls as (
select 
	t.productpurchased, 
	count( distinct case when s.sentiment = 'Negative' then s.customerid end) as negative_buzz_count,
	count( distinct case when t.productrecalled = true then t.customerid end) as product_recalled_count
from transaction_data t
left join socialmedia_data s  on t.customerid = s.customerid                                                                           
group by t.productpurchased
)

select n.productpurchased, n.negative_buzz_count, n.product_recalled_count
from negativeBuzzAndRecalls n
where n.negative_buzz_count  > 0 or n.product_recalled_count > 0;

-- views
-- creating a view for brand mentions
create or replace view brandMentions as
select interactiondate, count(*) as brandMention_count
from socialmedia_data
where brandMention
group by interactionDate
order by interactionDate;

select * from brandMentions;

-- stored procedures
-- stored procedures for crisis response time

create or replace function calculatedAvgResponseTime() returns table (
	platform Varchar(50),
	AvgResponseTimeHours numeric
) as $$
Begin
	return query (
		select
			s.platform,
			avg(extract(epoch from (cast(s.firstresponsetime as timestamp) - cast(s.crisiseventtime as timestamp)))) /3600
		from socialmedia_data s
		where crisiseventtime is not null and s.firstresponsetime is not null
		group by s.platform
	);
end;
$$ language plpgsql;

select * from calculatedAvgResponseTime();

--purchase by age range
create or replace view purchase_by_agerange as
SELECT
  CASE 
    WHEN c.age BETWEEN 18 AND 25 THEN '18-25'
    WHEN c.age BETWEEN 26 AND 35 THEN '26-35'
    WHEN c.age BETWEEN 36 AND 45 THEN '36-45'
    WHEN c.age BETWEEN 46 AND 60 THEN '46-60'
    ELSE '60+'
  END AS age_range,
  SUM(t.purchaseamount) AS total_purchase
FROM customer_data c
JOIN transaction_data t
  ON c.customerid = t.customerid
GROUP BY
  CASE 
    WHEN c.age BETWEEN 18 AND 25 THEN '18-25'
    WHEN c.age BETWEEN 26 AND 35 THEN '26-35'
    WHEN c.age BETWEEN 36 AND 45 THEN '36-45'
    WHEN c.age BETWEEN 46 AND 60 THEN '46-60'
    ELSE '60+'
  END
ORDER BY age_range;

select count(sentiment) from socialmedia_data;

-- top regional sales volume
create or replace view top_regional_sales as

select c.region, sum(t.purchaseamount) as purchaseamount
from transaction_data t
left join customer_data c on t.customerid = c.customerid
group by c.region
order by purchaseamount desc limit 5;

-- worst regional sales volume
create or replace view worst_regional_sales as
select c.region, sum(t.purchaseamount) as purchaseamount
from transaction_data t
left join customer_data c on t.customerid = c.customerid
group by c.region
order by purchaseamount asc limit 5;
