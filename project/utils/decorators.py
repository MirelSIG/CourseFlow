import os
from fastapi import Request, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError

from project.utils.errors import error_response, forbidden_error
from project.utils.enums import Role

# Mock temporal para la lista negra de tokens hasta que se integre con BD (BE-01)
BLACKLIST = set()

# TODO: Mover a config.py
SECRET_KEY = os.environ.get("JWT_SECRET_KEY", "super-secret-key")
ALGORITHM = "HS256"

# Jerarquía de roles: user < admin < superadmin
ROLE_HIERARCHY = {
    Role.USER.value: 1,
    Role.ADMIN.value: 2,
    Role.SUPERADMIN.value: 3
}

security = HTTPBearer(auto_error=False)

async def require_auth(request: Request, token: HTTPAuthorizationCredentials = Depends(security)):
    """
    Dependencia de FastAPI que extrae el token JWT del header Authorization,
    valida su integridad, expiración y si está en la lista negra.
    Inyecta request.state.current_user con la información del token.
    """
    if not token:
        error_response(401, "Missing or invalid authorization header")
        
    token_str = token.credentials
    
    if token_str in BLACKLIST:
        error_response(401, "Token has been revoked")

    try:
        payload = jwt.decode(token_str, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("user_id")
        role = payload.get("role")
        
        if user_id is None or role is None:
            error_response(401, "Invalid token payload")
            
        request.state.current_user = {
            "id": user_id,
            "role": role
        }
        
        return request.state.current_user
    except jwt.ExpiredSignatureError:
        error_response(401, "Token has expired")
    except JWTError:
        error_response(401, "Invalid token")

def require_role(roles: list[Role]):
    """
    Generador de dependencia que comprueba que el usuario autenticado tiene permisos
    suficientes basados en una lista de roles permitidos y su jerarquía.
    """
    def role_checker(request: Request, user: dict = Depends(require_auth)):
        user_role = user.get("role")
        user_level = ROLE_HIERARCHY.get(user_role, 0)
        
        allowed_roles = [r.value if hasattr(r, "value") else r for r in roles]
        min_required_level = min(
            [ROLE_HIERARCHY.get(r, 99) for r in allowed_roles], 
            default=99
        )
        
        # Si el nivel del usuario es igual o mayor al mínimo requerido, pasa.
        if user_level >= min_required_level:
            return user
            
        forbidden_error()
        
    return role_checker
