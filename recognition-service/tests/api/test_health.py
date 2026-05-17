"""
Tests for health check and vocabulary endpoints.
"""

import pytest
from httpx import AsyncClient
from app.main import app


@pytest.mark.asyncio
async def test_health_returns_200(client: AsyncClient):
    """GET /health returns 200 status."""
    response = await client.get('/health')
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_health_contains_required_fields(client: AsyncClient):
    """Health response contains all required fields."""
    response = await client.get('/health')
    data = response.json()
    
    assert 'status' in data
    assert data['status'] == 'healthy'
    assert 'service' in data
    assert data['service'] == 'recognition'
    assert 'version' in data
    assert 'vocabulary_size' in data
    assert 'model_loaded' in data


@pytest.mark.asyncio
async def test_health_vocabulary_size(client: AsyncClient):
    """vocabulary_size matches actual vocabulary count."""
    response = await client.get('/health')
    data = response.json()
    
    from app.models.vocabulary import VOCABULARY
    assert data['vocabulary_size'] == len(VOCABULARY)


@pytest.mark.asyncio
async def test_vocabulary_endpoint(client: AsyncClient):
    """GET /vocabulary returns vocabulary list."""
    response = await client.get('/vocabulary')
    assert response.status_code == 200
    
    data = response.json()
    assert 'vocabulary' in data
    assert isinstance(data['vocabulary'], list)
    assert len(data['vocabulary']) >= 50


@pytest.mark.asyncio
async def test_vocabulary_endpoint_count(client: AsyncClient):
    """Vocabulary count matches expected."""
    response = await client.get('/vocabulary')
    data = response.json()
    
    from app.models.vocabulary import VOCABULARY
    assert data['count'] == len(VOCABULARY)


@pytest.mark.asyncio
async def test_readiness_check_ready(client: AsyncClient):
    """GET /ready returns 200 when service is ready."""
    response = await client.get('/ready')
    assert response.status_code == 200
    data = response.json()
    assert data['status'] == 'ready'
