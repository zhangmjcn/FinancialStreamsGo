# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copy go mod files
COPY project/go.mod project/go.sum* ./

# Download dependencies
RUN go mod download

# Copy source code
COPY project/ ./

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o financial-streams src/main.go

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy the binary from builder
COPY --from=builder /app/financial-streams .

# Expose port (if needed)
EXPOSE 8080

# Run the application
CMD ["./financial-streams"]