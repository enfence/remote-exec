#!/bin/bash
set -euo pipefail
[[ "${SSH_CLIENT:-}" = '127.0.0.1 '* || "${SSH_CLIENT:-}" = '::1 '* ]]
