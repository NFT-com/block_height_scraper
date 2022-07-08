SELECT
    DISTINCT c.contract, c."name", n.type
FROM
    "collection" c
        LEFT JOIN "nft" n
                  ON c.contract = n.contract;