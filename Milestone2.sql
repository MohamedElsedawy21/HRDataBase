create database University_HR_ManagementSystem_Team_58;

use University_HR_ManagementSystem_Team_58;

GO

CREATE FUNCTION Salary(@emp_ID INT)

RETURNS decimal(10,2)
AS
BEGIN
    DECLARE @calculated_salary DECIMAL(10,2)=0;
    
    WITH HighestRankRole AS (
        SELECT TOP 1 
            R.base_salary,
            R.percentage_YOE,
            E.years_of_experience
        FROM Employee_Role ER
        INNER JOIN Role R ON ER.role_name = R.role_name
        INNER JOIN Employee E ON ER.emp_ID = E.employee_ID
        WHERE ER.emp_ID = @emp_ID
        ORDER BY R.rank ASC 
    )
    SELECT @calculated_salary = 
        base_salary + 
        (percentage_YOE / 100.0) * years_of_experience * base_salary
    FROM HighestRankRole;

    RETURN @calculated_salary;
END;

GO

CREATE Function Rate_per_hour(@employee_ID INT)
RETURNS  Decimal(10,2) 
AS
BEGIN
DECLARE @salary Decimal(10,2),
        @Rate Decimal(10,2)
SET @salary = dbo.Salary(@employee_ID)
SET @Rate= (@salary/22)/8
Return @Rate
END;

GO
--2.4h
CREATE FUNCTION Overtime(@employee_ID INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @total_overtime DECIMAL(10,2);

    SELECT @total_overtime = ISNULL(SUM(
        IIF(DATEDIFF(MINUTE, check_in_time, check_out_time) > 480, 
            CAST(DATEDIFF(MINUTE, check_in_time, check_out_time) - 480 AS DECIMAL(10,2)) / 60,
            0)
    ), 0)
    FROM Attendance
    WHERE emp_ID = @employee_ID
      AND MONTH([date]) = MONTH(GETDATE())
      AND YEAR([date]) = YEAR(GETDATE())
      AND check_in_time IS NOT NULL
      AND check_out_time IS NOT NULL
      AND status = 'attended';

    RETURN @total_overtime;
END;

GO

--2.4h

CREATE FUNCTION Bonus_amount(@employee_ID int)
RETURNS  Decimal(10,2) 
AS
BEGIN
DECLARE @rate_per_hour Decimal(10,2),
        @bonus_value Decimal(10,2),
        @percentage_overtime decimal(4,2),
        @extra_hours decimal(4,2)
SET @rate_per_hour=dbo.Rate_per_hour(@employee_ID);
SET @extra_hours=dbo.overtime(@employee_ID);
 WITH HighestRankRole AS (
        SELECT TOP 1 R.percentage_overtime
        FROM Employee_Role ER
        INNER JOIN Role R ON ER.role_name = R.role_name
        INNER JOIN Employee E ON ER.emp_ID = E.employee_ID
        WHERE ER.emp_ID = @employee_ID
        ORDER BY R.rank ASC 
    )
    SELECT @percentage_overtime = percentage_overtime/100
    FROM HighestRankRole;
    SET @bonus_value= @rate_per_hour*(@percentage_overtime*@extra_hours)
        


RETURN @bonus_value
END ;

GO
--2.4a
CREATE FUNCTION [HRLoginValidation]
(
    @employee_ID INT,
    @password VARCHAR(50)
)
RETURNS BIT
AS
BEGIN
    DECLARE @login_successful BIT;

    IF EXISTS (
        SELECT *
        FROM employee
        WHERE employee_ID = @employee_ID
          AND password = @password
    )
        SET @login_successful = 1 
    ELSE
        SET @login_successful = 0

    RETURN @login_successful
END

go


CREATE FUNCTION Is_On_Leave(@employee_ID INT,@from DATE,@to DATE)
RETURNS BIT
AS
BEGIN
    DECLARE @result BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Annual_Leave al
        INNER JOIN [Leave] l ON al.request_id = l.request_id
        WHERE al.emp_id = @employee_ID
          AND l.final_approval_status IN ('approved', 'pending')
          AND l.start_date <= @to
          AND l.end_date >= @from
    )
        SET @result = 1;

    ELSE IF EXISTS (
        SELECT 1
        FROM Accidental_Leave al
        INNER JOIN [Leave] l ON al.request_id = l.request_id
        WHERE al.emp_id = @employee_ID
          AND l.final_approval_status IN ('approved', 'pending')
          AND l.start_date <= @to
          AND l.end_date >= @from
    )
        SET @result = 1;

    ELSE IF EXISTS (
        SELECT 1
        FROM Medical_Leave ml
        INNER JOIN [Leave] l ON ml.request_id = l.request_id
        WHERE ml.emp_id = @employee_ID
          AND l.final_approval_status IN ('approved', 'pending')
          AND l.start_date <= @to
          AND l.end_date >= @from
    )
        SET @result = 1;

    ELSE IF EXISTS (
        SELECT 1
        FROM Unpaid_Leave ul
        INNER JOIN [Leave] l ON ul.request_id = l.request_id
        WHERE ul.emp_id = @employee_ID
          AND l.final_approval_status IN ('approved', 'pending')
          AND l.start_date <= @to
          AND l.end_date >= @from
    )
        SET @result = 1;

    ELSE IF EXISTS (
        SELECT 1
        FROM Compensation_Leave cl
        INNER JOIN [Leave] l ON cl.request_id = l.request_id
        WHERE cl.emp_id = @employee_ID
          AND l.final_approval_status IN ('approved', 'pending')
          AND l.start_date <= @to
          AND l.end_date >= @from
    )
        SET @result = 1;

    RETURN @result;
END;

go

--2.5 a
  CREATE FUNCTION [EmployeeLoginValidation]
(
    @employee_ID INT,
    @password VARCHAR(50)
)
RETURNS BIT
AS
BEGIN
    DECLARE @login_successful BIT;

    IF EXISTS (
        SELECT *
        FROM employee
        WHERE employee_ID = @employee_ID
          AND password = @password
    )
        SET @login_successful = 1 
    ELSE
        SET @login_successful = 0

    RETURN @login_successful
END
go 


