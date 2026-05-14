# ============================
#   BASE IMAGE
# ============================
FROM python:3.11-slim

# ============================
#   WORKDIR
# ============================
WORKDIR /app

# ============================
#   INSTALL SYSTEM DEPENDENCIES
# ============================
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# ============================
#   INSTALL PYTHON DEPENDENCIES
# ============================
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ============================
#   COPY PROJECT
# ============================
COPY . .

# ============================
#   EXPOSE PORT
# ============================
EXPOSE 8000

# ============================
#   START SERVER
# ============================
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
