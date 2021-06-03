# shellcheck disable=SC2046
kill -9 $(lsof -i:1735 -t)
kill -9 $(lsof -i:1736 -t)
kill -9 $(lsof -i:1737 -t)
kill -9 $(lsof -i:1738 -t)
kill -9 $(lsof -i:1739 -t)
kill -9 $(lsof -i:1740 -t)
rm client* server* cmd history* latency