--2.1 b
CREATE PROC createAllTables
AS
BEGIN
    -- ==========================
    -- Department Table
    -- ==========================
    CREATE TABLE Department (
        name VARCHAR(50) PRIMARY KEY,
        building_location VARCHAR(50)
    );

    -- ==========================
    -- Employee Table
    -- ==========================
    CREATE TABLE Employee (
        employee_ID INT PRIMARY KEY IDENTITY(1,1),
        first_name VARCHAR(50),
        last_name VARCHAR(50),
        email VARCHAR(50), 
        password VARCHAR(50), 
        address VARCHAR(50), 
        gender CHAR(1),
        official_day_off VARCHAR(50),
        years_of_experience INT, 
        national_ID CHAR(16), 
        employment_status VARCHAR(50)
            DEFAULT '' CHECK (employment_status IN ('active', 'onleave','notice_period','resigned')),
        type_of_contract VARCHAR(50)
            CHECK (type_of_contract IN ('full_time', 'part_time')),
        emergency_contact_name VARCHAR(50),
        emergency_contact_phone CHAR(11), 
        annual_balance INT, 
        accidental_balance INT,
        salary AS (dbo.Salary(employee_ID)), 
        hire_date DATE, 
        last_working_date DATE, 
        dept_name VARCHAR(50),
        FOREIGN KEY (dept_name) REFERENCES Department(name)
            ON DELETE CASCADE
    );

    -- ==========================
    -- Employee_Phone Table
    -- ==========================
    CREATE TABLE Employee_Phone (
        emp_ID INT,
        phone_num CHAR(11),
        FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID)
            ON DELETE CASCADE,
        PRIMARY KEY (emp_ID, phone_num)
    );

    -- ==========================
    -- Role Table
    -- ==========================
    CREATE TABLE Role (
        role_name VARCHAR(50) PRIMARY KEY,
        title VARCHAR(50),
        description VARCHAR(50),
        rank INT,
        base_salary DECIMAL(10,2),
        percentage_YOE DECIMAL(4,2),
        percentage_overtime DECIMAL(4,2),
        annual_balance INT,
        accidental_balance INT
    );

    -- ==========================
    -- Employee_Role Table
    -- ==========================
    CREATE TABLE Employee_Role (
        emp_ID INT,
        role_name VARCHAR(50),
        CONSTRAINT PK_Employee_Role PRIMARY KEY (emp_ID, role_name),
        CONSTRAINT FK_EmployeeRole_Employee FOREIGN KEY (emp_ID)
            REFERENCES Employee(employee_ID)
            ON DELETE CASCADE,
        CONSTRAINT FK_EmployeeRole_Role FOREIGN KEY (role_name)
            REFERENCES Role(role_name)
            ON DELETE CASCADE
    );

    -- ==========================
    -- Role_existsIn_Department Table
    -- ==========================
    CREATE TABLE Role_existsIn_Department (
        department_name VARCHAR(50),
        role_name VARCHAR(50),
        CONSTRAINT PK_Role_Dept PRIMARY KEY (department_name, role_name),
        CONSTRAINT FK_RoleDept_Dept FOREIGN KEY (department_name)
            REFERENCES Department(name)
            ON DELETE CASCADE,
        CONSTRAINT FK_RoleDept_Role FOREIGN KEY (role_name)
            REFERENCES Role(role_name)
            ON DELETE CASCADE
    );

    -- ==========================
    -- Leave Table 
    -- ==========================
    CREATE TABLE [leave] (
        request_id INT IDENTITY(1,1) PRIMARY KEY,
        date_of_request DATE,
        start_date DATE,
        end_date DATE,
        num_days AS (DATEDIFF(DAY, start_date, end_date)+1),
        final_approval_status VARCHAR(50)
            CONSTRAINT DF_LeaveStatus DEFAULT 'pending'
            CONSTRAINT CK_LeaveStatus CHECK (final_approval_status IN ('rejected', 'pending','approved'))
    );

    -- ==========================
    -- Annual Leave
    -- ==========================
    CREATE TABLE annual_leave (
        request_id INT PRIMARY KEY,
        emp_id INT,
        replacement_emp INT ,
        FOREIGN KEY (request_id) REFERENCES [leave](request_id)
            ON DELETE CASCADE,
        FOREIGN KEY (emp_id) REFERENCES Employee(employee_ID)
            ON DELETE CASCADE,
        FOREIGN KEY (replacement_emp) REFERENCES Employee(employee_ID)
            
    );

    -- ==========================
    -- Accidental Leave
    -- ==========================
    CREATE TABLE accidental_leave (
        request_id INT PRIMARY KEY,
        emp_id INT,
        FOREIGN KEY (request_id) REFERENCES [leave](request_id)
            ON DELETE CASCADE,
        FOREIGN KEY (emp_id) REFERENCES Employee(employee_ID)
            ON DELETE CASCADE
    );

    -- ==========================
    -- Medical Leave
    -- ==========================
    CREATE TABLE medical_leave (
        request_id INT PRIMARY KEY,
        insurance_status BIT,
        disability_details VARCHAR(50),
        type VARCHAR(50) CHECK (type IN ('sick','maternity')),
        emp_id INT,
        FOREIGN KEY (request_id) REFERENCES [leave](request_id)
            ON DELETE CASCADE,
        FOREIGN KEY (emp_id) REFERENCES Employee(employee_ID)
            ON DELETE CASCADE
    );

    -- ==========================
    -- Unpaid Leave
    -- ==========================
    CREATE TABLE unpaid_leave (
        request_id INT PRIMARY KEY,
        emp_id INT,
        FOREIGN KEY (request_id) REFERENCES [leave](request_id)
            ON DELETE CASCADE,
        FOREIGN KEY (emp_id) REFERENCES Employee(employee_ID)
            ON DELETE CASCADE
    );

    -- ==========================
    -- Compensation Leave
    -- ==========================
    CREATE TABLE compensation_leave (
        request_id INT PRIMARY KEY,
        reason VARCHAR(50),
        date_of_original_workday DATE,
        emp_id INT,
        replacement_emp INT,
        FOREIGN KEY (request_id) REFERENCES [leave](request_id)
            ON DELETE CASCADE,
        FOREIGN KEY (emp_id) REFERENCES Employee(employee_ID)
            ON DELETE CASCADE,
        FOREIGN KEY (replacement_emp) REFERENCES Employee(employee_ID)
            
    );

    -- ==========================
    -- Document Table
    -- ==========================
    CREATE TABLE Document (
        document_ID INT PRIMARY KEY IDENTITY(1,1),
        type VARCHAR(50),
        description VARCHAR(50), 
        file_name VARCHAR(50), 
        creation_date DATE, 
        expiry_date DATE, 
        status VARCHAR(50)
            DEFAULT 'valid' CHECK (status IN ('expired', 'valid')), 
        emp_ID INT,
        medical_ID INT, 
        unpaid_ID INT,
        FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID)
            ON DELETE CASCADE,
        FOREIGN KEY (medical_ID) REFERENCES medical_leave(request_ID)
            ,
        FOREIGN KEY (unpaid_ID) REFERENCES unpaid_leave(request_ID)
            
    );

    -- ==========================
    -- Payroll Table
    -- ==========================
    CREATE TABLE Payroll (
        ID INT PRIMARY KEY IDENTITY(1,1),
        payment_date DATE, 
        final_salary_amount DECIMAL(10,1), 
        from_date DATE, 
        to_date DATE, 
        comments VARCHAR(150), 
        bonus_amount DECIMAL(10,2), 
        deductions_amount DECIMAL(10,2), 
        emp_ID INT,
        FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID)
            ON DELETE CASCADE
    );

    -- ==========================
    -- Attendance Table
    -- ==========================
    CREATE TABLE Attendance (
        attendance_ID INT PRIMARY KEY IDENTITY(1,1), 
        date DATE, 
        check_in_time TIME,
        check_out_time TIME, 
        total_duration AS DATEADD(SECOND, DATEDIFF(SECOND, check_in_time, check_out_time), '00:00:00'), 
        status VARCHAR(50) DEFAULT 'absent'
            CHECK (status IN ('attended', 'absent')), 
        emp_ID INT,
        FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID)
            ON DELETE CASCADE
    );

    -- ==========================
    -- Deduction Table
    -- ==========================
    CREATE TABLE Deduction (
        deduction_ID INT IDENTITY(1,1),
        emp_ID INT,
        date DATE,
        amount DECIMAL(10,2),
        type VARCHAR(50)
            CHECK (type IN ('unpaid', 'missing_hours', 'missing_days')),
        status VARCHAR(50) DEFAULT 'pending'
            CHECK (status IN ('pending', 'finalized')),
        unpaid_ID INT,
        attendance_ID INT,
        PRIMARY KEY (deduction_ID, emp_ID),
        FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID)
            ,
        FOREIGN KEY (unpaid_ID) REFERENCES unpaid_leave(request_ID)
           ,
        FOREIGN KEY (attendance_ID) REFERENCES Attendance(attendance_ID)
        on delete cascade
           
    );

    -- ==========================
    -- Performance Table
    -- ==========================
    CREATE TABLE Performance (
        performance_ID INT PRIMARY KEY IDENTITY(1,1), 
        rating INT CHECK (rating BETWEEN 1 AND 5), 
        comments VARCHAR(50), 
        semester CHAR(3), 
        emp_ID INT,
        FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID)
            ON DELETE CASCADE
    );

    -- ==========================
    -- Employee Replace Employee
    -- ==========================
    CREATE TABLE Employee_Replace_Employee (
        Table_ID INT IDENTITY (1,1),
        Emp1_ID INT,
        Emp2_ID INT,
        from_date DATE,
        to_date DATE,
        PRIMARY KEY (Table_ID,Emp1_ID, Emp2_ID),
        FOREIGN KEY (Emp1_ID) REFERENCES Employee(employee_ID)
            ON DELETE CASCADE,
        FOREIGN KEY (Emp2_ID) REFERENCES Employee(employee_ID)
        
    );

    -- ==========================
    -- Employee Approve Leave
    -- ==========================
    CREATE TABLE Employee_Approve_Leave (
        Emp1_ID INT, 
        Leave_ID INT, 
        status VARCHAR(50),
        PRIMARY KEY (Emp1_ID, Leave_ID),
        FOREIGN KEY (Leave_ID) REFERENCES [leave](request_id)
            ON DELETE CASCADE,
        FOREIGN KEY (Emp1_ID) REFERENCES Employee(employee_ID)
            ON DELETE CASCADE
    );
