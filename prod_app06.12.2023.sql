-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Dec 06, 2023 at 03:11 PM
-- Wersja serwera: 10.4.28-MariaDB
-- Wersja PHP: 8.0.28

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `prod_app`
--

DELIMITER $$
--
-- Procedury
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `add_item_to_basket` (IN `stock_id_in` BIGINT(20), IN `qty_in` INT(11), IN `user_id_in` BIGINT(20))   begin
    declare basket_id_in bigint(20);
    declare price_in double;
    declare exist_item int(11);
    declare qty_db int(11);

    select count(id) into exist_item
    from basket_items bi 
    where bi.stock_item_id = stock_id_in;

    select b.id  into basket_id_in
    from basket b 
    where b.customer_id = user_id_in;

    select s.PRICE into price_in
    from stockitem s  
    where s.ID = stock_id_in;


if exist_item = 0 then
     update basket b set b.reserved_stock_until = NOW() + INTERVAL 3 minute where b.id = basket_id_in;
     update basket b set reserved_stock = true where b.id = basket_id_in;
     INSERT INTO prod_app.basket_items (basket_id,stock_item_id,quantity,price)
     VALUES (basket_id_in,stock_id_in,qty_in,price_in);
 
end if;

if exist_item = 1 then
    
    select bi.quantity  into qty_db
    from basket_items bi 
    where bi.stock_item_id = stock_id_in;

    update basket_items bi set bi.quantity = qty_db + qty_in
    where bi.stock_item_id = stock_id_in;
    
end if;
end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_quantity_to_stock` (IN `mag_id` BIGINT(20), IN `prod_id` BIGINT(20), IN `qty_in` INT(11))   begin
	declare qty int(11);

	select QUANTITY
		into qty
		from stockitem  
		where MAGAZINE_ID = mag_id
		and PRODUCT_ID = prod_id;

	update stockitem 
		set QUANTITY = qty + qty_in
		where MAGAZINE_ID = mag_id
		and PRODUCT_ID = prod_id;
end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_reserved_qty_to_stock_item` (IN `stock_id_in` BIGINT(20), IN `qty_in` INT(11), IN `basket_id_in` BIGINT(20))   begin
    declare qty_in_stock int(11);
    declare reserved_qty_in int(11);
    declare reserved_bool bool;
    declare reserved_qty_item int(11);
    declare time_in timestamp;

    select b.reserved_stock
    into reserved_bool
    from basket b 
    where b.id = basket_id_in;

    select b.reserved_stock_until 
    into time_in
    from basket b 
    where b.id = basket_id_in; 

-- if reserved_bool = 1 then
    select QUANTITY  into qty_in_stock 
    from stockitem s 
    where s.ID = stock_id_in;

    select s.RESERVED_QUANTITY  into reserved_qty_in
    from stockitem s 
    where s.ID  = stock_id_in;

    select bi.reserved_qty  
    into reserved_qty_item
    from basket_items bi  
    where
    bi.basket_id  = basket_id_in
    and 
    bi.stock_item_id = stock_id_in;


    update basket_items bi 
    set bi.reserved_qty = reserved_qty_item + qty_in
    where 
    bi.basket_id  = basket_id_in
    and 
    bi.stock_item_id = stock_id_in;
    
    update stockitem si 
    set si.QUANTITY =  qty_in_stock - qty_in
    where si.ID = stock_id_in;

    update stockitem si 
    set si.RESERVED_QUANTITY  = reserved_qty_in + qty_in
    where si.ID = stock_id_in;

    update basket 
    set reserved_stock = true 
    where id = basket_id_in;
-- end if;
-- 
-- if reserved_bool = 0 then
--     select QUANTITY  into qty_in_stock 
--     from stockitem s 
--     where s.ID = stock_id_in;
-- 
--      update stockitem si 
--     set si.QUANTITY =  qty_in_stock - qty_in
--     where si.ID = stock_id_in;
-- end if;
end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_stock_item` (IN `mag_id` BIGINT(20), IN `prod_id` BIGINT(20))   begin
	INSERT INTO prod_app.stockitem (MAGAZINE_ID,PRODUCT_ID)
	VALUES (mag_id, prod_id);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_total_weight_to_basket` (IN `basket_id_in` BIGINT(20), IN `total_weight_in` INT(11))   begin
    
    update basket b  
    set b.total_weight = total_weight_in
    where b.id = basket_id_in;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `changeOrderStatus` (IN `order_id_in` BIGINT(20), IN `order_status_id` INT(11))   begin

declare picker bigint(20);
declare courier bigint(20);

select o.picker_id 
		into picker
		from orders o  
		where o.id  = order_id_in;
	
	select o.delivery_courier_id  
		into courier
		from orders o  
		where o.id  = order_id_in;

if courier is null && picker is not null && order_status_id = 3 then
	update orders o 
	set o.status = order_status_id 
	where o.id = order_id_in;

elseif courier is not null && picker is not null && order_status_id = 4 then
	update orders o 
	set o.status = order_status_id 
	where o.id = order_id_in;

elseif courier is  null && picker is  null && order_status_id = 1 then
	update orders o 
	set o.status =  order_status_id
	where o.id = order_id_in;
else
	SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'nieczekiwany błąd w procedurze changeOrderStatus';
end if;
end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `change_active` (IN `id_user` VARCHAR(10))   begin
	DECLARE status varchar(10);


	SELECT active
     INTO @status
     FROM users
    WHERE id = id_user;

   IF @status = '1' THEN UPDATE users 
      SET
      active = '0'
    WHERE id = id_user;

   ELSE UPDATE users 
      SET
      active = '1'
    WHERE id = id_user;

   END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `change_active_category` (IN `category_id_in` VARCHAR(10))   begin
declare  status            VARCHAR(10);
declare parent            VARCHAR(5);
declare check_if_parent   VARCHAR(5);

 SELECT is_active,
          parent_id
     INTO
      status,
      parent
     FROM categorytree
    WHERE id = category_id_in;

   IF parent IS NULL THEN IF status = 1 THEN
      UPDATE categorytree
         SET
         is_active = 0
       WHERE id = category_id_in;

      UPDATE categorytree
         SET
         is_active = 0
       WHERE parent_id = category_id_in;

   ELSE
      UPDATE categorytree
         SET
         is_active = 1
       WHERE id = category_id_in;

      UPDATE categorytree
         SET
         is_active = 1
       WHERE parent_id = category_id_in;

   END IF;

   END IF;

   IF parent IS NOT NULL THEN IF status = 1 THEN
      UPDATE categorytree
         SET
         is_active = 0
       WHERE id = category_id_in;

   ELSE 

      IF parent IS NULL THEN 
       UPDATE categorytree
         SET
         is_active = 1
       WHERE id = category_id_in;
      

      END IF;

      IF parent IS NOT NULL THEN
         SELECT is_active
           INTO check_if_parent
           FROM categorytree
          WHERE id = parent;

         IF check_if_parent = 1 THEN UPDATE categorytree
            SET
            is_active = 1
          WHERE id = category_id_in;

         END IF;

      END IF;

   END IF;
   END IF;

   COMMIT;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `change_close_store` (IN `mag_id` BIGINT(20))   begin
	update store set active = 0 where id = mag_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `change_mag_hours` (IN `open_from_in` VARCHAR(10), IN `open_to_in` VARCHAR(10), IN `store_id` VARCHAR(10))   begin
	update store 
	set OPEN_FROM = OPEN_FROM_IN
	where id = store_id;

	update store 
	set OPEN_TO  = OPEN_TO_IN
	where id = store_id;

commit;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `change_open_store` (IN `mag_id` BIGINT(20))   begin
	update store set active = 1 where id = mag_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `change_product_active` (IN `id_product` VARCHAR(10))   begin
	declare status VARCHAR(10);

 SELECT is_active
     INTO status
     FROM products
    WHERE id = id_product;

   IF status = 1 THEN UPDATE products
      SET
      is_active = 0
    WHERE id = id_product;

   ELSE UPDATE products
      SET
      is_active = 1
    WHERE id = id_product;

   END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `change_product_price` (IN `price_in` DOUBLE, IN `mag_id` BIGINT(20), IN `prod_id` BIGINT(20))   begin
	declare is_promo boolean;

select
    promo
into
    is_promo
from
    stockitem s
where
    MAGAZINE_ID = mag_id
    and PRODUCT_ID = prod_id;

if is_promo = true then
update
    stockitem
set
    price_before_promo = price_in
where
    MAGAZINE_ID = mag_id
    and PRODUCT_ID = prod_id;
else
update
    stockitem
set
    price = price_in
where
    MAGAZINE_ID = mag_id
    and PRODUCT_ID = prod_id;
end if;
end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `change_reserved_stock_bool_in_basket` (IN `basket_id_in` BIGINT(20))   begin
    update basket b  
    set b.reserved_stock = false 
    where b.id = basket_id_in;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `change_store_active` (IN `id_store` VARCHAR(11))   begin
	declare status VARCHAR(10);

SELECT active
     INTO status
     FROM store
    WHERE id = id_store;

   IF status = 1 THEN UPDATE store
      SET
      active = 0
    WHERE id = id_store;

   ELSE UPDATE store
      SET
      active = 1
    WHERE id = id_store;

   END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `change_temp_ava_store` (IN `id_store` VARCHAR(11))   begin
	declare status VARCHAR(10);

