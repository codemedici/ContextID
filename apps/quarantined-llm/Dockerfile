## Dockerfile for the quarantined LLM placeholder service
# Mirrors the privileged container but runs on a different port
FROM python:3.11-slim

# Install minimal runtime dependencies
RUN pip install --no-cache-dir fastapi uvicorn

# Copy application code into the image
WORKDIR /app
COPY app.py .

# Expose the port used by the FastAPI server
EXPOSE 9090

# Launch the app with Uvicorn; replace with production server as needed
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "9090"]
