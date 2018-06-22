-- startup haproxy
/usr/local/haproxy/sbin/haproxy -f /etc/haproxy/haproxy.cfg

-- startup keepalived
service keepalived start