SELECT TEMPORARYAVAIABLE 
     INTO status
     FROM store
    WHERE id = id_store;

   IF status = 1 THEN UPDATE store
      SET
      TEMPORARYAVAIABLE = 0
    WHERE id = id_store;

   ELSE UPDATE store
      SET
      TEMPORARYAVAIABLE = 1
    WHERE id = id_store;

   END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `change_user_banned` (IN `user_id_in` BIGINT(20))   begin
	declare status VARCHAR(10);

SELECT is_banned 
     INTO status
     FROM users u 
    WHERE id = user_id_in;

   IF status = 1 THEN UPDATE users 
      SET
      is_banned = 0
    WHERE id = user_id_in;

   ELSE UPDATE users 
      SET
      is_banned = 1
    WHERE id = user_id_in;

   END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `clear_cart` (IN `basket_id_in` BIGINT(20))   begin
    
    delete from basket_items where basket_id = basket_id_in;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `clear_reservations` (IN `stock_id_in` BIGINT(20), IN `qty_in` INT(11), IN `basket_id_in` BIGINT(20))   begin
        declare
            qty_get int(11);
            select
                   s.QUANTITY
            into
                   qty_get
            from
                   stockitem s
            where
                   s.ID = stock_id_in
            ;
            
            update
                   basket_items bi
            set    reserved_qty = 0
            where
                   basket_id         = basket_id_in
                   and stock_item_id = stock_id_in
            ;
            
            update
                   stockitem si
            set    RESERVED_QUANTITY = 0
            where
                   si.ID = stock_id_in
            ;
            
            update
                   stockitem si
            set    QUANTITY = qty_get + qty_in
            where
                   si.ID = stock_id_in
            ;
            
            update
                   basket b
            set    b.reserved_stock = false
            where
                   b.id = basket_id_in
            ;
        
        END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `confirm_user` (IN `user_id_in` BIGINT(20), IN `user_email_in` VARCHAR(100), IN `user_phone_in` VARCHAR(20))   begin
    update users u 
    set u.ACTIVE = true 
    where u.ID = user_id_in
    and u.email = user_email_in
    and u.phone = user_phone_in;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteI_all_item_from_basket` (IN `basket_id_in` BIGINT(20))   begin
    delete from basket_items where basket_id = basket_id_in;
    update basket set total_weight = 0 where id = basket_id_in;
    update basket set reserved_stock = 0 where id = basket_id_in;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteUserAddress` (IN `address_id` BIGINT(20), IN `user_id` BIGINT(20))   begin
  delete from user_addresses where id = address_id
  and USER_ID = user_id;
  commit;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_photo` (IN `id_product` VARCHAR(10))   begin
	declare status VARCHAR(10);
   declare file varchar(10);
  
  SELECT photo
     INTO file
     FROM products
    WHERE id = id_product;

    UPDATE products 
    set photo = 1
    where id = id_product;

    delete from files
    where id = file;
    
    commit;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `minus_quantity_from_stock` (IN `mag_id` BIGINT(20), IN `prod_id` BIGINT(20), IN `qty_in` INT(11))   begin
	declare qty int(11);

	select QUANTITY
		into qty
		from stockitem  
		where MAGAZINE_ID = mag_id
		and PRODUCT_ID = prod_id;

	if qty_in > qty then
	SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Nie można zmniejszyc ilości produktu poniżej wartości 0';
		else
			update stockitem 
			set QUANTITY = qty - qty_in
			where MAGAZINE_ID = mag_id
			and PRODUCT_ID = prod_id;
	end if;
end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `remove_from_basket` (IN `stock_id_in` BIGINT(20), IN `qty_in` INT(11), IN `user_id_in` BIGINT(20))   begin
    declare basket_id_in bigint(20);
    declare qty_db int(11);


    select id 
    into basket_id_in
    from basket b 
    where b.customer_id = user_id_in;


    select quantity 
    into qty_db
    from basket_items
    where stock_item_id = stock_id_in
    and 
    basket_id = basket_id_in;

    if qty_db = 1 then
    delete from basket_items
    where 
    basket_id = basket_id_in
    and
    stock_item_id = stock_id_in;
    end if;

    if qty_db = 0 then
    delete from basket_items
    where 
    basket_id = basket_id_in
    and
    stock_item_id = stock_id_in;
    end if;

    if qty_db > 1 then
        update basket_items
        set quantity = qty_db - qty_in
        where 
         basket_id = basket_id_in
        and
        stock_item_id = stock_id_in;
    end if;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `remove_reserved_qty_to_stock_item` (IN `stock_id_in` BIGINT(20), IN `qty_in` INT(11), IN `basket_id_in` BIGINT(20))   begin
    declare qty_in_stock int(11);
    declare reserved_qty_in int(11);
    declare reserved_bool bool;
    declare item_exist int(11);
    declare reserved_qty_item int(11);

    select b.reserved_stock
    into reserved_bool
    from basket b 
    where b.id = basket_id_in;

    select count(*)
    into item_exist
    from
    basket_items bi 
    where 
    basket_id = basket_id_in
    and stock_item_id = stock_id_in;

    
if item_exist = 1 then

if reserved_bool = 1 then
    select QUANTITY  into qty_in_stock 
    from stockitem s 
    where s.ID = stock_id_in;

    select s.RESERVED_QUANTITY  into reserved_qty_in
    from stockitem s 
    where s.ID  = stock_id_in;

    select bi.reserved_qty  
    into reserved_qty_item
    from basket_items bi  
    where
    bi.basket_id  = basket_id_in
    and 
    bi.stock_item_id = stock_id_in;


    update basket_items bi 
    set bi.reserved_qty = reserved_qty_item - qty_in
    where 
    bi.basket_id  = basket_id_in
    and 
    bi.stock_item_id = stock_id_in;

    
    update stockitem si 
    set si.QUANTITY =  qty_in_stock + qty_in
    where si.ID = stock_id_in;

    update stockitem si 
    set si.RESERVED_QUANTITY  = reserved_qty_in - qty_in
    where si.ID = stock_id_in;
end if;

if reserved_bool = 0 then
    select QUANTITY  into qty_in_stock 
    from stockitem s 
    where s.ID = stock_id_in;

     update stockitem si 
    set si.QUANTITY =  qty_in_stock + qty_in
    where si.ID = stock_id_in;
end if;

    
end if;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `setAddressAndMagOnBasket` (IN `address_id_in` BIGINT(20), IN `user_id_in` BIGINT(20))   begin
    declare mag_p bigint(20);

declare basket_p bigint(20);

select
    mag_id
    into
    mag_p
from
    addresses a
where
    id = address_id_in;

select
    id
into
    basket_p
from
    basket
where
    customer_id = user_id_in;

update
    basket
set
    mag_id = mag_p
where
    id = basket_p;

update
    basket
set
    addresess_id = address_id_in
where
    id = basket_p;
end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `setting_promo_by_product` (IN `ds_in` BIGINT(20), IN `prod_in` BIGINT(20), IN `discount_price` DOUBLE)   begin
	declare is_promo boolean;

declare price_par double;

declare price_before double;

select
	promo
	into
	is_promo
from
	stockitem s
where 
	MAGAZINE_ID = ds_in
	and 
	PRODUCT_ID = prod_in;

if is_promo = false then

select
	price 
	into
	price_par
from
	stockitem s
where 
	MAGAZINE_ID = ds_in
	and 
	PRODUCT_ID = prod_in;

	

if price_par <= discount_price then
	SIGNAL SQLSTATE '45001'
      SET MESSAGE_TEXT = 'Cena promocyjna jest większa niż cena regularna';
     end if;

update
	stockitem
set
	price_before_promo = price_par
where 
	MAGAZINE_ID = ds_in
	and
	PRODUCT_ID = prod_in;

update
	stockitem
set
	price = discount_price
where 
	MAGAZINE_ID = ds_in
	and 
	PRODUCT_ID = prod_in;

update
	stockitem
set
	promo = true
where 
	MAGAZINE_ID = ds_in
	and 
	PRODUCT_ID = prod_in;

else
	select
	price_before_promo  
	into
	price_before
from
	stockitem s
where 
	MAGAZINE_ID = ds_in
	and 
	PRODUCT_ID = prod_in;

update
	stockitem
set
	price = price_before
where 
	MAGAZINE_ID = ds_in
	and 
	PRODUCT_ID = prod_in;

update
	stockitem
set
	price_before_promo = 0
where 
	MAGAZINE_ID = ds_in
	and 
	PRODUCT_ID = prod_in;

update
	stockitem
set
	promo = false
where 
	MAGAZINE_ID = ds_in
	and 
	PRODUCT_ID = prod_in;
end if;
end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `set_contractor_type` (IN `contractor_type_in` VARCHAR(10))   begin
	IF contractor_type_in = 1 THEN UPDATE contractor
      SET
      contractortype = 1
    WHERE contractortype IS NULL;

   END IF;

   IF contractor_type_in = 2 THEN UPDATE contractor
      SET
      contractortype = 2
    WHERE contractortype IS NULL;

   END IF;

   IF contractor_type_in >= 3 or contractor_type_in < 1 THEN ROLLBACK;
   END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `set_current_address` (IN `address_id_in` BIGINT(20), IN `user_id_in` BIGINT(20))   begin
	declare is_double_address int(11);
    
    call set_uncurrent_address(user_id_in);
   
  	select count(*)
  	into is_double_address 
  	from user_addresses
  	where ADDRESS_ID = address_id_in;
    
  if is_double_address = 1 then
  
  update user_addresses 
    set IS_CURRENT = true
    where 
    USER_ID = user_id_in
    and 
    ADDRESS_ID  = address_id_in;
   
   else
   update user_addresses 
    set IS_CURRENT = true
    where 
    USER_ID = user_id_in
    and 
    ADDRESS_ID  = address_id_in
   LIMIT 1;
  	
  end if;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `set_photo_in_product_table` (IN `id_product` VARCHAR(255), IN `photo_id` VARCHAR(255))   begin
	UPDATE products
      SET
      photo = photo_id
    WHERE id = id_product;

   COMMIT;
end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `set_product_artibute` (IN `cold_in` BOOLEAN, IN `hit_in` BOOLEAN, IN `new_in` BOOLEAN, IN `mag_in` BIGINT(20), IN `prod_in` BIGINT(20))   begin
    
    update stockitem 
    set COLD = cold_in
    where MAGAZINE_ID = mag_in
    and PRODUCT_ID = prod_in;

    update stockitem 
    set HIT = hit_in
    where MAGAZINE_ID = mag_in
    and PRODUCT_ID = prod_in;

    update stockitem 
    set NEW = new_in
    where MAGAZINE_ID = mag_in
    and PRODUCT_ID = prod_in;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `set_uncurrent_address` (IN `user_id_in` BIGINT(20))   begin

update user_addresses 
set IS_CURRENT = false 
where USER_ID  = user_id_in;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_order_status` (`order_id_in` BIGINT(20), `status_in` INT(11))   begin
	update orders set status = status_in where id = order_id_in;
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `anti_duplicate_address` (`street_in` VARCHAR(50), `street_number_in` VARCHAR(50), `door_number_in` VARCHAR(50), `city_in` VARCHAR(100)) RETURNS BIGINT(11)  begin
	declare id_out INT;

