CREATE DEFINER=`carmonk`@`%` FUNCTION `sp_InsertIntoServiceInquiry`(zipcode varchar(11), service_id INT) RETURNS int(11)
BEGIN

	declare scheduled_id int;
	
    insert into t_service_inquiry(service_id, zipcode, status,createdAt,updatedAt) values (service_id,zipcode ,default, now(), now());
	
    SET scheduled_id = LAST_INSERT_ID();
    
    RETURN scheduled_id;


END