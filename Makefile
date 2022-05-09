.PHONY: init_sample_project ingestor_build_image

ingestor_build_image:
	cd ingestor && mix docker.release


init_sample_project:
	mix new kv_umbrella --umbrella

init_server_app:
	cd kv_umbrella/apps && mix new kv_server --module KVServer --sup
	cd kv_umbrella/apps && mix new kv --module KV

test_sample:
	cd kv_umbrella && mix test

run_server:
	cd kv_umbrella && PORT=4321 mix run --no-halt
clean:
	$(RM) -rf kv_umbrella
