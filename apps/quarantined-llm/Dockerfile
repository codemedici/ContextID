# Simple FastAPI container for quarantined LLM placeholder
FROM python:3.11-slim

# Install minimal runtime dependencies
RUN pip install --no-cache-dir fastapi uvicorn

# Copy application code
WORKDIR /app
COPY app.py .

# Expose service port
EXPOSE 9090

# Run the FastAPI server
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "9090"]
