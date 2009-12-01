
DELIMITER |
 CREATE FUNCTION GET_LAST_TP (user_id INT)
  RETURNS VARCHAR(25)
   DETERMINISTIC
    BEGIN
     DECLARE last_tp_info VARCHAR(25);
     SET last_tp_info = '';
  
     SELECT CONCAT(SUBSTRING(actions, 1, position('-' IN actions)-1), ',', datetime) INTO last_tp_info

       FROM admin_actions WHERE uid=user_id AND action_type=3 ORDER BY id DESC LIMIT 1;
     RETURN last_tp_info;
    END|

 CREATE FUNCTION GET_LAST_PAYMENT_INFO (user_id INT)
  RETURNS VARCHAR(50)
   DETERMINISTIC
    BEGIN
     DECLARE last_payment_info VARCHAR(50);
     SET last_payment_info = '';
  
     SELECT CONCAT(sum, ',', date, ',', method) INTO last_payment_info
       FROM payments WHERE uid=user_id ORDER BY id DESC LIMIT 1;
     RETURN last_payment_info;
    END|



 CREATE FUNCTION GET_ACTION_INFO (user_id INT, action_type_id INT, action_module VARCHAR(10))
  RETURNS VARCHAR(50)
   DETERMINISTIC
    BEGIN
     DECLARE action_info VARCHAR(50);
     SET action_info = '';
  
     SELECT CONCAT(datetime, ',', actions) INTO action_info
       FROM admin_actions WHERE uid=user_id AND action_type=action_type_id AND module='' ORDER BY id DESC LIMIT 1;  
 
     RETURN action_info;
    END|