declare count_address int(11);

declare id_out_defoult INT;

select
    COUNT(*)
     into
    count_address
from
    addresses
where
    street = street_in
    and street_number = street_number_in
    and door_number = door_number_in
    and city = city_in;

if count_address = 1 then
select
    id
                              into
    id_out
from
    addresses
where
    street = street_in
    and street_number = street_number_in
    and door_number = door_number_in
    and CITY = city_in;

return id_out;
else 
return 0;
end if;
end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `anti_duplicate_user_address` (`address_in` BIGINT(20), `user_in` BIGINT(20)) RETURNS TINYINT(1)  begin
declare count_in int(11);

select
    COUNT(*)
     into count_in
from
    user_addresses 
where 
    ADDRESS_ID = address_in
    and 
    USER_ID = user_in;

if count_in = 0 then
return false;
else 
    return true;
end if;
end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `change_mag` (`basket_id_in` BIGINT(20), `item_basket_id_in` BIGINT(20), `address_id_in` BIGINT(20)) RETURNS INT(11)  begin
    declare value_out int(11);
    declare product_id_in bigint(20);
    declare mag_id_param bigint(20);
    declare count_product_is_avaiable int(11);
    declare new_qty int(11);
    declare old_qty int(11);
    declare basket_reservation_param tinyint(1);
    declare stock_id_param bigint(20);
    declare new_stock_id bigint(20);
    declare reserved_qty_pqram int(11);
    declare basket_item_qty bigint(20);
    declare stock_item_id bigint(20);
    declare stock_item_qty bigint(20);

--     pobierz id produktu
select 
p.ID 
into product_id_in
from basket_items bi 
join stockitem s 
on bi.stock_item_id = s.ID 
join products p 
on s.PRODUCT_ID = p.ID 
where 
bi.id = item_basket_id_in;

select 
s.ID 
into stock_id_param
from basket_items bi 
join stockitem s 
on bi.stock_item_id = s.ID 
join products p 
on s.PRODUCT_ID = p.ID 
where 
bi.id = item_basket_id_in;

-- pobierz magazyn dla nowego adresu
select MAG_ID  
into mag_id_param
from addresses a 
where ID = address_id_in;

select count(*)
into count_product_is_avaiable
from stockitem s 
where PRODUCT_ID = product_id_in
and MAGAZINE_ID = mag_id_param
and QUANTITY > 0;

    select bi.reserved_qty  
    into reserved_qty_pqram
    from basket_items bi 
    where bi.id = item_basket_id_in;


        select reserved_stock 
    into basket_reservation_param
    from basket b 
    where b.id  = basket_id_in;


-- jesli istnieje stock dla produktu w magazynie
if count_product_is_avaiable = 1 then
-- pobierz qty z nowego mag
    select
    QUANTITY 
    into
    new_qty
from
    stockitem s
where
    PRODUCT_ID = product_id_in
    and MAGAZINE_ID = mag_id_param;

-- pobierz qty ze starego magazynu
    select QUANTITY 
    into old_qty
    from basket_items bi 
    where bi.id = item_basket_id_in;

    
    
-- jesli qty z nowego jest wieksze badz rowne qty ze starego
    if new_qty >= old_qty then
 
         if basket_reservation_param = 1 then
        -- jesli ma to ja usun przez procedure clear_reservations
         call clear_reservations(stock_id_param, reserved_qty_pqram, basket_id_in);
         end if;

     -- update basketitem : ustaw nowy stock_item_id
     -- pobierz nowy stock id dla nowego magazynu
     select ID
     into new_stock_id
     from 
     stockitem s
     where s.MAGAZINE_ID = mag_id_param
     and PRODUCT_ID = product_id_in;
     
     -- update basket item ustaw nowy stock item 
     update basket_items 
     set stock_item_id = new_stock_id 
     where id = item_basket_id_in;
 -- zmień adres na nowy w basket
    update basket 
    set addresess_id = address_id_in
    where id = basket_id_in;
 -- zmien magazyn na nowy w basket
    update basket 
    set mag_id = mag_id_param
    where id = basket_id_in;
     select 1
     into value_out
     from dual;
    
--     pobierac qty z tabeli basket_item oraz stock item id 
-- i w tabeli stock item odejmowac od qty pobrane qty z tabeli basket item 
    
    
       select QUANTITY 
    into basket_item_qty 
    from stockitem sd 
    where sd.ID = (select bi.stock_item_id  from  basket_items bi where bi.basket_id = basket_id_in);
   
    select bi.stock_item_id into stock_item_id from  basket_items bi where bi.basket_id = basket_id_in;
   
    select s.QUANTITY  into stock_item_qty from  stockitem s  where s.ID  = stock_item_id;
   
   update
   stockitem ss set QUANTITY = stock_item_qty - basket_item_qty 
   where ss.ID = stock_item_id;
   
   
    end if; 
   

   
--    pobrac aktualny stan z tabeli stockitem i od tego stanu odjac basket_item_qty , wynik zapisac w stockitem pole qty

    if  new_qty < old_qty then
     if basket_reservation_param = 1 then
        -- jesli ma to ja usun przez procedure clear_reservations
         call clear_reservations(stock_id_param, reserved_qty_pqram, basket_id_in);
         end if;
--      dorobic obsluge przeniesienia mniejszej ilosci
--      narazie jest usuwane ale w przyszlosci dorobic przeniesienie mniejszej ilosci
      delete from basket_items
    where id = item_basket_id_in
    and basket_id = basket_id_in;
         select 3
        into value_out
        from dual;
    end if;

 
 end if;
 if count_product_is_avaiable = 0 then
     if basket_reservation_param = 1 then
        -- jesli ma to ja usun przez procedure clear_reservations
         call clear_reservations(stock_id_param, reserved_qty_pqram, basket_id_in);
         end if;
    delete from basket_items
    where id = item_basket_id_in
    and basket_id = basket_id_in;

         select 3
         into value_out
         from dual;  
 end if;
 
 return value_out;
 end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `check_active_orders` (`user_id_in` BIGINT(20)) RETURNS INT(11)  begin
    declare order_count int(11);

SELECT COUNT(*)
     INTO order_count
     FROM orders o  
     where o.status <> 7
     and o.customer_id = user_id_in;
   RETURN order_count;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_lat_from_address` (`basket_id_in` BIGINT(20)) RETURNS VARCHAR(100) CHARSET utf8mb4 COLLATE utf8mb4_general_ci  begin
    declare long_out varchar(100);
    
    
    select a.LATIDUTE
    into long_out
    from 
basket b  
join store s 
on b.mag_id = s.ID 
join addresses a 
on s.ADDRESS = a.ID 
where b.id = basket_id_in;
    return long_out;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_long_from_address` (`basket_id_in` BIGINT(20)) RETURNS VARCHAR(100) CHARSET utf8mb4 COLLATE utf8mb4_general_ci  begin
    declare long_out varchar(100);
    
    
    select a.LONGTITIUDE
    into long_out
    from 
