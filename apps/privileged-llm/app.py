"""Privileged LLM service placeholder.

This FastAPI app stands in for the privileged model that has broader
network access. Replace the stub endpoint with actual LLM inference code.
"""

from fastapi import FastAPI

# Instantiate FastAPI application
app = FastAPI()


@app.get("/")
def read_root():
    """Health check endpoint for the privileged model."""
    return {"message": "Privileged LLM placeholder"}
