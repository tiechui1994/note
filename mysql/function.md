
```
DELIMITER $$
CREATE
    [DEFINER = user]
    PROCEDURE sp_name ([proc_parameter[,...]])
    [characteristic ...] 
    
    BEGIN
      procedure_body
    END $$
DELIMITER ;
    
proc_parameter:
    [ IN | OUT | INOUT ] param_name TYPE
    

DELIMITER $$
CREATE
    [DEFINER = user]
    FUNCTION sp_name ([func_parameter[,...]])
    RETURNS type
    [characteristic ...] 
    
    BEGIN
      function_body
    END $$
DELIMITER ;

func_parameter:
    param_name TYPE

characteristic:
    COMMENT 'string'
  | LANGUAGE SQL
  | [NOT] DETERMINISTIC
  | { CONTAINS SQL | NO SQL | READS SQL DATA | MODIFIES SQL DATA }
  | SQL SECURITY { DEFINER | INVOKER }
```