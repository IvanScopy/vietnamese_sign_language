"""
Authentication middleware for Socket.io connections.

Verifies JWT tokens using shared secret from Node.js API.
"""
import os
from typing import Optional
from jose import jwt, JWTError

SECRET_KEY = os.getenv('JWT_SECRET', 'dev-secret-change-in-production')
ALGORITHM = 'HS256'


async def verify_token(token: str) -> Optional[str]:
    """
    Verify JWT token and return user_id.

    Args:
        token: JWT token string from Socket.io auth

    Returns:
        user_id string if valid, None otherwise
    """
    if not token:
        return None

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        # Try common user ID field names
        return payload.get('sub') or payload.get('userId') or payload.get('user_id')
    except JWTError:
        return None
