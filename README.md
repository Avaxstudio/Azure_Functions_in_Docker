# Azure Functions in Docker (Terraform Demo)

## Project Goal
Showcase how to provision Azure Functions inside a custom Docker container using Terraform, and trigger them via Event Grid events.

## Current State
- Terraform defines Resource Group, Storage Account, Function App, and Event Grid subscription.
- Function App is configured to run from a Docker image.
- Event Grid trigger is wired to blob uploads.
- Function code is a placeholder for audio processing logic (future step: integrate FFmpeg).

## Why
This repo serves as a proof‑of‑concept for Infrastructure as Code + serverless in containers. It’s meant for presentation/demo purposes, not production.
