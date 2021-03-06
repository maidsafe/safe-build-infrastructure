#!/usr/bin/env bash

function setup() {
    # This is to try and subvert the mysterious "Package 'python' has no installation candidate" error.
    sed -Ei 's/^(.*ubuntu.* main)$/\1 universe/' /etc/apt/sources.list
    # When installing python-pip, there are sometimes prompts for user input.
    # Declaring the DEBIAN_FRONTEND variable will bypass those prompts.
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
}

function install_python() {
    apt-get install -y python
    rc=$?
    while [[ $rc != 0 ]]
    do
        echo "Problem with python package availability. Trying again in 5 seconds..."
        sleep 5
        apt-get install -y python
        rc=$?
    done
}

function install_python_pip() {
    apt-get install -y python-pip
    rc=$?
    while [[ $rc != 0 ]]
    do
        echo "Problem with python-pip package availability. Trying again in 5 seconds..."
        sleep 5
        apt-get install -y python-pip
        rc=$?
    done
}

setup
install_python
install_python_pip