basket b  
join store s 
on b.mag_id = s.ID 
join addresses a 
on s.ADDRESS = a.ID 
where b.id = basket_id_in;
    return long_out;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_mag_by_basket_id` (`user_id_in` BIGINT(20)) RETURNS BIGINT(20)  begin
    declare mag_id_out bigint(20);

    select mag_id
    into mag_id_out
    from basket b 
    where customer_id = user_id_in;

    return mag_id_out;
end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `give_count_active_employee` () RETURNS INT(11)  begin
	declare count_employee_active INT;

SELECT COUNT(*)
        INTO count_employee_active
        FROM Employee
       WHERE ACTIVE = 'T';

      RETURN count_employee_active;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `give_count_employee` () RETURNS INT(11)  begin
	declare employee_count int;

SELECT COUNT(*)
     INTO employee_count
     FROM Employee;
   RETURN employee_count;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `addresses`
--

CREATE TABLE `addresses` (
  `ID` bigint(20) NOT NULL,
  `STREET` varchar(100) NOT NULL,
  `STREET_NUMBER` varchar(100) NOT NULL,
  `DOOR_NUMBER` varchar(100) DEFAULT NULL,
  `FLOR` varchar(20) DEFAULT NULL,
  `LATIDUTE` varchar(100) DEFAULT NULL,
  `LONGTITIUDE` varchar(100) DEFAULT NULL,
  `POSTAL_CODE` varchar(20) DEFAULT NULL,
  `MESSAGE` varchar(100) DEFAULT NULL,
  `CITY` varchar(100) NOT NULL,
  `MAG_ID` bigint(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `addresses`
--

INSERT INTO `addresses` (`ID`, `STREET`, `STREET_NUMBER`, `DOOR_NUMBER`, `FLOR`, `LATIDUTE`, `LONGTITIUDE`, `POSTAL_CODE`, `MESSAGE`, `CITY`, `MAG_ID`) VALUES
(1, 'Ogrodowa', '9', 'null', NULL, '52.2437429', '19.35306984524314', '99-300', 'domyślny magazyn', 'Kutno', 1),
(2, 'Władysława łokietka', '15', '12', NULL, '52.2271539', '19.3818665', '99-300', 'magazyn 2', 'Kutno', 2),
(23, 'Papieża Jana Pawła II', '5', '21', '1', '52.229642', '19.363749', '99-300', 'kod do domofonu #1234', 'Kutno', 2),
(24, 'Bolesława Chrobrego', '18', '21', '3', '52.2283293', '19.3741678', '99-300', 'kod do domofonu #1234', 'Kutno', 2),
(25, 'Ogrodowa', '11', 'null', NULL, '52.2429757', '19.3525023', '99-300', 'kod do domofonu #1234', 'Kutno', 1),
(26, 'Olimpijska', '6', '20', '3', '52.23427795', '19.37163385269215', '99-300', 'kod do domofonu #1234', 'Kutno', 2),
(27, 'Władysława Lokietka ', '3', '25', '2', '52.22646175', '19.380672430856414', '99-300', 'test ', 'kutno', 2),
(28, 'Ogrodowa', '9', '23', '2', '52.2437429', '19.35306984524314', '99-300', 'test', 'kutno', 1),
(29, 'Ogrodowa', '11', '11', '2', '52.2429757', '19.3525023', '99-300', 'kod do domofonu #1234', 'Kutno', 1),
(30, 'Ogrodowa', '9', '11', '2', '52.2437429', '19.35306984524314', '99-300', 'test', 'Kutno', 1),
(31, 'Bolesława Chrobrego ', '16', '', '', '52.2283293', '19.3741678', '99-300', '', 'kutno ', 2),
(32, 'Ogrodowa', '11', '', '', '52.2429757', '19.3525023', '99-300', '', 'Kutno', 1),
(33, 'Ogrodowa ', '9', '', '', '52.2437429', '19.35306984524314', '99-300', '', 'Kutno ', 1),
(34, 'Oporowska', '9', '25', '2', '52.233657750000006', '19.370697097451288', '99-300', '', 'Kutno', 2),
(35, 'Oporowska ', '9', '36', '', '52.233657750000006', '19.370697097451288', '99-300 ', '', 'Kutno ', 2),
(36, 'Oporowska ', '9', '69', '', '52.233657750000006', '19.370697097451288', '99-300', '', 'Kutno ', 2),
(37, 'Oporowska ', '9', '65', '', '52.233657750000006', '19.370697097451288', '99-300', '', 'Kutno ', 2),
(38, 'Oporowska ', '9', '6', '', '52.233657750000006', '19.370697097451288', '99-300', '', 'Kutno', 2),
(39, 'Oporowska ', '9', '58', '', '52.233657750000006', '19.370697097451288', '99-300', '', 'Kutno ', 2),
(40, 'Władysława Jagiełły ', '6', '25', '', '52.2260577', '19.37704461230836', '99-300', '', 'Kutno ', 2),
(41, 'Bolesława Chrobrego ', '18', '22', '', '52.2283293', '19.3741678', '99-300', '', 'Kutno', 2),
(42, 'Sienkiewicza ', '9', '3', '', '52.23101805', '19.355402960599665', '99-300', 'wejście od podwórza', 'Kutno', 1);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `basket`
--

CREATE TABLE `basket` (
  `id` bigint(20) NOT NULL,
  `customer_id` bigint(20) DEFAULT NULL,
  `addresess_id` bigint(20) DEFAULT NULL,
  `mag_id` bigint(20) DEFAULT 3,
  `ordered` tinyint(1) NOT NULL DEFAULT 0,
  `order_id` bigint(20) DEFAULT NULL,
  `reserved_stock` tinyint(1) DEFAULT 0,
  `reserved_stock_until` timestamp NULL DEFAULT NULL,
  `distanse` varchar(100) DEFAULT NULL,
  `total_weight` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `basket`
--

INSERT INTO `basket` (`id`, `customer_id`, `addresess_id`, `mag_id`, `ordered`, `order_id`, `reserved_stock`, `reserved_stock_until`, `distanse`, `total_weight`) VALUES
(18, 15, 42, 1, 0, 132, 0, '2023-11-15 19:22:03', '0', 0),
(20, 28, NULL, 3, 0, NULL, 0, '2023-04-04 18:15:53', '0', 0),
(28, 30, 40, 2, 0, NULL, 0, '2023-05-11 04:41:51', '0', 0),
(30, 44, NULL, 3, 0, NULL, 0, '2023-05-02 17:08:14', '0', 0),
(31, 45, NULL, 3, 0, NULL, 0, '2023-05-02 17:10:05', '0', 0),
(32, 53, NULL, 3, 0, NULL, 0, '2023-05-04 07:31:17', '0', 0),
(33, 58, NULL, 3, 0, NULL, 0, '2023-05-07 10:37:09', '0', 0);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `basket_items`
--

CREATE TABLE `basket_items` (
  `id` bigint(20) NOT NULL,
  `basket_id` bigint(20) DEFAULT NULL,
  `stock_item_id` bigint(20) DEFAULT NULL,
  `quantity` int(11) DEFAULT NULL,
  `price` double DEFAULT NULL,
  `reserved_qty` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Zastąpiona struktura widoku `basket_item_view`
-- (See below for the actual view)
--
CREATE TABLE `basket_item_view` (
`basket_id` bigint(20)
,`stock_item_id` bigint(20)
,`quantity` int(11)
,`PRICE` double
,`RESERVED_QUANTITY` int(11)
,`ID` bigint(20)
,`WEIGHT` int(11)
,`Image` varchar(300)
,`NAME` varchar(100)
,`DESCRIPTION` varchar(100)
,`PRICE_BEFORE_PROMO` double
,`quantity_on_stock` int(11)
);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `categorytree`
--

CREATE TABLE `categorytree` (
  `ID` bigint(20) NOT NULL,
  `NAME` varchar(100) NOT NULL,
  `PARENT_ID` int(11) DEFAULT NULL,
  `IS_ACTIVE` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `categorytree`
--

INSERT INTO `categorytree` (`ID`, `NAME`, `PARENT_ID`, `IS_ACTIVE`) VALUES
(10, 'Woda', NULL, 0),
(11, 'Woda gazowana', 10, 1),
(12, 'Woda niegazowana', 10, 1),
(13, 'Pieczywo', NULL, 1),
(14, 'Bułki', 13, 1),
(15, 'Strefa Zero', NULL, 1),
(16, 'Promocje', NULL, 1),
(17, 'Nowości', NULL, 1),
(18, 'Wyprzedaż', NULL, 1),
(19, 'Do kanapki', NULL, 1),
(20, 'Owoce i warzywa', NULL, 1),
(21, 'Śniadaniowe', NULL, 1),
(22, 'Lody', NULL, 1),
(23, 'Słodycze', NULL, 1),
(24, 'Przekąski i bakalie', NULL, 1),
(25, 'Nabiał i sery', NULL, 1),
(26, 'Napoje ', NULL, 1),
(27, 'Energetyki', NULL, 1),
(28, 'Jogurty i desery', NULL, 1),
(29, 'Mięso i ryby', NULL, 1),
(30, 'Wędliny i kiełbasy', NULL, 1),
(31, 'Dania gotowe', NULL, 1),
(32, 'Spiżarnia', NULL, 1),
(33, 'Produkty sypkie', NULL, 1),
(34, 'Oleje, sosy i dressingi', NULL, 1),
(35, 'Przyprawy', NULL, 1),
(36, 'Kawa i herbata', NULL, 1),
(37, 'Deser zrób to sam', NULL, 1),
(38, 'Chemia do domu', NULL, 1),
(39, 'Drogeria', NULL, 1),
(40, 'Zwierzaki', NULL, 1),
(51, 'string', 0, 0),
(56, 'XXX', NULL, 0);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `contractor`
--

CREATE TABLE `contractor` (
  `ID` bigint(20) NOT NULL,
  `NAME` varchar(100) NOT NULL,
  `ADDRESS` varchar(100) NOT NULL,
  `CITY` varchar(100) NOT NULL,
  `POSTALCODE` varchar(100) NOT NULL,
  `PHONE` varchar(20) NOT NULL,
  `NIP` varchar(100) NOT NULL,
  `EMAIL` varchar(100) NOT NULL,
  `CONTRACTORTYPE` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `contractor`
--

INSERT INTO `contractor` (`ID`, `NAME`, `ADDRESS`, `CITY`, `POSTALCODE`, `PHONE`, `NIP`, `EMAIL`, `CONTRACTORTYPE`) VALUES
(3, 'testExcel1', 'adres testowy excel', 'Kutno', '99-300', '697-568-386', '123-456-12-23', 'szydlowskiptr@gmail.com', 1),
(4, 'testExcel2', 'asd', 'asd', 'sad', '147-258-369', '610-420-11-44', 'saffdd@sdf.pl', 1);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `contractor_type`
--

CREATE TABLE `contractor_type` (
  `ID` int(11) NOT NULL,
  `TYPE` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `contractor_type`
--

INSERT INTO `contractor_type` (`ID`, `TYPE`) VALUES
(1, 'dostawca'),
(2, 'odbiorca');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `files`
--

CREATE TABLE `files` (
  `ID` bigint(20) NOT NULL,
  `FILENAME` varchar(100) DEFAULT NULL,
  `FILETYPE` varchar(100) DEFAULT NULL,
  `DATA` longblob DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Zastąpiona struktura widoku `min_qty_stock`
-- (See below for the actual view)
--
CREATE TABLE `min_qty_stock` (
`ID` bigint(20)
,`MAGAZINE_ID` bigint(20)
,`PRODUCT_ID` bigint(20)
,`QUANTITY` int(11)
);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `orders`
--

CREATE TABLE `orders` (
  `id` bigint(20) NOT NULL,
  `amount` float DEFAULT 0,
  `customer_id` bigint(20) NOT NULL,
  `picker_id` bigint(20) DEFAULT NULL,
  `delivery_courier_id` bigint(20) DEFAULT NULL,
  `delivery_cost` float NOT NULL,
  `discount` float NOT NULL DEFAULT 0,
  `address_id` bigint(20) NOT NULL,
  `mag_id` bigint(20) NOT NULL,
  `status` int(11) DEFAULT 0,
  `payment_status` int(11) DEFAULT NULL,
  `slient_delivery` tinyint(1) NOT NULL DEFAULT 0,
  `message` varchar(400) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`id`, `amount`, `customer_id`, `picker_id`, `delivery_courier_id`, `delivery_cost`, `discount`, `address_id`, `mag_id`, `status`, `payment_status`, `slient_delivery`, `message`) VALUES
(131, 10.46, 15, 3, 3, 5.99, 0, 46, 1, 7, 0, 0, ''),
(132, 11.34, 15, NULL, NULL, 5.99, 0, 46, 1, 1, 0, 0, '');

--
-- Wyzwalacze `orders`
--
DELIMITER $$
CREATE TRIGGER `set_order_id_in_basket` AFTER INSERT ON `orders` FOR EACH ROW BEGIN 
    update basket set order_id = new .id  where customer_id = new .customer_id ;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `order_items`
--

CREATE TABLE `order_items` (
  `id` bigint(20) NOT NULL,
  `price` double DEFAULT NULL,
  `quantity` int(11) DEFAULT NULL,
  `order_id` bigint(20) DEFAULT NULL,
  `stock_item_id` bigint(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `order_items`
--

INSERT INTO `order_items` (`id`, `price`, `quantity`, `order_id`, `stock_item_id`) VALUES
(23, 0.76, 1, 42, 13),
(24, 12.98, 1, 42, 19),
(25, 3.68, 5, 43, 17),
(26, 0.76, 1, 43, 13),
(27, 3.68, 3, 44, 17),
(28, 3.68, 1, 45, 17),
(29, 0.76, 1, 45, 13),
(30, 0.76, 2, 46, 13),
(31, 3.68, 1, 46, 17),
(32, 3.68, 2, 47, 17),
(33, 3.68, 1, 48, 17),
(34, 3.68, 1, 49, 17),
(35, 3.68, 2, 50, 17),
(36, 3.68, 1, 51, 17),
(37, 4.99, 1, 52, 22),
(38, 3.68, 1, 52, 17),
(39, 3.68, 1, 53, 17),
(40, 3.68, 1, 54, 17),
(41, 3.68, 1, 55, 17),
(42, 3.68, 1, 56, 17),
(43, 3.68, 1, 57, 17),
(44, 0.76, 1, 58, 13),
(45, 3.68, 1, 58, 17),
(46, 2.32, 1, 59, 11),
(47, 2.32, 2, 60, 11),
(48, 0.76, 5, 61, 13),
(49, 0.76, 1, 62, 13),
(50, 0.76, 1, 63, 13),
(51, 0.76, 1, 64, 13),
(52, 0.76, 1, 65, 13),
(53, 0.76, 1, 66, 13),
(54, 0.76, 1, 67, 13),
(55, 2.32, 1, 68, 11),
(56, 0.76, 1, 68, 13),
(57, 0.76, 1, 69, 13),
(58, 2.32, 1, 69, 11),
(59, 0.76, 1, 70, 13),
(60, 0.76, 1, 71, 13),
(61, 3.68, 1, 71, 17),
(62, 3.68, 2, 72, 17),
(63, 4.99, 1, 73, 20),
(64, 3.68, 1, 73, 17),
(71, 4.99, 1, 85, 20),
(72, 0.76, 2, 85, 13),
(73, 2.32, 1, 85, 11),
(74, 0.76, 4, 86, 13),
(75, 1.65, 1, 86, 19),
(76, 0.76, 1, 87, 13),
(77, 3.68, 1, 87, 17),
(78, 4.99, 1, 88, 20),
(79, 3.68, 1, 88, 17),
(80, 0.76, 1, 88, 13),
(81, 3.68, 1, 89, 17),
(82, 0.76, 1, 90, 13),
(83, 0.76, 1, 91, 13),
(84, 0.76, 1, 92, 13),
(85, 0.76, 1, 93, 13),
(86, 0, 1, 94, 23),
(87, 0, 1, 95, 23),
(88, 0, 1, 95, 18),
(89, 0, 1, 96, 18),
(90, 0, 1, 96, 23),
(91, 0, 1, 96, 27),
(92, 3.68, 3, 97, 17),
(93, 0.76, 1, 97, 13),
(94, 2.32, 1, 98, 11),
(95, 3.68, 1, 98, 17),
(96, 1.65, 1, 98, 19),
(97, 3.49, 1, 98, 30),
(98, 0.76, 2, 99, 13),
(99, 3.68, 2, 99, 17),
(100, 0.76, 1, 100, 13),
(101, 2.32, 1, 101, 11),
(102, 0.76, 1, 101, 13),
(103, 0.76, 1, 102, 13),
(104, 2.32, 1, 103, 11),
(105, 0.76, 1, 103, 13),
(106, 2.32, 1, 104, 11),
(107, 0.76, 1, 104, 13),
(108, 2.32, 1, 105, 11),
(109, 0.76, 1, 105, 13),
(110, 0.76, 1, 106, 13),
(111, 0.76, 1, 107, 13),
(112, 2.32, 3, 108, 11),
(113, 2.32, 1, 109, 11),
(114, 2.32, 1, 110, 11),
(115, 2.32, 1, 111, 11),
(116, 2.32, 1, 112, 11),
(117, 2.32, 1, 113, 11),
(118, 2.32, 1, 114, 11),
(119, 2.32, 1, 115, 11),
(120, 2.32, 1, 116, 11),
(121, 2.32, 1, 117, 11),
(122, 2.32, 1, 118, 11),
(123, 0.76, 1, 119, 13),
(124, 3.68, 1, 119, 17),
(125, 2.32, 1, 119, 11),
(135, 3.68, 1, 129, 17),
(137, 3.68, 1, 131, 17),
(138, 0.76, 6, 132, 13);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `products`
--

CREATE TABLE `products` (
  `ID` bigint(20) NOT NULL,
  `EAN` varchar(20) NOT NULL,
  `UNIT` bigint(20) DEFAULT NULL,
  `IS_ACTIVE` tinyint(1) NOT NULL DEFAULT 0,
  `CATEGORY` bigint(20) DEFAULT NULL,
  `NAME` varchar(100) NOT NULL,
  `DESCRIPTION` varchar(100) DEFAULT NULL,
  `SUBCATEGORY` bigint(20) DEFAULT NULL,
  `PHOTO` bigint(20) DEFAULT 1,
  `WEIGHT` int(11) DEFAULT 0,
  `Image` varchar(300) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `products`
--

INSERT INTO `products` (`ID`, `EAN`, `UNIT`, `IS_ACTIVE`, `CATEGORY`, `NAME`, `DESCRIPTION`, `SUBCATEGORY`, `PHOTO`, `WEIGHT`, `Image`) VALUES
(12, '5902078000201', 1, 1, 10, 'Cisowianka', 'woda niegazowana 1,5l', 12, 13, 1500, 'https://res.cloudinary.com/kep/image/upload/v1680428040/cisowianka_hajsz6.png'),
(13, '856230012031', 1, 1, 10, 'Kropla Beskidu', 'Woda gazowana 1,5l', 11, 14, 1500, 'https://res.cloudinary.com/kep/image/upload/v1680428040/kropla_unfeik.png'),
(14, '85210300120', 1, 1, 13, 'Bułka Kajzerka', 'Putka 55g', 14, 15, 55, 'https://res.cloudinary.com/kep/image/upload/v1680428040/kajzerka_ywcaxd.png'),
(16, '65210300', 1, 1, 10, 'Alcalia', 'woda niegazowana 1,5l', 12, 16, 1500, 'https://res.cloudinary.com/kep/image/upload/v1680428040/alcalia_tbuiid.png'),
(17, '854210030210', 1, 1, 27, 'Monster', 'Ultra Paradise', NULL, 1, 500, 'https://res.cloudinary.com/kep/image/upload/v1680429588/monster_gxixvw.png'),
(18, '52310200', 1, 1, 24, 'Lajkonik ', 'Junior buźki', NULL, 1, 90, 'https://res.cloudinary.com/kep/image/upload/v1680429873/lajkonik_junior_buzki_ecgqff.png'),
(19, '85421032000', 1, 1, 36, 'Lipton ', ' herbata granulowana', NULL, 1, 100, 'https://res.cloudinary.com/kep/image/upload/v1680430105/lipton_wxdmxl.png'),
(21, '854722410365', 1, 1, 21, 'Lisner', 'pasta z tuńczyka', NULL, 1, 80, 'https://res.cloudinary.com/kep/image/upload/v1680430374/lisner_pasta_tunczyk_svrtrm.png'),
(22, '8542104120322', 1, 1, 17, 'PROSTE HISTORIE', 'Owoce lasów i sadów', NULL, 1, 280, 'https://res.cloudinary.com/kep/image/upload/v1680435897/proste_historie_owoce_lasu_vvhnyz.png'),
(23, '564515156415', 1, 1, 17, 'Napój jogurtowy', 'banan-truskawka Jovi-Duet', NULL, 1, 350, 'https://res.cloudinary.com/kep/image/upload/v1680436201/napoj_jogurtowy_flweuy.png'),
(24, '5645215265156', 1, 1, 17, 'Śmietanka UHT', 'ŁOWICZ 36%', NULL, 1, 500, 'https://res.cloudinary.com/kep/image/upload/v1680436444/smietanka_lowicz_lyda0y.png'),
(25, '5451515', 1, 1, 17, 'Whiskas saszetki', 'Łosoś Sos', NULL, 1, 85, 'https://res.cloudinary.com/kep/image/upload/v1680436737/whiskas_pnw6ze.png');

-- --------------------------------------------------------

--
-- Zastąpiona struktura widoku `reserved_qty_to_unlock_view`
-- (See below for the actual view)
--
CREATE TABLE `reserved_qty_to_unlock_view` (
`basket_id` bigint(20)
,`basket_item_id` bigint(20)
,`stock_item_id` bigint(20)
,`quantity` int(11)
,`reserved_qty` int(11)
);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `settings`
--

CREATE TABLE `settings` (
  `ID` bigint(20) NOT NULL,
  `SETTING_NAME` varchar(100) NOT NULL,
  `SETTING_VALUE` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `settings`
--

INSERT INTO `settings` (`ID`, `SETTING_NAME`, `SETTING_VALUE`) VALUES
(1, 'dostawa', '5.99'),
(2, 'max_waga_koszyka', '10000'),
(3, 'cena_opakowania', '0.79'),
(4, 'min_qty', '15');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `sliders`
--

CREATE TABLE `sliders` (
  `id` bigint(20) NOT NULL,
  `url` varchar(100) NOT NULL,
  `mag_id` bigint(20) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `sliders`
--

INSERT INTO `sliders` (`id`, `url`, `mag_id`) VALUES
(1, 'https://res.cloudinary.com/kep/image/upload/v1680638736/banner_details_hdevjs.png', 0),
(2, 'https://res.cloudinary.com/kep/image/upload/v1680638823/banner1_j3ypyd.jpg', 0),
(3, 'https://res.cloudinary.com/kep/image/upload/v1680638850/banner2_wfesu5.png', 0),
(4, 'https://res.cloudinary.com/kep/image/upload/v1680638878/banner3_qqi4mg.jpg', 0);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `stockitem`
--

CREATE TABLE `stockitem` (
  `ID` bigint(20) NOT NULL,
  `MAGAZINE_ID` bigint(20) NOT NULL,
  `PRODUCT_ID` bigint(20) NOT NULL,
  `QUANTITY` int(11) DEFAULT 0,
  `PRICE` double DEFAULT 0,
  `NEW` tinyint(1) DEFAULT 0,
  `HIT` tinyint(1) DEFAULT 0,
  `PROMO` tinyint(1) DEFAULT 0,
  `COLD` tinyint(1) DEFAULT 0,
  `ACTIVE` tinyint(1) DEFAULT 0,
  `RESERVED_QUANTITY` int(11) DEFAULT 0,
  `PRICE_BEFORE_PROMO` double DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `stockitem`
--

INSERT INTO `stockitem` (`ID`, `MAGAZINE_ID`, `PRODUCT_ID`, `QUANTITY`, `PRICE`, `NEW`, `HIT`, `PROMO`, `COLD`, `ACTIVE`, `RESERVED_QUANTITY`, `PRICE_BEFORE_PROMO`) VALUES
(11, 1, 13, 0, 2.32, 0, 0, 1, 0, 0, 0, 2.99),
(13, 1, 14, 4, 0.76, 0, 0, 1, 0, 0, 0, 0.99),
(14, 2, 14, 100, 1.98, 0, 1, 0, 0, 0, 0, 0),
(17, 1, 16, 0, 3.68, 0, 0, 1, 0, 0, 0, 0),
(18, 2, 16, 0, 2.36, 0, 1, 0, 0, 0, 0, 0),
(19, 1, 12, 101, 1.65, 0, 1, 0, 1, 0, 0, 0),
(20, 1, 17, 0, 4.99, 0, 1, 0, 0, 0, 0, 0),
(21, 2, 17, 50, 4.99, 1, 0, 0, 0, 0, 2, 0),
(22, 1, 18, 0, 4.99, 0, 1, 0, 0, 0, 0, 0),
(23, 2, 18, 129, 0, 0, 0, 1, 0, 0, 0, 0),
(24, 1, 19, 22, 5.99, 0, 1, 0, 0, 0, 0, 0),
(25, 2, 19, 97, 0, 0, 0, 1, 0, 0, 0, 0),
(26, 1, 21, 0, 3.49, 0, 1, 0, 0, 0, 0, 0),
(27, 2, 21, 96, 0, 0, 1, 0, 0, 0, 0, 0),
(28, 1, 22, 0, 14.49, 1, 0, 0, 0, 0, 0, 0),
(29, 2, 22, 50, 2.99, 0, 1, 1, 0, 0, 1, 3.99),
(30, 1, 23, 18, 3.49, 1, 0, 0, 0, 0, -1, 0),
(31, 2, 23, 100, 0, 0, 1, 0, 0, 0, 0, 0),
(32, 1, 24, 11, 13.49, 1, 0, 0, 0, 0, 0, 0),
(33, 2, 24, 100, 0, 1, 0, 0, 0, 0, 0, 0),
(34, 1, 25, 20, 3.19, 1, 0, 0, 0, 0, -1, 0),
(35, 2, 25, 102, 0, 1, 0, 0, 0, 0, 0, 0),
(36, 2, 13, 0, 2.32, 0, 0, 1, 0, 0, 0, 2.99),
(37, 3, 14, 0, 0.76, 0, 0, 1, 0, 0, 0, 0.99),
(38, 3, 16, 100, 3.68, 0, 0, 1, 0, 0, 0, 0),
(39, 3, 12, 110, 12.98, 0, 0, 1, 0, 0, 0, 0),
(40, 3, 17, 100, 4.99, 0, 1, 0, 0, 0, 0, 0),
(41, 3, 18, 50, 4.99, 0, 1, 0, 0, 0, 0, 0),
(42, 3, 19, 28, 5.99, 0, 1, 0, 0, 0, 0, 0),
(43, 3, 21, 30, 3.49, 0, 1, 0, 0, 0, 0, 0),
(44, 3, 22, 20, 14.49, 1, 0, 0, 0, 0, 0, 0),
(45, 3, 23, 15, 3.49, 1, 0, 0, 0, 0, 0, 0),
(46, 3, 24, 10, 13.49, 1, 0, 0, 0, 0, 0, 0),
(47, 3, 25, 20, 3.19, 1, 0, 0, 0, 0, 0, 0);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `store`
--

CREATE TABLE `store` (
  `ID` bigint(20) NOT NULL,
  `ADDRESS` bigint(20) NOT NULL,
  `ACTIVE` tinyint(1) DEFAULT NULL,
  `DEFOULT` tinyint(1) NOT NULL,
  `COORDINATES` longtext DEFAULT NULL,
  `OPEN_FROM` varchar(20) NOT NULL,
  `OPEN_TO` varchar(20) NOT NULL,
  `TEMPORARYAVAIABLE` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `store`
--

INSERT INTO `store` (`ID`, `ADDRESS`, `ACTIVE`, `DEFOULT`, `COORDINATES`, `OPEN_FROM`, `OPEN_TO`, `TEMPORARYAVAIABLE`) VALUES
(1, 1, 1, 0, '19.3718617 52.2403177, 19.3762056 52.2442002, 19.3621722 52.2489823, 19.3489114 52.2488247, 19.3404658 52.2479302, 19.3353375 52.2459201, 19.3326123 52.2435552, 19.3303807 52.2443698, 19.3185361 52.248101, 19.3162401 52.2464456, 19.3176993 52.2414398, 19.3266256 52.23826, 19.331518 52.243437, 19.3365176 52.2388645, 19.3404658 52.2376687, 19.3352087 52.2320705, 19.3565698 52.2246512, 19.3628856 52.2317237, 19.3718617 52.2403177', '06:00', '23:00', 0),
(2, 2, 1, 0, '19.3762056 52.2442002, 19.3660121 52.2346218, 19.3630295 52.2317438, 19.3565903 52.2246441, 19.3554314 52.2234479, 19.3737562 52.2121027, 19.3802794 52.2147979, 19.3793567 52.2162441, 19.3804296 52.2179006, 19.3848284 52.2233822, 19.3863948 52.2271151, 19.391729 52.2266269, 19.3960634 52.2400051, 19.3963638 52.2407146, 19.3931022 52.2443147, 19.3879524 52.2469423, 19.3794122 52.2494384, 19.3755928 52.245287, 19.3762056 52.2442002', '11:00', '22:00', 0),
(3, 1, 1, 1, NULL, '06:00', '05:59', 0);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `units`
--

CREATE TABLE `units` (
  `ID` bigint(20) NOT NULL,
  `NAME` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `units`
--

INSERT INTO `units` (`ID`, `NAME`) VALUES
(1, 'szt');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `users`
--

CREATE TABLE `users` (
  `ID` bigint(20) NOT NULL,
  `LOGIN` varchar(20) DEFAULT NULL,
  `PASSWORD` varchar(60) NOT NULL,
  `ROLE` varchar(100) NOT NULL,
  `ACTIVE` varchar(10) DEFAULT NULL,
  `is_employee` tinyint(1) DEFAULT 0,
  `email` varchar(100) DEFAULT NULL,
  `is_vip` tinyint(1) DEFAULT 0,
  `is_banned` tinyint(1) DEFAULT 0,
  `is_fraud` tinyint(1) DEFAULT 0,
  `phone` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`ID`, `LOGIN`, `PASSWORD`, `ROLE`, `ACTIVE`, `is_employee`, `email`, `is_vip`, `is_banned`, `is_fraud`, `phone`) VALUES
(3, 'test', '$2a$12$kUjGq8OvhyAe8.d259YrW.LMWShk93gAj2wJXC0IUnnd0BOYRiDxG', 'admin', '1', 1, 'admin@admin.pl', 0, 0, 0, NULL),
(15, NULL, '$2a$12$kUjGq8OvhyAe8.d259YrW.LMWShk93gAj2wJXC0IUnnd0BOYRiDxG', 'customer', '1', 1, 'test1234@op.pl', 0, 0, 0, '875630100'),
(28, NULL, '$2a$12$kUjGq8OvhyAe8.d259YrW.LMWShk93gAj2wJXC0IUnnd0BOYRiDxG', 'customer', '1', 0, 'test@gmail.com', 0, 0, 0, '555555555'),
(30, NULL, '$2a$10$3In5sXx4oriE4a2IqdOtT.om.gtWw8XUpMZeXqIMD8e1p1zIHvb5O', 'customer', '1', 0, 'test1@op.pl', 0, 0, 0, '502045369'),
(44, NULL, '$2a$10$b5ogxE3VEcCx.lduPYtcaOWrg7RvjO2zQNHKF4PrjeJBL/zagjGtO', 'customer', '1', 0, 'testa@op.pl', 0, 0, 0, '369369369'),
(45, NULL, '$2a$10$Od.0WaVgMr7UNMpHZgiFX.9Y0iuJsOIQiCRzkhm01ffsiKwZW/cv.', 'customer', '1', 0, 'teste@op.pl', 0, 0, 0, '251111147'),
(53, NULL, '$2a$10$qLsU6fANcpBLGVN7DeEy1OfPW/M/J.36/eQq9l4nfWbhnfbd6xVVa', 'customer', '1', 0, 'test5-6@op.pl', 0, 0, 0, '502042369'),
(58, NULL, '$2a$10$E1MiQuh6vNKBA92ZrBaCLOtLOXfj1x58MvfwqtnAE7FPqDOTlWqiW', 'customer', '1', 0, 'kfalkowska87@gmail.com ', 0, 0, 0, '503045369'),
(59, 'string', 'string', 'string', '0', 0, NULL, 0, 0, 0, NULL),
(62, 'strings', 'string', 'string', '0', 0, NULL, 0, 0, 0, NULL),
(63, 'stringhghg', 'string', 'string', '0', 0, NULL, 0, 0, 0, NULL),
(66, 'Testowy', 'Test1234', 'customer', '0', 0, NULL, 0, 0, 0, NULL);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `user_addresses`
--

CREATE TABLE `user_addresses` (
  `ID` bigint(20) NOT NULL,
  `USER_ID` bigint(20) NOT NULL,
  `ADDRESS_ID` bigint(20) NOT NULL,
  `IS_CURRENT` tinyint(1) NOT NULL DEFAULT 0,
  `NAME` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user_addresses`
