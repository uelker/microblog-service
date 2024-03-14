FROM ubuntu:24.04

COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.8.1 /lambda-adapter /opt/extensions/lambda-adapter

WORKDIR /app

ARG APP_FILE
EXPOSE 8080

COPY target/${APP_FILE} /app/microblog-service
ENTRYPOINT ["./microblog-service"]
