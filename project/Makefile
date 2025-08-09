.PHONY: build run test clean docker-up docker-down

# 构建应用
build:
	cd project && go build -o ../bin/financial-streams src/main.go

# 运行应用
run:
	cd project && go run src/main.go

# 运行测试
test:
	cd project && go test -v ./...

# 清理构建产物
clean:
	rm -rf bin/

# Docker相关命令
docker-up:
	cd docker && docker-compose up -d

docker-down:
	cd docker && docker-compose down

docker-build:
	cd docker && docker-compose build

docker-logs:
	cd docker && docker-compose logs -f

# 开发环境快速启动
dev: docker-up run

# 生产环境部署
deploy: docker-build docker-up