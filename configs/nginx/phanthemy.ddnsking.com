server {
    server_name phanthemy.ddnsking.com;

    root /var/www/portfolio-react;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
        add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0";
    }

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/phanthemy.ddnsking.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/phanthemy.ddnsking.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

}
server {
    if ($host = phanthemy.ddnsking.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80;
    server_name phanthemy.ddnsking.com;
    return 404; # managed by Certbot


}