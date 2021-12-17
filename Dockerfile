FROM alpine:3.15

RUN apk add --update --no-cache bash wget inotify-tools \
    && rm -rf /var/cache/apk/*

WORKDIR /gimme

COPY gimme.sh .

ENTRYPOINT [ "/bin/bash" ]
CMD [ "./gimme.sh" ]