END;
GO

exec createAllTables


--2.1c 
go
CREATE PROC dropAllTables
AS
Drop Table Employee_Approve_Leave
Drop Table Employee_Replace_Employee
Drop Table Performance
Drop Table Deduction
Drop Table Attendance
Drop Table Payroll
Drop Table Document
Drop Table Compensation_Leave
Drop Table Unpaid_Leave
Drop Table Medical_Leave
Drop Table Accidental_Leave
Drop Table Annual_Leave
Drop Table Leave
Drop Table Role_ExistsIn_Department
Drop Table Employee_Role
Drop Table Role
Drop Table Employee_Phone
Drop Table Employee
Drop Table Department

go


--2.1 d

CREATE PROC dropAllProceduresFunctionsViews
as
drop procedure createAllTables
drop procedure dropAllTables
drop procedure clearAllTables
drop view allEmployeeProfiles
drop view NoEmployeeDept
drop view allPerformance
drop view allRejectedMedicals
drop view allEmployeeAttendance
drop proc Update_Status_Doc
drop procedure allEmployeeAttendance
drop procedure Remove_Deductions
drop procedure Update_Employment_Status
drop procedure Create_Holiday
drop procedure Add_Holiday
drop procedure Intitiate_Attendance
drop procedure Update_Attendance
drop procedure Remove_Holiday
drop procedure Remove_DayOff
drop procedure Remove_Approved_Leaves
drop procedure Replace_employee
drop function HRLoginValidation
drop procedure HR_approval_an_acc
drop procedure HR_approval_unpaid
drop procedure HR_approval_comp
drop procedure Deduction_hours
drop procedure Deduction_days
drop procedure Deduction_unpaid
drop function Bonus_amount
drop procedure Add_Payroll
drop function EmployeeLoginValidation
drop function MyPerformance 
drop function MyAttendance 
drop function Last_month_payroll
drop function Deductions_Attendance 
drop function Is_On_Leave
drop procedure Submit_annual
drop function Status_leaves 
drop procedure Upperboard_approve_annual
drop procedure Submit_accidental
drop procedure Submit_medical
drop procedure Submit_unpaid
drop procedure Upperboard_approve_unpaids
drop procedure Submit_compensation
drop procedure Dean_andHR_Evaluation

