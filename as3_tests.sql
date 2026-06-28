select * from customers;
select * from products;

insert into customers (full_name, email, balance)
values ('super tip', 'supertip@gmail.com', 1000.00);


insert into products (product_name, price, stock_quantity)
values ('ultra thing', 50.00, 10);

select customer_id
from customers
where email = 'supertip@gmail.com';

call create_order(9);

select *
from orders
order by order_id desc
limit 1;

select *
from order_log
order by log_id desc
limit 1;

select product_id
from products
where product_name = 'ultra thing'
order by product_id desc
limit 1;

select order_id
from orders
order by order_id desc
limit 1;

call add_product_to_order(5, 10, 3);

select *
from order_items
where order_id = 5;

select
    order_id,
    total_amount,
    calculate_order_total(order_id) as calculated_total
from orders
where order_id = 5;

select *
from products
where product_id = 10;

call add_product_to_order(5, 10, 0);
call add_product_to_order(5, 10, 999999);
call create_order(999999);