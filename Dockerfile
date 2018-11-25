FROM jgreat/helm-with-plugins

ADD publish-chart.sh /bin/
CMD [ "/bin/publish-chart.sh" ]
