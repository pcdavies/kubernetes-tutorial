#!/usr/bin/env bash
#
watch -n .25 curl -o /dev/null -s -w %{http_code} http://test.example.com:30000/iis/
