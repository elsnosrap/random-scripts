#!/bin/bash
xclip -o -selection clipboard | python -mjson.tool | xclip -i -selection clipboard
