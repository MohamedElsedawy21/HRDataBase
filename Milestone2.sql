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
  
        RETURN
    END

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
--2.4.C
GO
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

    -- Fix: Remove the extra END and RETURN that were in the middle of the code
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
GO
--2.4.F
CREATE PROC Deduction_days
@employee_ID int
AS
BEGIN
    DECLARE @rate_per_hour decimal(10,2),
            @daily_deduction decimal(10,2)

    SET @rate_per_hour = Rate_per_hour(@employee_ID)
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
EXEC Deduction_days @employee_ID = 1

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


GO