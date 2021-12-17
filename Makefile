#
# gimme
#

IMAGE := edaniszewski/gimme

.PHONY: docker run

docker:
	docker build -t ${IMAGE}:latest .

run: docker
	docker run -d -v ${PWD}/gimme:/mount --name gimme ${IMAGE}:latest