go 
--2.1 e
CREATE PROC clearAllTables
as

 DELETE FROM Employee_Approve_Leave;
    DELETE FROM Employee_Replace_Employee;
    DELETE FROM Performance;
    DELETE FROM Deduction;
    DELETE FROM Attendance;
    DELETE FROM Payroll;
    DELETE FROM Document;
    DELETE FROM Compensation_Leave;
    DELETE FROM Unpaid_Leave;
    DELETE FROM Medical_Leave;
    DELETE FROM Accidental_Leave;
    DELETE FROM Annual_Leave;
    DELETE FROM [Leave];
    DELETE FROM Role_ExistsIn_Department;
    DELETE FROM Employee_Role;
    DELETE FROM Employee_Phone;
    DELETE FROM Role;
    DELETE FROM Employee;
    DELETE FROM Department;

go
--2.2a
CREATE VIEW allEmployeeProfiles
As
SELECT employee_ID,first_name,last_name, gender, email, address, years_of_experience,
official_day_off,type_of_contract,employment_status,
annual_balance, accidental_balance
FROM employee;


GO
--2.2b
CREATE VIEW NoEmployeeDept
As 
SELECT dept_name,count(employee_ID)
FROM employee
GROUP BY dept_name;

GO
--2.2c
CREATE VIEW allPerformance
As 
SELECT emp_ID,performance_ID,rating,comments,semester
FROM performance
where semester LIKE 'W%';


GO
--2.2d
CREATE VIEW allRejectedMedicals
AS
SELECT M.Emp_ID,M.request_ID,M.insurance_status,M.disability_details,M.type,L.date_of_request,
L.start_date,L.end_date,L.num_days,L.final_approval_status
FROM Medical_Leave M,Leave L
WHERE M.request_ID=L.request_ID AND L.final_approval_status='rejected';


GO

--2.2e
CREATE VIEW allEmployeeAttendance
AS
SELECT *
FROM attendance
WHERE date=DATEADD(DAY, -1, GETDATE());

GO

--2.3 a 
CREATE PROC  Update_Status_Doc
as 
Update Document 
Set status = 'expired'
Where
expiry_date <= CAST(GETDATE() AS DATE)
go

--2.3 b 
CREATE PROC  Remove_Deductions
as 
DELETE d
FROM deduction d WHERE d.emp_ID IN(
select e.employee_ID
from employee e
where e.employment_status = 'resigned' )
go

--2.3 c 

CREATE PROC Update_Employment_Status 
@Employee_ID INT
AS 
BEGIN
DECLARE @ISONLEAVE BIT
SET @ISONLEAVE=dbo.Is_On_Leave(@Employee_ID,GETDATE(),GETDATE())
UPDATE Employee
SET employment_status='onleave'
WHERE employee_ID=@Employee_ID and @ISONLEAVE=1 and employment_status='active'

UPDATE Employee
SET employment_status='active'
WHERE employee_ID=@Employee_ID and @ISONLEAVE=0 and employment_status='onleave'
END

GO

 --2.3 d
 CREATE PROCEDURE Create_Holiday
AS 
create table Holiday 
( holiday_id INT IDENTITY(1,1) PRIMARY KEY,
        name VARCHAR(50),
        from_date DATE ,
        to_date DATE
    )

    go
exec Create_Holiday
select* from holiday
go
 --2.3 e

    CREATE PROCEDURE Add_Holiday
    @holiday_name VARCHAR(50),
    @from_date DATE,
    @to_date DATE
AS
INSERT INTO Holiday (name, from_date, to_date)
    VALUES (@holiday_name, @from_date, @to_date)

--2.3 f
Go
CREATE PROC Intitiate_Attendance
AS
    DECLARE @today DATE = GETDATE()
    
    -- Only insert records if they don't already exist for today
    INSERT INTO Attendance(date, check_in_time, check_out_time, status, emp_ID)
    SELECT @today, NULL, NULL, 'absent', e.employee_ID 
    FROM Employee e
    WHERE NOT EXISTS (
        SELECT 1 
        FROM Attendance a 
        WHERE a.emp_ID = e.employee_ID 
        AND a.date = @today
    )
EXEC Intitiate_Attendance;
SELECT emp_ID, date, check_in_time, check_out_time, status
FROM Attendance
WHERE date = CAST(GETDATE() AS DATE)
ORDER BY emp_ID;

go
--2.3 g
CREATE PROC Update_Attendance
	@Employee_id INT,
	@check_in TIME,
	@check_out TIME

	AS
	DECLARE @today DATE = GETDATE()
	UPDATE Attendance
	SET check_in_time = @check_in,
	    check_out_time = @check_out,
	    status = 'attended'
	WHERE (emp_ID = @Employee_id AND date = @today);

go

--2.3 h
CREATE PROC Remove_Holiday
AS
BEGIN
    DELETE a
    FROM Attendance AS a
    INNER JOIN Holiday AS h
    ON a.date BETWEEN h.from_date AND h.to_date;
END;

SELECT * FROM Attendance;


go
--2.3 i 
Create procedure Remove_DayOff
@Employee_id int
as 
delete a 
from Attendance a join employee e 
on a.emp_ID = e.employee_ID
where DATENAME(WEEKDAY, a.date) = e.official_day_off
 go 
 
 --2.3 j 
  CREATE PROCEDURE Remove_Approved_Leaves
    @Employee_id INT
