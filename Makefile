include .env
export

SERVER_IP=`cat ./.server_ip`

.PHONY: save-image copy-image run-remote rm-remote stop-remote deploy logs restart

build:
	docker build -t rebalancer ./

save-image:
	docker save -o ./rebalancer.tar.gz rebalancer

copy-image:
	scp -i ./deploykey  ./rebalancer.tar.gz rancher@$(SERVER_IP):/home/rancher/ && \
	ssh -i ./deploykey rancher@$(SERVER_IP) "docker load -i /home/rancher/rebalancer.tar.gz"

run-remote:
	ssh -i ./deploykey rancher@$(SERVER_IP) "docker run -dit --restart=always --name rebalancer -e API_KEY="""$(API_KEY)""" -e API_SECRET="""$(API_SECRET)""" -e TELEGRAM_API_TOKEN="""$(TELEGRAM_API_TOKEN)""" -e TELEGRAM_CHANNEL="""$(TELEGRAM_CHANNEL)""" -e USER_SECRET="""$(USER_SECRET)""" -e RUST_LOG="INFO,ureq=ERROR" rebalancer"

rm-remote:
	ssh -i ./deploykey rancher@$(SERVER_IP) "docker stop rebalancer || true" &&\
	ssh -i ./deploykey rancher@$(SERVER_IP) "docker rm rebalancer || true"

stop-remote:
	ssh -i ./deploykey rancher@$(SERVER_IP) "docker stop rebalancer || true"

deploy: build save-image copy-image rm-remote run-remote

logs:
	ssh -i ./deploykey rancher@$(SERVER_IP) "docker logs rebalancer"

restart:
	ssh -i ./deploykey rancher@$(SERVER_IP) "docker restart rebalancer"

release:
	cargo release