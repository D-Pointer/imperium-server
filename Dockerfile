FROM swift:4.1

WORKDIR /app

ADD swift /app/

RUN swift build

EXPOSE 11000

CMD ["swift", "run", "--skip-build", "imperium-server", "0.0.0.0", "11000"]

