#!/bin/bash
set -e
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# Create a simple API-like response for the private service
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Private Application Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f8ff; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { color: #333; border-bottom: 2px solid #4CAF50; padding-bottom: 10px; }
        .info { background: #e8f5e8; padding: 15px; border-radius: 4px; margin: 10px 0; }
        .meta { color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="header">🔒 Private Application Server</h1>
        <div class="info">
            <p><strong>Status:</strong> Running in Private Subnet</p>
            <p><strong>Access:</strong> Via Internal ALB Only</p>
            <p><strong>Instance ID:</strong> <code>$(curl -s http://169.254.169.254/latest/meta-data/instance-id)</code></p>
            <p><strong>Private IP:</strong> <code>$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)</code></p>
            <p><strong>AZ:</strong> <code>$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</code></p>
        </div>
        <div class="meta">
            <p>🛡️ This server is only accessible from public EC2 instances via internal ALB</p>
            <p>⏰ Server Time: $(date)</p>
        </div>
    </div>
</body>
</html>
EOF

# Install PHP for dynamic API responses
yum install -y php

# Create API endpoints directory
mkdir -p /var/www/html/api

# Create dynamic status endpoint
cat > /var/www/html/api/status.php << 'EOF'
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$instanceId = file_get_contents('http://169.254.169.254/latest/meta-data/instance-id');
$privateIp = file_get_contents('http://169.254.169.254/latest/meta-data/local-ipv4');

$response = [
    "status" => "healthy",
    "service" => "private-backend",
    "instance_id" => trim($instanceId),
    "private_ip" => trim($privateIp),
    "timestamp" => date('c'),
    "uptime" => trim(shell_exec('uptime'))
];

echo json_encode($response, JSON_PRETTY_PRINT);
?>
EOF

# Create dynamic data endpoint
cat > /var/www/html/api/data.php << 'EOF'
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$instanceId = file_get_contents('http://169.254.169.254/latest/meta-data/instance-id');

$response = [
    "message" => "Hello from private backend!",
    "data" => [
        "users" => rand(100, 200),
        "orders" => rand(1000, 2000),
        "revenue" => round(rand(50000, 100000) + (rand(0, 99) / 100), 2)
    ],
    "source" => "private-ec2-" . substr(trim($instanceId), -8),
    "timestamp" => date('c'),
    "random_fact" => "This data is served from a private subnet!"
];

echo json_encode($response, JSON_PRETTY_PRINT);
?>
EOF

# Create URL rewrite rules for clean API endpoints
cat > /var/www/html/.htaccess << 'EOF'
RewriteEngine On
RewriteRule ^api/status/?$ /api/status.php [L]
RewriteRule ^api/data/?$ /api/data.php [L]
EOF

# Enable mod_rewrite
echo "LoadModule rewrite_module modules/mod_rewrite.so" >> /etc/httpd/conf/httpd.conf

# Allow .htaccess overrides
sed -i 's/AllowOverride None/AllowOverride All/g' /etc/httpd/conf/httpd.conf

# Restart Apache to apply changes
systemctl restart httpd
