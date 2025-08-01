"""Quarantined LLM service placeholder.

This FastAPI app represents the quarantined model with restricted
network capabilities. Replace the stub endpoint with the isolated LLM
inference logic.
"""

from fastapi import FastAPI

# Instantiate FastAPI application
app = FastAPI()


@app.get("/")
def read_root():
    """Health check endpoint for the quarantined model."""
    return {"message": "Quarantined LLM placeholder"}
