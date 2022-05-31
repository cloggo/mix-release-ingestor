IMAGE_NAME := covalenthq/elrond
CONFIG_TAG := D1.2.24.0-covalent1.0.3

# network can we "mainnet", "testnet" or "devnet"
NETWORK := devnet

SRC = observing-squad/covalent

.PHONY: build-image

build-image:
	cd $(SRC) && docker build --build-arg CONFIG_TAG=$(CONFIG_TAG) --build-arg NETWORK=$(NETWORK) . -t $(IMAGE_NAME)-$(NETWORK)-$(CONFIG_TAG) -f ./observer/Dockerfile

build-multiarch-image:
	docker buildx use builder && cd $(SRC) && docker buildx build --platform=linux/amd64,linux/arm64 --build-arg CONFIG_TAG=$(CONFIG_TAG) --build-arg NETWORK=$(NETWORK) . -t $(IMAGE_NAME):$(NETWORK)-$(CONFIG_TAG) -f ./observer/Dockerfile --push

deploy:
	cd elrond-ansible && ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ansible_hosts site.yml
