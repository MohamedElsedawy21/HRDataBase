create database University_HR_ManagementSystem_Team_58;

use University_HR_ManagementSystem_Team_58;

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
        salary DECIMAL(10,2), 
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
        num_days AS DATEDIFF(DAY, start_date, end_date),
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
        total_duration TIME, 
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
        Emp1_ID INT,
        Emp2_ID INT,
        from_date DATE,
        to_date DATE,
        PRIMARY KEY (Emp1_ID, Emp2_ID),
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



-- Execute procedure
EXEC createAllTables;

DROP PROC createAllTables;

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

exec dropAllTables
drop proc dropAllTables
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
drop function MyPerformance --table valued function
drop function MyAttendance --table valued function
drop function Last_month_payroll--table valued function
drop function Deductions_Attendance --table valued function
drop function Is_On_Leave
drop procedure Submit_annual
drop function Status_leaves --table valued function
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
EXEC clearAllTables
DROP PROC clearAllTables









--------MOCK DATA BASE-----------
-- ==========================
-- 1. Department
-- ==========================
INSERT INTO Department (name, building_location)
VALUES
('HR', 'Building A'),
('IT', 'Building B'),
('Finance', 'Building C'),
('Medical', 'Building D'),
('MET', 'Building E'),
('IET', 'Building F'),
('Upper Board', 'Main Office');

-- ==========================
-- 2. Employee
-- ==========================
INSERT INTO Employee (first_name, last_name, email, password, address, gender, official_day_off, years_of_experience, national_ID, employment_status, type_of_contract, emergency_contact_name, emergency_contact_phone, annual_balance, accidental_balance, salary, hire_date, last_working_date, dept_name)
VALUES
('John', 'Doe', 'john.doe@example.com', 'pass123', '123 Main St', 'M', 'Friday', 5, '1234567890123456', 'active', 'full_time', 'Jane Doe', '01234567890', 20, 5, 5000.00, '2020-01-15', NULL, 'IT'),
('Alice', 'Smith', 'alice.smith@example.com', 'alice123', '456 Oak St', 'F', 'Monday', 3, '2345678901234567', 'active', 'part_time', 'Bob Smith', '09876543210', 15, 3, 3500.00, '2021-03-10', NULL, 'HR'),
('Bob', 'Johnson', 'bob.johnson@example.com', 'bobpass', '789 Pine St', 'M', 'Wednesday', 7, '3456789012345678', 'active', 'full_time', 'Mary Johnson', '01122334455', 25, 7, 6000.00, '2019-06-20', NULL, 'Finance');

-- ==========================
-- 3. Employee_Phone
-- ==========================
INSERT INTO Employee_Phone (emp_ID, phone_num)
VALUES
(1, '01234567890'),
(1, '09876543211'),
(2, '09876543210'),
(3, '01122334455');

-- ==========================
-- 4. Role
-- ==========================
INSERT INTO Role (role_name, title, description, rank, base_salary, percentage_YOE, percentage_overtime, annual_balance, accidental_balance)
VALUES
('President', 'President', 'Head of the organization', 1, 10000.00, 5.0, 2.0, 30, 10),
('Vice President', 'Vice President', 'Second in command', 2, 8000.00, 4.0, 1.5, 25, 8),
('Dean_MET', 'Dean', 'Head of MET department', 3, 7000.00, 3.5, 1.5, 25, 7),
('Vice Dean_MET', 'Vice Dean', 'Assistant to Dean', 4, 6000.00, 3.0, 1.2, 20, 5),
('Lecturer_MET', 'Lecturer', 'Teaching faculty', 5, 4000.00, 2.5, 1.0, 20, 5),
('TA_MET', 'Teaching Assistant', 'Assists lecturers', 6, 2500.00, 1.5, 0.8, 15, 3),
('HR Manager', 'HR Manager', 'Manages HR department', 3, 6000.00, 3.5, 1.5, 25, 7),
('HR Representative', 'HR Representative', 'Handles HR tasks', 4, 3500.00, 2.0, 1.0, 20, 5),
('Medical Doctor', 'Medical Doctor', 'Provides medical services', NULL, 7000.00, 3.0, 1.2, 20, 5);

-- ==========================
-- 5. Employee_Role
-- ==========================
INSERT INTO Employee_Role (emp_ID, role_name)
VALUES
(1, 'Lecturer_MET'),
(1, 'TA_MET'),
(2, 'HR Manager'),
(2, 'Lecturer_MET'),
(3, 'Medical Doctor');

-- ==========================
-- 6. Role_existsIn_Department
-- ==========================
INSERT INTO Role_existsIn_Department (department_name, role_name)
VALUES
('MET', 'Dean_MET'),
('MET', 'Vice Dean_MET'),
('MET', 'Lecturer_MET'),
('MET', 'TA_MET'),
('HR', 'HR Manager'),
('HR', 'HR Representative'),
('Medical', 'Medical Doctor'),
('Upper Board', 'President'),
('Upper Board', 'Vice President');

