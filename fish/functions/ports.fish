function ports
    lsof -iTCP -sTCP:LISTEN -P -n
end
