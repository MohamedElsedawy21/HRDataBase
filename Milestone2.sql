create database m2;

use m2;

GO

CREATE VIEW allEmployeeProfiles
As
SELECT employee_ID,first_name,last_name, gender, email, address, years_of_experience,
official_day_off,type_of_contract,employment_status,
annual_balance, accidental_balance
FROM employee;


GO

CREATE VIEW NoEmployeeDept
As 
SELECT dept_name,count(employee_ID)
FROM employee
GROUP BY dept_name;

GO

CREATE VIEW allPerformance
As 
SELECT employee_ID,performance_ID,rating,comments,semester
FROM performance
where semester LIKE "W%";


GO

CREATE VIEW allRejectedMedicals
AS
SELECT M.Emp_ID,M.request_ID,M.insurance_status,M.disability_details,M.type,L.date_of_request,
L.start_date,L.end_date,L.num_days,L.final_approval_status
FROM Medical_Leave M,Leave L
WHERE M.request_ID=L.request_ID AND L.final_approval_status='rejected';


GO


CREATE VIEW allEmployeeAttendance
AS
SELECT *
FROM attendance
WHERE date=DATEADD(DAY, -1, GETDATE());

GO


CREATE TABLE Employee(
employee_ID INT PRIMARY KEY IDENTITY(1,1),
first_name varchar (50),
last_name varchar (50),
email varchar(50), 
password varchar (50), 
address varchar (50), 
gender char (1),
official_day_off varchar(50),
years_of_experience int, 
national_ID char (16), 
employment_status varchar (50) 
      CHECK (employment_status IN ('active', 'onleave','notice_period','resigned')),
type_of_contract varchar (50) CHECK (type_of_contract IN ('full_time', 'part_time')),
emergency_contact_name varchar (50),
emergency_contact_phone char (11), 
annual_balance int, 
accidental_balance int,
salary decimal(10,2), 
hire_date date, 
last_working_date date, 
dept_name varchar (50),
FOREIGN KEY (dept_name) REFERENCES Department(name)
);



CREATE TABLE Document(
document_ID int PRIMARY KEY IDENTITY(1,1),
type varchar(50),
description varchar(50), 
file_name varchar(50), 
creation_date date, 
expiry_date date, 
status varchar(50)
    CONSTRAINT DF_DocumentStatus DEFAULT 'pending',
    CONSTRAINT CK_DocumentStatus CHECK (status IN ('rejected', 'pending')), 
emp_ID int ,
medical_ID int, 
unpaid_ID int,
FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID),
FOREIGN KEY (medical_ID) REFERENCES medical_leave(request_ID),
FOREIGN KEY (unpaid_ID) REFERENCES unpaid_leave(request_ID)
);