-- ==========================
-- 7. Leave
-- ==========================
INSERT INTO [Leave] (date_of_request, start_date, end_date, final_approval_status)
VALUES
('2025-11-01', '2025-11-10', '2025-11-12', 'approved'),
('2025-11-05', '2025-11-15', '2025-11-15', 'approved'),
('2025-11-03', '2025-11-20', '2025-11-22', 'pending');

-- ==========================
-- 8. Annual_Leave
-- ==========================
INSERT INTO Annual_Leave (request_id, emp_id, replacement_emp)
VALUES
(1, 1, 2);

-- ==========================
-- 9. Accidental_Leave
-- ==========================
INSERT INTO Accidental_Leave (request_id, emp_id)
VALUES
(2, 2);

-- ==========================
-- 10. Medical_Leave
-- ==========================
INSERT INTO Medical_Leave (request_id, insurance_status, disability_details, type, emp_id)
VALUES
(3, 1, 'None', 'sick', 3);

-- ==========================
-- 11. Unpaid_Leave
-- ==========================
INSERT INTO Unpaid_Leave (request_id, emp_id)
VALUES
(3, 1);

-- ==========================
-- 12. Compensation_Leave
-- ==========================
INSERT INTO Compensation_Leave (request_id, reason, date_of_original_workday, emp_id, replacement_emp)
VALUES
(2, 'Extra work', '2025-11-25', 2, 1);

-- ==========================
-- 13. Document
-- ==========================
INSERT INTO Document (type, description, file_name, creation_date, expiry_date, status, emp_ID, medical_ID, unpaid_ID)
VALUES
('Medical', 'Sick certificate', 'doc1.pdf', '2025-11-01', '2025-12-01', 'valid', 3, 3, NULL),
('Medical', 'Sick certificate', 'doc1.pdf', '2025-10-01', '2025-11-01', 'valid', 3, 3, NULL);

-- ==========================
-- 14. Payroll
-- ==========================
INSERT INTO Payroll (payment_date, final_salary_amount, from_date, to_date, comments, bonus_amount, deductions_amount, emp_ID)
VALUES
('2025-11-30', 5000.00, '2025-11-01', '2025-11-30', 'Monthly salary', 200.00, 50.00, 1);

-- ==========================
-- 15. Attendance
-- ==========================
INSERT INTO Attendance (date, check_in_time, check_out_time, total_duration, status, emp_ID)
VALUES
('2025-11-10', '09:00', '17:00', '08:00', 'attended', 1),
('2025-11-11', '09:15', '17:00', '07:45', 'attended', 1),
('2025-11-12', '09:00', '17:00', '08:00', 'absent', 1);

-- ==========================
-- 16. Deduction
-- ==========================
INSERT INTO Deduction (emp_ID, date, amount, type, status, unpaid_ID, attendance_ID)
VALUES
(1, '2025-11-12', 100.00, 'missing_hours', 'pending', NULL, 3);


-- ==========================
-- 17. Performance
-- ==========================
INSERT INTO Performance (rating, comments, semester, emp_ID)
VALUES
(5, 'Excellent', 'F21', 1),
(4, 'Good', 'F21', 2);

-- ==========================
-- 18. Employee_Replace_Employee
-- ==========================
INSERT INTO Employee_Replace_Employee (Emp1_ID, Emp2_ID, from_date, to_date)
VALUES
(1, 2, '2025-11-10', '2025-11-12');

-- ==========================
-- 19. Employee_Approve_Leave
-- ==========================
INSERT INTO Employee_Approve_Leave (Emp1_ID, Leave_ID, status)
VALUES
(2, 1, 'approved');

-----END OF MOCK DATABASE---------
















--2.2 a 
CREATE PROC  Update_Status_Doc
as 
Update Document 
Set status = 'expired'
Where
expiry_date >= CAST(GETDATE() AS DATE)
go

EXEC Update_Status_Doc
select * from Document

--2.2 b 
go

CREATE PROC  Remove_Deductions
as 
DELETE
FROM deductions WHERE employee_ID IN(
select employee_ID as r
from employee 
where employment_status = 'resigned' )
go
EXEC Remove_Deductions

--c missing

go
 --2.2 d
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
go
    --2.2 e

    CREATE PROCEDURE Add_Holiday
    @holiday_name VARCHAR(50),
    @from_date DATE,
    @to_date DATE
AS
INSERT INTO Holiday (name, from_date, to_date)
    VALUES (@holiday_name, @from_date, @to_date)


go
exec Add_Holiday


go
--2.2 i 
Create procedure Remove_DayOff
@Employee_id int
as 
delete a 
from Attendance a join employee e 
on a.emp_ID = e.employee_ID
where DAYNAME(a.date) = e.official_day_off
 go 
 exec Remove_DayOff  
 go 

 
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
        
        SELECT l.start_date, l.end_date, cl.emp_IDQ
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
    
   GO

   create procedure Replace_employee
   @Emp1_ID int,
   @Emp2_ID int,
   @from_date date,
   @to_date date
   as 
   insert into Employee_Replace_Employee (Emp1_ID , Emp2_ID, from_date ,to_date)
   values (  @Emp1_ID, @Emp2_ID , @from_date , @to_date )

   go

