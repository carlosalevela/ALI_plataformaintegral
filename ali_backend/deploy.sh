#!/bin/bash

# Deployment script for Azure App Service

echo "Starting deployment..."

# Navigate to deployment directory
cd /home/site/wwwroot

# Create virtual environment if it doesn't exist
if [ ! -d "antenv" ]; then
    echo "Creating virtual environment..."
    python -m venv antenv
fi

# Activate virtual environment
source antenv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install dependencies
echo "Installing dependencies from requirements.txt..."
pip install -r requirements.txt

# Collect static files (if needed)
# python manage.py collectstatic --noinput

echo "Deployment completed successfully!"