podman build --format docker \
--tag lzj1769/print \
-f ./Dockerfile ./

podman push lzj1769/print:latest

