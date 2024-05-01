alter table player_details modify L1_Status varchar(30);
alter table player_details modify L2_Status varchar(30);
alter table player_details modify P_ID int primary key;
alter table player_details drop myunknowncolumn
select * from player_details
alter table level_details2 drop myunknowncolumn;
alter table level_details2 change timestamp start_datetime datetime;
alter table level_details2 modify Dev_Id varchar(10);
alter table level_details2 modify Difficulty varchar(15);
alter table level_details2 add primary key(P_ID,Dev_id,start_datetime)
select * from level_details2
Rename Table level_details2 to ld
Rename Table player_details to pd
select * from pd
select * from ld
Select pd.P_ID,ld.Dev_Id,pd.PName,ld.Difficulty from pd INNER JOIN ld on pd.P_ID=ld.P_ID where ld.Level=0
select pd.L1_Code,AVG(ld.kill_Count) as avg_kill_count from pd inner join ld on pd.P_ID=ld.P_ID  
where ld.Lives_Earned=2 and ld.Stages_crossed >=3 group by pd.L1_Code
select ld.Difficulty,SUM(ld.Stages_Crossed) as total_stages_crossed from pd inner join ld on pd.P_ID=ld.P_ID 
where ld.Level=2 and ld.Dev_Id like 'zm_series%' group by ld.Difficulty order by total_stages_crossed desc
select P_ID , COUNT(DISTINCT DATE(start_datetime)) as unique_dates from ld group by P_ID having COUNT(DISTINCT DATE(start_datetime))>1 
SELECT ld.P_ID, ld.Level, SUM(ld.Kill_Count) AS Total_Kill_Count
FROM ld
JOIN pd ON ld.P_ID = pd.P_ID
WHERE ld.Kill_Count > (SELECT AVG(Kill_Count) FROM ld WHERE Difficulty = 'Medium')
GROUP BY ld.P_ID, ld.Level;
SELECT ld.Level, pd.L1_Code, SUM(Lives_Earned) AS Total_Lives_Earned
FROM ld
JOIN pd ON ld.P_ID = pd.P_ID
WHERE Level >0
GROUP BY ld.Level, pd.L1_Code
ORDER BY Level ASC;
WITH RankedScores AS (
    SELECT ld.Dev_Id, ld.Difficulty, ld.Score, ROW_NUMBER() OVER(PARTITION BY ld.Dev_Id ORDER BY ld.Score) AS Ranking
    FROM ld
)
SELECT Dev_Id, Difficulty, Score, Ranking
FROM RankedScores
WHERE Ranking <= 3
SELECT ld.Dev_Id, MIN(ld.start_datetime) AS first_login
FROM ld
GROUP BY Dev_ID;
WITH RankedScores AS (
    SELECT ld.Dev_Id, ld.Difficulty, ld.Score, RANK() OVER(PARTITION BY ld.Difficulty ORDER BY ld.Score) AS Ranking
    FROM ld
)
SELECT Dev_ID, Difficulty, Score, Ranking
FROM RankedScores
WHERE Ranking <= 5;
WITH FirstLogin AS (
    SELECT ld.P_ID, ld.Dev_Id, MIN(ld.start_datetime) AS first_login
    FROM ld
    GROUP BY ld.P_ID, ld.Dev_Id
)
SELECT P_ID, Dev_Id, first_login
FROM FirstLogin;
SELECT ld.P_ID, ld.start_datetime, ld.Kill_Count,
       SUM(kill_count) OVER (PARTITION BY ld.P_ID ORDER BY ld.start_datetime) AS total_kill_count_so_far
FROM ld;
select ld.P_ID, ld.start_datetime as date, sum(Kill_Count) as total_kill_count
from ld
group by ld.P_ID,  ld.start_datetime
WITH CumulativeStages AS (
    SELECT ld.P_ID, ld.start_datetime, ld.Stages_crossed,
           SUM(Stages_crossed) OVER (PARTITION BY ld.P_ID ORDER BY ld.start_datetime ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS cumulative_stages
    FROM ld
)
SELECT P_ID, start_datetime, Stages_crossed, cumulative_stages
FROM CumulativeStages;
WITH TopScores AS (
    SELECT Dev_Id, P_ID, SUM(score) AS total_score,
           ROW_NUMBER() OVER (PARTITION BY Dev_Id ORDER BY SUM(score) DESC) AS ranking
    FROM ld
    GROUP BY Dev_Id, P_ID
)
SELECT Dev_Id, P_ID, total_score
FROM TopScores
WHERE ranking <= 3;
SELECT P_ID 
FROM (
    SELECT P_ID, SUM(Score) as total_score 
    FROM ld 
    GROUP BY P_ID
) AS player_score 
WHERE total_score > 0.5 * (
    SELECT AVG(total_score) 
    FROM (
        SELECT SUM(Score) AS total_score 
        FROM ld 
        GROUP BY P_ID
    ) AS avg_scores
);
DELIMITER $$
Create Procedure Top_n_Headshots( IN n int)
Begin
Select Dev_Id,Headshots_Count,Difficulty,ranking 
from(Select Dev_Id, Headshots_Count,Difficulty,
Row_Number() Over ( Partition By Dev_Id Order by Headshots_Count Desc) as ranking
from ld) as ranked
where ranking <=n;
ENd
$$ Delimiter
call Top_n_Headshots(3) 