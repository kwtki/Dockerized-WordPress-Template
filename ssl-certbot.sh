events {
    worker_connections 1024;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    gzip on;
    gzip_disable "msie6";
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    open_file_cache max=10000 inactive=30s;
    open_file_cache_valid 60s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;

    limit_conn_zone $binary_remote_addr zone=addr:10m;
    limit_req_zone $binary_remote_addr zone=req_limit_per_ip:10m rate=5r/s;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "no-referrer-when-downgrade";

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log warn;

    server {
        listen 443 ssl;
        server_name kkawataki.com www.kkawataki.com;

        ssl_certificate /etc/letsencrypt/live/kkawataki.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/kkawataki.com/privkey.pem;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-SHA384';

        # Use the domain name to dynamically set the root directory
        set $domain_name 'kkawataki.com'; # Set default domain name
        if ($host ~* (.+)) {
            set $domain_name $1;
        }

        root /var/www/$domain_name/html;
        index index.php index.html index.htm;

        error_page 404 /404.html;
        error_page 500 502 503 504 /50x.html;

        # Cache static assets
        location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|webp|woff|woff2|ttf|eot)$ {
            expires 30d;
            add_header Cache-Control "public, no-transform";
            try_files $uri $uri/ =404;
        }

        # Serve other content, let Nginx handle routing
        location / {
            try_files $uri $uri/ /index.php?$args; # This line handles pretty permalinks correctly
        }

        # PHP processing via PHP-FPM
        location ~ \.php$ {
            try_files $uri =404;
            fastcgi_pass wordpress_app:9000;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
        }

        # Deny access to hidden files, such as .htaccess
        location ~ /\. {
            deny all;
        }

        location = /404.html {
            internal;
        }

        location = /50x.html {
            internal;
        }
    }
}
