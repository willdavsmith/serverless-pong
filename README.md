# 🎮 Serverless Pong

A multiplayer Pong game built to demonstrate serverless architecture patterns across multiple platforms. The game uses Redis for session state management and can be deployed to AWS Lambda, Azure Functions, or Kubernetes using Radius.

## 🏗️ Architecture

This project demonstrates a truly portable serverless application:

- **State Management**: Redis for distributed session storage
- **Application Logic**: Platform-agnostic JavaScript (Node.js)
- **Deployment Options**:
  - Kubernetes (via Radius)
  - AWS Lambda (container image)
  - Azure Functions (container image)
  - Local development server

## 📁 Project Structure

```
pong/
├── bicepconfig.json          # Bicep configuration
├── pong.bicep                # Radius deployment definition
├── setup.sh                  # Quick setup script
├── pong/                     # Application source
│   ├── Dockerfile.local      # Local/Kubernetes container
│   ├── Dockerfile.lambda     # AWS Lambda container
│   ├── Dockerfile.azure      # Azure Functions container
│   ├── package.json
│   └── src/
│       ├── pong.js           # Core game logic
│       ├── local.js          # Express server adapter
│       ├── lambda.js         # AWS Lambda adapter
│       └── azure.js          # Azure Functions adapter
├── recipes/                  # Radius recipes
│   └── functions/
│       ├── kubernetes/       # Kubernetes recipe
│       ├── aws/              # AWS Lambda recipe
│       └── azure/            # Azure Functions recipe
└── types/
    └── functions.yaml        # Radius function type definition
```

## 🚀 Quick Start

### Prerequisites

- Node.js 18+
- Docker
- Redis (or use Docker to run Redis locally)

### Local Development

1. **Run the setup script**:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

2. **Start the development server**:
   ```bash
   cd pong
   npm run dev
   ```

3. **Open the game**:
   - Go to `http://localhost:3000`
   - Open in two browser windows to play multiplayer
   - Each player gets their own paddle (left or right)

### Environment Variables

The application uses the following environment variables:

- **Local/Kubernetes**: `CONNECTION_REDIS_URL` (automatically set by Radius)
- **AWS Lambda**: `REDIS_URL`
- **Azure Functions**: `REDIS_URL`

## 🐳 Container Images

Build platform-specific container images:

```bash
cd pong

# Build for local/Kubernetes deployment
npm run build:local

# Build for AWS Lambda
npm run build:lambda

# Build for Azure Functions
npm run build:azure

# Build all images
npm run build:all
```

Image tags:
- `pong-local:latest` - Local/Kubernetes deployment
- `pong-lambda:latest` - AWS Lambda deployment
- `pong-azure:latest` - Azure Functions deployment

## ☸️ Kubernetes Deployment with Radius

### Prerequisites

- [Radius CLI](https://docs.radapp.io/getting-started/) installed
- kubectl configured for your cluster
- kind (for local Kubernetes cluster)

### Deploy to Kubernetes

1. **Create a kind cluster** (if testing locally):
   ```bash
   kind create cluster --name pong
   ```

2. **Load the container image into kind**:
   ```bash
   cd pong
   npm run build:local
   kind load docker-image pong-local:latest --name pong
   ```

3. **Initialize Radius**:
   ```bash
   rad init
   ```

4. **Deploy the application**:
   ```bash
   rad deploy pong.bicep -p environment=<your-environment-id>
   ```

5. **Access the application**:
   ```bash
   kubectl port-forward svc/pong -n default-pong 3000:3000
   ```
   
   Then open `http://localhost:3000`

### What Gets Deployed

The Radius deployment creates:
- A pong container (port 3000)
- A Redis cache (managed by Radius)
- Automatic connection injection (Redis URL via secret)
- Kubernetes Service and Deployment resources

## 🔧 Development

### File Descriptions

- **`pong/src/pong.js`**: Core game logic with Redis session management. Platform-agnostic.
- **`pong/src/local.js`**: Express.js wrapper for local development and Kubernetes
- **`pong/src/lambda.js`**: AWS Lambda handler
- **`pong/src/azure.js`**: Azure Functions handler
- **`pong.bicep`**: Radius application definition using `Applications.Core/containers`
- **`recipes/functions/kubernetes/main.tf`**: Terraform recipe for Kubernetes deployment (not actively used with current Radius setup)

### Key Differences Between Files

The project contains two versions of `pong.js`:
- **`pong/src/pong.js`**: Uses `CONNECTION_REDIS_URL` (Radius convention)
- **`src/pong.js`**: Uses `REDIS_URL` (standard convention)

The `pong/src/pong.js` version is used for all deployments.

## 🎮 How to Play

1. Open the game URL in two browser windows
2. The first player controls the left paddle (player 1)
3. The second player controls the right paddle (player 2)
4. Click "Start Game" to begin the countdown
5. Move your paddle with your mouse
6. First to 5 points wins!

## 🔍 Troubleshooting

### Game starts but ball doesn't move

Check the browser console logs. The game requires:
- Both players to be connected
- The countdown to complete
- Player 1 to be active (player 1 runs the ball physics)

### Kind/Kubernetes image pull errors

Make sure to load the image into kind after building:
```bash
kind load docker-image pong-local:latest --name pong
```

### Redis connection issues

Check that:
- Redis is running and accessible
- Environment variables are set correctly
- For Kubernetes: Check the secrets are injected: `kubectl get secrets -n default-pong`

### Port-forward issues

If port-forwarding fails:
- Check the pod is running: `kubectl get pods -n default-pong`
- Check the pod logs: `kubectl logs -n default-pong <pod-name>`
- Verify the service: `kubectl get svc -n default-pong`

## 📚 Additional Resources

- [Radius Documentation](https://docs.radapp.io/)
- [Redis Documentation](https://redis.io/documentation)
- [Kind Documentation](https://kind.sigs.k8s.io/)

## 🤝 Contributing

This is a demonstration project showing serverless patterns across multiple platforms. Feel free to use it as a reference for building portable serverless applications!

## 📝 License

MIT
