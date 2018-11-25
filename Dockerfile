FROM jgreat/drone-build-tag:0.1.0 as tagger

ENV APPLICATION_VERSION 0.0.1

WORKDIR /app
ADD ./ /app 
RUN build-tags.sh --include-feature-tag

FROM jgreat/helm-with-plugins
COPY --from=tagger /app/.tags ./
ADD publish-chart.sh /bin/
CMD [ "/bin/publish-chart.sh" ]
