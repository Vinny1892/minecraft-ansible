import pytest


def test_minecraft_running(host):
    assert host.socket("tcp://0.0.0.0:25565").is_listening