--

INSERT INTO `user_addresses` (`ID`, `USER_ID`, `ADDRESS_ID`, `IS_CURRENT`, `NAME`) VALUES
(46, 15, 33, 0, NULL),
(75, 30, 40, 1, NULL),
(76, 30, 24, 0, NULL),
(80, 15, 41, 0, NULL),
(81, 15, 42, 1, NULL);

-- --------------------------------------------------------

--
-- Zastąpiona struktura widoku `user_addresses_view`
-- (See below for the actual view)
--
CREATE TABLE `user_addresses_view` (
`USER_ID` bigint(20)
,`LOGIN` varchar(20)
,`ID` bigint(20)
,`ADDRESS_ID` bigint(20)
,`IS_CURRENT` tinyint(1)
,`STREET` varchar(100)
,`STREET_NUMBER` varchar(100)
,`DOOR_NUMBER` varchar(100)
,`FLOR` varchar(20)
,`POSTAL_CODE` varchar(20)
,`MESSAGE` varchar(100)
,`CITY` varchar(100)
,`MAG_ID` bigint(20)
);

-- --------------------------------------------------------

--
-- Struktura widoku `basket_item_view`
--
DROP TABLE IF EXISTS `basket_item_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `basket_item_view`  AS SELECT `bi`.`basket_id` AS `basket_id`, `bi`.`stock_item_id` AS `stock_item_id`, `bi`.`quantity` AS `quantity`, `s`.`PRICE` AS `PRICE`, `s`.`RESERVED_QUANTITY` AS `RESERVED_QUANTITY`, `p`.`ID` AS `ID`, `p`.`WEIGHT` AS `WEIGHT`, `p`.`Image` AS `Image`, `p`.`NAME` AS `NAME`, `p`.`DESCRIPTION` AS `DESCRIPTION`, `s`.`PRICE_BEFORE_PROMO` AS `PRICE_BEFORE_PROMO`, `s`.`QUANTITY` AS `quantity_on_stock` FROM (((`basket_items` `bi` join `stockitem` `s` on(`bi`.`stock_item_id` = `s`.`ID`)) join `products` `p` on(`s`.`PRODUCT_ID` = `p`.`ID`)) join `basket` `b` on(`b`.`id` = `bi`.`basket_id`)) ;

-- --------------------------------------------------------

--
-- Struktura widoku `min_qty_stock`
--
DROP TABLE IF EXISTS `min_qty_stock`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `min_qty_stock`  AS SELECT `s`.`ID` AS `ID`, `s`.`MAGAZINE_ID` AS `MAGAZINE_ID`, `s`.`PRODUCT_ID` AS `PRODUCT_ID`, `s`.`QUANTITY` AS `QUANTITY` FROM `stockitem` AS `s` WHERE `s`.`QUANTITY` < 15 ;

-- --------------------------------------------------------

--
-- Struktura widoku `reserved_qty_to_unlock_view`
--
DROP TABLE IF EXISTS `reserved_qty_to_unlock_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `reserved_qty_to_unlock_view`  AS SELECT `b`.`id` AS `basket_id`, `bi`.`id` AS `basket_item_id`, `bi`.`stock_item_id` AS `stock_item_id`, `bi`.`quantity` AS `quantity`, `bi`.`reserved_qty` AS `reserved_qty` FROM (`basket_items` `bi` join `basket` `b` on(`bi`.`basket_id` = `b`.`id`)) WHERE `b`.`reserved_stock_until` < current_timestamp() AND `bi`.`reserved_qty` > 0 ;

