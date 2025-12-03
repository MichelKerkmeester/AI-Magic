# Media Editor MCP Server Installation Guide

A comprehensive guide to installing, configuring, and using the Imagician and Video-Audio MCP servers for AI-powered media editing.

---

## 🤖 AI-FIRST INSTALL GUIDE

**Copy and paste this prompt to your AI assistant to get installation help:**

```
I want to install the Media Editor MCP servers (Imagician + Video-Audio) for image and video processing.

Please help me:
1. Check if I have Docker Desktop installed and running
2. Set up the folder structure for Media Editor workspace
3. Clone the imagician and video-audio repositories
4. Configure the Docker volume paths for my system
5. Build and start the Docker containers
6. Configure the MCP servers for my environment (I'm using: [Claude Desktop / OpenCode / VS Code Copilot])
7. Verify both servers are working with test commands

My preferred media workspace location is: [your path]

Guide me through each step with the exact commands I need to run.
```

**What the AI will do:**
- Verify Docker Desktop is installed and running
- Create proper folder structure for media files (Original/New directories)
- Clone and configure both MCP server repositories
- Update volume paths in docker-compose files
- Build and start Docker containers
- Configure MCP servers for your AI platform
- Test image and video processing capabilities
- Show you how to use the available tools effectively

**Expected setup time:** 15-20 minutes

---

#### 📋 TABLE OF CONTENTS

