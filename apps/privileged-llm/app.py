"""Privileged LLM service placeholder.

This FastAPI app stands in for the privileged model that has broader
network access. Replace the stub endpoint with actual LLM inference code.
"""

from fastapi import FastAPI

app = FastAPI()


@app.get("/")
def read_root():
    """Health check endpoint."""
    return {"message": "Privileged LLM placeholder"}
