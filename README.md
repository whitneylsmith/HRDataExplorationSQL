# HR Data Exploration in SQL

This is a case study hosted by DataInMotion, designed to utilize intermediate and advanced SQL skills.

Case Study information found here:  https://d-i-motion.com/courses/sql-case-studies/

### Questions to answer

#### 1. Find the longest ongoing project for each department.
   
First I inserted extra data into the `projects` table for a better test of the longest project for each department.
```
INSERT INTO projects (name, start_date, end_date, department_id)
VALUES ('HR Project 2', '2023-01-12', '2023-07-30', 1),
       ('IT Project 2', '2023-02-14', '2023-08-30', 2),
       ('Sales Project 2', '2023-03-01', '2023-09-30', 3);
```
Next I created a temp table to calculate and store the number of days between the start and end date. Because I used MS SQL Server for this project, I had to use the `DATEDIFF` function rather than subtracting the two dates.
```
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
```
I created another temp table to calculate the maximum difference in start and end date for each department.
```
DROP TABLE IF EXISTS #max_project_days
CREATE TABLE #max_project_days (
	Department varchar(100),
	MaxProjectDays int
)
INSERT INTO #max_project_days
SELECT Department, MAX(Days) AS MaxProjectDays
FROM #project_days
GROUP BY Department
```
Finally, I used a `JOIN` to include the name of the longest projects in a results table.
```
SELECT max.Department, p_days.ProjectName, max.MaxProjectDays AS LongestProjectDays
FROM #max_project_days AS max
LEFT JOIN #project_days as p_days
ON max.Department = p_days.Department
AND max.MaxProjectDays = p_days.Days
```
The results table with the longest project for each department is below:
| Department	|ProjectName		| LongestProjectDays |
|---------------|-----------------------|--------------------|
| HR		| HR Project 2		| 199
| IT		| IT Project 2		| 197
| Sales		| Sales Project 2	| 213

#### 2. Find all employees who are not managers.

For this question, I assumed that all managers would have the word 'manager' somewhere in their job title.
```
SELECT name, job_title, department_id
FROM employees
WHERE LOWER(job_title) NOT LIKE '%manager%'
```
| name          | job_title       | department_id |
|---------------|-----------------|---------------|
| Bob Miller    | HR Associate    | 1             |
| Charlie Brown | IT Associate    | 2             |
| Dave Davis    | Sales Associate | 3             |

#### 3. Find all employees who have been hired after the start of a project in their department.

For this question, I did a join on `employees` and `projects` to compare employee hire dates to project start dates.
```
SELECT em.name AS EmployeesHiredAfterProjectStart
FROM employees em
FULL JOIN projects pr
ON em.department_id = pr.department_id
WHERE DATEDIFF(DAY,pr.start_date,em.hire_date) > 0
GROUP BY em.name
```
| EmployeesHiredAfterProjectStart |
|---------------------------------|
| Dave Davis                      |

#### 4. Rank employees within each department based on their hire date (earliest hire gets the highest rank).

I joined the `employees` and `departments` tables and ranked each employee by hiring date within each department.
```
SELECT dep.name AS department, emp.name, 
	RANK() OVER(PARTITION BY emp.department_id ORDER BY hire_date) hiring_order,
	emp.hire_date
FROM employees emp
LEFT JOIN departments as dep
ON emp.department_id = dep.id
ORDER BY dep.name, hiring_order
```
| department | name          | hiring_order | hire_date  |
|------------|---------------|--------------|------------|
| HR         | John Doe      | 1            | 2018-06-20 |
| HR         | Bob Miller    | 2            | 2021-04-30 |
| IT         | Jane Smith    | 1            | 2019-07-15 |
| IT         | Charlie Brown | 2            | 2022-10-01 |
| Sales      | Alice Johnson | 1            | 2020-01-10 |
| Sales      | Dave Davis    | 2            | 2023-03-15 |

#### 5. Find the duration between the hire date of each employee and the hire date of the next employee hired in the same department.

I used a self join and the `DATEDIFF` function to calculate the difference between hire dates for the employees in each department.
```
SELECT e1.name, e1.hire_date, dep.name AS department,
	DATEDIFF(day,e1.hire_date,e2.hire_date) AS days_before_next_employee_hired
FROM employees e1
LEFT JOIN employees e2
ON e1.department_id = e2.department_id
AND e1.hire_date < e2.hire_date
LEFT JOIN departments AS dep
ON e2.department_id = dep.id
WHERE DATEDIFF(day,e1.hire_date,e2.hire_date) IS NOT NULL
```
| name          | hire_date  | department | days_before_next_employee_hired |
|---------------|------------|------------|---------------------------------|
| John Doe      | 2018-06-20 | HR         | 1045                            |
| Jane Smith    | 2019-07-15 | IT         | 1174                            |
| Alice Johnson | 2020-01-10 | Sales      | 1160                            |