1. [📖 OVERVIEW](#1--overview)
2. [📋 PREREQUISITES](#2--prerequisites)
3. [📥 INSTALLATION](#3--installation)
4. [⚙️ CONFIGURATION](#4-️-configuration)
5. [✅ VERIFICATION](#5--verification)
6. [🚀 USAGE](#6--usage)
7. [🎯 FEATURES](#7--features)
8. [💡 EXAMPLES](#8--examples)
9. [🔧 TROUBLESHOOTING](#9--troubleshooting)
10. [📚 RESOURCES](#10--resources)

---

## 1. 📖 OVERVIEW

The Media Editor MCP system provides AI-powered image and video processing through two complementary MCP servers running in Docker containers. This enables Claude and other AI assistants to perform sophisticated media editing operations.

### Key Features

- **Image Processing (Imagician)**: Resize, crop, rotate, compress, convert, apply filters
- **Video Processing (Video-Audio)**: Trim, merge, extract audio, add subtitles, convert formats
- **Audio Extraction**: Separate audio tracks from video files
- **HLS Conversion**: Create streaming-ready video content
- **Batch Processing**: Handle multiple files efficiently
- **Docker Isolation**: Clean, reproducible environment

### Two-Server Architecture

| Server          | Technology      | Purpose                           |
| --------------- | --------------- | --------------------------------- |
| **Imagician**   | Node.js + Sharp | High-performance image processing |
| **Video-Audio** | Python + FFmpeg | Video/audio manipulation          |

```
┌─────────────────────────────────────────────────────────────┐
│                    Your AI Assistant                         │
│  (Claude Desktop, OpenCode, VS Code Copilot, etc.)          │
└──────────────────────┬──────────────────┬───────────────────┘
                       │                  │
                       ▼                  ▼
┌─────────────────────────────┐  ┌────────────────────────────┐
│   Imagician MCP Server      │  │  Video-Audio MCP Server    │
│   (Docker: imagician)       │  │  (Docker: video-audio)     │
│   • Image resize/crop       │  │  • Video trim/merge        │
│   • Format conversion       │  │  • Audio extraction        │
│   • Filters and effects     │  │  • HLS conversion          │
└──────────────┬──────────────┘  └─────────────┬──────────────┘
               │                               │
               ▼                               ▼
┌─────────────────────────────┐  ┌────────────────────────────┐
│  /images (Docker Volume)    │  │  /videos (Docker Volume)   │
│  ├── Original/              │  │  ├── Original/             │
│  └── New/                   │  │  └── New/                  │
└─────────────────────────────┘  └────────────────────────────┘
```

---

## 2. 📋 PREREQUISITES

Before installing the Media Editor MCP servers, ensure you have:

### Required

- **Docker Desktop** installed and running
  ```bash
  # Verify Docker is running
  docker --version
  docker ps
  
  # If not installed: https://www.docker.com/products/docker-desktop
  ```

- **Claude Desktop** (or other MCP-compatible client)
  ```bash
  # Download from: https://claude.ai/download
  ```

- **Git** for cloning repositories
  ```bash
  git --version
  ```

### Recommended

- **At least 4GB RAM** available for Docker
- **10GB+ free disk space** for Docker images and media files
- **Terminal/Shell** access (Terminal on macOS, PowerShell on Windows)

---

## 3. 📥 INSTALLATION

### Step 1: Create Folder Structure

Create a dedicated directory for the Media Editor system:

```bash
# Create main directory
mkdir -p ~/MCP\ Servers/Media\ Editor

# Create media working directories
mkdir -p ~/MCP\ Servers/Media\ Editor/export/images/Original
mkdir -p ~/MCP\ Servers/Media\ Editor/export/images/New
mkdir -p ~/MCP\ Servers/Media\ Editor/export/videos/Original
mkdir -p ~/MCP\ Servers/Media\ Editor/export/videos/New

# Navigate to MCP Servers directory
cd ~/MCP\ Servers
```

### Step 2: Clone Repositories

```bash
# Clone Imagician (Image Processing)
git clone https://github.com/flowy11/imagician.git
cd imagician

# Clone Video-Audio (Video/Audio Processing)
cd ~/MCP\ Servers
git clone https://github.com/misbahsy/video-audio-mcp.git video-audio
```

### Step 3: Configure Docker Volume Paths

#### 3.1 Update Imagician Docker Compose

Open `~/MCP Servers/imagician/docker-compose.yml` and update the volume path:

```yaml
# Find and replace this line:
- /path/to/your/Media Editor/export/images:/images:rw

# With your actual path (example for macOS):
- /Users/yourusername/MCP Servers/Media Editor/export/images:/images:rw
```

> 💡 **Tip:** Drag the folder into Terminal to get the exact path.

#### 3.2 Update Video-Audio Docker Compose

Open `~/MCP Servers/video-audio/docker-compose.yml` and update the volume path:

```yaml
# Find and replace this line:
- /path/to/your/Media Editor/export/videos:/videos:rw

# With your actual path (example for macOS):
- /Users/yourusername/MCP Servers/Media Editor/export/videos:/videos:rw
```

### Step 4: Build and Start Docker Containers

#### 4.1 Start Imagician Server

```bash
# Navigate to imagician folder
cd ~/MCP\ Servers/imagician

# Build and start container
docker-compose up -d --build

# Verify it's running
docker ps | grep imagician
```

**Expected output:**
```
imagician    imagician:latest    "node dist/index.js"    Up X minutes
```

#### 4.2 Start Video-Audio Server

```bash
# Navigate to video-audio folder
cd ~/MCP\ Servers/video-audio

# Build and start container
docker-compose up -d --build

# Verify it's running
docker ps | grep video-audio
```

**Expected output:**
```
video-audio    video-audio:latest    "sh -c 'echo..."    Up X minutes
```

---

## 4. ⚙️ CONFIGURATION

Configure the MCP servers for your AI platform:

### Option A: Configure for Claude Desktop

Open the Claude Desktop configuration file:

```bash
# macOS
open ~/Library/Application\ Support/Claude/claude_desktop_config.json

# If file doesn't exist, create it:
mkdir -p ~/Library/Application\ Support/Claude/
touch ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

Add the MCP server configuration:

```json
{
  "mcpServers": {
    "imagician": {
      "command": "docker",
      "args": ["exec", "-i", "imagician", "node", "dist/index.js"],
      "env": {
        "IMAGE_PATH": "/images",
        "NODE_ENV": "production"
      }
    },
    "video-audio": {
      "command": "docker",
      "args": ["exec", "-i", "video-audio", "python", "-m", "video_audio_mcp"],
      "env": {
        "PYTHONUNBUFFERED": "1",
        "VIDEO_PATH": "/videos",
        "NODE_ENV": "production"
      }
    }
  }
}
```

**Restart Claude Desktop** (⌘Q then reopen).

### Option B: Configure for OpenCode

Add to `opencode.json` in your project root:

```json
{
  "mcp": {
    "imagician": {
      "type": "local",
      "command": ["docker", "exec", "-i", "imagician", "node", "dist/index.js"],
      "env": {
        "IMAGE_PATH": "/images",
        "NODE_ENV": "production"
      }
    },
    "video-audio": {
      "type": "local",
      "command": ["docker", "exec", "-i", "video-audio", "python", "-m", "video_audio_mcp"],
      "env": {
        "PYTHONUNBUFFERED": "1",
        "VIDEO_PATH": "/videos"
      }
    }
  }
}
```

### Option C: Configure for VS Code Copilot

Create `.vscode/mcp.json` in your workspace:

```json
{
  "mcpServers": {
    "imagician": {
      "command": "docker",
      "args": ["exec", "-i", "imagician", "node", "dist/index.js"],
      "env": {
        "IMAGE_PATH": "/images",
        "NODE_ENV": "production"
      }
    },
    "video-audio": {
      "command": "docker",
      "args": ["exec", "-i", "video-audio", "python", "-m", "video_audio_mcp"],
      "env": {
        "PYTHONUNBUFFERED": "1",
        "VIDEO_PATH": "/videos"
      }
    }
  }
}
```

---

## 5. ✅ VERIFICATION

### Check 1: Verify Docker Containers

```bash
# List running containers
docker ps

# Should show both imagician and video-audio running
```

### Check 2: View Container Logs

```bash
# Check Imagician logs
docker logs imagician

# Check Video-Audio logs
docker logs video-audio
```

### Check 3: Test in Claude Desktop

Open Claude Desktop and try these commands:

```
# Test Imagician
Can you list the images in /images/Original/?

# Test Video-Audio
Can you check the video-audio MCP server status?
```

### Check 4: Run Repair Command

```
$repair
```

This runs connection verification for both MCP servers.

---

## 6. 🚀 USAGE

### File Workflow

| Step | Action              | Location                                   |
| ---- | ------------------- | ------------------------------------------ |
| 1    | Place input files   | `Original/` folder                         |
| 2    | Reference in Claude | `/images/Original/` or `/videos/Original/` |
| 3    | Process with AI     | Claude performs operations                 |
| 4    | Find output         | `New/` folder                              |

### Working with Images

```
# Place input images in:
Media Editor/export/images/Original/

# Reference in Claude as:
/images/Original/filename.jpg

# Processed images saved to:
Media Editor/export/images/New/
```

### Working with Videos

```
# Place input videos in:
Media Editor/export/videos/Original/

# Reference in Claude as:
/videos/Original/filename.mp4

# Processed videos saved to:
Media Editor/export/videos/New/
```

### Quick Commands

The Media Editor system supports these command shortcuts in Claude:

| Command                  | Function                   |
| ------------------------ | -------------------------- |
| `$image` or `$img`       | Image operations mode      |
| `$video` or `$vid`       | Video operations mode      |
| `$audio` or `$aud`       | Audio operations mode      |
| `$hls`                   | HLS video conversion       |
| `$repair` or `$r`        | Connection troubleshooting |
| `$interactive` or `$int` | Full conversational flow   |

---

## 7. 🎯 FEATURES

### Imagician Capabilities

| Feature      | Description                                       |
| ------------ | ------------------------------------------------- |
| **Resize**   | Change image dimensions with aspect ratio options |
| **Crop**     | Extract portions of images                        |
| **Rotate**   | Rotate images by any angle                        |
| **Compress** | Reduce file size with quality control             |
| **Convert**  | Change formats (JPG, PNG, WebP, etc.)             |
| **Filters**  | Apply blur, sharpen, grayscale, etc.              |
| **Metadata** | Read/write EXIF data                              |

### Video-Audio Capabilities

| Feature           | Description                           |
| ----------------- | ------------------------------------- |
| **Trim**          | Cut video to specific start/end times |
| **Merge**         | Combine multiple videos               |
| **Extract Audio** | Separate audio track from video       |
| **Add Subtitles** | Burn in or attach subtitle tracks     |
| **Convert**       | Change formats (MP4, MOV, WebM, etc.) |
| **HLS**           | Create streaming-ready content        |
| **Compress**      | Reduce video file size                |

---

## 8. 💡 EXAMPLES

### Image Processing Examples

```
# Resize an image
Resize the image /images/Original/photo.jpg to 800x600 and save to /images/New/

# Convert format
Convert /images/Original/image.png to JPEG with 85% quality

# Apply filters
Apply grayscale filter to /images/Original/photo.jpg

# Batch resize
Resize all images in /images/Original/ to max 1920px width
```

### Video Processing Examples

```
# Trim video
Trim /videos/Original/video.mp4 from 00:30 to 02:00

# Extract audio
Extract the audio from /videos/Original/video.mp4 as MP3

# Convert to HLS
Convert /videos/Original/video.mp4 to HLS format for streaming

# Merge videos
Merge all videos in /videos/Original/ into one file
```

---

## 9. 🔧 TROUBLESHOOTING

### Docker Containers Not Running

```bash
# Check Docker Desktop is running
docker ps

# Restart containers
docker restart imagician
docker restart video-audio

# View detailed logs
docker logs imagician --tail 50
docker logs video-audio --tail 50
```

### Claude Desktop Not Connecting

1. **Verify containers are running:**
   ```bash
   docker ps | grep -E "imagician|video-audio"
   ```

2. **Check config file exists and is valid:**
   ```bash
   cat ~/Library/Application\ Support/Claude/claude_desktop_config.json
   ```

3. **Validate JSON syntax** (no trailing commas, proper brackets)

4. **Restart Claude Desktop completely** (⌘Q, not just close window)

### Permission Issues

```bash
# Check folder permissions
ls -la ~/MCP\ Servers/Media\ Editor/export/

# Grant permissions if needed
chmod -R 755 ~/MCP\ Servers/Media\ Editor/export/
```

### Containers Keep Stopping

```bash
# Rebuild with logs visible
cd ~/MCP\ Servers/imagician
docker-compose down
docker-compose up --build

# Same for video-audio
cd ~/MCP\ Servers/video-audio
docker-compose down
docker-compose up --build
```

### Volume Path Issues

```bash
# Verify the path in docker-compose.yml matches your actual folder
# The path before the colon should be your local path
# The path after the colon should be /images or /videos

# Test volume mounting
docker run --rm -v /your/path/to/images:/test alpine ls /test
```

---

## 10. 📚 RESOURCES

### Official Repositories

- **Imagician**: https://github.com/flowy11/imagician
- **Video-Audio MCP**: https://github.com/misbahsy/video-audio-mcp

### Docker Commands Reference

| Command                        | Purpose                        |
| ------------------------------ | ------------------------------ |
| `docker ps`                    | List running containers        |
| `docker logs [container]`      | View container logs            |
| `docker restart [container]`   | Restart a container            |
| `docker-compose up -d`         | Start containers in background |
| `docker-compose down`          | Stop and remove containers     |
| `docker-compose up -d --build` | Rebuild and start containers   |

### Quick Start Checklist

- [ ] Docker Desktop installed and running
- [ ] Folder structure created (Original/New directories)
- [ ] Repositories cloned
- [ ] Volume paths updated in docker-compose files
- [ ] Containers built and running
- [ ] Claude Desktop config updated
- [ ] Claude Desktop restarted
- [ ] Test commands verified

---

## 🎉 Ready to Go!

Your Media Editor MCP system is now configured. Place media files in the `Original/` folders and start editing with AI!

**Quick Test:**
1. Place a test image in `Media Editor/export/images/Original/`
2. Open Claude Desktop
3. Run: `$repair` to verify connections
4. Ask: `Resize the image in /images/Original/ to 800x600`

Enjoy AI-powered media editing! 🚀