AS

     WITH ApprovedLeaves AS (
        SELECT l.start_date, l.end_date, al.emp_ID
        FROM Leave l
        INNER JOIN Annual_Leave al ON l.request_ID = al.request_ID
        WHERE l.final_approval_status = 'approved'
        
        UNION ALL
        
        SELECT l.start_date, l.end_date, ac.emp_ID
        FROM Leave l
        INNER JOIN Accidental_Leave ac ON l.request_ID = ac.request_ID
        WHERE l.final_approval_status = 'approved'
        
        UNION ALL
        
        SELECT l.start_date, l.end_date, ml.emp_ID
        FROM Leave l
        INNER JOIN Medical_Leave ml ON l.request_ID = ml.request_ID
        WHERE l.final_approval_status = 'approved'
        
        UNION ALL
        
        SELECT l.start_date, l.end_date, ul.emp_ID
        FROM Leave l
        INNER JOIN Unpaid_Leave ul ON l.request_ID = ul.request_ID
        WHERE l.final_approval_status = 'approved'
        
        UNION ALL
        
        SELECT l.start_date, l.end_date, cl.emp_ID
        FROM Leave l
        INNER JOIN Compensation_Leave cl ON l.request_ID = cl.request_ID
        WHERE l.final_approval_status = 'approved'
    )
    
    -- Delete attendance records with employee filtering only in WHERE clause
    DELETE a
    FROM attendance a
    INNER JOIN ApprovedLeaves al ON a.date BETWEEN al.start_date AND al.end_date 
                                   AND a.emp_ID = al.emp_ID
    WHERE a.emp_ID = @Employee_id;
    
     exec Remove_Approved_Leaves @Employee_id = 1
     select* from attendance
     select* from employee
     select* from leave
     select* from annual_leave
   GO


 --2.3k
   create procedure Replace_employee
   @Emp1_ID int,
   @Emp2_ID int,
   @from_date date,
   @to_date date
   as 
   insert into Employee_Replace_Employee (Emp1_ID , Emp2_ID, from_date ,to_date)
   values (  @Emp1_ID, @Emp2_ID , @from_date , @to_date )


   GO
-- 2.4.B 
CREATE PROC HR_approval_an_acc
    @request_ID INT,
    @HR_ID INT
AS
BEGIN
    DECLARE @emp_ID INT,
            @annual_balance INT,
            @accidental_balance INT,
            @num_days INT,
            @leave_type VARCHAR(20),
            @approval_status VARCHAR(50)

    
    IF EXISTS (SELECT 1 FROM Annual_Leave WHERE request_ID = @request_ID)
        SET @leave_type = 'annual'
    ELSE
        SET @leave_type = 'accidental'
  
       
    

    SELECT @num_days = num_days 
    FROM Leave 
    WHERE request_ID = @request_ID

    IF @leave_type = 'annual'
    BEGIN
      
        SELECT @emp_ID = al.emp_ID, 
               @annual_balance = e.annual_balance
        FROM Annual_Leave al
        INNER JOIN Employee e ON al.emp_ID = e.employee_ID
        WHERE al.request_ID = @request_ID

       
        IF @annual_balance >= @num_days
        BEGIN
            SET @approval_status = 'Approved'
         
            UPDATE Employee 
            SET annual_balance = annual_balance - @num_days 
            WHERE employee_ID = @emp_ID
        END
        ELSE
        BEGIN
            SET @approval_status = 'Rejected'
        END
    END
    ELSE IF @leave_type = 'accidental'
    BEGIN
        SELECT @emp_ID = al.emp_ID, 
               @accidental_balance = e.accidental_balance
        FROM Accidental_Leave al
        INNER JOIN Employee e ON al.emp_ID = e.employee_ID
        WHERE al.request_ID = @request_ID

        IF @accidental_balance >= @num_days
        BEGIN
            SET @approval_status = 'Approved'

            UPDATE Employee 
            SET accidental_balance = accidental_balance - @num_days 
            WHERE employee_ID = @emp_ID
        END
        ELSE
        BEGIN
            SET @approval_status = 'Rejected'
        END
    END

    UPDATE Leave 
    SET final_approval_status = @approval_status 
    WHERE request_ID = @request_ID

END
go 
--2.4.C
GO
CREATE PROC HR_approval_unpaid
    @request_ID INT, 
    @HR_ID INT
AS
BEGIN
    DECLARE @annual_balance INT,
            @emp_ID INT,
            @num_days INT,
            @approval_status VARCHAR(50)


    SELECT @num_days = num_days
    FROM Leave 
    WHERE request_ID = @request_ID   


    IF (@num_days > 30)
    BEGIN
        SET @approval_status = 'rejected'
    END
    ELSE
    BEGIN

        SELECT 
            @emp_ID = ul.emp_ID,
            @annual_balance = e.annual_balance
        FROM Unpaid_Leave ul
        INNER JOIN Employee e 
            ON ul.emp_ID = e.employee_ID
        WHERE ul.request_ID = @request_ID


        IF (@annual_balance > 0)
            SET @approval_status = 'rejected'
        ELSE
            SET @approval_status = 'approved'
    END

  
    UPDATE Leave 
    SET final_approval_status = @approval_status 
    WHERE request_ID = @request_ID

END
GO
--2.4.d
CREATE PROC HR_approval_comp
    @request_ID INT, 
    @HR_ID INT
AS
BEGIN
DECLARE 
    @emp_id INT,
    @orig_workDay DATE,
    @reqDate DATE,
    @reason VARCHAR(50),
    @dayOff VARCHAR(50),
    @req_status VARCHAR(50)

SELECT 
    @emp_id = cl.emp_ID,
    @orig_workDay = cl.date_of_original_workday,
    @reqDate = l.date_of_request,
    @reason = cl.reason
FROM compensation_leave cl
JOIN leave l 
ON l.request_id = cl.request_id
WHERE cl.request_id = @request_ID;


SELECT @dayOff = e.official_day_off
FROM Employee e
WHERE e.employee_ID = @emp_id;

DECLARE @check_in TIME, @check_out TIME;
SELECT @check_in = a.check_in_time,
       @check_out = a.check_out_time
FROM Attendance a
WHERE a.emp_ID = @emp_id AND a.date = @orig_workDay;

DECLARE @total_duration TIME = dbo.fn_AttendanceTotalDuration(@check_in,@check_out)
DECLARE @mins INT = CASE WHEN @total_duration IS NULL THEN NULL
                    ELSE DATEDIFF(MINUTE, '00:00:00', @total_duration) 
                    END;

 /* Rule checks */
    DECLARE 
        @worked_8h  BIT = CASE WHEN @mins IS NOT NULL AND @mins >= 480 THEN 1 ELSE 0 END,
        @is_day_off BIT = CASE WHEN @dayOff IS NOT NULL AND DATENAME(WEEKDAY, @orig_workDay) = @dayOff THEN 1 ELSE 0 END,
        @same_month BIT = CASE WHEN @reqDate IS NOT NULL AND DATEDIFF(MONTH, @reqDate, @orig_workDay) = 0 THEN 1 ELSE 0 END,
        @has_reason BIT = CASE WHEN @reason IS NOT NULL THEN 1 ELSE 0 END;

        IF (@worked_8h = 1 AND @is_day_off = 1 AND @same_month = 1 AND @has_reason = 1)
            SET @req_status = 'approved';
        ELSE
            SET @req_status = 'rejected';


    UPDATE leave 
    SET final_approval_status = @req_status
    WHERE request_ID = @request_ID;