-- --------------------------------------------------------

--
-- Struktura widoku `user_addresses_view`
--
DROP TABLE IF EXISTS `user_addresses_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `user_addresses_view`  AS SELECT `ua`.`USER_ID` AS `USER_ID`, `u`.`LOGIN` AS `LOGIN`, `ua`.`ID` AS `ID`, `ua`.`ADDRESS_ID` AS `ADDRESS_ID`, `ua`.`IS_CURRENT` AS `IS_CURRENT`, `a`.`STREET` AS `STREET`, `a`.`STREET_NUMBER` AS `STREET_NUMBER`, `a`.`DOOR_NUMBER` AS `DOOR_NUMBER`, `a`.`FLOR` AS `FLOR`, `a`.`POSTAL_CODE` AS `POSTAL_CODE`, `a`.`MESSAGE` AS `MESSAGE`, `a`.`CITY` AS `CITY`, `a`.`MAG_ID` AS `MAG_ID` FROM ((`user_addresses` `ua` join `addresses` `a`) join `users` `u` on(`ua`.`ADDRESS_ID` = `a`.`ID` and `u`.`ID` = `ua`.`USER_ID`)) ;

--
-- Indeksy dla zrzutów tabel
--

--
-- Indeksy dla tabeli `addresses`
--
ALTER TABLE `addresses`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `addresses_FK` (`MAG_ID`);

--
-- Indeksy dla tabeli `basket`
--
ALTER TABLE `basket`
  ADD PRIMARY KEY (`id`),
  ADD KEY `basket_FK` (`customer_id`),
  ADD KEY `basket_FK_1` (`addresess_id`),
  ADD KEY `basket_FK_2` (`mag_id`);

--
-- Indeksy dla tabeli `basket_items`
--
ALTER TABLE `basket_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `backet_items_FK` (`basket_id`),
  ADD KEY `backet_items_FK_1` (`stock_item_id`);

