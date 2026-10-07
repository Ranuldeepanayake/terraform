#!/bin/bash
set -euo pipefail

dnf install -y awscli
aws --version