END;
GO

--2.4 e
CREATE PROC Deduction_hours
@employee_ID int
AS
BEGIN
    DECLARE @MissingHours DECIMAL(10,2);
    DECLARE @Emp_rate DECIMAL(10,2);
    DECLARE @deduction_amount DECIMAL(10,2);
    DECLARE @first_attendance_id INT;
SELECT 
    @MissingHours=(COUNT(*) * 8) - SUM(CAST(DATEDIFF(SECOND, '00:00:00', A.total_duration) AS DECIMAL(10,2)) / 3600.0) 
FROM Attendance A
WHERE A.emp_ID = @employee_ID 
    AND A.total_duration < '08:00:00' 
    AND MONTH(A.date) = MONTH(GETDATE())
    AND YEAR(A.date) = YEAR(GETDATE());

SELECT TOP 1 @first_attendance_id = A.attendance_ID
    FROM Attendance A
    WHERE A.emp_ID = @employee_ID 
        AND A.total_duration < '08:00:00' 
        AND MONTH(A.date) = MONTH(GETDATE())
        AND YEAR(A.date) = YEAR(GETDATE())
    ORDER BY A.date ASC;

IF @MissingHours IS NULL OR @MissingHours <= 0
        RETURN;
SELECT @Emp_rate = dbo.Rate_per_hour(@employee_ID);
SET @deduction_amount = @Emp_rate * @MissingHours;
INSERT INTO Deduction (
        emp_ID, date, amount, type, status, attendance_ID
    ) VALUES (
        @employee_ID, 
        GETDATE(), 
        @deduction_amount, 
        'missing_hours', 
        'pending', 
        @first_attendance_id
    );

END
go

--2.4 f

CREATE PROC Deduction_days
@employee_ID int
AS
BEGIN
    DECLARE @rate_per_hour decimal(10,2),
            @daily_deduction decimal(10,2)

    SET @rate_per_hour = dbo.Rate_per_hour(@employee_ID)
    SET @daily_deduction = @rate_per_hour * 8

   
    INSERT INTO Deduction (emp_ID, date, amount, type, status)
    SELECT 
        @employee_ID,
        a.date,  
        @daily_deduction,
        'missing_days',
        'pending'
    FROM ATTENDANCE a
    WHERE 
        a.emp_ID = @employee_ID
        AND MONTH(a.date) = MONTH(GETDATE())
        AND YEAR(a.date) = YEAR(GETDATE())
        AND a.status = 'Absent'
END


go

 --2.4 g
CREATE PROCEDURE Deduction_unpaid
@employee_ID INT
AS
BEGIN
DECLARE @Start_date date;
DECLARE @End_date date ;
DECLARE @Emp_Dayrate Decimal(10,2);
DECLARE @Ded_amount Decimal(10,2);
DECLARE @Unpaid_ID INT;
SET @Emp_Dayrate=dbo.Rate_per_hour(@employee_ID)*8


SELECT @Unpaid_ID=ul.request_id,@Start_date=l.start_date,@End_date=l.end_date
FROM unpaid_leave ul inner join leave l on(ul.request_id=l.request_id)
WHERE ul.emp_id=@employee_ID and MONTH(GETDATE())=MONTH(l.start_date) and l.final_approval_status='approved'


if @Unpaid_ID IS NULL
BEGIN
    RETURN;
END

if MONTH(@Start_date)=MONTH(@End_date)
BEGIN

SET @Ded_amount= (DATEDIFF(DAY, @Start_date, @End_date) + 1)*@Emp_Dayrate
INSERT INTO Deduction (emp_ID,date,amount,type,status,unpaid_ID) VALUES(
@employee_ID,
GETDATE(),
@Ded_amount,
'unpaid',
'pending',
@Unpaid_ID
)
END


ELSE

BEGIN
SET @Ded_amount= (DATEDIFF(DAY, @Start_date, EOMONTH(GETDATE())) + 1)*@Emp_Dayrate
INSERT INTO Deduction (emp_ID,date,amount,type,status,unpaid_ID) VALUES(
@employee_ID,
GETDATE(),
@Ded_amount,
'unpaid',
'pending',
@Unpaid_ID
)
SET @Ded_amount= (DATEDIFF(DAY,DATEADD(DAY, 1 - DAY(@End_date), @End_date), @End_date)+1)*@Emp_Dayrate
INSERT INTO Deduction (emp_ID,date,amount,type,status,unpaid_ID) VALUES(
@employee_ID,
GETDATE(),
@Ded_amount,
'unpaid',
'pending',
@Unpaid_ID
)
END


END

go


GO
--2.4 i
CREATE PROC Add_Payroll 
@employee_ID INT,
@from DATE,
@to DATE
AS
BEGIN
DECLARE @DEDS DECIMAL(10,2)
DECLARE @BONUS DECIMAL(10,2)
DECLARE @SALARY DECIMAL(10,2)
DECLARE @TOTAL DECIMAL(10,2)
SET @BONUS=dbo.Bonus_amount(@employee_ID)
SELECT @DEDS=SUM(D.amount)
FROM Deduction D
WHERE D.date>=@from AND D.date<=@to AND D.status='pending' and d.emp_ID=@employee_ID

UPDATE Deduction 
SET status='finalized'
WHERE date>=@from AND date<=@to AND status='pending' and emp_ID=@employee_ID

set @SALARY=dbo.Salary(@employee_ID)



SET @TOTAL=@BONUS+@SALARY-@DEDS
INSERT INTO PAYROLL (payment_date,final_salary_amount,from_date,to_date,bonus_amount,deductions_amount,emp_ID) VALUES(
GETDATE(),@TOTAL,@from,@to,@BONUS,@DEDS,@employee_ID)
END
GO


GO
--2.5 i
CREATE PROC Upperboard_approve_annual
@request_ID INT,
@Upperboard_ID INT,
@replacement_ID INT
AS
BEGIN
DECLARE @ISONLEAVE BIT
DECLARE @REPLACED_EMP INT
DECLARE @EMP1_D VARCHAR(50)
DECLARE @EMP2_D VARCHAR(50)
DECLARE @START DATE
DECLARE @END DATE

SELECT @START=l.start_date,@END=l.end_date
FROM leave l
WHERE l.request_id=@request_ID