--
-- Indeksy dla tabeli `categorytree`
--
ALTER TABLE `categorytree`
  ADD PRIMARY KEY (`ID`),
  ADD UNIQUE KEY `categorytree_un` (`NAME`);

--
-- Indeksy dla tabeli `contractor`
--
ALTER TABLE `contractor`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `contractor_FK` (`CONTRACTORTYPE`);

--
-- Indeksy dla tabeli `contractor_type`
--
ALTER TABLE `contractor_type`
  ADD PRIMARY KEY (`ID`);

--
-- Indeksy dla tabeli `files`
--
ALTER TABLE `files`
  ADD PRIMARY KEY (`ID`);

--
-- Indeksy dla tabeli `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD KEY `NewTable_FK` (`customer_id`),
  ADD KEY `newtable_FK_0` (`picker_id`),
  ADD KEY `newtable_FK_1` (`delivery_courier_id`),
  ADD KEY `newtable_FK_3` (`mag_id`),
  ADD KEY `orders_FK` (`address_id`);

--
-- Indeksy dla tabeli `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`id`);

--
-- Indeksy dla tabeli `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`ID`),
  ADD UNIQUE KEY `products_un` (`EAN`),
  ADD KEY `products_FK` (`PHOTO`),
  ADD KEY `products_FK_1` (`SUBCATEGORY`),
  ADD KEY `products_FK_2` (`CATEGORY`),
  ADD KEY `products_FK_3` (`UNIT`);

--
-- Indeksy dla tabeli `settings`
--
ALTER TABLE `settings`
  ADD PRIMARY KEY (`ID`),
  ADD UNIQUE KEY `SETTINGS_un` (`SETTING_NAME`);

--
-- Indeksy dla tabeli `sliders`
--
ALTER TABLE `sliders`
  ADD PRIMARY KEY (`id`);

--
-- Indeksy dla tabeli `stockitem`
--
ALTER TABLE `stockitem`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `STOCKITEM_FK` (`MAGAZINE_ID`),
  ADD KEY `STOCKITEM_FK_1` (`PRODUCT_ID`);

--
-- Indeksy dla tabeli `store`
--
ALTER TABLE `store`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `STORE_FK` (`ADDRESS`);

--
-- Indeksy dla tabeli `units`
--
ALTER TABLE `units`
  ADD PRIMARY KEY (`ID`);

--
-- Indeksy dla tabeli `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`ID`),
  ADD UNIQUE KEY `users_un` (`LOGIN`),
  ADD UNIQUE KEY `users_un_email` (`email`),
  ADD UNIQUE KEY `users_un_phone` (`phone`);

