--Common Table Expression (CTE) to identify and tag duplicate records
;
WITH DuplicateRecords AS (
	SELECT JourneyID,
		CustomerID,
		ProductID,
		VisitDate,
		Stage,
		Action,
		Duration,
		-- Use ROW_NUMBER() to assign a unique row number to each record within the partition defined below
		ROW_NUMBER() OVER (
			PARTITION BY CustomerID,
			ProductID,
			VisitDate,
			Stage,
			Action -- PARTITION BY groups the rows based on the specified columns that should be unique
			ORDER BY JourneyID -- ORDER BY defined how to order the rows within each partition (usually by a unique identifier like JourneyID)
		) AS row_num
	FROM dbo.customer_journey
)
SELECT *
FROM DuplicateRecords
WHERE row_num > 1
ORDER BY JourneyID --******************************************
SELECT JourneyID,
	CustomerID,
	ProductID,
	FORMAT(CONVERT(DATE, VisitDate), 'dd.MM.yyyy') AS VisitDate,
	Stage,
	Action,
	COALESCE(Duration, avg_duration) AS Duration
FROM (
		SELECT JourneyID,
			CustomerID,
			ProductID,
			VisitDate,
			UPPER(Stage) AS Stage,
			Action,
			Duration,
			AVG(Duration) OVER (PARTITION BY VisitDate) AS avg_duration,
			ROW_NUMBER() OVER (
				PARTITION BY CustomerID,
				ProductID,
				VisitDate,
				UPPER(Stage),
				Action
				ORDER BY JourneyID
			) AS row_num
		FROM dbo.customer_journey
	) AS subquery
WHERE row_num = 1;