SET @ISONLEAVE=dbo.Is_On_Leave(@replacement_ID,@START,@END)

SELECT @REPLACED_EMP=al.emp_id
FROM annual_leave al
where al.request_id=@request_ID


SELECT @EMP1_D=e.dept_name
FROM Employee e
WHERE e.employee_ID=@REPLACED_EMP

SELECT @EMP2_D=e.dept_name
FROM Employee e
WHERE e.employee_ID=@replacement_ID

if (@EMP1_D=@EMP2_D AND @ISONLEAVE=0)
BEGIN 
INSERT INTO Employee_Approve_Leave(Emp1_ID,Leave_ID,status) VALUES
(@Upperboard_ID,@request_ID,'approved')
END

END  
go
--2.5 b
CREATE FUNCTION MyPerformance
(@employee_ID int,
@semester char(3)
)
RETURNS TABLE
AS
RETURN
(
select * from Performance where emp_ID = @employee_ID AND semester = @semester
)
go
--2.5c
CREATE FUNCTION MyAttendance
(@employee_ID int)
returns table 
as 
return
(
with fullmonth as(
select *
from attendance a 
where a.emp_ID = @employee_ID AND MONTH(a.date) = MONTH(GETDATE())
)
select fm.attendance_ID,  fm.date, fm.check_in_time, fm.check_out_time, fm.total_duration, fm.status, fm.emp_ID
from fullmonth fm inner join employee e 
on fm.emp_ID = e.employee_ID 
where DATENAME(WEEKDAY, fm.date) != e.official_day_off 
)
go 
--2.5d 
CREATE FUNCTION Last_month_payroll
(@employee_ID int)
returns table 
as 
return
(
SELECT * 
FROM Payroll p
where p.emp_ID = @employee_ID AND MONTH(DATEADD(MONTH, -1, GETDATE()))= MONTH(p.to_date)
)
go

--2.5e
CREATE FUNCTION Deductions_Attendance(@employee_ID INT, @month INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        d.deduction_ID,
        d.emp_ID,
        e.first_name,
        e.last_name,
        d.date,
        d.amount,
        d.type,
        d.status,
        a.check_in_time,
        a.check_out_time,
        a.total_duration
    FROM Deduction d
    INNER JOIN Attendance a
        ON d.attendance_ID = a.attendance_ID
    INNER JOIN Employee e
        ON d.emp_ID = e.employee_ID
    WHERE d.emp_ID = @employee_ID
      AND MONTH(d.date) = @month
      AND d.type IN ('missing_hours', 'missing_days') 
);
go
--2.5 h
CREATE FUNCTION Status_leaves 
(@employee_ID int)
returns table 
as
return
(
  WITH Leaves AS (
        SELECT l.request_id, start_date, l.end_date,l.date_of_request,l.final_approval_status, al.emp_ID
        FROM Leave l
        INNER JOIN Annual_Leave al ON l.request_ID = al.request_ID
        WHERE month(l.date_of_request) =  MONTH(GETDATE())

        
        UNION ALL
        
        SELECT l.request_id, l.start_date, l.end_date,l.date_of_request,l.final_approval_status, acc.emp_ID
        FROM Leave l
        INNER JOIN accidental_leave acc ON l.request_ID = acc.request_ID
        WHERE month(l.date_of_request) =  MONTH(GETDATE()))
        
select le.request_id , le.date_of_request, le.final_approval_status
from Leaves le
where le.emp_id = @employee_ID 
)
go

--2.5 i
CREATE PROC Upperboard_approve_annual
@request_ID INT,
@Upperboard_ID INT,
@replacement_ID INT
AS
BEGIN
DECLARE @ISONLEAVE BIT
DECLARE @REPLACED_EMP INT
DECLARE @EMP1_D VARCHAR(50)
DECLARE @EMP2_D VARCHAR(50)
DECLARE @START DATE
DECLARE @END DATE

SELECT @START=l.start_date,@END=l.end_date
FROM leave l
WHERE l.request_id=@request_ID

SET @ISONLEAVE=dbo.Is_On_Leave(@replacement_ID,@START,@END)

SELECT @REPLACED_EMP=al.emp_id
FROM annual_leave al
where al.request_id=@request_ID


SELECT @EMP1_D=e.dept_name
FROM Employee e
WHERE e.employee_ID=@REPLACED_EMP

SELECT @EMP2_D=e.dept_name
FROM Employee e
WHERE e.employee_ID=@replacement_ID

if (@EMP1_D=@EMP2_D AND @ISONLEAVE=0)
BEGIN 
INSERT INTO Employee_Approve_Leave(Emp1_ID,Leave_ID,status) VALUES
(@Upperboard_ID,@request_ID,'approved')
END

END
--missing 2.5 j-->n

GO
--2.5 k
CREATE PROC Submit_medical
@employee_ID int, 
@start_date date, 
@end_date date, 
@type varchar(50), 
@insurance_status bit,
@disability_details varchar(50),
@document_description varchar(50), 
@file_name varchar(50)
AS
BEGIN
DECLARE @LEAVE_ID INT
DECLARE @EMP_CONTRACT varchar(50)
DECLARE @gender char(1)

select @EMP_CONTRACT=e.type_of_contract, @gender=e.gender
from Employee e
where e.employee_ID=@employee_ID

if (@EMP_CONTRACT='part_time' and @type='maternity')or(@gender='F')
begin
print ('cant apply for maternity leave as a part time employee')
return;
end

INSERT INTO  [Leave] (date_of_request,start_date,end_date) 
VALUES (GETDATE(),@start_date,@end_date);

SET @LEAVE_ID= SCOPE_IDENTITY()

INSERT INTO medical_leave(request_ID,insurance_status,disability_details,type,emp_ID) 
VALUES(@LEAVE_ID,@insurance_status,@disability_details,@type,@employee_ID);

INSERT INTO Document(type,description,file_name,creation_date,emp_ID,medical_ID)
VALUES('medical report',@document_description,@file_name,GETDATE(),@employee_ID,@LEAVE_ID);

with empaprove as (select emp_ID
from Employee_Role er inner join [role] r
on r.role_name= er.role_name
where (r.role_name = 'HR Representative') or (r.role_name='Medical Doctor'))


INSERT INTO  Employee_Approve_Leave (Emp1_ID,leave_ID)
SELECT empaprove.emp_ID, @LEAVE_ID
FROM empaprove


