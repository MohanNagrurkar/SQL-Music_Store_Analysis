create database Music_Store;
use Music_Store;

select * from employee;

-- -----------------------------------------------------------------------
-- 1. Who is the senior most employee based on job title?
SELECT 
    *
FROM
    employee
ORDER BY levels DESC
LIMIT 1;

-- -----------------------------------------------------------------------
-- 2. Which countries have the most Invoices?
select * from invoice;

SELECT 
    billing_country as 'Billing Country', COUNT(billing_country) AS 'Most Invoices'
FROM
    invoice
GROUP BY billing_country;

-- -----------------------------------------------------------------------
-- 3. What are top 3 values of total invoice?

select * from invoice;
SELECT 
    invoice_id as 'Invoice ID', total as 'Invoice Total'
FROM
    invoice
ORDER BY total DESC
LIMIT 3;

-- -----------------------------------------------------------------------
-- 4. Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. Write a query that returns one city that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals

SELECT 
    billing_city as 'Billing City', SUM(total) as 'Invoice Total'
FROM
    invoice
GROUP BY billing_city
ORDER BY SUM(total) DESC
LIMIT 1;

-- -----------------------------------------------------------------------
-- Who is the best customer? 
-- Write a query that returns the person who has spent the most money

SELECT 
    invoice.customer_id AS 'Id of Best Customer',
    customer.first_name AS 'First Name',
    customer.last_name AS 'Last Name',
    SUM(total) AS 'Invoice'
FROM
    invoice
        JOIN
    customer ON invoice.customer_id = customer.customer_id
GROUP BY invoice.customer_id , customer.first_name , customer.last_name
ORDER BY SUM(total) DESC
LIMIT 1;


-- -----------------------------------------------------------------------
-- Write query to return the email, first name, last name, & Genre of all Rock Music listeners. Return your list ordered alphabetically by email starting with A.

SELECT DISTINCT
    customer.email, customer.first_name, customer.last_name
FROM
    customer
        JOIN
    invoice ON customer.customer_id = invoice.customer_id
        JOIN
    invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE
    track_id IN (SELECT 
            track_id
        FROM
            track
                JOIN
            genre ON track.genre_id = genre.genre_id
        WHERE
            genre.name LIKE 'Rock')
ORDER BY email;

-- -----------------------------------------------------------------------
-- Write a query that returns the Artist name and total track count of the top 10 rock bands.

SELECT 
    track.composer AS 'Top 10 Artist',
    COUNT(track.composer) AS 'Total Track Count'
FROM
    track
WHERE
    genre_id = '1'
GROUP BY track.composer
ORDER BY COUNT(track.composer) DESC
LIMIT 10;

-- -----------------------------------------------------------------------
-- Write a query to return all the track names that have a song length longer than the average song length. Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.

SELECT 
    track.name AS 'Track Name',
    track.milliseconds AS 'Song Length in MIlliseconds'
FROM
    track
WHERE
    track.milliseconds > (SELECT 
            AVG(track.milliseconds)
        FROM
            track)
ORDER BY milliseconds DESC; 


-- -----------------------------------------------------------------------
-- Find how much amount spent by each customer on artists? 
-- Write a query to return customer name, artist name and total spent?

SELECT 
    customer.first_name AS 'Customer Name',
    artist.name AS 'Artist Name',
    invoice.total AS 'Total Amount Spent'
FROM
    customer
        JOIN
    invoice ON customer.customer_id = invoice.customer_id
        JOIN
    invoice_line ON invoice.invoice_id = invoice_line.invoice_id
        JOIN
    track ON invoice_line.track_id = track.track_id
        JOIN
    album2 ON track.album_id = album2.album_id
        JOIN
    artist ON album2.artist_id = artist.artist_id;
-- ------------------------
-- ---------------------------------
-- ------------------------------------
with best_selling_artist as (
SELECT 
    artist.artist_id AS artist_id,
    artist.name AS artist_name,
    SUM(invoice_line.unit_price * invoice_line.quantity) AS total_sales
FROM
    invoice_line
        JOIN
    track ON track.track_id = invoice_line.track_id
        JOIN
    album2 ON album2.album_id = track.album_id
        JOIN
    artist ON artist.artist_id = album2.artist_id
GROUP BY artist_id , artist_name
ORDER BY 3 DESC
LIMIT 1
)
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    bsa.artist_name,
    SUM(il.unit_price * il.quantity) AS amount_spent
FROM
    invoice i
        JOIN
    customer c ON c.customer_id = i.customer_id
        JOIN
    invoice_line il ON il.invoice_id = i.invoice_id
        JOIN
    track t ON t.track_id = il.track_id
        JOIN
    album2 alb ON alb.album_id = t.album_id
		join
        best_selling_artist bsa on bsa.artist_id = alb.artist_id
GROUP BY 1 , 2 , 3 , 4
ORDER BY 5 DESC;
-- ---------------------------------
-- ------------------------------------
-- -----------------------------------------------------------------------
-- Write a query that returns each country along with the top Genre. 
-- For countries where the maximum number of purchases is shared return all Genres.

with popular_genre as (
	select 
		count(invoice_line.quantity) as purchases, 
		customer.country, genre.name, genre.genre_id, 
		row_number() over(partition by customer.country 
	order by 
		count(invoice_line.quantity) desc) as RowNo 
	from 
		invoice_line 
			join 
		invoice on invoice.invoice_id = invoice_line.invoice_id 
			join 
		customer on customer.customer_id = invoice.customer_id 
			join 
		track on track.track_id = invoice_line.track_id 
			join 
		genre on genre.genre_id = track.genre_id 
	group by 2,3,4 
	order by 2 asc, 1 desc)
    
select 
	* 
from 
	popular_genre 
where RowNo <= 1;
-- ----------------------------------------
SELECT 
    invoice.billing_country, genre.name, SUM(total)
FROM
    invoice
        JOIN
    invoice_line ON invoice.invoice_id = invoice_line.invoice_id
        JOIN
    track ON invoice_line.track_id = track.track_id
        JOIN
    genre ON track.genre_id = genre.genre_id
GROUP BY invoice.billing_country , genre.name
ORDER BY invoice.billing_country DESC;
-- -----------------------------------------------

with recursive  sales_per_country As (select count(*) as purchases_per_genre, customer.country, genre.name, genre.genre_id from invoice_line join invoice on invoice.invoice_id = invoice_line.invoice_id join customer on customer.customer_id = invoice.customer_id join track on track.track_id = invoice_line.track_id  join genre on genre.genre_id = track.genre_id group by 2,3,4 order by 2),
max_genre_per_country as (select max(purchases_per_genre) as max_genre_number, country from sales_per_country group by 2 order by 2)
select sales_per_country.* from sales_per_country join max_genre_per_country on sales_per_country.country = max_genre_per_country.max_genre_number;


-- -----------------------------------------------------------------------
-- 3. Write a query that determines the customer that has spent the most on music for each country. Write a query that returns the country along with the top customer and how much they spent. For countries where the top amount spent is shared, provide all customers who spent this amount


with Customer_with_country as (
	select 
		customer.customer_id, first_name, last_name, 
		billing_country, sum(total) as total_spending, 
		row_number() over(partition by billing_country 
		order by sum(total) desc) as RowNo 
    from 
		invoice 
			join 
		customer on customer.customer_id = invoice.customer_id 
	group by 1,2,3,4 
    order by 4 asc, 5 desc) 
select 
	* 
from 
	customer_with_country where RowNo <= 1;