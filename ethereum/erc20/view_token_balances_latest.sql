CREATE OR REPLACE VIEW erc20.view_token_balances_latest AS
WITH token_prices AS (
    SELECT p.contract_address, price
    FROM prices.usd p
    INNER JOIN
        (SELECT contract_address, MAX(minute) AS latest_minute
        FROM prices.usd
        WHERE minute > now() - interval '1hour'
        GROUP BY contract_address) lp
    ON p.contract_address = lp.contract_address
    AND p.minute = lp.latest_minute
)

SELECT distinct on (wallet_address, token_address)
wallet_address,
token_address,
t.symbol as token_symbol,
amount_raw,
amount_raw / 10^coalesce(t.decimals, null) amount,
amount_raw / 10^coalesce(t.decimals, null) * p.price amount_usd,
timestamp as last_transfer_timestamp
FROM erc20.token_balances
left join erc20.tokens t on t.contract_address = token_address
left join token_prices p on p.contract_address = token_address
order by wallet_address, token_address, timestamp desc
