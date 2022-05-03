.PHONY: build_image

build_image:
	cd ingestor && mix docker.release
