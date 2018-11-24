ARG HELM_VERSION

FROM jgreat/helm-with-plugins:${HELM_VERSION}

ADD publish-chart.sh /bin/

CMD [ "/bin/publish-chart.sh" ]