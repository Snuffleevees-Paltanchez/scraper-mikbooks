# Based on https://gist.github.com/usr-ein/c42d98abca3cb4632ab0c2c6aff8c88a

# Base image
FROM python:3.12-slim as base

# Environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_VERSION=1.8.0 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv"

# Prepend poetry and venv to path
ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"

# Builder stage for installing poetry
FROM base as poetry-install
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        curl \
        build-essential

# Install poetry
RUN --mount=type=cache,target=/root/.cache \
    curl -sSL https://install.python-poetry.org | python3 - --version $POETRY_VERSION

# Copy project requirement files
WORKDIR $PYSETUP_PATH
COPY poetry.lock pyproject.toml ./

# Install runtime dependencies
RUN --mount=type=cache,target=/root/.cache \
    poetry install --without=dev

# Development stage
FROM base as development
WORKDIR $PYSETUP_PATH

# Copy built poetry and venv
COPY --from=poetry-install $POETRY_HOME $POETRY_HOME
COPY --from=poetry-install $PYSETUP_PATH $PYSETUP_PATH

# Faster install as runtime deps are already installed
RUN --mount=type=cache,target=/root/.cache \
    poetry install --without=dev

# Copy .env
# COPY .env.prod ./

# Set the working directory for the application
WORKDIR /app

# Expose port
# EXPOSE 8000

# Command to run the application
CMD ["python", "scraper.py"]

# Production stage
FROM base as production

# Copy project files
COPY --from=poetry-install $PYSETUP_PATH $PYSETUP_PATH
COPY . /app/

# Copy .env
# COPY .env.prod ./

# Set the working directory for the application
WORKDIR /app

# Command to run the application
CMD ["python", "scraper.py"]