END

GO
--2.5 M
CREATE PROC Submit_compensation
@employee_ID int,
@compensation_date date, 
@reason varchar(50), 
@date_of_original_workday date, 
@replacement_emp int
AS
BEGIN
DECLARE @Timespent TIME
DECLARE @LEAVE_ID INT

SELECT @Timespent=a.total_duration
FROM Attendance a
WHERE a.date=@date_of_original_workday and a.emp_ID=@employee_ID

if (@Timespent<'08:00:00' )OR (MONTH(@compensation_date)<>MONTH(@date_of_original_workday))
BEGIN
print('didnt work full day(8 hours) or month of compensation date isnt month of extra day')
END

INSERT INTO  [Leave] (date_of_request,start_date,end_date) 
VALUES (GETDATE(),@compensation_date,@compensation_date);

SET @LEAVE_ID= SCOPE_IDENTITY()

INSERT INTO compensation_leave(request_ID,reason,date_of_original_workday,emp_ID,replacement_emp)
VALUES(@LEAVE_ID,@reason,@date_of_original_workday,@employee_ID,@replacement_emp)

INSERT INTO Employee_Replace_Employee(Emp1_ID,Emp2_ID,from_date,to_date)
VALUES(@employee_ID,@replacement_emp,@compensation_date,@compensation_date)

with empaprove as (select emp_ID
from Employee_Role er inner join [role] r
on r.role_name= er.role_name
where r.role_name = 'HR Representative')


INSERT INTO  Employee_Approve_Leave (Emp1_ID,leave_ID)
SELECT empaprove.emp_ID, @LEAVE_ID
FROM empaprove

END

GO

--2.5 o
CREATE PROC Dean_andHR_Evaluation
@employee_ID INT,
@rating INT,
@comment VARCHAR(50),
@semester CHAR(3)
AS 
BEGIN
INSERT INTO Performance (rating,comments,semester,emp_ID) VALUES 
(@rating,@comment,@semester,@employee_ID)
END


go






























insert into Department (name,building_location)
values ('MET','C building')
insert into Department (name,building_location)
values ('BI','B building')
insert into Department (name,building_location)
values ('HR','N building')
insert into Department (name,building_location)
values ('Medical','B building')


insert into Employee (first_name,last_name,email,
password,address,gender,official_day_off,years_of_experience,
national_ID,employment_status, type_of_contract,emergency_contact_name,
emergency_contact_phone,annual_balance,accidental_balance,hire_date,
last_working_date,dept_name)
values  ('Jack','John','jack.john@guc.edu.eg','123','new cairo',
'M','Saturday',0,'1234567890123456','active','full_time',
'Sarah','01234567892',
30,6,'09-01-2025',null,'MET'),

('Ahmed','Zaki','ahmed.zaki@guc.edu.eg','345',
'New Giza',
'M','Saturday',2,'1234567890123457','active','full_time',
'Mona Zaki','01234567893',
27,0,'09-01-2020',NULL,'BI'), -- EMPLOYEE WITH ZERO ACCIDENTAL LEAVES

('Sarah','Sabry','sarah.sabry@guc.edu.eg','567',
'Korba',
'F','Thursday',5,'1234567890123458','active','full_time',
'Hanen Turk','01234567894',
0,4,'09-01-2020',NULL,'MET');

select * from Employee

insert into role (role_name,title,description,rank,base_salary,
percentage_YOE,percentage_overtime,annual_balance,
accidental_balance)
values ('President','Upper Board','Manage University',
1,100000,25.00,25.00,NULL,NULL)
insert into role (role_name,title,description,rank,base_salary,
percentage_YOE,percentage_overtime,annual_balance,
accidental_balance)
values ('Vice President','Upper Board','Helps the president.',
2,75000,20.00,20.00,NULL,NULL)
insert into role (role_name,title,description,rank,base_salary,
percentage_YOE,percentage_overtime,annual_balance,
accidental_balance)
values ('Dean','PHD Holder','Manage the Academic Department.',
3,60000,18.00,18.00,40,12)
insert into role (role_name,title,description,rank,base_salary,
percentage_YOE,percentage_overtime,annual_balance,
accidental_balance)
values ('Vice Dean','PHD Holder','Helps the Dean.',
4,55000,15.00,15.00,35,12)
insert into role (role_name,title,description,rank,base_salary,
percentage_YOE,percentage_overtime,annual_balance,
accidental_balance)
values ('HR Manager','Manager','Manage the HR Department.',
3,60000,18.00,18.00,40,12)
insert into role (role_name,title,description,rank,base_salary,
percentage_YOE,percentage_overtime,annual_balance,
accidental_balance)
values ('HR_Representative_MET','Representative','Assigned to MET department',
4,50000,15.00,15.00,35,12)
insert into role (role_name,title,description,rank,base_salary,
percentage_YOE,percentage_overtime,annual_balance,
accidental_balance)
values ('HR_Representative_BI','Representative','Assigned to BI department',
4,50000,15.00,15.00,35,12)
insert into role (role_name,title,description,rank,base_salary,
percentage_YOE,percentage_overtime,annual_balance,
accidental_balance)
values ('Lecturer','PHD Holder','Delivering Academic Courses.',
5,45000,12.00,12.00,30,12)
insert into role (role_name,title,description,rank,base_salary,
percentage_YOE,percentage_overtime,annual_balance,
accidental_balance)
values ('Teaching Assistant','Master Holder','Assists the Lecturer.',
6,40000,10.00,10.00,30,6)
insert into role (role_name,title,description,rank,base_salary,
percentage_YOE,percentage_overtime,annual_balance,
accidental_balance)
values ('Medical Doctor','Dr','Diagnosing and managing patients’health conditions',
null,35000,10.00,10.00,30,6)

insert into Employee_Role (emp_ID,role_name)
values (1,'Teaching Assistant') --MET
insert into Employee_Role (emp_ID,role_name)
values (2,'Teaching Assistant') --BI
insert into Employee_Role (emp_ID,role_name)
values (3,'Lecturer') --MET



INSERT INTO Deduction(emp_ID,date,amount,type) values
(1,'11-30-2025',2000,'missing_days'),
(1,'10-1-2025',2000,'missing_hours'),
(1,'12-31-2024',2000,'unpaid')


select *
from dbo.Deductions_Attendance(1,11)

select * from Deduction

