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
    create table Department (
    name varchar(50)primary key,
    building_location varchar (50)
    );

    -- ==========================
    -- Employee Table
    -- ==========================
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
          DEFAULT '' CHECK (employment_status IN ('active', 'onleave','notice_period','resigned')),
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


    -- ==========================
    -- Employee_Phone Table
    -- ==========================
    create table Employee_Phone(
    emp_ID int,
    phone_num char (11),
    foreign key(emp_ID) references Employee(employee_ID),
    primary key(emp_ID, phone_num)
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
    accidental_balance INT);


    -- ==========================
    -- Employee_Role Table
    -- ==========================
   CREATE TABLE Employee_Role (
    emp_ID INT,
    role_name VARCHAR(50),
    CONSTRAINT PK_Employee_Role PRIMARY KEY (emp_ID, role_name),
    CONSTRAINT FK_EmployeeRole_Employee FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID),
    CONSTRAINT FK_EmployeeRole_Role FOREIGN KEY (role_name) REFERENCES Role(role_name));
    -- ==========================
    -- Role_existsIn_Department Table
    -- ==========================
   CREATE TABLE Role_existsIn_Department (
    department_name VARCHAR(50),
    role_name VARCHAR(50),
    CONSTRAINT PK_Role_Dept PRIMARY KEY (department_name, role_name),
    CONSTRAINT FK_RoleDept_Dept FOREIGN KEY (department_name) REFERENCES Department(name),
    CONSTRAINT FK_RoleDept_Role FOREIGN KEY (role_name) REFERENCES Role(role_name));

    -- ==========================
    -- Leave Table 
    -- ==========================
    create table [leave] (
    request_id int identity(1,1) primary key,
    date_of_request date,
    start_date date,
    end_date date,
    num_days as datediff(day, start_date, end_date),
    final_approval_status varchar(50) CONSTRAINT DF_LeaveStatus DEFAULT 'pending',
        CONSTRAINT CK_LeaveStatus CHECK (final_approval_status IN ('rejected', 'pending','approved'))
    )


    -- ==========================
    -- Annual Leave
    -- ==========================
    create table annual_leave (
        request_id int primary key,
        emp_id int,
        replacement_emp int,
        foreign key (request_id) references [leave](request_id),
        foreign key (emp_id) references employee(employee_id),
        foreign key (replacement_emp) references employee(employee_id)
    );

    -- ==========================
    -- Accidental Leave
    -- ==========================
    create table accidental_leave (
        request_id int primary key,
        emp_id int,
        foreign key (request_id) references [leave](request_id),
        foreign key (emp_id) references employee(employee_id)
    );


    -- ==========================
    -- Medical Leave
    -- ==========================
    create table medical_leave (
        request_id int primary key,
        insurance_status bit,
        disability_details varchar(50),
        type varchar(50) CHECK (type in('sick','maternity')),
        emp_id int,
        foreign key (request_id) references [leave](request_id),
        foreign key (emp_id) references employee(employee_id)
    );


    -- ==========================
    -- Unpaid Leave
    -- ==========================
   create table unpaid_leave (
        request_id int primary key,
        emp_id int,
        foreign key (request_id) references [leave](request_id),
        foreign key (emp_id) references employee(employee_id)
    );


    -- ==========================
    -- Compensation Leave
    -- ==========================
    create table compensation_leave (
        request_id int primary key,
        reason varchar(50),
        date_of_original_workday date,
        emp_id int,
        replacement_emp int,
        foreign key (request_id) references [leave](request_id),
        foreign key (emp_id) references employee(employee_id),
        foreign key (replacement_emp) references employee(employee_id)
    );

    -- ==========================
    -- Document Table
    -- ==========================
    CREATE TABLE Document(
    document_ID int PRIMARY KEY IDENTITY(1,1),
    type varchar(50),
    description varchar(50), 
    file_name varchar(50), 
    creation_date date, 
    expiry_date date, 
    status varchar(50)
        DEFAULT 'valid' CHECK (status IN ('expired', 'valid')), 
    emp_ID int ,
    medical_ID int, 
    unpaid_ID int,
    FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID),
    FOREIGN KEY (medical_ID) REFERENCES medical_leave(request_ID),
    FOREIGN KEY (unpaid_ID) REFERENCES unpaid_leave(request_ID)
    );

    -- ==========================
    -- Payroll Table
    -- ==========================
   CREATE TABLE Payroll(
    ID int PRIMARY KEY IDENTITY(1,1),
    payment_date date, 
    final_salary_amount decimal (10,1), 
    from_date date, 
    to_date date, 
    comments varchar (150), 
    bonus_amount decimal (10,2), 
    deductions_amount decimal (10,2), 
    emp_ID int ,
    FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID));

    -- ==========================
    -- Attendance Table
    -- ==========================
    CREATE TABLE Attendance (
    attendance_ID int PRIMARY KEY IDENTITY(1,1), 
    date date, 
    check_in_time time,
    check_out_time time, 
    total_duration time, 
    status varchar (50) DEFAULT 'absent' CHECK (status IN ('attended', 'absent')), 
    emp_ID int,
    foreign key (emp_id) references employee(employee_id));


    -- ==========================
    -- Deduction Table
    -- ==========================

    CREATE TABLE Deduction (
    deduction_ID int IDENTITY(1,1),
    emp_ID int,
    FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID),
    date date,
    amount decimal (10,2),
    type varchar(50) CHECK (type IN ('unpaid', 'missing_hours', 'missing_days')),
    status varchar(50) DEFAULT 'pending' CHECK (status IN ('pending', 'finalized')),
    unpaid_ID int,
    FOREIGN KEY (unpaid_ID) REFERENCES unpaid_leave(request_ID),
    attendance_ID int,
    FOREIGN KEY (attendance_ID) REFERENCES attendance(attendance_ID),
    PRIMARY KEY (deduction_ID, emp_ID)
);



    -- ==========================
    -- Performance Table
    -- ==========================
    CREATE TABLE Performance (
    performance_ID int PRIMARY KEY IDENTITY(1,1), 
    rating int CHECK (rating between 1 and 5), 
    comments varchar (50), 
    semester char (3), 
    emp_ID int,
    foreign key(emp_ID) references Employee(employee_ID)
    ) ;


    -- ==========================
    -- Employee Replace Employee
    -- ==========================
    CREATE TABLE Employee_Replace_Employee(
    Emp1_ID int,
    FOREIGN KEY (Emp1_ID) REFERENCES Employee(employee_ID),
    Emp2_ID int,
    FOREIGN KEY (Emp2_ID) REFERENCES Employee(employee_ID),
    from_date date,
    to_date date,
    PRIMARY KEY (Emp1_ID, Emp2_ID)
);


    -- ==========================
    -- Employee Approve Leave
    -- ==========================
    CREATE TABLE Employee_Approve_Leave (
        Emp1_ID int, 
        Leave_ID int, 
        status varchar (50),
        foreign key (Leave_ID) references [leave](request_id),
        foreign key (Emp1_id) references employee(employee_id),
        PRIMARY KEY (Emp1_ID, Leave_ID)
    );

