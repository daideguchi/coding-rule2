# Models Directory

This directory contains trained models and checkpoints for the AI Compliance Engine.

## Structure

- Model files are organized by timestamp and experiment ID
- Each model directory should contain:
  - Model artifacts (.pkl, .joblib, .h5, etc.)
  - Configuration files used for training
  - Evaluation metrics and results
  - README with model description

## Important Notes

- Model files are git-ignored due to size constraints
- Use model versioning tools (MLflow, DVC) for production deployments
- Always document model performance and limitations