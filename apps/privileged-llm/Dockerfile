## Dockerfile for the privileged LLM placeholder service
# Uses a slim Python image to keep container size minimal
FROM python:3.11-slim

# Install minimal runtime dependencies
RUN pip install --no-cache-dir fastapi uvicorn

# Copy application code into the image
WORKDIR /app
COPY app.py .

# Expose the port used by the FastAPI server
EXPOSE 8080

# Launch the app with Uvicorn; replace with production server as needed
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8080"]