--
-- Indeksy dla tabeli `user_addresses`
--
ALTER TABLE `user_addresses`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `user_addresses_FK` (`USER_ID`),
  ADD KEY `user_addresses_FK_1` (`ADDRESS_ID`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `addresses`
--
ALTER TABLE `addresses`
  MODIFY `ID` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=43;

--
-- AUTO_INCREMENT for table `basket`
--
ALTER TABLE `basket`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT for table `basket_items`
--
ALTER TABLE `basket_items`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=698;

--
-- AUTO_INCREMENT for table `categorytree`
--
ALTER TABLE `categorytree`
  MODIFY `ID` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=58;

--
-- AUTO_INCREMENT for table `contractor`
--
ALTER TABLE `contractor`
  MODIFY `ID` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `contractor_type`
--
ALTER TABLE `contractor_type`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `files`
--
ALTER TABLE `files`
  MODIFY `ID` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=133;

--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=139;

--
-- AUTO_INCREMENT for table `products`
--
ALTER TABLE `products`
  MODIFY `ID` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `settings`
--
ALTER TABLE `settings`
  MODIFY `ID` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `sliders`
--
ALTER TABLE `sliders`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `stockitem`
--
ALTER TABLE `stockitem`
  MODIFY `ID` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=48;

--
-- AUTO_INCREMENT for table `store`
--
ALTER TABLE `store`
  MODIFY `ID` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `units`
--
ALTER TABLE `units`
  MODIFY `ID` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `ID` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=67;

--
-- AUTO_INCREMENT for table `user_addresses`
--
ALTER TABLE `user_addresses`
  MODIFY `ID` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=82;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `addresses`
--
ALTER TABLE `addresses`
  ADD CONSTRAINT `addresses_FK` FOREIGN KEY (`MAG_ID`) REFERENCES `store` (`ID`);

--
-- Constraints for table `basket`
--
ALTER TABLE `basket`
  ADD CONSTRAINT `basket_FK` FOREIGN KEY (`customer_id`) REFERENCES `users` (`ID`),
  ADD CONSTRAINT `basket_FK_1` FOREIGN KEY (`addresess_id`) REFERENCES `addresses` (`ID`),
  ADD CONSTRAINT `basket_FK_2` FOREIGN KEY (`mag_id`) REFERENCES `store` (`ID`);

--
-- Constraints for table `basket_items`
--
ALTER TABLE `basket_items`
  ADD CONSTRAINT `backet_items_FK` FOREIGN KEY (`basket_id`) REFERENCES `basket` (`id`),
  ADD CONSTRAINT `backet_items_FK_1` FOREIGN KEY (`stock_item_id`) REFERENCES `stockitem` (`ID`);

--
-- Constraints for table `contractor`
--
ALTER TABLE `contractor`
  ADD CONSTRAINT `contractor_FK` FOREIGN KEY (`CONTRACTORTYPE`) REFERENCES `contractor_type` (`ID`);

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `NewTable_FK` FOREIGN KEY (`customer_id`) REFERENCES `users` (`ID`),
  ADD CONSTRAINT `newtable_FK_0` FOREIGN KEY (`picker_id`) REFERENCES `users` (`ID`),
  ADD CONSTRAINT `newtable_FK_1` FOREIGN KEY (`delivery_courier_id`) REFERENCES `users` (`ID`),
  ADD CONSTRAINT `newtable_FK_3` FOREIGN KEY (`mag_id`) REFERENCES `store` (`ID`),
  ADD CONSTRAINT `orders_FK` FOREIGN KEY (`address_id`) REFERENCES `user_addresses` (`ID`);

--
-- Constraints for table `products`
--
ALTER TABLE `products`
  ADD CONSTRAINT `products_FK` FOREIGN KEY (`ID`) REFERENCES `categorytree` (`ID`);

--
-- Constraints for table `stockitem`
--
ALTER TABLE `stockitem`
  ADD CONSTRAINT `STOCKITEM_FK` FOREIGN KEY (`MAGAZINE_ID`) REFERENCES `store` (`ID`),
  ADD CONSTRAINT `STOCKITEM_FK_1` FOREIGN KEY (`PRODUCT_ID`) REFERENCES `products` (`ID`);

--
-- Constraints for table `store`
--
ALTER TABLE `store`
  ADD CONSTRAINT `STORE_FK` FOREIGN KEY (`ADDRESS`) REFERENCES `addresses` (`ID`);

--
-- Constraints for table `user_addresses`
--
ALTER TABLE `user_addresses`
  ADD CONSTRAINT `user_addresses_FK` FOREIGN KEY (`USER_ID`) REFERENCES `users` (`ID`),
  ADD CONSTRAINT `user_addresses_FK_1` FOREIGN KEY (`ADDRESS_ID`) REFERENCES `addresses` (`ID`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