END;
GO

-- Execute procedure
EXEC createAllTables;

DROP PROC createAllTables;

GO
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
('Bob', 'Johnson', 'bob.johnson@example.com', 'bobpass', '789 Pine St', 'M', 'Wednesday', 7, '3456789012345678', 'active', 'full_time', 'Mary Johnson', '01122334455', 25, 7, 6000.00, '2019-06-20', NULL, 'Finance'),
('High', 'Balance', 'high.balance@example.com', 'pass123', '111 High St', 'M', 'Friday', 10, '1111111111111111', 'active', 'full_time', 'Contact High', '01111111111', 30, 15, 8000.00, '2018-01-01', NULL, 'IT'),
('Zero', 'Balance', 'zero.balance@example.com', 'pass123', '222 Zero St', 'F', 'Monday', 2, '2222222222222222', 'active', 'full_time', 'Contact Zero', '02222222222', 0, 0, 4000.00, '2023-01-01', NULL, 'HR'),
('Low', 'Balance', 'low.balance@example.com', 'pass123', '333 Low St', 'M', 'Wednesday', 1, '3333333333333333', 'active', 'full_time', 'Contact Low', '03333333333', 2, 1, 3000.00, '2024-01-01', NULL, 'Finance');
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
('Vice Dean_MET', 'Vice Dean', 'Assistant to Dean', 4, 6000.00, 3.0, 1.2, 50, 5),
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
('2025-11-05', '2025-11-15', '2025-11-25', 'approved'),
('2025-11-03', '2025-11-20', '2025-11-22', 'pending'),
('2024-01-02', '2024-01-15', '2024-01-17', 'pending'), -- 3 days (request 4)
('2024-01-03', '2024-01-20', '2024-01-30', 'pending'), -- 11 days (request 5)
('2024-01-04', '2024-02-05', '2024-02-05', 'pending'), -- 1 day (request 6)
-- Accidental leave test cases
('2024-01-05', '2024-02-10', '2024-02-12', 'pending'), -- 3 days (request 7)
('2024-01-06', '2024-02-15', '2024-02-25', 'pending'), -- 11 days (request 8)
('2024-01-07', '2024-03-01', '2024-03-01', 'pending');


