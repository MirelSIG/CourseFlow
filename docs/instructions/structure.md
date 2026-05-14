# Estructura del Proyecto - Backend (CourseFlow)

Este documento detalla la arquitectura de directorios del backend de **CourseFlow**, diseñada específicamente para cumplir con los requerimientos de modularización, código limpio en inglés y el stack tecnológico (Python + PostgreSQL + Docker) solicitado para el proyecto pedagógico.

## Jerarquía de Directorios (Source Code)

Basado en el estado actual del repositorio, esta es la estructura de arquitectura backend:

```text
CourseFlow_Backend/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── config.py
│   ├── alembic/
│   │   └── env_1.py
│   ├── api/
│   │   ├── deps.py
│   │   └── v1/
│   │       ├── routes_auth.py
│   │       ├── routes_users.py
│   │       ├── routes_courses.py
│   │       ├── routes_applications.py
│   │       └── routes_waiting_list.py
│   ├── core/
│   │   ├── config.py
│   │   └── security.py
│   ├── db/
│   │   ├── base.py
│   │   └── session.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── course.py
│   │   ├── application.py
│   │   └── waiting_list.py
│   ├── schemas/
│   │   ├── __init__.py
│   │   ├── user_schema.py
│   │   ├── course_schema.py
│   │   ├── auth_schema.py
│   │   └── application_schema.py
│   ├── routes/
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   ├── courses.py
│   │   └── applications.py
│   └── utils/
│       ├── __init__.py
│       └── decorators.py
├── tests/
│   └── test_health.py
├── docs/
├── project/
│   ├── instructions/
│   └── stories/
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
├── README.md
└── .env.example
```