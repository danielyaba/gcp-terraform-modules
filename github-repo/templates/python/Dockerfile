FROM python:alpine3.17

# LABEL name="Python Flask Demo App" 
# LABEL version="0.1.0"
# LABEL org.opencontainers.image.source="https://github.com/danielyaba/adct-python-flask"

RUN adduser -D worker
USER worker
WORKDIR /home/worker

ENV PATH="/home/worker/.local/bin:${PATH}"

COPY --chown=worker:worker /src .
RUN pip install --upgrade pip --no-cache-dir --user -r requirements.txt

RUN pylint ./**/*.py

EXPOSE 8080

CMD ["python", "-m", "flask", "run", "--host=0.0.0.0", "-p 8080"]