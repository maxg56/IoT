# Simple Makefile to up and test the connection

all: up

up: 
	vagrant up

down:
	vagrant destroy -f

test:
	sh scripts/test.sh

.PHONY: all up down test