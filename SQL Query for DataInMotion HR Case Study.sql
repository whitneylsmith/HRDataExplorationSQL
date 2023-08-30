-- SQL Case Study 2: Human Resources

--1. Find the longest ongoing project for each department.

--Insert extra data into 'projects' for a better test of the longest project for each department
--INSERT INTO projects (name, start_date, end_date, department_id)
--VALUES ('HR Project 2', '2023-01-12', '2023-07-30', 1),
--       ('IT Project 2', '2023-02-14', '2023-08-30', 2),
--       ('Sales Project 2', '2023-03-01', '2023-09-30', 3);

DROP TABLE IF EXISTS #project_days
CREATE TABLE #project_days (
	DepartmentID int,
	Department varchar(100),
	ProjectName varchar(100),
	Days int
)

INSERT INTO #project_days
SELECT p.department_id, d.name, p.name, DATEDIFF(DAY,p.start_date,p.end_date) Days
FROM projects p
JOIN departments d
ON p.department_id = d.id


DROP TABLE IF EXISTS #max_project_days
CREATE TABLE #max_project_days (
	Department varchar(100),
	MaxProjectDays int
)

INSERT INTO #max_project_days
SELECT Department, MAX(Days) AS MaxProjectDays
FROM #project_days
GROUP BY Department


SELECT max.Department, p_days.ProjectName, max.MaxProjectDays AS LongestProjectDays
FROM #max_project_days AS max
LEFT JOIN #project_days as p_days
ON max.Department = p_days.Department
AND max.MaxProjectDays = p_days.Days

--Drop temp tables
DROP TABLE IF EXISTS #project_days
DROP TABLE IF EXISTS #max_project_days

--2. Find all employees who are not managers.
SELECT name, job_title, department_id
FROM employees
WHERE LOWER(job_title) NOT LIKE '%manager%'


--3. Find all employees who have been hired after the start of a project in their department.
SELECT em.name AS EmployeesHiredAfterProjectStart
FROM employees em
FULL JOIN projects pr
ON em.department_id = pr.department_id
WHERE DATEDIFF(DAY,pr.start_date,em.hire_date) > 0
GROUP BY em.name


--4. Rank employees within each department based on their hire date (earliest hire gets the highest rank).
SELECT dep.name AS department, emp.name, 
	RANK() OVER(PARTITION BY emp.department_id ORDER BY hire_date) hiring_order,
	emp.hire_date
FROM employees emp
LEFT JOIN departments as dep
ON emp.department_id = dep.id
ORDER BY dep.name, hiring_order


--5. Find the duration between the hire date of each employee and the hire date of the next employee hired in the same department.

SELECT e1.name, e1.hire_date, dep.name AS department,
	DATEDIFF(day,e1.hire_date,e2.hire_date) AS days_before_next_employee_hired
FROM employees e1
LEFT JOIN employees e2
ON e1.department_id = e2.department_id
AND e1.hire_date < e2.hire_date
LEFT JOIN departments AS dep
ON e2.department_id = dep.id
WHERE DATEDIFF(day,e1.hire_date,e2.hire_date) IS NOT NULL
