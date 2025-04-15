# Dockerfile


# Using slim-bullseye for a smaller image size
FROM python:3.13-slim-bullseye as builder

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    # Poetry settings:
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    # Set path where Poetry installs packages inside the container
    POETRY_HOME="/opt/poetry" \
    # Set path for Poetry's cache
    POETRY_CACHE_DIR="/opt/.cache"

# Add Poetry to PATH
ENV PATH="$POETRY_HOME/bin:$PATH"

# Install Poetry
# Why install Poetry? We need it inside the container to install dependencies defined in pyproject.toml
RUN apt-get update && apt-get install --no-install-recommends -y curl \
    && curl -sSL https://install.python-poetry.org | python3 - \
    && apt-get remove -y curl && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the working directory in the container
WORKDIR /app

# Copy only the dependency definition files first
# Why? Leverage Docker layer caching. These files change less often than source code.
# If they don't change, Docker reuses the layer where dependencies are installed.
COPY pyproject.toml poetry.lock ./

# Install project dependencies using Poetry
# Why --no-root? Don't install the project package itself yet.
# Why --no-dev? Exclude development dependencies (like pytest) for a smaller production image.
# Why --sync? Ensures the environment exactly matches the lock file, removing unused deps.
RUN poetry install --no-root --sync

# --- Stage 2: Runtime Stage ---
# Use a fresh slim image for the final runtime environment
FROM python:3.13-slim-bullseye as runtime

# Set environment variables (can be overridden by docker-compose)
ENV PYTHONUNBUFFERED=1 \
    # Set the path where packages were installed by Poetry in the builder stage
    PYTHONPATH="/app/.venv/lib/python3.13/site-packages" \
    # Add Poetry's venv bin to PATH if needed, though we use absolute path in CMD
    PATH="/app/.venv/bin:$PATH" \
    # Set default host and port (can be overridden)
    APP_HOST="0.0.0.0" \
    APP_PORT="8000"

# Set the working directory
WORKDIR /app

# Copy installed dependencies from the builder stage's virtual environment
# Why? Copies the already installed packages, avoiding reinstalling them.
# Adjust python3.X based on your Python version if needed.
COPY --from=builder /app/.venv /app/.venv

# Copy the application source code
# Why copy src? This contains our actual FastAPI application code.
COPY src/ ./src/

# Copy the .env file - Alternative: Use Docker Compose env_file (recommended)
# COPY .env ./
# Note: Copying .env into the image isn't ideal for secrets.
# Using Docker Compose's `env_file` is generally better.

# Expose the port the app runs on
# Why? Informs Docker that the container listens on this port.
EXPOSE ${APP_PORT}

# Define the command to run the application
# Why 0.0.0.0? Makes the server accessible from outside the container network (required in Docker).
# Why poetry run? Although we copied the venv, using `poetry run` is explicit.
# Alternative CMD using direct python path from copied venv:
# CMD ["/app/.venv/bin/uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
CMD uvicorn src.main:app --host ${APP_HOST} --port ${APP_PORT}