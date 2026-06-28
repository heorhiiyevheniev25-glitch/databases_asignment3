create or replace function calculate_order_total(p_order_id int)
returns numeric(10,2)
language plpgsql
as $$
declare
    v_total numeric(10,2);
begin
    select coalesce(sum(quantity * price), 0)
    into v_total
    from order_items
    where order_id = p_order_id;

    return v_total;
end;
$$;

create or replace procedure create_order(p_customer_id int)
language plpgsql
as $$
begin
    if not exists (
        select 1
        from customers
        where customer_id = p_customer_id
    ) then
        raise exception 'Customer with id % does not exist', p_customer_id;
    end if;

    insert into orders (customer_id, total_amount)
    values (p_customer_id, 0);
end;
$$;

create or replace procedure add_product_to_order(
    p_order_id int,
    p_product_id int,
    p_quantity int
)
language plpgsql
as $$
declare
    v_price numeric(10,2);
    v_stock int;
begin
    if p_quantity <= 0 then
        raise exception 'Quantity must be greater than zero';
    end if;

    if not exists (
        select 1
        from orders
        where order_id = p_order_id
    ) then
        raise exception 'Order with id % does not exist', p_order_id;
    end if;

    select price, stock_quantity
    into v_price, v_stock
    from products
    where product_id = p_product_id;

    if v_price is null then
        raise exception 'Product with id % does not exist', p_product_id;
    end if;

    if v_stock < p_quantity then
        raise exception 'Not enough stock for product id %. Available: %, requested: %',
            p_product_id, v_stock, p_quantity;
    end if;

    insert into order_items (order_id, product_id, quantity, price)
    values (p_order_id, p_product_id, p_quantity, v_price);

    update products
    set stock_quantity = stock_quantity - p_quantity
    where product_id = p_product_id;
end;
$$;

create or replace function update_order_total_trigger()
returns trigger
language plpgsql
as $$
declare
    v_order_id int;
begin
    if tg_op = 'DELETE' then
        v_order_id := old.order_id;
    else
        v_order_id := new.order_id;
    end if;
    update orders
    set total_amount = calculate_order_total(v_order_id)
    where order_id = v_order_id;

    return null;
end;
$$;

drop trigger if exists trg_update_order_total on order_items;
create trigger trg_update_order_total
after insert or update or delete
on order_items
for each row
execute function update_order_total_trigger();

create or replace function order_audit_log_trigger()
returns trigger
language plpgsql
as $$
begin
    insert into order_log (order_id, customer_id, action)
    values (new.order_id, new.customer_id, 'CREATE_ORDER');
    return new;
end;
$$;

drop trigger if exists trg_order_audit_log on orders;
create trigger trg_order_audit_log
after insert
on orders
for each row
execute function order_audit_log_trigger();