-- Now delete from Leave
DELETE FROM [Leave]
WHERE request_id = 15;
select * from leave

INSERT INTO [Leave] (date_of_request, start_date, end_date, final_approval_status)
VALUES
('2024-01-04', '2024-02-05', '2024-02-25', 'pending')
-- ==========================
-- 8. Annual_Leave
-- ==========================
INSERT INTO Annual_Leave (request_id, emp_id, replacement_emp)
VALUES
(1, 1, 2),
(4, 9, 1), -- High balance employee (30 days) requesting 3 days - SHOULD APPROVE
(5, 5, 1), -- Zero balance employee (0 days) requesting 11 days - SHOULD REJECT
(6, 6, 1);

-- ==========================
-- 9. Accidental_Leave
-- ==========================
INSERT INTO Accidental_Leave (request_id, emp_id)
VALUES
(2, 2),
(7, 9), -- High balance employee (15 days) requesting 3 days - SHOULD APPROVE
(8, 5), -- Zero balance employee (0 days) requesting 11 days - SHOULD REJECT
(9, 6);

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
EXEC HR_approval_an_acc @request_ID = 4, @HR_ID = 2;

SELECT employee_ID, annual_balance FROM Employee WHERE employee_ID = 9;
SELECT * FROM [Leave] WHERE request_id = 4;

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
EXEC dbo.HR_approval_unpaid @request_ID = 3, @HR_ID = 2;
SELECT * FROM Leave WHERE request_ID = 3;

