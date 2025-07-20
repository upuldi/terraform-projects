#!/bin/bash
set -e
yum update -y
yum install -y httpd php
systemctl start httpd
systemctl enable httpd

# Get the private ALB DNS name from the terraform output
# In production, this would come from terraform output or parameter store
PRIVATE_ALB_DNS="${private_alb_dns_name}"

# Create enhanced public server page with private ALB integration
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Public Web Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f8ff; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { color: #333; border-bottom: 2px solid #2196F3; padding-bottom: 10px; }
        .info { background: #e3f2fd; padding: 15px; border-radius: 4px; margin: 10px 0; }
        .api-test { background: #f5f5f5; padding: 15px; border-radius: 4px; margin: 10px 0; border-left: 4px solid #4CAF50; }
        .meta { color: #666; font-size: 0.9em; }
        button { background: #4CAF50; color: white; padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; margin: 5px; }
        button:hover { background: #45a049; }
        button:disabled { background: #cccccc; cursor: not-allowed; }
        #result { background: #f9f9f9; padding: 10px; border-radius: 4px; margin-top: 10px; border: 1px solid #ddd; min-height: 50px; }
        .success { border-left: 4px solid #4CAF50; background-color: #f1f8e9; }
        .error { border-left: 4px solid #f44336; background-color: #ffebee; }
    </style>
    <script>
        async function testPrivateAPI(endpoint) {
            const resultDiv = document.getElementById('result');
            const buttons = document.querySelectorAll('button');
            
            // Disable all buttons during request
            buttons.forEach(btn => btn.disabled = true);
            resultDiv.innerHTML = '⏳ Loading...';
            resultDiv.className = '';
            
            try {
                const response = await fetch('/proxy.php?endpoint=' + encodeURIComponent(endpoint));
                const data = await response.text();
                
                if (response.ok) {
                    resultDiv.innerHTML = '<strong>✅ Success:</strong><br><pre>' + data + '</pre>';
                    resultDiv.className = 'success';
                } else {
                    resultDiv.innerHTML = '<strong>❌ Error:</strong><br><pre>' + data + '</pre>';
                    resultDiv.className = 'error';
                }
            } catch (error) {
                resultDiv.innerHTML = '<strong>❌ Network Error:</strong><br>' + error.message;
                resultDiv.className = 'error';
            } finally {
                // Re-enable all buttons
                buttons.forEach(btn => btn.disabled = false);
            }
        }
        
        // Test connectivity on page load
        window.onload = function() {
            setTimeout(() => testPrivateAPI('/api/status'), 1000);
        };
    </script>
</head>
<body>
    <div class="container">
        <h1 class="header">🌐 Public Web Server</h1>
        <div class="info">
            <p><strong>Status:</strong> Running in Public Subnet</p>
            <p><strong>Access:</strong> Internet → ALB → This Server</p>
            <p><strong>Instance ID:</strong> <code>INSTANCE_ID_PLACEHOLDER</code></p>
            <p><strong>Public IP:</strong> <code>PUBLIC_IP_PLACEHOLDER</code></p>
            <p><strong>Private IP:</strong> <code>PRIVATE_IP_PLACEHOLDER</code></p>
            <p><strong>AZ:</strong> <code>AZ_PLACEHOLDER</code></p>
            <p><strong>Private ALB:</strong> <code>$PRIVATE_ALB_DNS</code></p>
        </div>
        
        <div class="api-test">
            <h3>🔗 Private Backend Integration</h3>
            <p>Test connectivity to private ALB and backend services:</p>
            <button onclick="testPrivateAPI('/api/status')">🔍 Test Health Check</button>
            <button onclick="testPrivateAPI('/api/data')">📊 Get Backend Data</button>
            <div id="result">Click a button to test the private API...</div>
        </div>
        
        <div class="meta">
            <p>🌍 This server can communicate with private backend via internal ALB</p>
            <p>⏰ Server Time: SERVER_TIME_PLACEHOLDER</p>
        </div>
    </div>
</body>
</html>
EOF

# Replace placeholders with actual values
sed -i "s/INSTANCE_ID_PLACEHOLDER/$(curl -s http://169.254.169.254/latest/meta-data/instance-id)/" /var/www/html/index.html
sed -i "s/PUBLIC_IP_PLACEHOLDER/$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/" /var/www/html/index.html
sed -i "s/PRIVATE_IP_PLACEHOLDER/$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)/" /var/www/html/index.html
sed -i "s/AZ_PLACEHOLDER/$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)/" /var/www/html/index.html
sed -i "s/SERVER_TIME_PLACEHOLDER/$(date)/" /var/www/html/index.html

# Create proxy script for calling private ALB
cat > /var/www/html/proxy.php << EOF
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

\$privateAlbDns = '$PRIVATE_ALB_DNS';
\$endpoint = isset(\$_GET['endpoint']) ? \$_GET['endpoint'] : '/api/status';

// Validate endpoint
if (!preg_match('/^\/api\/(status|data)$/', \$endpoint)) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid endpoint']);
    exit;
}

// Build the full URL to the private ALB
\$url = 'http://' . \$privateAlbDns . \$endpoint;

// Use curl to make the request
\$ch = curl_init();
curl_setopt(\$ch, CURLOPT_URL, \$url);
curl_setopt(\$ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt(\$ch, CURLOPT_TIMEOUT, 10);
curl_setopt(\$ch, CURLOPT_CONNECTTIMEOUT, 5);
curl_setopt(\$ch, CURLOPT_USERAGENT, 'Public-Server-Proxy/1.0');

\$response = curl_exec(\$ch);
\$httpCode = curl_getinfo(\$ch, CURLINFO_HTTP_CODE);
\$error = curl_error(\$ch);

if (\$error) {
    http_response_code(502);
    echo json_encode([
        'error' => 'Failed to connect to private backend',
        'details' => \$error,
        'target_url' => \$url
    ]);
} else {
    http_response_code(\$httpCode);
    
    // Check if response is valid JSON
    \$jsonData = json_decode(\$response, true);
    if (json_last_error() === JSON_ERROR_NONE) {
        // Add proxy metadata
        \$jsonData['_proxy_info'] = [
            'proxied_by' => 'public-server',
            'target_url' => \$url,
            'timestamp' => date('c')
        ];
        echo json_encode(\$jsonData, JSON_PRETTY_PRINT);
    } else {
        // Return raw response if not JSON
        echo \$response;
    }
}

curl_close(\$ch);
?>
EOF

# Create a simple test endpoint for debugging
cat > /var/www/html/api-test.php << EOF
<?php
header('Content-Type: application/json');

\$tests = [
    'private_alb_dns' => '$PRIVATE_ALB_DNS',
    'curl_available' => function_exists('curl_init'),
    'instance_id' => trim(file_get_contents('http://169.254.169.254/latest/meta-data/instance-id')),
    'private_ip' => trim(file_get_contents('http://169.254.169.254/latest/meta-data/local-ipv4')),
    'test_urls' => [
        'http://$PRIVATE_ALB_DNS/api/status',
        'http://$PRIVATE_ALB_DNS/api/data'
    ]
];

echo json_encode(\$tests, JSON_PRETTY_PRINT);
?>
EOF
