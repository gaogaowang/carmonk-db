CREATE DEFINER=`carmonk`@`%` PROCEDURE `sp_InquireAvailability`(IN zipcodeIn VARCHAR(11), IN service_idIn INT(11))
BEGIN

/* this stored procedure expects 3 inputs to inquire availability - zipcode, service_id and inquiry id*/
/* the last argument must be passed by PHP after calling the function sp_insertIntoServiceInquiry which returns*/
/* the last added primary key */

/* variable declarations */
declare lv_scheduledId INT(11) default 0;
declare lv_duration REAL(7,2) default 0;
declare lv_finished INT(1) default 0;
declare lv_mechanicId INT(11) default 0;
declare lv_zipcode VARCHAR(11) default '';

/* this cursor below will read mechanics that are available to service per zip code and servcie id per latest inquiry*/
declare lv_cursorMechanicId CURSOR for 
select mechanic_id, t_service_areas.zipcode from t_service_areas, t_service_inquiry
where t_service_inquiry.zipcode = zipcodeIn 
and t_service_inquiry.id= inquiryIdIn
and t_service_areas.zipcode=t_service_inquiry.zipcode
and t_service_areas.service_id=service_idIn
and t_service_areas.status='ACTIVE';
declare continue handler
   for not found set lv_finished=1; 

/* First read value of service durations for the particular work, e.g. 45 minutes for small car express wash */
/* This variable is used later to add as lead time for when a job is completed.  */

select duration into lv_duration from t_services where id = service_idIn;



 OPEN lv_cursorMechanicId;
 
 get_mechnicId: LOOP
 
 fetch lv_cursorMechanicId into lv_mechanicId, lv_zipcode;

 /* If nothing is returned, exit*/
 IF lv_finished = 1 THEN 
 LEAVE get_mechnicId;
 END IF;
 
 
 /* Select blocked time slots first which will have 4 columns */
 /* It is expected that PHP will use the returned value to display on calendar */
 /* Note the use of lv_duration to add time for completion time */
 select  
tsl.mechanic_id,
tsl.proposed_time start_time, 
addtime(tsl.proposed_comp_time, lv_duration) finish_time,
ta.from_tm,
ta.to_dt
from t_availability ta, t_service_logs tsl where tsl.mechanic_id=lv_mechanicId 
and dayofweek(tsl.proposed_time)=dayofweek(ta.from_tm)
and ta.mechanic_id=tsl.mechanic_id;

/* select general available time slot when there is no job selected for the particular mechanic id*/
select  
ta.mechanic_id,
ta.from_tm,
ta.to_dt
from t_availability ta where ta.mechanic_id=lv_mechanicId
and dayofweek(ta.from_tm) not in (select dayofweek(t_service_logs.proposed_time) from t_service_logs where mechanic_id=1);
 
 END LOOP get_mechnicId;
 
 CLOSE lv_cursorMechanicId;


END