#!/bin/bash
# Script to setup SSL certificate using Let's Encrypt (Certbot)
# Usage: ./setup-ssl.sh

set -e

DOMAIN="lms.septadenita.my.id"
EMAIL="admin@septadenita.my.id"  # Change this to your email
NGINX_CONFIG="/etc/nginx/sites-available/${DOMAIN}"

echo "========================================="
echo "SSL Certificate Setup for ${DOMAIN}"
echo "========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root (use sudo)"
    exit 1
fi

# Check if Certbot is installed
if ! command -v certbot &> /dev/null; then
    echo "Installing Certbot..."
    apt-get update
    apt-get install -y certbot python3-certbot-nginx
fi

# Check if Nginx is installed
if ! command -v nginx &> /dev/null; then
    echo "❌ Error: Nginx is not installed"
    echo "   Install it: sudo apt-get install nginx"
    exit 1
fi

# Check if domain is pointing to this server
echo "Checking if domain ${DOMAIN} points to this server..."
SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || echo "")
DOMAIN_IP=$(dig +short ${DOMAIN} | tail -1)

if [ -z "$DOMAIN_IP" ]; then
    echo "⚠ Warning: Could not resolve ${DOMAIN}"
    echo "   Make sure DNS A record points to this server's IP"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if Nginx config exists
if [ ! -f "$NGINX_CONFIG" ]; then
    echo "⚠ Warning: Nginx config file not found at ${NGINX_CONFIG}"
    echo "   Make sure you've copied nginx-reverse-proxy.conf to ${NGINX_CONFIG}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Get email if not set
if [ -z "$EMAIL" ] || [ "$EMAIL" = "admin@septadenita.my.id" ]; then
    read -p "Enter email for Let's Encrypt notifications: " EMAIL
fi

echo ""
echo "Obtaining SSL certificate for ${DOMAIN}..."
echo "Email: ${EMAIL}"
echo ""

# Obtain certificate using Nginx plugin (automatic configuration)
certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos --email ${EMAIL} --redirect

# Test Nginx configuration
echo ""
echo "Testing Nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✓ Nginx configuration is valid"
    echo ""
    echo "Reloading Nginx..."
    systemctl reload nginx
    echo "✓ Nginx reloaded"
else
    echo "❌ Nginx configuration test failed"
    exit 1
fi

# Setup auto-renewal (usually already enabled, but let's verify)
echo ""
echo "Setting up auto-renewal..."
systemctl enable certbot.timer
systemctl start certbot.timer

echo ""
echo "========================================="
echo "✓ SSL certificate setup completed!"
echo "========================================="
echo ""
echo "Your site should now be accessible at: https://${DOMAIN}"
echo ""
echo "Certificate will auto-renew. To test renewal:"
echo "  sudo certbot renew --dry-run"
echo ""