-------
GO
CREATE FUNCTION Overtime(@employee_ID INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    RETURN (
    SELECT ISNULL(SUM(
          CASE 
             WHEN DATEDIFF(HOUR, check_in_time, check_out_time) > 8 
             THEN DATEDIFF(HOUR, check_in_time, check_out_time) - 8
             ELSE 0
            END
        ), 0)

        FROM ATTENDANCE 
        WHERE 
            emp_ID = @employee_ID
            AND MONTH(date) = MONTH(GETDATE())
            AND YEAR(date) = YEAR(GETDATE())
            AND check_in_time IS NOT NULL
            AND check_out_time IS NOT NULL
            AND status = 'Present'
    )
END
-----
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
----
go
CREATE Function Rate_per_hour(@employee_ID INT)
RETURNS  Decimal(10,2) 
AS
BEGIN
DECLARE @salary Decimal(10,2),
        @Rate Decimal(10,2)
SET @salary = dbo.salary(@employee_ID)
SET @Rate= (@salary/22)/8
Return @Rate
END
GO
--2.4.F
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
        'missing day',
        'pending'
    FROM ATTENDANCE a
    WHERE 
        a.emp_ID = @employee_ID
        AND MONTH(a.date) = MONTH(GETDATE())
        AND YEAR(a.date) = YEAR(GETDATE())
        AND a.status = 'Absent'
END
-----
GO
CREATE FUNCTION Overtime(@employee_ID INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @total_overtime DECIMAL(10,2);

    SELECT @total_overtime = ISNULL(SUM(
        CASE 
            WHEN DATEDIFF(MINUTE, check_in_time, check_out_time) > 480  
            THEN CAST(DATEDIFF(MINUTE, check_in_time, check_out_time) - 480 AS DECIMAL(10,2)) / 60
            ELSE 0
        END
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
------
GO
CREATE FUNCTION Bonus_amount(@employee_ID int)
RETURNS  Decimal(10,2) 
AS
BEGIN
DECLARE @rate_per_hour Decimal(10,2),
        @bonus_value Decimal(10,2),
        @percentage_overtime decimal(4,2),
        @extra_hours INT
SET @rate_per_hour=Rate_per_hour(@employee_ID)
SET @extra_hours=overtime(@employee_ID)
 WITH HighestRankRole AS (
        SELECT TOP 1 
            R.percentage_overtime
        FROM Employee_Role ER
        INNER JOIN Role R ON ER.role_name = R.role_name
        INNER JOIN Employee E ON ER.emp_ID = E.employee_ID
        WHERE ER.emp_ID = @emp_ID
        ORDER BY R.rank ASC 
    )
    SELECT @percentage_overtime = percentage_overtime
    FROM HighestRankRole;

    SET @bonus_value= @rate_per_hour*(@extra_hours/100)
        


RETURN @bonus_value



END
GO
CREATE FUNCTION Overtime(@employee_ID INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @total_overtime DECIMAL(10,2);

    SELECT @total_overtime = ISNULL(SUM(
        CASE 
            WHEN DATEDIFF(MINUTE, check_in_time, check_out_time) > 480  
            THEN CAST(DATEDIFF(MINUTE, check_in_time, check_out_time) - 480 AS DECIMAL(10,2)) / 60
            ELSE 0
        END
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
------

CREATE FUNCTION Bonus_amount(@employee_ID INT)
RETURNS DECIMAL(10,2) 
AS
BEGIN
    DECLARE @rate_per_hour DECIMAL(10,2),
            @bonus_value DECIMAL(10,2),
            @percentage_overtime DECIMAL(4,2),
            @extra_hours DECIMAL(10,2)  

    SET @rate_per_hour = dbo.Rate_per_hour(@employee_ID)
    SET @extra_hours = dbo.Overtime(@employee_ID)

    WITH HighestRankRole AS (
        SELECT TOP 1 
            R.percentage_overtime
        FROM Employee_Role ER
        INNER JOIN Role R ON ER.role_name = R.role_name
        INNER JOIN Employee E ON ER.emp_ID = E.employee_ID
        WHERE ER.emp_ID = @employee_ID  
        ORDER BY R.rank ASC 
    )
    SELECT @percentage_overtime = ISNULL(percentage_overtime, 0)  
    FROM HighestRankRole;

    SET @bonus_value = @rate_per_hour * @extra_hours * (@percentage_overtime / 100.0)  

    RETURN ISNULL(@bonus_value, 0)
END
GO

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
      AND d.type IN ('missing_hours', 'missing_days')  -- Attendance-related deductions
);
GO
SELECT *
FROM dbo.Deductions_Attendance(1, 11);
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
GO
CREATE PROC Submit_annual
@employee_ID int, 
@replacement_emp int, 
@start_date date, 
@end_date date,
@rank int
AS 
DECLARE 
@LeaveRequestID int
BEGIN
SELECT @LeaveRequestID = request_ID
FROM (
    SELECT request_ID FROM Annual_Leave WHERE emp_ID = @EmployeeID
    UNION ALL
    SELECT request_ID FROM Accidental_Leave WHERE emp_ID = @EmployeeID
    UNION ALL
    SELECT request_ID FROM Medical_Leave WHERE emp_ID = @EmployeeID
    UNION ALL
    SELECT request_ID FROM Unpaid_Leave WHERE emp_ID = @EmployeeID
    UNION ALL
    SELECT request_ID FROM Compensation_Leave WHERE emp_ID = @EmployeeID
) AS AllRequests ;
insert into Employee_Approve_Leave (employee_ID, LeaveRequestID)
select E.employee_ID
from Employee E
INNER JOIN Employee_Role ER ON E.employee_ID = ER.emp_ID
INNER JOIN Role R ON ER.role_name = R.role_name
where E.employee_ID.RANK=3

end



