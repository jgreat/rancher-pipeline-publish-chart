ARG HELM_VERSION

FROM jgreat/helm-with-plugins:${HELM_VERSION}

ADD ./publish-charts.sh /bin/publish-charts.sh

CMD [ "/bin/publish-chart.sh" ]