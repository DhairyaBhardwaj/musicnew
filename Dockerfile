FROM nikolaik/python-nodejs:python3.10-nodejs19

# Fix Debian source issues & install ffmpeg + aria2
RUN sed -i 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g' /etc/apt/sources.list && \
    sed -i '/security.debian.org/d' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg aria2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy app files
COPY . /app/
WORKDIR /app/

# Install dependencies
RUN python -m pip install --no-cache-dir --upgrade pip
RUN pip3 install --no-cache-dir --upgrade --requirement requirements.txt

# --- Render Free Plan Fix ---
# Add environment variable and expose dummy web port
ENV PORT=8080
EXPOSE 8080

# Create a small Python script to keep Render happy
# (runs alongside your bot to open a port)
RUN echo 'import threading, http.server, socketserver;' \
    'PORT=8080;' \
    'Handler=http.server.SimpleHTTPRequestHandler;' \
    'def serve():' \
    ' httpd=socketserver.TCPServer(("0.0.0.0", PORT), Handler);' \
    ' print("[INFO] Dummy web server running on port", PORT);' \
    ' httpd.serve_forever();' \
    'threading.Thread(target=serve, daemon=True).start();' \
    'import subprocess; subprocess.call(["bash", "start"])' \
    > run.py

# Start both the bot and dummy server
CMD ["python3", "run.py"]
