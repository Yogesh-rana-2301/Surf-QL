# Write your MySQL query statement below
SELECT stock_name, sum(case when operation='Sell' then price else -price end) AS capital_gain_loss
From Stocks
GROUP BY stock_name;
