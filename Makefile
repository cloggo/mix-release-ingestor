.PHONY: init_sample_project ingestor_build_image

ingestor_build_image:
	cd ingestor && mix docker.release

ingestor_get_deps:
	cd ingestor && mix deps.get

ingestor_compile: ingestor_get_deps
	cd ingestor && MIX_ENV=prod mix release

init_sample_project:
	mix new kv_umbrella --umbrella

init_server_app:
	cd kv_umbrella/apps && mix new kv_server --module KVServer --sup
	cd kv_umbrella/apps && mix new kv --module KV

test_sample:
	cd kv_umbrella && mix test

run_server:
	cd kv_umbrella && PORT=4321 mix run --no-halt

foo_release:
	cd kv_umbrella && MIX_ENV=prod mix release foo

bar_release:
	cd kv_umbrella && MIX_ENV=prod mix release bar

os_config_init:
	cd kv_umbrella && mix release.init

ingestor_os_config_init:
	cd ingestor && mix release.init

clean:
	$(RM) -rf kv_umbrella
