#!/usr/bin/env bash
# Hour and minute on separate lines, the way the waybar clock stacked them.
# Month and day are for the hover reveal, matching zenities' calendar-short.
date +'{"h":"%H","m":"%M","mon":"%b","d":"%d"}'
