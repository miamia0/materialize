#!/bin/sh

# Copyright 2020 Materialize, Inc. All rights reserved.
#
# This file is part of Materialize. Materialize may not be used or
# distributed without the express permission of Materialize, Inc.

psql -h materialized -p 6875 -d materialize << EOF
-- Flask request logs format
CREATE SOURCE requests FROM 'file:///log/requests' FORMAT REGEX '(?P<ip>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) - - \[(?P<ts>[^]]+)\] "(?P<path>(?:GET /search/\?kw=(?P<search_kw>[^ ]*) HTTP/\d\.\d)|(?:GET /detail/(?P<product_detail_id>[a-zA-Z0-9]+) HTTP/\d\.\d)|(?:[^"]+))" (?P<code>\d{3}) -' WITH (tail=true);

-- Average number of product detail pages viewed per IP that has viewed the
-- search page at least once
CREATE MATERIALIZED VIEW avg_dps_for_searcher AS SELECT avg(dp_hits) FROM (SELECT ip, count(product_detail_id) AS dp_hits, count(search_kw) AS search_hits FROM requests GROUP BY ip) WHERE search_hits > 0;

-- Number of unique IP hits
CREATE MATERIALIZED VIEW unique_visitors AS SELECT count(DISTINCT ip) FROM requests;

-- 40 products with the most hits
CREATE MATERIALIZED VIEW top_products AS SELECT count(product_detail_id) ct, product_detail_id from requests GROUP BY product_detail_id ORDER BY ct DESC LIMIT 40;
EOF
